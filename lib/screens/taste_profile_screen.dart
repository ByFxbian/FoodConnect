import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/screens/main_screen.dart';

class TasteProfileScreen extends StatefulWidget {
  final String userId;

  TasteProfileScreen({ required this.userId});

  @override
  // ignore: library_private_types_in_public_api
  _TasteProfileScreenState createState() => _TasteProfileScreenState();
}

class _TasteProfileScreenState extends State<TasteProfileScreen> {
  int currentStep = 0;
  List<String> answers = ['', '', '', '', ''];

  final List<Map<String, dynamic>> questions = [
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
  ];

  void _saveAnswer(String answer) async {
    setState(() {
      answers[currentStep] = answer;
    });

    await FirebaseFirestore.instance.collection("users").doc(widget.userId).set({
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                questions[currentStep]['question'],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),
            ...questions[currentStep]['options'].map<Widget>((option) => Padding(
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
            )),
            Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (currentStep + 1) / questions.length,
                  backgroundColor: Colors.white30,
                  color: Colors.deepPurple,
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