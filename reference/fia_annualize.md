# Create annualized FIA data

Converts tidied panel data into annualized data with interpolated
measurements for trees for years between inventories. This happens in
three steps, which can be "manually" replicated by chaining other
`forestTIME` functions.

## Usage

``` r
fia_annualize(data_tidy, year_var = c("INVYR", "MEASYEAR"), use_mortyr = TRUE)
```

## Arguments

- data_tidy:

  A tibble produced by
  [`fia_tidy()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_tidy.md).

- year_var:

  character indicating which year variable to use; default is `INVYR`.

- use_mortyr:

  logical; Use `MORTYR` (if recorded) as the first year a tree was dead?
  Passed to
  [`adjust_mortality()`](https://evans-ecology-lab.github.io/forestTIME/reference/adjust_mortality.md).

## Details

First, data is expanded by
[`expand_data()`](https://evans-ecology-lab.github.io/forestTIME/reference/expand_data.md)
to add rows for years between inventories for each tree in the data.
Next, data is interpolated with
[`interpolate_data()`](https://evans-ecology-lab.github.io/forestTIME/reference/interpolate_data.md).
Finally,
[`adjust_mortality()`](https://evans-ecology-lab.github.io/forestTIME/reference/adjust_mortality.md)
is applied. For trees that die and/or fall between inventories, we
adjust their history according either to a recorded `MORTYR` (if
`use_morty = TRUE`) or, as a fall-back, the midpoint between surveys,
rounded down. Unlike these intermediate functions, `fia_annualize()`
produces a dataset which can be safely used for other analyses (with the
caveat that all of this is experimental).

## Note

Most users should use this "wrapper" function rather than running each
step separately since the intermediate steps may contain data artifacts.
However, one reason to use the stepwise workflow would be to save time
when generating interpolated data with and without using `MORTYR` as
[`interpolate_data()`](https://evans-ecology-lab.github.io/forestTIME/reference/interpolate_data.md)
is the slowest step.

## See also

For more details on each step, see:
[`expand_data()`](https://evans-ecology-lab.github.io/forestTIME/reference/expand_data.md),
[`interpolate_data()`](https://evans-ecology-lab.github.io/forestTIME/reference/interpolate_data.md),
[`adjust_mortality()`](https://evans-ecology-lab.github.io/forestTIME/reference/adjust_mortality.md)

## Examples

``` r
if (FALSE) { # \dontrun{
db <- db <- fia_load("RI", dir = system.file("exdata", package = "forestTIME"))
data_tidy <- fia_tidy(db)
data_annualized <- fia_annualize(data_tidy)
} # }
```
