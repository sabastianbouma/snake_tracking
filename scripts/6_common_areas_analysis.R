rm(list = ls())

common_areas <- readRDS("data/processed/RDS/common_areas.RDS")

# Create summary table: one row per common area
common_areas_table <- common_areas |>
  dplyr::mutate(
    common_area_id = dplyr::row_number()
  ) |>
  dplyr::select(common_area_id, n_snakes, snake_ids, area_ha)

# Save as CSV for report inclusion
readr::write_csv(
  common_areas_table,
  "data/processed/misc/common_areas_table.csv"
)

# Additional summary: number of common areas, size stats, snakes per area
summary_stats <- list(
  n_common_areas = nrow(common_areas_table),
  area_ha_summary = summary(common_areas_table$area_ha),
  snakes_per_area_summary = summary(
    stringr::str_count(common_areas_table$snake_ids, ",") + 1
  )
)

summary_stats
