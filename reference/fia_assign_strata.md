# Assign interpolated data plots to estimation units and strata

This adds columns from various `POP_*` tables to annualized data so that
it can be used for stratified estimation (see, for example, [FIA
Demystified](https://doserlab.com/files/rfia/articles/fiademystified#with-sampling-errors)).
Each plot in each year is matched with an EVALID and it's associated
data as such:

1.  The EVALID must have both the `"EXPVOL"` and `"EXPCURR"` `EVAL_TYP`.

2.  The year indicated by the middle two digits of the EVALID (usually,
    but not always the `END_INVYR`) must match the `YEAR` in the
    annualized data for that plot.

3.  When there are gaps (e.g. because a plot was not sampled and not
    belong to an EVALID with `"EXPVOL"` or `"EXPCURR"`) the EVALIDs are
    filled down, then up.

## Usage

``` r
fia_assign_strata(data_annualized, db)
```

## Arguments

- data_annualized:

  Annualized data produced by
  [`fia_annualize()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_annualize.md).

- db:

  The list of tables produced by
  [`fia_load()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_load.md).

## Details

This means that the EVALID-associated data added by this function **may
be in conflict with the results of interpolation by
[`fia_annualize()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_annualize.md)!**
When using this function to do stratified estimation, use the
`PLOT_STATUS_CD` as part of the domain indicator to correctly exclude
any non-sampled plots with no tree data!

## See also

[`fia_eval_info()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_eval_info.md)
to see all possible EVALIDs associated with plots.

## Examples

``` r
# Load example data included in package
db <- fia_load("RI", dir = system.file("exdata", package = "forestTIME"))

# Annualize data
data_annualized <- db |> fia_tidy() |>
   fia_annualize(use_mortyr = FALSE)
#> ℹ Adjusting for mortality
#> ℹ Interpolating between surveys
#> ℹ Expanding years between surveys
#> ℹ Wrangling data
#> ✔ Wrangling data [494ms]
#> 
#> ℹ Expanding years between surveys
#> ✔ Expanding years between surveys [4.7s]
#> 
#> ℹ Interpolating between surveys
#> ✔ Interpolating between surveys [23.2s]
#> 
#> ℹ Adjusting for mortality
#> ✔ Adjusting for mortality [34.9s]
#> 

# Assign plots to strata, estimation units, and EVLIDs
data_stratified <- fia_assign_strata(data_annualized, db)
```
