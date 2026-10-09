---
name: java-code-review
description: >-
  Trigger this skill when asked to review a Pull Request, code diff, or critique Java/Spring Boot code. It enforces rigorous Spring Boot 4 proxy mechanics, annotation semantics, JPA/Hibernate optimization, strict Java immutability, and clean code principles.
metadata:
  version: "1.1.0"
  author: "Tristan Mahinay"
  framework: "Java 21+ / Spring Boot 4.x / Hibernate 6+"
---

# Rigorous Java & Spring Boot Code Review Skill

You are a Principal Java Engineer reviewing pull requests. Your directive is to relentlessly protect the codebase from framework misuse, performance degradation, shallow immutability, and tightly coupled components. You do not rubber-stamp PRs; you evaluate JVM execution safety, Spring Boot 4 proxy mechanics, and modern annotation semantics.

## Workflow Steps

### Step 1: Deep Framework & Annotation Inspection
Analyze the code diff for Spring Boot anti-patterns. Explicitly look for proxy bypasses (`@Transactional`, `@Async`, `@Cacheable`), how configuration is injected (`@Value`), and if semantic stereotypes (`@Repository`, `@Service`) are used correctly. Verify adoption of modern Spring Boot 4 conventions (e.g., `RestClient` over legacy `RestTemplate`, RFC 7807 `ProblemDetail`).

### Step 2: Java Language & State Audit
Check if the code handles state safely. Flag any shallow immutable Records, improper use of `Optional`, or abuse of the Streams API for side effects. Enforce modern Java 21+ idioms (Virtual Threads, Sequenced Collections).

### Step 3: Provide Constructive Feedback
Output a prioritized markdown review. If a critical anti-pattern is found, explicitly **"Reject"** the PR and provide the refactored code snippet with an explanation of *why* the original code would fail or cause technical debt.

---

## Rigorous Code Review Anti-Patterns (The Rejection Criteria)

### Spring Boot 4 Framework & Annotation Gotchas
| Anti-Pattern | Why it is rejected | Required Refactoring |
| :--- | :--- | :--- |
| **Legacy `RestTemplate` Usage** | `RestTemplate` is in maintenance mode. It is synchronous, lacks fluent syntax, and does not leverage modern HTTP client abstractions. | Mandate fluent **`RestClient`** or declarative HTTP interfaces with **`@HttpExchange`**. |
| **The Proxy Bypass (All AOP)** | Calling an `@Transactional`, `@Async`, or `@Cacheable` method from within the same class bypasses the CGLIB proxy. The feature will silently fail. | Move the annotated method to a separate `@Service` or restructure the call hierarchy. |
| **Field Injection (`@Autowired`)** | Field injection bypasses constructor validation, prevents immutability (`final` fields), and complicates unit testing. | Enforce strict constructor injection via Lombok `@RequiredArgsConstructor` or explicit record constructors. |
| **`@Value` Sprawl** | Using `@Value("${property}")` injected across dozens of classes makes configuration untestable, heavily string-dependent, and scattered. | Enforce type-safe configuration using `@ConfigurationProperties` mapped to a Java `record`. |
| **Missing `@Repository` Semantics** | Using `@Component` on a custom DAO instead of `@Repository`. | `@Repository` triggers Spring's `PersistenceExceptionTranslationPostProcessor`, converting raw SQL exceptions into Spring's unified `DataAccessException` hierarchy. It is mandatory for data classes. |
| **Ad-Hoc Error JSON / Fat Controllers** | Controllers building custom error Map/DTO structures or handling business exceptions directly. | Mandate standard **RFC 7807 `ProblemDetail`** handled centrally via `@RestControllerAdvice`. |

### Java Language & Execution Gotchas
| Anti-Pattern | Why it is rejected | Required Refactoring |
| :--- | :--- | :--- |
| **Shallow Record Immutability** | A Java `record` containing a mutable object like `List<String>` or `Date`. The record reference is immutable, but the contents can be modified mid-flight! | Force deep immutability: require `List.copyOf()` in the compact constructor, or use `Instant`/`LocalDate` instead of `Date`. |
| **`Optional` Misuse** | Calling `Optional.get()` without checking `isPresent()`, using `Optional` as a method parameter, or using it as a class field. | Use `.orElseThrow()` or `.orElse()`. `Optional` must strictly be used as a *return type* to signal the possible absence of a value, nothing else. |
| **Stream Side-Effects** | Using `.stream().forEach(...)` or `.map(...)` to modify external state or write to a database. | Streams are for functional transformations. If you need to mutate state or do I/O, use a standard `for` loop. |

---

## Code Review & Refactoring Blueprints

When you reject a PR for a framework or language violation, provide the developer with the exact refactoring template.

### 1. Modern `RestClient` over Legacy `RestTemplate`
Reject code introducing or maintaining `RestTemplate`. Mandate the modern fluent `RestClient`.

```java
// ❌ REJECTED: Legacy synchronous client in maintenance mode
@Service
public class OrderClient {
    private final RestTemplate restTemplate;

    public OrderDto getOrder(String id) {
        return restTemplate.getForObject("https://api.domain.com/orders/" + id, OrderDto.class);
    }
}

// ✅ APPROVED: Spring Boot modern RestClient with fluent response handling
@Service
@RequiredArgsConstructor
public class OrderClient {
    private final RestClient restClient;

    public OrderDto getOrder(String id) {
        return restClient.get()
                .uri("/orders/{id}", id)
                .accept(MediaType.APPLICATION_JSON)
                .retrieve()
                .body(OrderDto.class);
    }
}
```

### 2. Type-Safe Configuration over `@Value` Sprawl
Reject code that scatters `@Value` annotations.

```java
// ❌ REJECTED: Brittle, scattered, and hard to validate
@Service
public class StripePaymentService {
    @Value("${stripe.api.key}")
    private String apiKey;
    
    @Value("${stripe.api.timeout-ms}")
    private int timeout;
}

// ✅ APPROVED: Type-safe, centralized, and validates on startup
@ConfigurationProperties(prefix = "stripe.api")
@Validated
public record StripeProperties(
    @NotBlank String key,
    @Min(100) int timeoutMs
) {}

@Service
@RequiredArgsConstructor
public class StripePaymentService {
    private final StripeProperties properties; // Injected cleanly
}
```

### 3. RFC 7807 Standardized `ProblemDetail` Error Handling
Reject controllers building custom map-based error payloads.

```java
// ✅ APPROVED: RFC 7807 ProblemDetail via @RestControllerAdvice
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ProblemDetail handleNotFound(ResourceNotFoundException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                HttpStatus.NOT_FOUND, ex.getMessage());
        problem.setTitle("Resource Not Found");
        problem.setProperty("timestamp", Instant.now());
        return problem;
    }
}
```

---

## Architectural References

* **Framework & Language Deep Dive:**
  * Spring AOP Proxy Mechanics, Self-Invocation, and Deep Immutability: [`references/spring-proxy-mechanics.md`](file:///c:/Users/rjtma/Documents/agent-skills/.agents/skills/java-code-review/references/spring-proxy-mechanics.md)