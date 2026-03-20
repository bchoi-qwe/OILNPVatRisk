# Ensure Rcpp is available and compile the C++ function if not already loaded
if (!requireNamespace("Rcpp", quietly = TRUE)) {
  stop("Please install the 'Rcpp' package to use the fast C++ implementation.")
}
if (!exists("rcppOU", mode = "function")) {
  if (file.exists("src/rcppOU.cpp")) {
    Rcpp::sourceCpp("src/rcppOU.cpp")
  } else if (file.exists(file.path(dirname(sys.frame(1)$ofile), "../src/rcppOU.cpp"))) {
    # Fallback to relative path if sourced from another directory
    Rcpp::sourceCpp(file.path(dirname(sys.frame(1)$ofile), "../src/rcppOU.cpp"))
  }
}

#' Schwartz-Smith two-factor model simulation
#' @description Simulates WTI price using the Schwartz-Smith two-factor model (short-term OU deviations + long-term GBM). Leverages the project's rcppOU C++ implementation for massive performance gains.
#' @param nsims Number of simulations. Defaults to 1. `numeric`
#' @param S0 Spot price at t=0. `numeric`
#' @param mu_xi Long-term drift of the equilibrium price in percentage. `numeric`
#' @param sigma_xi Long-term volatility of the equilibrium price. `numeric`
#' @param kappa Short-term mean reversion speed (theta in simOU). `numeric`
#' @param sigma_chi Short-term volatility. `numeric`
#' @param rho Correlation between short and long term shocks ([-1, 1]). `numeric`
#' @param gamma Long-term mean reversion speed. If 0, model defaults to standard Schwartz-Smith ABM. `numeric`
#' @param chi0 Initial short-term deviation. Defaults to 0. `numeric`
#' @param lambda_chi Short-term market price of risk. `numeric`
#' @param lambda_xi Long-term market price of risk. `numeric`
#' @param T2M Maturity in years. `numeric`
#' @param dt Time step in period e.g. 1/250 = 1 business day. `numeric`
#' @returns A list of tibbles containing simulated values for `S`, `chi`, and `xi`. `list`
#' @export simSchwartzSmith
#' @author Antigravity
#' @examples
#' simSchwartzSmith(nsims = 2, S0 = 70, mu_xi = 0.05, sigma_xi = 0.2, kappa = 1, sigma_chi = 0.3, rho = 0.3, T2M = 1, dt = 1/250)
simSchwartzSmith <- function(nsims = 1, S0 = 10, mu_xi = 0, sigma_xi = 0.2, 
                             kappa = 1, sigma_chi = 0.2, rho = 0, gamma = 0,
                             chi0 = 0, lambda_chi = 0, lambda_xi = 0,
                             T2M = 1, dt = 1 / 250) {
  
  if (rho < -1 || rho > 1) stop("Correlation rho must be between -1 and 1.")
  
  periods <- T2M / dt
  
  # 1. Generate correlated Brownian motions
  # Z1 and Z2 are independent N(0, dt)
  Z1 <- matrix(stats::rnorm(periods * nsims, mean = 0, sd = sqrt(dt)), ncol = nsims, nrow = periods)
  Z2 <- matrix(stats::rnorm(periods * nsims, mean = 0, sd = sqrt(dt)), ncol = nsims, nrow = periods)
  
  dW_chi <- Z1
  dW_xi <- rho * Z1 + sqrt(1 - rho^2) * Z2
  
  # 2. Simulate long-term equilibrium (xi)
  # log(S0) is split between xi0 and chi0: xi0 = log(S0) - chi0
  xi0 <- log(S0) - chi0
  
  # Apply risk-neutral parameters if provided
  mu_xi_adj <- mu_xi - lambda_xi
  mu_chi_adj <- -lambda_chi / kappa
  
  if (gamma == 0) {
    # Standard Schwartz-Smith: Arithmetic Brownian Motion
    # Standard Schwartz-Smith: ξ follows ABM in log-space
    # dξ = μ_ξ dt + σ_ξ dW_ξ  (no Ito correction; μ is the log-drift per SS 2000 §2)
    d_xi <- mu_xi_adj * dt + sigma_xi * dW_xi
    
    # Cumulative sum over periods using vectorized apply
    xi <- apply(rbind(rep(xi0, nsims), d_xi), 2, cumsum)
  } else {
    # Extended Schwartz-Smith: xi also follows an OU process
    # Here mu_xi acts as the long-term mean reversion level of the log-price factor xi
    diffusion_xi <- rbind(rep(xi0, nsims), dW_xi)
    xi <- rcppOU(diffusion_xi, gamma, mu_xi_adj, dt, sigma_xi)
  }
  
  # 3. Simulate short-term deviations (chi) using the fast C++ loop
  # diffusion_chi initially holds the initial state at index 1 and dW_chi at subsequent indices
  diffusion_chi <- rbind(rep(chi0, nsims), dW_chi)
  
  # rcppOU overwrites diffusion_chi in place with the simulated OU paths
  # For Chi process, mean reversion level is typically 0 (or adjusted under Q measure)
  chi <- rcppOU(diffusion_chi, kappa, mu_chi_adj, dt, sigma_chi)
  
  # 4. Combine to get S_t
  S <- exp(xi + chi)
  
  # 5. Format to tibble per project Tidyverse rules
  format_tibble <- function(mat) {
    df <- dplyr::as_tibble(mat, .name_repair = "minimal")
    names(df) <- paste0("sim", 1:nsims)
    df <- df %>% 
      dplyr::mutate(t = seq(0, T2M, dt)) %>% 
      dplyr::select(t, dplyr::everything())
    return(df)
  }
  
  return(list(
    S = format_tibble(S),
    chi = format_tibble(chi),
    xi = format_tibble(xi)
  ))
}
