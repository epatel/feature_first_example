# Feature-First Structured Example

A Flutter demo of feature-first architecture where each feature is a pipeline of hookable nodes. Features are isolated peers that extend each other through before/after hooks — no feature imports another. Built with Flutter 3 + Dart 3, no external dependencies beyond Flutter SDK.

## Cards

### Architecture
- [architecture](cards/architecture.md) — cross-domain work, dataflow, onboarding

### Domains
- [feature-engine](cards/feature-engine.md) — modifying Engine, Feature, Node, Context, or HookHandle
- [place-order](cards/place-order.md) — touching order pipeline, cart, totals, payment, or confirmation
- [inventory](cards/inventory.md) — touching stock levels, low-stock detection, or warehouse queries

### Features
- [hook-wiring](cards/hook-wiring.md) — adding/changing hooks, understanding static vs dynamic wiring

### Decisions
- [feature-first-over-layered](cards/feature-first-over-layered.md) — why features-as-peers instead of layered or event-bus architecture

## Adding a new feature

1. Create `lib/features/<name>/` with `<name>.dart` and `CLAUDE.md`
2. Define the feature pipeline in `<name>.dart` — register nodes with `engine.feature('<name>')`
3. Wire hooks in `lib/demo_setup.dart` — read target feature's card for context keys and hook guidance
4. Add a card under `cards/` and add it to the index above
5. Update the target feature's card — add your hook under "Hooked by"
6. Write tests in `test/` — use `ctx.traceLog` to verify hooks fire at the right nodes

## Testing

```
flutter test test/feature_engine_test.dart
```

26 tests covering: pipeline execution, before/after hooks, short-circuit, wildcard, dynamic bind/unbind, bi-directional composition, execution trace, hook introspection, and demo setup integration.
