#' Calculate area of different landcover classes
#'
#' The land cover data shows us how much of the region is covered by forests,
#' rivers, wetlands, barren land, or urban infrastructure thus allowing the
#' observation of land cover dynamics over a period of time. This function
#' allows to efficiently calculate area of different landcover classes for
#' polygons. For each polygon, the area of the classes in hectare(ha) is
#' returned.
#' The required resources for this indicator are:
#'  - [esalandcover]
#'
#' @name landcover
#' @docType data
#' @keywords indicator
#' @format A tibble with a column for area (in ha) and the percentage covered per
#'   landcover class
#' @examples
#' library(sf)
#' library(mapme.biodiversity)
#'
#' temp_loc <- file.path(tempdir(), "mapme.biodiversity")
#' if (!file.exists(temp_loc)) {
#'   dir.create(temp_loc)
#'   resource_dir <- system.file("res", package = "mapme.biodiversity")
#'   file.copy(resource_dir, temp_loc, recursive = TRUE)
#' }
#'
#' (try(aoi <- system.file("extdata", "sierra_de_neiba_478140_2.gpkg",
#'   package = "mapme.biodiversity"
#' ) %>%
#'   read_sf() %>%
#'   init_portfolio(
#'     years = 2016:2017,
#'     outdir = file.path(temp_loc, "res"),
#'     tmpdir = tempdir(),
#'     add_resources = FALSE,
#'     verbose = FALSE
#'   ) %>%
#'   get_resources("esalandcover") %>%
#'   calc_indicators("landcover") %>%
#'   tidyr::unnest(landcover)))
NULL

#' Calculate area of different landcover classes from ESA
#'
#' Considering the 100 meter global copernicus landcover raster datasets users
#' can compute the area of the landcover classes among 23 discrete classes provided
#' from ESA available for years 2015 to 2019.
#'
#' @param shp A single polygon for which to calculate the area of landcover classes
#' @param esalandcover The landcover raster resource from ESA
#' @param rundir A directory where intermediate files are written to.
#' @param verbose A directory where intermediate files are written to.
#' @param ... additional arguments
#' @return A tibble
#' @keywords internal
#' @noRd

.calc_landcover <- function(shp,
                            esalandcover,
                            rundir = tempdir(),
                            verbose = TRUE,
                            ...) {
  percentage <- NULL
  year <- NULL
  classes <- NULL

  if (is.null(esalandcover)) {
    return(NA)
  }

  shp_v <- vect(shp)
  esa_mask <- terra::mask(esalandcover, shp_v)
  arearaster <- cellSize(esa_mask, mask = TRUE, unit = "ha")
  total_size <- as.numeric(global(arearaster, fun = sum, na.rm = TRUE))

  purrr::map_dfr(1:nlyr(esa_mask), function(i) {
    zonal(arearaster, esa_mask[[i]], sum) %>%
      tidyr::pivot_longer(cols = -area, names_to = "year", values_to = "code") %>%
      dplyr::left_join(.esa_landcover_classes, by = "code") %>%
      dplyr::mutate(
        percentage = area / total_size,
        year = regmatches(year, regexpr("\\d{4}", year))
      ) %>%
      dplyr::select(classes, year, area, percentage)
  })
}

.esa_landcover_classes <- data.frame(
  code = c(0, 111:116, 121:126, seq(20, 100, 10), 200),
  classes = c(
    "no_data", "closed_forest_evergreen_needle_leaf", "closed_forest_evergreen_broad_leaf", "closed_forest_deciduous_needle_leaf",
    "closed_forest_deciduous_broad_leaf", "closed_forest_mixed", "closed_forest_unknown", "open_forest_evergreen_needle_leaf",
    "open_forest_evergreen_broad_leaf", "open_forest_deciduous_needle_leaf", "open_forest_deciduous_broad_leaf",
    "open_forest_mixed", "open_forest_unknown", "shrubs", "herbaceous_vegetation", "cropland", "built_up", "bare_vegetation",
    "snow_and_ice", "permanent_water_bodies", "herbaceous_wetland", "moss_and_lichen", "open_sea"
  )
)
