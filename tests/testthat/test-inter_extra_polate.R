test_that("inter_extra_polate() works", {
  y <- c(2, NA, 5, 6, NA, NA, NA)
  expect_equal(
    inter_extra_polate(x = seq_along(y), y = y),
    c(2, 3.5, 5, 6, 7, 8, 9)
  )

  expect_equal(
    inter_extra_polate(x = seq_along(y), y = y, extrapolate = FALSE),
    c(2, 3.5, 5, 6, NA, NA, NA)
  )
})

test_that("single numbers get carried forward", {
  y <- c(5, NA, NA, NA)
  expect_equal(
    inter_extra_polate(x = seq_along(y), y = y, extrapolate = TRUE),
    c(5, 5, 5, 5)
  )
})

test_that("leading NAs handled correctly", {
  y <- c(NA, NA, 5, NA, 7, NA)
  expect_equal(
    inter_extra_polate(x = seq_along(y), y = y, extrapolate = TRUE),
    c(NA, NA, 5, 6, 7, 8)
  )
  expect_equal(
    inter_extra_polate(x = seq_along(y), y = y, extrapolate = FALSE),
    c(NA, NA, 5, 6, 7, NA)
  )
  y2 <- c(NA, 5, 6, 7, 8)
  expect_equal(
    inter_extra_polate(x = seq_along(y2), y = y2, extrapolate = TRUE),
    y2
  )
  y3 <- c(NA, 7, NA, 5, NA)
  expect_equal(
    inter_extra_polate(x = seq_along(y3), y = y3, extrapolate = TRUE),
    c(NA, 7, 6, 5, 4)
  )
})
