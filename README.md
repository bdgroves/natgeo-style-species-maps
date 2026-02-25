# NatGeo Style Species Maps 🗺️

Recreating the National Geographic editorial map style 
using open source tools. A cartography learning project.

## Maps in the Series

| # | Species | Tool | Status |
|---|---------|------|--------|
| 1 | Namibian Wolf Snake 🐍 | QGIS | ✅ |
| 2 | Great Basin Bristlecone Pine 🌲 | QGIS | ✅ |
| 3 | Gila Monster 🦎 | R | ✅ |

## Gallery

### Gila Monster
![Gila Monster](outputs/gila_monster_natgeo.png)

### Namibian Wolf Snake  
![Wolf Snake](outputs/wolf_snake_natgeo.png)

### Bristlecone Pine
![Bristlecone](outputs/bristlecone_pine_natgeo.png)

## The NatGeo Style

Key design elements:
- Warm beige land fill
- White or subtle blue ocean
- Spaced uppercase labels
- Muted accent color for species range
- Orthographic globe inset
- Dual scale bars (mi + km)
- Clean sans-serif typography
- Generous white space

## Color Palettes

| Species Type | Color | Hex |
|-------------|-------|-----|
| Reptiles/Desert | Terracotta | `#D4845A` |
| Snakes/Africa | Golden Ochre | `#C8A856` |
| Trees/Forest | Sage Green | `#7A9E6B` |

## Data Sources

- **Species Ranges**: [IUCN Red List](https://www.iucnredlist.org)
  (free account required, not redistributable)
- **Occurrence Points**: [GBIF](https://www.gbif.org)
- **Base Maps**: [Natural Earth](https://www.naturalearthdata.com)
  (public domain)

## Tools

- **R**: ggplot2, sf, cowplot, rnaturalearth, ggspatial
- **QGIS**: Print Layout, rule-based labeling
- **Data Processing**: sf, MASS, smoothr, concaveman

## How to Use

### R Maps
```r
# Install packages
install.packages(c("tidyverse", "sf", "rnaturalearth",
                    "rnaturalearthdata", "cowplot", "ggspatial"))

# Download species data from IUCN Red List
# Place shapefile in data/ directory
# Run script from R/ directory
source("R/01_gila_monster_map.R")