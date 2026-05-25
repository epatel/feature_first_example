typedef HookFn = Future<void> Function(Context ctx, String nodeName);

enum HookPoint { before, after }

class TraceEntry {
  final String feature;
  final String node;
  final String phase; // 'before', 'action', 'after', 'abort'
  final String? hookLabel;
  final DateTime timestamp;

  TraceEntry(this.feature, this.node, this.phase, {this.hookLabel})
      : timestamp = DateTime.now();

  @override
  String toString() {
    final hook = hookLabel != null ? ' [$hookLabel]' : '';
    return '$feature.$node.$phase$hook';
  }
}

class Context {
  final Map<String, dynamic> data = {};
  final List<TraceEntry> trace = [];
  bool _aborted = false;
  String? _abortReason;
  String? _abortedAt;

  bool get isAborted => _aborted;
  String? get abortReason => _abortReason;
  String? get abortedAt => _abortedAt;

  void abort(String reason) {
    _aborted = true;
    _abortReason = reason;
  }

  List<String> get executedNodes =>
      trace.where((e) => e.phase == 'action').map((e) => e.node).toList();

  List<String> get traceLog => trace.map((e) => e.toString()).toList();

  dynamic operator [](String key) => data[key];
  void operator []=(String key, dynamic value) => data[key] = value;
}

class HookHandle {
  final String label;
  final void Function() _unbind;
  bool _bound = true;

  HookHandle(this.label, this._unbind);

  bool get isBound => _bound;

  void unbind() {
    if (!_bound) return;
    _bound = false;
    _unbind();
  }
}

class _HookEntry {
  final String label;
  final HookFn fn;
  _HookEntry(this.label, this.fn);
}

class Node {
  final String featureName;
  final String name;
  final Future<void> Function(Context ctx) _action;
  final List<_HookEntry> _beforeHooks = [];
  final List<_HookEntry> _afterHooks = [];

  Node(this.featureName, this.name, this._action);

  Future<void> execute(Context ctx) async {
    for (final entry in List.of(_beforeHooks)) {
      ctx.trace.add(
          TraceEntry(featureName, name, 'before', hookLabel: entry.label));
      await entry.fn(ctx, name);
      if (ctx.isAborted) {
        ctx._abortedAt = '$featureName.$name.before';
        ctx.trace.add(
            TraceEntry(featureName, name, 'abort', hookLabel: entry.label));
        return;
      }
    }
    ctx.trace.add(TraceEntry(featureName, name, 'action'));
    await _action(ctx);
    if (ctx.isAborted) return;
    for (final entry in List.of(_afterHooks)) {
      ctx.trace.add(
          TraceEntry(featureName, name, 'after', hookLabel: entry.label));
      await entry.fn(ctx, name);
      if (ctx.isAborted) break;
    }
  }
}

class Feature {
  final String name;
  final List<Node> _nodes = [];

  Feature(this.name);

  Node addNode(String nodeName, Future<void> Function(Context ctx) action) {
    final node = Node(name, nodeName, action);
    _nodes.add(node);
    return node;
  }

  Node? getNode(String nodeName) {
    for (final n in _nodes) {
      if (n.name == nodeName) return n;
    }
    return null;
  }

  List<String> get nodeNames => _nodes.map((n) => n.name).toList();

  Future<Context> run([Context? ctx]) async {
    final context = ctx ?? Context();
    for (final node in _nodes) {
      await node.execute(context);
      if (context.isAborted) break;
    }
    return context;
  }
}

class Engine {
  final Map<String, Feature> _features = {};

  Feature feature(String name) {
    return _features.putIfAbsent(name, () => Feature(name));
  }

  Feature? getFeature(String name) => _features[name];

  List<String> get featureNames => _features.keys.toList();

  void bind(String target, HookPoint point, String label, HookFn hook) {
    _forEachTargetNode(target, (node) {
      _attach(node, point, _HookEntry(label, hook));
    });
  }

  HookHandle dynamicBind(
      String target, HookPoint point, String label, HookFn hook) {
    final entry = _HookEntry(label, hook);
    final nodes = <Node>[];
    _forEachTargetNode(target, (node) {
      _attach(node, point, entry);
      nodes.add(node);
    });
    return HookHandle(label, () {
      for (final node in nodes) {
        _detach(node, point, entry);
      }
    });
  }

  List<String> hooksOn(String target, HookPoint point) {
    final parts = target.split('.');
    final feature = _features[parts[0]];
    if (feature == null) return [];
    final node = feature.getNode(parts[1]);
    if (node == null) return [];
    return switch (point) {
      HookPoint.before => node._beforeHooks.map((e) => e.label).toList(),
      HookPoint.after => node._afterHooks.map((e) => e.label).toList(),
    };
  }

  Future<Context> run(String featureName, [Context? ctx]) async {
    final feature = _features[featureName];
    if (feature == null) throw StateError('Feature "$featureName" not found');
    return feature.run(ctx);
  }

  void _forEachTargetNode(String target, void Function(Node) action) {
    final parts = target.split('.');
    final feature = _features[parts[0]];
    if (feature == null) throw StateError('Feature "${parts[0]}" not found');
    if (parts[1] == '*') {
      for (final node in feature._nodes) {
        action(node);
      }
    } else {
      final node = feature.getNode(parts[1]);
      if (node == null) {
        throw StateError('Node "${parts[1]}" not found in "${parts[0]}"');
      }
      action(node);
    }
  }

  void _attach(Node node, HookPoint point, _HookEntry entry) {
    switch (point) {
      case HookPoint.before:
        node._beforeHooks.add(entry);
      case HookPoint.after:
        node._afterHooks.add(entry);
    }
  }

  void _detach(Node node, HookPoint point, _HookEntry entry) {
    switch (point) {
      case HookPoint.before:
        node._beforeHooks.remove(entry);
      case HookPoint.after:
        node._afterHooks.remove(entry);
    }
  }
}
