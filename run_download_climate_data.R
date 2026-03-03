# MOSAIC::install_dependencies()
# MOSAIC::check_python_env()

library(MOSAIC)

set_root_directory("~/git/cholera-prj/MOSAIC")
PATHS <- MOSAIC::get_paths()

set_openmeteo_api_key("free")
#set_openmeteo_api_key("JJjz1zPqFKe27phI")

DATE_START <- as.Date("2023-01-01")
DATE_STOP <- as.Date("2023-03-31")

################################################################################
# DATA PREPARATION: downloading and processing all data required for MOSAIC
################################################################################

#-------------------------------------------------------------------------------
# Get shapefiles for all countries

# download_africa_shapefile(PATHS)
# download_all_country_shapefiles(PATHS)


# process_country_similarity_data(PATHS)


#-------------------------------------------------------------------------------
# Download climate data for all countries from OpenMeteo API (aggregated by sampling point and
# by week)

download_climate_data(PATHS,
                      iso_codes = MOSAIC::iso_codes_africa[1:3],
                      n_points = 30,
                      date_start = DATE_START,
                      date_stop = DATE_STOP,
                      climate_model = c("MRI_AGCM3_2_S"),
                      api_key = getOption('openmeteo_api_key'))

# Process all climate variables into country level aggregates (daily, weekly, monthly)
# process_climate_data(PATHS)
