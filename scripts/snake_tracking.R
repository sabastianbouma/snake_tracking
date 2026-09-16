rm(list = ls())

raw <- utils::read.csv(
  "data/processed/misc/points.csv"
)
raw <- raw |>
  dplyr::mutate(
    timestamp = as.POSIXct(
      timestamp,
      format = "%Y-%m-%d %H:%M:%S",
      tz = "UTC"
    )
  ) |>
  dplyr::arrange(ind_ident, timestamp) |>
  dplyr::filter(!ind_ident %in% c(1))

pythons <- move::move(
  #set coordinates
  x = raw$long,
  y = raw$lat,
  #provide my time format in POSIX
  time = raw$timestamp,
  #set the projection – this is PROJ4 format. See below for more details.
  proj = "+proj=longlat +ellps=GRS80 +no_defs",
  #set the id
  animal = as.numeric(raw$ind_ident),
  #add the rest of the data
  data = raw
)

pythons_prj <- sp::spTransform(
  pythons,
  "+proj=utm +zone=54 +south +datum=WGS84 +units=m +no_defs"
)
