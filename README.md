# Trova i tuoi auricolari Bluetooth

App Flutter (Android/iOS) per ritrovare gli auricolari Bluetooth quando li perdi.

## Funzionalità

- **Salva i tuoi auricolari**: scansiona i dispositivi Bluetooth nelle vicinanze e salva quelli che vuoi poter ritrovare in seguito.
- **Indicatore di prossimità**: mostra in tempo reale quanto sei vicino agli auricolari in base alla potenza del segnale Bluetooth (RSSI).
- **Fai squillare**: riproduce un suono ad alto volume (a volume massimo) attraverso l'uscita audio Bluetooth, così gli auricolari stessi squillano e puoi localizzarli ad orecchio.
- **Monitoraggio fuori portata**: quando attivato, controlla continuamente se un auricolare salvato esce dal raggio Bluetooth. Se succede:
  1. mostra una notifica e riproduce un breve suono di avviso sul telefono;
  2. dopo un istante, fa squillare l'auricolare stesso a volume alto per ~20 secondi per aiutare a localizzarlo.

  Su **Android** questo monitoraggio gira tramite un foreground service con notifica persistente, quindi continua a funzionare anche ad app chiusa. Su **iOS**, per le restrizioni di sistema sulla scansione BLE in background, funziona solo mentre l'app è aperta.

## Come funziona

- La scansione BLE (`flutter_blue_plus`) traccia l'RSSI dell'auricolare selezionato per indicare se ti stai avvicinando o allontanando, e tiene traccia di quando ogni dispositivo salvato è stato visto l'ultima volta.
- Il suono di allarme viene riprodotto con `audioplayers` a volume massimo (`volume_controller`): se gli auricolari sono connessi via profilo audio (A2DP), l'audio viene riprodotto direttamente da loro.
- Il monitoraggio in background usa `flutter_background_service` (foreground service Android) e `flutter_local_notifications` per l'avviso di "fuori portata".
- I dispositivi salvati e lo stato del monitoraggio sono persistiti localmente con `shared_preferences`.

## Sviluppo

```bash
flutter pub get
flutter run
```

## Struttura del progetto

```
lib/
  main.dart                          # entry point dell'app
  models/saved_device.dart           # modello dispositivo salvato
  services/
    bluetooth_finder_service.dart    # scansione BLE e tracking RSSI
    ring_service.dart                # riproduzione suoni (squillo + avviso) a volume massimo
    notification_service.dart        # notifica locale "auricolare fuori portata"
    proximity_monitor_service.dart   # servizio in background che monitora la portata
    storage_service.dart             # persistenza dispositivi salvati
  screens/
    home_screen.dart                 # lista auricolari salvati + switch monitoraggio
    scan_screen.dart                 # scansione e selezione nuovo dispositivo
    finder_screen.dart               # ricerca con indicatore di prossimità + squillo
  widgets/
    signal_strength_indicator.dart
```
