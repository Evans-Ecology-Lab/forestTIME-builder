# Interpolate categorical variables to switch at midpoint

Categorical variables like `DECAYCD` can't be linearly interpolated
between inventory years. Instead, we assume they switch values at the
midpoint (rounded down) between non-missing values. Trailing `NA`s are
replaced with the last non-`NA` value and leading `NA`s are returned
as-is.

## Usage

``` r
step_interp(x)
```

## Arguments

- x:

  a vector

## Value

a vector with no `NA`s

a vector

## Examples

``` r
step_interp(c(NA, NA, "A", NA, NA, NA, "B", NA, NA, NA, NA, "C", NA))
#>  [1] NA  NA  "A" "A" "B" "B" "B" "B" "B" "C" "C" "C" "C"
```
