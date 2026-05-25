import 'package:flutter/material.dart';
import 'feature_engine.dart';
import 'demo_setup.dart';
import 'widgets/log_view.dart';
import 'widgets/control_panel.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  late Engine _engine;
  final List<LogLine> _log = [];
  final _scrollController = ScrollController();

  HookHandle? _holidayHandle;
  HookHandle? _debugHandle;

  bool _holidayActive = false;
  bool _fraudActive = false;
  bool _debugActive = false;

  @override
  void initState() {
    super.initState();
    _engine = buildDemoEngine();
  }

  void _addLog(String text, {LogType type = LogType.node}) {
    setState(() {
      _log.add(LogLine(text, type));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _appendTrace(Context ctx) {
    for (final entry in ctx.trace) {
      final type = switch (entry.phase) {
        'before' || 'after' => LogType.hook,
        'abort' => LogType.result,
        _ => LogType.node,
      };
      _addLog('  $entry', type: type);
    }
  }

  Future<void> _runOrder(List<Map<String, dynamic>> cart,
      {String? risk, String? label}) async {
    _addLog(label ?? 'place-order', type: LogType.header);
    final ctx = makeCart(cart, risk: risk);

    HookHandle? perRequestFraud;
    if (_fraudActive && ctx['customer_risk'] == 'high') {
      perRequestFraud = _engine.dynamicBind(
        'place-order.charge_payment',
        HookPoint.before,
        'fraud',
        (ctx, node) async {},
      );
    }

    await _engine.run('place-order', ctx);
    perRequestFraud?.unbind();
    _appendTrace(ctx);

    if (ctx.isAborted) {
      _addLog('ABORTED at ${ctx.abortedAt}: ${ctx.abortReason}',
          type: LogType.result);
    } else {
      final metrics = (ctx['metrics'] as List<String>?) ?? [];
      _addLog(
          'order=${ctx['order_id']}  total=${ctx['total']}  metrics=${metrics.length} events',
          type: LogType.result);
    }
  }

  Future<void> _runInventory() async {
    _addLog('inventory', type: LogType.header);
    final ctx = await _engine.run('inventory');
    _appendTrace(ctx);
    final low = ctx['low_stock_items'] as List<String>? ?? [];
    final alert = ctx['customer_alert'] as String?;
    _addLog('low_stock=$low', type: LogType.result);
    if (alert != null) _addLog('  $alert', type: LogType.hook);
  }

  void _toggleHoliday() {
    setState(() {
      if (_holidayActive) {
        _holidayHandle?.unbind();
        _holidayHandle = null;
        _holidayActive = false;
        _addLog('[holiday_pricing] UNBOUND', type: LogType.hook);
      } else {
        _holidayHandle = _engine.dynamicBind(
          'place-order.calculate_totals',
          HookPoint.before,
          'holiday_pricing',
          (ctx, node) async {
            final discounts = (ctx['discounts'] as List<double>?) ?? [];
            discounts.add(5.0);
            ctx['discounts'] = discounts;
          },
        );
        _holidayActive = true;
        _addLog('[holiday_pricing] BOUND to place-order.calculate_totals.before',
            type: LogType.hook);
      }
    });
  }

  void _toggleFraud() {
    setState(() {
      _fraudActive = !_fraudActive;
      _addLog(
          _fraudActive
              ? '[fraud] ENABLED (per-request for high-risk customers)'
              : '[fraud] DISABLED',
          type: LogType.hook);
    });
  }

  void _toggleDebug() {
    setState(() {
      if (_debugActive) {
        _debugHandle?.unbind();
        _debugHandle = null;
        _debugActive = false;
        _addLog('[debug] UNBOUND', type: LogType.hook);
      } else {
        _debugHandle = _engine.dynamicBind(
          'place-order.*',
          HookPoint.before,
          'debug',
          (ctx, node) async {},
        );
        _debugActive = true;
        _addLog('[debug] BOUND to place-order.*.before', type: LogType.hook);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feature-First Structured')),
      body: Row(
        children: [
          SizedBox(
            width: 320,
            child: ControlPanel(
              actions: [
                ActionItem('Order: widget + doohickey', Icons.shopping_cart,
                    () => _runOrder([
                          {'name': 'widget', 'price': 29.99},
                          {'name': 'doohickey', 'price': 9.99},
                        ], label: 'Order (widget + doohickey)')),
                ActionItem('Order: gadget (out of stock)',
                    Icons.remove_shopping_cart,
                    () => _runOrder([
                          {'name': 'gadget', 'price': 49.99},
                        ], label: 'Order (gadget - out of stock)')),
                ActionItem('Order: high-risk customer', Icons.warning_amber,
                    () => _runOrder([
                          {'name': 'widget', 'price': 29.99},
                        ], risk: 'high', label: 'Order (high-risk customer)')),
                ActionItem(
                    'Run inventory check', Icons.inventory, _runInventory),
              ],
              toggles: [
                ToggleItem('Holiday pricing (-\$5)',
                    'place-order.calculate_totals.before',
                    _holidayActive, _toggleHoliday),
                ToggleItem('Fraud check (per-request)',
                    'place-order.charge_payment.before',
                    _fraudActive, _toggleFraud),
                ToggleItem('Debug observer', 'place-order.*.before',
                    _debugActive, _toggleDebug),
              ],
              staticHooks: [
                StaticHookItem('inventory -> place-order',
                    'validate_cart.before', 'Stock check'),
                StaticHookItem('place-order -> inventory',
                    'low_stock.after', 'Customer alert'),
                StaticHookItem('analytics -> place-order',
                    '*.after', 'Observe all'),
              ],
              onClearLog: () => setState(() => _log.clear()),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: LogView(lines: _log, controller: _scrollController),
          ),
        ],
      ),
    );
  }
}
