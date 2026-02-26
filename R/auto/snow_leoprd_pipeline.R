# ============================================
# ADD SNOW LEOPARD TO THE PIPELINE
# ============================================

library(sf)
library(readr)
library(tidyverse)
sf_use_s2(FALSE)

setwd("C:/data/R_Projects/natgeo-style-species-maps")

# 1. Unzip shapefile
dir.create("C:/data/Shapefiles/IUCN/snow_leopard",
           recursive = TRUE, showWarnings = FALSE)

unzip(
  zipfile = "C:/data/Shapefiles/IUCN/redlist_species_data_10777b78-0f9c-4d17-a80f-ee574dac1abd.zip",
  exdir   = "C:/data/Shapefiles/IUCN/snow_leopard"
)

shp_files <- list.files(
  "C:/data/Shapefiles/IUCN/snow_leopard",
  pattern = "\\.shp$",
  recursive = TRUE,
  full.names = TRUE
)
message("✓ Shapefile: ", shp_files[1])

# 2. Move photo
file.copy(
  from = "C:/data/Shapefiles/IUCN/330px-Uncia_uncia.jpg",
  to   = "data/photos/snow_leopard.jpg",
  overwrite = TRUE
)
message("✓ Photo copied")

# 3. Add to queue
queue <- read_csv("data/species_queue.csv", show_col_types = FALSE)

queue <- bind_rows(queue, tibble(
  common_name     = "Snow Leopard",
  scientific_name = "Panthera uncia",
  shapefile_path  = shp_files[1],
  photo_path      = "data/photos/snow_leopard.jpg",
  photo_credit    = "Bernard Landgraf / Wikimedia Commons / CC BY-SA 3.0",
  palette_type    = "mountain",
  continent       = "Asia",
  iucn_status     = "Vulnerable"
))

write_csv(queue, "data/species_queue.csv")
message("✓ Queue updated — ", nrow(queue), " species")

# 4. Verify shapefile loads
snow_leopard <- st_read(shp_files[1], quiet = TRUE)
bbox <- st_bbox(snow_leopard)
message("✓ Shapefile loaded — ",
        round(bbox["xmin"], 1), "° to ",
        round(bbox["xmax"], 1), "° lon | ",
        round(bbox["ymin"], 1), "° to ",
        round(bbox["ymax"], 1), "° lat")

# 5. Build the map
source("R/auto/generate_map.R")

build_species_map(
  common_name     = "Snow Leopard",
  scientific_name = "Panthera uncia",
  shapefile_path  = shp_files[1],
  photo_path      = "data/photos/snow_leopard.jpg",
  photo_credit    = "Bernard Landgraf / Wikimedia Commons / CC BY-SA 3.0",
  palette_type    = "mountain",
  output_path     = "outputs/snow_leopard_natgeo.png"
)

message("🐆 Snow Leopard complete!")