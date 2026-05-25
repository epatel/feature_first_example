import 'package:flutter/material.dart';

enum LogType { header, node, hook, result }

class LogLine {
  final String text;
  final LogType type;
  LogLine(this.text, this.type);
}

class LogView extends StatelessWidget {
  final List<LogLine> lines;
  final ScrollController controller;

  const LogView({super.key, required this.lines, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.all(16),
        itemCount: lines.length,
        itemBuilder: (context, index) {
          final line = lines[index];
          return Text(
            line.text,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.5,
              color: switch (line.type) {
                LogType.header => Colors.amber,
                LogType.result => Colors.greenAccent,
                LogType.hook => Colors.cyanAccent,
                LogType.node => Colors.white70,
              },
            ),
          );
        },
      ),
    );
  }
}
