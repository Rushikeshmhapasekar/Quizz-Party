import 'package:flutter/material.dart';

import '../game_service.dart';
import '../models.dart';
import '../widgets.dart';
import 'host_screen.dart';

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final questions = <Question>[];
  bool _busy = false;

  void _addSamples() => setState(() => questions.addAll([
        Question(
            text: 'Which planet is known as the Red Planet?',
            options: ['Venus', 'Mars', 'Jupiter', 'Mercury'],
            correct: 1,
            seconds: 15),
        Question(
            text: 'What is 7 x 8?',
            options: ['54', '56', '63', '48'],
            correct: 1,
            seconds: 10),
        Question(
            text: 'Which language is Flutter written in?',
            options: ['Kotlin', 'Swift', 'Dart', 'Java'],
            correct: 2,
            seconds: 15),
      ]));

  Future<void> _edit([int? i]) async {
    final q = i == null ? null : questions[i];
    final text = TextEditingController(text: q?.text);
    final opts = List.generate(
        4,
        (k) => TextEditingController(
            text: q != null && k < q.options.length ? q.options[k] : ''));
    int correct = q?.correct ?? 0;
    int secs = q?.seconds ?? 20;

    final result = await showDialog<Question>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(q == null ? 'New question' : 'Edit question'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: text,
                  decoration: const InputDecoration(labelText: 'Question'),
                ),
                const SizedBox(height: 8),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Tap the circle to mark the correct answer',
                        style: TextStyle(fontSize: 12, color: Colors.white60))),
                for (var k = 0; k < 4; k++)
                  Row(children: [
                    IconButton(
                      icon: Icon(
                          correct == k
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: correct == k
                              ? Colors.greenAccent
                              : kOptionColors[k]),
                      onPressed: () => setS(() => correct = k),
                    ),
                    Expanded(
                      child: TextField(
                        controller: opts[k],
                        decoration:
                            InputDecoration(labelText: 'Option ${k + 1}'),
                      ),
                    ),
                  ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Text('Time limit: '),
                  DropdownButton<int>(
                    value: secs,
                    items: [10, 15, 20, 30, 60]
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text('$s s')))
                        .toList(),
                    onChanged: (v) => setS(() => secs = v!),
                  ),
                ]),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (text.text.trim().isEmpty ||
                    opts.any((o) => o.text.trim().isEmpty)) {
                  return;
                }
                Navigator.pop(
                  ctx,
                  Question(
                    text: text.text.trim(),
                    options: opts.map((o) => o.text.trim()).toList(),
                    correct: correct,
                    seconds: secs,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => i == null ? questions.add(result) : questions[i] = result);
    }
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final code = await GameService.instance.createGame(questions);
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => HostScreen(code: code)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not create game: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create quiz'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(onPressed: _addSamples, child: const Text('Add samples')),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Question'),
      ),
      body: Column(children: [
        Expanded(
          child: questions.isEmpty
              ? const Center(
                  child: Text('No questions yet.\nTap + to add one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60)))
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: questions.length,
                  onReorder: (a, b) => setState(() {
                    if (b > a) b--;
                    questions.insert(b, questions.removeAt(a));
                  }),
                  itemBuilder: (_, i) {
                    final q = questions[i];
                    return Card(
                      key: ValueKey(q),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(q.text),
                        subtitle: Text(
                            'Answer: ${q.options[q.correct]}  •  ${q.seconds}s'),
                        onTap: () => _edit(i),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              setState(() => questions.removeAt(i)),
                        ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: questions.isEmpty || _busy ? null : _create,
                child: _busy
                    ? const CircularProgressIndicator()
                    : const Text('Create game & get code',
                        style: TextStyle(fontSize: 17)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
