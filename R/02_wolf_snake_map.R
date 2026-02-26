# ============================================
# Namibian Wolf Snake (Lycophidion namibianum)
# NatGeo Style Species Range Map
# 
# Author: Brooks Groves
# Date: 2026
# 
# Description:
#   Creates a National Geographic editorial style
#   species range map for the Namibian Wolf Snake
#   using IUCN Red List spatial data. Features a
#   warm African palette with golden ochre range
#   and orthographic globe inset.
#
# Data Sources:
#   - Species range: IUCN Red List of Threatened Species
#     https://www.iucnredlist.org
#   - Base map: Natural Earth via rnaturalearth package
#     https://www.naturalearthdata.com
#
# Output:
#   outputs/wolf_snake_natgeo.png (300 DPI)
# ============================================


# ============================================
# PACKAGES
# ============================================

library(tidyverse)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(cowplot)
library(ggspatial)


# ============================================
# CONFIGURATION
# ============================================

# -- File paths --
input_shapefile <- "C:/data/Shapefiles/IUCN/lycophidion/data_0.shp"
output_path     <- "C:/data/R_Projects/natgeo-style-species-maps/outputs/wolf_snake_natgeo.png"

# -- Map extent --
map_xmin <- 5
map_xmax <- 38
map_ymin <- -36
map_ymax <- -2

# -- Globe inset --
globe_crs      <- "+proj=ortho +lat_0=-15 +lon_0=17"
globe_box_xmin <- 10
globe_box_xmax <- 30
globe_box_ymin <- -30
globe_box_ymax <- -5

# -- African color palette --
# Warm earth tones for southern Africa
land_fill      <- "#E4DDD0"    # warm beige
border_color   <- "#C5BDB1"    # warm gray borders
range_fill     <- "#C8A856"    # golden ochre
range_stroke   <- "#B8983E"    # darker ochre outline
focus_label    <- "#8A8478"    # primary country labels
context_label  <- "#A8A198"    # secondary country labels
species_color  <- "#B8983E"    # species annotation text

# -- Species info --
common_name     <- "Namibian Wolf Snake"
scientific_name <- "Lycophidion namibianum"
data_source     <- "Source: IUCN Red List of Threatened Species"
map_author      <- "Map by Brooks Groves"

# -- Scale bar --
sb_x          <- 7
sb_y_mi       <- -34.6
sb_y_km       <- -35.2
deg_per_300mi <- 300 / 60      # approximate at this latitude
deg_per_300km <- 300 / 96

# -- Species label position --
label_x <- 6
label_y <- -22


# ============================================
# HELPER FUNCTION
# ============================================

space_text <- function(text, spaces = 1) {
  sapply(text, function(t) {
    paste(strsplit(toupper(t), "")[[1]],
          collapse = paste(rep(" ", spaces), collapse = ""))
  })
}


# ============================================
# LOAD DATA
# ============================================

wolf_snake <- st_read(input_shapefile)
range_bbox <- st_bbox(wolf_snake)

countries <- ne_countries(scale = "medium", returnclass = "sf")

africa <- countries %>%
  filter(continent == "Africa")

message("✓ Data loaded")
message(paste("  Range extent:",
              round(range_bbox["xmin"], 1), "to",
              round(range_bbox["xmax"], 1), "lon,",
              round(range_bbox["ymin"], 1), "to",
              round(range_bbox["ymax"], 1), "lat"))


# ============================================
# LABEL POSITIONS
# ============================================

# Focus countries — where the species lives
focus_labels <- tibble(
  X = c(17.5, 18),
  Y = c(-12, -22),
  label = c(space_text("Angola"), space_text("Namibia"))
)

# Context countries — surrounding geographic reference
context_labels <- tibble(
  X = c(25, 24, 25, 33, 30, 35, 34, 29, 28),
  Y = c(-3, -14, -22, -8, -15, -19, -25, -30, -27),
  label = c("D E M.  R E P.\nC O N G O",
            space_text("Zambia"),
            space_text("Botswana"),
            space_text("Tanzania"),
            space_text("Malawi"),
            space_text("Mozambique"),
            space_text("Zimbabwe"),
            space_text("South Africa"),
            space_text("Lesotho"))
)

message("✓ Labels positioned")


# ============================================
# BUILD MAIN MAP
# ============================================

main_map <- ggplot() +
  
  # -- Base layers --
  
  # African countries as land fill
  geom_sf(data = africa,
          fill = land_fill,
          color = border_color,
          linewidth = 0.15) +
  
  # -- Species range --
  
  geom_sf(data = wolf_snake,
          fill = range_fill,
          color = range_stroke,
          alpha = 0.85,
          linewidth = 0.3) +
  
  # -- Country labels --
  
  # Focus countries (larger, darker)
  geom_text(data = focus_labels,
            aes(x = X, y = Y, label = label),
            color = focus_label, size = 4) +
  
  # Context countries (smaller, lighter)
  geom_text(data = context_labels,
            aes(x = X, y = Y, label = label),
            color = context_label, size = 2.5,
            lineheight = 0.8) +
  
  # -- Species annotation --
  
  # Common name (bold)
  annotate("text", x = label_x, y = label_y,
           label = paste(common_name, "range"),
           color = species_color, size = 3,
           hjust = 0, fontface = "bold") +
  
  # Scientific name (italic)
  annotate("text", x = label_x + 0.5, y = label_y - 1.5,
           label = scientific_name,
           color = species_color, size = 2.8,
           hjust = 0, fontface = "italic") +
  
  # -- Scale bars --
  
  # Miles
  annotate("segment",
           x = sb_x, xend = sb_x + deg_per_300mi,
           y = sb_y_mi, yend = sb_y_mi,
           color = "#666666", linewidth = 0.4) +
  annotate("text",
           x = sb_x, y = sb_y_mi + 0.5,
           label = "300 mi",
           color = "#666666", size = 2.2, hjust = 0) +
  
  # Km
  annotate("segment",
           x = sb_x, xend = sb_x + deg_per_300km,
           y = sb_y_km, yend = sb_y_km,
           color = "#666666", linewidth = 0.4) +
  annotate("text",
           x = sb_x, y = sb_y_km + 0.5,
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
  geom_sf(data = countries,
          fill = "#D5CFC3",
          color = "#B0B0B0",
          linewidth = 0.15) +
  
  geom_sf(data = map_box,
          fill = "transparent",
          color = "black",
          linewidth = 0.8) +
  
  coord_sf(crs = globe_crs) +
  
  annotate("text", x = 0, y = 5500000,
           label = "AFRICA",
           color = "#5A8A9A", size = 2.5,
           fontface = "bold") +
  
  annotate("text", x = 2500000, y = -2500000,
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

title_text <- ggdraw() +
  draw_label(common_name,
             x = 0.5, y = 0.65,
             size = 22, fontface = "bold",
             color = "#333333") +
  draw_label(expression(italic("Lycophidion namibianum")),
             x = 0.5, y = 0.25,
             size = 14, color = "#888888")

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

map_with_globe <- ggdraw() +
  draw_plot(main_map) +
  draw_plot(globe,
            x = 0.60, y = 0.58,
            width = 0.38, height = 0.38)

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
       width = 210, height = 280,
       units = "mm", dpi = 300, bg = "white")

message(paste("✓ Map exported to:", output_path))
message("🐍 Done!")