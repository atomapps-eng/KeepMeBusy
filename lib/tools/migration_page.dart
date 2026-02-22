import 'package:flutter/material.dart';
import 'migration_engine.dart';

class MigrationPage extends StatefulWidget {
  const MigrationPage({super.key});

  @override
  State<MigrationPage> createState() => _MigrationPageState();
}

class _MigrationPageState extends State<MigrationPage> {
  bool isRunning = false;
  String status = "Ready";

  Future<void> runMigration() async {
  setState(() {
    isRunning = true;
    status = "Running full migration...";
  });

  try {
    await MigrationEngine.migrateAttendance();

    setState(() {
      status = "Full Migration Completed ✅";
    });
  } catch (e) {
    setState(() {
      status = "Error: $e";
    });
  }

  setState(() {
    isRunning = false;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Migration Tool")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(status),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isRunning ? null : runMigration,
              child: const Text("RRun Full Migration"),
            ),
          ],
        ),
      ),
    );
  } 
}
