rm(list = ls())

# Load preprocessed data
df <- readRDS("data/processed/RDS/points_df.RDS")
pythons_prj <- readRDS("data/processed/RDS/pythons_prj.RDS")

pythons_ade <- move::move2ade(pythons_prj)

mcp_90 <- adehabitatHR::mcp(
  pythons_ade,
  percent = 90,
  unin = "m",
  unout = "ha"
)
mcp_100 <- adehabitatHR::mcp(
  pythons_ade,
  percent = 100,
  unin = "m",
  unout = "ha"
)

kde <- adehabitatHR::kernelUD(pythons_ade, h = "href", extent = 1.5)
kde_area <- adehabitatHR::kernel.area(
  kde,
  percent = c(50, 75, 95),
  unin = "m",
  unout = "ha"
)

bbmm <- move::brownian.bridge.dyn(
  pythons_prj,
  raster = 10,
  location.error = 19,
  margin = 3,
  window.size = 7
)

bbmm_ud <- move::getVolumeUD(bbmm)

saveRDS(mcp_90, "data/processed/RDS/mcp_90.RDS")
saveRDS(mcp_100, "data/processed/RDS/mcp_100.RDS")
saveRDS(kde, "data/processed/RDS/kde.RDS")
saveRDS(kde_area, "data/processed/RDS/kde_area.RDS")
saveRDS(bbmm, "data/processed/RDS/bbmm.RDS")
saveRDS(bbmm_ud, "data/processed/RDS/bbmm_ud.RDS")
