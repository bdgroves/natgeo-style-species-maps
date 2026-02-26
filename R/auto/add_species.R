# ============================================
# add_species.R
# Quick-add a species to the pipeline
#
# Usage:
#   source("R/auto/add_species.R")
#   add_species(
#     common_name = "Snow Leopard",
#     scientific_name = "Panthera uncia",
#     zip_path = "C:/data/Shapefiles/IUCN/redlist_blahblah.zip",
#     photo_path_source = "C:/Users/me/Downloads/snow_leopard.jpg",
#     photo_credit = "Someone / Wikimedia / CC BY-SA 4.0",
#     palette_type = "mountain",
#     continent = "Asia",
#     iucn_status = "Vulnerable"
#   )
# ============================================

library(tidyverse)
library(sf)

add_species <- function(
    common_name,
    scientific_name,
    zip_path,
    photo_path_source = NULL,
    photo_credit      = "",
    palette_type      = "jungle",
    continent         = "",
    iucn_status       = "",
    project_root      = "C:/data/R_Projects/natgeo-style-species-maps",
    shapefile_root    = "C:/data/Shapefiles/IUCN"
) {
  
  # ── Slug for folder names ──────────────────
  slug <- gsub(" ", "_", tolower(common_name))
  
  message(strrep("=", 50))
  message("  Adding: ", common_name, " (", scientific_name, ")")
  message(strrep("=", 50))
  
  # ── 1. Unzip shapefile ─────────────────────
  shp_dir <- file.path(shapefile_root, slug)
  dir.create(shp_dir, recursive = TRUE, showWarnings = FALSE)
  
  message("  Unzipping to: ", shp_dir)
  unzip(zip_path, exdir = shp_dir)
  
  # Find the .shp file wherever it landed
  shp_file <- list.files(shp_dir, pattern = "\\.shp$",
                         recursive = TRUE, full.names = TRUE)
  
  if (length(shp_file) == 0) {
    stop("No .shp file found in: ", shp_dir)
  }
  
  shp_file <- shp_file[1]
  message("  ✓ Shapefile: ", basename(shp_file))
  
  # ── 2. Verify it loads ─────────────────────
  sf_use_s2(FALSE)
  test <- st_read(shp_file, quiet = TRUE)
  bbox <- st_bbox(test)
  message("  ✓ Loaded: ", nrow(test), " features")
  message("    Extent: ",
          round(bbox["xmin"], 1), "° to ",
          round(bbox["xmax"], 1), "° lon | ",
          round(bbox["ymin"], 1), "° to ",
          round(bbox["ymax"], 1), "° lat")
  
  # ── 3. Copy photo ──────────────────────────
  photo_dest <- ""
  if (!is.null(photo_path_source) && file.exists(photo_path_source)) {
    photo_dir <- file.path(project_root, "data", "photos")
    dir.create(photo_dir, recursive = TRUE, showWarnings = FALSE)
    
    # Get extension from source file
    ext <- tools::file_ext(photo_path_source)
    photo_dest <- file.path("data", "photos",
                            paste0(slug, ".", ext))
    photo_full <- file.path(project_root, photo_dest)
    
    file.copy(photo_path_source, photo_full, overwrite = TRUE)
    message("  ✓ Photo: ", photo_dest)
  } else {
    message("  ⊘ No photo provided")
  }
  
  # ── 4. Add to queue CSV ────────────────────
  queue_path <- file.path(project_root, "data", "species_queue.csv")
  
  if (file.exists(queue_path)) {
    queue <- read_csv(queue_path, show_col_types = FALSE)
  } else {
    queue <- tibble(
      common_name = character(),
      scientific_name = character(),
      shapefile_path = character(),
      photo_path = character(),
      photo_credit = character(),
      palette_type = character(),
      continent = character(),
      iucn_status = character()
    )
  }
  
  # Check for duplicates
  if (common_name %in% queue$common_name) {
    message("  ⚠ Already in queue — updating row")
    queue <- queue %>% filter(common_name != !!common_name)
  }
  
  new_row <- tibble(
    common_name     = common_name,
    scientific_name = scientific_name,
    shapefile_path  = shp_file,
    photo_path      = photo_dest,
    photo_credit    = photo_credit,
    palette_type    = palette_type,
    continent       = continent,
    iucn_status     = iucn_status
  )
  
  queue <- bind_rows(queue, new_row)
  write_csv(queue, queue_path)
  
  message("  ✓ Queue: ", nrow(queue), " species total")
  
  # ── 5. Summary ─────────────────────────────
  message("\n  Ready to build:")
  message("    source(\"R/auto/generate_map.R\")")
  message("    run_queue()")
  message(strrep("=", 50))
  
  invisible(list(
    shapefile = shp_file,
    photo     = photo_dest,
    queue     = queue
  ))
}


# ============================================
# BATCH ADD — add multiple species at once
# from a list
# ============================================

batch_add <- function(species_list) {
  for (sp in species_list) {
    tryCatch(
      do.call(add_species, sp),
      error = function(e) {
        message("  ✗ FAILED: ", sp$common_name,
                " — ", conditionMessage(e))
      }
    )
  }
}