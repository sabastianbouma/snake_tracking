rm(list = ls())
ndvi <- terra::rast("data/raw/NDVI/NDVI.tif")

home_range_summary <- readRDS("data/processed/RDS/home_range_summary.RDS")

# Connect to PostgreSQL/PostGIS
db_con <- DBI::dbConnect(
  RPostgres::Postgres(),
  dbname = "snake_tracking",
  host = "localhost",
  port = 5432,
  user = "sabastianbouma"
)
bbmm95_sf <- sf::st_read(db_con, "home_ranges_bbmm") |>
  dplyr::filter(percentage == 95)
bbmm95_sf <- sf::st_transform(bbmm95_sf, terra::crs(ndvi)) # match CRS to the raster

ndvi_stats <- terra::extract(
  ndvi,
  terra::vect(bbmm95_sf),
  fun = mean,
  na.rm = TRUE
) |>
  dplyr::bind_cols(id = bbmm95_sf$id)

# join to home_range_summary and correlate
merged <- dplyr::left_join(
  home_range_summary,
  ndvi_stats,
  by = c("Individual_ID" = "id")
)

cor.test(merged$BBMM_95, merged$NDVI)
