#' Assign interpolated data plots to estimation units and strata
#'
#' This adds columns from various `POP_*` tables to annualized data so that it
#' can be used for stratified estimation (see, for example, [FIA
#' Demystified](https://doserlab.com/files/rfia/articles/fiademystified#with-sampling-errors)).
#' Each plot in each year is matched with an EVALID and it's associated data as
#' such:
#' 1. The EVALID must have both the `"EXPVOL"` and `"EXPCURR"` `EVAL_TYP`.
#' 2. The `YEAR` must be between `START_INVYR` and `END_INVYR`.
#' 3. The first matching EVALID is used—i.e. if the `YEAR` is 2002 and there are
#'    EVALIDs for 2000--2003, 2001--2004, and 2002--2005, the one from
#'    2000--2003 will be matched.
#'
#' EVALID-associated data added by this function **may be in conflict with the
#' results of interpolation by `fia_annualize()`!** When using this function to
#' do stratified estimation, use the `PLOT_STATUS_CD` as part of the domain
#' indicator to correctly exclude any non-sampled plots with no tree data!
#'
#' @param data_annualized Annualized data produced by [fia_annualize()].
#' @param db The list of tables produced by [fia_load()].
#' @examples
#' \dontrun{
#' # Load example data included in package
#' db <- fia_load("RI", dir = system.file("exdata", package = "forestTIME"))
#'
#' # Annualize data
#' data_annualized <- db |> fia_tidy() |>
#'    fia_annualize(use_mortyr = FALSE)
#'
#' # Assign plots to strata, estimation units, and EVLIDs
#' data_stratified <- fia_assign_strata(data_annualized, db)
#' }
#' @seealso [fia_eval_info()] to see all possible EVALIDs associated with plots.
#' @export
fia_assign_strata <- function(data_annualized, db) {
  pop_info <- fia_eval_info(db)

  # # TODO need to collapse EVALIDs that are only EXPVOL or EXPCURR into a single
  # # row I think.  These *might* only exist pre-1999 though.
  # pop_info |>
  #     filter(EXPVOL | EXPCURR) |>
  #     filter(INVYR == END_INVYR) |> # one per year per type
  #     count(plot_ID, INVYR, EVAL_TYPs) |> filter(n>1)

  chosen_evals <- pop_info |>
    dplyr::filter(EXPVOL & EXPCURR) |>
    dplyr::arrange(INVYR, START_INVYR, END_INVYR) |>
    dplyr::select(-INVYR) |>
    fia_split_composite_ids() |>
    # Only keep EVALIDs after the start of the annual inventory in each state as
    # an additional layer of precaution against matching "bad" EVALIDs.  This
    # takes the place of some of the state-specific fixes implemented in rFIA
    # here:
    # https://github.com/doserjef/rFIA/blob/ac9c8cb7c524935afeb25ef859ab422a2bb68044/R/getDesignInfo.R#L55C3-L62C4)
    dplyr::left_join(annual_inventory_start, by = "STATECD") |>
    dplyr::select(
      plot_ID,
      EVALID,
      EVALID_YEAR,
      START_INVYR,
      END_INVYR,
      annual_inventory_start,
      everything()
    ) |>
    dplyr::filter(START_INVYR >= annual_inventory_start)

  # Handle Texas.  Remove plots part of any EVALID associated with West/East
  # Texas
  if (48 %in% unique(chosen_evals$STATECD)) {
    # fmt: table
    bad_evalids <- c(
      482320 , 482321 , 482323 , 482329 , 482327 , 481277 , 480320 , 480321 ,
      480329 , 481223 , 481229 , 480323 , 480420 , 480421 , 480429 , 480520 ,
      480521 , 480529 , 480620 , 480621 , 480623 , 480629 , 480723 , 480729 ,
      480823 , 480829 , 480923 , 480929 , 481023 , 481029 , 481377 , 481323 ,
      481329 , 481429 , 487503 , 488601 , 488602 , 488603 , 489201 , 489202 ,
      489203 , 487501 , 481529 , 481177 , 481123 , 481129 , 487502
    )

    chosen_evals <- chosen_evals |>
      dplyr::filter(!.data$EVALID %in% bad_evalids)
  }

  # Rolling join to match all EVALIDs containing YEAR between START_INVYR and
  # END_INVYR
  data_eval <- dplyr::left_join(
    data_annualized |> dplyr::select(-annual_inventory_start),
    chosen_evals,
    by = dplyr::join_by(plot_ID, dplyr::between(YEAR, START_INVYR, END_INVYR))
  ) |>
    # For each tree x year, only keep one row (the first/earliest EVALID match)
    dplyr::group_by(plot_ID, tree_ID, YEAR) |>
    dplyr::arrange(EVALID_YEAR) |>
    dplyr::slice_head(n = 1) |>
    # Fill down within each tree to carry EVALIDs forward across inventories where
    # trees weren't sampled.  Not doing this by plot because there are some edge
    # cases where a plot was not sampled and then an entirely different set of
    # trees was sampled the following inventory.
    dplyr::arrange(plot_ID, tree_ID, YEAR) |>
    dplyr::group_by(tree_ID) |>
    tidyr::fill(colnames(chosen_evals), .direction = "down") |>
    dplyr::ungroup() |>
    # Calculate P2POINTCNT (number of plots per stratum in each year)
    dplyr::mutate(
      .by = c(EVALID, ESTN_UNIT_CN, STRATUM_CN, YEAR),
      P2POINTCNT = ifelse(!is.na(EVALID), length(unique(plot_ID)), NA)
    )

  
# Identify small strata with too few plots for variance calculation
  # TODO:
  # - Use a better algorithm than adist().  E.g. try
  #   `stringdist::stringdistmatrix(... method = "jaccard")`
  # - Detect small strata iteratively so the next small stratum in the for-loop
  #   doesn't try to merge with a stratum that has already been merged.
  # - Don't merge strata with "buff" in the description with strata that don't
  #   have "buff" in the description (PNW only).

  # Make unique ID for stratum / year pairs
  data_eval$stratID <- paste(data_eval$STRATUM_CN, data_eval$YEAR, sep = "_")

  data_eval <- data_eval |>
    dplyr::mutate(too_small = P2POINTCNT == 1) |> # NOTE: in rFIA it is `< 2` but that's the same as `== 1` for integers.
    dplyr::arrange(P2POINTCNT) |>
    dplyr::mutate(
      .by = c(EVALID, ESTN_UNIT_CN, YEAR),
      n_strata = length(unique(STRATUM_CN))
    )

  # This recreates the chosen_evals, but only the ones that matched with a plot
  # in the data
  pop_matched <- data_eval |>
    dplyr::distinct(
      stratID,
      EVALID,
      ESTN_UNIT_CN,
      STRATUM_CN,
      STRATUM_DESCR,
      YEAR,
      P1POINTCNT,
      P2POINTCNT,
      too_small,
      n_strata
    )

  ## Check if any fail
  warnMe <- c()

  ## If any are too small, i.e., only one plot --> do some merging
  if (any(pop_matched$too_small)) {
    for (i in pop_matched$stratID[pop_matched$too_small == TRUE]) {
      # Subset rows of the pop info matched with data
      pop <- pop_matched |> dplyr::filter(stratID == i)

      # Use fuzzy string matching if there are any other strata available to merge with
      if (pop$n_strata > 1) {
        neighbors <- pop_matched |>
          dplyr::filter(ESTN_UNIT_CN == pop$ESTN_UNIT_CN) |>
          dplyr::filter(YEAR == pop$YEAR) |>
          dplyr::filter(stratID != i)

        if (nrow(neighbors) < 1) {
          warnMe <- c(warnMe, TRUE)
        } else {
          warnMe <- c(warnMe, FALSE)

          # Find the most similar neighbor in terms of stratum description
          # FIXME: adist() doesn't do particularly well here. Explore
          # alternatives.
          msn <- adist(pop$STRATUM_DESCR, neighbors$STRATUM_DESCR)
          msnID <- neighbors$stratID[which.min(msn)]

          # In `data_eval`, we want to update all rows of the giving and receiving
          # strata where giving gets a change in STRATUM_CN, P1POINTCNT, and
          # P2POINTCNT

          # Giving Stratum ----
          data_eval[data_eval$stratID == i, 'STRATUM_CN'] <- unique(pop_matched[
            pop_matched$stratID == msnID,
            'STRATUM_CN'
          ])
          data_eval[data_eval$stratID == i, 'P1POINTCNT'] <- unique(pop_matched[
            pop_matched$stratID == msnID,
            'P1POINTCNT'
          ])
          data_eval[data_eval$stratID == i, 'P2POINTCNT'] <- unique(pop_matched[
            pop_matched$stratID == msnID,
            'P2POINTCNT'
          ])

          # Receiving Stratum ----
          data_eval[
            data_eval$stratID == msnID,
            'P1POINTCNT'
          ] <- unique(pop_matched[
            pop_matched$stratID == msnID,
            'P1POINTCNT'
          ]) +
            pop$P1POINTCNT

          data_eval[
            data_eval$stratID == msnID,
            'P2POINTCNT'
          ] <- unique(pop_matched[
            pop_matched$stratID == msnID,
            'P2POINTCNT'
          ]) +
            pop$P2POINTCNT
        }
      } else {
        # If this is the only available stratum in the estimation unit in a given year

        # Not sure what to do in this situation.  In rFIA they combine strata
        # from different years in the same estimation unit and EVALID, but that
        # involves changing the INVYR of the EVALID. In effect, perhaps we are
        # already doing this by using an overlap join to allow matching of *any*
        # EVALID where the plot's YEAR is between the start and end of the eval.
        warnMe <- c(warnMe, TRUE)
      }
    }
  }

  if (any(warnMe)) {
    cli::cli_warn(
      "Bad stratification, i.e., strata too small to compute variance of interpolated data in some years."
    )
  }

  # TODO: not 100% sure how to adapt this or if we need it:
  # https://github.com/doserjef/rFIA/blob/ac9c8cb7c524935afeb25ef859ab422a2bb68044/R/util.R#L1039-L1062

  # Calculate EXPNS
  data_expns <- data_eval |>
    dplyr::mutate(
      EXPNS = (AREA_USED * P1POINTCNT / P1PNTCNT_EU) / P2POINTCNT
    )

  # If a plot isn't assigned an EVALID, it's not EXPCURR or EXPVOL
  data_out <- data_expns |>
    dplyr::mutate(
      EXPCURR = dplyr::if_else(is.na(EXPCURR), FALSE, EXPCURR),
      EXPVOL = dplyr::if_else(is.na(EXPVOL), FALSE, EXPVOL)
    ) |>
    # remove cols that could easily be joined in from eval info later
    dplyr::select(
      -all_of(c(
        "UNITCD",
        "STATECD",
        "COUNTYCD",
        "PLOT",
        "EVALID_YEAR",
        "STRATUM_DESCR",
        "ESTN_UNIT_DESCR",
        "EVAL_DESCR",
        "START_INVYR",
        "END_INVYR",
        "ESTN_METHOD",
        "EVAL_TYPs"
      ))
    )

  data_out
}


