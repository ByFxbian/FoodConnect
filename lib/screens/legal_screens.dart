import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
        ),
      ),
    );
  }
}

const String impressumText = '''
Impressum

Angaben gemäß § 5 TMG:
FoodConnect GmbH
Musterstraße 1
12345 Musterstadt

Vertreten durch:
Max Mustermann

Kontakt:
Telefon: +49 (0) 123 44 55 66
E-Mail: info@foodconnect.app

Registereintrag:
Eintragung im Handelsregister.
Registergericht: Amtsgericht Musterstadt
Registernummer: HRB 123456

Umsatzsteuer-ID:
Umsatzsteuer-Identifikationsnummer gemäß § 27 a Umsatzsteuergesetz:
DE 123456789
''';

const String datenschutzText = '''
Datenschutzerklärung

1. Datenschutz auf einen Blick
Wir nehmen den Schutz Ihrer persönlichen Daten sehr ernst. Wir behandeln Ihre personenbezogenen Daten vertraulich und entsprechend der gesetzlichen Datenschutzvorschriften sowie dieser Datenschutzerklärung.

2. Datenerfassung in unserer App
Die Datenerfassung in dieser App erfolgt durch den App-Betreiber (FoodConnect). Die erfassten Daten können z. B. Ihre Konto-Informationen (E-Mail, Name) oder Ihr Profilbild sein. Wir verwenden Firebase zur Authentifizierung und Datenspeicherung.

3. E-Mail und Push-Benachrichtigungen
Um Sie über neue Follower oder Aktivitäten zu informieren, senden wir gegebenenfalls Push-Benachrichtigungen.

Weitere detaillierte Informationen können auf unserer offiziellen Website eingesehen werden.
''';

const String agbText = '''
Allgemeine Nutzungsbedingungen (AGB)

1. Geltungsbereich
Diese AGB gelten für alle Nutzungsverträge, die zwischen Nutzern und der FoodConnect GmbH über diese App geschlossen werden.

2. Leistungen
Die App "FoodConnect" bietet eine Plattform zum Entdecken und Bewerten von Restaurants, sowie zum Erstellen und Teilen von Listen.

3. Pflichten der Nutzer
Nutzer verpflichten sich, bei der Erstellung von Inhalten (z. B. Restaurants oder Listen) geltendes Recht zu wahren. Beleidigungen, Spam oder rechtswidrige Inhalte sind strengstens untersagt und können zum Ausschluss führen.

4. Haftung
FoodConnect haftet nicht für die Richtigkeit der von Nutzern erstellten Restaurant-Daten oder sonstigen Informationen. Das Angebot wird "wie besehen" bereitgestellt.

Stand: März 2026
''';
