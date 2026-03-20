# Contributing Guide

Rules and conventions for the team. Read this before pushing anything.

---

## Git Workflow

### Branching

We use a simple **feature-branch** workflow off `main`:

```
main              ← always renderable, never broken
├── feat/simulation
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
sim: implement OU calibration with fitOU()
npv: add shutdown logic to cash flow engine
viz: create NPV distribution histogram
docs: update AI-USAGE.md with ChatGPT session
fix: correct monthly discount factor interpolation
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
- Prefix RTL functions with the namespace: `RTL::simOU()`, `RTL::fitOU()`, etc.

### Quarto (.qmd) conventions

- Use **named code chunks** (`{r chunk-name}`) so errors are easy to trace.
- Set `echo: false` for production chunks (we're writing a business document, not a code tutorial).
- Keep heavy computation in sourced `.R` files under `R/`. The `.qmd` should focus on narrative and visualization.
- Use `params$` from the setup chunk for all magic numbers — no hardcoded values in analysis chunks.

### File organization

- **Don't put everything in the `.qmd`.** Factor reusable logic into `R/` scripts and `source()` them.
- Data exploration and scratch work go in a personal notebook (e.g., `notebooks/yourname-exploration.qmd`). These are `.gitignore`d or kept in a `scratch/` folder.
- Final figures that need manual export go in `figures/`.

---

## AI Usage Requirements

**This is non-negotiable for our project.** Every team member must:

1. **Log every substantive AI interaction** in `AI-USAGE.md` following the template in that file.
2. **Understand and be able to explain** any AI-generated code or text you incorporate. If you can't explain it line by line, don't use it.
3. **Cite the tool** in your commit message when AI contributed meaningfully (e.g., `sim: OU simulation loop — drafted with Claude, reviewed and modified`).
4. **Never copy-paste AI output directly** into the final `.qmd` without review, testing, and adaptation. AI output is a *draft*, not a deliverable.
5. **Record failed/rejected AI suggestions** too — documenting what *didn't* work shows critical thinking.

See [AI-USAGE.md](AI-USAGE.md) for the full policy and logging format.

---

## Division of Work

Use GitHub Issues or a shared task board to track who owns what. Suggested areas:

| Area | Description |
|------|-------------|
| **Data & Calibration** | Explore `fizdiffs`, compute CL-SYN spread, run `fitOU()`, validate parameters |
| **Simulation Engine** | `simOU()` wrapper, path generation, seed management, convergence checks |
| **Cash Flow / NPV** | Monthly cash flow model, shutdown/restart logic, expansion option, `npv()` integration |
| **Risk Analysis** | NPV distribution stats, VaR/CVaR, sensitivity analysis, tornado diagram |
| **Visualization & Narrative** | All ggplot2 charts, Quarto document structure, executive summary writing |
| **Quality & Integration** | Code review, rendering checks, proofreading, AI-USAGE.md completeness |

Overlap is expected and fine — just communicate ownership clearly.

---

## Rendering Checklist (Before Merging to Main)

- [ ] `quarto render p2-npvatrisk.qmd` completes without errors
- [ ] All figures render correctly (no broken paths)
- [ ] No hardcoded file paths that only work on one person's machine
- [ ] `set.seed()` is used — results are reproducible
- [ ] Narrative reads as a business document, not a homework submission
- [ ] AI-USAGE.md is up to date with your contributions
- [ ] Spell check (seriously)
