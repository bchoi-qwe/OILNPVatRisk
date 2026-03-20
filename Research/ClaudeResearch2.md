# Simulation methodology for a Cold Lake–SYN upgrader NPV@Risk model

**Model the CL-SYN spread directly as an Ornstein-Uhlenbeck process, but simulate WTI separately because Alberta royalties are explicitly price-linked.** This hybrid architecture—a stochastic WTI price driving a deterministic royalty function, combined with a mean-reverting spread for the upgrading margin—captures the two dominant value drivers while avoiding unnecessary multivariate complexity. The Trans Mountain Expansion (TMX) in May 2024 represents a known structural break that compressed differentials by **~$5–7/bbl** and demands a piecewise calibration strategy. For a 20-year projection, the single most critical technical issue is upward bias in the mean-reversion speed estimator κ, which can exceed **200% relative bias** in small samples and would systematically understate long-run spread uncertainty.

---

## Single spread modeling outperforms joint simulation for upgrader valuation

The foundational architectural choice—model one spread process or simulate multiple correlated prices—has a clear empirical answer. Mahringer and Prokopczuk (2015) directly compared univariate spread modeling against bivariate GARCH for crack spread options and found the **simpler univariate approach was superior** in pricing performance. The theoretical justification is equally strong: if Cold Lake bitumen and Synthetic Crude are cointegrated (testable via Engle-Granger or Johansen tests), then their spread is stationary by definition, and an OU process is the natural continuous-time representation.

The economic logic reinforces this. The CL-SYN spread mean-reverts because of a negative feedback mechanism: when the upgrading margin widens, operators increase processing throughput, which tightens the spread; when it narrows, processing curtailments allow it to widen. This is the same arbitrage-driven mean-reversion that Schwartz (1997) documented for commodity prices generally, but it operates more cleanly for processing margins than for absolute price levels.

However, pure single-spread modeling has a critical limitation for this specific application. **Alberta's oil sands royalty regime is an explicit function of WTI price in Canadian dollars**, with pre-payout gross royalties ranging from 1% at C$55/bbl WTI to 9% at C$120/bbl, and post-payout net royalties ranging from 25% to 40% over the same price range. A $10/bbl WTI move shifts the gross royalty rate by ~1.2 percentage points and the net royalty rate by ~2.3 percentage points. At Suncor's ~330,000 bbl/d upgrader scale, a single percentage point in royalty rate represents roughly **$440 million annually**. This means WTI cannot be collapsed into the spread—it must be modeled as a separate stochastic factor.

The recommended architecture therefore uses **two stochastic processes**: (1) WTI price modeled as a Schwartz-Smith two-factor process (short-term OU deviations plus long-term GBM, calibrated via Kalman filter on the futures term structure), and (2) the CL-SYN spread modeled as an OU process with time-varying mean. Royalties are then derived deterministically from WTI × USD/CAD using the statutory sliding-scale formulas. This captures the essential nonlinearity without requiring a full multivariate simulation of individual crude grades. Nakajima and Ohashi (2016) showed that ignoring cointegration in commodity spread models can **overprice spread options for maturities beyond 6 years**, making the direct spread approach particularly important for a 20-year upgrader.

---

## WTI levels matter through royalties and exchange rates, not location arbitrage

Beyond royalties, the question of whether absolute WTI levels create operational optionality through location choice depends heavily on the entity. For Suncor specifically, location arbitrage is a **second-order effect** for three reasons. First, approximately two-thirds of Suncor's oil sands output is upgraded to SCO, which trades within $0–3/bbl of WTI and is less affected by pipeline egress constraints. Second, Suncor consumes roughly **466,000 bbl/d** across its own refineries in Edmonton, Montreal, Sarnia, and Commerce City, insulating a large portion of production from market differentials entirely. Third, Suncor holds committed pipeline capacity on TMX ($5.9 billion over 20 years take-or-pay), Enbridge Mainline, and other systems, making its transportation costs largely deterministic rather than stochastic.

