################################################################################
# Visualize grid coordinate differences between old and new download_climate_data
#
# Old code: generate_country_grid_n called once per variable → 17 different
#           random grids per country per run
# New code: generate_country_grid_n called once per country → same grid for
#           all 17 variables
#
# Produces: perf_test_coords_viz.png
################################################################################

library(MOSAIC)
library(ggplot2)
library(sf)
devtools::load_all()

set_root_directory("~/git/cholera-prj/MOSAIC")
PATHS <- MOSAIC::get_paths()

dir_old <- file.path(PATHS$DATA_RAW, "climate_perf_old", "climate")
dir_new <- file.path(PATHS$DATA_RAW, "climate_perf_new", "climate")

COUNTRIES <- c("AGO", "BDI", "BEN", "BFA", "BWA")

# ── Extract unique lat/lon per variable per country ───────────────────────────
extract_coords <- function(dir, source_label) {
     files <- list.files(dir, pattern = "\\.parquet$", full.names = TRUE)
     do.call(rbind, lapply(files, function(f) {
          df  <- arrow::read_parquet(f, col_select = c("latitude", "longitude",
                                                        "iso_code", "variable_name"))
          pts <- unique(df[, c("iso_code", "variable_name", "latitude", "longitude")])
          pts$source <- source_label
          pts
     }))
}

coords_old <- extract_coords(dir_old, "Old (per-variable grid)")
coords_new <- extract_coords(dir_new, "New (shared grid)")
all_coords <- rbind(coords_old, coords_new)
all_coords$source <- factor(all_coords$source,
                             levels = c("Old (per-variable grid)", "New (shared grid)"))

# ── Load country shapefiles ───────────────────────────────────────────────────
shp_list <- lapply(COUNTRIES, function(iso)
     sf::st_read(file.path(PATHS$DATA_SHAPEFILES, paste0(iso, "_ADM0.shp")), quiet = TRUE))
africa_shp <- do.call(rbind, shp_list)

# ── Plot 1: map — coordinates per variable, faceted old vs new ────────────────
p_map <- ggplot() +
     geom_sf(data = africa_shp, fill = "grey95", color = "grey50", linewidth = 0.4) +
     geom_point(data = all_coords,
                aes(x = longitude, y = latitude, color = variable_name),
                size = 1.8, alpha = 0.75) +
     facet_grid(iso_code ~ source) +
     scale_color_viridis_d(option = "turbo", name = "Variable") +
     theme_minimal(base_size = 10) +
     theme(
          legend.position  = "bottom",
          legend.text      = element_text(size = 7),
          legend.key.size  = unit(0.4, "cm"),
          strip.text       = element_text(face = "bold"),
          panel.grid.minor = element_blank()
     ) +
     guides(color = guide_legend(nrow = 3, override.aes = list(size = 3, alpha = 1))) +
     labs(
          title    = "Grid point coordinates: Old vs New implementation",
          subtitle = "Old: random resample per variable — colours scatter across locations\nNew: same grid for all variables — all colours coincide at identical points",
          x = "Longitude", y = "Latitude"
     )

# ── Plot 2: unique location count per variable ────────────────────────────────
n_locs <- aggregate(
     cbind(n_locs = latitude) ~ source + iso_code + variable_name,
     data    = all_coords,
     FUN     = length
)

p_count <- ggplot(n_locs, aes(x = variable_name, y = n_locs, fill = source)) +
     geom_col(position = position_dodge(width = 0.7), width = 0.65) +
     facet_wrap(~iso_code, nrow = 1) +
     scale_fill_manual(values = c("Old (per-variable grid)" = "#E07B54",
                                   "New (shared grid)"       = "#4C9BE8"),
                        name = NULL) +
     theme_minimal(base_size = 10) +
     theme(
          axis.text.x      = element_text(angle = 45, hjust = 1, size = 7),
          legend.position  = "top",
          strip.text       = element_text(face = "bold"),
          panel.grid.minor = element_blank()
     ) +
     labs(
          title    = "Number of unique grid points per variable",
          subtitle = "Old: varies across variables (different random draws)\nNew: constant across all variables (same grid reused)",
          x = NULL, y = "Unique locations"
     )

# ── Plot 3: coordinate overlap — do old/new agree on point positions? ─────────
# For each country, show old vs new lat/lon clouds side by side
p_scatter <- ggplot(all_coords, aes(x = longitude, y = latitude, color = source)) +
     geom_point(size = 1.4, alpha = 0.5,
                position = position_jitter(width = 0.05, height = 0.05, seed = 42)) +
     facet_wrap(~iso_code, nrow = 1, scales = "free") +
     scale_color_manual(values = c("Old (per-variable grid)" = "#E07B54",
                                    "New (shared grid)"       = "#4C9BE8"),
                         name = NULL) +
     theme_minimal(base_size = 10) +
     theme(
          legend.position  = "top",
          strip.text       = element_text(face = "bold"),
          panel.grid.minor = element_blank()
     ) +
     labs(
          title    = "All coordinates: old (orange) vs new (blue)",
          subtitle = "Old: spread from repeated random sampling — more unique points in total\nNew: compact single sample — all variables share the same N points",
          x = "Longitude", y = "Latitude"
     )

# ── Save ──────────────────────────────────────────────────────────────────────
out_dir <- dirname(PATHS$ROOT)
out_dir <- file.path(out_dir, "MOSAIC", "MOSAIC-pkg")

ggplot2::ggsave(file.path(out_dir, "perf_test_coords_map.png"),
                p_map,   width = 14, height = 18, dpi = 150)
ggplot2::ggsave(file.path(out_dir, "perf_test_coords_count.png"),
                p_count, width = 14, height = 5,  dpi = 150)
ggplot2::ggsave(file.path(out_dir, "perf_test_coords_scatter.png"),
                p_scatter, width = 14, height = 5, dpi = 150)

cat("Saved:\n  perf_test_coords_map.png\n  perf_test_coords_count.png\n  perf_test_coords_scatter.png\n")
