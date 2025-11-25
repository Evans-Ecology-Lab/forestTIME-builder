# Adjust interpolated tables for mortality

This is an "internal" function—most users will want to run
[`fia_annualize()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_annualize.md)
instead. Trees in the input `data_interpolated` already have had their
switch to `STATUSCD` 2 (i.e. death) interpolated to the midpoint
(rounded down) between it's last survey alive and first survey dead.

## Usage

``` r
adjust_mortality(data_interpolated, use_mortyr = TRUE)
```

## Arguments

- data_interpolated:

  tibble created by
  [`interpolate_data()`](https://evans-ecology-lab.github.io/forestTIME/reference/interpolate_data.md)

- use_mortyr:

  logical; use `MORTYR` (if recorded) as the first year a tree was dead?

## Value

a tibble

## Details

This does the following:

- Optionally figures out if a tree has a recorded `MORTYR` and uses that
  for the transition to `STATUSCD` 2 instead of the interpolated values.
  If the tree is alive (`STATUSCD` 1) in `MORTYR`, then it is assumed it
  died in the following year.

- Adjusts `STANDING_DEAD_CD` so that it only applies to dead trees

- Adjusts `DECAYCD` so that it only applies to standing dead trees

- Adjusts `DIA`, `HT`, `ACTUALHT`, `CULL`, and `CR` so that they only
  apply to live or standing dead trees in sampled conitions.
