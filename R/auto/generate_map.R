# ============================================
# generate_map.R
# Auto Species Map Generator
# Author: Brooks Groves | Date: 2026
#
# Usage:
#   source("R/auto/generate_map.R")
#   build_species_map(common_name = "Dhole", ...)
#   run_queue()
# ============================================

library(tidyverse)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(cowplot)
library(magick)
library(grid)

sf_use_s2(FALSE)


# ============================================
# PALETTE LIBRARY
# ============================================

palettes <- list(
  
  desert = list(
    land = "#EBE1D1", border = "#C5B9A8",
    range = "#D4845A", stroke = "#B8633A",
    focus = "#8A7E6E", context = "#ADA393",
    species = "#B8633A", ocean = "#D6E8F0"
  ),
  savanna = list(
    land = "#E4DDD0", border = "#C5BDB1",
    range = "#C8A856", stroke = "#B8983E",
    focus = "#8A8478", context = "#A8A198",
    species = "#B8983E", ocean = "#D6E8F0"
  ),
  jungle = list(
    land = "#E4DDD0", border = "#C5B9A8",
    range = "#8B6E4E", stroke = "#6B5038",
    focus = "#7A6E62", context = "#ADA393",
    species = "#6B5038", ocean = "#D6E8F0"
  ),
  forest = list(
    land = "#E8E3D8", border = "#C5BDB1",
    range = "#7A9E6B", stroke = "#5C7D4E",
    focus = "#7A7E6E", context = "#ADA898",
    species = "#5C7D4E", ocean = "#D6E8F0"
  ),
  mountain = list(
    land = "#E6E0D5", border = "#C2BAB0",
    range = "#8C7B6B", stroke = "#6B5D50",
    focus = "#7A7268", context = "#ADA59B",
    species = "#6B5D50", ocean = "#D6E8F0"
  ),
  ocean = list(
    land = "#E4DDD0", border = "#C5B9A8",
    range = "#5B8FA8", stroke = "#3D6E85",
    focus = "#7A7E82", context = "#ADA8A3",
    species = "#3D6E85", ocean = "#D0E4EE"
  )
)


# ============================================
# HELPERS
# ============================================

space_text <- function(text, spaces = 1) {
  sapply(text, function(t) {
    if (is.na(t)) return(NA_character_)
    paste(strsplit(toupper(t), "")[[1]],
          collapse = paste(rep(" ", spaces), collapse = ""))
  })
}

auto_extent <- function(species_sf, buffer_deg = 8) {
  bbox <- st_bbox(species_sf)
  list(
    xmin = unname(floor(bbox["xmin"] - buffer_deg)),
    xmax = unname(ceiling(bbox["xmax"] + buffer_deg)),
    ymin = unname(floor(bbox["ymin"] - buffer_deg)),
    ymax = unname(ceiling(bbox["ymax"] + buffer_deg))
  )
}

auto_countries <- function(extent, countries_sf) {
  suppressWarnings(
    countries_sf %>%
      st_make_valid() %>%
      st_crop(
        xmin = extent$xmin,
        xmax = extent$xmax,
        ymin = extent$ymin,
        ymax = extent$ymax
      )
  )
}

auto_continent <- function(extent) {
  cx <- (extent$xmin + extent$xmax) / 2
  cy <- (extent$ymin + extent$ymax) / 2
  if (cx > 25 & cx < 145 & cy > -15 & cy < 55) return("ASIA")
  if (cx > -20 & cx < 55 & cy > -40 & cy < 40) return("AFRICA")
  if (cx > -140 & cx < -30 & cy > 10 & cy < 75) return("NORTH\nAMERICA")
  if (cx > -90 & cx < -30 & cy > -60 & cy < 15) return("SOUTH\nAMERICA")
  if (cx > -15 & cx < 45 & cy > 35 & cy < 72) return("EUROPE")
  if (cx > 100 & cx < 180 & cy > -50 & cy < 0) return("OCEANIA")
  return("WORLD")
}

