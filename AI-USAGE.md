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
| **Antigravity** (Google) | Codebase-aware coding, math audits, refactoring, visualization |
| **ChatGPT** (OpenAI) | Code generation, brainstorming, debugging, writing |
| **GitHub Copilot** | Inline code completion, function scaffolding |
| **Gemini** (Google) | Research, summarization, code assistance |
| **Perplexity** | Research with citations, fact-checking |
| **Other** | Document as needed — no tool is off-limits if logged properly |

### Ground Rules

1. **Log it.** Every interaction that materially influences the project must be documented below. A "material" interaction is one where AI output ends up in the codebase, the report, or significantly shapes your thinking on a design decision.

2. **Understand it.** You must be able to explain any AI-generated content you use. During peer review or presentation, "the AI wrote it" is not an acceptable explanation. If you can't defend it, remove it.

3. **Verify the math.** AI tools hallucinate formulas — especially stochastic calculus, Ito's lemma, and risk-neutral dynamics. **Cross-reference every equation** against the source papers (NFCP vignette, PDSim paper, Schwartz & Smith 2000). This project has already caught an incorrect `-σ²/2` Ito correction that an AI introduced.

4. **Adapt it.** Raw AI output rarely fits a project perfectly. Expect to modify, refactor, and integrate. Your value-add is the judgment to shape AI output into something correct and contextually appropriate.

5. **Document failures.** Logging prompts that produced wrong, misleading, or useless output is just as valuable as logging successes. It demonstrates critical evaluation.

6. **No sensitive data in prompts.** Do not paste proprietary data, API keys, credentials, or any confidential information into AI tools.

### What Counts as "Substantive"

**Log these:**
- Asking AI to write or debug a function
- Using AI to explain a statistical concept that shaped your approach
- Having AI draft or edit report text
- Using AI for research that informed parameter choices (e.g., Research/ documents)
- Getting AI help with plotly/ggplot2 chart design
- Architecture/design discussions with AI
- Math audits or equation verification

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

**Tool:** [e.g., Claude 3.5 Sonnet / Antigravity / ChatGPT-4o / GitHub Copilot]
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
[How did you confirm the output was correct? Ran tests? Checked against docs? Compared to source paper?]

**Outcome:**
[What ended up in the project? Which file(s) were affected?]
```

---

## Interaction Log

> Add your entries below, organized by team member. Most recent entries at the top of each section.

---

### Team Member: Brandon Choi

### 2026-03-20 — Brandon Choi

**Tool:** Antigravity (Gemini)
**Task:** Math audit of Schwartz-Smith two-factor simulation and plotly visualization
**Prompt (summary):**
> WTI price modeled as a Schwartz-Smith two-factor process. Look at calibrate_NFCP, as well as simSchwartzSmith.R. Goal is the plotly plot. All math must be completely correct. Double check everything against the NFCP vignette and PDSim paper.

**What AI produced:**
- Line-by-line audit of `simSchwartzSmith.R` against NFCP's actual `spot_price_simulate` source code
- Identified and fixed a spurious `-σ²/2` Ito correction in the ABM drift for the long-term factor ξ
- Identified a dormant bug in the extended model mean-reversion level (`mu_xi - lambda_xi` should be `mu_xi - lambda_xi/gamma` when γ > 0 and λ_ξ ≠ 0)
- Created `plotSchwartzSmith.R`: 3-panel interactive plotly visualization (fan chart, factor decomposition, terminal distribution)
- Refactored plot from hardcoded script into reusable `plotSchwartzSmith(sim, S0, ...)` function

**How you used it:**
- [x] Substantially modified before use

**What you changed and why:**
Reviewed the math audit against the source papers. The `-σ²/2` removal was confirmed correct — NFCP's `spot_price_simulate` uses `GBM_mu_rn * dt` with no Ito correction. The dormant `lambda_xi/gamma` bug was noted but not fixed since `lambda_xi = 0` in current usage.

**Verification:**
- Compared simulation code line-by-line against NFCP source code (`R/simulations.R` on GitHub)
- Cross-referenced with NFCP vignette §3 (model equations) and PDSim paper §I (extended SS formulation)
- Generated 500-path simulation and visually verified fan chart, factor decomposition, and terminal distribution

**Outcome:**
- `Functions/simSchwartzSmith.R` — bug fix (removed `-σ²/2`)
- `Functions/plotSchwartzSmith.R` — new file (replaces `plotlysim.R`)
- `Functions/calibrate_NFCP.R` — updated reference comment

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
| Total logged interactions | 1 |
| Interactions resulting in code | 1 |
| Interactions resulting in report text | 0 |
| Interactions used as reference only | 0 |
| Interactions rejected / not used | 0 |
| Unique tools used | 1 |

---

## Reflection (Complete Before Final Submission)

Each team member should write 2–3 sentences here reflecting on how AI tools affected their work on this project. Be honest — what helped, what didn't, and what would you do differently?

**Brandon Choi:**
> TBD

**[Name 2]:**
> TBD

**[Name 3]:**
> TBD

**[Name 4]:**
> TBD