The location spreads themselves are modest relative to the upgrading margin. The Hardisty-to-Houston transportation spread is typically **$7–10/bbl**, while the Hardisty-to-Cushing spread is **$5–7/bbl**. Pipeline tariffs are contractual or regulated: ~$10/bbl for Enbridge to the US Gulf Coast, ~$11.46/bbl for TMX committed shippers, ~$5.50–7.00/bbl for Keystone to Cushing. These should be treated as **deterministic inputs** in the model, not stochastic risk factors. Enbridge cut its joint tariff rates by ~11% in September 2024 to compete with TMX, illustrating that tariff competition exists but changes slowly through regulatory processes.

For a pure bitumen producer like MEG Energy or Cenovus, location optionality would be more material because the entire revenue stream depends on the WCS-WTI differential, and the $7–10/bbl Hardisty-Houston spread is a larger fraction of their netback. But for Suncor's upgrader, the **upgrading spread of $10–20/bbl dominates** all location-based value. The model should include WTI (for royalties and the Schwartz-Smith long-term factor), the CL-SYN spread (the core value driver), and USD/CAD (for royalty conversion). Carbon costs under Alberta's TIER system are negligible at ~$0.09/bbl average today and projected ~$0.50/bbl by 2030, safely treated as a fixed operating cost escalator.

---

## Three stochastic processes compared: plain OU wins as baseline, regime-switching adds most value for 20-year horizons

**Plain Ornstein-Uhlenbeck** (dS = κ(θ − S)dt + σdW) requires only three parameters, has an exact discretization with no approximation error, a known stationary distribution N(θ, σ²/2κ), and a closed-form half-life of ln(2)/κ. The AR(1) representation at discrete time steps (S_{t+1} = c + φS_t + ε_t with φ = e^{−κΔt}) makes estimation straightforward. RTL's `fitOU()` function implements exactly this OLS/AR(1) approach. For a first-pass model, OU is the right starting point.

**OU with Poisson jumps** (OUJ) adds three parameters: jump intensity λ, mean jump size μ_J, and jump size volatility σ_J. The model captures the fat tails and sudden spread widenings observed during pipeline crises (the November 2018 WCS blowout to >$40/bbl discount) or refinery outages. Göncü and Akyildirim (2016) rejected normality of AR(1)-corrected residuals for all 23 commodity futures tested, supporting jump specifications. However, OUJ estimation is substantially more complex—the likelihood involves summing over possible jump counts in each interval, typically requiring EM algorithms or threshold-based jump filtering. For **20-year projections, jumps matter less** than getting the mean-reversion dynamics right, because individual jumps wash out over long horizons while the mean-reversion level and speed compound over the entire project life.

**Regime-switching OU** adds the most genuine value for long-horizon upgrader valuation. Parameters (κ, θ, σ) switch between states governed by a hidden Markov chain, typically two regimes: a "normal" state with moderate spreads and a "stressed/constrained" state with wide spreads and high volatility. The TMX startup in May 2024 is precisely the kind of structural shift that regime-switching captures. Chen and Insley (2012) demonstrated that regime-switching commodity models more closely match futures prices and produce significantly different real asset values and optimal operating thresholds compared to single-regime models. For 20-year horizons, the probability of future structural shifts (new pipelines, regulatory changes, energy transition effects) is non-trivial, and regime-switching provides a principled framework for incorporating this uncertainty.

A critical caveat applies to testing regime-switching models. The standard likelihood ratio test has a **non-standard distribution** under the null hypothesis of no regime switching (the Davies problem—transition probabilities are unidentified under the null). Model selection should rely on **AIC/BIC rather than LRT** for comparing OU against regime-switching OU. BIC is preferred because it penalizes complexity more heavily and is appropriate when the goal is long-horizon forecasting rather than in-sample fit.

| Model | Parameters | Estimation | Best for | Weakness |
|-------|-----------|------------|----------|----------|
| Plain OU | κ, θ, σ (3) | OLS/AR(1) or exact MLE | Baseline; long-horizon mean behavior | Gaussian tails; no structural shifts |
| OU + Jumps | κ, θ, σ, λ, μ_J, σ_J (6) | EM algorithm or threshold filtering | Short-horizon tail risk | Jumps wash out over 20 years; estimation complex |
| Regime-switching OU | κ₁, θ₁, σ₁, κ₂, θ₂, σ₂, p₁₁, p₂₂ (8) | Hamilton filter + EM | Long-horizon structural uncertainty | Overfitting risk; non-standard tests; regimes may be spurious |

---

