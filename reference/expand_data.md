# Expand data to include years between inventory years

This is an "internal" function—most users will want to run
[`fia_annualize()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_annualize.md)
instead. This expands the data frame in preparation for interpolation of
now "missing" values between inventory years. Time-invariant variables
`tree_ID`, `plot_ID`, `SPCD`, `MORTYR`, `ECOSUBCD`, `DESIGNCD`, and
`PROP_BASIS` are simply filled in with
[`tidyr::fill()`](https://tidyr.tidyverse.org/reference/fill.html).
Categorical variables `STATUDSCD`, `RECONCILECD`, `STDORGCD`, `CONDID`,
and `COND_STATUS_CD` are modified to replace `NA`s with `999` so that
they are properly interpolated by
[`interpolate_data()`](https://evans-ecology-lab.github.io/forestTIME/reference/interpolate_data.md)
(which converts them back to `NA`s).

## Usage

``` r
expand_data(data)
```

## Arguments

- data:

  tibble produced by
  [`fia_tidy()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_tidy.md)—must
  have at least `tree_ID` and `INVYR` columns.

## Value

a tibble with a logical column `interpolated` marking whether a row was
present in the original data (`FALSE`) or was added (`TRUE`).
