#' Calculate Zonal Soil Properties
#'
#' This indicator allows the extraction of zonal statistics for resource layers
#' previously downloaded from SoilGrids, thus in total supporting the calculation
#' of zonal statistics for 10 different soil properties at 6 different depths for
#' a total of 4 different model outputs (stat). Zonal statistics will be calculated
#' for all SoilGrid layers that have been previously made available vie \code{get_resources()}.
#' The required resource for this indicator is:
#'  - [soilgrids]
#'
#' The following arguments can be set:
#' \describe{
#'   \item{stats_soil}{Function to be applied to compute statistics for polygons either
#'   single or multiple inputs as character. Supported statistics are: "mean",
#'   "median", "sd", "min", "max", "sum" "var".}
#'   \item{engine}{The preferred processing functions from either one of "zonal",
#'   "extract" or "exactextract" as character.}
#' }
#'
#' @name soilproperties
#' @docType data
#' @keywords indicator
#' @format A tibble with a column for the SoilGrid layer, the depth and the model
#'   output statistic as well as additional columns for all zonal statistics
#'   specified via \code{stats_soil}
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
#'   get_resources("soilgrids",
#'     layers = c("clay", "silt"), depths = c("0-5cm", "5-15cm"), stats = "mean"
#'   ) %>%
#'   calc_indicators("soilproperties", stats_soil = c("mean", "median"), engine = "extract") %>%
#'   tidyr::unnest(soilproperties)))
NULL
.calc_soilproperties <- function(shp,
                                 soilgrids,
                                 engine = "zonal",
                                 stats_soil = "mean",
                                 rundir = tempdir(),
                                 verbose = TRUE,
                                 ...) {
  # check if input engines are correct
  if (is.null(soilgrids)) {
    return(NA)
  }
  results <- .select_engine(
    shp = shp,
    raster = soilgrids,
    stats = stats_soil,
    engine = engine,
    mode = "asset"
  )

  parameters <- gsub(".tif", "", names(soilgrids))
  parameters <- lapply(parameters, function(param) {
    splitted <- strsplit(param, "_")[[1]]
    names(splitted) <- c("layer", "depth", "stat")
    splitted
  })

  results$layer <- sapply(parameters, function(para) para["layer"])
  results$depth <- sapply(parameters, function(para) para["depth"])
  results$stat <- sapply(parameters, function(para) para["stat"])

  # conversion to conventional units
  conv_df <- lapply(.sg_layers, function(y) as.data.frame(y))
  conv_df <- do.call(rbind, conv_df)["conversion_factor"]
  conv_df$layer <- row.names(conv_df)
  results <- tibble(merge(results, conv_df))
  # apply conversion factor
  for (stat in stats_soil) results[[stat]] <- results[[stat]] / results[["conversion_factor"]]
  # select cols in right order
  as_tibble(results[, c("layer", "depth", "stat", stats_soil)])
}
