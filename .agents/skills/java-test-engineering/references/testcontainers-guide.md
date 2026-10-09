# Enterprise Spring Boot Testcontainers & Context Optimization Guide

This reference provides architectural blueprints for fast, non-flaky integration testing using Testcontainers and Spring Boot 4.x features.

---

## 1. Modern `@ServiceConnection` (Spring Boot 4.x)

Legacy Spring Boot required manual `@DynamicPropertySource` methods to bind dynamic container ports into Spring environment properties. Modern Spring Boot provides `@ServiceConnection`, which automatically discovers and auto-configures the connection details:

### ❌ Legacy Pattern (Verbose & Repetitive):
```java
@Container
static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

@DynamicPropertySource
static void configureProperties(DynamicPropertyRegistry registry) {
    registry.add("spring.datasource.url", postgres::getJdbcUrl);
    registry.add("spring.datasource.username", postgres::getUsername);
    registry.add("spring.datasource.password", postgres::getPassword);
}
```

### ✅ Modern Spring Boot Pattern:
```java
@Container
@ServiceConnection
static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");
// Connection details (url, username, password, driver) automatically mapped!
```

---

## 2. The Singleton Container Pattern (Preventing Container Churn)

Spinning up containers per test class kills CI pipeline performance. Use an abstract base class or Testcontainers' static singleton lifecycle:

```java
public abstract class AbstractIntegrationTest {

    @ServiceConnection
    protected static final PostgreSQLContainer<?> POSTGRES =
        new PostgreSQLContainer<>("postgres:16-alpine")
            .withReuse(true);

    static {
        POSTGRES.start();
    }
}
```

Every integration test inheriting from `AbstractIntegrationTest` shares the single running container instance across the test run.

---

## 3. Protecting the Spring Test Context Cache

Spring caches the `ApplicationContext` across test classes unless the configuration signature changes.

### Context Cache Busters to Avoid:
* **Arbitrary `@MockBean` / `@MockitoBean`:** Each variation in `@MockBean` signatures produces a distinct context key, forcing Spring to restart the entire application context for that class.
* **`@DirtiesContext`:** Forces context destruction and recreation. Only use when external static state is corrupted.
* **Dynamic Profiles (`@ActiveProfiles`):** Swapping active profiles between test classes forces new context instances. Group tests by profile into common base classes.

---

## 4. Asynchronous Testing with Awaitility

Never use `Thread.sleep()` to wait for asynchronous events (e.g. Kafka consumers, scheduled jobs, async events). It causes non-deterministic build failures.

```java
import static org.awaitility.Awaitility.await;
import static java.util.concurrent.TimeUnit.SECONDS;

@Test
void shouldConsumeMessageAsynchronously() {
    eventProducer.publish(new OrderCreatedEvent("ord-123"));

    await()
        .atMost(5, SECONDS)
        .pollInterval(100, java.util.concurrent.TimeUnit.MILLISECONDS)
        .untilAsserted(() -> {
            assertThat(repository.findByOrderId("ord-123")).isPresent();
        });
}
```
