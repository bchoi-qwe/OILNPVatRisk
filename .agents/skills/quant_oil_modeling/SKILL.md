---
name: Quantitative Oil Spread Modeling
description: Advanced rules for modeling the upgrading spread, pipelines, and running Ornstein-Uhlenbeck processes in energy markets.
---

# Quantitative Oil Spread Modeling

When working on the `OIL NPV at Risk` simulator, bear in mind the core structural realities of the Canadian heavy-light crude market:

### Market Fundamentals
- **WTI (West Texas Intermediate):** The absolute baseline reference price.
- **WCS (Western Canadian Select):** The heavy sour benchmark. Trades at a discount (differential) to WTI based on (1) Quality/Upgrading cost (heavy/sour penalty) and (2) Location/Transportation cost (pipeline bottlenecks out of Hardisty).
- **SYN (Synthetic Crude):** Upgraded bitumen. Trades much closer to WTI as a sweet light crude.
- **Upgrading Spread:** Mathematically `SYN - WCS`. This is the fundamental premium captured by upgraders.

### Modeling Stochastic Processes (simOU)
- **Mean Reversion (θ & μ):** Commodity spreads are structurally mean-reverting due to supply/demand elasticity. If the upgrading spread blows out, producers shut in or rail is mobilized, pulling the spread back.
- **Asymmetric Jumps:** Pipeline outages or sudden OPEC cuts create severe, asymmetric price jumps. Your models should ideally incorporate jump-diffusions (Merton models) overlaying the OU process.
- **Greeks / Sensitivities:** Carefully track structural constraints (like the $15-$20/bbl pipeline equivalent threshold). If the spread crosses this, transportation by rail becomes profitable, acting as an economic ceiling to the differential.

### Validating Simulations
Always validate simulated trajectories against empirical histograms (e.g., checking for fat tails via kurtosis, and directional bias via skewness) rather than just fitting a Normal distribution.
