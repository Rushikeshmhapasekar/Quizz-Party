import 'package:flutter/material.dart';

import '../game_service.dart';
import '../models.dart';
import '../widgets.dart';

class HostScreen extends StatelessWidget {
  final String code;
  const HostScreen({super.key, required this.code});

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
                switch (game.status) {
                  case 'lobby':
                    return _Lobby(game: game, players: players);
                  case 'question':
                    return _HostQuestion(
                      key: ValueKey(game.index),
                      game: game,
                      players: players,
                    );
                  case 'reveal':
                    return _Reveal(game: game, players: players);
                  default:
                    return _Finished(players: players);
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _Lobby extends StatelessWidget {
  final Game game;
  final List<Player> players;
  const _Lobby({required this.game, required this.players});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Text('Join with code', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            game.code,
            style: const TextStyle(
              color: Color(0xFF1B1038),
              fontSize: 64,
              fontWeight: FontWeight.w900,
              letterSpacing: 10,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('${players.length} player${players.length == 1 ? '' : 's'} joined',
            style: const TextStyle(fontSize: 18, color: Colors.white70)),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 20,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [for (final p in players) PlayerChip(p, key: ValueKey(p.id))],
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start quiz', style: TextStyle(fontSize: 18)),
            onPressed: players.isEmpty
                ? null
                : () => GameService.instance.startQuestion(game.code, 0),
          ),
        ),
      ]),
    );
  }
}

class _HostQuestion extends StatefulWidget {
  final Game game;
  final List<Player> players;
  const _HostQuestion({super.key, required this.game, required this.players});

  @override
  State<_HostQuestion> createState() => _HostQuestionState();
}

class _HostQuestionState extends State<_HostQuestion> {
  bool _ended = false;

  void _end() {
    if (_ended) return;
    _ended = true;
    GameService.instance.showResults(widget.game.code);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final q = game.current!;
    final answered = widget.players
        .where((p) => p.answeredQuestion == game.index)
        .length;

    // Everyone answered -> move on automatically.
    if (widget.players.isNotEmpty && answered == widget.players.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _end());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Row(children: [
          Text('Question ${game.index + 1}/${game.questions.length}',
              style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Text('$answered/${widget.players.length} answered',
              style: const TextStyle(color: Colors.white70)),
        ]),
        const SizedBox(height: 12),
        CountdownBar(seconds: q.seconds, onDone: _end),
        const Spacer(),
        Text(q.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
        const Spacer(),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          childAspectRatio: 3.2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < q.options.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: kOptionColors[i],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Icon(kOptionIcons[i], size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(q.options[i],
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton(onPressed: _end, child: const Text('Skip / show results')),
      ]),
    );
  }
}

class _Reveal extends StatelessWidget {
  final Game game;
  final List<Player> players;
  const _Reveal({required this.game, required this.players});

  @override
  Widget build(BuildContext context) {
    final q = game.current!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Text(q.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: Colors.white70)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: kOptionColors[q.correct],
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(q.options[q.correct],
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('Leaderboard',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: AnimatedLeaderboard(
              players: players,
              questionIndex: game.index,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: () => game.isLast
                ? GameService.instance.finish(game.code)
                : GameService.instance.startQuestion(game.code, game.index + 1),
            child: Text(game.isLast ? 'Final results' : 'Next question',
                style: const TextStyle(fontSize: 18)),
          ),
        ),
      ]),
    );
  }
}

class _Finished extends StatelessWidget {
  final List<Player> players;
  const _Finished({required this.players});

  @override
  Widget build(BuildContext context) {
    final top = ([...players]..sort((a, b) => b.score.compareTo(a.score)))
        .take(1)
        .toList();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Text('🏆 Final results',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
        if (top.isNotEmpty) ...[
          const SizedBox(height: 12),
          BouncingCharacter(top.first.char, size: 110),
          const SizedBox(height: 8),
          Text('${top.first.name} wins!',
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
              child: AnimatedLeaderboard(players: players)),
        ),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Back to home'),
          ),
        ),
      ]),
    );
  }
}
