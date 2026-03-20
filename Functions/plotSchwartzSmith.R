# -------------------------------------------------------------------------
# Script: plotSchwartzSmith.R
# Purpose: Interactive plotly visualization for Schwartz-Smith two-factor
#          simulation output (fan chart + factor decomposition + terminal
#          distribution). Replaces the former plotlysim.R / simPlot.
# -------------------------------------------------------------------------

#' Compute quantile ribbons from a simulation tibble
#' @param tbl A tibble with a 't' column and sim columns.
#' @param probs Quantile probabilities. `numeric`
#' @returns A tibble with t, p05, p25, p50, p75, p95 columns. `tbl_df`
#' @keywords internal
compute_quantiles <- function(tbl, probs = c(0.05, 0.25, 0.50, 0.75, 0.95)) {
  mat <- as.matrix(tbl %>% dplyr::select(-t))
  qs <- t(apply(mat, 1, quantile, probs = probs))
  dplyr::tibble(
    t   = tbl$t,
    p05 = qs[, 1],
    p25 = qs[, 2],
    p50 = qs[, 3],
    p75 = qs[, 4],
    p95 = qs[, 5]
  )
}

#' Schwartz-Smith simulation plotly visualization
#' @description Creates a three-panel interactive plotly subplot from
#'   simSchwartzSmith() output: (1) price fan chart with quantile bands,
#'   (2) chi/xi factor decomposition, (3) terminal distribution histogram.
#' @param sim List returned by simSchwartzSmith() containing $S, $chi, $xi tibbles. `list`
#' @param S0 Initial spot price used in the simulation. `numeric`
#' @param title Main plot title. `character`
#' @param n_sample Number of sample paths to overlay on the fan chart. `integer`
#' @param subtitle Optional subtitle with parameter info. If NULL, auto-generated. `character`
#' @returns A plotly htmlwidget object. `plotly`
#' @importFrom magrittr %>%
#' @export
plotSchwartzSmith <- function(sim,
                              S0 = NULL,
                              title = "Schwartz-Smith Two-Factor Simulation",
                              n_sample = 8,
                              subtitle = NULL) {

  requireNamespace("dplyr", quietly = TRUE)
  requireNamespace("tidyr", quietly = TRUE)
  requireNamespace("plotly", quietly = TRUE)

  # --- Infer dimensions from the simulation output ---
  nsims  <- ncol(sim$S) - 1    # minus the 't' column
  T2M    <- max(sim$S$t)

  # Infer S0 from first row if not provided
  if (is.null(S0)) {
    S0 <- as.numeric(sim$S[1, 2])
  }

  # --- Quantile ribbons ---
  q_S   <- compute_quantiles(sim$S)
  q_chi <- compute_quantiles(sim$chi)
  q_xi  <- compute_quantiles(sim$xi)

  # --- Colour palette (dark theme) ---
  col_accent   <- "#60a5fa"
  col_band_out <- "rgba(96, 165, 250, 0.10)"
  col_band_in  <- "rgba(96, 165, 250, 0.22)"
  col_median   <- "#2563eb"
  col_chi      <- "#f97316"
  col_xi       <- "#22c55e"
  col_hist     <- "rgba(96, 165, 250, 0.55)"
  col_sample   <- "rgba(148, 163, 184, 0.15)"
  col_bg       <- "#0f172a"
  col_grid     <- "rgba(148, 163, 184, 0.08)"
  col_text     <- "#e2e8f0"
  col_subtext  <- "#94a3b8"
  font_family  <- "Inter, -apple-system, BlinkMacSystemFont, sans-serif"

  axis_template <- list(
    gridcolor     = col_grid,
    zerolinecolor = "rgba(148,163,184,0.2)",
    tickfont      = list(family = font_family, size = 11, color = col_subtext),
    titlefont     = list(family = font_family, size = 13, color = col_text)
  )

  # ─── Panel 1: Price Fan Chart ──────────────────────────────────────────
  set.seed(7)
  sample_cols <- paste0("sim", sort(sample(1:nsims, min(n_sample, nsims))))

  p1 <- plotly::plot_ly() %>%
    plotly::add_ribbons(
      data = q_S, x = ~t, ymin = ~p05, ymax = ~p95,
      fillcolor = col_band_out, line = list(width = 0),
      name = "P5 \u2013 P95", showlegend = TRUE, legendgroup = "bands"
    ) %>%
    plotly::add_ribbons(
      data = q_S, x = ~t, ymin = ~p25, ymax = ~p75,
      fillcolor = col_band_in, line = list(width = 0),
      name = "P25 \u2013 P75", showlegend = TRUE, legendgroup = "bands"
    )

  for (col_name in sample_cols) {
    p1 <- p1 %>%
      plotly::add_lines(
        data = sim$S, x = ~t, y = as.formula(paste0("~`", col_name, "`")),
        line = list(color = col_sample, width = 0.7),
        showlegend = FALSE, hoverinfo = "skip"
      )
  }

  p1 <- p1 %>%
    plotly::add_lines(
      data = q_S, x = ~t, y = ~p50,
      line = list(color = col_median, width = 2.5),
      name = "Median", showlegend = TRUE
    ) %>%
    plotly::add_markers(
      x = 0, y = S0,
      marker = list(color = col_accent, size = 8, symbol = "diamond",
                    line = list(color = col_bg, width = 1.5)),
      name = paste0("S\u2080 = $", round(S0, 1)), showlegend = TRUE
    ) %>%
    plotly::layout(
      xaxis = c(axis_template, list(title = "Years")),
      yaxis = c(axis_template, list(title = "Price ($/bbl)"))
    )

  # ─── Panel 2: Factor Decomposition ─────────────────────────────────────
  p2 <- plotly::plot_ly() %>%
    plotly::add_ribbons(
      data = q_xi, x = ~t, ymin = ~p05, ymax = ~p95,
      fillcolor = "rgba(34, 197, 94, 0.10)", line = list(width = 0),
      name = "\u03be P5\u2013P95", showlegend = TRUE, legendgroup = "xi"
    ) %>%
    plotly::add_ribbons(
      data = q_xi, x = ~t, ymin = ~p25, ymax = ~p75,
      fillcolor = "rgba(34, 197, 94, 0.22)", line = list(width = 0),
      name = "\u03be P25\u2013P75", showlegend = TRUE, legendgroup = "xi"
    ) %>%
    plotly::add_lines(
      data = q_xi, x = ~t, y = ~p50,
      line = list(color = col_xi, width = 2),
      name = "\u03be Median (Equilibrium)", showlegend = TRUE, legendgroup = "xi"
    ) %>%
    plotly::add_ribbons(
      data = q_chi, x = ~t, ymin = ~p05, ymax = ~p95,
      fillcolor = "rgba(249, 115, 22, 0.10)", line = list(width = 0),
      name = "\u03c7 P5\u2013P95", showlegend = TRUE, legendgroup = "chi"
    ) %>%
    plotly::add_ribbons(
      data = q_chi, x = ~t, ymin = ~p25, ymax = ~p75,
      fillcolor = "rgba(249, 115, 22, 0.22)", line = list(width = 0),
      name = "\u03c7 P25\u2013P75", showlegend = TRUE, legendgroup = "chi"
    ) %>%
    plotly::add_lines(
      data = q_chi, x = ~t, y = ~p50,
      line = list(color = col_chi, width = 2),
      name = "\u03c7 Median (Short-term)", showlegend = TRUE, legendgroup = "chi"
    ) %>%
    plotly::add_lines(
      x = c(0, T2M), y = c(0, 0),
      line = list(color = "rgba(148,163,184,0.3)", width = 1, dash = "dot"),
      showlegend = FALSE, hoverinfo = "skip"
    ) %>%
    plotly::layout(
      xaxis = c(axis_template, list(title = "Years")),
      yaxis = c(axis_template, list(title = "Log-Price Factor Value"))
    )

  # ─── Panel 3: Terminal Distribution ────────────────────────────────────
  terminal_prices <- as.numeric(sim$S[nrow(sim$S), -1])
  tp_q <- quantile(terminal_prices, probs = c(0.05, 0.50, 0.95))

  p3 <- plotly::plot_ly() %>%
    plotly::add_histogram(
      x = terminal_prices, nbinsx = 50,
      marker = list(color = col_hist, line = list(color = col_accent, width = 0.5)),
      name = "Terminal S_T", showlegend = FALSE
    ) %>%
    plotly::add_lines(
      x = c(tp_q[1], tp_q[1]), y = c(0, nsims * 0.06),
      line = list(color = "#ef4444", width = 1.5, dash = "dash"),
      name = sprintf("P5 = $%.1f", tp_q[1]), showlegend = TRUE
    ) %>%
    plotly::add_lines(
      x = c(tp_q[2], tp_q[2]), y = c(0, nsims * 0.06),
      line = list(color = col_median, width = 2),
      name = sprintf("Median = $%.1f", tp_q[2]), showlegend = TRUE
    ) %>%
    plotly::add_lines(
      x = c(tp_q[3], tp_q[3]), y = c(0, nsims * 0.06),
      line = list(color = "#22c55e", width = 1.5, dash = "dash"),
      name = sprintf("P95 = $%.1f", tp_q[3]), showlegend = TRUE
    ) %>%
    plotly::layout(
      xaxis = c(axis_template, list(title = sprintf("Terminal Price at T = %g yr ($/bbl)", T2M))),
      yaxis = c(axis_template, list(title = "Count"))
    )

  # ─── Assemble Subplot ──────────────────────────────────────────────────
  if (is.null(subtitle)) {
    subtitle <- paste0(nsims, " paths \u00b7 T = ", T2M, " yr")
  }

  fig <- plotly::subplot(
    p1, p2, p3,
    nrows = 3, shareX = FALSE,
    heights = c(0.45, 0.30, 0.25),
    titleY = TRUE, titleX = TRUE
  ) %>%
    plotly::layout(
      title = list(
        text = paste0(
          "<b>", title, "</b>",
          "<br><span style='font-size:12px;color:", col_subtext, "'>",
          subtitle, "</span>"
        ),
        font = list(family = font_family, size = 18, color = col_text),
        x = 0.02, xanchor = "left"
      ),
      paper_bgcolor = col_bg,
      plot_bgcolor  = col_bg,
      font = list(family = font_family, color = col_text),
      legend = list(
        font = list(size = 11, color = col_subtext),
        bgcolor = "rgba(15,23,42,0.8)",
        bordercolor = "rgba(148,163,184,0.15)",
        borderwidth = 1,
        orientation = "h",
        x = 0.5, xanchor = "center",
        y = -0.06
      ),
      margin = list(t = 80, b = 80, l = 60, r = 30),
      annotations = list(
        list(text = "<b>Price Fan Chart</b>", x = 0.01, y = 1.0,
             xref = "paper", yref = "paper", showarrow = FALSE,
             font = list(size = 13, color = col_text, family = font_family),
             xanchor = "left"),
        list(text = "<b>Factor Decomposition (log-space)</b>", x = 0.01, y = 0.53,
             xref = "paper", yref = "paper", showarrow = FALSE,
             font = list(size = 13, color = col_text, family = font_family),
             xanchor = "left"),
        list(text = "<b>Terminal Price Distribution</b>", x = 0.01, y = 0.23,
             xref = "paper", yref = "paper", showarrow = FALSE,
             font = list(size = 13, color = col_text, family = font_family),
             xanchor = "left")
      )
    )

  return(fig)
}
