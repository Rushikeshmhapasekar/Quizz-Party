import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'models.dart';

class GameService {
  GameService._();
  static final instance = GameService._();

  final _db = FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> _game(String code) =>
      _db.collection('games').doc(code);

  // ---------------- Host ----------------
  Future<String> createGame(List<Question> questions) async {
    final rnd = Random();
    String code;
    do {
      code = (100000 + rnd.nextInt(900000)).toString();
    } while ((await _game(code).get()).exists);

    await _game(code).set({
      'status': 'lobby',
      'index': -1,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  Future<void> startQuestion(String code, int index) =>
      _game(code).update({'status': 'question', 'index': index});

  Future<void> showResults(String code) =>
      _game(code).update({'status': 'reveal'});

  Future<void> finish(String code) =>
      _game(code).update({'status': 'finished'});

  // ---------------- Streams ----------------
  Stream<Game?> watchGame(String code) => _game(code)
      .snapshots()
      .map((s) => s.exists ? Game.fromDoc(s) : null);

  Stream<List<Player>> watchPlayers(String code) => _game(code)
      .collection('players')
      .snapshots()
      .map((s) => s.docs.map(Player.fromDoc).toList());

  // ---------------- Player ----------------
  /// Returns the new player's id. Throws a String message on failure.
  Future<String> joinGame(String code, String name, String characterId) async {
    final snap = await _game(code).get();
    if (!snap.exists) throw 'No game found with that code';
    if (snap.data()!['status'] != 'lobby') throw 'That game already started';

    final ref = await _game(code).collection('players').add({
      'name': name,
      'character': characterId,
      'score': 0,
      'answeredQuestion': -1,
      'choice': -1,
      'lastGain': 0,
    });
    return ref.id;
  }

  /// Faster correct answers earn more (500 - 1000 points).
  Future<int> submitAnswer({
    required String code,
    required String playerId,
    required Game game,
    required int choice,
    required double elapsedSeconds,
  }) {
    final ref = _game(code).collection('players').doc(playerId);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.data()!['answeredQuestion'] == game.index) return 0;

      final q = game.current!;
      final ratio = (elapsedSeconds / q.seconds).clamp(0.0, 1.0).toDouble();
      final gain = choice == q.correct ? (500 + 500 * (1 - ratio)).round() : 0;

      tx.update(ref, {
        'score': FieldValue.increment(gain),
        'answeredQuestion': game.index,
        'choice': choice,
        'lastGain': gain,
      });
      return gain;
    });
  }
}
