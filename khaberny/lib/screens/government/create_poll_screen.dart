import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreatePollScreen extends StatefulWidget {
  const CreatePollScreen({super.key});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _allowMultipleVotes = false;
  bool _isSubmitting = false;

  void _addOption() {
    setState(() => _optionControllers.add(TextEditingController()));
  }

  Future<void> _submitPoll() async {
    if (!_formKey.currentState!.validate()) return;

    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 2 options')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final pollData = {
        'type': 'poll',
        'question': question,
        'options': options,
        'votes': List.generate(options.length, (_) => 0),
        'voters': [],
        'allowMultipleVotes': _allowMultipleVotes,
        'createdAt': Timestamp.now(),
        'authorId': 'government',
        'authorName': 'Government Panel',
        'authorRole': 'government',
        'content': '📊 POLL: $question',
      };

      await FirebaseFirestore.instance.collection('posts').add(pollData);
      await FirebaseFirestore.instance.collection('polls').add(pollData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Poll created successfully!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B203D),
      appBar: AppBar(
        title: const Text("Create Poll"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("Poll Question", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _questionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Enter poll question...',
                  hintStyle: TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text("Options", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              ..._optionControllers.map((controller) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: TextFormField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Option',
                      hintStyle: TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                );
              }),
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add, color: Colors.white70),
                label: const Text("Add Option", style: TextStyle(color: Colors.white70)),
              ),
              Row(
                children: [
                  Switch(
                    value: _allowMultipleVotes,
                    onChanged: (val) => setState(() => _allowMultipleVotes = val),
                    activeColor: Colors.greenAccent,
                  ),
                  const SizedBox(width: 8),
                  const Text("Allow multiple votes", style: TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: _isSubmitting ? null : _submitPoll,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Poll"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