auto_labels <- function(countries_in_view, species_sf) {
  
  # Clean geometries
  countries_clean <- countries_in_view %>%
    st_make_valid()
  
  # Drop empty, invalid, and unnamed
  keep <- !st_is_empty(countries_clean) & st_is_valid(countries_clean)
  countries_clean <- countries_clean[keep, ]
  countries_clean <- countries_clean %>%
    filter(!is.na(name))
  
  # Early return if nothing left
  if (nrow(countries_clean) == 0) {
    return(list(
      focus   = tibble(X = numeric(), Y = numeric(), label = character()),
      context = tibble(X = numeric(), Y = numeric(), label = character())
    ))
  }
  
  # Centroids
  centroids <- suppressWarnings(st_centroid(countries_clean))
  coords <- st_coordinates(centroids)
  
  countries_clean$X_ctr <- coords[, 1]
  countries_clean$Y_ctr <- coords[, 2]
  
  # Drop NA coordinates
  countries_clean <- countries_clean %>%
    filter(!is.na(X_ctr), !is.na(Y_ctr))
  
  if (nrow(countries_clean) == 0) {
    return(list(
      focus   = tibble(X = numeric(), Y = numeric(), label = character()),
      context = tibble(X = numeric(), Y = numeric(), label = character())
    ))
  }
  
  # Which countries overlap the range
  intersects <- suppressWarnings(
    st_intersects(countries_clean, species_sf, sparse = FALSE)
  )
  countries_clean$in_range <- apply(intersects, 1, any)
  
  # Split into focus and context
  focus <- countries_clean %>%
    filter(in_range) %>%
    as_tibble() %>%
    transmute(X = X_ctr, Y = Y_ctr, label = space_text(name))
  
  context <- countries_clean %>%
    filter(!in_range) %>%
    as_tibble() %>%
    transmute(X = X_ctr, Y = Y_ctr, label = space_text(name))
  
  list(focus = focus, context = context)
}

auto_scale_bar <- function(extent, miles = 500) {
  center_lat <- (extent$ymin + extent$ymax) / 2
  km <- round(miles * 1.609)
  km_per_deg <- 111.32 * cos(center_lat * pi / 180)
  deg_per_mi <- miles / (km_per_deg / 1.609)
  deg_per_km <- km / km_per_deg
  list(
    x = extent$xmin + 2,
    y_mi = extent$ymin + 3,
    y_km = extent$ymin + 1.8,
    miles = miles, km = km,
    deg_per_mi = deg_per_mi,
    deg_per_km = deg_per_km
  )
}


# ============================================
# BUILD SPECIES MAP
# ============================================

