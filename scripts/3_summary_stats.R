rm(list = ls())

# Load preprocessed data
df <- readRDS("data/processed/RDS/points_df.RDS")
pythons_prj <- readRDS("data/processed/RDS/pythons_prj.RDS")
mcp_90 <- readRDS("data/processed/RDS/mcp_90.RDS")
mcp_100 <- readRDS("data/processed/RDS/mcp_100.RDS")
kde_area <- readRDS("data/processed/RDS/kde_area.RDS")
bbmm <- readRDS("data/processed/RDS/bbmm.RDS")

# Calculate distance and speed
distance <- move::distance(pythons_prj)
speed <- move::speed(pythons_prj)

# 1. Individual-level movement summary statistics
individual_summary <- purrr::map_dfr(
  unique(pythons_prj@trackId),
  function(animal) {
    m <- pythons_prj[[animal]]

    step_distances <- move::distance(m)
    step_speeds <- move::speed(m)
    step_dates <- as.Date(move::timestamps(m)[-length(m)])

    # Calculate daily metrics
    daily_movement <- data.frame(
      date = step_dates,
      distance = step_distances
    ) |>
      dplyr::group_by(date) |>
      dplyr::summarise(
        daily_total = sum(distance, na.rm = TRUE),
        .groups = "drop"
      )

    # Return summary dataframe
    data.frame(
      Individual_ID = stringr::str_extract(animal, "\\d+"),
      Number_of_Locations = length(m),
      Study_Period_Days = as.integer(difftime(
        move::timestamps(m)[length(m)],
        move::timestamps(m)[1],
        units = "days"
      )),
      Mean_Step_Distance_m = round(mean(step_distances, na.rm = TRUE), 2),
      Max_Step_Distance_m = round(max(step_distances, na.rm = TRUE), 2),
      SD_Step_Distance_m = round(sd(step_distances, na.rm = TRUE), 2),
      Mean_Daily_Distance_m = round(
        mean(daily_movement$daily_total, na.rm = TRUE),
        2
      ),
      Max_Daily_Distance_m = round(
        max(daily_movement$daily_total, na.rm = TRUE),
        2
      ),
      SD_Daily_Distance_m = round(
        sd(daily_movement$daily_total, na.rm = TRUE),
        2
      ),
      Mean_Speed_ms = round(mean(step_speeds, na.rm = TRUE), 4),
      Max_Speed_ms = round(max(step_speeds, na.rm = TRUE), 4)
    )
  }
)

# 2. Overall population-level summary
population_summary <- data.frame(
  Metric = c(
    "Number of Individuals",
    "Total Locations",
    "Mean Locations per Individual",
    "Mean Study Period (days)",
    "Overall Mean Step Distance (m)",
    "Overall Mean Daily Distance (m)",
    "Overall Mean Speed (m/s)"
  ),
  Value = c(
    dplyr::n_distinct(pythons_prj@trackId),
    nrow(df),
    round(nrow(df) / dplyr::n_distinct(pythons_prj@trackId), 1),
    round(mean(individual_summary$Study_Period_Days), 1),
    round(mean(individual_summary$Mean_Step_Distance_m), 2),
    round(mean(individual_summary$Mean_Daily_Distance_m), 2),
    round(mean(individual_summary$Mean_Speed_ms), 4)
  )
)

mcp_summary <- purrr::map_dfr(unique(pythons_prj@trackId), function(animal) {
  animal_id <- stringr::str_extract(animal, "\\d+")
  mcp_90_val <- mcp_90[mcp_90$id == animal, ]$area
  mcp_100_val <- mcp_100[mcp_100$id == animal, ]$area

  if (length(mcp_90_val) == 0) {
    mcp_90_val <- NA
  }
  if (length(mcp_100_val) == 0) {
    mcp_100_val <- NA
  }

  data.frame(
    Individual_ID = animal_id,
    MCP_90_ha = round(mcp_90_val, 2),
    MCP_100_ha = round(mcp_100_val, 2)
  )
})

kde_summary <- purrr::map_dfr(
  unique(pythons_prj@trackId),
  function(animal) {
    animal_id <- stringr::str_extract(animal, "\\d+")
    Core_Area_50_ha <- kde_area['50', animal]
    Core_Area_75_ha <- kde_area['75', animal]
    Home_Range_95_ha <- kde_area['95', animal]

    if (length(Core_Area_50_ha) == 0) {
      Core_Area_50_ha <- NA
    }
    if (length(Core_Area_75_ha) == 0) {
      Core_Area_75_ha <- NA
    }
    if (length(Home_Range_95_ha) == 0) {
      Home_Range_95_ha <- NA
    }
    data.frame(
      Individual_ID = animal_id,
      Core_Area_50_ha = round(Core_Area_50_ha, 2),
      Core_Area_75_ha = round(Core_Area_75_ha, 2),
      Home_Range_95_ha = round(Home_Range_95_ha, 2)
    )
  }
)

# 3. Combine home range estimates
home_range_summary <- mcp_summary |>
  dplyr::full_join(kde_summary, by = "Individual_ID") |>
  dplyr::arrange(as.numeric(Individual_ID))

# Save summaries
saveRDS(
  individual_summary,
  "data/processed/RDS/individual_movement_summary.RDS"
)
saveRDS(population_summary, "data/processed/RDS/population_summary.RDS")

saveRDS(home_range_summary, "data/processed/RDS/home_range_summary.RDS")
