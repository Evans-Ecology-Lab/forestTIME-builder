#' Tree Allometry
#'
#' Takes the interpolated diameter, height, and status code data and applies NSVB allometric equations to calculate volume, carbon, and biomass using code provided by David Walker with slight
#' modifications
#'
#' @param data_prepped tibble produced by [prep_carbon()].
#' @author David Walker
#' @noRd
#' @returns a tibble
tree_allometry <- function(data_prepped) {
  med_cr_prop <-
    median_crprop_csv |>
    dplyr::mutate(SFTWD_HRDWD = dplyr::if_else(hwd_yn == 'N', 'S', 'H'))

  fiadb <-
    data_prepped |>
    # Can't estimate carbon for trees with missing heights or woodland species woodland species
    dplyr::filter(JENKINS_SPGRPCD < 10, !is.na(HT)) |>
    # Can't estimate carbon for empty plots
    dplyr::filter(!is.na(tree_ID) | !stringr::str_starts(tree_ID, "NA_")) |>
    dplyr::left_join(
      med_cr_prop |> dplyr::select(PROVINCE = Province, SFTWD_HRDWD, CRmn),
      by = dplyr::join_by(SFTWD_HRDWD, PROVINCE)
    )

  miss_sft <- med_cr_prop[med_cr_prop$Province == 'UNDEFINED', ]$CRmn[1]
  miss_hwd <- med_cr_prop[med_cr_prop$Province == 'UNDEFINED', ]$CRmn[2]

  fiadb[
    is.na(fiadb$CRmn) &
      fiadb$SFTWD_HRDWD == 'S',
    'CRmn'
  ] <- miss_sft
  fiadb[
    is.na(fiadb$CRmn) &
      fiadb$SFTWD_HRDWD == 'H',
    'CRmn'
  ] <- miss_hwd

  fiadb$BROKEN_TOP <- !(fiadb$HT == fiadb$ACTUALHT)

  # Assumes un-recorded CR for alive trees is 0

  # original code doesn't work with NAs for STATUSCD as is the case with plots with no trees
  # fiadb[is.na(fiadb$CR) & fiadb$STATUSCD == 1, 'CR'] <- 0
  fiadb <- dplyr::mutate(
    fiadb,
    CR = dplyr::if_else(is.na(CR) & STATUSCD == 1, 0, CR)
  )

  # planted loblolly/slash use separate equations
  fiadb[is.na(fiadb$STDORGCD), "STDORGCD"] <- 0
  fiadb$SPCD <- ifelse(
    fiadb$SPCD %in% c(111, 131) & fiadb$STDORGCD == 1,
    paste0("1_", fiadb$SPCD),
    fiadb$SPCD
  )

  fiadb[is.na(fiadb$CULL), 'CULL'] <- 0

  # finest level of model application
  fiadb$SPCD_DIVISION <- paste(fiadb$SPCD, fiadb$DIVISION)

  #The `forms` object is assumed to be in the parent environment by
  #applyAllLevels() I think

  # equation numbers and forms are stored in ref file
  forms <- equation_forms_and_calls_csv
  add_me <- data.frame(
    equation = c(3.1, 6.1),
    rhs = c(
      "<- a * DBH^b * THT^c * WDSG",
      "<- (1 - (1 - ACTUALHT / THT)^alpha)^beta"
    )
  )

  forms <- rbind(forms, add_me)

  forms$rhs <- gsub('VTOTIB', 'VTOTIB_GROSS', forms$rhs)
  forms$rhs <- gsub('VTOTOB', 'VTOTOB_GROSS', forms$rhs)

  # apply over fiadb
  fiadb2 <- predictCRM2(
    data = fiadb,
    # # directory where the coefficient files are
    forms = forms,
    # what are the variable names for dbh/total height/cull
    # should probably update this for c_frac, actual_ht, etc
    var_names = c(DBH = "DIA", THT = "HT", CULL = "CULL"),
    gross.volume = FALSE,
    all.vars = TRUE
  ) |>
    dplyr::as_tibble() |>
    # I don't trust predictCRM2() to have not modified columns in weird ways
    # just to satisfy prerequesites of calculations. Therefore, I'm only going
    # to keep certain columns from the output and join them into the input data.
    dplyr::select(
      any_of(c(
        "tree_ID",
        "plot_ID",
        "YEAR",

        "DRYBIO_AG" = "BIOMASS", #Does not include foliage
        "DRIBIO_FOLIAGE" = "FOLIAGE", #just foliage
        "CARBON_AG" = "CARBON",

        #total stem volumes
        "VOLTSGRS" = "VTOTIB_GROSS",
        "VOLTSSND" = "VTOTIB_SOUND" #,

        #bole volumes
        # "VOLCFNET" =
        # "VOLCFGRS" =
        # "VOLCFSND" =
      ))
    )

  cli::cli_progress_step("Joining carbon estimation results")
  carbon_joined <- dplyr::left_join(
    data_prepped, # input
    fiadb2, # carbon estimates
    by = dplyr::join_by(plot_ID, tree_ID, YEAR)
  ) |>
    # This is a temporary workaround for estimating carbon of woodland species
    # through interpolation rather than re-calculating.  The `coalesce()` fills
    # in any NAs for the re-calculated values with interpolated values
    # TODO: eventually remove this
    dplyr::mutate(
      DRYBIO_AG = dplyr::if_else(
        JENKINS_SPGRPCD == 10,
        pmax(
          # set negative numbers to 0
          dplyr::coalesce(
            DRYBIO_AG,
            DRYBIO_AG_interpolated
          ),
          0
        ),
        DRYBIO_AG
      ),
      CARBON_AG = dplyr::if_else(
        JENKINS_SPGRPCD == 10,
        pmax(
          dplyr::coalesce(
            CARBON_AG,
            CARBON_AG_interpolated
          ),
          0
        ),
        CARBON_AG
      )
    ) |>
    # add forestTIME identifier to carbon and biomass columns
    dplyr::rename(
      CARBON_AG_ft = CARBON_AG,
      DRYBIO_AG_ft = DRYBIO_AG
    ) |>
    # drop temporary carbon and biomass interpolated columns to avoid confusion
    dplyr::select(
      -dplyr::any_of(c(
        "CARBON_AG_interpolated",
        "DRYBIO_AG_interpolated"
      ))
    )

  carbon_joined
}
