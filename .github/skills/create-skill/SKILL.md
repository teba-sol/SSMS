---
name: create-skill
description: "Use when: you need to turn a repeatable workflow or methodology into a reusable skill file for this workspace or your profile."
---

# Create a reusable skill

## Purpose

Turn an observed multi-step workflow into a reusable SKILL.md that another agent or user can invoke later.

## When to use

Use this skill when:
- the user is following a repeatable process such as debugging, review, setup, implementation, or validation;
- the workflow contains clear steps, branch points, or completion checks;
- you want to preserve a method as a reusable skill instead of leaving it as a one-off interaction.

## Workflow

1. Review the conversation and identify the workflow being followed.
2. Extract the main steps in order and note any decision points or branching logic.
3. Capture the quality criteria or completion checks that indicate success.
4. Clarify anything ambiguous before drafting, including:
   - whether the skill should be workspace-scoped or personal;
   - whether the outcome is a quick checklist or a fuller workflow;
   - what result the skill should produce.
5. Draft the skill with clear frontmatter, a useful description, and concise sections for purpose, workflow, and validation.
6. Save the file in the appropriate location:
   - workspace-scoped: .github/skills/<name>/SKILL.md
   - personal: the user's prompt customization folder
7. Review the final skill for clarity, actionability, and completeness.

## Quality checklist

A strong skill should:
- be grounded in a real workflow observed in the conversation;
- include a clear description that helps discovery;
- explain the step-by-step process in plain language;
- capture important branching logic and decision points;
- define how to know when the task is complete;
- be saved in the correct location and use valid YAML frontmatter.

## Output

Create or update a SKILL.md that packages the workflow into a reusable, discoverable skill.
