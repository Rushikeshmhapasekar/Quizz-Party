import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// ---------- Characters (emoji based, no assets needed) ----------
class GameCharacter {
  final String id, emoji, name;
  final Color color;
  const GameCharacter(this.id, this.emoji, this.name, this.color);
}

const kCharacters = <GameCharacter>[
  GameCharacter('fox', '🦊', 'Fox', Color(0xFFFF8A3D)),
  GameCharacter('panda', '🐼', 'Panda', Color(0xFF90A4AE)),
  GameCharacter('lion', '🦁', 'Lion', Color(0xFFFFC107)),
  GameCharacter('frog', '🐸', 'Frog', Color(0xFF66BB6A)),
  GameCharacter('unicorn', '🦄', 'Unicorn', Color(0xFFEC6FD1)),
  GameCharacter('octopus', '🐙', 'Octo', Color(0xFFE5566D)),
  GameCharacter('robot', '🤖', 'Robot', Color(0xFF42A5F5)),
  GameCharacter('alien', '👽', 'Alien', Color(0xFF26C6A0)),
  GameCharacter('dragon', '🐲', 'Dragon', Color(0xFF8BC34A)),
  GameCharacter('penguin', '🐧', 'Penguin', Color(0xFF5C6BC0)),
  GameCharacter('owl', '🦉', 'Owl', Color(0xFFA1887F)),
  GameCharacter('cat', '🐱', 'Cat', Color(0xFFFFB74D)),
];

GameCharacter characterById(String id) =>
    kCharacters.firstWhere((c) => c.id == id, orElse: () => kCharacters.first);

/// ---------- Question ----------
class Question {
  String text;
  List<String> options;
  int correct;
  int seconds;

  Question({
    required this.text,
    required this.options,
    required this.correct,
    this.seconds = 20,
  });

  Map<String, dynamic> toMap() => {
        'text': text,
        'options': options,
        'correct': correct,
        'seconds': seconds,
      };

  factory Question.fromMap(Map<String, dynamic> m) => Question(
        text: m['text'] as String,
        options: List<String>.from(m['options'] as List),
        correct: m['correct'] as int,
        seconds: m['seconds'] as int,
      );
}

/// ---------- Game ----------
/// status: lobby | question | reveal | finished
class Game {
  final String code;
  final String status;
  final int index;
  final List<Question> questions;

  Game({
    required this.code,
    required this.status,
    required this.index,
    required this.questions,
  });

  Question? get current =>
      index >= 0 && index < questions.length ? questions[index] : null;
  bool get isLast => index >= questions.length - 1;

  factory Game.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Game(
      code: d.id,
      status: m['status'] as String,
      index: m['index'] as int,
      questions: (m['questions'] as List)
          .map((e) => Question.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

/// ---------- Player ----------
class Player {
  final String id, name, character;
  final int score, answeredQuestion, choice, lastGain;

  Player({
    required this.id,
    required this.name,
    required this.character,
    required this.score,
    required this.answeredQuestion,
    required this.choice,
    required this.lastGain,
  });

  GameCharacter get char => characterById(character);

  factory Player.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return Player(
      id: d.id,
      name: m['name'] as String,
      character: m['character'] as String,
      score: (m['score'] ?? 0) as int,
      answeredQuestion: (m['answeredQuestion'] ?? -1) as int,
      choice: (m['choice'] ?? -1) as int,
      lastGain: (m['lastGain'] ?? 0) as int,
    );
  }
}
