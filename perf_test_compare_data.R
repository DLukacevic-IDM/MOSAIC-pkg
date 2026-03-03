################################################################################
# Data comparison: output of download_climate_data old vs new
# Reads parquets from climate_perf_old/ and climate_perf_new/ written by
# perf_test_climate_download.R and checks they contain equivalent data.
################################################################################

library(MOSAIC)
devtools::load_all()

set_root_directory("~/git/cholera-prj/MOSAIC")
PATHS <- MOSAIC::get_paths()

dir_old <- file.path(PATHS$DATA_RAW, "climate_perf_old", "climate")
dir_new <- file.path(PATHS$DATA_RAW, "climate_perf_new", "climate")

files_old <- list.files(dir_old, pattern = "\\.parquet$")
files_new <- list.files(dir_new, pattern = "\\.parquet$")

cat(glue::glue("Old files: {length(files_old)}  |  New files: {length(files_new)}\n\n"))

# ── Match files by name (identical naming convention in both) ─────────────────
only_old  <- setdiff(files_old, files_new)
only_new  <- setdiff(files_new, files_old)
common    <- intersect(files_old, files_new)

if (length(only_old) > 0) cat("Only in OLD:\n", paste(" ", only_old, collapse="\n"), "\n\n")
if (length(only_new) > 0) cat("Only in NEW:\n", paste(" ", only_new, collapse="\n"), "\n\n")
cat(glue::glue("Matched files to compare: {length(common)}\n\n"))

# ── Per-file comparison ───────────────────────────────────────────────────────
results <- lapply(common, function(fname) {

     old <- arrow::read_parquet(file.path(dir_old, fname))
     new <- arrow::read_parquet(file.path(dir_new, fname))

     # Sort both by date + lat + lon for a consistent comparison
     key_cols <- c("date", "latitude", "longitude")
     old <- old[do.call(order, old[key_cols]), ]
     new <- new[do.call(order, new[key_cols]), ]

     rows_match   <- nrow(old) == nrow(new)
     dates_match  <- identical(sort(unique(old$date)),  sort(unique(new$date)))
     locs_match   <- nrow(old) == nrow(new) &&
                     all(abs(sort(old$latitude)  - sort(new$latitude))  < 1e-4) &&
                     all(abs(sort(old$longitude) - sort(new$longitude)) < 1e-4)

     # Value correlation (only meaningful when row counts match)
     value_cor  <- NA_real_
     value_rmse <- NA_real_
     max_diff   <- NA_real_

     if (rows_match) {
          diffs      <- old$value - new$value
          value_cor  <- cor(old$value, new$value, use = "complete.obs")
          value_rmse <- sqrt(mean(diffs^2, na.rm = TRUE))
          max_diff   <- max(abs(diffs), na.rm = TRUE)
     }

     list(
          file       = fname,
          rows_old   = nrow(old),
          rows_new   = nrow(new),
          rows_match = rows_match,
          dates_match = dates_match,
          locs_match  = locs_match,
          value_cor   = value_cor,
          value_rmse  = value_rmse,
          max_diff    = max_diff,
          mean_old    = mean(old$value, na.rm = TRUE),
          mean_new    = mean(new$value, na.rm = TRUE)
     )
})

results_df <- do.call(rbind.data.frame, results)

# ── Print summary ─────────────────────────────────────────────────────────────
cat("=== Per-file comparison ===\n")
print(results_df[, c("file","rows_old","rows_new","rows_match","dates_match","locs_match",
                      "value_cor","value_rmse","max_diff")],
      row.names = FALSE, digits = 4)

n_pass <- sum(results_df$rows_match & results_df$dates_match & results_df$value_cor > 0.999,
              na.rm = TRUE)
cat(glue::glue("\n\nFiles fully equivalent (cor > 0.999): {n_pass} / {length(common)}\n"))

# ── Write markdown report ─────────────────────────────────────────────────────
report_path <- file.path(dirname(PATHS$ROOT), "MOSAIC", "MOSAIC-pkg", "perf_test_results.md")
existing    <- readLines(report_path)

table_rows <- apply(results_df, 1, function(r) {
     glue::glue("| {basename(r['file'])} | {r['rows_old']} | {r['rows_new']} | {r['rows_match']} | {r['dates_match']} | {round(as.numeric(r['value_cor']), 5)} | {round(as.numeric(r['value_rmse']), 4)} | {round(as.numeric(r['max_diff']), 4)} |")
})

section <- c(
     "",
     "## Data Equivalence Check",
     glue::glue(""),
     glue::glue("Compared {length(common)} matched parquet files. Files only in old: {length(only_old)}. Only in new: {length(only_new)}."),
     "",
     "| File | Rows old | Rows new | Rows match | Dates match | Value cor | RMSE | Max diff |",
     "|---|---|---|---|---|---|---|---|",
     table_rows,
     "",
     glue::glue("**Files fully equivalent (cor > 0.999): {n_pass} / {length(common)}**"),
     "",
     "> Note: coordinates may differ slightly (old uses API-returned snapped coords;",
     "> new uses request coords). Values should be identical for matched locations.",
     glue::glue(""),
     glue::glue("_Updated: {format(Sys.time(), '%Y-%m-%d %H:%M:%S')}_")
)

# Remove any previous equivalence section before appending
cut <- which(grepl("^## Data Equivalence Check", existing))
base <- if (length(cut) > 0) existing[seq_len(cut[1] - 1)] else existing

writeLines(c(base, section), report_path)
cat(glue::glue("\nReport updated: {report_path}\n"))
