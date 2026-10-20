rm(list = ls())

# Load preprocessed data
df <- readRDS("data/processed/RDS/points_df.RDS")

# Create Move objects
pythons <- move::move(
  x = df$long,
  y = df$lat,
  time = df$timestamp,
  proj = "+proj=longlat +ellps=GRS80 +no_defs",
  animal = as.numeric(df$ind_ident),
  data = df
)

pythons_prj <- sp::spTransform(
  pythons,
  "+proj=utm +zone=54 +south +datum=WGS84 +units=m +no_defs"
)

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

# Save summaries
saveRDS(
  individual_summary,
  "data/processed/RDS/individual_movement_summary.RDS"
)
saveRDS(population_summary, "data/processed/RDS/population_summary.RDS")
