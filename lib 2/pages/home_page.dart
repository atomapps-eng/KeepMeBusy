import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final String title;

  const HomePage({super.key, required this.title});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> _activities = [];
  final TextEditingController _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _addActivity() async {
  final text = _taskController.text.trim();
  if (text.isEmpty) return;

  setState(() {
    _activities.add(text);
    _taskController.clear();
  });

  await _saveActivities();
  if (!mounted) return;
  FocusScope.of(context).unfocus();
}


  void _removeActivity(int index) {
    setState(() {
      _activities.removeAt(index);
    });

    _saveActivities();
  }

  void _editActivity(int index) {
    final controller =
        TextEditingController(text: _activities[index]);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;

                setState(() {
                  _activities[index] = text;
                });

                _saveActivities();
                FocusScope.of(context).unfocus();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveActivities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('keepmebusy_tasks', _activities);
  }

  Future<void> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('keepmebusy_tasks');

    if (saved != null) {
      setState(() {
        _activities
          ..clear()
          ..addAll(saved);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What should I do today?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _activities.isEmpty
                  ? 'No activities yet'
                  : 'Total tasks: ${_activities.length}',
            ),
            const SizedBox(height: 16),
            Row(
  children: [
    Expanded(
      child: TextField(
        controller: _taskController,
        decoration: const InputDecoration(
          hintText: 'Add a task...',
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
    ),
    const SizedBox(width: 8),
    SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _addActivity,
        child: const Icon(Icons.add),
      ),
    ),
  ],
),

            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _addActivity,
              child: const Text('Add Task'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _activities.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_activities[index]),
                    onTap: () => _editActivity(index),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeActivity(index),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
