# Linear intrpolation and extrapolation

Performs linear interpolation and, optionally, extrapolation of numeric
vectors. In `forestTIME`, Interpolation is used for annualizing tree
measurements such as `DIA`, `HT`, and `ACTUALHT`. Extrapolation is
necessary for trees that are alive in one inventory, then fallen and
dead with `NA`s in the next inventory, because we want to extrapolate
their growth from the last time they were inventoried alive to an
estimated mortality year. In the case of vectors with only one non-NA
value, that value is carried forward if `extrapolate = TRUE`.

## Usage

``` r
inter_extra_polate(x, y, extrapolate = TRUE)
```

## Arguments

- x:

  numeric; an x variable, usually `YEAR` in `forestTIME`

- y:

  numeric; the variable to be interpolated/extrapolated

- extrapolate:

  logical; perform extrapolation if possible?

## Value

numeric vector

a numeric vector

## Author

Eric R. Scott

## Examples

``` r
x <- 1:7
y <- c(2, NA, 5, 6, NA, NA, NA)
inter_extra_polate(x = x, y = y)
#> [1] 2.0 3.5 5.0 6.0 7.0 8.0 9.0
#with extrapolation
inter_extra_polate(x = x, y = y, extrapolate = TRUE)
#> [1] 2.0 3.5 5.0 6.0 7.0 8.0 9.0
#single numbers get carried forward
y2 <- c(NA, NA, 3, NA, NA)
inter_extra_polate(x = x, y = y2, extrapolate = TRUE)
#> [1] NA NA  3  3  3
```
