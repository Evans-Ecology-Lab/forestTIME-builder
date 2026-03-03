# Split composite ID columns

Splits the composite ID columns `tree_ID` and/or `plot_ID` into their
original component columns

## Usage

``` r
fia_split_composite_ids(data)
```

## Arguments

- data:

  A tibble with the `tree_ID` and/or `plot_ID` columns

## Value

The input tibble with additional columns `UNITCD`, `STATECD`,
`COUNTYCD`, `PLOT` and possibly `SUBP` and `TREE`.

## See also

[`fia_add_composite_ids()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_add_composite_ids.md)

## Examples

``` r
db <- fia_load("RI", dir = system.file("exdata", package = "forestTIME"))
data_tidy <- fia_tidy(db)
#> ℹ Wrangling data
#> ✔ Wrangling data [532ms]
#> 
fia_split_composite_ids(data_tidy)
#> # A tibble: 15,890 × 34
#>    UNITCD STATECD COUNTYCD PLOT  plot_ID SUBP  TREE  tree_ID INVYR PLT_CN CONDID
#>    <chr>  <chr>   <chr>    <chr> <chr>   <chr> <chr> <chr>   <dbl> <chr>   <int>
#>  1 1      44      1        155   1_44_1… NA    NA    NA       2005 62270…      1
#>  2 1      44      1        155   1_44_1… NA    NA    NA       2009 14500…      1
#>  3 1      44      1        155   1_44_1… NA    NA    NA       2014 16826…      1
#>  4 1      44      1        155   1_44_1… NA    NA    NA       2021 71991…      1
#>  5 1      44      1        228   1_44_1… 1     1     1_44_1…  2004 55944…      2
#>  6 1      44      1        228   1_44_1… 1     1     1_44_1…  2008 12004…      2
#>  7 1      44      1        228   1_44_1… 1     1     1_44_1…  2013 14527…      1
#>  8 1      44      1        228   1_44_1… 1     1     1_44_1…  2020 60259…      1
#>  9 1      44      1        228   1_44_1… 1     2     1_44_1…  2004 55944…      2
#> 10 1      44      1        228   1_44_1… 1     2     1_44_1…  2008 12004…      2
#> # ℹ 15,880 more rows
#> # ℹ 23 more variables: CONDPROP_UNADJ <dbl>, PROP_BASIS <chr>,
#> #   COND_STATUS_CD <int>, STDORGCD <int>, MORTYR <lgl>, STATUSCD <int>,
#> #   RECONCILECD <int>, DECAYCD <int>, STANDING_DEAD_CD <int>, DIA <dbl>,
#> #   CR <int>, HT <int>, ACTUALHT <int>, CULL <int>, SPCD <dbl>,
#> #   CARBON_AG <dbl>, DRYBIO_AG <dbl>, MACRO_BREAKPOINT_DIA <lgl>,
#> #   INTENSITY <int>, SUBCYCLE <int>, PLOT_STATUS_CD <int>, ECOSUBCD <chr>, …
```
