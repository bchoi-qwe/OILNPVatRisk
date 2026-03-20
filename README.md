# NPV@Risk: Valuing a Cold Lake to Synthetic Crude Upgrader

> Suncor capital investment analysis using Monte Carlo simulation, real options valuation, and yield-curve discounting — built in R with the RTL package.

## Project Overview

This project evaluates a proposed **$2 billion upgrader facility** converting Cold Lake bitumen to Synthetic Crude using NPV@Risk methodology. The analysis incorporates:

- **Stochastic spread modeling** — Ornstein-Uhlenbeck process calibrated to historical CL-SYN differentials
- **Monte Carlo simulation** — 10,000+ paths over 20 years at monthly frequency
- **Real options** — Shutdown/restart flexibility and a Year-5 expansion option
- **Yield curve discounting** — US swap curve from `RTL::usSwapCurves`
- **Executive-ready communication** — Waterfall, tornado, fan, and NPV distribution charts

The deliverable is a Quarto (`.qmd`) business document suitable for peer review and eventual executive presentation.

---

## Repository Structure

```
├── README.md                 # You are here
├── CONTRIBUTING.md           # Workflow rules, branching, code style
├── AI-USAGE.md               # AI usage policy and interaction log
├── p2-npvatrisk.qmd          # Main Quarto document (final deliverable)
├── data/                     # Any exported or intermediate data
├── R/                        # Helper functions (sourced by .qmd)
│   ├── simulation.R          # OU simulation and calibration wrappers
│   ├── cashflow.R            # NPV engine with shutdown/expansion logic
│   └── visualization.R       # ggplot2 chart functions
├── figures/                  # Exported plots (if not inline)
└── references/               # PDFs, notes, background reading
```

> Adjust the structure as the project evolves. The above is a starting scaffold.

---

## Setup

### Prerequisites

- **R** ≥ 4.3
- **RStudio** (recommended) or any editor with Quarto support
- **Quarto** CLI ([install guide](https://quarto.org/docs/get-started/))

### Install dependencies

```r
# CRAN packages
install.packages(c("tidyverse", "scales", "patchwork", "RQuantLib"))

# RTL from GitHub (dev version with fizdiffs)
# install.packages("remotes")
remotes::install_github("risktoollib/RTL")
```

### Render the document

```bash
quarto render p2-npvatrisk.qmd
```

---

## Team

| Member | Role / Focus Area |
|--------|-------------------|
| TBD    | TBD               |
| TBD    | TBD               |
| TBD    | TBD               |
| TBD    | TBD               |

---

## Key References

- Schwartz, E. (1997). *The Stochastic Behavior of Commodity Prices.* Journal of Finance.
- Brennan, M. & Schwartz, E. (1985). *Evaluating Natural Resource Investments.* Journal of Business.
- Dixit, A. & Pindyck, R. (1994). *Investment Under Uncertainty.* Princeton University Press.
- Trigeorgis, L. (1993). *The Nature of Option Interactions.* JFQA.
- RTL Package — [GitHub](https://github.com/risktoollib/RTL) | [CRAN](https://cran.r-project.org/package=RTL)

---

## License

Academic use only. Not for redistribution.
