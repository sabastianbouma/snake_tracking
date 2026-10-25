individual_summary <- readRDS(
  "data/processed/RDS/individual_movement_summary.RDS"
)
home_range_summary <- readRDS("data/processed/RDS/home_range_summary.RDS")

dat <- individual_summary |>
  dplyr::select(Individual_ID, Number_of_Locations, Study_Period_Days) |>
  dplyr::inner_join(
    home_range_summary |>
      dplyr::select(Individual_ID, MCP_100, KDE_95, BBMM_95),
    by = "Individual_ID"
  )

# ---- 2. Long format: one row per snake x estimator x effort measure ----
plot_dat <- dat |>
  tidyr::pivot_longer(
    cols = c(MCP_100, KDE_95, BBMM_95),
    names_to = "estimator",
    values_to = "home_range_ha"
  ) |>
  tidyr::pivot_longer(
    cols = c(Number_of_Locations, Study_Period_Days),
    names_to = "effort_measure",
    values_to = "effort"
  ) |>
  dplyr::mutate(
    estimator = factor(
      estimator,
      levels = c("MCP_100", "KDE_95", "BBMM_95"),
      labels = c("MCP 100%", "KDE 95%", "BBMM 95%")
    ),
    effort_measure = factor(
      effort_measure,
      levels = c("Number_of_Locations", "Study_Period_Days"),
      labels = c("Number of locations", "Study period (days)")
    )
  )

# ---- 3. Pearson r and p for each panel, to print on the plot ----
cor_labels <- plot_dat |>
  dplyr::group_by(estimator, effort_measure) |>
  dplyr::summarise(
    r = stats::cor(effort, home_range_ha),
    p = stats::cor.test(effort, home_range_ha)$p.value,
    .groups = "drop"
  ) |>
  dplyr::mutate(
    label = sprintf(
      "r = %.2f, p %s",
      r,
      ifelse(p < 0.001, "< 0.001", sprintf("= %.3f", p))
    )
  )

# ---- 4. Plot ----
p <- ggplot2::ggplot(plot_dat, ggplot2::aes(x = effort, y = home_range_ha)) +
  ggplot2::geom_point(alpha = 0.7, size = 2) +
  ggplot2::geom_smooth(
    method = "lm",
    formula = y ~ x,
    se = TRUE,
    colour = "firebrick",
    linewidth = 0.7
  ) +
  ggplot2::geom_text(
    data = cor_labels,
    mapping = ggplot2::aes(label = label),
    x = -Inf,
    y = Inf,
    hjust = -0.1,
    vjust = 1.5,
    inherit.aes = FALSE,
    size = 3.2
  ) +
  ggplot2::scale_y_continuous(
    expand = ggplot2::expansion(mult = c(0.05, 0.25))
  ) +
  ggplot2::facet_grid(estimator ~ effort_measure, scales = "free") +
  ggplot2::labs(x = "Tracking effort", y = "Home range size (ha)") +
  ggplot2::theme_bw(base_size = 11)

p

ggplot2::ggsave(
  filename = "data/processed/images/effort_vs_home_range.png",
  plot = p,
  width = 7,
  height = 7,
  dpi = 300
)
