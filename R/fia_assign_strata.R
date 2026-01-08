#' Assign interpolated data plots to estimation units and strata
#'
#' This adds columns from various `POP_*` tables to annualized data so that it
#' can be used for stratified estimation (see, for example, [FIA
#' Demystified](https://doserlab.com/files/rfia/articles/fiademystified#with-sampling-errors)).
#' Each plot in each year is matched with an EVALID and it's associated data as such:
#' 1. The EVALID must have both the `"EXPVOL"` and `"EXPCURR"` `EVAL_TYP`.
#' 2. The EVALID's `END_INVYR` must match the `YEAR` in the annualized data for
#'    that plot.
#' 3. When there are gaps (e.g. because a plot was not sampled and not belong to
#'    an EVALID with `"EXPVOL"` or `"EXPCURR"`) the EVALIDs are filled down,
#'    then up.
#'
#' This means that the EVALID-associated data added by this function **may be in
#' conflict with the results of interpolation by `fia_annualize()`!** When using
#' this function to do stratified estimation, use the `PLOT_STATUS_CD` as part
#' of the domain indicator to correctly exclude any non-sampled plots with no
#' tree data!
#' @param data_annualized Annualized data produced by [fia_annualize()].
#' @param db The list of tables produced by [fia_load()].
#' @examples
#' \dontrun{
#'
#' db <- fia_load("RI", dir = system.file("exdata", package = "forestTIME"))
#' data_annualized <- db |> fia_tidy() |>
#'    fia_annualize(use_mortyr = FALSE)
#' data_stratified <- fia_assign_strata(data_annualized, db)
#' }
#' @export
fia_assign_strata <- function(data_annualized, db) {
  pop_info <- make_eval_info(db)

  # # TODO need to collapse EVALIDs that are only EXPVOL or EXPCURR into a single
  # # row I think.  These *might* only exist pre-1999 though.
  # pop_info |>
  #     filter(EXPVOL | EXPCURR) |>
  #     filter(INVYR == END_INVYR) |> # one per year per type
  #     count(plot_ID, INVYR, EVAL_TYPs) |> filter(n>1)

  chosen_evals <- pop_info |>
    dplyr::filter(EXPVOL & EXPCURR) |>
    dplyr::select(-INVYR)

  data_eval <- dplyr::left_join(
    data_annualized,
    chosen_evals,
    by = dplyr::join_by(plot_ID, YEAR == END_INVYR),
    keep = TRUE # to keep END_INVYR
  ) |>
    dplyr::select(plot_ID = plot_ID.x, dplyr::everything(), -plot_ID.y)

  # Fill NAs down then up (doesn't matter much, I think, because plots that
  # shouldn't be included in EXPCURR evals will be excluded due to PLOT_STATUS_CD)

  data_eval <- data_eval |>
    dplyr::group_by(plot_ID) |>
    dplyr::arrange(YEAR) |>
    tidyr::fill(colnames(chosen_evals), .direction = "downup") |>
    dplyr::ungroup()

  data_eval

  # TODO calculate EXPNS
}


#' Get EVALIDs and associated information for plots
#'
#' @param db A list of tibbles produced by [fia_load()].
#' @returns A tibble with variables that can be used for stratified estimation
#'   that can be joined to annualized data.
#' @noRd
make_eval_info <- function(db) {
  # Matches plot_ID & INVYR to stratum code, estimation unit, and EVALID
  POP_PLOT_STRATUM_ASSGN <- db$POP_PLOT_STRATUM_ASSGN |>
    fia_add_composite_ids() |>
    dplyr::select(plot_ID, INVYR, EVALID, ESTN_UNIT, STRATUMCD, STRATUM_CN) |>
    dplyr::mutate(dplyr::across(dplyr::ends_with("_CN"), as.character))

  # Contains P1POINTCNT for each stratum x estimation unit x EVALID combination
  POP_STRATUM <- db$POP_STRATUM |>
    dplyr::select(
      EVALID,
      ESTN_UNIT,
      ESTN_UNIT_CN,
      STRATUMCD,
      STRATUM_DESCR,
      P1POINTCNT
    ) |>
    dplyr::mutate(dplyr::across(dplyr::ends_with("_CN"), as.character))

  # Contains P1PNTCNT_EU and AREA_USED for every estimation unit x EVALID combination
  POP_ESTN_UNIT <- db$POP_ESTN_UNIT |>
    dplyr::select(EVALID, ESTN_UNIT, ESTN_UNIT_DESCR, P1PNTCNT_EU, AREA_USED)

  # Matches EVALIDs to their START_INVYR and END_INVYR
  POP_EVAL <- db$POP_EVAL |>
    dplyr::select(EVAL_CN = CN, EVAL_GRP_CN, EVALID, START_INVYR, END_INVYR) |>
    dplyr::mutate(dplyr::across(dplyr::ends_with("CN"), as.character))

  # Summarize to get just one row per EVALID with indicator columns for just the
  # EVAL_TYPs we are interested in.  This table doesn't have EVALID, so we'll
  # have to get EVAL_CN and EVAL_GRP_CN and join on those.
  POP_EVAL_TYP <- db$POP_EVAL_TYP |>
    dplyr::select(EVAL_GRP_CN, EVAL_CN, EVAL_TYP) |>
    dplyr::mutate(dplyr::across(dplyr::ends_with("CN"), as.character)) |>
    dplyr::summarize(
      .by = c(EVAL_GRP_CN, EVAL_CN),
      EVAL_TYPs = paste0(sort(EVAL_TYP), collapse = ", "),
      EXPCURR = any(EVAL_TYP == "EXPCURR"),
      EXPVOL = any(EVAL_TYP == "EXPVOL")
    )

  # Join eval type info to END_INVYR
  pop_eval_type <- dplyr::full_join(
    POP_EVAL,
    POP_EVAL_TYP,
    by = dplyr::join_by(EVAL_CN, EVAL_GRP_CN)
  )

  # Bring it all together
  pop_info <- POP_PLOT_STRATUM_ASSGN |>
    dplyr::left_join(
      POP_STRATUM,
      by = dplyr::join_by(EVALID, ESTN_UNIT, STRATUMCD)
    ) |>
    dplyr::left_join(POP_ESTN_UNIT, by = dplyr::join_by(EVALID, ESTN_UNIT)) |>
    dplyr::left_join(pop_eval_type, by = dplyr::join_by(EVALID))

  pop_info
}
