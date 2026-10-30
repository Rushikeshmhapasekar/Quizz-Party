import 'package:flutter/material.dart';

import '../game_service.dart';
import '../models.dart';
import '../widgets.dart';
import 'player_screen.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  GameCharacter _selected = kCharacters.first;
  bool _busy = false;
  String? _error;

  Future<void> _join() async {
    final code = _code.text.trim();
    final name = _name.text.trim();
    if (code.length != 6 || name.isEmpty) {
      setState(() => _error = 'Enter the 6-digit code and your name');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id =
          await GameService.instance.joinGame(code, name, _selected.id);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) =>
                PlayerScreen(code: code, playerId: id, character: _selected)),
      );
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Join game'), backgroundColor: Colors.transparent),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 8),
                decoration: const InputDecoration(
                    hintText: '000000', counterText: '',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _name,
                maxLength: 14,
                decoration: const InputDecoration(
                    labelText: 'Your nickname', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              const Text('Choose your character',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (final c in kCharacters)
                    GestureDetector(
                      onTap: () => setState(() => _selected = c),
                      child: AnimatedScale(
                        scale: _selected == c ? 1.15 : 0.92,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: _selected == c
                                ? [
                                    BoxShadow(
                                        color: c.color.withOpacity(0.7),
                                        blurRadius: 18)
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                  child: FittedBox(
                                      child: CharacterAvatar(c, size: 80))),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('${_selected.emoji}  ${_selected.name}',
                    style: const TextStyle(fontSize: 18)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _busy ? null : _join,
                  child: _busy
                      ? const CircularProgressIndicator()
                      : const Text('Join', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
