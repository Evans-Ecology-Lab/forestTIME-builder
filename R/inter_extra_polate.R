#' Linear intrpolation and extrapolation
#'
#' Performs linear interpolation and, optionally, extrapolation of numeric
#' vectors. In `forestTIME`, Interpolation is used for annualizing tree
#' measurements such as `DIA`, `HT`, and `ACTUALHT`. Extrapolation is necessary
#' for trees that are alive in one inventory, then fallen and dead with `NA`s in
#' the next inventory, because we want to extrapolate their growth from the last
#' time they were inventoried alive to an estimated mortality year. In the case
#' of vectors with only one non-NA value, that value is carried forward if
#' `extrapolate = TRUE`.
#'
#' @param x numeric; an x variable, usually `YEAR` in `forestTIME`
#' @param y numeric; the variable to be interpolated/extrapolated
#' @param extrapolate logical; perform extrapolation if possible?
#' @returns numeric vector
#' @author Eric R. Scott
#' @keywords internal
#' @export
#'
#' @returns a numeric vector
#' @examples
#' x <- 1:7
#' y <- c(2, NA, 5, 6, NA, NA, NA)
#' inter_extra_polate(x = x, y = y)
#' #with extrapolation
#' inter_extra_polate(x = x, y = y, extrapolate = TRUE)
#' #single numbers get carried forward
#' y2 <- c(NA, NA, 3, NA, NA)
#' inter_extra_polate(x = x, y = y2, extrapolate = TRUE)
#'
inter_extra_polate <- function(x, y, extrapolate = TRUE) {
  if (sum(is.finite(y)) < 2) {
    if (isFALSE(extrapolate)) {
      return(y)
    } else {
      # if only one number, all we can do is cary it forwards
      interpolated <- vctrs::vec_fill_missing(y, direction = "down")
      return(interpolated)
    }
  } else {
    #first interpolate
    interpolated <- stats::approx(x, y, xout = x)$y
  }

  #then extrapolate trailing NAs if needed
  if (isFALSE(extrapolate)) {
    return(interpolated)
  } else {
    # If any trailing NAs
    if (any(is.na(interpolated)) & is.na(interpolated[length(interpolated)])) {
      # Everything but trailing NAs
      first_val <- min(which(!is.na(interpolated)))
      x_tr <- c(
        x[1:first_val - 1],
        x[!is.na(interpolated)]
      )
      y_tr <- c(
        interpolated[1:first_val - 1],
        interpolated[!is.na(interpolated)]
      )
      # year of trailing NAs
      xout_lgl <- is.na(interpolated)
      xout_lgl[1:first_val - 1] <- FALSE
      xout_tr <- x[xout_lgl]

      extrapolated <-
        Hmisc::approxExtrap(
          x = x_tr,
          y = y_tr,
          xout = xout_tr
        )$y
      return(c(y_tr, extrapolated))
    } else {
      return(interpolated)
    }
  }
}
