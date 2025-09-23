test_that("EXPNS get added", {
  df1 <- tidyr::expand_grid(
    plot_ID = c(
      "44_1_7_254",
      "44_1_3_261",
      "44_1_9_117",
      "44_1_7_177",
      "44_1_5_348",
      "44_1_7_65",
      "44_1_9_80",
      "44_1_3_327",
      "44_1_3_23",
      "44_1_9_54"
    ),
    YEAR = 2000:2005
  ) |>
    fia_calc_expns()

  df2 <- tidyr::expand_grid(
    plot_ID = c(
      "44_1_7_254",
      "44_1_3_261",
      "44_1_9_117",
      "44_1_7_177",
      "44_1_5_348"
    ),
    YEAR = 2000:2005
  ) |>
    fia_calc_expns()

  expect_s3_class(df1, "data.frame")
  # super simple test works because same # plots in every year
  expect_equal(unique(df1$EXPNS) * 2, unique(df2$EXPNS))
})
