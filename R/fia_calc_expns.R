#' Add expansion factors (`EXPNS`)
#'
#' Adds an `EXPNS` column intended to be used in the same way as the `EXPNS`
#' column in the raw FIA data.  It is calculated simply as the state land area
#' divided by the total number of plots in that state in that year in the data.
#' This allows it to be used with interpolated data.
#'
#' @param data a data frame with at least a `plot_ID` column and a `YEAR`
#'   column.
#' @export
#' @returns a tibble
fia_calc_expns <- function(data) {
  data |>
    # get STATECD out of plot_ID
    dplyr::mutate(
      STATECD = as.numeric(stringr::str_extract(plot_ID, "\\d+(?=_)"))
    ) |>
    dplyr::left_join(
      state_areas |> dplyr::select(STATECD, state_land_area),
      by = dplyr::join_by(STATECD)
    ) |>
    dplyr::group_by(YEAR, STATECD) |>
    dplyr::mutate(
      EXPNS = state_land_area / length(unique(plot_ID))
    ) |>
    dplyr::ungroup() |>
    dplyr::select(-STATECD, -state_land_area)
}
