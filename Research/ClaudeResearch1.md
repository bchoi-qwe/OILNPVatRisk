# NPV@Risk for oil sands upgraders: a complete research guide

**NPV@Risk transforms capital budgeting from a single-number gamble into a probability-weighted decision framework**, combining Monte Carlo simulation of commodity price paths with discounted cash flow analysis to produce a full distribution of project outcomes. For a Cold Lake bitumen-to-Synthetic Crude upgrader, this methodology is especially powerful: the upgrading spread is volatile and mean-reverting, the project embeds valuable operating options (shutdown/restart) and growth options (expansion), and the RTL package in R provides purpose-built tools — `simOU()`, `fitOU()`, `npv()`, and the `fizdiffs` dataset — to implement the entire analysis. This report covers every component needed for a graduate-level implementation: stochastic spread modeling, real options valuation, Monte Carlo mechanics, yield curve discounting, and executive communication of results.

---

## How NPV@Risk replaces deterministic guesswork with probabilistic rigor

Traditional NPV analysis produces a single point estimate — "the NPV is $150M" — by plugging best-guess inputs into a DCF model. This approach suffers from three fatal limitations: sensitivity analysis tweaks one variable at a time and misses interaction effects, scenario analysis examines only three combinations with no probabilities attached, and neither approach tells you **the probability that the project actually destroys value**.

NPV@Risk resolves all three. The methodology simulates thousands of possible commodity price paths over the project's life using calibrated stochastic models, computes NPV for each path (incorporating operational logic like shutdown decisions), and then analyzes the resulting distribution. The key output metrics are:

- **Mean NPV (E[NPV])**: the probability-weighted expected value, theoretically the "true" NPV
- **P(NPV < 0)**: the probability of loss — the single most important risk metric for go/no-go decisions
- **VaR₅%**: the 5th percentile NPV, answering "what's the worst outcome at 95% confidence?"
- **CVaR₅% (Expected Shortfall)**: the average NPV in the worst 5% of scenarios, capturing tail risk better than VaR
- **P10/P50/P90 NPV**: percentile scenarios that map directly to the oil industry's reserve classification language

The formal definition of NPV-at-Risk is the gap between expected NPV and the α-percentile: **NPVaR_α = E[NPV] − Q_α(NPV)**. A critical methodological warning: discounting at a risk-adjusted rate (WACC) while also showing NPV as a distribution creates a "double-counting" problem, since the discount rate already embeds a risk premium. The pragmatic resolution is to use the mean of the NPV distribution as the decision-relevant NPV, while using the distribution shape and tail metrics for risk assessment. For option valuation specifically, use **risk-neutral simulation** (drift = r − δ, discount at risk-free rate) to avoid this issue entirely.

---

## Modeling the upgrading spread with mean-reverting stochastic processes

### Cold Lake bitumen and Synthetic Crude fundamentals

Cold Lake (CL) bitumen is produced via Cyclic Steam Stimulation from northeastern Alberta's Cold Lake deposit. Marketed as a dilbit blend (~21° API, ~4% sulphur), it trades at a heavy discount to WTI — typically **US$10–25/bbl at Hardisty**, similar to Western Canadian Select. Synthetic Crude Oil (SYN/SCO), benchmarked by Syncrude Sweet Premium at Edmonton, is the upgraded product: **~32° API, ~0.15% sulphur** (light sweet), trading near WTI parity (±US$5/bbl). Four Alberta upgraders (Syncrude, Suncor, CNRL Horizon, Shell Scotford) produce roughly **1.3–1.4 million bbl/day** of SCO.

The **upgrading spread** = Price(SYN) − Price(CL) typically ranges from **US$10–30/bbl**, widening dramatically during pipeline bottlenecks (potentially exceeding US$40/bbl during the October 2018 crisis) and compressing when heavy oil demand strengthens or new pipeline capacity comes online (post-TMX expansion in 2024). This spread exhibits strong **mean reversion** because upgraders increase throughput when the spread widens (consuming bitumen, increasing SCO supply) and reduce throughput when it narrows.

