import 'package:flutter/material.dart';

import 'models.dart';

const kOptionColors = [
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFFF9A825),
  Color(0xFF43A047),
];
const kOptionIcons = [
  Icons.change_history,
  Icons.diamond_outlined,
  Icons.circle_outlined,
  Icons.square_outlined,
];

/// Round avatar with the character emoji.
class CharacterAvatar extends StatelessWidget {
  final GameCharacter character;
  final double size;
  const CharacterAvatar(this.character, {super.key, this.size = 48});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: character.color.withOpacity(0.25),
          border: Border.all(color: character.color, width: 2),
        ),
        child: Text(character.emoji, style: TextStyle(fontSize: size * 0.55)),
      );
}

/// Character that gently bounces forever.
class BouncingCharacter extends StatefulWidget {
  final GameCharacter character;
  final double size;
  const BouncingCharacter(this.character, {super.key, this.size = 120});

  @override
  State<BouncingCharacter> createState() => _BouncingCharacterState();
}

class _BouncingCharacterState extends State<BouncingCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: CurvedAnimation(parent: _c, curve: Curves.easeInOut),
        builder: (_, child) => Transform.translate(
          offset: Offset(0, -18 * Curves.easeInOut.transform(_c.value)),
          child: Transform.rotate(
            angle: (_c.value - 0.5) * 0.12,
            child: child,
          ),
        ),
        child: CharacterAvatar(widget.character, size: widget.size),
      );
}

/// Pops in with an elastic animation (used for players joining the lobby).
class PlayerChip extends StatelessWidget {
  final Player player;
  const PlayerChip(this.player, {super.key});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.elasticOut,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CharacterAvatar(player.char, size: 64),
            const SizedBox(height: 4),
            Text(player.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

/// Shrinking progress bar with seconds left.
class CountdownBar extends StatefulWidget {
  final int seconds;
  final VoidCallback? onDone;
  const CountdownBar({super.key, required this.seconds, this.onDone});

  @override
  State<CountdownBar> createState() => _CountdownBarState();
}

class _CountdownBarState extends State<CountdownBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.seconds),
  )
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone?.call();
    })
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final left = (widget.seconds * (1 - _c.value)).ceil();
          return Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: 1 - _c.value,
                  minHeight: 14,
                  color: left <= 5 ? Colors.redAccent : Colors.greenAccent,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('$left',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ]);
        },
      );
}

/// Leaderboard whose rows slide to their new rank and whose scores count up.
///
/// On a "reveal" screen pass [questionIndex]: rows first show the OLD ranking
/// (score minus points gained on that question), then animate to the new one.
class AnimatedLeaderboard extends StatefulWidget {
  final List<Player> players;
  final int? questionIndex;
  final String? highlightId;
  const AnimatedLeaderboard({
    super.key,
    required this.players,
    this.questionIndex,
    this.highlightId,
  });

  @override
  State<AnimatedLeaderboard> createState() => _AnimatedLeaderboardState();
}

class _AnimatedLeaderboardState extends State<AnimatedLeaderboard> {
  static const rowH = 68.0;
  static const anim = Duration(milliseconds: 1100);
  bool _final = false;

  @override
  void initState() {
    super.initState();
    if (widget.questionIndex == null) {
      _final = true;
    } else {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _final = true);
      });
    }
  }

  int _gain(Player p) =>
      widget.questionIndex != null && p.answeredQuestion == widget.questionIndex
          ? p.lastGain
          : 0;

  int _display(Player p) => _final ? p.score : p.score - _gain(p);

  @override
  Widget build(BuildContext context) {
    final stable = [...widget.players]..sort((a, b) => a.id.compareTo(b.id));
    final ranked = [...widget.players]..sort((a, b) {
        final c = _display(b).compareTo(_display(a));
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    final rankOf = {for (var i = 0; i < ranked.length; i++) ranked[i].id: i};

    return SizedBox(
      height: stable.length * rowH,
      child: Stack(
        children: [
          for (final p in stable)
            AnimatedPositioned(
              key: ValueKey(p.id),
              duration: anim,
              curve: Curves.easeInOutCubic,
              top: rankOf[p.id]! * rowH,
              left: 0,
              right: 0,
              height: rowH,
              child: _Row(
                player: p,
                rank: rankOf[p.id]!,
                score: _display(p),
                gain: _final ? _gain(p) : 0,
                highlight: p.id == widget.highlightId,
              ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final Player player;
  final int rank, score, gain;
  final bool highlight;
  const _Row({
    required this.player,
    required this.rank,
    required this.score,
    required this.gain,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    const medals = ['🥇', '🥈', '🥉'];
    final base = rank == 0
        ? const Color(0xFFFFC107)
        : highlight
            ? const Color(0xFF7C4DFF)
            : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: base.withOpacity(rank == 0 || highlight ? 0.28 : 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight ? const Color(0xFFB39DFF) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(children: [
          SizedBox(
            width: 38,
            child: Text(rank < 3 ? medals[rank] : '${rank + 1}',
                style: TextStyle(
                    fontSize: rank < 3 ? 26 : 20, fontWeight: FontWeight.bold)),
          ),
          CharacterAvatar(player.char, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Text(player.name,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          AnimatedOpacity(
            opacity: gain > 0 ? 1 : 0,
            duration: const Duration(milliseconds: 400),
            child: Text('+$gain  ',
                style: const TextStyle(
                    color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(end: score.toDouble()),
            duration: AnimatedLeaderboardDuration.value,
            builder: (_, v, __) => Text('${v.round()}',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
    );
  }
}

class AnimatedLeaderboardDuration {
  static const value = Duration(milliseconds: 1100);
}
