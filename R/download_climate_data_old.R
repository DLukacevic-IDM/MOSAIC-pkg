# Old implementation: triple loop (model × country × variable), one request per location.
# Adapted from main branch with minimum changes:
#   - calls get_climate_future_old instead of get_climate_future
#   - skips NULL returns gracefully
# Climate variables are hardcoded (same as main branch).

download_climate_data_old <- function(PATHS,
                                      iso_codes,
                                      n_points,
                                      date_start,
                                      date_stop,
                                      climate_models,
                                      climate_variables,
                                      api_key) {

     climate_variables <- c(
          "temperature_2m_mean", "temperature_2m_max", "temperature_2m_min",
          "wind_speed_10m_mean", "wind_speed_10m_max", "cloud_cover_mean",
          "shortwave_radiation_sum", "relative_humidity_2m_mean",
          "relative_humidity_2m_max", "relative_humidity_2m_min",
          "dew_point_2m_mean", "dew_point_2m_min", "dew_point_2m_max",
          "precipitation_sum", "pressure_msl_mean", "soil_moisture_0_to_10cm_mean",
          "et0_fao_evapotranspiration_sum"
     )

     if (!dir.exists(PATHS$DATA_CLIMATE)) {
          dir.create(PATHS$DATA_CLIMATE, recursive = TRUE)
     }

     for (climate_model in climate_models) {
          for (country_iso_code in iso_codes) {
               for (climate_variable in climate_variables) {

                    message(glue::glue("Downloading daily {climate_variable} data for {country_iso_code} using {climate_model} at {n_points} points"))

                    country_name <- MOSAIC::convert_iso_to_country(country_iso_code)
                    country_shp  <- sf::st_read(
                         dsn = file.path(PATHS$DATA_SHAPEFILES, paste0(country_iso_code, "_ADM0.shp")),
                         quiet = TRUE)
                    grid_points <- MOSAIC::generate_country_grid_n(country_shp, n_points = n_points)
                    coords      <- as.data.frame(sf::st_coordinates(grid_points))
                    rm(grid_points, country_shp)

                    climate_data <- get_climate_future_old(
                         lat               = coords$Y,
                         lon               = coords$X,
                         date_start        = date_start,
                         date_stop         = date_stop,
                         climate_variables = climate_variable,
                         climate_model     = climate_model,
                         api_key           = api_key
                    )

                    if (is.null(climate_data) || nrow(climate_data) == 0) {
                         warning(glue::glue("No data returned for {country_iso_code} / {climate_model} / {climate_variable} — skipping"))
                         next
                    }

                    climate_data <- data.frame(
                         country_name = country_name,
                         iso_code     = country_iso_code,
                         year  = lubridate::year(climate_data$date),
                         month = lubridate::month(climate_data$date),
                         week  = lubridate::week(climate_data$date),
                         doy   = lubridate::yday(climate_data$date),
                         climate_data
                    )

                    arrow::write_parquet(
                         climate_data,
                         sink = file.path(PATHS$DATA_RAW, paste0(
                              "climate/climate_data_", climate_model, "_", climate_variable, "_",
                              date_start, "_", date_stop, "_", country_iso_code, ".parquet")))
               }
          }
     }

     message(glue::glue("Raw climate data saved for all countries, variables, and models here: {PATHS$DATA_RAW}/climate"))
}
