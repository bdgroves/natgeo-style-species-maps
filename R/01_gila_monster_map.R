# ============================================
# Gila Monster (Heloderma suspectum)
# NatGeo Style Species Range Map
# 
# Author: Brooks Groves
# Date: 2026
# 
# Description:
#   Creates a National Geographic editorial style
#   species range map for the Gila Monster using
#   IUCN Red List spatial data. Features a desert
#   southwest color palette, orthographic globe
#   inset, and NatGeo-style typography.
#
# Data Sources:
#   - Species range: IUCN Red List of Threatened Species
#     https://www.iucnredlist.org
#     (free account required, data not redistributable)
#   - Base map: Natural Earth via rnaturalearth package
#     https://www.naturalearthdata.com
#
# Notes:
#   - IUCN shapefile must be downloaded separately
#     and placed in data/ directory
#   - Leader line from species label to range is
#     added manually in image editor after export
#   - Globe map area box uses geom_sf (not geom_rect)
#     so it projects correctly onto the orthographic globe
#
# Output:
#   outputs/gila_monster_natgeo.png (300 DPI)
# ============================================


# ============================================
# PACKAGES
# ============================================

library(tidyverse)       # data wrangling and ggplot2
library(sf)              # spatial data handling
library(rnaturalearth)   # base map data (countries, states)
library(rnaturalearthdata)
library(cowplot)         # plot composition (ggdraw, draw_plot, plot_grid)
library(ggspatial)       # spatial map utilities


# ============================================
# CONFIGURATION
# ============================================

# -- File paths --
input_shapefile <- "C:/data/Shapefiles/IUCN/heloderma/data_0.shp"
output_path     <- "C:/data/R_Projects/natgeo-style-species-maps/outputs/gila_monster_natgeo.png"

# -- Map extent --
# Controls the geographic bounds of the main map
map_xmin <- -125
map_xmax <- -96
map_ymin <- 23
map_ymax <- 42

# -- Globe inset projection --
# Orthographic projection centered on study area
# Change lat_0 and lon_0 to recenter for different regions
globe_crs <- "+proj=ortho +lat_0=32 +lon_0=-110"

# -- Globe map area box --
# Tighter than map extent to highlight just the range area
globe_box_xmin <- -117
globe_box_xmax <- -107
globe_box_ymin <- 25
globe_box_ymax <- 38

# -- Desert color palette --
# Warm tones for the US/Mexico southwest
land_fill      <- "#EBE1D1"    # warm sand
border_color   <- "#C5B9A8"    # warm tan borders
range_fill     <- "#D4845A"    # terracotta for species range
range_stroke   <- "#B8633A"    # darker terracotta outline
focus_label    <- "#8A7E6E"    # primary state/country labels
context_label  <- "#ADA393"    # secondary state labels
species_color  <- "#B8633A"    # species annotation text

# -- Species info --
common_name    <- "Gila Monster"
scientific_name <- "Heloderma suspectum"
data_source    <- "Source: IUCN Red List of Threatened Species"
map_author     <- "Map by Brooks Groves"

# -- Scale bar --
# Position and sizing for NatGeo-style dual scale bars
sb_x          <- -124.5        # left edge x position
sb_y_mi       <- 24.6          # miles bar y position
sb_y_km       <- 24.0          # km bar y position
deg_per_300mi <- 300 / 58      # approximate degrees per 300 miles at ~32N
deg_per_300km <- 300 / 94      # approximate degrees per 300 km at ~32N

# -- Species label position --
# Placed in the ocean area (white space) to avoid clutter
label_x <- -124.5
label_y <- 28


# ============================================
# HELPER FUNCTION
# ============================================

#' Add spaces between letters for NatGeo-style labels
#' 
#' National Geographic editorial maps use wide letter-spacing
#' in uppercase state and country labels. This function
#' converts "Arizona" to "A R I Z O N A"
#'
#' @param text Character string to space out
#' @param spaces Number of spaces between each letter (default 1)
#' @return Character string with spaces inserted
space_text <- function(text, spaces = 1) {
  sapply(text, function(t) {
    paste(strsplit(toupper(t), "")[[1]],
          collapse = paste(rep(" ", spaces), collapse = ""))
  })
}


# ============================================
# LOAD DATA
# ============================================

# Species range polygon from IUCN Red List
gila <- st_read(input_shapefile)
gila_bbox <- st_bbox(gila)

# US and Mexico state boundaries from Natural Earth
states <- ne_states(country = "United States of America",
                    returnclass = "sf")

mexico_states <- ne_states(country = "Mexico",
                           returnclass = "sf")

# Country polygons for borders
countries <- ne_countries(scale = "medium", returnclass = "sf")

