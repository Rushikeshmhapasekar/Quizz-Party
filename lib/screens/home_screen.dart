import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets.dart';
import 'create_quiz_screen.dart';
import 'join_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in kCharacters.take(4))
                        BouncingCharacter(c, size: 56),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Quiz Party',
                      style:
                          TextStyle(fontSize: 44, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text('Host a live quiz or join with a code',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Host a quiz',
                          style: TextStyle(fontSize: 18)),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CreateQuizScreen())),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('Join a game',
                          style: TextStyle(fontSize: 18)),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const JoinScreen())),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
