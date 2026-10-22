rm(list = ls())

# Load preprocessed data
df <- readRDS("data/processed/RDS/points_df.RDS")
pythons_prj <- readRDS("data/processed/RDS/pythons_prj.RDS")
mcp_90_model <- readRDS("data/processed/RDS/mcp_90.RDS")
mcp_100_model <- readRDS("data/processed/RDS/mcp_100.RDS")
kde_area <- readRDS("data/processed/RDS/kde_area.RDS")
bbmm_ud <- readRDS("data/processed/RDS/bbmm_ud.RDS")

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

home_range_summary <- purrr::map_dfr(
  unique(pythons_prj@trackId),
  function(animal) {
    animal_id <- stringr::str_extract(animal, "\\d+")
    mcp_90 <- mcp_90_model[mcp_90_model$id == animal, ]$area
    mcp_100 <- mcp_100_model[mcp_100_model$id == animal, ]$area

    kde_50 <- kde_area['50', animal]
    kde_75 <- kde_area['75', animal]
    kde_95 <- kde_area['95', animal]
    bbmm_50 <- bbmm_ud[[animal]] |>
      raster::rasterToPolygons(fun = function(x) x <= 0.50) |>
      sf::st_as_sf() |>
      sf::st_area() |>
      sum()
    bbmm_75 <- bbmm_ud[[animal]] |>
      raster::rasterToPolygons(fun = function(x) x <= 0.75) |>
      sf::st_as_sf() |>
      sf::st_area() |>
      sum()
    bbmm_95 <- bbmm_ud[[animal]] |>
      raster::rasterToPolygons(fun = function(x) x <= 0.95) |>
      sf::st_as_sf() |>
      sf::st_area() |>
      sum()

    # List of variables to check
    variables_to_check <- c(
      "kde_50",
      "kde_75",
      "kde_95",
      "mcp_90",
      "mcp_100",
      "bbmm_50",
      "bbmm_75",
      "bbmm_95"
    )

    # Assign NA if length is 0
    for (var in variables_to_check) {
      assign(var, ifelse(length(get(var)) == 0, NA, get(var)))
    }

    data.frame(
      Individual_ID = animal_id,
      MCP_90 = round(mcp_90, 2),
      MCP_100 = round(mcp_100, 2),
      KDE_50 = round(kde_50, 2),
      KDE_75 = round(kde_75, 2),
      KDE_95 = round(kde_95, 2),
      BBMM_50 = round(bbmm_50 / 10000, 2), # Convert from m^2 to ha
      BBMM_75 = round(bbmm_75 / 10000, 2), # Convert from m^2 to ha
      BBMM_95 = round(bbmm_95 / 10000, 2) # Convert from m^2 to ha
    )
  }
) |>
  dplyr::arrange(as.numeric(Individual_ID))

# Save summaries
saveRDS(
  individual_summary,
  "data/processed/RDS/individual_movement_summary.RDS"
)
saveRDS(population_summary, "data/processed/RDS/population_summary.RDS")

saveRDS(home_range_summary, "data/processed/RDS/home_range_summary.RDS")
