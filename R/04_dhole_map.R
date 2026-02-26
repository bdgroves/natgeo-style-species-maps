# ============================================
# Dhole / Asian Wild Dog (Cuon alpinus)
# NatGeo Style Species Range Map
# Author: Brooks Groves  |  Date: 2026
# ============================================

library(tidyverse)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(cowplot)
library(magick)
library(grid)


# ============================================
# CONFIGURATION
# ============================================

input_shapefile <- "C:/data/Shapefiles/IUCN/dhole/data_0.shp"
image_path      <- "C:/data/R_Projects/natgeo-style-species-maps/data/Cuon.alpinus-cut.jpg"
output_path     <- "C:/data/R_Projects/natgeo-style-species-maps/outputs/dhole_natgeo.png"

map_xmin <- 62
map_xmax <- 128
map_ymin <- -11
map_ymax <-  45

land_fill      <- "#E4DDD0"
border_color   <- "#C5B9A8"
range_fill     <- "#8B6E4E"
range_stroke   <- "#6B5038"
focus_label    <- "#7A6E62"
context_label  <- "#ADA393"
species_color  <- "#6B5038"
ocean_color    <- "#D6E8F0"

common_name     <- "Dhole"
scientific_name <- "Cuon alpinus"
data_source     <- "Source: IUCN Red List of Threatened Species"
map_author      <- "Map by Brooks Groves"

sb_x          <- 64
sb_y_mi       <- -8.0
sb_y_km       <- -9.3
deg_per_500mi <- 500 / 55
deg_per_500km <- 500 / 90

label_x <- 63
label_y <-  2.5


# ============================================
# HELPER
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

sf_use_s2(FALSE)

dhole     <- st_read(input_shapefile, quiet = TRUE)
countries <- ne_countries(scale = "medium", returnclass = "sf")

asia_land <- countries %>%
  filter(name %in% c(
    "India", "China", "Myanmar", "Thailand",
    "Laos", "Vietnam", "Cambodia", "Malaysia",
    "Indonesia", "Bangladesh", "Nepal", "Bhutan",
    "Pakistan", "Afghanistan", "Sri Lanka",
    "Philippines", "Brunei", "Singapore",
    "Mongolia", "Kazakhstan", "Kyrgyzstan",
    "Tajikistan", "Uzbekistan", "Turkmenistan",
    "Japan", "South Korea", "North Korea",
    "Taiwan", "Papua New Guinea"
  ))

message("✓ Data loaded")


# ============================================
# LOAD ANIMAL IMAGE
# ============================================

dhole_img  <- image_read(image_path)
dhole_grob <- rasterGrob(as.raster(dhole_img), interpolate = TRUE)

img_info   <- image_info(dhole_img)
img_aspect <- img_info$width / img_info$height

message(paste("✓ Image loaded —",
              img_info$width, "×", img_info$height,
              "px | aspect ratio:", round(img_aspect, 3)))


# ============================================
# LABELS
# ============================================

focus_labels <- tibble(
  X = c( 76,  113,   99,  101,  106,  110,  106,  112,   92,   93,   81),
  Y = c( 18,   30,   21,   14,   21,   16,   11,    3,   25,   28,   29),
  label = c(
    space_text("India"),
    space_text("China"),
    space_text("Myanmar"),
    space_text("Thailand"),
    space_text("Laos"),
    space_text("Vietnam"),
    space_text("Cambodia"),
    space_text("Malaysia"),
    space_text("Bangladesh"),
    space_text("Bhutan"),
    space_text("Nepal")
  )
)

context_labels <- tibble(
  X = c(  67,   65,   79,  120,   94,  118,  134,  126),
  Y = c(  31,   35,    7,   14,   44,   -5,   34,   36),
  label = c(
    space_text("Pakistan"),
    "A F G H A N.",
    "S R I\nL A N K A",
    "P H I L I P.",
    space_text("Mongolia"),
    "I N D O N E S I A",
    space_text("Japan"),
    "S. K O R E A"
  )
)

message("✓ Labels set")


# ============================================
# MAIN MAP
# ============================================

