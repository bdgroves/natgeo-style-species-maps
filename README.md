# NatGeo Style Species Maps 🗺️

Recreating the National Geographic editorial map style
using open source tools. A cartography learning project.

## Maps in the Series

| # | Species | Region | Tool | Status |
|---|---------|--------|------|--------|
| 1 | Namibian Wolf Snake 🐍 | Southern Africa | QGIS | ✅ |
| 2 | Great Basin Bristlecone Pine 🌲 | Western USA | QGIS | ✅ |
| 3 | Gila Monster 🦎 | Southwest USA / Mexico | R | ✅ |
| 4 | Dhole (Asian Wild Dog) 🐕 | South & Southeast Asia | R | ✅ |

## Gallery

### Dhole — *Cuon alpinus*
![Dhole](outputs/dhole_natgeo.png)
> Endangered. Range spans India through Southeast Asia
> to the Indonesian archipelago. IUCN Status: EN C2a(i)

### Gila Monster — *Heloderma suspectum*
![Gila Monster](outputs/gila_monster_natgeo.png)
> Near Threatened. Sonoran and Chihuahuan Desert regions
> of the American Southwest and northern Mexico.

### Namibian Wolf Snake — *Lycophidion namibianum*
![Wolf Snake](outputs/wolf_snake_natgeo.png)
> Data Deficient. Endemic to Angola and Namibia
> in southern Africa.

### Great Basin Bristlecone Pine — *Pinus longaeva*
![Bristlecone Pine](outputs/bristlecone_pine_natgeo.png)
> Vulnerable. Among the oldest living organisms on Earth.
> High-elevation Great Basin ranges of the western USA.

---

## The NatGeo Style

Key design elements recreated from National Geographic
editorial species range maps:

| Element | Implementation |
|---------|---------------|
| Warm parchment land | `#E4DDD0` — `#EBE1D1` depending on region |
| Soft blue ocean | `#D6E8F0` as panel background |
| Spaced uppercase labels | Custom `space_text()` function |
| Muted range color | Species-specific earth tone |
| Locator inset | Flat WGS-84 regional context map |
| Dual scale bars | Miles + km, manual degree conversion |
| Species annotation | Bold common name + italic scientific name |
| Animal photo | Right column below locator inset |
| Typography | ggplot2 default (Helvetica-style sans-serif) |
| Attribution footer | Source + author at 6pt |

---

## Color Palettes

| Species | Range Color | Hex | Region Feel |
|---------|-------------|-----|-------------|
| Gila Monster | Terracotta | `#D4845A` | Desert Southwest |
| Namibian Wolf Snake | Golden Ochre | `#C8A856` | African savanna |
| Bristlecone Pine | Sage Green | `#7A9E6B` | Mountain forest |
| Dhole | Jungle Earth Brown | `#8B6E4E` | Tropical Asia |

---

## Lessons Learned

### Orthographic Globe Insets
The original design used an orthographic globe inset
(like real NatGeo maps). This works well for Africa and
North America but causes GEOS geometry errors for
Asia-centered projections:
IllegalArgumentException: Invalid number of points
in LinearRing found 2 - must be 0 or >= 4
Copy
**Root cause:** Country polygons crossing the orthographic
hemisphere boundary are clipped into 2–3 point slivers —
invalid LinearRings. ggplot2 defers geometry processing
to render time, so `suppressWarnings()` does not help.

**Solution adopted:** Replaced the orthographic globe with
a flat WGS-84 regional locator inset. Visually equivalent,
zero projection math, no crashes. Many real NatGeo maps
use this approach anyway.

### Asia Map Layout Challenges
- Large polygon countries (Russia, Kazakhstan, China)
  cause memory issues with `st_segmentize()` at fine
  resolution — use `scale = "small"` for inset world data
- `sf_use_s2(FALSE)` must be set before any spatial ops
  when using orthographic projections
- Page height must be calculated from map aspect ratio —
  guessing produces large white gaps

### R vs QGIS for This Style
| Task | R | QGIS |
|------|---|------|
| Scripted / reproducible | ✅ | ❌ |
| Fine label placement | Harder | Easier |
| Globe inset | Fragile | Stable |
| Batch species | ✅ | Manual |
| Photo inset | ✅ magick | Manual |

---

## Project Structure
natgeo-style-species-maps/
│
├── R/
│   ├── dhole.R                    # Dhole range map
│   └── gila_monster.R             # Gila Monster range map
│
├── QGIS/
│   ├── wolf_snake.qgz             # Namibian Wolf Snake project
│   └── bristlecone_pine.qgz       # Bristlecone Pine project
│
├── data/
│   └── Cuon.alpinus-cut.jpg       # Dhole photo (Wikimedia CC BY-SA 4.0)
│
├── outputs/
│   ├── dhole_natgeo.png
│   ├── gila_monster_natgeo.png
│   ├── wolf_snake_natgeo.png
│   └── bristlecone_pine_natgeo.png
│
└── README.md
Copy
> **Note:** Species shapefiles from IUCN Red List are not
> included in this repository. Download from
> https://www.iucnredlist.org (free account required).

---

## Data Sources

| Data | Source | License |
|------|--------|---------|
| Species ranges | [IUCN Red List](https://www.iucnredlist.org) | Free, not redistributable |
| Base maps | [Natural Earth](https://www.naturalearthdata.com) | Public domain |
| Occurrence points | [GBIF](https://www.gbif.org) | CC BY 4.0 |
| Dhole photo | [Davidvraju / Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Cuon_alpinus.jpg) | CC BY-SA 4.0 |

---

## R Package Dependencies

```r
install.packages(c(
  "tidyverse",          # data wrangling
  "sf",                 # spatial data handling
  "rnaturalearth",      # Natural Earth base maps
  "rnaturalearthdata",  # Natural Earth data files
  "cowplot",            # map composition
  "magick"              # animal photo inset
))

How to Reproduce
Dhole Map (R)
rCopy# 1. Download Dhole range shapefile from IUCN Red List
#    https://www.iucnredlist.org/species/18533/549084
#    Save to: data/Shapefiles/IUCN/dhole/data_0.shp

# 2. Add animal photo to:
#    data/Cuon.alpinus-cut.jpg

# 3. Run:
source("R/dhole.R")
Gila Monster Map (R)
rCopy# 1. Download range shapefile from IUCN Red List
#    Save to: data/Shapefiles/IUCN/gila_monster/data_0.shp

# 2. Run:
source("R/gila_monster.R")
QGIS Maps
Open the .qgz project files in QGIS 3.x.
Data layers use relative paths — place shapefiles
in the same directory structure as the project.

Next Species
Possible additions to the series:
SpeciesRegionInterestSnow Leopard 🐆Central AsiaRange overlaps DholeIrrawaddy Dolphin 🐬SE Asia riversFreshwater range mapKakapo 🦜New ZealandIsland endemicEthiopian Wolf 🐺Horn of AfricaAfrica seriesSunda Pangolin 🦔SE AsiaCritically Endangered

A personal cartography project by Brooks Groves.
Maps produced with open source tools — R and QGIS.
Add to Conversation