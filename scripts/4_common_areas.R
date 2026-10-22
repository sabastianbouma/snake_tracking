rm(list = ls())

# Load BBMM 95% polygons (assuming you have a list or sf object per individual)
bbmm_ud <- readRDS("data/processed/RDS/bbmm_ud.RDS")
animal_ids <- names(bbmm_ud)
srid <- 32754

bbmm_sf <- purrr::map(animal_ids, function(animal) {
  UDmypy_conts <- raster::rasterToContour(
    bbmm_ud[[animal]],
    levels = seq(0, 1, by = 0.05)
  )
  mycontours <- sf::st_as_sf(UDmypy_conts)
  my_contours_poly <- sf::st_polygonize(mycontours)
  my_contours_subset <- raster::subset(my_contours_poly, level == .95)

  my_contours_dissolved <- sf::st_union(my_contours_subset)

  my_contours_extracted <- sf::st_collection_extract(
    my_contours_dissolved,
    'POLYGON'
  )

  sf::st_sf(
    percentage = .95,
    id = stringr::str_extract(animal, "\\d+"),
    geometry = my_contours_extracted
  )
}) |>
  dplyr::bind_rows() |>
  sf::st_transform(crs = srid) |>
  dplyr::mutate(fid = dplyr::row_number())

# Assume bbmm_sf has columns: id, animal_id, geometry

# Union all polygons into one geometry collection
all_union <- sf::st_union(bbmm_sf)

# Intersect all polygons to get all unique overlapping regions
all_intersections <- sf::st_intersection(bbmm_sf) |>
  dplyr::filter(n.overlaps > 1)

# For each resulting geometry, find which individuals overlap it
common_areas <- all_intersections |>
  dplyr::mutate(
    snake_ids = purrr::map(origins, function(idx) bbmm_sf$id[idx]),
    n_snakes = purrr::map_int(snake_ids, length),
    area_ha = as.numeric(sf::st_area(geometry)) / 10000
  ) |>
  dplyr::filter(area_ha > 0) |>
  dplyr::mutate(snake_ids = sapply(snake_ids, paste, collapse = ",")) |>
  sf::st_collection_extract(
    'POLYGON'
  )

saveRDS(common_areas, "data/processed/RDS/common_areas.RDS")
