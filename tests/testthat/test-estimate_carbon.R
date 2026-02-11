library(dplyr)
test_that("estimates match those in raw data", {
  db <- fia_load(
    "DE",
    dir = system.file("exdata", package = "forestTIME")
  )
  orig <- db$TREE |>
    # dplyr::filter(INVYR >= 2000L) |>
    fia_add_composite_ids() |>
    dplyr::select(
      tree_ID,
      INVYR,
      TPA_UNADJ,
      CARBON_AG,
      DRYBIO_AG
    )
  data_prepped <- fia_tidy(db) |>
    dplyr::filter(INTENSITY == 1) |>
    dplyr::rename(YEAR = INVYR) |>
    prep_carbon() |>
    # add back TPA_UNADJ from raw data because we are skipping interpolation steps
    dplyr::left_join(
      orig |>
        dplyr::select(tree_ID, YEAR = INVYR, TPA_UNADJ) |>
        dplyr::distinct()
    )

  data_carbon <- data_prepped |>
    estimate_carbon() |>
    dplyr::select(
      tree_ID,
      YEAR,
      CARBON_AG_est = CARBON_AG,
      DRYBIO_AG_est = DRYBIO_AG
    )
  # add the original estimates of carbon and biomass to the prepped data, then
  # add the outputs of estimate_carbon()
  test <- dplyr::left_join(
    data_prepped |> dplyr::filter(!is.na(tree_ID)), #ignore empty plots
    orig |>
      dplyr::select(
        tree_ID,
        YEAR = INVYR,
        CARBON_AG_orig = CARBON_AG,
        DRYBIO_AG_orig = DRYBIO_AG
      )
  ) |>
    dplyr::left_join(data_carbon |> dplyr::filter(!is.na(tree_ID))) #ignore empty plots

  expect_equal(test$CARBON_AG_est, test$CARBON_AG_orig, tolerance = 1e-3)
  expect_equal(test$DRYBIO_AG_est, test$DRYBIO_AG_orig, tolerance = 1e-3)
})

test_that("no carbon or biomass estimates for fallen dead trees", {
  db <- fia_load(
    "RI",
    dir = system.file("exdata", package = "forestTIME")
  )
  data_tidy <- fia_tidy(db)
  test_tree <- "1_44_9_5416_2_15"
  test_val <- data_tidy |>
    filter(tree_ID == test_tree) |>
    fia_annualize() |>
    fia_estimate() |>
    filter(YEAR > 2020) |>
    pull(CARBON_AG) |>
    is.na() |>
    all()
  expect_true(test_val)
})

test_that("no negative carbon or biomass", {
  db <- fia_load(
    "RI",
    dir = system.file("exdata", package = "forestTIME")
  )
  data_tidy <- fia_tidy(db) |>
    filter(plot_ID %in% c("1_44_3_129", "1_44_3_135", "1_44_3_211"))
  data_estimated <- fia_annualize(data_tidy, use_mortyr = FALSE) |>
    fia_estimate()
  expect_equal(nrow(data_estimated |> filter(CARBON_AG < 0)), 0)
  expect_equal(nrow(data_estimated |> filter(DRYBIO_AG < 0)), 0)

  # The issue is really only with woodland species, but don't want to run AZ on
  # GitHub actions
  skip_on_ci()
  az <- fia_load("AZ", dir = "../../fia")
  az_example <- fia_tidy(az) |>
    filter(plot_ID %in% c("1_4_11_1", "1_4_9_88113")) |>
    fia_annualize() |>
    prep_carbon() |> 
    estimate_carbon()

  expect_equal(nrow(az_example |> filter(CARBON_AG < 0)), 0)
  expect_equal(nrow(az_example |> filter(DRYBIO_AG < 0)), 0)
})

