#' Read in needed tables
#'
#' Wrapper for [rFIA::readFIA] that reads in the necessary tables
#' @inheritParams rFIA::readFIA
#'
#' @export
#' @returns a list of data frames
#' @examples
#' /dontrun{
#' fia_download(states = "RI")
#' RI_db <- fia_load("RI")
#' }
#' 
fia_load <- function(states, dir = "fia") {
  rFIA::readFIA(dir = dir, states = states, tables = tables_ft) |>
    purrr::map(dplyr::as_tibble)
}