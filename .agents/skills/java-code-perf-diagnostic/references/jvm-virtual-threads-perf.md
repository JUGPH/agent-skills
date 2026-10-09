# Java 21+ JVM Performance, Virtual Threads & Memory Optimization Guide

This reference documents the low-level execution mechanics, memory profiling rules, and concurrency patterns for high-throughput Java 21+ applications.

---

## 1. Virtual Threads (Project Loom) Architecture

Virtual Threads are lightweight threads managed by the JVM rather than the underlying operating system. They enable the "thread-per-request" style to achieve near-reactive throughput on I/O-bound workloads.

```text
Millions of Virtual Threads (Mounted on demand)
  [VT 1]  [VT 2]  [VT 3]  [VT 4] ... [VT 1,000,000]
    │       │       │       │
    ▼       ▼       ▼       ▼
┌──────────────────────────────────────────────┐
│ JVM Carrier Thread Pool (ForkJoinPool)       │
│ Sized to Available CPU Cores (e.g., 8 - 16)  │
└──────────────────────────────────────────────┘
    │
    ▼
[OS Platform Threads / Kernel Schedulers]
```

### The Critical Anti-Pattern: Virtual Thread Pinning
When a Virtual Thread executes a blocking operation inside a `synchronized` block or native method, it **pins** the carrier OS thread, preventing other virtual threads from running.

* **❌ PROHIBITED:**
  ```java
  public synchronized String fetchRemoteData() {
      return httpClient.send(request, HttpResponse.BodyHandlers.ofString()).body(); // PINS CARRIER THREAD!
  }
  ```
* **✅ REQUIRED:**
  ```java
  private final ReentrantLock lock = new ReentrantLock();

  public String fetchRemoteData() {
      lock.lock();
      try {
          return httpClient.send(request, HttpResponse.BodyHandlers.ofString()).body(); // Unmounts safely
      } finally {
          lock.unlock();
      }
  }
  ```

---

## 2. Context Propagation: `ScopedValue` vs `ThreadLocal`

* **`ThreadLocal` (Severe Hazard with Virtual Threads):**
  * Virtual Threads can exist in the millions. Giving each virtual thread a `ThreadLocal` map causes massive heap exhaustion and GC pressure.
* **`ScopedValue` (Java 21+ Preview / Modern Idiom):**
  * Immutable, shared across child virtual threads, and automatically discarded when execution leaves the dynamic scope:
  ```java
  public final static ScopedValue<SecurityContext> CURRENT_CONTEXT = ScopedValue.newInstance();

  // Binding within execution scope
  ScopedValue.runWhere(CURRENT_CONTEXT, tenantContext, () -> {
      orderService.processOrder(order);
  });
  ```

---

## 3. High-Allocation & GC Thrashing Defenses

| Optimization Area | Anti-Pattern | High-Performance Pattern |
| :--- | :--- | :--- |
| **Collection Growth** | `new ArrayList<>()` populated in a loop with 50,000 elements (triggers multiple array resizes and memory copies). | `new ArrayList<>(expectedSize)` or `HashMap.newHashMap(expectedSize)` in Java 19+. |
| **Sequenced Collections** | `list.get(list.size() - 1)` or manual iteration for tail elements. | `list.getLast()` (Java 21 `SequencedCollection`). Constant time $O(1)$ without index calculations. |
| **String Concatenation** | `str += item` inside loops. | `StringBuilder` initialized with estimated capacity, or String templates. |
| **Boxing Overhead** | `Stream<Long>` calculating sums. | `LongStream` or primitive arrays to avoid wrapper allocations. |

---

## 4. JFR Telemetry Events for Diagnostics

When diagnosing hot paths in production, capture these specific JFR events:
* **`jdk.VirtualThreadPinned`:** Flags any virtual threads pinned to carrier threads.
* **`jdk.ObjectAllocationInNewTLAB`:** Identifies which classes/methods churn memory fastest.
* **`jdk.JavaMonitorWait`:** Uncovers thread lock contention hot-spots.
