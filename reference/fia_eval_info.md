# Get EVALIDs and associated information for plots

Get information about the EVALIDs associated with plots from the various
`POP_*` tables.

## Usage

``` r
fia_eval_info(db)
```

## Arguments

- db:

  A list of tibbles produced by
  [`fia_load()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_load.md).
  @returns A tibble with variables that can be used for stratified
  estimation that can be joined to annualized data. @examples db \<-
  fia_load("RI", dir = system.file("exdata", package = "forestTIME"))
  fia_eval_info(db)

## Value

A tibble.
