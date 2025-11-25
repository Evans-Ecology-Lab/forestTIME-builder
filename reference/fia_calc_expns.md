# Add expansion factors (`EXPNS`)

Adds an `EXPNS` column intended to be used in the same way as the
`EXPNS` column in the raw FIA data. It is calculated simply as the state
land area divided by the total number of plots in that state in that
year in the data. This allows it to be used with interpolated data.

## Usage

``` r
fia_calc_expns(data)
```

## Arguments

- data:

  a data frame with at least a `plot_ID` column and a `YEAR` column.

## Value

a tibble