## κ bias is the most consequential estimation problem for long-horizon projections

The mean-reversion speed κ is notoriously biased upward in finite samples, and this bias is **the single most critical technical issue** for a 20-year projection. The bias is of order O(T⁻¹) where T is the total observation span—not the number of observations. This means 2 years of daily data and 2 years of hourly data have essentially the same κ bias. Phillips and Yu (2005) documented relative biases exceeding 200% even with monthly data spanning 10+ years. Bao, Ullah, Wang, and Yu (2015) proved that the MLE always has a positive bias, meaning the model systematically overestimates mean-reversion speed.

An upward-biased κ is catastrophic for long-horizon spread simulation. It produces a half-life that is too short, which means the simulated spread reverts to its long-run mean too quickly. This **understates the long-run variance** of the spread, overstates the probability of the spread returning to equilibrium, and underprices the optionality embedded in extreme spread levels. For a 20-year NPV@Risk analysis, even a 20–30% overestimate of κ dramatically narrows the simulated NPV distribution and understates tail risk.

The four common estimation approaches are mathematically equivalent for the Gaussian OU case:

- **OLS on discretized OU**: Regress S_{t+1} on S_t, recover κ = −ln(φ̂)/Δt, θ = â/(1−φ̂). This is what RTL's `fitOU()` implements.
- **AR(1) reparametrization**: Identical to OLS. The AR(1) coefficient φ maps to κ via the exponential transformation.
- **Exact MLE**: The Gaussian transition density is known in closed form, so the exact log-likelihood can be maximized. García Franco (2023) showed this reduces to a one-dimensional optimization over κ with closed-form solutions for θ and σ² conditional on κ. Results are identical to OLS for equally-spaced data.
- **RTL `fitOU()`**: Uses the OLS/AR(1) approach with annualized σ and periodicity-adjusted half-life.

All four methods share the same upward κ bias. The recommended mitigation is **parametric bootstrap bias correction** following Tang and Chen (2009): estimate κ̂ from data, simulate many OU paths with the estimated parameters, re-estimate κ̂ on each simulated path, compute the average bias, and subtract it from the original estimate. This effectively reduces both bias and MSE. Yu (2012) provided closed-form bias approximations that can serve as a quick check, including a nonlinear correction term that is particularly important in the near-unit-root case (slow mean reversion), which is empirically realistic for commodity spreads.

---

## The TMX structural break demands a piecewise calibration strategy

The Trans Mountain Expansion commenced commercial operations on **May 1, 2024**, nearly tripling pipeline capacity from ~300,000 to ~890,000 bbl/d and increasing Western Canadian export capacity to tidewater by approximately 700%. The impact on differentials was immediate and dramatic. The WCS-WTI differential narrowed from a pre-TMX average of **~$17–19/bbl to ~$11–13/bbl**, with the egress-scarcity premium of ~$5–8/bbl largely eliminated. The Q4 2024 seasonal widening—historically the most pronounced period, with differentials blowing out by $3–8/bbl—essentially **disappeared**, with spreads narrower by ~$12/bbl compared to Q4 2023.

This is a known, exogenous structural break—not a stochastic regime shift. The break date is precisely known, the mechanism is clear, and the direction is permanent. The optimal calibration strategy is a **piecewise model** rather than a pure regime-switching approach:

- **θ (long-run mean)**: Calibrate exclusively on post-TMX data, supplemented by the AER forward curve (~$13/bbl for WCS-WTI long-term). Pre-TMX θ estimates of $17–19/bbl are no longer relevant. For the CL-SYN spread specifically, the post-TMX equilibrium is approximately **$9–14/bbl**, down from $14–19/bbl pre-TMX.
- **κ (mean-reversion speed)**: Calibrate on the full historical sample using a piecewise θ specification (dS = κ[θ(t) − S]dt + σdW, where θ(t) = θ_pre for t < May 2024 and θ_post for t ≥ May 2024). The rationale is that κ reflects market microstructure and arbitrage dynamics, not infrastructure levels, so the full sample provides more statistical power.
- **σ (volatility)**: Calibrate on post-TMX data, since pre-TMX volatility included egress-crisis spikes that are no longer structurally relevant. Post-TMX σ is likely materially lower.

