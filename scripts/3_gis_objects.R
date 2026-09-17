rm(list = ls())

df <- readRDS("data/processed/RDS/points_df.RDS")

pythons <- move::move(
  #set coordinates
  x = df$long,
  y = df$lat,
  #provide time format in POSIX
  time = df$timestamp,
  #set the projection
  proj = "+proj=longlat +ellps=GRS80 +no_defs",
  #set the id
  animal = as.numeric(df$ind_ident),
  #add the rest of the data
  data = df
)

pythons_prj <- sp::spTransform(
  pythons,
  "+proj=utm +zone=54 +south +datum=WGS84 +units=m +no_defs"
)
