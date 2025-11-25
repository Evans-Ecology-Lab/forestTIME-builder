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