With only ~23 months of post-TMX data as of March 2026, parameter estimates will have wide confidence intervals. A **Bayesian approach** with informative priors—κ prior from pre-TMX estimation, θ prior anchored to the AER forward curve and post-TMX data—provides the most principled framework for combining limited post-break data with prior knowledge. Formally confirm the break with a Chow test at May 2024, and run a Bai-Perron test as a robustness check to verify no other significant breaks are missed.

The AER forecasts WCS-WTI at $11/bbl (2025), $12/bbl (2026), and $13/bbl (2027+), but cautions that Canadian production growth may again exceed egress capacity by **2027–2028**, potentially re-widening differentials. The 20-year model should therefore allow for the possibility of future structural shifts—either through regime-switching or through scenario analysis with distinct "TMX world" versus "capacity-constrained" parameter sets.

---

## Seasonality has been attenuated by TMX but deserves testing

Pre-TMX, Alberta crude differentials exhibited clear seasonal patterns: **Q4 widening** driven by maximum bitumen production ahead of spring turnarounds, lower US refinery demand during fall maintenance, increased diluent requirements in cold weather, and peak pipeline apportionment. The typical Q4 premium was $3–8/bbl additional widening. However, the 2024 Q4 data showed this seasonal effect essentially vanishing post-TMX—the spread was narrower by $12/bbl compared to the previous two years' Q4 averages.

The standard approach for incorporating seasonality into an OU model is a time-varying mean: dS = κ[θ(t) − S]dt + σdW, where θ(t) = θ₀ + α₁cos(2πt) + β₁sin(2πt) for an annual harmonic. RTL's `simOUt()` function supports this directly through a time-varying μ parameter. Whether this complexity is justified depends on statistical significance testing of the seasonal coefficients in the post-TMX sample. Given only two years of post-TMX data, there is insufficient statistical power to precisely estimate seasonal amplitude. The recommended approach is to **estimate seasonality on the full sample with an interaction term** (pre/post-TMX × seasonal dummies) to test whether TMX attenuated the seasonal component. If the post-TMX seasonal amplitude is statistically insignificant, drop it. If significant but reduced, include it at the reduced amplitude.

Over a 20-year horizon, seasonality is a **second-order effect** relative to the long-run mean and mean-reversion speed. An incorrectly specified θ by $5/bbl matters far more than a seasonal wobble of $2–3/bbl. Seasonality matters most for short-horizon cash flow timing and working capital analysis, less for the NPV@Risk distribution.

---

## Constant correlation with Cholesky is sufficient for the 20-year horizon

If the model simulates multiple stochastic factors (WTI price and CL-SYN spread, potentially with USD/CAD), correlation must be modeled. The options range from constant Pearson correlation with Cholesky decomposition through DCC-GARCH to copula approaches (Gaussian, Student-t, vine copulas).

For a 20-year NPV@Risk analysis, **constant correlation is sufficient and appropriate**. DCC-GARCH dynamics converge to the unconditional correlation over long horizons, eliminating the advantage of time-varying modeling. Copula approaches (particularly Student-t copulas, which Aepli et al. 2017 found outperform Gaussian copulas for commodity dependence) add genuine value only when the valuation is sensitive to joint tail events at short horizons—relevant for trading desk VaR but not for multi-decade project valuation. The parameter estimation uncertainty in correlation (standard errors of ~0.05–0.10 with 10–15 years of monthly data) already dominates any gains from more sophisticated dependence modeling.

The correlation between WTI and WCS is typically **ρ ≈ 0.92–0.97 in price levels** and **ρ ≈ 0.80–0.90 in returns**. Between WTI and SCO, return correlation is approximately 0.90–0.95. These correlations break down asymmetrically during stress: they increase during global macro shocks (like COVID) but decrease during localized infrastructure shocks (like the 2018 pipeline crisis). This asymmetry matters in principle, but for the recommended architecture—where the spread itself is modeled directly as an OU process rather than derived from separate price simulations—the correlation breakdown is already implicitly captured in the spread's own volatility dynamics.

If cointegration between CL and SYN is confirmed (the Engle-Granger test should be run as a prerequisite), this provides the strongest possible justification for direct spread modeling. Farkas et al. (2017) showed that cointegration creates an **upward-sloping term structure of correlation** that lowers long-horizon spread volatility. Ignoring cointegration in a multivariate simulation can produce pathological results where the spread diverges unrealistically over 20 years.

