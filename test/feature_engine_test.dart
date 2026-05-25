import 'package:flutter_test/flutter_test.dart';
import 'package:feature_first_example/feature_engine.dart';
import 'package:feature_first_example/demo_setup.dart';
import 'package:feature_first_example/features/place_order/place_order.dart';
import 'package:feature_first_example/features/inventory/inventory.dart';

void main() {
  group('Pipeline execution', () {
    test('nodes run in declared order', () async {
      final engine = Engine();
      final f = engine.feature('f');
      f.addNode('a', (ctx) async => ctx['order'] = '${ctx['order'] ?? ''}a');
      f.addNode('b', (ctx) async => ctx['order'] = '${ctx['order'] ?? ''}b');
      f.addNode('c', (ctx) async => ctx['order'] = '${ctx['order'] ?? ''}c');

      final ctx = await engine.run('f');

      expect(ctx['order'], 'abc');
      expect(ctx.executedNodes, ['a', 'b', 'c']);
    });

    test('context flows through the entire pipeline', () async {
      final engine = Engine();
      final f = engine.feature('math');
      f.addNode('start', (ctx) async => ctx['value'] = 10);
      f.addNode('double', (ctx) async => ctx['value'] = ctx['value'] * 2);
      f.addNode('add_one', (ctx) async => ctx['value'] = ctx['value'] + 1);

      final ctx = await engine.run('math');

      expect(ctx['value'], 21);
    });
  });

  group('Before hooks', () {
    test('run before the node action', () async {
      final engine = Engine();
      final f = engine.feature('f');
      f.addNode('step', (ctx) async => ctx['log'] = '${ctx['log']}action,');

      engine.bind('f.step', HookPoint.before, 'pre', (ctx, node) async {
        ctx['log'] = '${ctx['log'] ?? ''}before,';
      });

      final ctx = await engine.run('f');

      expect(ctx['log'], 'before,action,');
    });

    test('can short-circuit a node', () async {
      final engine = Engine();
      final f = engine.feature('f');
      f.addNode('guarded', (ctx) async => ctx['ran'] = true);
      f.addNode('next', (ctx) async => ctx['next_ran'] = true);

      engine.bind('f.guarded', HookPoint.before, 'guard', (ctx, node) async {
        ctx.abort('blocked');
      });

      final ctx = await engine.run('f');

      expect(ctx.isAborted, true);
      expect(ctx.abortReason, 'blocked');
      expect(ctx.abortedAt, 'f.guarded.before');
      expect(ctx['ran'], null);
      expect(ctx['next_ran'], null);
      expect(ctx.executedNodes, isEmpty);
    });

    test('multiple before hooks run in registration order', () async {
      final engine = Engine();
      final f = engine.feature('f');
      f.addNode('step', (ctx) async {});

      engine.bind('f.step', HookPoint.before, 'first', (ctx, node) async {
        ctx['order'] = '${ctx['order'] ?? ''}1,';
      });
      engine.bind('f.step', HookPoint.before, 'second', (ctx, node) async {
        ctx['order'] = '${ctx['order'] ?? ''}2,';
      });

      final ctx = await engine.run('f');

      expect(ctx['order'], '1,2,');
    });
  });

  group('After hooks', () {
    test('run after the node action and can read output', () async {
      final engine = Engine();
      final f = engine.feature('f');
      f.addNode('produce', (ctx) async => ctx['value'] = 42);

      engine.bind('f.produce', HookPoint.after, 'reader', (ctx, node) async {
        ctx['observed'] = ctx['value'];
      });

      final ctx = await engine.run('f');

      expect(ctx['observed'], 42);
    });

    test('can modify context for downstream nodes', () async {
      final engine = Engine();
      final f = engine.feature('f');
      f.addNode('first', (ctx) async => ctx['value'] = 10);
      f.addNode('second', (ctx) async => ctx['doubled'] = ctx['value'] * 2);

      engine.bind('f.first', HookPoint.after, 'modifier', (ctx, node) async {
        ctx['value'] = ctx['value'] + 5;
      });

      final ctx = await engine.run('f');

      expect(ctx['value'], 15);
      expect(ctx['doubled'], 30);
    });

    test('abort in after hook stops remaining after hooks on same node',
        () async {
      final engine = Engine();
      final f = engine.feature('f');
      f.addNode('step', (ctx) async {});
      f.addNode('next', (ctx) async => ctx['next_ran'] = true);

      engine.bind('f.step', HookPoint.after, 'first', (ctx, node) async {
        ctx['first_ran'] = true;
        ctx.abort('stop');
      });
      engine.bind('f.step', HookPoint.after, 'second', (ctx, node) async {
        ctx['second_ran'] = true;
      });

      final ctx = await engine.run('f');

      expect(ctx.isAborted, true);
      expect(ctx['first_ran'], true);
      expect(ctx['second_ran'], null);
      expect(ctx['next_ran'], null);
    });
  });

  group('Wildcard hooks', () {
    test('attach to all existing nodes in a feature', () async {
      final engine = Engine();
      final f = engine.feature('f');
      f.addNode('a', (ctx) async {});
      f.addNode('b', (ctx) async {});
      f.addNode('c', (ctx) async {});

      engine.bind('f.*', HookPoint.after, 'observer', (ctx, node) async {
        final seen = (ctx['seen'] as List<String>?) ?? [];
        seen.add(node);
        ctx['seen'] = seen;
      });

      final ctx = await engine.run('f');

      expect(ctx['seen'], ['a', 'b', 'c']);
    });
  });

  group('Dynamic hooks', () {
    test('can be bound and unbound at runtime', () async {
      final engine = Engine();
      final f = engine.feature('f');
      f.addNode('step', (ctx) async {});

      final handle = engine.dynamicBind(
        'f.step',
        HookPoint.before,
        'dynamic',
        (ctx, node) async => ctx['hooked'] = true,
      );

      var ctx = await engine.run('f');
      expect(ctx['hooked'], true);

      handle.unbind();

      ctx = await engine.run('f');
      expect(ctx['hooked'], null);
    });

    test('unbinding one hook does not affect others', () async {
      final engine = Engine();
      final f = engine.feature('f');
      f.addNode('step', (ctx) async {});

      engine.bind('f.step', HookPoint.before, 'static', (ctx, node) async {
        ctx['static'] = true;
      });

      final handle = engine.dynamicBind(
        'f.step',
        HookPoint.before,
        'dynamic',
        (ctx, node) async => ctx['dynamic'] = true,
      );

      handle.unbind();

      final ctx = await engine.run('f');
      expect(ctx['static'], true);
      expect(ctx['dynamic'], null);
    });

    test('wildcard dynamic hooks unbind from all nodes', () async {
      final engine = Engine();
      final f = engine.feature('f');
      f.addNode('a', (ctx) async {});
      f.addNode('b', (ctx) async {});

      final handle = engine.dynamicBind(
        'f.*',
        HookPoint.after,
        'wildcard',
        (ctx, node) async {
          ctx['count'] = (ctx['count'] ?? 0) + 1;
        },
      );

      var ctx = await engine.run('f');
      expect(ctx['count'], 2);

      handle.unbind();

      ctx = await engine.run('f');
      expect(ctx['count'], null);
    });

    test('double unbind is safe', () async {
      final engine = Engine();
      final f = engine.feature('f');
      f.addNode('step', (ctx) async {});

      final handle = engine.dynamicBind(
        'f.step',
        HookPoint.before,
        'temp',
        (ctx, node) async => ctx['ran'] = true,
      );

      handle.unbind();
      handle.unbind(); // should not throw

      expect(handle.isBound, false);
    });
  });

  group('Bi-directional composition', () {
    test('two features can be middleware for each other', () async {
      final engine = Engine();

      final featureA = engine.feature('A');
      featureA.addNode('step1', (ctx) async => ctx['a1'] = true);
      featureA.addNode('step2', (ctx) async => ctx['a2'] = true);

      final featureB = engine.feature('B');
      featureB.addNode('step1', (ctx) async => ctx['b1'] = true);

      // A hooks into B
      engine.bind('B.step1', HookPoint.after, 'A', (ctx, node) async {
        ctx['a_saw_b'] = true;
      });

      // B hooks into A
      engine.bind('A.step1', HookPoint.after, 'B', (ctx, node) async {
        ctx['b_saw_a'] = true;
      });

      final ctxA = await engine.run('A');
      expect(ctxA['a1'], true);
      expect(ctxA['b_saw_a'], true);

      final ctxB = await engine.run('B');
      expect(ctxB['b1'], true);
      expect(ctxB['a_saw_b'], true);
    });

    test('feature can short-circuit another feature', () async {
      final engine = Engine();

      final order = engine.feature('order');
      order.addNode('validate', (ctx) async => ctx['validated'] = true);
      order.addNode('charge', (ctx) async => ctx['charged'] = true);

      engine.feature('inventory').addNode('check', (ctx) async {});

      engine.bind('order.validate', HookPoint.before, 'inventory',
          (ctx, node) async {
        if (ctx['item'] == 'unavailable') {
          ctx.abort('out of stock');
        }
      });

      final good = Context()..['item'] = 'available';
      await engine.run('order', good);
      expect(good.isAborted, false);
      expect(good['charged'], true);

      final bad = Context()..['item'] = 'unavailable';
      await engine.run('order', bad);
      expect(bad.isAborted, true);
      expect(bad['charged'], null);
    });

    test('running both features uses their mutual hooks', () async {
      final engine = Engine();

      final order = engine.feature('order');
      order.addNode('confirm', (ctx) async => ctx['confirmed'] = true);

      final inventory = engine.feature('inventory');
      inventory.addNode('check', (ctx) async {
        ctx['stock'] = {'widget': 2};
      });
      inventory.addNode('low_stock', (ctx) async {
        ctx['low'] = true;
      });

      // order -> inventory: react to low stock
      engine.bind('inventory.low_stock', HookPoint.after, 'order',
          (ctx, node) async {
        ctx['order_alerted'] = true;
      });

      // inventory -> order: decrement stock
      engine.bind('order.confirm', HookPoint.after, 'inventory',
          (ctx, node) async {
        ctx['stock_decremented'] = true;
      });

      // run order — inventory's hook fires
      final orderCtx = await engine.run('order');
      expect(orderCtx['confirmed'], true);
      expect(orderCtx['stock_decremented'], true);

      // run inventory — order's hook fires
      final invCtx = await engine.run('inventory');
      expect(invCtx['low'], true);
      expect(invCtx['order_alerted'], true);
    });
  });

  group('Execution trace', () {
    test('records full execution history with feature names', () async {
      final engine = Engine();
      final f = engine.feature('order');
      f.addNode('a', (ctx) async {});
      f.addNode('b', (ctx) async {});

      engine.bind('order.a', HookPoint.before, 'pre', (ctx, node) async {});
      engine.bind('order.b', HookPoint.after, 'post', (ctx, node) async {});

      final ctx = await engine.run('order');

      expect(ctx.traceLog, [
        'order.a.before [pre]',
        'order.a.action',
        'order.b.action',
        'order.b.after [post]',
      ]);
    });

    test('trace shows where abort happened with feature name', () async {
      final engine = Engine();
      final f = engine.feature('order');
      f.addNode('a', (ctx) async {});
      f.addNode('b', (ctx) async {});

      engine.bind(
          'order.a', HookPoint.before, 'blocker', (ctx, node) async {
        ctx.abort('nope');
      });

      final ctx = await engine.run('order');

      expect(ctx.traceLog, [
        'order.a.before [blocker]',
        'order.a.abort [blocker]',
      ]);
      expect(ctx.abortedAt, 'order.a.before');
    });

    test('trace disambiguates same-named nodes across features', () async {
      final engine = Engine();
      engine.feature('A').addNode('step', (ctx) async {});
      engine.feature('B').addNode('step', (ctx) async {});

      final ctxA = await engine.run('A');
      final ctxB = await engine.run('B');

      expect(ctxA.traceLog, ['A.step.action']);
      expect(ctxB.traceLog, ['B.step.action']);
    });
  });

  group('Hook introspection', () {
    test('can list hooks bound to a node', () async {
      final engine = Engine();
      final f = engine.feature('f');
      f.addNode('step', (ctx) async {});

      engine.bind('f.step', HookPoint.before, 'auth', (ctx, node) async {});
      engine.bind(
          'f.step', HookPoint.before, 'logging', (ctx, node) async {});
      engine.bind(
          'f.step', HookPoint.after, 'metrics', (ctx, node) async {});

      expect(engine.hooksOn('f.step', HookPoint.before), ['auth', 'logging']);
      expect(engine.hooksOn('f.step', HookPoint.after), ['metrics']);
    });

    test('dynamic unbind is reflected in introspection', () async {
      final engine = Engine();
      final f = engine.feature('f');
      f.addNode('step', (ctx) async {});

      final handle = engine.dynamicBind(
          'f.step', HookPoint.before, 'temp', (ctx, node) async {});

      expect(engine.hooksOn('f.step', HookPoint.before), ['temp']);

      handle.unbind();

      expect(engine.hooksOn('f.step', HookPoint.before), isEmpty);
    });
  });

  group('Demo setup', () {
    test('successful order runs all nodes with analytics', () async {
      final engine = buildDemoEngine();
      final ctx = makeCart([
        {'name': 'widget', 'price': 29.99},
        {'name': 'doohickey', 'price': 9.99},
      ]);

      await engine.run('place-order', ctx);

      expect(ctx.isAborted, false);
      expect(ctx.validated, true);
      expect(ctx.total, 39.98);
      expect(ctx.paymentStatus, 'charged');
      expect(ctx.orderId, startsWith('ORD-'));
      expect(ctx.metrics, ['validate_cart', 'calculate_totals',
          'charge_payment', 'confirm_order']);
    });

    test('out-of-stock item is blocked by inventory hook', () async {
      final engine = buildDemoEngine();
      final ctx = makeCart([
        {'name': 'gadget', 'price': 49.99},
      ]);

      await engine.run('place-order', ctx);

      expect(ctx.isAborted, true);
      expect(ctx.abortReason, 'Out of stock: gadget');
      expect(ctx['payment_status'], null); // never reached
    });

    test('inventory pipeline triggers place-order alert hook', () async {
      final engine = buildDemoEngine();

      final ctx = await engine.run('inventory');

      expect(ctx.lowStockItems, contains('gadget'));
      expect(ctx.customerAlert, contains('gadget'));
    });

    test('dynamic holiday discount modifies totals', () async {
      final engine = buildDemoEngine();

      final handle = engine.dynamicBind(
        'place-order.calculate_totals',
        HookPoint.before,
        'holiday',
        (ctx, node) async {
          final d = ctx.discounts;
          d.add(5.0);
          ctx.discounts = d;
        },
      );

      final ctx = makeCart([
        {'name': 'widget', 'price': 29.99},
      ]);
      await engine.run('place-order', ctx);
      expect(ctx.total, 24.99);

      handle.unbind();

      final ctx2 = makeCart([
        {'name': 'widget', 'price': 29.99},
      ]);
      await engine.run('place-order', ctx2);
      expect(ctx2.total, 29.99);
    });
  });

  group('Real-world scenario: order with plugins', () {
    test('full pipeline with static + dynamic hooks composes correctly',
        () async {
      final engine = Engine();

      final order = engine.feature('order');
      order.addNode('validate', (ctx) async => ctx['valid'] = true);
      order.addNode('price', (ctx) async {
        final base = ctx['base_price'] as double;
        final discounts = (ctx['discounts'] as List<double>?) ?? [];
        ctx['total'] = discounts.fold(base, (t, d) => t - d);
      });
      order.addNode('pay', (ctx) async => ctx['paid'] = true);
      order.addNode('confirm', (ctx) async => ctx['confirmed'] = true);

      // static: inventory checks stock
      engine.bind('order.validate', HookPoint.before, 'inventory',
          (ctx, node) async {
        if (ctx['out_of_stock'] == true) ctx.abort('no stock');
      });

      // static: analytics observes all
      engine.bind('order.*', HookPoint.after, 'analytics',
          (ctx, node) async {
        final events = (ctx['events'] as List<String>?) ?? [];
        events.add(node);
        ctx['events'] = events;
      });

      // dynamic: holiday discount
      final holiday = engine.dynamicBind(
        'order.price',
        HookPoint.before,
        'holiday',
        (ctx, node) async {
          final d = (ctx['discounts'] as List<double>?) ?? [];
          d.add(10.0);
          ctx['discounts'] = d;
        },
      );

      final ctx = Context()
        ..['base_price'] = 100.0
        ..['out_of_stock'] = false;
      await engine.run('order', ctx);

      expect(ctx['valid'], true);
      expect(ctx['total'], 90.0);
      expect(ctx['paid'], true);
      expect(ctx['confirmed'], true);
      expect(ctx['events'], ['validate', 'price', 'pay', 'confirm']);
      expect(ctx.executedNodes, ['validate', 'price', 'pay', 'confirm']);

      // unbind holiday, price goes back to base
      holiday.unbind();

      final ctx2 = Context()
        ..['base_price'] = 100.0
        ..['out_of_stock'] = false;
      await engine.run('order', ctx2);

      expect(ctx2['total'], 100.0);
    });
  });
}