### The Ornstein-Uhlenbeck process is the right model

For commodity spreads, the Ornstein-Uhlenbeck (OU) process is the preferred stochastic model:

**dX_t = κ(μ − X_t)dt + σdW_t**

where κ is the mean-reversion speed, μ is the long-run equilibrium spread, and σ is volatility. The key properties that make OU ideal for spreads are: the stationary distribution is **N(μ, σ²/2κ)**, the half-life of mean reversion is **t₁/₂ = ln(2)/κ**, and the process can go negative (appropriate since the spread could theoretically invert). Geometric Brownian Motion is inappropriate for spreads — it cannot go negative, has no mean reversion, and its expected value grows unboundedly. For capturing extreme events like pipeline crises or production curtailments, a jump-augmented OU process adds Poisson jumps: **dX = κ(μ − X)dt + σdW + JdN**, where N is a Poisson process with intensity λ ≈ 0.5–2 jumps/year.

### Parameter estimation from historical data

Three estimation approaches exist, in order of sophistication:

**OLS regression** on the discretized OU: ΔX = a + bX_t + ε gives **κ̂ = −b̂/Δt**, **μ̂ = −â/b̂**, and **σ̂ = std(residuals)/√Δt**. This is fast but produces biased estimates of κ, especially with small samples.

**AR(1) reparametrization** exploits the exact discrete-time form: X_{t+Δt} = μ + φ(X_t − μ) + ε, where **φ = e^{−κΔt}**. Regressing X_{t+1} on X_t recovers φ directly, then κ = −ln(φ)/Δt.

**Maximum likelihood estimation** uses the exact Gaussian transition density. RTL's `fitOU()` function implements this, returning θ (mean-reversion speed), μ (long-run mean), annualized σ, and the half-life. For the CL-SYN spread, expect κ in the range of **1–6/year** (half-life of 1–8 months), μ around **US$15–25/bbl**, and σ around **US$5–15/bbl√year**. Always validate with an Augmented Dickey-Fuller test for stationarity, and note that post-TMX (May 2024) spread dynamics represent a structural regime change from pre-TMX conditions.

### Exact simulation avoids discretization error

