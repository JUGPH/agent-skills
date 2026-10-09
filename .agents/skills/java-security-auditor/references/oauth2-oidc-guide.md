# Enterprise Spring Security, OAuth 2.1 & OIDC Implementation Guide

This reference provides architectural standards, claim specifications, and security policies for Spring Boot 3.x and Spring Security 6.x services.

---

## 1. OAuth 2.1 Baseline Standard

OAuth 2.1 consolidates the core specifications and deprecates legacy, vulnerable grant types:

| Capability | OAuth 2.0 (Legacy) | OAuth 2.1 (Mandatory Standard) |
| :--- | :--- | :--- |
| **Authorization Code Flow** | PKCE was optional | **PKCE (Proof Key for Code Exchange) is mandatory** for all clients. |
| **Implicit Grant** | Allowed (`response_type=token`) | **Completely Removed** due to token leakage in browser history/URIs. |
| **Resource Owner Password Credentials** | Allowed (ROPC) | **Completely Removed**; client must never handle credentials directly. |
| **Redirect URIs** | Substring / wildcard matching allowed | **Exact URI matching strictly required**. |
| **Refresh Tokens** | Infinite or unrotated | **Sender-constrained or single-use refresh token rotation**. |

---

## 2. JWT Verification & Claims Taxonomy

When acting as an OAuth 2.1 Resource Server, the application must enforce asymmetric cryptographic validation via remote JWKS:

```properties
# application.yml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          jwk-set-uri: https://auth.enterprise.domain/oauth2/v1/keys
          issuer-uri: https://auth.enterprise.domain/oauth2/v1
```

### Essential Claims to Validate:
* **`iss` (Issuer):** Must match the authorized Identity Provider URI exactly.
* **`aud` (Audience):** Must match the resource server's client/API identifier. Reject tokens intended for other microservices.
* **`exp` (Expiration):** Must enforce clock skew tolerance $\le 60$ seconds.
* **`scp` or `scope`:** Space-delimited permissions granted by the resource owner.
* **`sub` (Subject):** Unique user identifier (UUID / subject principal).

---

## 3. Granular Method-Level Authorization (SpEL)

Global URL pattern matching (`requestMatchers`) only provides coarse boundary defense. Business logic must be protected by `@EnableMethodSecurity(prePostEnabled = true)`.

### Approved SpEL Patterns:
```java
// 1. Scope / Authority verification
@PreAuthorize("hasAuthority('SCOPE_payment:write')")
PaymentRecord processPayment(@Valid @RequestBody PaymentRequest request);

// 2. Role-based verification
@PreAuthorize("hasRole('ADMIN')")
void revokeTenant(@PathVariable UUID tenantId);

// 3. Object-Level Defense (BOLA / IDOR Prevention)
@PreAuthorize("hasRole('ADMIN') or #userId == authentication.principal.claims['sub']")
UserProfileRecord fetchProfile(@PathVariable String userId);
```

---

## 4. CORS & CSRF Decision Tree

```text
Is the application exposing a purely stateless API using Bearer tokens?
   │
   ├── YES:
   │    ├── CSRF: May be disabled (.csrf(AbstractHttpConfigurer::disable))
   │    └── Session: Must be stateless (SessionCreationPolicy.STATELESS)
   │
   └── NO (Cookie-backed authentication, session cookies, or browser front-ends):
        ├── CSRF: MANDATORY. Enforce CookieCsrfTokenRepository.withHttpOnlyFalse()
        └── SameSite: Set SameSite=Strict or Lax on session cookies
```

### CORS Security Rules:
* **Never** combine `allowCredentials(true)` with `allowedOrigins("*")`.
* Origins must be parameterized and injected from environment-specific configuration (`${cors.allowed-origins}`).
