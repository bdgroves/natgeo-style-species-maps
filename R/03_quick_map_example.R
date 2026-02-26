# ============================================
# Quick Map Example Using make_natgeo_map()
# Shows how fast a new map can be made
#
# Author: Brooks Groves
# Date: 2025
# ============================================

source("R/utils/make_natgeo_map.R")

# -- Get state data for land base --
states <- ne_states(country = "United States of America",
                    returnclass = "sf")
mexico_states <- ne_states(country = "Mexico",
                           returnclass = "sf")

land <- bind_rows(
  states %>% filter(name %in% c("Arizona", "New Mexico", "California",
                                "Nevada", "Utah", "Colorado", "Texas",
                                "Oregon", "Oklahoma", "Kansas")),
  mexico_states %>% filter(name %in% c("Sonora", "Chihuahua", "Sinaloa",
                                       "Baja California", "Baja California Sur",
                                       "Durango", "Coahuila", "Nayarit"))
)

# -- Make the map! --
make_natgeo_map(
  shapefile_path = "C:/data/Shapefiles/IUCN/heloderma/data_0.shp",
  common_name = "Gila Monster",
  scientific_name = "Heloderma suspectum",
  scientific_name_expr = expression(italic("Heloderma suspectum")),
  output_path = "C:/data/R_Projects/natgeo-style-species-maps/outputs/gila_monster_quick.png",
  land_data = land,
  
  focus_labels = tibble(
    X = c(-112.5, -106),
    Y = c(35.2, 35.2),
    label = c("A R I Z.", "N.  M E X.")
  ),
  
  context_labels = tibble(
    X = c(-120, -117.5, -111.5, -105, -99.5,
          -111, -106, -107, -116, -113, -104, -101),
    Y = c(37.5, 39.5, 40.5, 39.5, 31.5,
          29.5, 28, 24.5, 31.5, 25.5, 25.5, 28),
    label = c("C A L I F.", "N E V A D A", "U T A H",
              "C O L O.", "T E X A S",
              "S O N O R A", "C H I H U A H U A",
              "S I N A L O A", "B A J A\nC A L I F.",
              "B. C.  S U R", "D U R A N G O", "C O A H.")
  ),
  
  country_labels = list(
    list(x = -110, y = 41.3, label = "U N I T E D   S T A T E S", size = 2.8),
    list(x = -108, y = 24, label = "M E X I C O", size = 3.5)
  ),
  
  palette = list(
    land    = "#EBE1D1",
    border  = "#C5B9A8",
    range   = "#D4845A",
    stroke  = "#B8633A",
    focus   = "#8A7E6E",
    context = "#ADA393",
    species = "#B8633A"
  ),
  
  globe_crs = "+proj=ortho +lat_0=32 +lon_0=-110",
  globe_box = list(xmin = -117, xmax = -107, ymin = 25, ymax = 38),
  continent_label = "NORTH\nAMERICA"
)