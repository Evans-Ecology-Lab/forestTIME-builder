test_that("fia_assign_strata() works", {
  db <- fia_load("RI", dir = system.file("exdata", package = "forestTIME"))
  data_tidy <- fia_tidy(db) |> dplyr::filter(INVYR %in% c(2009:2014))
  data_annualized <- fia_annualize(data_tidy, use_mortyr = FALSE)
  data_strata <- fia_assign_strata(data_annualized, db)
  expect_s3_class(data_strata, "data.frame")
})