build_species_map <- function(
    common_name,
    scientific_name,
    shapefile_path,
    photo_path      = NULL,
    photo_credit    = "",
    palette_type    = "jungle",
    output_path     = NULL,
    data_source     = "Source: IUCN Red List of Threatened Species",
    map_author      = "Map by Brooks Groves"
) {
  
  message(strrep("=", 54))
  message("  Building: ", common_name)
  message(strrep("=", 54))
  
  # ── Load data ──────────────────────────────
  species   <- st_read(shapefile_path, quiet = TRUE)
  countries <- ne_countries(scale = "medium", returnclass = "sf")
  
  pal <- palettes[[palette_type]]
  if (is.null(pal)) {
    warning("Unknown palette '", palette_type, "', using jungle")
    pal <- palettes$jungle
  }
  
  # ── Auto-detect everything ─────────────────
  extent    <- auto_extent(species)
  land      <- auto_countries(extent, countries)
  labels    <- auto_labels(land, species)
  sb        <- auto_scale_bar(extent)
  continent <- auto_continent(extent)
  
  message("  Extent: ", extent$xmin, " to ", extent$xmax,
          " lon | ", extent$ymin, " to ", extent$ymax, " lat")
  message("  Countries: ", nrow(land))
  message("  Focus labels: ", nrow(labels$focus))
  message("  Context labels: ", nrow(labels$context))
  message("  Continent: ", gsub("\n", " ", continent))
  
  # Species label in bottom-left of map
  label_x <- extent$xmin + 1.5
  label_y <- extent$ymin + (extent$ymax - extent$ymin) * 0.28
  
  # ── Main map ───────────────────────────────
  main_map <- ggplot() +
    geom_sf(data = land,
            fill = pal$land,
            color = pal$border,
            linewidth = 0.15) +
    geom_sf(data = species,
            fill = pal$range,
            color = pal$stroke,
            alpha = 0.85,
            linewidth = 0.3)
  
  # Add labels only if we have them
  if (nrow(labels$focus) > 0) {
    main_map <- main_map +
      geom_text(data = labels$focus,
                aes(x = X, y = Y, label = label),
                color = pal$focus, size = 3.0)
  }
  
  if (nrow(labels$context) > 0) {
    main_map <- main_map +
      geom_text(data = labels$context,
                aes(x = X, y = Y, label = label),
                color = pal$context, size = 2.3,
                lineheight = 0.8)
  }
  
  main_map <- main_map +
    # Species name annotation
    annotate("text", x = label_x, y = label_y,
             label = paste(common_name, "range"),
             color = pal$species, size = 3.0,
             hjust = 0, fontface = "bold") +
    annotate("text", x = label_x + 0.2, y = label_y - 1.5,
             label = scientific_name,
             color = pal$species, size = 2.6,
             hjust = 0, fontface = "italic") +
    
    # Scale bars
    annotate("segment",
             x = sb$x, xend = sb$x + sb$deg_per_mi,
             y = sb$y_mi, yend = sb$y_mi,
             color = "#666666", linewidth = 0.4) +
    annotate("text",
             x = sb$x, y = sb$y_mi + 0.55,
             label = paste(sb$miles, "mi"),
             color = "#666666", size = 2.1, hjust = 0) +
    annotate("segment",
             x = sb$x, xend = sb$x + sb$deg_per_km,
             y = sb$y_km, yend = sb$y_km,
             color = "#666666", linewidth = 0.4) +
    annotate("text",
             x = sb$x, y = sb$y_km + 0.55,
             label = paste(sb$km, "km"),
             color = "#666666", size = 2.1, hjust = 0) +
    
    # Map extent and theme
    coord_sf(xlim = c(extent$xmin, extent$xmax),
             ylim = c(extent$ymin, extent$ymax),
             expand = FALSE) +
    theme_void() +
    theme(
      panel.background = element_rect(fill = pal$ocean, color = NA),
      plot.background  = element_rect(fill = pal$ocean, color = NA),
      plot.margin = margin(0, 0, 0, 0)
    )
  
  message("  ✓ Main map")
  
  # ── Locator inset ──────────────────────────
  world_inset <- ne_countries(scale = "small", returnclass = "sf")
  inset_xmin <- 0;    inset_xmax <- 160
  inset_ymin <- -60;   inset_ymax <- 72
  
  locator_box <- st_sf(geometry = st_sfc(
    st_polygon(list(matrix(c(
      extent$xmin, extent$ymin,
      extent$xmax, extent$ymin,
      extent$xmax, extent$ymax,
      extent$xmin, extent$ymax,
      extent$xmin, extent$ymin
    ), ncol = 2, byrow = TRUE))),
    crs = 4326
  ))
  
  box_cx <- (extent$xmin + extent$xmax) / 2
  box_cy <- (extent$ymin + extent$ymax) / 2
  
  locator_inset <- ggplot() +
    geom_rect(aes(xmin = inset_xmin, xmax = inset_xmax,
                  ymin = inset_ymin, ymax = inset_ymax),
              fill = "#C8DAE5") +
    geom_sf(data = world_inset,
            fill = "#D5CFC3",
            color = "#B8B0A4",
            linewidth = 0.08) +
    geom_sf(data = locator_box,
            fill = pal$range,
            color = pal$stroke,
            alpha = 0.45,
            linewidth = 0.7) +
    annotate("text", x = box_cx, y = box_cy,
             label = "MAP\nAREA", color = "white",
             size = 1.85, fontface = "bold",
             lineheight = 0.85) +
    annotate("text", x = 80, y = 63,
             label = continent, color = "#5A8A9A",
             size = 2.3, fontface = "bold") +
    coord_sf(xlim = c(inset_xmin, inset_xmax),
             ylim = c(inset_ymin, inset_ymax),
             expand = FALSE) +
    theme_void() +
    theme(
      panel.background = element_rect(fill = "#C8DAE5",
                                      color = "#7A9EAD",
                                      linewidth = 0.7),
      plot.background = element_rect(fill = "transparent",
                                     color = NA),
      plot.margin = margin(0, 0, 0, 0)
    )
  
  message("  ✓ Locator inset")
  
  # ── Photo ──────────────────────────────────
  has_photo <- !is.null(photo_path) && file.exists(photo_path)
  if (has_photo) {
    img <- image_read(photo_path)
    photo_grob <- rasterGrob(as.raster(img), interpolate = TRUE)
    message("  ✓ Photo loaded")
  } else {
    message("  ⊘ No photo (", 
            if (is.null(photo_path)) "path is NULL" else "file not found",
            ")")
  }
  
  # ── Page layout math ──────────────────────
  page_w_mm  <- 240
  col_l_frac <- 0.75
  col_r_frac <- 0.25
  col_l_mm   <- page_w_mm * col_l_frac
  col_r_mm   <- page_w_mm * col_r_frac
  
  map_lat  <- extent$ymax - extent$ymin
  map_lon  <- extent$xmax - extent$xmin
  map_h_mm <- col_l_mm * (map_lat / map_lon)
  
  title_mm  <- 28
  attrib_mm <- 16
  page_h_mm <- map_h_mm + title_mm + attrib_mm
  
  inset_geo_asp <- (inset_ymax - inset_ymin) / (inset_xmax - inset_xmin)
  inset_h_mm    <- col_r_mm * inset_geo_asp
  photo_h_mm    <- map_h_mm - inset_h_mm
  
  # Convert to 0-1 canvas proportions
  attrib_p  <- attrib_mm / page_h_mm
  map_h_p   <- map_h_mm / page_h_mm
  title_p   <- title_mm / page_h_mm
  col_l_p   <- col_l_frac
  col_r_p   <- col_r_frac
  inset_h_p <- inset_h_mm / page_h_mm
  photo_h_p <- photo_h_mm / page_h_mm
  
  map_y     <- attrib_p
  title_y   <- attrib_p + map_h_p
  inset_y   <- attrib_p + map_h_p - inset_h_p
  photo_y   <- attrib_p
  col_r_x   <- col_l_p + 0.008
  col_r_use <- col_r_p - 0.010
  
  message("  Page: ", round(page_w_mm), " x ",
          round(page_h_mm, 1), " mm")
  
  # ── Compose final layout ───────────────────
  sci_label <- bquote(italic(.(scientific_name)))
  
  final_map <- ggdraw() +
    
    # White page background
    draw_grob(grid::rectGrob(
      gp = grid::gpar(fill = "white", col = NA)
    )) +
    
    # Column divider line
    draw_grob(grid::linesGrob(
      x = unit(c(col_l_p + 0.003, col_l_p + 0.003), "npc"),
      y = unit(c(attrib_p, attrib_p + map_h_p), "npc"),
      gp = grid::gpar(col = pal$border, lwd = 0.8)
    )) +
    
    # Main map
    draw_plot(main_map,
              x = 0, y = map_y,
              width = col_l_p, height = map_h_p) +
    
    # Locator inset
    draw_plot(locator_inset,
              x = col_r_x, y = inset_y,
              width = col_r_use, height = inset_h_p) +
    
    # Title
    draw_label(common_name,
               x = 0.5, y = title_y + title_p * 0.67,
               size = 28, fontface = "bold",
               color = "#2B2B2B", hjust = 0.5) +
    
    # Scientific name
    draw_label(sci_label,
               x = 0.5, y = title_y + title_p * 0.24,
               size = 16, color = "#888888",
               hjust = 0.5) +
    
    # Attribution
    draw_label(data_source,
               x = 0.02, y = attrib_p * 0.65,
               size = 6, color = "#AAAAAA", hjust = 0) +
    
    draw_label(map_author,
               x = 0.02, y = attrib_p * 0.28,
               size = 6, color = "#AAAAAA", hjust = 0)
  
  # Add photo if available
  if (has_photo) {
    final_map <- final_map +
      draw_grob(photo_grob,
                x = col_r_x,
                y = photo_y + 0.022,
                width = col_r_use,
                height = photo_h_p - 0.022) +
      draw_label(paste("Photo:", photo_credit),
                 x = col_r_x, y = photo_y + 0.010,
                 size = 4.8, color = "#AAAAAA",
                 hjust = 0, fontface = "italic")
  }
  
  message("  ✓ Composed")
  
  # ── Export ─────────────────────────────────
  if (is.null(output_path)) {
    slug <- gsub(" ", "_", tolower(common_name))
    output_path <- paste0("outputs/", slug, "_natgeo.png")
  }
  
  dir.create(dirname(output_path),
             showWarnings = FALSE, recursive = TRUE)
  
  ggsave(output_path, final_map,
         width = page_w_mm, height = page_h_mm,
         units = "mm", dpi = 300, bg = "white")
  
  message("  ✓ Exported: ", output_path)
  message(strrep("=", 54))
  
  invisible(final_map)
}


