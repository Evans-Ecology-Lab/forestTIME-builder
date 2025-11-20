#' Read in and join all required tables
#'
#' Reads in all the tables needed for carbon estimation and population scaling
#' and joins them into a single table. Then, some additional data cleaning steps
#' are performed.
#' 1. Creates unique tree and plot identifiers (`tree_ID` and `plot_ID`,
#'   respectively).
#' 2. Fills in missing values for `ACTUALHT` with values from `HT` to prepare
#'   for interpolation.
#' 3. Overwrites `SPCD` with whatever the last value of `SPCD` is for each tree
#'   (to handle trees that change `SPCD`).
#' 4. Fills a tree's `MORTYR` column so every row contains the recorded
#'   mortality year.
#'
#' @param db a list of tables produced by [fia_load()]
#' @export
#' @seealso [fia_add_composite_ids()]
#' @returns a tibble
fia_tidy <- function(db) {
  # Select only the columns we need from each table, to keep things slim
  cli::cli_progress_step("Wrangling data")
  PLOTGEOM <-
    db$PLOTGEOM |>
    dplyr::mutate(CN = as.character(CN)) |>
    dplyr::select(PLT_CN = CN, INVYR, ECOSUBCD)

  PLOT <-
    db$PLOT |>
    dplyr::mutate(CN = as.character(CN)) |>
    fia_add_composite_ids() |>
    dplyr::select(
      plot_ID,
      PLT_CN = CN,
      INVYR,
      MACRO_BREAKPOINT_DIA, #for assigning TPA_UNADJ
      INTENSITY,
      SUBCYCLE
    )

  COND <-
    db$COND |>
    dplyr::mutate(PLT_CN = as.character(PLT_CN)) |>
    fia_add_composite_ids() |>
    dplyr::select(
      plot_ID,
      PLT_CN,
      INVYR,
      CONDID,
      CONDPROP_UNADJ,
      PROP_BASIS, #for assigning TPA_UNADJ
      COND_STATUS_CD,
      STDORGCD
    )

  TREE <-
    db$TREE |>
    dplyr::mutate(PLT_CN = as.character(PLT_CN)) |>
    fia_add_composite_ids() |>
    dplyr::select(
      plot_ID,
      tree_ID,
      INVYR,
      PLT_CN,
      CONDID,
      MORTYR,
      STATUSCD,
      RECONCILECD,
      DECAYCD,
      STANDING_DEAD_CD,
      DIA,
      CR,
      HT,
      ACTUALHT,
      CULL,
      SPCD,
      # Temporary workaround for woodland species is to linearly interpolate
      # carbon and biomass rather than re-calculated it.
      # TODO: Eventually remove these columns to avoid confusing users.
      CARBON_AG,
      DRYBIO_AG
    )

  # POP table stuff
  POP_PLOT_STRATUM_ASSGN <- db$POP_PLOT_STRATUM_ASSGN |>
    fia_add_composite_ids() |>
    dplyr::select(plot_ID, INVYR, EVALID, ESTN_UNIT, STRATUMCD) |>
    dplyr::distinct()

  POP_STRATUM <- db$POP_STRATUM |>
    dplyr::select(EVALID, ESTN_UNIT, STRATUMCD, P1POINTCNT) |>
    dplyr::distinct()

  POP_ESTN_UNIT <- db$POP_ESTN_UNIT |>
    dplyr::select(EVALID, ESTN_UNIT, P1PNTCNT_EU, AREA_USED)

  POP_EVAL <- db$POP_EVAL |>
    dplyr::select(EVALID, END_INVYR)

  pop_info <- POP_PLOT_STRATUM_ASSGN |>
    dplyr::left_join(
      POP_STRATUM,
      by = dplyr::join_by(EVALID, ESTN_UNIT, STRATUMCD)
    ) |>
    dplyr::left_join(POP_ESTN_UNIT, by = dplyr::join_by(EVALID, ESTN_UNIT)) |>
    dplyr::left_join(POP_EVAL, by = dplyr::join_by(EVALID)) |>
    dplyr::mutate(
      EVAL_TYP_CD = stringr::str_extract(EVALID, "(\\d{2})$", group = 1)
    ) |>
    # for every plot_ID, INVYR and eval type, only keep the EVALID that is the
    # most recent one
    dplyr::filter(
      END_INVYR == max(END_INVYR),
      .by = c(plot_ID, EVAL_TYP_CD, INVYR)
    ) |>
    dplyr::select(-END_INVYR) |>
    # Keep only eval types 01 (EXPCURR) and 02 (EXPVOL)
    dplyr::filter(EVAL_TYP_CD %in% c("01", "02")) |>
    dplyr::arrange(plot_ID, INVYR, EVAL_TYP_CD) |>
    # Create indicator columns for these eval types
    dplyr::mutate(
      .by = plot_ID,
      INVYR,
      EVAL_TYPE_EXPCURR = any(EVAL_TYP_CD == "01"),
      EVAL_TYPE_EXPVOL = any(EVAL_TYP_CD == "02")
    ) |>
    # Pivot wider to get separate columns for each eval type and just one row
    # per plot x year
    dplyr::mutate(
      eval_type = dplyr::case_match(
        EVAL_TYP_CD,
        "01" ~ "EXPCURR",
        "02" ~ "EXPVOL"
      )
    ) |>
    dplyr::select(-EVAL_TYP_CD, -EVALID) |>
    tidyr::pivot_wider(
      names_from = eval_type,
      values_from = c(ESTN_UNIT, STRATUMCD, P1POINTCNT, P1PNTCNT_EU, AREA_USED)
    )

  # Join the tables
  data <-
    COND |>
    dplyr::as_tibble() |>
    dplyr::left_join(
      TREE,
      by = dplyr::join_by(plot_ID, PLT_CN, CONDID, INVYR)
    ) |>
    dplyr::left_join(PLOT, by = dplyr::join_by(plot_ID, PLT_CN, INVYR)) |>
    dplyr::left_join(PLOTGEOM, by = dplyr::join_by(INVYR, PLT_CN)) |>
    dplyr::left_join(pop_info, by = dplyr::join_by(plot_ID, INVYR))

  # Only keep plots that are part of an EXPCURR or EXPVOL eval.

  data <- data |> dplyr::filter(EVAL_TYPE_EXPVOL | EVAL_TYPE_EXPCURR)

  # Use only base intensity plots "Subcycle is 0 for a periodic inventory.
  # Subcycle 99 may be used for plots that are not included in the estimation
  # process." --FIADB user guide. For *most* states, this effectively filters
  # INVYR>= 2000, but in some southern states it appears all base-intenstiy
  # plots were measured in 1999
  # (https://github.com/Evans-Ecology-Lab/forestTIME/issues/171)

  # data <- data |>
  #   dplyr::filter(INTENSITY == 1 & SUBCYCLE != 0 & SUBCYCLE != 99)

  # fill MORTYR so it is a property of trees
  data <- data |>
    dplyr::group_by(tree_ID) |>
    tidyr::fill(MORTYR, .direction = c("updown")) |>
    # if trees have more than one SPCD, set all to be the most recent SPCD
    # (https://github.com/Evans-Ecology-Lab/forestTIME/issues/53)
    dplyr::mutate(SPCD = dplyr::last(SPCD)) |>
    dplyr::ungroup()

  # at this point, get the list of plots and years as following steps may remove
  # "empty" plots
  all_plots <- data |>
    dplyr::select(plot_ID, INVYR) |>
    dplyr::distinct() |>
    dplyr::left_join(PLOT, by = dplyr::join_by(plot_ID, INVYR))

  # coalesce ACTUALHT so it can be interpolated
  data <- data |>
    dplyr::mutate(ACTUALHT = dplyr::coalesce(ACTUALHT, HT))

  # join the empty plots back in
  data <-
    dplyr::full_join(
      data,
      all_plots,
      by = dplyr::join_by(
        plot_ID,
        PLT_CN,
        INVYR,
        MACRO_BREAKPOINT_DIA,
        INTENSITY,
        SUBCYCLE
      )
    ) |>
    dplyr::arrange(plot_ID, tree_ID, INVYR) |>
    dplyr::select(plot_ID, tree_ID, INVYR, everything())

  # return:
  data
}
