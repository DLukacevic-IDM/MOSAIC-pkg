################################################################################
# Time series comparison: old vs new download_climate_data
#
# For each variable: daily mean ± 1 sd across grid points, per country.
# Old and new have different spatial samples so we compare spatial averages.
# Saves one PNG per variable into local/perf/ts/
################################################################################

library(MOSAIC)
library(ggplot2)
devtools::load_all()

set_root_directory("~/git/cholera-prj/MOSAIC")
PATHS <- MOSAIC::get_paths()

dir_old <- file.path(PATHS$DATA_RAW, "climate_perf_old", "climate")
dir_new <- file.path(PATHS$DATA_RAW, "climate_perf_new", "climate")
out_dir <- file.path(dirname(PATHS$ROOT), "MOSAIC", "MOSAIC-pkg", "local", "perf", "ts")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ── Load and aggregate all parquets to daily mean ± sd per country × variable ─
load_daily <- function(dir, source_label) {
     files <- list.files(dir, pattern = "\\.parquet$", full.names = TRUE)
     chunks <- lapply(files, function(f) {
          df <- arrow::read_parquet(f, col_select = c("date", "iso_code",
                                                       "variable_name", "value"))
          df$date <- as.Date(df$date)
          df
     })
     raw <- do.call(rbind, chunks)

     # Aggregate: mean and sd across grid points per date × country × variable
     agg <- aggregate(value ~ date + iso_code + variable_name, data = raw,
                      FUN = function(x) c(mean = mean(x, na.rm = TRUE),
                                          sd   = sd(x,   na.rm = TRUE)))
     agg <- do.call(data.frame, agg)   # expands the matrix column
     names(agg)[4:5] <- c("mean_val", "sd_val")
     agg$source <- source_label
     agg
}

cat("Loading old parquets...\n")
old <- load_daily(dir_old, "Old")
cat("Loading new parquets...\n")
new <- load_daily(dir_new, "New")
ts  <- rbind(old, new)
ts$source <- factor(ts$source, levels = c("Old", "New"))

COLORS <- c(Old = "#E07B54", New = "#4C9BE8")

variables <- sort(unique(ts$variable_name))
countries <- sort(unique(ts$iso_code))

cat(glue::glue("Plotting {length(variables)} variables × {length(countries)} countries\n\n"))

# ── One PNG per variable ───────────────────────────────────────────────────────
for (v in variables) {

     dat <- ts[ts$variable_name == v, ]

     p <- ggplot(dat, aes(x = date, color = source, fill = source)) +
          geom_ribbon(aes(ymin = mean_val - sd_val,
                          ymax = mean_val + sd_val),
                      alpha = 0.15, color = NA) +
          geom_line(aes(y = mean_val), linewidth = 0.7) +
          facet_wrap(~iso_code, nrow = 1, scales = "free_y") +
          scale_color_manual(values = COLORS, name = NULL) +
          scale_fill_manual( values = COLORS, name = NULL) +
          scale_x_date(date_labels = "%b", date_breaks = "1 month") +
          theme_minimal(base_size = 11) +
          theme(
               legend.position  = "top",
               strip.text       = element_text(face = "bold"),
               panel.grid.minor = element_blank(),
               axis.text.x      = element_text(size = 8)
          ) +
          labs(
               title    = v,
               subtitle = "Daily spatial mean ± 1 SD across grid points  |  Orange = old (per-variable grid)  |  Blue = new (shared grid)",
               x = NULL, y = NULL
          )

     fname <- file.path(out_dir, paste0("ts_", v, ".png"))
     ggplot2::ggsave(fname, p, width = 14, height = 4, dpi = 130)
     cat(glue::glue("  saved: ts/{v}.png\n"))
}

# ── Summary: all variables per country, one PNG each ─────────────────────────
for (cty in countries) {

     p_summary <- ggplot(ts[ts$iso_code == cty, ],
                         aes(x = date, color = source, fill = source)) +
          geom_ribbon(aes(ymin = mean_val - sd_val,
                          ymax = mean_val + sd_val),
                      alpha = 0.15, color = NA) +
          geom_line(aes(y = mean_val), linewidth = 0.6) +
          facet_wrap(~variable_name, scales = "free_y", ncol = 3) +
          scale_color_manual(values = COLORS, name = NULL) +
          scale_fill_manual( values = COLORS, name = NULL) +
          scale_x_date(date_labels = "%b", date_breaks = "1 month") +
          theme_minimal(base_size = 10) +
          theme(
               legend.position  = "top",
               strip.text       = element_text(face = "bold", size = 8),
               panel.grid.minor = element_blank(),
               axis.text.x      = element_text(size = 7),
               axis.text.y      = element_text(size = 7)
          ) +
          labs(
               title    = glue::glue("All variables — {cty}"),
               subtitle = "Daily spatial mean ± 1 SD  |  Orange = old  |  Blue = new",
               x = NULL, y = NULL
          )

     fname <- file.path(out_dir, paste0("ts_summary_", cty, ".png"))
     ggplot2::ggsave(fname, p_summary, width = 14, height = 20, dpi = 130)
     cat(glue::glue("  saved: ts/ts_summary_{cty}.png\n"))
}

cat(glue::glue("\nAll plots in: {out_dir}\n"))