main_map <- ggplot() +
  
  geom_sf(data      = asia_land,
          fill      = land_fill,
          color     = border_color,
          linewidth = 0.15) +
  
  geom_sf(data      = dhole,
          fill      = range_fill,
          color     = range_stroke,
          alpha     = 0.85,
          linewidth = 0.3) +
  
  geom_text(data = focus_labels,
            aes(x = X, y = Y, label = label),
            color = focus_label, size = 3.0) +
  
  geom_text(data = context_labels,
            aes(x = X, y = Y, label = label),
            color = context_label, size = 2.3,
            lineheight = 0.8) +
  
  annotate("text",
           x = label_x, y = label_y,
           label = paste(common_name, "range"),
           color = species_color, size = 3.0,
           hjust = 0, fontface = "bold") +
  
  annotate("text",
           x = label_x + 0.2, y = label_y - 1.5,
           label = scientific_name,
           color = species_color, size = 2.6,
           hjust = 0, fontface = "italic") +
  
  annotate("segment",
           x = sb_x, xend = sb_x + deg_per_500mi,
           y = sb_y_mi, yend = sb_y_mi,
           color = "#666666", linewidth = 0.4) +
  annotate("text",
           x = sb_x, y = sb_y_mi + 0.55,
           label = "500 mi",
           color = "#666666", size = 2.1, hjust = 0) +
  
  annotate("segment",
           x = sb_x, xend = sb_x + deg_per_500km,
           y = sb_y_km, yend = sb_y_km,
           color = "#666666", linewidth = 0.4) +
  annotate("text",
           x = sb_x, y = sb_y_km + 0.55,
           label = "500 km",
           color = "#666666", size = 2.1, hjust = 0) +
  
  coord_sf(xlim   = c(map_xmin, map_xmax),
           ylim   = c(map_ymin, map_ymax),
           expand = FALSE) +
  
  theme_void() +
  theme(
    panel.background = element_rect(fill  = ocean_color, color = NA),
    plot.background  = element_rect(fill  = ocean_color, color = NA),
    plot.margin      = margin(0, 0, 0, 0)
  )

message("✓ Main map built")


# ============================================
# LOCATOR INSET
# ============================================

world_inset <- ne_countries(scale = "small", returnclass = "sf")

inset_xmin <-   0
inset_xmax <- 160
inset_ymin <- -60
inset_ymax <-  72

locator_box <- st_sf(
  geometry = st_sfc(
    st_polygon(list(matrix(c(
      map_xmin, map_ymin,
      map_xmax, map_ymin,
      map_xmax, map_ymax,
      map_xmin, map_ymax,
      map_xmin, map_ymin
    ), ncol = 2, byrow = TRUE))),
    crs = 4326
  )
)

locator_inset <- ggplot() +
  
  geom_rect(aes(xmin = inset_xmin, xmax = inset_xmax,
                ymin = inset_ymin, ymax = inset_ymax),
            fill = "#C8DAE5") +
  
  geom_sf(data      = world_inset,
          fill      = "#D5CFC3",
          color     = "#B8B0A4",
          linewidth = 0.08) +
  
  geom_sf(data      = locator_box,
          fill      = range_fill,
          color     = range_stroke,
          alpha     = 0.45,
          linewidth = 0.7) +
  
  annotate("text", x = 95, y = 15,
           label = "MAP\nAREA", color = "white",
           size = 1.85, fontface = "bold",
           lineheight = 0.85) +
  
  annotate("text", x = 75, y = 63,
           label = "ASIA", color = "#5A8A9A",
           size = 2.3, fontface = "bold") +
  
  coord_sf(xlim   = c(inset_xmin, inset_xmax),
           ylim   = c(inset_ymin, inset_ymax),
           expand = FALSE) +
  
  theme_void() +
  theme(
    panel.background = element_rect(fill      = "#C8DAE5",
                                    color     = "#7A9EAD",
                                    linewidth = 0.7),
    plot.background  = element_rect(fill  = "transparent",
                                    color = NA),
    plot.margin = margin(0, 0, 0, 0)
  )

message("✓ Locator inset built")


# ============================================
# PAGE LAYOUT CALCULATIONS
#
# All dimensions in mm first, then converted
# to 0-1 proportions for ggdraw().
#
# Page width = 240 mm (fixed)
#
# Left column  = 75% = 180 mm  (main map)
# Right column = 25% =  60 mm  (inset + photo)
#
# Map height = map_width × (lat_span / lon_span)
#            = 180 × (56/66) = 152.7 mm
#
# Title       =  28 mm  (top)
# Attribution =  16 mm  (bottom)
# Page height = 152.7 + 28 + 16 = 196.7 → 197 mm
#
# Right column breakdown:
#   Inset height = col_width × (lat/lon of inset window)
#                = 60 × (132/160) = 49.5 mm
#   Gap          =  3 mm
#   Photo height = map_height - inset_height - gap
#                = 152.7 - 49.5 - 3 = 100.2 mm
#   Caption      =  4 mm  (inside photo bottom)
# ============================================

page_w_mm  <- 240
col_l_frac <- 0.75    # left column fraction
col_r_frac <- 0.25    # right column fraction