#' Get EVALIDs and associated information for plots
#'
#' Get information about the EVALIDs associated with plots from the various
#' `POP_*` tables.
#'
#' @param db A list of tibbles produced by [fia_load()].
#' @returns A tibble with variables that can be used for stratified estimation
#' that can be joined to annualized data.
#' @examples
#' db <- fia_load("RI", dir = system.file("exdata", package = "forestTIME"))
#' fia_eval_info(db)
#' @keywords internal
#' @export
fia_eval_info <- function(db) {
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
    dplyr::select(
      EVAL_CN = CN,
      EVAL_GRP_CN,
      EVALID,
      EVAL_DESCR,
      START_INVYR,
      END_INVYR,
      ESTN_METHOD
    ) |>
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

  # Extract middle two digits of EVALID and convert to a year
  pop_info <- pop_info |>
    dplyr::mutate(
      EVALID_YEAR = stringr::str_extract(
        EVALID,
        # the first 1 *or 2* digits are state code (leading zero may not be
        # there)
        "^\\d{1}\\d?(\\d{2})\\d{2}$",
        group = 1
      ),
      EVALID_YEAR = dplyr::if_else(
        as.numeric(EVALID_YEAR) > 30,
        as.integer(paste0("19", EVALID_YEAR)),
        as.integer(paste0("20", EVALID_YEAR))
      ),

      .after = EVALID
    )

  pop_info
}