message("✓ Data loaded")
message(paste("  Range extent:", 
              round(gila_bbox["xmin"], 1), "to", 
              round(gila_bbox["xmax"], 1), "lon,",
              round(gila_bbox["ymin"], 1), "to", 
              round(gila_bbox["ymax"], 1), "lat"))


# ============================================
# PREPARE LAND BASE
# ============================================

# US states visible in the map extent
us_states <- states %>% 
  filter(name %in% c("Arizona", "New Mexico", "California", 
                     "Nevada", "Utah", "Colorado", "Texas",
                     "Oregon", "Oklahoma", "Kansas"))

# Mexican states visible in the map extent
mx_states <- mexico_states %>%
  filter(name %in% c("Sonora", "Chihuahua", "Sinaloa",
                     "Baja California", "Baja California Sur",
                     "Durango", "Coahuila", "Nayarit"))

# Combined land base for the map
all_land <- bind_rows(us_states, mx_states)

message("✓ Land base prepared")


# ============================================
# LABEL POSITIONS
# ============================================

# Labels are manually positioned to avoid overlapping
# the species range and each other. Coordinates are
# in WGS84 (longitude, latitude).
#
# Focus labels: states where the species occurs (larger text)
# Context labels: surrounding states for geographic reference (smaller text)

# US focus states — where the Gila Monster lives
us_focus_labels <- tibble(
  X = c(-112.5, -106),
  Y = c(35.2, 35.2),
  label = c("A R I Z.", "N.  M E X.")
)

# US context states — surrounding geographic reference
us_context_labels <- tibble(
  X = c(-120, -117.5, -111.5, -105, -99.5),
  Y = c(37.5, 39.5, 40.5, 39.5, 31.5),
  label = c("C A L I F.",
            "N E V A D A",
            "U T A H",
            "C O L O.",
            "T E X A S")
)

# Mexico focus states — where the Gila Monster lives
mx_focus_labels <- tibble(
  X = c(-111, -106, -107),
  Y = c(29.5, 28, 24.5),
  label = c("S O N O R A",
            "C H I H U A H U A",
            "S I N A L O A")
)

# Mexico context states — surrounding geographic reference
mx_context_labels <- tibble(
  X = c(-116, -113, -104, -101),
  Y = c(31.5, 25.5, 25.5, 28),
  label = c("B A J A\nC A L I F.",
            "B. C.  S U R",
            "D U R A N G O",
            "C O A H.")
)

message("✓ Labels positioned")


# ============================================
# BUILD MAIN MAP
# ============================================

main_map <- ggplot() +
  
  # -- Base layers --
  
  # State/province polygons as land fill
  geom_sf(data = all_land,
          fill = land_fill,
          color = border_color,
          linewidth = 0.15) +
  
  # Country borders (US/Mexico) drawn thicker
  geom_sf(data = countries %>%
            filter(name %in% c("United States of America", "Mexico")),
          fill = NA,
          color = border_color,
          linewidth = 0.4) +
  
  # -- Species range --
  
  geom_sf(data = gila,
          fill = range_fill,
          color = range_stroke,
          alpha = 0.85,
          linewidth = 0.3) +
  
  # -- Country labels --
  
  annotate("text", x = -110, y = 41.3,
           label = "U N I T E D   S T A T E S",
           color = focus_label, size = 2.8) +
  annotate("text", x = -108, y = 24,
           label = "M E X I C O",
           color = focus_label, size = 3.5) +
  
  # -- State labels --
  
  # US focus (larger, darker)
  geom_text(data = us_focus_labels,
            aes(x = X, y = Y, label = label),
            color = focus_label, size = 3) +
  
  # US context (smaller, lighter)
  geom_text(data = us_context_labels,
            aes(x = X, y = Y, label = label),
            color = context_label, size = 2.5) +
  
  # Mexico focus (larger, darker)
  geom_text(data = mx_focus_labels,
            aes(x = X, y = Y, label = label),
            color = focus_label, size = 2.5) +
  
  # Mexico context (smaller, lighter, multi-line)
  geom_text(data = mx_context_labels,
            aes(x = X, y = Y, label = label),
            color = context_label, size = 1.8,
            lineheight = 0.8) +
  
  # -- Species annotation --
  # Leader line is added manually in image editor after export
  
  # Common name (bold)
  annotate("text", x = label_x, y = label_y,
           label = paste(common_name, "range"),
           color = species_color, size = 3,
           hjust = 0, fontface = "bold") +
  
  # Scientific name (italic, slightly indented)
  annotate("text", x = label_x + 0.5, y = label_y - 0.8,
           label = scientific_name,
           color = species_color, size = 2.8,
           hjust = 0, fontface = "italic") +
  
  # -- NatGeo-style dual scale bars --
  # Miles above, kilometers below
  
  # Miles bar and label
  annotate("segment",
           x = sb_x, xend = sb_x + deg_per_300mi,
           y = sb_y_mi, yend = sb_y_mi,
           color = "#666666", linewidth = 0.4) +
  annotate("text",
           x = sb_x, y = sb_y_mi + 0.3,
           label = "300 mi",
           color = "#666666", size = 2.2, hjust = 0) +
  
  # Km bar and label
  annotate("segment",
           x = sb_x, xend = sb_x + deg_per_300km,
           y = sb_y_km, yend = sb_y_km,
           color = "#666666", linewidth = 0.4) +
  annotate("text",
           x = sb_x, y = sb_y_km + 0.3,
           label = "300 km",
           color = "#666666", size = 2.2, hjust = 0) +
  
  # -- Map extent and theme --
  
  coord_sf(xlim = c(map_xmin, map_xmax),
           ylim = c(map_ymin, map_ymax),
           expand = FALSE) +
  
  theme_void() +
  theme(
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    plot.margin = margin(5, 5, 5, 5, "mm")
  )

