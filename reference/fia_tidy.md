# Read in and join all required tables

Reads in all the tables needed for carbon estimation and population
scaling and joins them into a single table. Then, some additional data
cleaning steps are performed.

1.  Creates unique tree and plot identifiers (`tree_ID` and `plot_ID`,
    respectively).

2.  Fills in missing values for `ACTUALHT` with values from `HT` to
    prepare for interpolation.

3.  Overwrites `SPCD` with whatever the last value of `SPCD` is for each
    tree (to handle trees that change `SPCD`).

4.  Fills a tree's `MORTYR` column so every row contains the recorded
    mortality year.

5.  Adds `EVALID`-related columns. `EVALID`s are merged such that each
    plot in each `INVYR` is associated with the `EVALID` of each type
    (last two digits) that has the greatest end year. Then, logical
    indicator columns `EVAL_TYPE_EXPVOL` and `EVAL_TYPE_EXPCURR` are
    added along with other columns from various `POP_*` tables suffixed
    with `_EXPVOL` and `_EXPCURR`.

## Usage

``` r
fia_tidy(db)
```

## Arguments

- db:

  a list of tables produced by
  [`fia_load()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_load.md)

## Value

a tibble

## See also

[`fia_add_composite_ids()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_add_composite_ids.md)