The OU process admits an exact simulation formula (Doob's result):

**X(t+Δt) = μ + (X(t) − μ)e^{−κΔt} + σ√((1 − e^{−2κΔt})/2κ) · Z**

where Z ~ N(0,1). This is computationally identical in cost to the Euler scheme but eliminates discretization bias. For 20 years at monthly frequency, this means **240 time steps per path across 10,000+ simulation paths**.

---

## Real options transform a mediocre project into a strategic investment

### The expanded NPV framework

Traditional NPV assumes passive management — operate continuously regardless of market conditions. Real options recognize that management actively adapts, creating asymmetric payoffs that add value. Trigeorgis's foundational equation captures this:

**Expanded (Strategic) NPV = Static NPV + Value of Operating Flexibility**

The option premium is always ≥ 0, so a project with negative static NPV may have positive strategic NPV once flexibility is properly valued. McKinsey documented a case where an oil block valued at −$100M by NPV was worth +$100M with real options — a $200M difference from flexibility alone.

### Operating options: shutdown and restart thresholds

An upgrader's shutdown/restart option works as follows: when the processing spread (SYN − CL − variable opex) falls below a shutdown threshold, the operator halts production, incurring only fixed "warm idle" costs (~$5–10/bbl capacity equivalent) plus a one-time shutdown cost ($10–50M). When the spread recovers above a higher restart threshold, operations resume after paying a restart cost ($20–100M). The gap between shutdown and restart thresholds creates a **hysteresis band** — a zone of inaction that exists because switching costs make it suboptimal to toggle frequently.

The foundational model is **Brennan & Schwartz (1985)**, which valued a copper mine with shutdown/restart/abandonment options using contingent claims analysis. Within Monte Carlo simulation, this is implemented as a path-dependent algorithm:

```
For each path: track state (Operating/Idle)
  If Operating and spread < shutdown_threshold → switch to Idle, pay C_shutdown
  If Idle and spread > restart_threshold → switch to Operating, pay C_restart
  Record cash flow based on current state
```

The operating option value equals **E[NPV with flexibility] − E[NPV without flexibility]**. Higher commodity volatility increases this value — a crucial insight that reverses the typical executive intuition that "more uncertainty = worse."

### Expansion options as call options on project value

The right to expand capacity (e.g., add 50% throughput at Year 5 for capital cost I_E) is equivalent to a **call option**: max(x·V − I_E, 0), where x is the fractional expansion and V is the base project value. Within simulation, implement this as a decision gate:

At Year 5, if the trailing 12-month average spread exceeds an expansion threshold and the forward NPV of incremental cash flows exceeds I_E, exercise the expansion option and increase production. Otherwise, let the option expire (or defer to a later decision point). For optimal exercise boundaries, the **Longstaff-Schwartz Least-Squares Monte Carlo (LSM)** method regresses continuation values on state variables at each decision point.

---

## The RTL package provides purpose-built tools for this analysis

### Package overview

RTL (Risk Tool Library) is an R package for commodities trading, risk, and analytics, created by Philippe Cote at the Alberta School of Business (University of Alberta). It is available on **CRAN (v1.3.7, January 2025)** and GitHub (risktoollib/RTL). Key dependencies include dplyr, ggplot2, xts, and PerformanceAnalytics.

### Critical datasets for this project

**`fizdiffs`** contains randomized (for confidentiality) historical physical crude oil price differentials. It is a data frame with a `date` column and multiple numeric columns for Canadian crude grades including **WCS-related differentials**. This dataset likely includes Cold Lake and Synthetic Crude differentials — exactly what's needed for calibrating the upgrading spread model. Use it as: `RTL::fizdiffs %>% dplyr::select(date, dplyr::contains("WCS"))`.

**`usSwapCurves`** is a sample output of `RQuantLib::DiscountCurve()` — a US bootstrapped interest rate curve containing four components: `times` (numeric vector of tenors at monthly intervals from 0 to ~30 years), `discounts` (discount factors), `zeroRates` (zero-coupon rates), and `forwards` (forward rates). It is constructed using `DiscountCurve()` with `dt = 1/12` and spline interpolation, producing approximately **360 monthly points** — ready to use directly for discounting monthly cash flows over a 20-year horizon. Pass it directly to the `npv()` function.

### Simulation and valuation functions

| Function | Purpose | Key Parameters |
|----------|---------|----------------|
| **`simOU()`** | Ornstein-Uhlenbeck simulation | `nsims`, `S0`, `mu`, `theta` (κ), `sigma`, `T2M`, `dt`, `epsilon` |
| **`simOUt()`** | OU with time-varying mean | `mu` as tibble with columns `t` and `mr` |
| **`simOUJ()`** | OU with jump diffusion | Adds Poisson jump parameters |
| **`simGBM()`** | Geometric Brownian Motion | `S0`, `drift`, `sigma`, `T2M`, `dt` |
| **`fitOU()`** | Calibrate OU to data | Returns `theta`, `mu`, annualized `sigma`, half-life |
| **`npv()`** | Net present value | `init.cost`, `C`, `cf.freq`, `TV`, `T2M`, `disc.factors` |

The `simOU()` function's `epsilon` parameter is especially powerful: it accepts custom random draws, enabling **correlated multivariate simulation** via Cholesky decomposition. Generate correlated standard normals externally and feed them in to simulate correlated SYN and CL price paths. The workflow for this project is: (1) extract spread data from `fizdiffs`, (2) calibrate with `fitOU()`, (3) simulate paths with `simOU()`, (4) compute NPV per path using discount factors from `usSwapCurves`, (5) analyze the NPV distribution.

---

## Monte Carlo mechanics: convergence, correlation, and variance reduction

### How many simulations are enough

The standard error of the Monte Carlo mean estimate follows **SE = σ(NPV)/√N**, implying 1/√N convergence. Practical guidelines are:

**10,000 simulations** is the minimum for production-quality NPV@Risk analysis. This delivers ~1% precision on the mean (SE ≈ σ/100). For **tail risk metrics** (VaR, CVaR at 5%), roughly **4× more simulations** are needed for comparable accuracy, making 50,000 paths advisable. Industry practice ranges from 10,000 (NFCP R package default) to 100,000 (IMA case studies). Convergence should be verified by plotting cumulative mean NPV versus simulation count — when the line stabilizes, you have enough paths. A formal criterion is the coefficient of variation of the estimator: CV = SE/|mean| < 1–2%.

### Generating correlated price paths

If modeling SYN and CL as separate stochastic processes (rather than modeling the spread directly), their correlation must be preserved. Use **Cholesky decomposition**: given correlation matrix Σ, compute L = chol(Σ)ᵀ, generate independent standard normals Z, and transform via ε = L·Z. For two variables with correlation ρ:

```r
z1 <- rnorm(n)
z2 <- rho * z1 + sqrt(1 - rho^2) * rnorm(n)
```

Typical SYN-CL correlation is **0.85–0.95** (both are Alberta crude grades driven by common WTI movements). Feed these correlated draws into `simOU()` via the `epsilon` parameter.

### Variance reduction techniques

**Antithetic variates** provide the best effort-to-benefit ratio: for every path using shocks {ε}, also compute the mirror path using {−ε}, and average both. This can halve variance at negligible computational cost. The NFCP R package implements this by default. **Quasi-Monte Carlo** using Sobol or Halton low-discrepancy sequences can achieve O(1/N) convergence instead of O(1/√N) — a dramatic improvement, but implementation is more complex. **Control variates** use analytically solvable reference problems (e.g., a Black-Scholes European option) to reduce estimator variance.

---

## Discounting monthly cash flows using US swap curves

### Why swap curves, not Treasuries

SOFR-based swap curves have supplanted Treasury curves as the primary discounting benchmark because they represent actual private-sector borrowing costs without the "convenience yield" distortion embedded in Treasuries. The swap curve is observable at standardized tenors (ON through 30Y) with deep liquidity, and project finance cash flows can be directly hedged with interest rate swaps. RTL's `usSwapCurves` is bootstrapped from market quotes using `RQuantLib::DiscountCurve()`.

### Interpolation for 240 monthly discount factors

The `usSwapCurves` dataset already contains monthly discount factors out to 30 years, so for this project it can be used directly. If constructing a custom curve, the standard approach is:

**Bootstrap** zero-coupon rates from observable swap par rates. Short-end rates (< 1Y) convert directly from deposit rates. Long-end rates are extracted iteratively: for each successive swap maturity, solve for the zero rate that makes the swap value equal to par, using previously computed discount factors for intermediate coupons.

**Nelson-Siegel interpolation** provides smooth rates at any tenor using just four parameters: r(τ) = β₀ + β₁[(1−e^{−τ/λ})/(τ/λ)] + β₂[(1−e^{−τ/λ})/(τ/λ) − e^{−τ/λ}]. Here β₀ captures the long-term rate level, β₁ the slope, β₂ the curvature, and λ controls where curvature peaks. The R package `YieldCurve` implements this directly: `Nelson.Siegel(rates, maturity)` returns fitted parameters, and `NSrates(params, maturity = 1:240)` generates monthly rates. Convert to discount factors via **DF(t) = exp(−r(t) · t)** for continuous compounding.

---

## Communicating stochastic results in a deterministic world

### The strategic NPV waterfall bridges both frameworks

The single most effective executive communication tool is a **waterfall chart** that starts from familiar ground:

**Base (Static) NPV** → + Operating Option Value (shutdown/restart flexibility) → + Expansion Option Value (right to expand if favorable) → = **Total Strategic NPV**

Each increment has a concrete narrative. The operating option value becomes: "If we shut down during periods when the upgrading spread is negative instead of losing money every month, the project is worth $X more." The expansion option becomes: "Having the right — but not the obligation — to add 50% capacity in Year 5 is worth $Y, because we only expand when market conditions justify it." This decomposition anchors executives in the deterministic NPV they understand, then incrementally introduces the value of flexibility.

### Five visualizations that work for board presentations

**Tornado charts** rank input variables by their impact on NPV, immediately directing attention to what matters most (likely the long-run spread mean and volatility). **Fan charts** show percentile bands of projected cash flows or spreads widening over time — the Bank of England pioneered these in 1997, and they intuitively convey growing uncertainty. **NPV histograms** with VaR and the zero-line marked are the primary Monte Carlo output. **S-curves** (cumulative probability plots) enable precise statements like "there is a 75% probability that NPV exceeds $80M." **Decision maps** (2×2 matrices of price × volume scenarios with optimal actions) translate complex optionality into actionable guidance.

### The P10/P50/P90 language executives already speak

The oil and gas industry's reserve classification (P90 = proved, P50 = probable, P10 = possible) provides a ready-made probabilistic vocabulary. Frame NPV@Risk results in these terms: "The P90 (conservative) NPV is $25M, the P50 (most likely) is $120M, and the P10 (upside) is $280M." **Swanson's Mean** — 0.30 × P10 + 0.40 × P50 + 0.30 × P90 — provides a quick approximation of the expected value that bridges probabilistic and deterministic worlds. However, note that P90 reserves do not produce P90 NPV; the NPV distribution reflects economic uncertainties beyond volume risk alone.

---

## Putting it all together: the complete simulation workflow

The implementation follows six sequential steps:

**Step 1 — Calibrate the spread model.** Extract CL and SYN differential data from `RTL::fizdiffs`. Compute the upgrading spread. Apply `RTL::fitOU()` to obtain κ, μ, and σ. Validate with an ADF test and check the half-life for economic reasonableness (expect 1–8 months).

**Step 2 — Build the base DCF model.** Define upgrader economics: production rate (bbl/day), variable opex (typically $15–25/bbl), fixed costs, royalties, taxes, and initial capex. Use `RTL::usSwapCurves` for discount factors.

**Step 3 — Simulate without options.** Run `RTL::simOU()` for 10,000+ paths over 20 years at monthly frequency. Compute NPV per path assuming rigid always-on operation. This produces the static NPV distribution.

**Step 4 — Add operating options.** Re-run with path-dependent shutdown/restart logic: if spread < shutdown threshold, switch to idle (pay only fixed costs); if idle and spread > restart threshold, resume operations (pay restart cost). The operating option value is the difference in mean NPV between flexible and rigid operation.

**Step 5 — Add expansion option.** At Year 5, if trailing 12-month average spread exceeds the expansion threshold, invest additional capex and increase production by the expansion fraction. The expansion option value is the incremental mean NPV from this flexibility.

**Step 6 — Analyze and present.** Compute all risk metrics (mean, P(loss), VaR₅%, CVaR₅%, P10/P50/P90). Build the executive waterfall chart. Generate tornado, fan, histogram, and S-curve visualizations.

---

## Conclusion: what makes this analysis work

Three insights distinguish excellent NPV@Risk analysis from naive simulation. First, **the OU process is non-negotiable for spreads** — GBM's lack of mean reversion produces economically absurd long-horizon forecasts, while OU's mean-reverting property correctly reflects the equilibrium forces governing upgrading economics. Second, **operating flexibility is where the real value lies** — for a project with volatile processing margins, the shutdown/restart option alone can shift NPV from negative to positive, turning an apparently marginal investment into a sound one. Third, **communication determines whether the analysis influences decisions** — the strategic NPV waterfall, translated into the P10/P50/P90 language that oil executives already use, bridges the gap between stochastic rigor and boardroom reality. The RTL package's integrated toolkit — from `fitOU()` for calibration to `simOU()` for simulation to `npv()` with `usSwapCurves` for discounting — makes R a production-ready platform for this entire workflow.