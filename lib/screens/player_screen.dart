import 'package:flutter/material.dart';

import '../game_service.dart';
import '../models.dart';
import '../widgets.dart';

class PlayerScreen extends StatelessWidget {
  final String code, playerId;
  final GameCharacter character;
  const PlayerScreen({
    super.key,
    required this.code,
    required this.playerId,
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    final svc = GameService.instance;
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<Game?>(
          stream: svc.watchGame(code),
          builder: (context, gs) {
            final game = gs.data;
            if (game == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return StreamBuilder<List<Player>>(
              stream: svc.watchPlayers(code),
              builder: (context, ps) {
                final players = ps.data ?? [];
                final me = players.where((p) => p.id == playerId).firstOrNull;
                switch (game.status) {
                  case 'lobby':
                    return _Waiting(character: character, count: players.length);
                  case 'question':
                    return _PlayerQuestion(
                      key: ValueKey(game.index),
                      game: game,
                      playerId: playerId,
                      character: character,
                    );
                  case 'reveal':
                    return _PlayerReveal(
                        game: game, players: players, me: me);
                  default:
                    return _PlayerFinished(players: players, me: me);
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _Waiting extends StatelessWidget {
  final GameCharacter character;
  final int count;
  const _Waiting({required this.character, required this.count});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          BouncingCharacter(character, size: 140),
          const SizedBox(height: 32),
          const Text("You're in!",
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('$count player${count == 1 ? '' : 's'} in the lobby',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          const Text('Waiting for the host to start…',
              style: TextStyle(color: Colors.white70)),
        ]),
      );
}

class _PlayerQuestion extends StatefulWidget {
  final Game game;
  final String playerId;
  final GameCharacter character;
  const _PlayerQuestion({
    super.key,
    required this.game,
    required this.playerId,
    required this.character,
  });

  @override
  State<_PlayerQuestion> createState() => _PlayerQuestionState();
}

class _PlayerQuestionState extends State<_PlayerQuestion> {
  final _watch = Stopwatch()..start();
  int? _choice;
  bool _timeUp = false;

  Future<void> _answer(int i) async {
    if (_choice != null || _timeUp) return;
    setState(() => _choice = i);
    await GameService.instance.submitAnswer(
      code: widget.game.code,
      playerId: widget.playerId,
      game: widget.game,
      choice: i,
      elapsedSeconds: _watch.elapsedMilliseconds / 1000,
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.game.current!;

    if (_choice != null || _timeUp) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          BouncingCharacter(widget.character, size: 110),
          const SizedBox(height: 24),
          Text(_choice != null ? 'Answer locked in!' : "Time's up!",
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Waiting for everyone else…',
              style: TextStyle(color: Colors.white70)),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        CountdownBar(
            seconds: q.seconds,
            onDone: () {
              if (mounted) setState(() => _timeUp = true);
            }),
        const SizedBox(height: 16),
        Text(q.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (var i = 0; i < q.options.length; i++)
                Material(
                  color: kOptionColors[i],
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _answer(i),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(kOptionIcons[i], size: 40),
                          const SizedBox(height: 8),
                          Text(q.options[i],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _PlayerReveal extends StatelessWidget {
  final Game game;
  final List<Player> players;
  final Player? me;
  const _PlayerReveal(
      {required this.game, required this.players, required this.me});

  @override
  Widget build(BuildContext context) {
    final q = game.current!;
    final answered = me?.answeredQuestion == game.index;
    final correct = answered && me!.choice == q.correct;
    final ranked = [...players]..sort((a, b) => b.score.compareTo(a.score));
    final rank = me == null ? 0 : ranked.indexWhere((p) => p.id == me!.id) + 1;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Column(children: [
            Text(correct ? '✅' : (answered ? '❌' : '⏰'),
                style: const TextStyle(fontSize: 64)),
            Text(
                correct
                    ? 'Correct!  +${me!.lastGain}'
                    : answered
                        ? 'Wrong answer'
                        : 'No answer',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: correct ? Colors.greenAccent : Colors.redAccent)),
            if (!correct)
              Text('Correct: ${q.options[q.correct]}',
                  style: const TextStyle(color: Colors.white70)),
          ]),
        ),
        const SizedBox(height: 10),
        Text('You are #$rank of ${players.length}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: AnimatedLeaderboard(
              players: players,
              questionIndex: game.index,
              highlightId: me?.id,
            ),
          ),
        ),
      ]),
    );
  }
}

class _PlayerFinished extends StatelessWidget {
  final List<Player> players;
  final Player? me;
  const _PlayerFinished({required this.players, required this.me});

  @override
  Widget build(BuildContext context) {
    final ranked = [...players]..sort((a, b) => b.score.compareTo(a.score));
    final rank = me == null ? 0 : ranked.indexWhere((p) => p.id == me!.id) + 1;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Text('Game over!',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
        if (me != null) ...[
          const SizedBox(height: 12),
          BouncingCharacter(me!.char, size: 100),
          const SizedBox(height: 8),
          Text(rank == 1 ? '🏆 You won with ${me!.score} pts!' : 'You finished #$rank with ${me!.score} pts',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: AnimatedLeaderboard(players: players, highlightId: me?.id),
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Back to home'),
          ),
        ),
      ]),
    );
  }
}
