# JUG Philippines — Enterprise Agent Skills

[![Skills Ecosystem](https://img.shields.io/badge/skills.sh-compatible-blue.svg)](https://skills.sh)
[![Java Version](https://img.shields.io/badge/Java-21%2B-orange.svg)](https://www.oracle.com/java/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-4.x-green.svg)](https://spring.io/projects/spring-boot)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE.md)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/JUGPH/agent-skills/pulls)

A curated collection of production-grade, enterprise AI agent skills maintained by **Java User Group Philippines (JUGPH)**.

These skills extend AI coding assistants (such as **Claude Code**, **Cursor**, **Antigravity**, **GitHub Copilot**, **Codex**, **Windsurf**, and **Cline**) with architectural guardrails for modern Java (21+), Spring Boot 4.x, Spring Security 7.x / OAuth 2.1, OpenShift S2I container deployment, and JVM runtime performance tuning.

---

## Quick Start with `npx skills`

Install and manage skills directly in your project using the [`skills`](https://skills.sh) CLI powered by Vercel Labs.

### 1. Discover Available Skills

The skills CLI queries this repository directly, providing a real-time list of all available skills and their descriptions:

```bash
npx skills add JUGPH/agent-skills --list
```

*(You can also use the full Git repository URL: `https://github.com/JUGPH/agent-skills.git`)*

```bash
npx skills add https://github.com/JUGPH/agent-skills.git --list
```

### 2. Install Skills

#### Install All Skills
Install every skill in this repository into your current project:

```bash
# Interactive agent selection
npx skills add JUGPH/agent-skills

# Non-interactive: install all skills to all detected agents
npx skills add JUGPH/agent-skills --all
```

#### Install Specific Skills
Install only the skills you need for your workspace:

```bash
npx skills add JUGPH/agent-skills --skill <skill-name>

# Example: install multiple skills simultaneously
npx skills add JUGPH/agent-skills --skill java-code-review --skill java-security-audit
```

#### Install Globally (User-Wide)
Make skills available across all projects on your local machine:

```bash
npx skills add JUGPH/agent-skills -g
```

#### Target Specific Agents
Restrict installation to specific coding assistants:

```bash
npx skills add JUGPH/agent-skills --agent claude-code cursor
```

### 3. Run a Skill on Demand (Without Installing)

Generate a one-shot prompt instruction pipeable directly to an agent CLI:

```bash
# Example: Pipe a skill prompt into Claude Code
npx skills use JUGPH/agent-skills@<skill-name> | claude

# Specify agent explicitly
npx skills use JUGPH/agent-skills --skill <skill-name> --agent claude-code
```

---

## Skill Domains & Focus Areas

Skills in this repository are categorized into core enterprise Java domains. Browse individual instructions and configurations directly in the [`.agents/skills/`](.agents/skills) directory:

- **Code Review & Architectural Integrity**: Enforces strict Spring Boot proxy mechanics, annotation semantics, JPA/Hibernate query boundaries, and shallow immutability auditing.
- **Security & OAuth 2.1 / OIDC Compliance**: Audits endpoints and configurations for stateless JWT validation, granular method security (`@PreAuthorize`), CORS/CSRF configurations, and Broken Object-Level Authorization (BOLA) defenses.
- **Performance & JVM Profiling**: Eliminates CPU hot-paths, avoids object churn and GC thrashing, prevents Virtual Thread (`ThreadLocal`) memory bloat, and optimizes data structure capacities.
- **Test Engineering**: Generates BDD-styled, architectural test slices (`@WebMvcTest`, `@DataJpaTest`, `@SpringBootTest`), Testcontainers integrations, and fluent AssertJ assertions.
- **Cloud-Native & Scaffolding**: Scaffolds production-ready microservices tailored for Red Hat OpenShift Source-to-Image (S2I) build environments and container runtime compliance.

To view the live, up-to-date catalog of specific skills and descriptions at any time, run:

```bash
npx skills add JUGPH/agent-skills --list
```

---

## Managing Installed Skills

### List Installed Skills
Inspect which skills are active in your current project or global environment:

```bash
# Current project
npx skills list

# Global environment
npx skills list -g

# Filter by agent
npx skills ls -a claude-code
```

### Update Skills
Pull the latest improvements and rule updates from upstream:

```bash
# Update all project skills
npx skills update

# Update global skills
npx skills update -g

# Update a specific skill
npx skills update <skill-name>
```

### Remove Skills
Uninstall skills when they are no longer needed:

```bash
# Interactive selection
npx skills remove

# Remove a specific skill
npx skills remove <skill-name>

# Remove from global scope
npx skills rm --global <skill-name>
```

---

## Supported Agents

Skills in this repository follow the [Open Agent Skills standard](https://skills.sh) and work with 30+ agentic development environments, including:

- **Claude Code** (`~/.claude/skills/` or `.claude/skills/`)
- **Cursor** (`.cursor/skills/`)
- **Google Antigravity** (`.agents/skills/` or `~/.gemini/config/skills/`)
- **GitHub Copilot** (`.github/skills/`)
- **Roo Code / Cline**
- **Windsurf**
- **Codex / OpenCode**

---

## Repository Layout

```text
agent-skills/
├── .agents/
│   └── skills/
│       └── <skill-name>/
│           └── SKILL.md
└── README.md
```

---

## Contributing New Skills

We welcome contributions from the Java and Open Source community!

1. Fork this repository: `https://github.com/JUGPH/agent-skills.git`
2. Create your skill directory under `.agents/skills/<skill-name>/`
3. Add a `SKILL.md` file with standard YAML frontmatter:
   ```yaml
   ---
   name: your-skill-name
   description: Trigger description and capabilities of the skill.
   metadata:
     version: "1.0.0"
     author: "Your Name"
     framework: "Java 21+ / Spring Boot 4.x"
   ---
   ```
4. Verify skill discovery locally:
   ```bash
   npx skills add . --list
   ```
5. Submit a Pull Request.

---

## License

This repository is licensed under the [Apache License 2.0](LICENSE.md). Maintained by [Java User Group Philippines (JUGPH)](https://github.com/JUGPH).
