# Climate Download Performance Test Results

Generated: 2026-03-03 00:23:34

## Test Parameters

| Parameter | Value |
|---|---|
| Countries | AGO, BDI, BEN, BFA, BWA |
| Grid points per country | 10 |
| Climate variables | 17 (all hardcoded) |
| Date range | 2023-01-01 to 2023-03-31 (90 days) |
| Climate model | MRI_AGCM3_2_S |
| API key | free |

## Architecture Comparison

| | Old | New |
|---|---|---|
| HTTP requests | 850 (1 per location) | 5 (1 per country) |
| Batching | None — 1 location per call | Up to 1,000 locations per call |
| Variables per call | 1 | All 17 at once |
| Parallelism | None (sequential triple loop) | 11 cores (mclapply) |
| Retry logic | None | Exponential backoff (5 attempts) |
| Rate throttle | 0.11s sleep per call | 0.11s sleep per chunk (free tier) |

## Timing Results

| Implementation | Elapsed (s) | Parquet files written |
|---|---|---|
| Old | 310.9 | 85 |
| New | 14.1 | 85 |
| **Speedup** | **22.1×** | |

## Notes

- Expected HTTP requests: old = 850, new = 5
  (170× fewer requests)
- Parquet files expected: 85 (1 per country × variable)
- Free API rate limit: 600 req/min → old code min sleep = 94s
- New code sleeps 0s (single chunk per country, no inter-chunk sleep needed)

## Data Equivalence Check

Compared 85 matched parquet files. Files only in old: 0. Only in new: 0.

