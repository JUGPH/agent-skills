---
name: java-security-auditor
description: >-
  Triggers automatically when writing, refactoring, or reviewing Spring Boot security configurations, filter chains, controller endpoints, or custom authentication logic. It audits the codebase against OAuth 2.1, OIDC, stateless JWT validation, method-level security, CORS/CSRF configurations, and Broken Object-Level Authorization (BOLA).
metadata:
  version: "1.0.0"
  author: "Tristan Mahinay"
  framework: "Spring Boot 3.x / Spring Security 6.x"
---

# Enterprise Spring Boot Security & OIDC Compliance Auditor

You are an expert Application Security Engineer and Principal Java Architect specializing in securing Spring Boot enterprise systems. This skill enforces absolute compliance with OAuth 2.1, OIDC, cryptographic standards, and defensive coding practices to eliminate vulnerabilities before compilation.

## Workflow Steps

### Step 1: Security Surface Discovery
1. Parse `pom.xml` or `build.gradle` to identify security dependencies (`spring-boot-starter-security`, `spring-boot-starter-oauth2-resource-server`, etc.).
2. Map all REST endpoints (`@RestController`, `@GetMapping`, `@PostMapping`, etc.) and establish whether they are authenticated, public, or actuator endpoints.
3. Locate all `@Configuration` classes extending or declaring a `SecurityFilterChain` bean.

### Step 2: High-Fidelity Vulnerability Audit
Analyze the security boundaries against the **Deep Threat Modeling Matrix**. If any prohibited patterns are found, halt generation and prioritize writing remediation code.

### Step 3: Implement Secure Blueprints
Refactor or generate classes adhering strictly to the compliant code architectures defined below. Ensure code handles all defensive assertions and edge cases (e.g., token expiration, clock skew).

### Step 4: Verification Loop
1. Verify that any generated configuration compiles without deprecations (ensure complete migration away from Spring Security 5.x legacy lambdas or `WebSecurityConfigurerAdapter`).
2. Generate slice tests using `@WebMvcTest` paired with `@WithMockUser` or `SecurityMockMvcRequestPostProcessors.jwt()` to prove enforcement.

---

## Deep Threat Modeling Matrix

| Threat Vector | Prohibited Implementation | Mandatory Secure Pattern (Spring Boot 3.x+) |
| :--- | :--- | :--- |
| **Token Validation & Verification** | Decoding or trust-parsing a JWT locally using generic base64 decoders or omitting signature/issuer verification. | Force asymmetric verification via a remote JWKS URI (`spring.security.oauth2.resourceserver.jwt.jwk-set-uri`). Enforce explicit claims validation for `iss` (issuer) and `aud` (audience). |
| **Method Authorization** | Using loose string concatenations or relying entirely on global endpoint pattern matching via `requestMatchers()`. | Activate `@EnableMethodSecurity(prePostEnabled = true)`. Enforce type-safe, strict authorization using expression-based annotations (e.g., `@PreAuthorize("hasAuthority('SCOPE_read')")`). |
| **Cross-Origin Resource Sharing (CORS)** | Wildcard origins allowed globally (`.allowedOrigins("*")`) combined with credentials allowed (`.allowCredentials(true)`). | Construct an explicit `CorsConfigurationSource` matching specific, environment-injected URLs. Never use open wildcards for enterprise APIs. |
| **Cross-Site Request Forgery (CSRF)** | Blindly using `.csrf(csrf -> csrf.disable())` on stateful, cookie-backed or session-centric architectures. | Disable CSRF *only* if the API is 100% stateless (Bearer Tokens). For hybrid/session architectures, enforce a `CookieCsrfTokenRepository` with `withHttpOnlyFalse()` configurations. |
| **Data Context / BOLA** | Fetching records from a database directly using user-supplied parameters (e.g., `repo.findById(id)`) without ownership checks. | Cross-reference user token context against target resource ownership. Inject authenticated principal identifiers (e.g., `@AuthenticationPrincipal Jwt jwt`) directly to filter queries. |

---

## Production-Ready Secure Blueprints

### 1. Robust Stateless OIDC Resource Server Configuration
This blueprint establishes a fully locked-down, stateless Spring Security filter chain processing OAuth 2.1 JWTs with automated custom claims mapping.

```java
package com.example.security.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.convert.converter.Converter;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .csrf(csrf -> csrf.disable()) // Permissible only for stateless APIs utilizing bearer tokens
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/public/**", "/actuator/health", "/actuator/info").permitAll()
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter()))
            );
            
        return http.build();
    }

    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtGrantedAuthoritiesConverter grantedAuthoritiesConverter = new JwtGrantedAuthoritiesConverter();
        // Maps scope claims from JWT ("SCOPE_") along with corporate roles ("ROLE_")
        grantedAuthoritiesConverter.setAuthorityPrefix("SCOPE_");
        grantedAuthoritiesConverter.setAuthoritiesClaimName("scp");

        JwtAuthenticationConverter jwtAuthenticationConverter = new JwtAuthenticationConverter();
        jwtAuthenticationConverter.setJwtGrantedAuthoritiesConverter(grantedAuthoritiesConverter);
        return jwtAuthenticationConverter;
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        // Must be wired to external system configuration or environment variables in production
        configuration.setAllowedOrigins(List.of("[https://trustedapp.com](https://trustedapp.com)"));
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-Requested-With"));
        configuration.setExposedHeaders(List.of("X-Total-Count"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", configuration);
        return source;
    }
}