# feature-engine

The generic runtime that powers all features — Engine, Feature, Node, Context, HookHandle.

**Purpose**: Provide a pipeline execution model where named nodes run in sequence, with extensibility via before/after hooks that can observe, mutate, or abort the pipeline.

**Public surface**:
- `Engine.feature(name)` — register or retrieve a feature
- `Engine.bind(target, point, label, fn)` — attach a static hook
- `Engine.dynamicBind(target, point, label, fn)` — attach a hook, returns `HookHandle` for unbinding
- `Engine.run(featureName, [ctx])` — execute a feature pipeline
- `Engine.hooksOn(target, point)` — introspect hook labels on a node
- `Feature.addNode(name, action)` — append a node to the pipeline
- `Feature.run([ctx])` — execute this feature's pipeline
- `Context.abort(reason)` — short-circuit the pipeline

**Key types**:
- `Engine` — registry of features, hook dispatcher
- `Feature` — ordered list of nodes
- `Node` — single pipeline step with before/after hook lists
- `Context` — shared mutable state (`data` map + `trace` log + abort flag)
- `HookHandle` — bound/unbound lifecycle for dynamic hooks
- `HookPoint` — enum: `before`, `after`
- `TraceEntry` — structured trace record (feature, node, phase, hookLabel)

**Target addressing**: hooks target `"feature.node"` or `"feature.*"` (wildcard = all nodes in that feature).

**Execution order per node**: before hooks (in registration order) → node action → after hooks. If any before hook calls `ctx.abort()`, the node action and remaining pipeline are skipped.

**Owns**: pipeline execution, hook dispatch, context lifecycle, trace recording, dynamic bind/unbind.

**Does not own**: domain logic, feature definitions, wiring decisions, UI.
