---
name: java-test-engineering
description: >-
  Trigger this skill when asked to write, generate, or fix unit tests, slice tests, or integration tests for Java code. It enforces JUnit 5, Mockito, Testcontainers, Awaitility, AssertJ, and deep Spring Boot context management rules.
metadata:
  version: "1.0.0"
  author: "Tristan Mahinay"
  framework: "Java 21+ / Spring Boot 3.x / JUnit 5"
---

# Java Test Engineering Skill

You are an expert Java SDET (Software Development Engineer in Test). Your directive is to generate fast, reliable, and perfectly sliced test suites using BDD (Given/When/Then) structures. 

## Workflow Steps

### Step 1: Context & Strategy Ingestion
Identify the target component's architectural layer to determine the test slice:
* **Controller:** Use `@WebMvcTest`.
* **Service:** Use pure JUnit 5 + Mockito (No Spring Context).
* **Repository:** Use `@DataJpaTest`.
* **External/E2E:** Use `@SpringBootTest` with Testcontainers.

### Step 2: Test Generation
Generate the test classes using the approved blueprints below. Always use **AssertJ** (`assertThat`) for fluent assertions. Do not use legacy JUnit `assertEquals`.

---

## Test Generation Anti-Patterns (Gotchas)

| Anti-Pattern | Why it is rejected | Required Approach |
| :--- | :--- | :--- |
| **The `@MockBean` Context Cache Buster** | Arbitrary `@MockBean` usage forces Spring to reboot the context per test class. | Extend from a centralized `AbstractIntegrationTest` base class that holds all global `@MockBean` definitions. |
| **The `@Transactional` Mirage** | Auto-rollback hides `LazyInitializationException` and database constraint violations. | In `@DataJpaTest`, manually invoke `TestEntityManager.flush()` to force constraint checks before assertions. |
| **Manual JSON String Concatenation** | Hardcoding JSON strings is brittle and bypasses Jackson rules. | Use `ObjectMapper.writeValueAsString()` or Spring's `@JsonTest`. |
| **The `Thread.sleep()` Hack** | Hardcoding sleeps for async tests causes flaky builds. | Enforce **Awaitility** (`await().untilAsserted(...)`) to poll asynchronously. |
| **Mocking Data Objects (DTOs/Records)** | `when(mockDto.name()).thenReturn("test")` masks serialization/mapping errors. | Never mock simple data holders. Instantiate real `record` instances. |

---

## Code Templates & Blueprints

### 1. Pure Mockito Service Test (Lightning Fast)
```java
package com.gotchu.service;

import com.gotchu.dto.WalletRecord;
import com.gotchu.repository.WalletRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;

@ExtendWith(MockitoExtension.class)
class WalletServiceTest {

    @Mock
    private WalletRepository repository;

    @InjectMocks
    private WalletService underTest;

    @Test
    void shouldFundWalletSuccessfully() {
        // Given
        WalletRecord input = new WalletRecord("usr-123", 500.00);
        given(repository.save(any())).willReturn(input);

        // When
        WalletRecord result = underTest.fund(input);

        // Then
        assertThat(result.amount()).isEqualTo(500.00);
    }
}
```

---

## Test Engineering Architecture References

* **Integration & Context Caching Deep Dive:**
  * Testcontainers `@ServiceConnection`, Singleton Containers, and Spring Test Context Caching: [`references/testcontainers-guide.md`](file:///c:/Users/rjtma/Documents/agent-skills/.agents/skills/java-test-engineering/references/testcontainers-guide.md)