# Green Tree Snake Movement and Home Range Analysis

Author: Sabastian Bouma

## Overview

This repository contains all code and data processing for the analysis of movement and home range of green tree snakes (Morelia viridis) in Kutini-Payamu National Park, Cape York, Queensland, Australia. The project uses radio telemetry data from 27 individuals to estimate home range size, movement metrics, and identify common-use areas, using a combination of MCP, KDE, and dynamic Brownian bridge movement models (BBMM). NDVI is used to provide vegetation context for home ranges.

## Data
- **Source:** movebank.org (study: "Green python Morelia viridis, Cape York Australia")
- **Description:** Radio telemetry data for 27 individuals, 2002–2005, Kutini-Payamu National Park
- **Note:** Raw data is not included in this repository. Download from Movebank and place in `data/raw/`.

## Repository Structure
- `scripts/` - R scripts for preprocessing, analysis, and visualization (run in order: 1_preprocessing.R, 2_estimates.R, ...)
- `data/` - Contains `raw/` (input data) and `processed/` (intermediate and output files)
- `ref/` - Reference documents and assignment brief
- `project/` - GIS project files

## Requirements
- R (>= 4.3.3)
- R packages: move, adehabitatHR, sf, terra, raster, dplyr, ggplot2, purrr, tidyr, stringr, DBI, RPostgres
- PostgreSQL/PostGIS (optional, for spatial database storage)

## Setup
1. Download the raw data from Movebank and place in `data/raw/`.
2. Install required R packages.
3. If using the database features, update the database connection string in scripts to match your local PostgreSQL/PostGIS setup.

## Running the Analysis
Run the scripts in order:
1. `scripts/1_preprocessing.R` - Clean and preprocess raw data
2. `scripts/2_estimates.R` - Estimate home ranges (MCP, KDE, BBMM)
3. `scripts/3_summary_stats.R` - Summarize movement and home range metrics
4. `scripts/4_common_areas.R` - Identify common-use areas
5. `scripts/5_gis_objects.R` - Export spatial objects to database
6. `scripts/6_common_areas_analysis.R` - Analyze and summarize common areas
7. `scripts/7_ndvi.R` - Extract NDVI statistics for home ranges
8. `scripts/8_scatter_plot.R` - Visualize relationships

## Output
- Processed data and results are saved in `data/processed/`.
- Figures and tables are generated for inclusion in the final report.

## Credits
- Author: Sabastian Bouma
- Unit: SPAT5008 (Applied Geographic Information Systems), Curtin University

## References
- See `Green Tree Snake Movement and Home Range Analysis.docx` and `ref/Assignment2_AGIS_2026.pdf` for full literature review and methodology.

## Notes
- The PostgreSQL/PostGIS database connection is optional and used for spatial data management. Users should provide their own connection string.
- Additional analysis for the report was completed in ArcGIS Pro using the spatial objects added to the PostgreSQL/PostGIS database
- All code is provided for reproducibility. Data must be obtained from Movebank.
