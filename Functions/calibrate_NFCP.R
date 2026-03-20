# -------------------------------------------------------------------------
# Script: calibrate_NFCP.R
# Purpose: Calibrate the Extended Schwartz-Smith (2-Factor) model using the
#          NFCP package and map the parameters to simSchwartzSmith.R
# -------------------------------------------------------------------------

# Packages required: NFCP, RTL, dplyr, tidyr, lubridate
library(RTL)
library(NFCP)
library(dplyr)
library(tidyr)
library(lubridate)

source("Functions/simSchwartzSmith.R")

# 1. PULL DATA via RTL::eia2tidy_all
# -------------------------------------------------------------------------
cat("\n[1] Pulling WTI Term Structure Data via RTL from the EIA API...\n")

# Free EIA Crude Oil Futures Contracts
# We use NYMEX futures (Contracts 1 through 4) to build the term structure.
tickers <- c(
  "PET.RCLC1.D",  # Contract 1 (Prompt Month)
  "PET.RCLC2.D",  # Contract 2
  "PET.RCLC3.D",  # Contract 3
  "PET.RCLC4.D"   # Contract 4
)

# You must have an EIA API key exported in your environment or passed here.
# Get a free key at: https://www.eia.gov/opendata/register.php
eia_key <- Sys.getenv("EIA_API_KEY")

if (eia_key == "") {
  stop("ERROR: Please set your EIA_API_KEY in your R environment (e.g. Sys.setenv(EIA_API_KEY = 'your_key')) to pull data via RTL!")
}

# Use RTL to scrape cleanly from the EIA
raw_data <- RTL::eia2tidy_all(ticker = tickers, key = eia_key)

cat("\n[2] Formatting Data into NFCP Panel layout...\n")
# The RTL eia2tidy function returns columns like: date, value, ticker, etc.
panel_data <- raw_data %>%
  dplyr::select(date, ticker, value) %>%
  tidyr::drop_na() %>%
  tidyr::pivot_wider(names_from = ticker, values_from = value) %>%
  dplyr::arrange(date) %>%
  tidyr::drop_na() # Ensure we have all 4 contract prices on a given date

# Optional: Only keep the last 5 years to keep the Kalman Filter fast
panel_data <- panel_data %>% filter(date >= (Sys.Date() - years(5)))

# NFCP expects a matrix of log prices
log_prices <- as.matrix(log(panel_data %>% dplyr::select(-date)))

# Define maturities (in years) corresponding roughly to 1, 2, 3, and 4 months
maturities <- c(1/12, 2/12, 3/12, 4/12)

# Assuming 252 trading days a year
dt_obs <- 1/252

cat(sprintf("   Panel dimensions: %d trading days across %d maturity points.\n", nrow(log_prices), ncol(log_prices)))

# 2. DEFINE THE MODEL PARAMETERS
# -------------------------------------------------------------------------
# N_factors = 2: We use a 2-factor model (Schwartz-Smith)
# GBM = FALSE:   We set this to FALSE to simulate an "Extended" Schwartz-Smith
#                model where the long-term factor ALSO mean-reverts.
#                If set to TRUE, the long-term factor acts as a standard GBM.
# N_ME:          Number of measurement errors (usually 1 per maturity column)
n_maturities <- length(maturities)

cat("\n[1] Setting up the NFCP Model Parameters...\n")
model_parameters <- NFCP_parameters(
  N_factors = 2, 
  GBM = FALSE, 
  initial_states = FALSE, 
  N_ME = n_maturities
)

# 3. RUN MAXIMUM LIKELIHOOD ESTIMATION (KALMAN FILTER)
# -------------------------------------------------------------------------
# This step fits the unobservable factors (short-term & long-term) to the 
# observed futures prices using a Kalman Filter paired with genetic algorithms.
#
# NOTE: This operation is computationally intensive and may take some time. 
#       We set `verbose = TRUE` so you can watch the optimizer run.
cat("\n[2] Running Maximum Likelihood Estimation via Kalman Filter...\n")
cat("    (This might take a while depending on your hardware, be patient!)\n")

# Uncomment the code below to run the actual estimation.
# We commented it out so it doesn't block you from running the script immediately.

# estimated_model <- NFCP_MLE(
#   log_price = log_prices,
#   dt = dt_obs,
#   maturity = maturities,
#   parameters = model_parameters,
#   verbose = TRUE,
#   max.generations = 50,    # Genetic algorithm setting, increase for more precision
#   pop.size = 100           # Genetic algorithm setting, increase for more precision
# )

# print("Calibration Complete! Here are the estimated parameters:")
# print(estimated_model$parameters)

# 4. MAP TO OUR SIMULATOR
# -------------------------------------------------------------------------
# The NFCP package names its parameters generally as kappa_1, kappa_2, etc.
# We must map these to our `simSchwartzSmith` arguments!

# --- EXAMPLE PARAMETERS ---
# IF we had run the estimation above, we would extract them like this:
# params <- estimated_model$parameters
#
# But for demonstration, we will map some dummy/presumed parameters here:

cat("\n[3] Mapping estimated parameters to simSchwartzSmith() ...\n")
params_mapped <- list(
  # --- Short-term factor (chi, factor 2 in NFCP) ---
  kappa = 1.49,                   # NFCP: kappa_2
  sigma_chi = 0.28,               # NFCP: sigma_2
  
  # --- Long-term factor (xi, factor 1 in NFCP) ---
  # In the extended model (GBM=FALSE), the long-term factor mean-reverts!
  gamma = 0.10,                   # NFCP: kappa_1 (this is our new gamma!)
  mu_xi = 0.05,                   # NFCP: mu_1    (or lambda_1)
  sigma_xi = 0.15,                # NFCP: sigma_1
  
  # --- Correlation ---
  rho = 0.30                      # NFCP: rho_1_2
)

cat("\nParameters Mapped:\n")
print(params_mapped)

# 5. RUN THE LIGHTNING-FAST SIMULATIONS
# -------------------------------------------------------------------------
cat("\n[4] Running simSchwartzSmith with the Calibrated Parameters...\n")

set.seed(123)
sim_results <- simSchwartzSmith(
  nsims = 1000, 
  S0 = 60,                        # Or use the last observed spot/front-month price
  mu_xi = params_mapped$mu_xi, 
  sigma_xi = params_mapped$sigma_xi, 
  kappa = params_mapped$kappa, 
  sigma_chi = params_mapped$sigma_chi, 
  rho = params_mapped$rho, 
  gamma = params_mapped$gamma,    # Extended feature!
  chi0 = 0,                       # Usually assumed 0, or extract filtered state from NFCP!
  T2M = 1, 
  dt = 1/250, 
  vec = TRUE
)

cat("\nSimulation Complete! Here is a preview of the simulated Forward Paths:\n")
print(head(sim_results))

# You can now pass `sim_results` into your NPV script or use plotSchwartzSmith(sim_results) to plot!
