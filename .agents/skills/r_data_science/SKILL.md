---
name: R Data Science & Tidyverse Expert
description: Expert instructions and best practices for writing clean, performant R code using Tidyverse principles.
---

# R & Tidyverse Best Practices

When writing R code for this project, you must adhere to the following principles:

1. **Tibbles Over Data.frames:** Always use and return `tbl_df` objects. Do not use `stringsAsFactors=TRUE`. Use `readr::read_rds` and `write_rds` for perfect serialization instead of `.csv` when passing data between scripts.
2. **Pipes:** Chain operations using `%>%` or `|>` to make data transformations readable.
3. **dplyr & purrr:** Rely heavily on `dplyr` for data manipulation (mutate, select, group_by, summarize) and `purrr::map` functions instead of raw `lapply` or `for` loops where possible.
4. **ggplot2:** All visualizations must use `ggplot2` with clear labeling, `theme_minimal()`, and appropriate color scales. Never use base R `plot()`.
5. **Reproducibility:** Set seeds (`set.seed()`) before any stochastic operations (like random sampling or Brownian motion generation).
6. **Code Clarity:** Comment comprehensively. Make sure functions are clearly defined with accurate `roxygen2` style docstrings.
