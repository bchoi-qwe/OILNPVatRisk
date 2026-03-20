# NPV@Risk: Valuing a Cold Lake to Synthetic Crude Upgrader

> Suncor capital investment analysis using Monte Carlo simulation, real options valuation, and yield-curve discounting — built in R with the RTL and NFCP packages.

## Project Overview

This project evaluates a proposed **$2 billion upgrader facility** converting Cold Lake bitumen to Synthetic Crude using NPV@Risk methodology. The analysis incorporates:

- **Two-process stochastic architecture** — WTI is modeled separately via Schwartz-Smith two-factor (short-term OU + long-term ABM), while the CL-SYN upgrading spread is modeled as an OU process. WTI is needed independently because Alberta royalties are explicitly price-linked.
- **NFCP Kalman filter calibration** — WTI Schwartz-Smith parameters estimated from the futures term structure using the [NFCP](https://cran.r-project.org/package=NFCP) package.
- **Monte Carlo simulation** — 10,000+ paths over 20 years at daily resolution, resampled to monthly cash flows.
- **Real options** — Shutdown/restart flexibility and a Year-5 expansion option.
- **Yield curve discounting** — US swap curve from `RTL::usSwapCurves`.
- **TMX structural break** — Piecewise calibration around May 2024 Trans Mountain Expansion.

The deliverable is a Quarto (`.qmd`) business document suitable for peer review and eventual executive presentation.

---

## Repository Structure

```
├── README.md                     # You are here
├── CONTRIBUTING.md               # Workflow rules, code style, AI usage
├── AI-USAGE.md                   # AI usage policy and interaction log
├── NPVatRisk.qmd                 # Main Quarto document (final deliverable)
│
├── Functions/                    # Production R functions (sourced by .qmd)
│   ├── simSchwartzSmith.R        # Schwartz-Smith two-factor WTI simulation
│   ├── calibrate_NFCP.R          # NFCP Kalman filter calibration for WTI
│   └── plotSchwartzSmith.R       # 3-panel plotly visualization
│
├── ExampleFunctions/             # Reference/archived functions
│   ├── simOU.R                   # Standalone OU simulation
│   ├── simGBM.R                  # Standalone GBM simulation
│   └── plotlysim.R               # Original basic plotly plotter
│
├── src/                          # C++ source (Rcpp)
│   └── rcppOU.cpp                # High-performance OU loop
│
├── Research/                     # Background research documents
│   ├── ClaudeResearch1.md        # Project scoping and methodology overview
│   └── ClaudeResearch2.md        # Simulation methodology deep dive
│
├── Planning/                     # Project planning notes
│   ├── OURPLANNING.md            # Team planning and prompt history
│   └── STEP1.md                  # Step 1: WTI Schwartz-Smith modeling
│
├── analysis.R                    # Exploratory data analysis
└── .agents/skills/               # AI agent skill definitions
```

---

## Modeling Architecture

The project uses **two independent stochastic processes** as recommended in `Research/ClaudeResearch2.md`:

1. **WTI Price** → Schwartz-Smith two-factor model  
   `log(S_t) = χ_t + ξ_t` where χ is OU (short-term deviations) and ξ is ABM (long-term equilibrium).  
   Calibrated via Kalman filter on the futures term structure using NFCP.

2. **CL-SYN Spread** → Ornstein-Uhlenbeck process *(upcoming)*  
   `dS = κ(θ − S)dt + σdW` with piecewise θ calibration around the TMX structural break.

3. **Royalties** → Deterministic function of WTI × USD/CAD  
   Alberta's sliding-scale statutory formula (1–9% gross, 25–40% net).

---

## Setup

### Prerequisites

- **R** ≥ 4.3
- **RStudio** (recommended) or any editor with Quarto support
- **Quarto** CLI ([install guide](https://quarto.org/docs/get-started/))

### Install dependencies

```r
# CRAN packages
install.packages(c("tidyverse", "plotly", "MASS", "Rcpp", "patchwork", "NFCP"))

# RTL from GitHub (dev version with fizdiffs)
# install.packages("remotes")
remotes::install_github("risktoollib/RTL")
```

### Compile Rcpp source

```r
Rcpp::sourceCpp("src/rcppOU.cpp")
```

### Render the document

```bash
quarto render NPVatRisk.qmd
```

---

## Team

| Member | Role / Focus Area |
|--------|-------------------|
| TBD    | TBD               |

---

## Key References

- Schwartz, E. & Smith, J. (2000). *Short-Term Variations and Long-Term Dynamics in Commodity Prices.* Management Science.
- Aspinall, T. et al. (2022). *PDSim: A pricing and derivative simulation R package.* JORS. [Link](https://openresearchsoftware.metajnl.com/articles/10.5334/jors.537)
- NFCP Package — [Vignette](https://cloud.r-project.org/web/packages/NFCP/vignettes/NFCP.html) | [GitHub](https://github.com/TomAspinall/NFCP)
- Schwartz, E. (1997). *The Stochastic Behavior of Commodity Prices.* Journal of Finance.
- Brennan, M. & Schwartz, E. (1985). *Evaluating Natural Resource Investments.* Journal of Business.
- RTL Package — [GitHub](https://github.com/risktoollib/RTL) | [CRAN](https://cran.r-project.org/package=RTL)

---

## License

Academic use only. Not for redistribution.