| File | Rows old | Rows new | Rows match | Dates match | Value cor | RMSE | Max diff |
|---|---|---|---|---|---|---|---|
| climate_data_MRI_AGCM3_2_S_cloud_cover_mean_2023-01-01_2023-03-31_AGO.parquet |  900 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_cloud_cover_mean_2023-01-01_2023-03-31_BDI.parquet |  900 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_cloud_cover_mean_2023-01-01_2023-03-31_BEN.parquet |  990 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_cloud_cover_mean_2023-01-01_2023-03-31_BFA.parquet |  810 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_cloud_cover_mean_2023-01-01_2023-03-31_BWA.parquet |  990 | 900 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_dew_point_2m_max_2023-01-01_2023-03-31_AGO.parquet |  900 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_dew_point_2m_max_2023-01-01_2023-03-31_BDI.parquet |  990 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_dew_point_2m_max_2023-01-01_2023-03-31_BEN.parquet |  900 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_dew_point_2m_max_2023-01-01_2023-03-31_BFA.parquet |  810 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_dew_point_2m_max_2023-01-01_2023-03-31_BWA.parquet |  900 | 900 | TRUE | TRUE | 0.72918 | 2.2589 | 10 |
| climate_data_MRI_AGCM3_2_S_dew_point_2m_mean_2023-01-01_2023-03-31_AGO.parquet |  900 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_dew_point_2m_mean_2023-01-01_2023-03-31_BDI.parquet | 1080 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_dew_point_2m_mean_2023-01-01_2023-03-31_BEN.parquet |  900 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_dew_point_2m_mean_2023-01-01_2023-03-31_BFA.parquet | 1080 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_dew_point_2m_mean_2023-01-01_2023-03-31_BWA.parquet |  900 | 900 | TRUE | TRUE | 0.9773 | 1.0542 | 8 |
| climate_data_MRI_AGCM3_2_S_dew_point_2m_min_2023-01-01_2023-03-31_AGO.parquet | 1080 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_dew_point_2m_min_2023-01-01_2023-03-31_BDI.parquet |  810 | 810 | TRUE | TRUE | 0.95365 | 0.9346 | 2.8 |
| climate_data_MRI_AGCM3_2_S_dew_point_2m_min_2023-01-01_2023-03-31_BEN.parquet |  900 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_dew_point_2m_min_2023-01-01_2023-03-31_BFA.parquet |  990 | 990 | TRUE | TRUE | 0.95213 | 2.6004 | 24.8 |
| climate_data_MRI_AGCM3_2_S_dew_point_2m_min_2023-01-01_2023-03-31_BWA.parquet |  990 | 900 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_et0_fao_evapotranspiration_sum_2023-01-01_2023-03-31_AGO.parquet |  900 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_et0_fao_evapotranspiration_sum_2023-01-01_2023-03-31_BDI.parquet |  810 | 810 | TRUE | TRUE | 0.99255 | 0.1299 | 0.72 |
| climate_data_MRI_AGCM3_2_S_et0_fao_evapotranspiration_sum_2023-01-01_2023-03-31_BEN.parquet |  810 | 810 | TRUE | TRUE | 0.98274 | 0.2418 | 1.49 |
| climate_data_MRI_AGCM3_2_S_et0_fao_evapotranspiration_sum_2023-01-01_2023-03-31_BFA.parquet | 1080 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_et0_fao_evapotranspiration_sum_2023-01-01_2023-03-31_BWA.parquet |  810 | 900 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_precipitation_sum_2023-01-01_2023-03-31_AGO.parquet |  990 | 990 | TRUE | TRUE | 0.12075 | 8.7804 | 91.74 |
| climate_data_MRI_AGCM3_2_S_precipitation_sum_2023-01-01_2023-03-31_BDI.parquet |  810 | 810 | TRUE | TRUE | 0.76846 | 7.8848 | 57.68 |
| climate_data_MRI_AGCM3_2_S_precipitation_sum_2023-01-01_2023-03-31_BEN.parquet | 1080 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_precipitation_sum_2023-01-01_2023-03-31_BFA.parquet |  990 | 990 | TRUE | TRUE | 1 | 0 | 0 |
| climate_data_MRI_AGCM3_2_S_precipitation_sum_2023-01-01_2023-03-31_BWA.parquet |  990 | 900 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_pressure_msl_mean_2023-01-01_2023-03-31_AGO.parquet |  990 | 990 | TRUE | TRUE | 0.99673 | 0.1131 | 0.3 |
| climate_data_MRI_AGCM3_2_S_pressure_msl_mean_2023-01-01_2023-03-31_BDI.parquet |  810 | 810 | TRUE | TRUE | 0.97025 | 0.3001 | 0.9 |
| climate_data_MRI_AGCM3_2_S_pressure_msl_mean_2023-01-01_2023-03-31_BEN.parquet | 1080 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_pressure_msl_mean_2023-01-01_2023-03-31_BFA.parquet |  990 | 990 | TRUE | TRUE | 0.98256 | 0.4779 | 3.4 |
| climate_data_MRI_AGCM3_2_S_pressure_msl_mean_2023-01-01_2023-03-31_BWA.parquet |  990 | 900 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_relative_humidity_2m_max_2023-01-01_2023-03-31_AGO.parquet |  990 | 990 | TRUE | TRUE | 0.22214 | 13.3377 | 67 |
| climate_data_MRI_AGCM3_2_S_relative_humidity_2m_max_2023-01-01_2023-03-31_BDI.parquet |  810 | 810 | TRUE | TRUE | 0.36298 | 6.247 | 30 |
| climate_data_MRI_AGCM3_2_S_relative_humidity_2m_max_2023-01-01_2023-03-31_BEN.parquet |  810 | 810 | TRUE | TRUE | 0.93111 | 11.5225 | 63 |
| climate_data_MRI_AGCM3_2_S_relative_humidity_2m_max_2023-01-01_2023-03-31_BFA.parquet |  810 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_relative_humidity_2m_max_2023-01-01_2023-03-31_BWA.parquet |  900 | 900 | TRUE | TRUE | 0.7779 | 12.2047 | 49 |
| climate_data_MRI_AGCM3_2_S_relative_humidity_2m_mean_2023-01-01_2023-03-31_AGO.parquet |  990 | 990 | TRUE | TRUE | 0.66304 | 14.4339 | 53 |
| climate_data_MRI_AGCM3_2_S_relative_humidity_2m_mean_2023-01-01_2023-03-31_BDI.parquet |  810 | 810 | TRUE | TRUE | 0.69631 | 8.2777 | 36 |
| climate_data_MRI_AGCM3_2_S_relative_humidity_2m_mean_2023-01-01_2023-03-31_BEN.parquet |  900 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_relative_humidity_2m_mean_2023-01-01_2023-03-31_BFA.parquet |  810 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_relative_humidity_2m_mean_2023-01-01_2023-03-31_BWA.parquet | 1080 | 900 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_relative_humidity_2m_min_2023-01-01_2023-03-31_AGO.parquet |  810 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_relative_humidity_2m_min_2023-01-01_2023-03-31_BDI.parquet |  990 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_relative_humidity_2m_min_2023-01-01_2023-03-31_BEN.parquet |  990 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_relative_humidity_2m_min_2023-01-01_2023-03-31_BFA.parquet |  810 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_relative_humidity_2m_min_2023-01-01_2023-03-31_BWA.parquet |  990 | 900 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_shortwave_radiation_sum_2023-01-01_2023-03-31_AGO.parquet |  990 | 990 | TRUE | TRUE | 0.65152 | 4.4722 | 18.07 |
| climate_data_MRI_AGCM3_2_S_shortwave_radiation_sum_2023-01-01_2023-03-31_BDI.parquet |  810 | 810 | TRUE | TRUE | 0.86257 | 2.6472 | 11.42 |
| climate_data_MRI_AGCM3_2_S_shortwave_radiation_sum_2023-01-01_2023-03-31_BEN.parquet |  990 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_shortwave_radiation_sum_2023-01-01_2023-03-31_BFA.parquet |  990 | 990 | TRUE | TRUE | 0.5334 | 1.6477 | 11.35 |
| climate_data_MRI_AGCM3_2_S_shortwave_radiation_sum_2023-01-01_2023-03-31_BWA.parquet |  810 | 900 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_soil_moisture_0_to_10cm_mean_2023-01-01_2023-03-31_AGO.parquet |  990 | 990 | TRUE | TRUE | 0.44231 | 0.1149 | 0.318 |
| climate_data_MRI_AGCM3_2_S_soil_moisture_0_to_10cm_mean_2023-01-01_2023-03-31_BDI.parquet |  810 | 810 | TRUE | TRUE | 0.53467 | 0.1175 | 0.367 |
| climate_data_MRI_AGCM3_2_S_soil_moisture_0_to_10cm_mean_2023-01-01_2023-03-31_BEN.parquet |  810 | 810 | TRUE | TRUE | 0.56372 | 0.0876 | 0.23 |
| climate_data_MRI_AGCM3_2_S_soil_moisture_0_to_10cm_mean_2023-01-01_2023-03-31_BFA.parquet |  810 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_soil_moisture_0_to_10cm_mean_2023-01-01_2023-03-31_BWA.parquet |  810 | 900 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_temperature_2m_max_2023-01-01_2023-03-31_AGO.parquet |  810 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_temperature_2m_max_2023-01-01_2023-03-31_BDI.parquet |  810 | 810 | TRUE | TRUE | 0.93759 | 1.0613 | 4.7 |
| climate_data_MRI_AGCM3_2_S_temperature_2m_max_2023-01-01_2023-03-31_BEN.parquet |  900 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_temperature_2m_max_2023-01-01_2023-03-31_BFA.parquet | 1080 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_temperature_2m_max_2023-01-01_2023-03-31_BWA.parquet |  990 | 900 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_temperature_2m_mean_2023-01-01_2023-03-31_AGO.parquet |  990 | 990 | TRUE | TRUE | 0.08672 | 3.3797 | 10.9 |
| climate_data_MRI_AGCM3_2_S_temperature_2m_mean_2023-01-01_2023-03-31_BDI.parquet |  900 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_temperature_2m_mean_2023-01-01_2023-03-31_BEN.parquet |  900 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_temperature_2m_mean_2023-01-01_2023-03-31_BFA.parquet |  900 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_temperature_2m_mean_2023-01-01_2023-03-31_BWA.parquet |  990 | 900 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_temperature_2m_min_2023-01-01_2023-03-31_AGO.parquet |  900 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_temperature_2m_min_2023-01-01_2023-03-31_BDI.parquet |  810 | 810 | TRUE | TRUE | 0.52208 | 1.4284 | 3.8 |
| climate_data_MRI_AGCM3_2_S_temperature_2m_min_2023-01-01_2023-03-31_BEN.parquet |  990 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_temperature_2m_min_2023-01-01_2023-03-31_BFA.parquet |  990 | 990 | TRUE | TRUE | 0.99194 | 0.5025 | 1.2 |
| climate_data_MRI_AGCM3_2_S_temperature_2m_min_2023-01-01_2023-03-31_BWA.parquet |  900 | 900 | TRUE | TRUE | 0.76377 | 1.5524 | 7 |
| climate_data_MRI_AGCM3_2_S_wind_speed_10m_max_2023-01-01_2023-03-31_AGO.parquet |  900 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_wind_speed_10m_max_2023-01-01_2023-03-31_BDI.parquet |  900 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_wind_speed_10m_max_2023-01-01_2023-03-31_BEN.parquet |  810 | 810 | TRUE | TRUE | 0.5495 | 2.9517 | 11.5 |
| climate_data_MRI_AGCM3_2_S_wind_speed_10m_max_2023-01-01_2023-03-31_BFA.parquet |  900 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_wind_speed_10m_max_2023-01-01_2023-03-31_BWA.parquet |  720 | 900 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_wind_speed_10m_mean_2023-01-01_2023-03-31_AGO.parquet |  810 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_wind_speed_10m_mean_2023-01-01_2023-03-31_BDI.parquet |  990 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_wind_speed_10m_mean_2023-01-01_2023-03-31_BEN.parquet |  900 | 810 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_wind_speed_10m_mean_2023-01-01_2023-03-31_BFA.parquet |  900 | 990 | FALSE | TRUE | NA | NA | NA |
| climate_data_MRI_AGCM3_2_S_wind_speed_10m_mean_2023-01-01_2023-03-31_BWA.parquet |  810 | 900 | FALSE | TRUE | NA | NA | NA |

**Files fully equivalent (cor > 0.999): 1 / 85**

> Note: coordinates may differ slightly (old uses API-returned snapped coords;
> new uses request coords). Values should be identical for matched locations.

_Updated: 2026-03-03 00:24:16_
