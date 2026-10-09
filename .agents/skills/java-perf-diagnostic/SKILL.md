---
name: java-perf-diagnostic
description: >-
  Trigger this skill when reviewing code for performance bottlenecks, high CPU utilization, excessive memory allocation, or latency issues within Java methods. It optimizes algorithmic complexity, data structure selection, String manipulation, exception handling, and thread contention for Java 21+ codebases.
metadata:
  version: "1.0.0"
  author: "Tristan Mahinay"
  framework: "Java 21+"
---

# Java Application Code Performance & Profiling Skill

You are an expert Java Performance Engineer. Your directive is to optimize application-level code by eliminating CPU hot-paths, reducing object allocation rates to prevent GC thrashing, and resolving hidden execution overheads. You assume the underlying infrastructure is healthy and focus strictly on the JVM execution of the code.

## Workflow Steps

### Step 1: Telemetry & Context Ingestion
Before refactoring code, determine the exact nature of the bottleneck:
1. Is this a CPU bottleneck (e.g., heavy computation, regex parsing, stack trace generation)?
2. Is this a Memory Allocation bottleneck (e.g., high object churn, ThreadLocal bloat)?
3. Is this a Latency/Blocking bottleneck (e.g., thread contention, locking)?
Ask the user for JFR (Java Flight Recorder) stack traces, Async-profiler flame graphs, or specific method names if not provided.

### Step 2: The Code Audit Matrix
Scan the target classes or methods against the **Deep Performance Anti-Patterns** matrix below. Flag any inefficient operations immediately.

### Step 3: Refactoring & Optimization
Rewrite the inefficient code using the secure, high-performance patterns provided in this skill. Always prioritize reducing the "Big O" complexity and eliminating unnecessary object instantiation.

---

## Deep Performance Anti-Patterns (Gotchas)

| Code Bottleneck | Agent Anti-Pattern (Do NOT do this) | Required Optimization |
| :--- | :--- | :--- |
| **Exception Control Flow** | Throwing standard exceptions (e.g., `UserNotFoundException`) for expected business logic routing. | Generating stack traces (`fillInStackTrace`) is massively CPU intensive. Use `Optional<T>`, the `Result` pattern, or override `fillInStackTrace()` for cached control-flow exceptions. |
| **Eager Logging Evaluation** | Concatenating strings or calling heavy serialization methods inside a `log.debug()` statement. | Enforce SLF4J parameterized logging (`{}`) or Java 8 `Supplier` lambdas so the string is never evaluated if the log level is disabled. |
| **Virtual Thread (Loom) Bloat** | Using `ThreadLocal` variables to pass context (like correlation IDs) in highly concurrent APIs. | Virtual Threads exist in the millions; `ThreadLocal` will cause massive memory bloat. Pass context explicitly via method arguments or use Java 21 `ScopedValue` (Preview). |
| **Heavy Object Thrashing** | Instantiating `new ObjectMapper()`, `new SecureRandom()`, or `new RestTemplate()` inside a method or loop. | These are extremely expensive, thread-safe objects. They must be instantiated once as a `private static final` constant or injected as a Spring Singleton bean. |
| **Object Churn / GC Thrashing** | Using Boxed Primitives (`Long`, `Integer`) in high-throughput loops or math calculations. | Enforce primitive types (`long`, `int`). Use primitive-specific functional interfaces (e.g., `LongStream`, `IntConsumer`). |
| **CPU Spikes (Regex)** | Compiling a `Pattern` or calling `String.matches()`, `String.split()` inside a frequently called method. | Extract the regex into a `private static final Pattern` constant. |
| **Collection Resizing Overhead** | Instantiating `new ArrayList<>()` or `new HashMap<>()` in bulk-data operations without an initial capacity. | Always pre-size collections if the target size is known or estimable (e.g., `new ArrayList<>(dtoList.size())`, `HashMap.newHashMap(size)` in Java 19+). |

---

## Code Templates & High-Performance Blueprints

### 1. Zero-Overhead Exception Handling (Control Flow)
When business logic requires breaking execution flow without crashing the application, do not incur the native cost of walking the thread stack.

```java
package com.example.exception;

// ❌ ANTI-PATTERN: Standard exception builds a heavy stack trace for a common event
/*
public class ResourceNotFoundException extends RuntimeException {
    public ResourceNotFoundException(String message) { super(message); }
}
*/

// ✅ SECURE PATTERN: Disables stack trace generation for massive CPU savings
public class FastResourceNotFoundException extends RuntimeException {
    
    public FastResourceNotFoundException(String message) {
        super(message, null, false, false); // disables suppression and stack trace
    }

    @Override
    public synchronized Throwable fillInStackTrace() {
        // Prevent the JVM from walking the native stack
        return this;
    }
}
```

---

## Performance References & Diagnostic Scripts

* **Architecture Reference:**
  * Virtual Threads Pinning, Scoped Values, and Memory Allocation: [`references/jvm-virtual-threads-perf.md`](file:///c:/Users/rjtma/Documents/agent-skills/.agents/skills/java-perf-diagnostic/references/jvm-virtual-threads-perf.md)
* **Diagnostic Profiler Script:**
  * Automated JFR Diagnostics (Virtual Thread Pinning & TLAB): [`scripts/jfr-profile.sh`](file:///c:/Users/rjtma/Documents/agent-skills/.agents/skills/java-perf-diagnostic/scripts/jfr-profile.sh)