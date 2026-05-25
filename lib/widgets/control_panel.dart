import 'package:flutter/material.dart';

class ControlPanel extends StatelessWidget {
  final List<ActionItem> actions;
  final List<ToggleItem> toggles;
  final List<StaticHookItem> staticHooks;
  final VoidCallback onClearLog;

  const ControlPanel({
    super.key,
    required this.actions,
    required this.toggles,
    required this.staticHooks,
    required this.onClearLog,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel(context, 'Run Features'),
        const SizedBox(height: 8),
        for (final a in actions)
          _actionButton(a.label, a.icon, a.onPressed),
        const SizedBox(height: 24),
        _sectionLabel(context, 'Dynamic Hooks'),
        const SizedBox(height: 8),
        for (final t in toggles)
          _toggleTile(t.title, t.target, t.value, t.onToggle),
        const SizedBox(height: 24),
        _sectionLabel(context, 'Static Hooks (always active)'),
        const SizedBox(height: 8),
        for (final h in staticHooks)
          _staticHookTile(h.from, h.target, h.description),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: onClearLog,
          icon: const Icon(Icons.clear_all),
          label: const Text('Clear log'),
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .labelLarge
          ?.copyWith(color: Colors.white54),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _toggleTile(
      String title, String target, bool value, VoidCallback onToggle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        dense: true,
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(target,
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
        value: value,
        onChanged: (_) => onToggle(),
      ),
    );
  }

  Widget _staticHookTile(String from, String target, String desc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: Colors.white.withValues(alpha: 0.05),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.link, size: 16, color: Colors.white38),
        title: Text(from, style: const TextStyle(fontSize: 13)),
        subtitle: Text('$target  ($desc)',
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
      ),
    );
  }
}

class ActionItem {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  ActionItem(this.label, this.icon, this.onPressed);
}

class ToggleItem {
  final String title;
  final String target;
  final bool value;
  final VoidCallback onToggle;
  ToggleItem(this.title, this.target, this.value, this.onToggle);
}

class StaticHookItem {
  final String from;
  final String target;
  final String description;
  StaticHookItem(this.from, this.target, this.description);
}
