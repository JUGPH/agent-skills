# AGENTS.md — Contributor Guidelines for AI Agents

This document defines architectural standards, structural requirements, and validation rules for AI agents authoring or modifying skills in the `JUGPH/agent-skills` repository.

---

## Repository Purpose

This repository is a curated collection of production-grade AI agent skills for enterprise Java and cloud-native ecosystems, distributed via the `skills` CLI (`npx skills`).

---

## Skill Authoring Standards

Every skill in this repository must reside in `.agents/skills/<skill-name>/SKILL.md`.

### 1. Naming & Directory Structure
- The directory name under `.agents/skills/` must strictly match the `name` field in the YAML frontmatter in `kebab-case`.
- Example: `.agents/skills/java-security-auditor/SKILL.md` with `name: java-security-auditor`.

### 2. Mandatory YAML Frontmatter
Every `SKILL.md` must begin with standard YAML frontmatter:

```yaml
---
name: kebab-case-skill-name
description: >-
  Trigger condition and purpose. Specify exact scenarios when an agent should invoke this skill, target frameworks, and capabilities.
metadata:
  version: "1.0.0"
  author: "Author Name"
  framework: "Target runtime/framework (e.g., Java 21+ / Spring Boot 3.x)"
---
```

**Description Guidelines:**
- Clearly state the **trigger condition** ("Trigger this skill when...").
- Specify the technologies and architectural patterns it covers.
- Keep descriptions precise so agent discovery engines can route tasks accurately.

### 3. Required `SKILL.md` Document Structure
Each skill should be structured with the following standard sections:

1. **Role & Directive**: Define the persona (e.g., Principal Java Architect, Application Security Engineer) and the core objective.
2. **Workflow Steps**: Provide a 2–4 step sequential protocol for the agent to follow (e.g., Ingestion/Context, Analysis/Audit Matrix, Remediation/Generation).
3. **Anti-Patterns Matrix**: A structured table or checklist contrasting bad practices against required modern patterns.
4. **Code Blueprints / Templates**: Production-ready, copy-pasteable Java snippets demonstrating modern patterns (Java 21+, Records, Text Blocks, Virtual Threads, Spring Boot 3.x conventions).

---

## Technical & Java Baseline Standards

When authoring Java guidance within skills:
- **Java Baseline**: Assume Java 21 LTS or newer. Use Records, Sealed Interfaces, Text Blocks (`"""`), Pattern Matching, and Sequenced Collections.
- **Spring Boot Baseline**: Spring Boot 3.x and Spring Security 6.x.
- **Dependency Injection**: Constructor injection via Lombok `@RequiredArgsConstructor` or explicit record constructors. Never field injection (`@Autowired`).
- **Entity Safety**: Never use Lombok `@Data`, `@EqualsAndHashCode`, or `@ToString` on JPA `@Entity` classes.
- **Data Flow**: Enforce immutable Java `record` DTOs for API ingress and egress; never expose JPA entities directly.
- **Formatting**: Do not use emojis in section headers. Maintain clean, professional GitHub-flavored markdown.

---

## Validation Before Committing

Before committing any new or modified skill, always validate that the `skills` CLI can parse the frontmatter and register the skill:

```bash
npx skills add . --list
```

**Verification Criteria:**
- The new skill name appears in the output list.
- The description renders completely without YAML parsing errors.
- The total skill count increments correctly.

---

## Git Conventions

- Commit messages must follow the [Conventional Commits](https://www.conventionalcommits.org/) format:
  - `feat(skills): add spring-cloud-stream-kafka skill`
  - `fix(skills): correct virtual thread anti-pattern in perf skill`
  - `docs: update contributor guidelines`
- Never push directly to remote branches without review.
