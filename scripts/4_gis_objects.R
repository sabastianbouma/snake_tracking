rm(list = ls())

# Load processed data
points_df <- base::readRDS("data/processed/RDS/points_df.RDS")
pythons_prj <- base::readRDS("data/processed/RDS/pythons_prj.RDS")
mcp_90 <- readRDS("data/processed/RDS/mcp_90.RDS")
mcp_100 <- readRDS("data/processed/RDS/mcp_100.RDS")
kde <- readRDS("data/processed/RDS/kde.RDS")

# Connect to PostgreSQL/PostGIS
db_con <- DBI::dbConnect(
  RPostgres::Postgres(),
  dbname = "snake_tracking",
  host = "localhost",
  port = 5432,
  user = "sabastianbouma"
)

# Ensure PostGIS extension is enabled
DBI::dbExecute(db_con, "CREATE EXTENSION IF NOT EXISTS postgis;")

# Set SRID (UTM zone 54S)
srid <- 32754

# Movement Points
points_sf <- sf::st_as_sf(points_df, coords = c("long", "lat"), crs = 4326) |>
  sf::st_transform(crs = srid)

# Add unique integer FID column for ArcGIS compatibility
points_sf$fid <- seq_len(nrow(points_sf))

if (DBI::dbExistsTable(db_con, "movement_points")) {
  DBI::dbExecute(db_con, "DROP TABLE movement_points;")
}
sf::st_write(
  points_sf,
  db_con,
  "movement_points",
  layer_options = c("OVERWRITE=YES")
)

# Movement Tracks
tracks_sf <- points_sf |>
  dplyr::arrange(ind_ident, timestamp) |>
  dplyr::group_by(ind_ident) |>
  dplyr::summarise(do_union = FALSE) |>
  dplyr::mutate(
    track_id = as.numeric(ind_ident)
  ) |>
  sf::st_cast("LINESTRING")

if (DBI::dbExistsTable(db_con, "movement_tracks")) {
  DBI::dbExecute(db_con, "DROP TABLE movement_tracks;")
}
sf::st_write(
  tracks_sf,
  db_con,
  "movement_tracks",
  layer_options = c("OVERWRITE=YES")
)

# MCP
mcp_sf <- sf::st_as_sf(mcp_90) |>
  sf::st_transform(crs = srid)

if (DBI::dbExistsTable(db_con, "home_ranges_mcp")) {
  DBI::dbExecute(db_con, "DROP TABLE home_ranges_mcp;")
}
sf::st_write(
  mcp_sf,
  db_con,
  "home_ranges_mcp",
  layer_options = c("OVERWRITE=YES")
)

# KDE
kde_poly <- adehabitatHR::getverticeshr(kde, percent = 90)
kde_sf <- sf::st_as_sf(kde_poly) |>
  sf::st_transform(crs = srid)

if (DBI::dbExistsTable(db_con, "home_ranges_kernel")) {
  DBI::dbExecute(db_con, "DROP TABLE home_ranges_kernel;")
}
sf::st_write(
  kde_sf,
  db_con,
  "home_ranges_kernel",
  layer_options = c("OVERWRITE=YES")
)

DBI::dbDisconnect(db_con)
