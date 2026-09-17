rm(list = ls())

# Read raw data
raw <- utils::read.csv(
  "data/processed/misc/points.csv"
)
# Perform preprocessing
df <- raw |>
  dplyr::mutate(
    timestamp = as.POSIXct(timestamp, format = "%Y-%m-%d %H:%M:%S", tz = "UTC") # convert timesetamp to POSIXct format
  ) |>
  dplyr::arrange(ind_ident, timestamp) # sort dataframe by unique identifier and timestamp

# There are duplicated rows in the data for records with ind_ident = 1
df |>
  dplyr::group_by(dplyr::across(-c(FID, tag_ident))) |>
  dplyr::filter(dplyr::n() > 1) |>
  dplyr::ungroup() |>
  dplyr::count(tag_ident, ind_ident)

df <- df |>
  dplyr::filter(!tag_ident %in% "1-Tag") # remove records with tag_ident = 1-Tag

# There are some records from much later years, create a timestamp_group variable
# to separate the 2019 records from the rest of the data
df |>
  dplyr::count(strftime(timestamp, '%Y'))

df <- df |>
  dplyr::mutate(
    timestamp_group = dplyr::if_else(
      strftime(timestamp, '%Y') == "2019",
      2,
      1
    )
  )

saveRDS(df, "data/processed/RDS/points_df.RDS")
