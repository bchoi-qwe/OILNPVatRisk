library(tidyverse)
library(RTL)
library(patchwork)
library(zoo)
library(moments)

# Load data
data(fizdiffs)

# Ensure the columns exist
if(!("WCS.HDY" %in% names(fizdiffs)) || !("SYN.EDM" %in% names(fizdiffs)) || !("CL.EDM" %in% names(fizdiffs))) {
    stop("Required columns not found in fizdiffs")
}

# 1. Compute absolute prices and spread
df <- fizdiffs %>%
    select(date, WTI.CMA01, WCS.HOU, WCS.CUS, WCS.HDY, CL.EDM, SYN.EDM) %>%
    mutate(
        CL_diff = WCS.HDY + CL.EDM,
        CL_abs = WTI.CMA01 + CL_diff,
        SYN_abs = WTI.CMA01 + SYN.EDM,
        spread = SYN_abs - CL_abs
    ) %>%
    drop_na()



# Compute summary stats
sync_mean <- mean(df$spread)
sync_sd <- sd(df$spread)
sync_min <- min(df$spread)
sync_max <- max(df$spread)
sync_skew <- skewness(df$spread)
sync_kurtosis <- kurtosis(df$spread)
sync_median <- median(df$spread)

# Print summary statistics
cat("=== SUMMARY STATISTICS ===\n")
cat(sprintf("Mean:     %.2f\n", sync_mean))
cat(sprintf("Std Dev:  %.2f\n", sync_sd))
cat(sprintf("Min:      %.2f\n", sync_min))
cat(sprintf("Max:      %.2f\n", sync_max))
cat(sprintf("Skewness: %.2f\n", sync_skew))
cat(sprintf("Kurtosis: %.2f\n", sync_kurtosis))
cat("==========================\n")

# 1. Spread time series
p1 <- ggplot(df, aes(x = date, y = spread)) +
    geom_line(color = "steelblue") +
    geom_hline(yintercept = sync_mean, linetype = "dashed", color = "darkred") +
    geom_hline(yintercept = 15, linetype = "dotted", color = "darkorange") +
    labs(x = "Date", y = "Spread ($/bbl)", title = "1. CL-SYN Spread Over Time") +
    theme_minimal()

# 2. Spread distribution
p2 <- ggplot(df, aes(x = spread)) +
    geom_histogram(aes(y = ..density..), bins = 30, fill = "lightgray", color = "black") +
    geom_density(color = "steelblue", size = 1) +
    geom_vline(xintercept = sync_mean, color = "darkred", linetype = "dashed") +
    geom_vline(xintercept = sync_median, color = "darkblue", linetype = "dotted") +
    labs(x = "Spread ($/bbl)", y = "Density", title = "2. Spread Distribution") +
    theme_minimal()

# 3. ACF plot
# Compute ACF values for plotting manually to match ggplot style
acf_res <- acf(df$spread, plot = FALSE)
acf_df <- data.frame(lag = acf_res$lag[-1], acf = acf_res$acf[-1])
ci <- qnorm((1 + 0.95)/2) / sqrt(acf_res$n.used)

p3 <- ggplot(acf_df, aes(x = lag, y = acf)) +
    geom_bar(stat = "identity", fill = "steelblue", width = 0.2) +
    geom_hline(yintercept = c(-ci, ci), linetype = "dashed", color = "darkred") +
    geom_hline(yintercept = 0) +
    labs(x = "Lag", y = "ACF", title = "3. Autocorrelation Function (ACF)") +
    theme_minimal()

# 4. Rolling statistics
# Using 12-month rolling window (approx 252 trading days)
window_size <- 252
df <- df %>%
    arrange(date) %>%
    mutate(
        rolling_mean = rollapply(spread, width = window_size, FUN = mean, fill = NA, align = "right"),
        rolling_sd = rollapply(spread, width = window_size, FUN = sd, fill = NA, align = "right")
    )

p4_mean <- ggplot(df, aes(x = date, y = rolling_mean)) +
    geom_line(color = "darkred") +
    labs(x = "Date", y = "Rol. Mean ($/bbl)", title = "4. Rolling Mean (12m)") +
    theme_minimal()

p4_sd <- ggplot(df, aes(x = date, y = rolling_sd)) +
    geom_line(color = "darkorange") +
    labs(x = "Date", y = "Rol. SD ($/bbl)", title = "Rolling Std. Dev (12m)") +
    theme_minimal()

# 5. Individual absolute price levels
df_long_levels <- df %>% select(date, CL_abs, SYN_abs) %>% pivot_longer(-date, names_to = "Crude", values_to = "Price")
p5 <- ggplot(df_long_levels, aes(x = date, y = Price, color = Crude)) +
    geom_line(alpha=0.8) +
    labs(x = "Date", y = "Absolute Price ($/bbl)", title = "5. Absolute Price Levels") +
    scale_color_manual(values = c("CL_abs" = "darkred", "SYN_abs" = "steelblue"), labels = c("Cold Lake", "Synthetic")) +
    theme_minimal() +
    theme(legend.position = "bottom")

# 6. Bonus: WCS Location spreads
df_wcs <- df %>% select(date, WCS.HDY, WCS.CUS, WCS.HOU) %>% pivot_longer(-date, names_to = "Location", values_to = "Price")
p6 <- ggplot(df_wcs, aes(x = date, y = Price, color = Location)) +
    geom_line(alpha=0.8) +
    labs(x = "Date", y = "Diff to WTI ($/bbl)", title = "Bonus: WCS by Location") +
    scale_color_manual(values = c("WCS.HDY" = "steelblue", "WCS.CUS" = "darkorange", "WCS.HOU" = "darkred")) +
    theme_minimal() +
    theme(legend.position = "bottom")

# Combine all using patchwork
final_plot <- (p1 | p2) / (p3 | p4_mean) / (p5 | p6) + 
    plot_annotation(title = "Exploratory Analysis of CL-SYN Spread & Transportation Economics")

# Save to artifact directory
ggsave("cl_syn_spread_charts.png", plot = final_plot, width = 12, height = 12, dpi = 300)
cat("Plot saved successfully.\n")
