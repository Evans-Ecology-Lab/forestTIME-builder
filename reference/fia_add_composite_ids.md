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
