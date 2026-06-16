# Trova i tuoi auricolari Bluetooth

App Flutter (Android/iOS) per ritrovare gli auricolari Bluetooth quando li perdi.

## Funzionalità

- **Salva i tuoi auricolari**: scansiona i dispositivi Bluetooth nelle vicinanze e salva quelli che vuoi poter ritrovare in seguito.
- **Indicatore di prossimità**: mostra in tempo reale quanto sei vicino agli auricolari in base alla potenza del segnale Bluetooth (RSSI).
- **Fai squillare**: riproduce un suono ad alto volume attraverso l'uscita audio Bluetooth, così gli auricolari stessi squillano e puoi localizzarli ad orecchio.

## Come funziona

- La scansione BLE (`flutter_blue_plus`) traccia l'RSSI dell'auricolare selezionato per indicare se ti stai avvicinando o allontanando.
- Il suono di allarme viene riprodotto con `audioplayers`: se gli auricolari sono connessi via profilo audio (A2DP), l'audio viene riprodotto direttamente da loro.
- I dispositivi salvati sono persistiti localmente con `shared_preferences`.

## Sviluppo

```bash
flutter pub get
flutter run
```

## Struttura del progetto

```
lib/
  main.dart                       # entry point dell'app
  models/saved_device.dart        # modello dispositivo salvato
  services/
    bluetooth_finder_service.dart # scansione BLE e tracking RSSI
    ring_service.dart             # riproduzione suono di allarme
    storage_service.dart          # persistenza dispositivi salvati
  screens/
    home_screen.dart              # lista auricolari salvati
    scan_screen.dart              # scansione e selezione nuovo dispositivo
    finder_screen.dart            # ricerca con indicatore di prossimità + squillo
  widgets/
    signal_strength_indicator.dart
```
