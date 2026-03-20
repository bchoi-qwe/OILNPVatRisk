# Contributing Guide

Rules and conventions for the team. Read this before pushing anything.

---

## Git Workflow

### Branching

We use a simple **feature-branch** workflow off `main`:

```
main              ← always renderable, never broken
├── feat/wti-schwartz-smith
├── feat/spread-ou-calibration
├── feat/cashflow-engine
├── feat/visualization
├── feat/sensitivity
└── fix/discount-factor-bug
```

**Branch naming:** `feat/<short-description>` for new work, `fix/<short-description>` for bug fixes.

### Commits

Write clear, short commit messages. Prefix with a category:

```
data: add fizdiffs exploration notebook
sim: implement Schwartz-Smith two-factor simulation
cal: calibrate NFCP Kalman filter for WTI futures
npv: add shutdown logic to cash flow engine
viz: create NPV distribution histogram
docs: update AI-USAGE.md with session log
fix: remove spurious Ito correction from ABM drift
```

### Pull Requests

- Create a PR when your branch is ready for review.
- At least **one other team member** must review before merging.
- Resolve merge conflicts on your branch, not on `main`.
- Squash-merge to keep `main` history clean.

---

## Code Style

### R conventions

- Use `tidyverse` style: snake_case for variables and functions, pipes (`|>` or `%>%`).
- Keep lines under **100 characters**.
- Comment the *why*, not the *what*. The code should explain itself.
- Prefix external package functions with the namespace: `RTL::simOU()`, `NFCP::NFCP_MLE()`, `plotly::plot_ly()`, etc.
- All production functions go in `Functions/`. Archived or reference code goes in `ExampleFunctions/`.

### Quarto (.qmd) conventions

- Use **named code chunks** (`{r chunk-name}`) so errors are easy to trace.
- Set `echo: false` for production chunks (we're writing a business document, not a code tutorial).
- Keep heavy computation in sourced `.R` files under `Functions/`. The `.qmd` should focus on narrative and visualization.
- Use `params$` from the setup chunk for all magic numbers — no hardcoded values in analysis chunks.

### File organization

```
Functions/          ← Production code (sourced by .qmd and each other)
ExampleFunctions/   ← Archived/reference implementations
Research/           ← Background research documents (READ THESE FIRST)
Planning/           ← Project planning and step-by-step notes
src/                ← C++ source files (Rcpp)
```

- **Don't put everything in the `.qmd`.** Factor reusable logic into `Functions/` scripts and `source()` them.
- Data exploration and scratch work go in a personal notebook (e.g., `notebooks/yourname-exploration.qmd`). These are `.gitignore`d or kept in a `scratch/` folder.

---

## Research-First Rule

> **⚠️ Always read the `Research/` folder before starting any modeling work.**

The `Research/` directory contains comprehensive methodology documents that define the project's modeling architecture, parameter choices, and estimation strategy. Key documents:

| File | Contents |
|------|----------|
| `ClaudeResearch1.md` | Project scoping, RTL functions, real options methodology |
| `ClaudeResearch2.md` | **Simulation architecture**: two-process model (WTI Schwartz-Smith + CL-SYN OU), TMX structural break calibration, κ bias correction, correlation modeling |

If you (or an AI agent) begin work without reading these, you will likely make incorrect architectural assumptions.

---

## AI Usage Requirements

**This is non-negotiable for our project.** Every team member must:

1. **Log every substantive AI interaction** in `AI-USAGE.md` following the template in that file.
2. **Understand and be able to explain** any AI-generated code or text you incorporate. If you can't explain it line by line, don't use it.
3. **Cite the tool** in your commit message when AI contributed meaningfully (e.g., `sim: OU simulation loop — drafted with Claude, reviewed and modified`).
4. **Never copy-paste AI output directly** into the final `.qmd` without review, testing, and adaptation. AI output is a *draft*, not a deliverable.
5. **Record failed/rejected AI suggestions** too — documenting what *didn't* work shows critical thinking.
6. **Verify all math** against the source papers. AI tools hallucinate formulas. Cross-reference against the NFCP vignette and PDSim paper.

See [AI-USAGE.md](AI-USAGE.md) for the full policy and logging format.

---

## Division of Work

Use GitHub Issues or a shared task board to track who owns what. Areas:

| Area | Description |
|------|-------------|
| **WTI Modeling** | Schwartz-Smith simulation, NFCP calibration, Kalman filter |
| **Spread Modeling** | CL-SYN OU calibration, TMX structural break, `fitOU()` with κ bias correction |
| **Cash Flow / NPV** | Monthly cash flow model, shutdown/restart logic, expansion option, royalty function |
| **Risk Analysis** | NPV distribution stats, VaR/CVaR, sensitivity analysis, tornado diagram |
| **Visualization & Narrative** | plotly charts, Quarto document structure, executive summary writing |
| **Quality & Integration** | Code review, rendering checks, math verification, AI-USAGE.md completeness |

---

## Rendering Checklist (Before Merging to Main)

- [ ] `quarto render NPVatRisk.qmd` completes without errors
- [ ] All figures render correctly (no broken paths)
- [ ] No hardcoded file paths that only work on one person's machine
- [ ] `set.seed()` is used — results are reproducible
- [ ] Narrative reads as a business document, not a homework submission
- [ ] AI-USAGE.md is up to date with your contributions
- [ ] Math verified against source papers (NFCP vignette, PDSim, SS 2000)
- [ ] Spell check (seriously)
