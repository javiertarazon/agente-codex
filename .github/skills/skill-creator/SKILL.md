---
name: skill-creator
description: Create or update AgentSkills. Use when designing, structuring, or packaging skills with scripts, references, and assets.
---

# Skill Creator

This skill provides guidance for creating effective skills.

## About Skills

Skills are modular, self-contained packages that extend capabilities by providing specialized knowledge, workflows, and tools. Think of them as "onboarding guides" for specific domains or tasks.

### What Skills Provide

1. Specialized workflows - Multi-step procedures for specific domains
2. Tool integrations - Instructions for working with specific file formats or APIs
3. Domain expertise - Company-specific knowledge, schemas, business logic
4. Bundled resources - Scripts, references, and assets for complex and repetitive tasks

---

## Core Principles

### Concise is Key

The context window is a public good. Only add context that is non-obvious. Challenge each piece of information: "Does the agent really need this explanation?"

Prefer concise examples over verbose explanations.

### Set Appropriate Degrees of Freedom

- **High freedom (text-based)**: Multiple approaches valid, decisions depend on context.
- **Medium freedom (pseudocode/scripts with params)**: Preferred pattern exists, some variation OK.
- **Low freedom (specific scripts, few params)**: Operations are fragile and need consistency.

---

## Anatomy of a Skill

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter: name + description
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/      - Executable code (Python/Bash/etc.)
    ├── references/   - Documentation to load into context as needed
    └── assets/       - Files used in output (templates, icons, fonts)
```

---

## Skill Creation Process

1. **Understand** the skill with concrete examples
2. **Plan** reusable skill contents (scripts, references, assets)
3. **Initialize** the skill directory
4. **Edit** SKILL.md and add resources
5. **Iterate** based on real usage

---

## SKILL.md Frontmatter

```yaml
---
name: my-skill
description: >
  What this skill does. Include WHEN to use it (triggers) here —
  the body is only read after triggering, so put trigger context in description.
---
```

Only `name` and `description` fields. Nothing else in frontmatter.

---

## Skill Naming

- Lowercase letters, digits, and hyphens only.
- Under 64 characters.
- Prefer short, verb-led phrases: `rotate-pdf`, `gh-address-comments`.
- Namespace by tool when it helps: `linear-address-issue`.
- Folder name exactly matches skill name.

---

## Progressive Disclosure Design

Skills use a three-level loading system:

1. **Metadata (name + description)** — Always in context (~100 words)
2. **SKILL.md body** — When skill triggers (<500 lines)
3. **Bundled resources** — As needed by agent (unlimited)

Keep SKILL.md body under 500 lines. Split detailed content into `references/` files.

---

## Bundled Resources

### scripts/
- Executable code for tasks that are repeatedly rewritten.
- Test scripts by actually running them.

### references/
- Documentation that agent should read while working.
- Examples: schemas, API docs, domain knowledge, policies.
- Keep SKILL.md lean; move detailed reference material here.

### assets/
- Files used in output, not loaded into context.
- Examples: templates, images, icons, boilerplate code.

---

## What NOT to Include

- README.md
- INSTALLATION_GUIDE.md
- QUICK_REFERENCE.md
- CHANGELOG.md

Only include files that directly support the skill's functionality.

---

## Para este workspace (openclaw-local-agent)

Para crear un nuevo skill en este workspace:

```
1. Crear .github/skills/<nombre-skill>/SKILL.md
2. Agregar frontmatter con name y description
3. Agregar el skill a la tabla de copilot-instructions.md
4. Agregar trigger keywords en .codex-agent/agent-config.yaml
```

Estructura de skills activos en este workspace:
- `.github/skills/` — todos los skills disponibles
- `.github/copilot-instructions.md` — tabla de activación de skills
- `.codex-agent/agent-config.yaml` — triggers por keywords
