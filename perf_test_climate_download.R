################################################################################
# Performance comparison: download_climate_data (old vs new)
#
# Old: triple loop (model × country × variable), 1 HTTP request per location
# New: batched (all locations in one request), all variables in one call,
#      parallel across countries (mclapply)
#
# Usage: source this file with PATHS and api_key already set, or run top-to-bottom.
################################################################################

library(MOSAIC)
devtools::load_all()   # loads get_climate_future_old, download_climate_data_old, new variants

set_root_directory("~/git/cholera-prj/MOSAIC")
PATHS <- MOSAIC::get_paths()

set_openmeteo_api_key("free")
# set_openmeteo_api_key("JJjz1zPqFKe27phI")   # uncomment for paid API

# ── Test parameters ────────────────────────────────────────────────────────────
ISO_TEST   <- MOSAIC::iso_codes_africa[1:5]   # 5 countries
N_POINTS   <- 10
DATE_START <- "2023-01-01"
DATE_STOP  <- "2023-03-31"                    # 90 days
MODEL      <- "MRI_AGCM3_2_S"
API_KEY    <- getOption("openmeteo_api_key")

# Derived counts (both functions hardcode all 17 variables)
N_VARS     <- 17L
N_DAYS     <- as.integer(as.Date(DATE_STOP) - as.Date(DATE_START)) + 1L
N_CALLS_OLD <- length(ISO_TEST) * N_VARS * N_POINTS   # one HTTP request per location
N_CALLS_NEW <- length(ISO_TEST)                        # one HTTP request per country (all batched)
N_CORES_NEW <- max(1L, parallel::detectCores() - 1L)

cat(glue::glue("
=== Perf test parameters ===
  Countries : {paste(ISO_TEST, collapse=', ')}
  Grid pts  : {N_POINTS} per country
  Variables : {N_VARS} (hardcoded in both functions)
  Date range: {DATE_START} to {DATE_STOP} ({N_DAYS} days)
  Model     : {MODEL}
  API key   : {API_KEY}
  Old calls : {N_CALLS_OLD} HTTP requests (sequential)
  New calls : {N_CALLS_NEW} HTTP requests ({N_CORES_NEW} parallel cores)
"), "\n\n")

# ── Output directories (separate so files don't collide) ──────────────────────
out_old <- file.path(PATHS$DATA_RAW, "climate_perf_old")
out_new <- file.path(PATHS$DATA_RAW, "climate_perf_new")
dir.create(file.path(out_old, "climate"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(out_new, "climate"), recursive = TRUE, showWarnings = FALSE)

PATHS_old <- PATHS; PATHS_old$DATA_RAW <- out_old
PATHS_new <- PATHS; PATHS_new$DATA_RAW <- out_new

# ── Run OLD ───────────────────────────────────────────────────────────────────
cat("--- Running OLD implementation ---\n")
t_old <- system.time({
     download_climate_data_old(
          PATHS             = PATHS_old,
          iso_codes         = ISO_TEST,
          n_points          = N_POINTS,
          date_start        = DATE_START,
          date_stop         = DATE_STOP,
          climate_models    = MODEL,
          climate_variables = NULL,    # ignored; function hardcodes all 17
          api_key           = API_KEY
     )
})

cat(glue::glue("\nOLD elapsed: {round(t_old['elapsed'], 1)}s\n\n"))

# ── Run NEW ───────────────────────────────────────────────────────────────────
cat("--- Running NEW implementation ---\n")
t_new <- system.time({
     download_climate_data(
          PATHS             = PATHS_new,
          iso_codes         = ISO_TEST,
          n_points          = N_POINTS,
          date_start        = DATE_START,
          date_stop         = DATE_STOP,
          climate_models    = MODEL,
          climate_variables = NULL,    # ignored; function hardcodes all 17
          api_key           = API_KEY
     )
})

cat(glue::glue("\nNEW elapsed: {round(t_new['elapsed'], 1)}s\n\n"))

# ── Results ───────────────────────────────────────────────────────────────────
files_old <- length(list.files(file.path(out_old, "climate"), pattern = "\\.parquet$"))
files_new <- length(list.files(file.path(out_new, "climate"), pattern = "\\.parquet$"))
speedup   <- round(t_old["elapsed"] / t_new["elapsed"], 1)

# ── Write markdown report ─────────────────────────────────────────────────────
report_path <- file.path(dirname(PATHS$ROOT), "MOSAIC-pkg", "perf_test_results.md")

writeLines(glue::glue(
"# Climate Download Performance Test Results

Generated: {format(Sys.time(), '%Y-%m-%d %H:%M:%S')}

## Test Parameters

| Parameter | Value |
|---|---|
| Countries | {paste(ISO_TEST, collapse=', ')} |
| Grid points per country | {N_POINTS} |
| Climate variables | {N_VARS} (all hardcoded) |
| Date range | {DATE_START} to {DATE_STOP} ({N_DAYS} days) |
| Climate model | {MODEL} |
| API key | {API_KEY} |

## Architecture Comparison

| | Old | New |
|---|---|---|
| HTTP requests | {N_CALLS_OLD} (1 per location) | {N_CALLS_NEW} (1 per country) |
| Batching | None — 1 location per call | Up to 1,000 locations per call |
| Variables per call | 1 | All {N_VARS} at once |
| Parallelism | None (sequential triple loop) | {N_CORES_NEW} cores (mclapply) |
| Retry logic | None | Exponential backoff (5 attempts) |
| Rate throttle | 0.11s sleep per call | 0.11s sleep per chunk (free tier) |

## Timing Results

| Implementation | Elapsed (s) | Parquet files written |
|---|---|---|
| Old | {round(t_old['elapsed'], 1)} | {files_old} |
| New | {round(t_new['elapsed'], 1)} | {files_new} |
| **Speedup** | **{speedup}×** | |

## Notes

- Expected HTTP requests: old = {N_CALLS_OLD}, new = {N_CALLS_NEW}
  ({round(N_CALLS_OLD / N_CALLS_NEW)}× fewer requests)
- Parquet files expected: {length(ISO_TEST) * N_VARS} (1 per country × variable)
- Free API rate limit: 600 req/min → old code min sleep = {round(N_CALLS_OLD * 0.11, 0)}s
- New code sleeps 0s (single chunk per country, no inter-chunk sleep needed)
"), report_path)

cat(glue::glue("
=== Summary ===
  Old: {round(t_old['elapsed'], 1)}s  ({files_old} files)
  New: {round(t_new['elapsed'], 1)}s  ({files_new} files)
  Speedup: {speedup}×
  Report: {report_path}
"), "\n")
