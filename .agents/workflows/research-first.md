---
description: mandatory first steps before any modeling or coding work
---

# Research-First Workflow

**This workflow is MANDATORY before starting any modeling, simulation, or analysis work.**

## Step 1: Read the Research Documents

Before writing or modifying any code, read the research documents in `Research/`:

// turbo
1. Read `Research/ClaudeResearch2.md` — this is the **primary architecture document** defining:
   - Two-process model: WTI (Schwartz-Smith) + CL-SYN spread (OU)
   - Why WTI is modeled separately (Alberta royalty linkage)
   - TMX structural break calibration strategy
   - κ bias correction requirements
   - Correlation modeling decisions

// turbo
2. Read `Research/ClaudeResearch1.md` — this covers:
   - Project scoping and RTL package capabilities
   - Real options methodology
   - Executive communication strategy

## Step 2: Read the Planning Documents

// turbo
3. Read `Planning/STEP1.md` — current step-level context
// turbo
4. Read `Planning/OURPLANNING.md` — team planning and prompt history

## Step 3: Read the Assignment

// turbo
5. Read `NPVatRisk.qmd` — the assignment specification (DO NOT EDIT)

## Step 4: Understand Existing Code

// turbo
6. Read `Functions/simSchwartzSmith.R` — the WTI simulation (already audited and corrected)
// turbo
7. Read `Functions/calibrate_NFCP.R` — NFCP Kalman filter calibration
// turbo
8. Read `Functions/plotSchwartzSmith.R` — plotly visualization function
// turbo
9. Read `src/rcppOU.cpp` — the C++ OU loop used by the simulation

## Key Architectural Decisions (from ClaudeResearch2.md)

These have already been made. Do not contradict them without explicit user approval:

- **WTI uses Schwartz-Smith two-factor** (not plain GBM or OU)
- **CL-SYN spread uses OU** (not joint multivariate simulation)
- **Royalties are deterministic** functions of WTI × USD/CAD
- **Constant correlation with Cholesky** is sufficient for 20-year horizon
- **TMX May 2024 is a known structural break** — piecewise calibration required
- **κ bias correction** via parametric bootstrap is essential
