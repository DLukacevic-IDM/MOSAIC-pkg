# Old implementation: one HTTP request per location (no batching).
# Adapted from main branch with minimum changes for free API support.

get_climate_future_old <- function(lat,
                                   lon,
                                   date_start,
                                   date_stop,
                                   climate_variables,
                                   climate_model,
                                   api_key = NULL) {

     if (length(climate_model) > 1) stop("One climate model at a time")

     available_climate_variables <- c(
          "temperature_2m_mean", "temperature_2m_max", "temperature_2m_min",
          "wind_speed_10m_mean", "wind_speed_10m_max", "cloud_cover_mean",
          "shortwave_radiation_sum", "relative_humidity_2m_mean",
          "relative_humidity_2m_max", "relative_humidity_2m_min",
          "dew_point_2m_mean", "dew_point_2m_min", "dew_point_2m_max",
          "precipitation_sum", "rain_sum", "snowfall_sum",
          "pressure_msl_mean", "soil_moisture_0_to_10cm_mean",
          "et0_fao_evapotranspiration_sum"
     )

     if (!all(climate_variables %in% available_climate_variables)) {
          stop(paste("Error: Some climate variables are not available. Please choose from:",
                     paste(available_climate_variables, collapse = ", ")))
     }

     available_models <- c(
          "CMCC_CM2_VHR4", "FGOALS_f3_H", "HiRAM_SIT_HR",
          "MRI_AGCM3_2_S", "EC_Earth3P_HR", "MPI_ESM1_2_XR", "NICAM16_8S"
     )

     if (!(climate_model %in% available_models)) {
          stop(paste("Error: The provided climate model is not available. Please choose from:",
                     paste(available_models, collapse = ", ")))
     }

     is_free  <- identical(api_key, "free")
     base_url <- if (is_free) "https://climate-api.open-meteo.com/v1/climate"
                 else          "https://customer-climate-api.open-meteo.com/v1/climate"

     variables_param <- paste(climate_variables, collapse = ",")
     results_list <- list()
     pb <- txtProgressBar(min = 0, max = length(lat), style = 3)

     for (i in seq_along(lat)) {

          url <- paste0(
               base_url, "?",
               "latitude=",  lat[i],
               "&longitude=", lon[i],
               "&start_date=", date_start,
               "&end_date=",   date_stop,
               "&models=",     climate_model,
               "&daily=",      variables_param,
               if (!is_free) paste0("&apikey=", api_key) else ""
          )

          response <- httr::GET(url, httr::timeout(120))

          if (httr::status_code(response) == 200) {

               data  <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))
               dates <- as.Date(substr(data$daily$time, 1, 10))

               for (variable in climate_variables) {
                    if (!is.null(data$daily[[variable]])) {
                         results_list[[paste0(i, "_", variable)]] <- data.frame(
                              date          = dates,
                              latitude      = lat[i],
                              longitude     = lon[i],
                              climate_model = climate_model,
                              variable_name = variable,
                              value         = data$daily[[variable]]
                         )
                    }
               }

          } else {
               warning(paste("Failed to retrieve data for lat:", lat[i], "lon:", lon[i],
                             "— HTTP", httr::status_code(response)))
          }

          setTxtProgressBar(pb, i)
          if (is_free) Sys.sleep(0.11)  # stay under 600 req/min on free tier
     }

     close(pb)
     results_df <- do.call(rbind, results_list)
     rownames(results_df) <- NULL
     return(results_df)
}
