# RaveFinder

App Flutter (Android/iOS) per ritrovare i tuoi amici ai rave e ai festival,
anche in zone senza campo o Wi-Fi — ispirata ai braccialetti/collane GPS
mesh tipo Totem Compass o Buddycompass, ma senza hardware dedicato.

## Funzionalità

- **Bonding**: prima dell'evento, condividi il tuo codice (8 caratteri) con
  un amico. Lui lo inserisce nella sua app e ti assegna un colore — non
  serve un "cristallo touch" NFC, basta condividere il codice a voce, per
  messaggio o con il tasto Condividi.
- **Bussola (Compass Mode)**: una freccia colorata ruota per indicarti la
  direzione verso un amico bondato, con la distanza in tempo reale, usando
  il GPS del telefono (funziona senza rete cellulare: il GPS è satellitare)
  e la bussola magnetica per orientare la freccia rispetto a come tieni il
  telefono in mano.
- **Rete mesh Bluetooth**: i telefoni bondati si scambiano la propria
  posizione via BLE. Ogni telefono che ha l'app aperta — anche di
  sconosciuti — inoltra per alcuni "salti" i pacchetti che riceve, così la
  posizione di un amico può arrivarti anche se è fuori dalla portata diretta
  del tuo Bluetooth, purché ci siano altri telefoni RaveFinder nel mezzo.

## Come funziona

- Ogni pacchetto di posizione (16 byte: id mittente, lat/lon, un contatore
  di sequenza e un contatore di salti TTL) viaggia dentro i dati
  "manufacturer" di un advertisement BLE — non serve una connessione GATT
  punto-punto, quindi non serve "accoppiare" i telefoni per il relay.
- Ogni dispositivo trasmette a rotazione: il proprio pacchetto di
  posizione, poi quelli che sta inoltrando per conto di altri (con TTL
  decrementato), un payload alla volta ogni ~1s.
- `lib/services/mesh_service.dart` gestisce scansione, relay, deduplica e
  scadenza dei pacchetti in coda. `lib/services/location_service.dart`
  calcola distanza e rotta (formula dell'ortodromia) tra la tua posizione e
  l'ultima nota di un amico.
- `lib/services/bonding_service.dart` mantiene la lista di amici bondati e
  applica i pacchetti in arrivo; `lib/services/storage_service.dart` la
  persiste con `shared_preferences`.

## Limiti noti (importante)

- **Broadcast solo Android**: l'advertising BLE con dati "manufacturer"
  personalizzati non è supportato dal Bluetooth periferico di iOS
  (limite di CoreBluetooth, non del plugin). Su iOS l'app può ricevere e
  mostrare le posizioni relayate da telefoni Android vicini, ma non può
  trasmettere la propria posizione né fare da relay per gli altri.
- **Mesh a flooding, non garantita**: non c'è instradamento intelligente,
  solo inondazione con TTL massimo di 6 salti e una finestra di dedupe di
  30s — funziona bene in una folla densa di persone con l'app aperta, non
  è un sostituto di un vero mesh radio dedicato come quello delle collane.
- **Nessuna cifratura**: i pacchetti (id breve + coordinate) viaggiano in
  chiaro nell'advertisement BLE. Va bene per l'uso previsto (ritrovarsi a
  un evento), ma chiunque scansioni nelle vicinanze con l'hardware giusto
  può leggere id e coordinate broadcast. Da valutare per una v2 se serve
  privacy più forte.
- **Company ID Bluetooth non registrato**: si usa `0xFFFF`, riservato dallo
  Bluetooth SIG per sviluppo/test. Va bene per un'app indie, ma prima di
  una distribuzione commerciale su larga scala andrebbe registrato un
  Company ID reale.
- **Non testato su hardware reale in questa sessione**: questo progetto è
  stato scritto in un ambiente senza Flutter SDK installato, quindi non è
  stato possibile eseguire `flutter pub get` / `flutter analyze` /
  `flutter run` localmente. La API dei plugin (`flutter_ble_peripheral`,
  `flutter_blue_plus`, `geolocator`, `flutter_compass`) è stata verificata
  contro la documentazione ufficiale, ma il primo run va fatto e verificato
  con dispositivi reali — il mesh multi-hop in particolare va provato con
  più telefoni fisici. La workflow CI (`flutter analyze` + `flutter test` +
  `flutter build apk`) darà il primo riscontro automatico.

## Sviluppo

```bash
cd rave_finder
flutter pub get
flutter run
```

## Pubblicazione sul Play Store

Prima di pubblicare, occorre (attività che l'utente deve completare, non
automatizzabili da qui):

1. Un account Google Play Developer (una tantum, a pagamento).
2. Sostituire `applicationId` in `android/app/build.gradle.kts`
   (attualmente `com.ravefinder.rave_finder`, placeholder) con un id
   univoco di tua proprietà.
3. Generare un keystore di firma release e configurarlo in
   `android/app/build.gradle.kts` (oggi firma con la chiave debug, va bene
   solo per test locali).
4. Sostituire l'icona placeholder in `android/app/src/main/res/mipmap-*`.
5. Preparare la scheda Play Store (screenshot, descrizione, privacy
   policy — obbligatoria, dato che l'app usa posizione e Bluetooth) e
   caricare l'App Bundle (`flutter build appbundle --release`).

## Struttura del progetto

```
lib/
  main.dart                       # entry point dell'app
  models/
    bonded_friend.dart            # amico bondato + codice <-> id
    mesh_packet.dart              # formato pacchetto mesh (encode/decode)
  services/
    identity_service.dart         # id mesh persistente di questo telefono
    location_service.dart         # GPS + bussola, distanza e rotta
    mesh_service.dart             # scansione/advertising BLE, relay flooding
    bonding_service.dart          # lista amici bondati + stato posizione live
    storage_service.dart          # persistenza amici bondati
  screens/
    home_screen.dart              # lista amici + distanza + ultimo segnale
    add_friend_screen.dart        # condividi il tuo codice / bonda un amico
    compass_screen.dart           # freccia direzione + distanza
  widgets/
    compass_arrow.dart            # freccia rotante (custom painter)
```
