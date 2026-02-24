import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:foodconnect/utils/snackbar_helper.dart';
import 'package:foodconnect/services/app_logger.dart';

class TasteProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? initialProfileData;

  TasteProfileScreen({required this.userId, this.initialProfileData});

  @override
  // ignore: library_private_types_in_public_api
  State<TasteProfileScreen> createState() => _TasteProfileScreenState();
}

class _TasteProfileScreenState extends State<TasteProfileScreen> {
  int currentStep = 0;
  List<String> answers = List.filled(5, '', growable: false);
  bool isEditMode = false;

  final Map<String, int> keyToIndex = {
    "favoriteCuisine": 0,
    "dietType": 1,
    "spiceLevel": 2,
    "allergies": 3,
    "favoriteTaste": 4,
  };

  final List<Map<String, dynamic>> questions = [
    {
      'key': "favoriteCuisine",
      'question': 'Was ist deine Lieblingsküche?',
      'options': [
        'Italienisch',
        'Asiatisch',
        'Amerikanisch',
        'Indisch',
        'Mexikanisch',
        'Andere',
        'Keine Präferenz'
      ]
    },
    {
      'key': "dietType",
      'question': 'Welche Ernährungsweise bevorzugst du?',
      'options': [
        'Allesesser',
        'Vegetarisch',
        'Vegan',
        'Pescatarisch',
        'Flexitarisch',
        'Andere',
        'Keine spezielle'
      ]
    },
    {
      'key': "spiceLevel",
      'question': 'Wie scharf magst du dein Essen?',
      'options': ['Mild', 'Leicht scharf', 'Scharf', 'Sehr scharf', 'Egal']
    },
    {
      'key': "allergies",
      'question': 'Hast du Allergien oder Unverträglichkeiten?',
      'options': [
        'Keine',
        'Laktose',
        'Gluten',
        'Nüsse',
        'Meeresfrüchte',
        'Soja',
        'Andere'
      ]
    },
    {
      'key': "favoriteTaste",
      'question': 'Welche Geschmacksrichtung bevorzugst du?',
      'options': ['Süß', 'Salzig', 'Sauer', 'Bitter', 'Umami', 'Egal']
    }
  ];

  /*final List<Map<String, dynamic>> questions = [
    {
      'question': 'Was ist deine Lieblingsküche?',
      'options': ['Italienisch', 'Asiatisch', 'Amerikanisch', 'Indisch', 'Mexikanisch']
    },
    {
      'question': 'Welche Ernährungsweise bevorzugst du?',
      'options': ['Allesesser', 'Vegetarisch', 'Vegan', 'Keto', 'Paleo']
    },
    {
      'question': 'Wie scharf magst du dein Essen?',
      'options': ['Mild', 'Leicht scharf', 'Scharf', 'Sehr scharf']
    },
    {
      'question': 'Hast du Allergien?',
      'options': ['Keine', 'Laktose', 'Gluten', 'Erdnüsse', 'Meeresfrüchte']
    },
    {
      'question': 'Welche Geschmacksrichtung bevorzugst du?',
      'options': ['Süß', 'Salzig', 'Sauer', 'Bitter', 'Umami']
    }
  ];*/

  @override
  void initState() {
    super.initState();
    if (widget.initialProfileData != null &&
        widget.initialProfileData!.isNotEmpty) {
      isEditMode = true;
      widget.initialProfileData!.forEach((key, value) {
        if (keyToIndex.containsKey(key) && value is String) {
          answers[keyToIndex[key]!] = value;
        }
      });
    }
  }

  Future<void> _saveAnswer(String answer) async {
    setState(() {
      answers[currentStep] = answer;
    });

    Map<String, dynamic> profileToSave = {};
    keyToIndex.forEach((key, index) {
      profileToSave[key] = answers[index];
    });

    /*await FirebaseFirestore.instance.collection("users").doc(widget.userId).set({
      "tasteProfile": {
        "favoriteCuisine": answers[0],
        "dietType": answers[1],
        "spiceLevel": answers[2],
        "allergies": answers[3],
        "favoriteTaste": answers[4],
      }
    }, SetOptions(merge: true));

    if(currentStep < questions.length - 1) {
      setState(() {
        currentStep++;
      });
    } else {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    }*/
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .set({
        "tasteProfile": profileToSave,
      }, SetOptions(merge: true));

      if (currentStep < questions.length - 1) {
        setState(() {
          currentStep++;
        });
      } else {
        if (isEditMode) {
          if (mounted) Navigator.pop(context);
        } else {
          if (mounted) {
            context.go('/explore');
          }
        }
      }
    } catch (e) {
      AppLogger().error('TasteProfile', 'Fehler beim Speichern', error: e);
      if (!mounted) return;
      AppSnackBar.error(
          context, 'Fehler beim Speichern des Geschmacksprofils.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestionData = questions[currentStep];
    final questionText = currentQuestionData['question'] as String;
    final options = currentQuestionData['options'] as List<String>;
    final currentAnswer = answers[currentStep];

    return Scaffold(
      appBar: isEditMode
          ? AppBar(
              title: Text(
                  'Profil bearbeiten (${currentStep + 1}/${questions.length})'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.adaptive.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: isEditMode ? 20 : 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                questionText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),
            /*...questions[currentStep]['options'].map<Widget>((option) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
              child: ElevatedButton(
                onPressed: () => _saveAnswer(option),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(option, style: TextStyle(fontSize: 16)),
              ),
            )),*/
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: options.map<Widget>((option) {
                  final bool isSelected = option == currentAnswer;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () => _saveAnswer(option),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.7),
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isSelected
                              ? BorderSide(color: Colors.white, width: 2)
                              : BorderSide.none,
                        ),
                        elevation: isSelected ? 4 : 2,
                      ),
                      child: Text(option,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (currentStep + 1) / questions.length,
                  backgroundColor: Colors.white30, // Oder Theme-Farbe
                  color:
                      Theme.of(context).colorScheme.primary, // Oder Theme-Farbe
                  minHeight: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
