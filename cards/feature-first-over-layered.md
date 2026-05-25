# feature-first-over-layered

Features are peers with their own pipelines, not layers in a shared stack.

**The choice**: organize code by feature (place-order, inventory) rather than by layer (controllers, services, models). Each feature defines its own pipeline of nodes. Cross-feature interaction happens exclusively through hooks — no feature imports another.

**Alternatives considered**:
- **Layered architecture** — controllers call services call repositories. Simple but creates horizontal coupling: adding a discount touches the controller, service, and model layers.
- **Event bus** — features publish/subscribe to events. Decoupled but harder to reason about ordering, no natural short-circuit, trace is scattered.
- **Direct imports** — features call each other's functions. Fast to write but creates a dependency graph that becomes circular as features grow.

**Why this won**: hooks give explicit extension points with clear ordering (before/after), built-in short-circuit (abort), and introspectable wiring (hooksOn). Features stay isolated — the wiring layer (`demo_setup.dart`) is the only file that knows about multiple features. Adding behavior to an existing pipeline requires zero changes to that pipeline's code.

**When to revisit**: if the number of features exceeds ~20 and the wiring file becomes a bottleneck, or if hook execution order between multiple hooks on the same node becomes hard to reason about. At that point, consider explicit priority ordering or a dependency-aware hook scheduler.
