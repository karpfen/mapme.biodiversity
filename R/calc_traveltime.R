#' Calculate accessibility statistics
#'
#' Accessibility is the ease with which larger cities can be reached from a
#' certain location. This function allows to efficiently calculate accessibility
#' statistics (i.e. travel time to nearby major cities) for polygons. For each
#' polygon, the desired statistic/s (mean, median or sd) is/are returned.
#' The required resources for this indicator are:
#'  - [nelson_et_al]
#'
#' The following arguments can be set:
#' \describe{
#'   \item{stats_accessibility}{Function to be applied to compute statistics for polygons either
#'   one or multiple inputs as character. Supported statistics are: "mean",
#'   "median", "sd", "min", "max", "sum" "var".}
#'   \item{engine}{The preferred processing functions from either one of "zonal",
#'   "extract" or "exactextract" as character.}
#' }
#'
#' @name traveltime
#' @docType data
#' @keywords indicator
#' @format A tibble with a column for accessibility statistics (in minutes)
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
#'     years = 2022,
#'     outdir = file.path(temp_loc, "res"),
#'     tmpdir = tempdir(),
#'     add_resources = FALSE,
#'     verbose = FALSE
#'   ) %>%
#'   get_resources("nelson_et_al",
#'     range_traveltime = c("5k_10k", "100k_200k", "500k_1mio", "1mio_5mio")
#'   ) %>%
#'   calc_indicators("traveltime", stats_accessibility = c("min", "max"), engine = "extract") %>%
#'   tidyr::unnest(traveltime)))
NULL

#' Calculate accessibility to major cities' statistics
#'
#' Considering the 1km travel time raster datasets users can specify which
#' statistics among mean, median or standard deviation to compute. Also, users
#' can specify the functions i.e. zonal from package terra, extract from package
#' terra, or exactextract from exactextractr as desired.
#'
#' @param shp A single polygon for which to calculate the accessibility statistic
#' @param nelson_et_al The nelson_et_al raster resource (Weiß et al. (2018))
#' @param stats_accessibility Function to be applied to compute statistics for polygons
#'    either one or multiple inputs as character "mean", "median" or "sd".
#' @param engine The preferred processing functions from either one of "zonal",
#'   "extract" or "exactextract" as character.
#' @param rundir A directory where intermediate files are written to.
#' @param verbose A directory where intermediate files are written to.
#' @param ... additional arguments
#' @return A tibble
#' @keywords internal
#' @noRd
.calc_traveltime <- function(shp,
                             nelson_et_al,
                             engine = "extract",
                             stats_accessibility = "mean",
                             rundir = tempdir(),
                             verbose = TRUE,
                             ...) {
  if (is.null(nelson_et_al)) {
    return(NA)
  }
  # set max value of 65535 to NA
  nelson_et_al <- clamp(nelson_et_al, lower = -Inf, upper = 65534, values = FALSE)
  results <- .select_engine(
    shp = shp,
    raster = nelson_et_al,
    stats = stats_accessibility,
    engine = engine,
    name = "minutes",
    mode = "asset"
  )
  results$distance <- unlist(lapply(names(nelson_et_al), function(x) strsplit(x, "-|.tif")[[1]][2]))
  results
}
