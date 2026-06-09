# Assign interpolated data plots to estimation units and strata

This adds columns from various `POP_*` tables to annualized data so that
it can be used for stratified estimation (see, for example, [FIA
Demystified](https://doserlab.com/files/rfia/articles/fiademystified#with-sampling-errors)).
Each plot in each year is matched with an EVALID and it's associated
data as such:

1.  The EVALID must have both the `"EXPVOL"` and `"EXPCURR"` `EVAL_TYP`.

2.  The `YEAR` must be between `START_INVYR` and `END_INVYR`.

3.  The first matching EVALID is used—i.e. if the `YEAR` is 2002 and
    there are EVALIDs for 2000–2003, 2001–2004, and 2002–2005, the one
    from 2000–2003 will be matched.

## Usage

``` r
fia_design(data_annualized, db)
```

## Arguments

- data_annualized:

  Annualized data produced by
  [`fia_annualize()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_annualize.md).

- db:

  The list of tables produced by
  [`fia_load()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_load.md).

## Details

EVALID-associated data added by this function **may be in conflict with
the results of interpolation by
[`fia_annualize()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_annualize.md)!**
When using this function to do stratified estimation, use the
`PLOT_STATUS_CD` as part of the domain indicator to correctly exclude
any non-sampled plots with no tree data!

## See also

[`fia_eval_info()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_eval_info.md)
to see all possible EVALIDs associated with plots.

## Examples

``` r
if (FALSE) { # \dontrun{
# Load example data included in package
db <- fia_load("RI", dir = system.file("exdata", package = "forestTIME"))

# Annualize data
data_annualized <- db |> fia_tidy() |>
   fia_annualize(use_mortyr = FALSE)

# Assign plots to strata, estimation units, and EVLIDs
data_stratified <- fia_design(data_annualized, db)
} # }
```
