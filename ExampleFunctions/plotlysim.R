#' Plot simulation paths
#' @param data A tibble with a 't' column and simulation columns.
#' @param title Plot title
#' @param S0 Initial spot price
#' @param xaxisTitle X-axis title
#' @param yaxisTitle Y-axis title
#' @importFrom magrittr %>%
#' @export
simPlot <- function(data, title = "type of sim", S0 = 10, xaxisTitle = "T", yaxisTitle = "y") {
  
  requireNamespace("dplyr", quietly = TRUE)
  requireNamespace("tidyr", quietly = TRUE)
  requireNamespace("plotly", quietly = TRUE)
  
  # Calculate max and min ignoring the 't' column
  sim_data <- data %>% dplyr::select(-t)
  max_val <- max(sim_data, na.rm = TRUE)
  min_val <- min(sim_data, na.rm = TRUE)
  
  # Calculate excursions from starting price
  up <- abs(max_val - S0)
  down <- abs(S0 - min_val) 
  
  # Calculate symmetric y-axis limits
  majorTicksize <- (down + up) / 6
  if (majorTicksize == 0) majorTicksize <- 1 # prevent division by zero
  
  ylim <- (max(down, up) %/% majorTicksize + 1) * majorTicksize
  
  p <- data %>%
    tidyr::pivot_longer(cols = -t, names_to = "sim", values_to = "value") %>%
    plotly::plot_ly(
      x = ~t,
      y = ~value,
      color = ~sim,
      type = "scatter",
      mode = "lines",
      showlegend = FALSE
    ) %>%
    plotly::layout(
      title = title,
      xaxis = list(title = xaxisTitle),
      yaxis = list(title = yaxisTitle, range = c(S0 - ylim, S0 + ylim))
    )    
  
  return(p)
}