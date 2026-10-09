# Spring Boot AOP Proxy Mechanics & Immutability Architecture Reference

This reference documents the internal execution mechanics of Spring's CGLIB Dynamic Proxies, transactional boundaries, and Java immutability rules.

---

## 1. Spring AOP Proxy Mechanics (Self-Invocation Pitfall)

Spring's declarative features (`@Transactional`, `@Async`, `@Cacheable`, `@Retryable`) rely on Spring AOP proxy interception:

```text
External Caller
       │
       ▼
┌──────────────────────────────────────────────┐
│ Spring AOP Proxy (CGLIB / Dynamic Proxy)     │
│  - Begins Transaction / Intercepts Cache     │
└──────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────┐
│ Actual Target Bean Method (e.g. methodA())   │
│                                              │
│   this.methodB(); ───► Direct JVM Call       │
│   (Bypasses Proxy! @Transactional ignored!)  │
└──────────────────────────────────────────────┘
```

### Self-Invocation Failure Example:
```java
@Service
public class OrderService {

    public void processOrder(Order order) {
        // ❌ Direct 'this' invocation bypasses proxy
        saveWithAudit(order); 
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void saveWithAudit(Order order) {
        // NEVER RUNS IN A NEW TRANSACTION!
        repository.save(order);
    }
}
```

### Approved Architectures:
1. **Separation of Concerns:** Move `saveWithAudit()` to a dedicated collaborator service (e.g. `OrderAuditService`).
2. **Self-Injection:** Inject the proxy instance via `@Lazy OrderService self` (acceptable fallback).

---

## 2. Deep Immutability for Java Records

Java `record` components provide **shallow immutability** by default: the component fields are `final`, but the referenced data structures may still be mutable.

### ❌ Shallow Immutability Anti-Pattern:
```java
// Vulnerable to mutation: caller can do payload.tags().add("injected")
public record Payload(String id, List<String> tags) {}
```

### ✅ Deep Immutability Pattern:
```java
public record Payload(String id, List<String> tags) {
    // Compact constructor enforces unmodifiable snapshot
    public Payload {
        tags = List.copyOf(tags);
    }
}
```

### Prohibited Component Types in Records:
* `java.util.Date` or `java.util.Calendar` $\rightarrow$ Replace with `java.time.Instant`, `java.time.LocalDate`.
* Raw arrays (`byte[]`, `int[]`) $\rightarrow$ Defensively copy in constructor and getter, or use immutable wrapper classes.
* Mutable POJOs $\rightarrow$ All nested entities must themselves be immutable records.

---

## 3. Functional Streams vs Imperative Loops

* **Streams (`java.util.stream.Stream`):** Pure functional pipeline for map/filter/reduce transformations. No side-effects.
* **Loops (`for` / `forEach`):** Mandatory for mutating state, triggering I/O, writing to databases, or emitting messages.

```java
// ❌ ANTI-PATTERN: Side-effecting stream doing database I/O
orders.stream().forEach(order -> repository.save(order));

// ✅ REQUIRED: Explicit imperative iteration
for (Order order : orders) {
    repository.save(order);
}
```