---

## Validation diagnostics that should accompany the chosen model

A defensible model requires a structured validation package. The essential diagnostics fall into three categories.

**Distributional validation** should compare simulated versus historical spread distributions at multiple horizons (1-month, 1-year, 5-year) using QQ plots and moment comparisons (mean, variance, skewness, kurtosis). A well-calibrated OU model should produce QQ plots that are approximately linear, with departures only at the extreme tails if jumps are present but not modeled. The stationary distribution should be approximately N(θ, σ²/2κ) for the OU model—compare this to the unconditional historical distribution of the post-TMX spread.

**Mean-reversion validation** should verify that the simulated half-life (ln(2)/κ) matches the historical estimate within approximately 20%. Run an ADF test on long simulated paths to confirm stationarity is preserved. For the WCS-WTI differential, the historical half-life is roughly **1–3 months** based on error-correction model estimates. If the simulated half-life deviates substantially, the κ estimate may be biased.

**Out-of-sample and coverage testing** should use rolling-window backtests: calibrate on data up to time T, simulate forward, and check that realized spread values fall within the simulated 5th–95th percentile band approximately 90% of the time. For model comparison (OU vs. OUJ vs. regime-switching), use BIC as the primary criterion for long-horizon selection, supplemented by out-of-sample predictive log-likelihood. The **convergence test** is also essential: re-run the full Monte Carlo with a different random seed and verify that P5, P50, and P95 of the NPV distribution differ by less than 2%. With 10,000 paths and antithetic variates, this should be achievable; increase to 50,000 paths if tail metrics need tighter stability.

---

## Recommended simulation framework: what adds value versus what adds complexity

The following table summarizes each modeling choice with a clear recommendation and rationale.

| Decision | Recommendation | Rationale |
|----------|---------------|-----------|
| Spread vs. joint simulation | **Direct spread OU + separate WTI** | Mahringer & Prokopczuk (2015); cointegration; royalty needs WTI |
| WTI process | Schwartz-Smith two-factor | Best-established for long-horizon commodity valuation |
| Spread process | OU baseline; test regime-switching | OU for tractability; RS-OU for structural break robustness |
| Jump-diffusion | Test but likely unnecessary | Jumps wash out over 20 years; estimation costly |
| Estimation method | OLS/AR(1) via RTL `fitOU()` + bootstrap κ correction | Tang & Chen (2009) correction is essential |
| Calibration window for θ | Post-TMX only (~23 months) | Pre-TMX θ is structurally wrong |
| Calibration window for κ | Full history with piecewise θ | More data reduces κ bias |
| Seasonality | Test significance post-TMX; include if material | Likely attenuated; second-order for 20-year NPV |
| Location arbitrage | Exclude (deterministic tariffs only) | Second-order for Suncor's upgraded SCO |
| Correlation modeling | Constant Pearson + Cholesky | DCC/copula converge to unconditional over 20 years |
| Royalties | Deterministic function of WTI × USD/CAD | Statutory sliding scale; no stochastic model needed |
| Carbon costs | Fixed escalator (~$0.50/bbl by 2030) | Negligible at current and projected levels |
| Number of MC paths | 10,000 with antithetic variates | 50,000 for stable tail quantiles |

## Conclusion

The core insight unifying these recommendations is that **model selection for 20-year real asset valuation should prioritize the long-run equilibrium specification over short-term distributional accuracy**. Getting θ right matters more than capturing jumps; getting κ unbiased matters more than modeling time-varying correlation; and acknowledging the TMX structural break matters more than any stochastic process refinement. The defensible framework is a two-factor model (WTI price + CL-SYN spread) with an OU spread process, piecewise calibration around the May 2024 structural break, and bootstrap-corrected κ estimation. Regime-switching adds genuine option value for capturing the possibility of future structural shifts over 20 years. Everything else—jumps, DCC-GARCH, copulas, multi-location modeling—adds complexity without proportional insight for this specific application. The biggest model risk is not the choice between OU and OUJ; it is the assumption that any single parameterization will remain valid for two decades. **Scenario analysis across distinct structural regimes** provides more decision-relevant information than incremental gains in within-regime distributional modeling.