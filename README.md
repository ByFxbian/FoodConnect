# FoodConnect

## Anleitung: FoodConnect auf dem PC über Android Emulator und VS Code starten und testen

Diese Anleitung zeigt Schritt für Schritt, wie man Flutter und den Android Emulator installiert und die App in Visual Studio Code startet – auch wenn man vorher noch nie mit Flutter oder Android gearbeitet hat.

### Notwendige Programme installieren

#### Flutter SDK installieren

- Flutter von der [offiziellen Webseite](https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.29.1-stable.zip) herunterladen
- Die Datei an einen Speicherort wie z.B. `C:\flutter\` entpacken (Empfohlen: Kein Pfad mit Leerzeichen oder Sonderzeichen)
- Flutter zur PATH-Umgebungsvariable hinzufügen
  - Damit Flutter in der Eingabeaufforderung genutzt werden kann, muss der bin-Ordner zur PATH-Variable hinzugefügt werden
    - Man drückt Win+R, tippt `sysdm.cpl` und drückt Enter
    - Man geht zu `Erweitert` -> `Umgebungsvariablen`
    - Unter „Systemvariablen“ wählt man den Eintrag „Path“ aus und klickt auf „Bearbeiten“
    - Man klickt auf „Neu“ und fügt den Pfad zum bin-Ordner von Flutter hinzu (z.B. `C:\flutter\bin`)
    - Man speichert und schließt das Fenster.
    - Um zu prüfen ob es funktioniert hat drückt man erneut Win+R, gibt `cmd` ein und gibt in der Eingabeaufforderung den Befehl `flutter doctor` ein

#### Android Studio (+ Emulator) installieren

- Android Studio von der [offiziellen Webseite](https://redirector.gvt1.com/edgedl/android/studio/install/2024.3.1.13/android-studio-2024.3.1.13-windows.exe) herunterladen und installieren. 
- Wichtige Komponenten installieren
    - Android Studio öffnen
    - Auf `More Actions` klicken und `SDK Manager` auswählen
    - `Android 14 (UpsideDownCake)` auswählen und per Klick auf `Apply` im unteren Rechten Eck installieren
    - Zum Reiter `SDK Tools` wechseln und folgende Tools installieren:
      - Android Emulator
      - Android Emulator hypervisor driver (installer)
      - Android SDK Platform-Tools
      - Android SDK Build-Tools 36-rc5
      - Android SDK Command-Line Tools (latest)
      - CMake
      - NDK (Side by Side)

#### VS Code installieren

- VS Code über die [offizielle Webseite](https://code.visualstudio.com/docs/?dv=win64user) herunterladen und installieren
- Flutter- & Dart-Erweiterungen installieren
    - VS Code öffnen
    - `STRG + SHIFT + X` drücken um den Erweiterungsmanager zu öffnen
    - Nach `Flutter` suchen und installieren
    - Nach `Dart` suchen und installieren

### Android Emulator einrichten

- Android Studio starten
- Über `More Actions` den `Virtual Device Manager` öffnen
- Neues virtuelles Gerät erstellen
    - `Pixel 7 Pro` auswählen
    - Im nächsten Schritt in den Reiter `x86 Images` wechseln
    - `UpsideDownCake` mit API Level `34` oder ABI `x68_64` installieren
    - Gerät benennen und Prozess abschließen
- Das Gerät nun über den `Virtual Device Manager` starten

### Das Projekt in VS Code öffnen

- Flutter Projekt über das [offizielle Github Repository](https://github.com/ByFxbian/FoodConnect) herunterladen
    - Per Klick auf den grünen `<> Code` Button und danach auf `Download ZIP`
- Flutter-Projekt entpacken
    - `.zip` Datei nach beliebigem Ort entpacken
- VS Code starten und per Klick auf `Datei` und `Ordner öffnen` dann den entpackten Projektordner auswählen
- Mit `STRG + Ö` das Terminal öffnen und den Befehl `flutter pub get` Eingabeaufforderung
- Sicherstellen, dass die Datei `google-services.json` im Ordner `android/app/` vorhanden ist
- Dia App mit dem Befehl `fltuter run` im Terminal starten
    - Nach einigen Sekunden bis Minuten wird FoodConnect dann im virtuellen Gerät angezeigt.

### Fehlerbehebung
- Falls Flutter nicht gefunden wird, im Terminal den Befehl `flutter doctor` eingeben
    - Dieser Befehl zeigt alle fehlenden Abhängigkeiten
- Falls der Emulator nicht startet, alternativ über das Terminal per Befehl `flutter emulators --launch <Name des Emulators>` starten
- Fehlermeldung `Android-Licenses nicht akzeptiert`?
    - Den Befehl `flutter doctor --android-licenses`im Terminal eingeben
- Für weitere Fehler/Probleme auf die [offiziellen Flutter Installations Dokumentation](https://docs.flutter.dev/get-started/install/windows/mobile) zurückgreifen



