setwd("C:/data/R_Projects/natgeo-style-species-maps")
source("R/auto/add_species.R")

# ── Ethiopian Wolf ───────────────────────────
add_species(
  common_name       = "Ethiopian Wolf",
  scientific_name   = "Canis simensis",
  zip_path          = "C:/data/Shapefiles/IUCN/redlist_species_data_447af4f8-cf47-4ead-ba21-9550ecdc0c17.zip",
  photo_path_source = "C:/data/Shapefiles/IUCN/500px-Ethiopian_wolf_(Canis_simensis_citernii).jpg",
  photo_credit      = "Charles J. Sharp / Sharp Photography / CC BY-SA 4.0",
  palette_type      = "savanna",
  continent         = "Africa",
  iucn_status       = "Endangered"
)

# ── Red Panda ────────────────────────────────
add_species(
  common_name       = "Red Panda",
  scientific_name   = "Ailurus fulgens",
  zip_path          = "C:/data/Shapefiles/IUCN/redlist_species_data_a5c2d9cd-b997-4bbb-9dfb-6b25c20973b1.zip",
  photo_path_source = "C:/data/Shapefiles/IUCN/500px-Red_Panda,_Gentle_Tree-Dweller_of_the_Himalayas.jpg",
  photo_credit      = "Sunuwargr / Wikimedia Commons / CC BY-SA 4.0",
  palette_type      = "forest",
  continent         = "Asia",
  iucn_status       = "Endangered"
)

# ── Kakapo ───────────────────────────────────
add_species(
  common_name       = "Kakapo",
  scientific_name   = "Strigops habroptila",
  zip_path          = "C:/data/Shapefiles/IUCN/redlist_species_data_27050ba6-770a-4e4c-9bab-35e405a59630.zip",
  photo_path_source = "C:/data/Shapefiles/IUCN/Sirocco_full_length_portrait.jpg",
  photo_credit      = "Department of Conservation NZ / Flickr / CC BY 2.0",
  palette_type      = "forest",
  continent         = "Oceania",
  iucn_status       = "Critically Endangered"
)

# ── Verify queue ─────────────────────────────
queue <- read_csv("data/species_queue.csv", show_col_types = FALSE)
message("\n✓ Queue has ", nrow(queue), " species:")
for (i in seq_len(nrow(queue))) {
  message("  ", i, ". ", queue$common_name[i], 
          " (", queue$palette_type[i], ")")
}

# ── Build all new maps ───────────────────────
source("R/auto/generate_map.R")
run_queue()