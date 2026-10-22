rm(list = ls())

# Load processed data
points_df <- base::readRDS("data/processed/RDS/points_df.RDS")
pythons_prj <- base::readRDS("data/processed/RDS/pythons_prj.RDS")
mcp_90 <- readRDS("data/processed/RDS/mcp_90.RDS")
mcp_100 <- readRDS("data/processed/RDS/mcp_100.RDS")
kde <- readRDS("data/processed/RDS/kde.RDS")
bbmm_ud <- readRDS("data/processed/RDS/bbmm_ud.RDS")

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
mcp_90$percentage <- 90
mcp_100$percentage <- 100
mcp_combined <- rbind(mcp_90, mcp_100)
mcp_combined$fid <- seq_len(nrow(mcp_combined))
mcp_sf <- mcp_combined |>
  sf::st_as_sf() |>
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
kde_sf <- purrr::map_dfr(
  c(50, 75, 95),
  ~ {
    poly <- adehabitatHR::getverticeshr(kde, percent = .x)
    poly_sf <- sf::st_as_sf(poly)
    poly_sf$percentage <- .x
    poly_sf
  }
) |>
  sf::st_transform(crs = srid) |>
  dplyr::mutate(fid = dplyr::row_number())

if (DBI::dbExistsTable(db_con, "home_ranges_kernel")) {
  DBI::dbExecute(db_con, "DROP TABLE home_ranges_kernel;")
}
sf::st_write(
  kde_sf,
  db_con,
  "home_ranges_kernel",
  layer_options = c("OVERWRITE=YES")
)

# BBMM
# Get the names of all layers in bbmm_ud
animal_ids <- names(bbmm_ud)

bbmm_sf <- purrr::map_dfr(
  c(50, 75, 95),
  ~ {
    # Create a list to store contours for each layer
    contours_list <- purrr::map(animal_ids, function(animal) {
      UDmypy_conts <- raster::rasterToContour(
        bbmm_ud[[animal]],
        levels = seq(0, 1, by = 0.05)
      )
      mycontours <- sf::st_as_sf(UDmypy_conts)
      my_contours_poly <- sf::st_polygonize(mycontours)
      my_contours_subset <- raster::subset(my_contours_poly, level == .x / 100)

      my_contours_dissolved <- sf::st_union(my_contours_subset)

      my_contours_extracted <- sf::st_collection_extract(
        my_contours_dissolved,
        'POLYGON'
      )

      sf::st_sf(
        percentage = .x,
        id = stringr::str_extract(animal, "\\d+"),
        geometry = my_contours_extracted
      )
    })

    # Combine contours from all layers into a single data frame
    dplyr::bind_rows(contours_list)
  }
) |>
  sf::st_transform(crs = srid) |>
  dplyr::mutate(fid = dplyr::row_number())

if (DBI::dbExistsTable(db_con, "home_ranges_bbmm")) {
  DBI::dbExecute(db_con, "DROP TABLE home_ranges_bbmm;")
}
sf::st_write(
  bbmm_sf,
  db_con,
  "home_ranges_bbmm",
  layer_options = c("OVERWRITE=YES")
)

DBI::dbDisconnect(db_con)