message("✓ Main map built")


# ============================================
# BUILD GLOBE INSET
# ============================================

# The map area box must be created as an sf polygon
# so it projects correctly onto the orthographic globe.
# Using geom_rect() does NOT work — the coordinates
# don't transform properly in orthographic projection.

map_box_coords <- matrix(c(
  globe_box_xmin, globe_box_ymin,
  globe_box_xmax, globe_box_ymin,
  globe_box_xmax, globe_box_ymax,
  globe_box_xmin, globe_box_ymax,
  globe_box_xmin, globe_box_ymin
), ncol = 2, byrow = TRUE)

map_box <- st_sf(
  geometry = st_sfc(
    st_polygon(list(map_box_coords)),
    crs = 4326
  )
)

globe <- ggplot() +
  
  # Country polygons as land
  geom_sf(data = countries,
          fill = "#D5CFC3",
          color = "#B0B0B0",
          linewidth = 0.15) +
  
  # Map area indicator box
  geom_sf(data = map_box,
          fill = "transparent",
          color = "black",
          linewidth = 0.8) +
  
  # Orthographic projection (globe view)
  coord_sf(crs = globe_crs) +
  
  # Continent label
  annotate("text", x = -3000000, y = 4500000,
           label = "NORTH\nAMERICA",
           color = "#5A8A9A", size = 2.5,
           fontface = "bold", lineheight = 0.8) +
  
  # Map area label
  annotate("text", x = 1500000, y = -500000,
           label = "MAP\nAREA",
           color = "black", size = 2,
           fontface = "bold", lineheight = 0.8) +
  
  theme_void() +
  theme(
    panel.background = element_rect(fill = "#C8DAE5",
                                    color = "#B0B0B0",
                                    linewidth = 0.3),
    plot.background = element_rect(fill = "transparent",
                                   color = NA),
    aspect.ratio = 1,
    plot.margin = margin(0, 0, 0, 0)
  )

message("✓ Globe inset built")


# ============================================
# BUILD TITLE AND ATTRIBUTION
# ============================================

# Title block with common name (bold) and scientific name (italic)
title_text <- ggdraw() +
  draw_label(common_name,
             x = 0.5, y = 0.65,
             size = 22, fontface = "bold",
             color = "#333333") +
  draw_label(expression(italic("Heloderma suspectum")),
             x = 0.5, y = 0.25,
             size = 14, color = "#888888")

# Attribution block
attribution <- ggdraw() +
  draw_label(data_source,
             x = 0.02, y = 0.7,
             size = 6, color = "#AAAAAA", hjust = 0) +
  draw_label(map_author,
             x = 0.02, y = 0.3,
             size = 6, color = "#AAAAAA", hjust = 0)

message("✓ Title and attribution built")


# ============================================
# COMPOSE FINAL MAP
# ============================================

# Overlay the globe inset on the main map
# Position: upper right corner
map_with_globe <- ggdraw() +
  draw_plot(main_map) +
  draw_plot(globe,
            x = 0.60,          # horizontal position (0=left, 1=right)
            y = 0.58,          # vertical position (0=bottom, 1=top)
            width = 0.38,      # globe width relative to page
            height = 0.38)     # globe height relative to page

# Stack: title on top, map in middle, attribution at bottom
final_map <- plot_grid(
  title_text,
  map_with_globe,
  attribution,
  ncol = 1,
  rel_heights = c(0.08, 0.85, 0.04)
)

message("✓ Final composition assembled")


# ============================================
# EXPORT
# ============================================

ggsave(output_path,
       final_map,
       width = 210,            # A4 width in mm
       height = 280,           # slightly taller than A4
       units = "mm",
       dpi = 300,              # print quality
       bg = "white")

message(paste("✓ Map exported to:", output_path))
message("🦎 Done!")