# AI Usage Policy & Interaction Log

This document serves two purposes:

1. **Policy** — Our team's rules for how AI tools are used in this project.
2. **Log** — A running record of every substantive AI interaction, organized by team member.

This file is a **living document**. Update it as you work, not retroactively at the end.

---

## Policy

### Approved Tools

Any AI tool is permitted, including but not limited to:

| Tool | Common Use Cases |
|------|------------------|
| **Claude** (Anthropic) | Code generation, conceptual explanations, document drafting, research |
| **ChatGPT** (OpenAI) | Code generation, brainstorming, debugging, writing |
| **GitHub Copilot** | Inline code completion, function scaffolding |
| **Gemini** (Google) | Research, summarization, code assistance |
| **Perplexity** | Research with citations, fact-checking |
| **Other** | Document as needed — no tool is off-limits if logged properly |

### Ground Rules

1. **Log it.** Every interaction that materially influences the project must be documented below. A "material" interaction is one where AI output ends up in the codebase, the report, or significantly shapes your thinking on a design decision.

2. **Understand it.** You must be able to explain any AI-generated content you use. During peer review or presentation, "the AI wrote it" is not an acceptable explanation. If you can't defend it, remove it.

3. **Verify it.** AI tools hallucinate — especially about R package APIs, function signatures, and statistical formulas. **Test every code suggestion.** Cross-reference every factual claim. Trust nothing blindly.

4. **Adapt it.** Raw AI output rarely fits a project perfectly. Expect to modify, refactor, and integrate. Your value-add is the judgment to shape AI output into something correct and contextually appropriate.

5. **Document failures.** Logging prompts that produced wrong, misleading, or useless output is just as valuable as logging successes. It demonstrates critical evaluation.

6. **No sensitive data in prompts.** Do not paste proprietary data, API keys, credentials, or any confidential information into AI tools.

### What Counts as "Substantive"

**Log these:**
- Asking AI to write or debug a function
- Using AI to explain a statistical concept that shaped your approach
- Having AI draft or edit report text
- Using AI for research that informed parameter choices
- Getting AI help with ggplot2 chart design
- Architecture/design discussions with AI (e.g., "how should I structure the simulation loop?")

**Skip these:**
- Autocomplete finishing a variable name
- Asking "what does this error message mean?" for a one-line fix
- Spell checking or grammar suggestions
- Generic questions unrelated to the project

---

## Log Template

Copy the block below for each interaction. Fill it in honestly.

```markdown
### [YYYY-MM-DD] — [Your Name]

**Tool:** [e.g., Claude 3.5 Sonnet / ChatGPT-4o / GitHub Copilot / etc.]
**Task:** [One-line summary of what you asked for]
**Prompt (summary or verbatim):**
> [Paste your prompt, or summarize if it was a long conversation]

**What AI produced:**
[Brief description of the output — don't paste entire code blocks here, just describe]

**How you used it:**
- [ ] Used directly (minor edits only)
- [ ] Substantially modified before use
- [ ] Used as reference/inspiration only
- [ ] Rejected / not used

**What you changed and why:**
[Describe your modifications. This is where you demonstrate critical thinking.]

**Verification:**
[How did you confirm the output was correct? Ran tests? Checked against docs? Compared to textbook?]

**Outcome:**
[What ended up in the project? Which file(s) were affected?]
```

---

## Interaction Log

> Add your entries below, organized by team member. Most recent entries at the top of each section.

---

### Team Member: [Name 1]

<!-- Paste completed log entries here. Most recent first. Example: -->

<!--
### 2026-03-19 — Jane Doe

**Tool:** Claude (Opus)
**Task:** Research NPV@Risk methodology and RTL package capabilities
**Prompt (summary):**
> Help me understand the NPV@Risk project. Uploaded the assignment .qmd file and asked for a comprehensive research plan covering OU processes, real options, RTL functions, and executive communication.

**What AI produced:**
Three research reports covering: OU process theory and calibration, RTL package functions (simOU, fitOU, npv, fizdiffs, usSwapCurves), real options (shutdown + expansion), oil sands economics, and visualization strategies.

**How you used it:**
- [x] Used as reference/inspiration only

**What you changed and why:**
Used the third report as a reference document for the team. Did not copy any text into the deliverable. Extracted key RTL function signatures and verified them against CRAN documentation.

**Verification:**
Cross-referenced all RTL function names and parameters against the official CRAN PDF manual (https://cran.r-project.org/web/packages/RTL/RTL.pdf). Confirmed fizdiffs dataset structure by running `str(RTL::fizdiffs)` locally.

**Outcome:**
Informed project planning. No code or text added to deliverable directly.
-->

---

### Team Member: [Name 2]

<!-- Paste completed log entries here -->

---

### Team Member: [Name 3]

<!-- Paste completed log entries here -->

---

### Team Member: [Name 4]

<!-- Paste completed log entries here -->

---

## Summary Statistics

Update this table periodically (e.g., before each milestone or submission).

| Metric | Count |
|--------|-------|
| Total logged interactions | 0 |
| Interactions resulting in code | 0 |
| Interactions resulting in report text | 0 |
| Interactions used as reference only | 0 |
| Interactions rejected / not used | 0 |
| Unique tools used | 0 |

---

## Reflection (Complete Before Final Submission)

Each team member should write 2–3 sentences here reflecting on how AI tools affected their work on this project. Be honest — what helped, what didn't, and what would you do differently?

**[Name 1]:**
> TBD

**[Name 2]:**
> TBD

**[Name 3]:**
> TBD

**[Name 4]:**
> TBD
