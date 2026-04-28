# Add composite ID columns to data

Creates a `tree_ID` and/or a `plot_ID` column that contain unique tree
and plot identifiers, respectively. These are created by pasting
together the values for `UNITCD`, `STATECD`, `COUNTYCD`, `PLOT` and in
the case of trees `SUBP` and `TREE`.

## Usage

``` r
fia_add_composite_ids(data)
```

## Arguments

- data:

  A tibble or data frame with at least the `UNITCD`, `STATECD`,
  `COUNTYCD` and `PLOT` columns

## Value

The input tibble with a `plot_ID` and possibly also a `tree_ID` column
added

## See also

See
[`fia_split_composite_ids()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_split_composite_ids.md)
for "undoing" this.

## Examples

``` r
db <- fia_load("RI", dir = system.file("exdata", package = "forestTIME"))
#> Warning: replacing previous import ‘bit64::setdiff’ by ‘dplyr::setdiff’ when loading ‘rFIA’
#> Warning: replacing previous import ‘bit64::intersect’ by ‘dplyr::intersect’ when loading ‘rFIA’
#> Warning: replacing previous import ‘bit64::union’ by ‘dplyr::union’ when loading ‘rFIA’
#> Warning: replacing previous import ‘bit64::setequal’ by ‘dplyr::setequal’ when loading ‘rFIA’
fia_add_composite_ids(db$TREE)
#> # A tibble: 22,707 × 196
#>    plot_ID  tree_ID         CN  PLT_CN PREV_TRE_CN INVYR STATECD UNITCD COUNTYCD
#>    <chr>    <chr>        <dbl>   <dbl>       <dbl> <int>   <int>  <int>    <int>
#>  1 1_44_1_1 1_44_1_1_… 1.02e13 1.02e13          NA  1985      44      1        1
#>  2 1_44_1_1 1_44_1_1_… 1.02e13 1.02e13          NA  1985      44      1        1
#>  3 1_44_1_1 1_44_1_1_… 1.02e13 1.02e13          NA  1985      44      1        1
#>  4 1_44_1_1 1_44_1_1_… 1.02e13 1.02e13          NA  1985      44      1        1
#>  5 1_44_1_1 1_44_1_1_… 1.02e13 1.02e13          NA  1985      44      1        1
#>  6 1_44_1_1 1_44_1_1_… 1.02e13 1.02e13          NA  1985      44      1        1
#>  7 1_44_1_1 1_44_1_1_… 1.02e13 1.02e13          NA  1985      44      1        1
#>  8 1_44_1_1 1_44_1_1_… 1.02e13 1.02e13          NA  1985      44      1        1
#>  9 1_44_1_1 1_44_1_1_… 1.02e13 1.02e13          NA  1985      44      1        1
#> 10 1_44_1_1 1_44_1_1_… 1.02e13 1.02e13          NA  1985      44      1        1
#> # ℹ 22,697 more rows
#> # ℹ 187 more variables: PLOT <int>, SUBP <int>, TREE <int>, CONDID <int>,
#> #   PREVCOND <int>, STATUSCD <int>, SPCD <dbl>, SPGRPCD <int>, DIA <dbl>,
#> #   DIAHTCD <int>, HT <int>, HTCD <int>, ACTUALHT <int>, TREECLCD <int>,
#> #   CR <int>, CCLCD <int>, TREEGRCD <int>, AGENTCD <int>, CULL <int>,
#> #   DAMLOC1 <int>, DAMTYP1 <int>, DAMSEV1 <int>, DAMLOC2 <int>, DAMTYP2 <int>,
#> #   DAMSEV2 <int>, DECAYCD <int>, STOCKING <dbl>, WDLDSTEM <lgl>, …
```
