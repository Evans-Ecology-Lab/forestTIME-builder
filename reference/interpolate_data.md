# Interpolate expanded tree data

This is an "internal" function—most users will want to run
[`fia_annualize()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_annualize.md)
instead. Fills in `NA`s between survey years with either linear
interpolation / extrapolation or by switching categorical variables at
the midpoint (rounded down) between surveys. Linear
interpolation/extrapolation is accomplished with
[`inter_extra_polate()`](https://evans-ecology-lab.github.io/forestTIME/reference/inter_extra_polate.md)
and the categorical variables are handled with
[`step_interp()`](https://evans-ecology-lab.github.io/forestTIME/reference/step_interp.md).
Also converts temporary `999` values created by
[`expand_data()`](https://evans-ecology-lab.github.io/forestTIME/reference/expand_data.md)
back to `NA`s. This also assigns a value for `TPA_UNADJ` based on
`DESIGNCD` and interpolated values of `DIA` according to Appendix G of
the FIADB user guide.

## Usage

``` r
interpolate_data(data_expanded)
```

## Arguments

- data_expanded:

  tibble produced by
  [`expand_data()`](https://evans-ecology-lab.github.io/forestTIME/reference/expand_data.md)

## Value

a tibble

## Note

If `HT` or `ACTUALHT` are extrapolated to values \< 4.5 (or \< 1 for
woodland species) OR `DIA` is extrapolated to \< 1, the tree is marked
as fallen dead (`STATUSCD` 2 and `STANDING_DEAD_CD` 0). All measurements
for these trees will be removed (set to `NA`) by
[`adjust_mortality()`](https://evans-ecology-lab.github.io/forestTIME/reference/adjust_mortality.md).
Trees with only one measurement have that measurement carried forward as
appropriate (e.g. until fallen and dead or in non-sampled condition).

Since missing values for `CULL` are already assumed to be 0 by
[`fia_estimate()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_estimate.md),
they are converted to 0s by
[`expand_data()`](https://evans-ecology-lab.github.io/forestTIME/reference/expand_data.md)
for better linear interpolation here and then set back to `NA` if `DIA`
\< 5.

## References

Burrill, E.A., Christensen, G.A., Conkling, B.L., DiTommaso, A.M.,
Kralicek, K.M., Lepine, L.C., Perry, C.J., Pugh, S.A., Turner, J.A.,
Walker, D.M., 2024. The Forest Inventory and Analysis Database User
Guide (NFI). USDA Forest Service.
<https://research.fs.usda.gov/understory/forest-inventory-and-analysis-database-user-guide-nfi>