# ============================================
# BATCH QUEUE RUNNER
# ============================================

run_queue <- function(
    queue_path = "data/species_queue.csv",
    force_rebuild = FALSE
) {
  queue <- read_csv(queue_path, show_col_types = FALSE)
  
  message("\n", strrep("=", 54))
  message("  Species Map Queue: ", nrow(queue), " species")
  message(strrep("=", 54), "\n")
  
  for (i in seq_len(nrow(queue))) {
    row <- queue[i, ]
    slug <- gsub(" ", "_", tolower(row$common_name))
    out <- paste0("outputs/", slug, "_natgeo.png")
    
    if (file.exists(out) && !force_rebuild) {
      message("[", i, "/", nrow(queue), "] ",
              row$common_name, " already built, skipping")
      next
    }
    
    message("\n[", i, "/", nrow(queue), "] Building: ",
            row$common_name)
    
    tryCatch({
      build_species_map(
        common_name     = row$common_name,
        scientific_name = row$scientific_name,
        shapefile_path  = row$shapefile_path,
        photo_path      = if (!is.na(row$photo_path)) row$photo_path else NULL,
        photo_credit    = if (!is.na(row$photo_credit)) row$photo_credit else "",
        palette_type    = row$palette_type,
        output_path     = out
      )
    },
    error = function(e) {
      message("  FAILED: ", conditionMessage(e))
    })
  }
  
  message("\n", strrep("=", 54))
  message("  Queue complete!")
  message(strrep("=", 54), "\n")
}