col_l_mm   <- page_w_mm * col_l_frac   # 180 mm
col_r_mm   <- page_w_mm * col_r_frac   #  60 mm

map_lat    <- map_ymax - map_ymin       # 56°
map_lon    <- map_xmax - map_xmin       # 66°
map_h_mm   <- col_l_mm * (map_lat / map_lon)   # 152.7 mm

title_mm   <- 28
attrib_mm  <- 16
page_h_mm  <- map_h_mm + title_mm + attrib_mm  # ~197 mm

inset_geo_asp <- (inset_ymax - inset_ymin) / (inset_xmax - inset_xmin)
inset_h_mm    <- col_r_mm * inset_geo_asp       # 49.5 mm
gap_mm        <- 3
photo_h_mm    <- map_h_mm - inset_h_mm - gap_mm # 100.2 mm

message(paste("  Page:", round(page_w_mm), "×", round(page_h_mm), "mm"))
message(paste("  Map panel:", round(col_l_mm), "×", round(map_h_mm), "mm"))
message(paste("  Inset:", round(col_r_mm), "×", round(inset_h_mm), "mm"))
message(paste("  Photo:", round(col_r_mm), "×", round(photo_h_mm), "mm"))

# Convert to 0-1 canvas proportions
# ggdraw: (0,0) = bottom-left, (1,1) = top-right

attrib_p   <- attrib_mm  / page_h_mm
map_h_p    <- map_h_mm   / page_h_mm
title_p    <- title_mm   / page_h_mm
col_r_p    <- col_r_frac
col_l_p    <- col_l_frac
inset_h_p  <- inset_h_mm / page_h_mm
photo_h_p  <- photo_h_mm / page_h_mm
gap_p      <- gap_mm     / page_h_mm

# Y anchor positions (from bottom)
map_y      <- attrib_p                        # map bottom
title_y    <- attrib_p + map_h_p              # title bottom
inset_y    <- attrib_p + map_h_p - inset_h_p  # inset bottom
photo_y    <- attrib_p                        # photo bottom
# (sits on attribution band)

# X anchor positions (from left)
col_r_x    <- col_l_p + 0.005   # small gap between columns


# ============================================
# COMPOSE — single ggdraw() canvas
# ============================================

final_map <- ggdraw() +
  
  # White page background
  draw_grob(grid::rectGrob(
    gp = grid::gpar(fill = "white", col = NA)
  )) +
  
  # ── Main map — left column ─────────────────
  draw_plot(main_map,
            x      = 0,
            y      = map_y,
            width  = col_l_p,
            height = map_h_p) +
  
  # ── Locator inset — right column top ───────
  draw_plot(locator_inset,
            x      = col_r_x,
            y      = inset_y,
            width  = col_r_p - 0.005,
            height = inset_h_p) +
  
  # ── Animal photo — right column bottom ─────
  draw_grob(dhole_grob,
            x      = col_r_x,
            y      = photo_y + 0.008,   # small bottom margin
            width  = col_r_p - 0.008,
            height = photo_h_p - gap_p - 0.012) +
  
  # Photo caption — sits below the image
  draw_label(
    "Dhole (Cuon alpinus)  ·  Photo credit",
    x        = col_r_x,
    y        = photo_y + 0.003,
    size     = 5,
    color    = "#AAAAAA",
    hjust    = 0,
    fontface = "italic"
  ) +
  
  # ── Title — centered on full page ──────────
  draw_label(common_name,
             x        = 0.5,
             y        = title_y + title_p * 0.67,
             size     = 28,
             fontface = "bold",
             color    = "#2B2B2B",
             hjust    = 0.5) +
  
  draw_label(expression(italic("Cuon alpinus")),
             x     = 0.5,
             y     = title_y + title_p * 0.24,
             size  = 16,
             color = "#888888",
             hjust = 0.5) +
  
  # ── Attribution — bottom of page ───────────
  draw_label(data_source,
             x     = 0.02,
             y     = attrib_p * 0.65,
             size  = 6,
             color = "#AAAAAA",
             hjust = 0) +
  
  draw_label(map_author,
             x     = 0.02,
             y     = attrib_p * 0.28,
             size  = 6,
             color = "#AAAAAA",
             hjust = 0)

message("✓ Composed")


# ============================================
# EXPORT
# ============================================

ggsave(output_path,
       final_map,
       width  = page_w_mm,
       height = page_h_mm,
       units  = "mm",
       dpi    = 300,
       bg     = "white")

message(paste("✓ Exported:", output_path))
message("🐕 Done!")