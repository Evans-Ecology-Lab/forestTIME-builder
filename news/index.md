# Changelog

## forestTIME (development version)

- Fixed a bug where for woodland species, carbon was being replaced with
  biomass.
- As part of the workaround for woodland species
  ([\#163](https://github.com/Evans-Ecology-Lab/forestTIME/issues/163)),
  any negative interpolated carbon and biomass values were set to 0.

## forestTIME 2.2.0

- The internal function
  [`fia_eval_info()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_eval_info.md)
  was added.
- [`fia_assign_strata()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_assign_strata.md)
  was added to match plots in each year of the annualized data to an
  EVALID, estimation unit, and stratum along with associated values
  necessary for population level estimation with variance calculations.
- [`fia_tidy()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_tidy.md)
  now adds several columns from the POP\_\* tables relating to EVALIDs.
  Each plot in each INVYR is matched to the EVALID of each type that has
  the latest end year. Then, for EVALIDs ending in 01 and 02 (“EXPCURR”
  and “EXPVOL”, respectively), two columns are created for each of
  EVALID, ESTN_UNIT, STRATUMCD, P1POINTCNT, P1PNTCNT_EU, and AREA_USED
  suffixed with \_EXPVOL or \_EXPCURR. There are also two logical
  columns EVAL_TYPE_EXPCURR and EVAL_TYPE_EXPVOL. These get filled down
  and switch at the next inventory (rather than at the midpoint like
  everything else)
  ([\#192](https://github.com/Evans-Ecology-Lab/forestTIME/issues/192)).
- [`fia_tidy()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_tidy.md)
  no longer filters to base intensity plots and reverts to just
  filtering to `INVYR≥2000`.
- Changeed the way composit IDs `plot_ID` and `tree_ID` are constructed
  by changing the order of STATECD and UNITCD so that now it is
  UNITCD_STATECD_COUNTYCD_PLOT
  ([\#189](https://github.com/Evans-Ecology-Lab/forestTIME/issues/189))
- Fixed a bug in
  [`fia_tidy()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_tidy.md)
  resulting in duplicated `SUBCYCLE` columns
  ([\#173](https://github.com/Evans-Ecology-Lab/forestTIME/issues/173)).
- A temporary workaround was implmented to deal with missing code for
  calculating biomass and carbon for woodland species
  ([\#163](https://github.com/Evans-Ecology-Lab/forestTIME/issues/163)).
  Eventually, we will modify
  [`fia_estimate()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_estimate.md)
  to be able to produce carbon and biomass estimates for woodland
  species and this can be reverted to avoid confusion.
  - [`fia_tidy()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_tidy.md)
    now keeps the `CARBON_AG` and `DRYBIO_AG` columns
  - [`interpolate_data()`](https://evans-ecology-lab.github.io/forestTIME/reference/interpolate_data.md)
    (and therefore
    [`fia_annualize()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_annualize.md))
    now linearly interpolates `CARBON_AG` and `DRYBIO_AG`
  - [`fia_estimate()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_estimate.md)
    now overwrites `CARBON_AG` and `DRYBIO_AG` columns in the input
    unless the result of carbon estimation is `NA` (as is the case with
    woodland species).
- The calculation of the `EXPNS` column no longer occurs as part of
  [`interpolate_data()`](https://evans-ecology-lab.github.io/forestTIME/reference/interpolate_data.md).

## forestTIME 2.1.0

- This package has been re-named from `forestTIME.builder` to
  `forestTIME`
- [`fia_tidy()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_tidy.md)
  now only keeps base-intensity plots
  (`INTENSITY == 1 & SUBCYCLE != 99 & SUBCYCLE != 0`).
- Fixed a bug that was causing `TPA_UNADJ` to not be populated for all
  trees in states that use macroplots
  ([\#160](https://github.com/Evans-Ecology-Lab/forestTIME/issues/160)).
- Fixed a bug in
  [`fia_split_composite_ids()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_split_composite_ids.md)
  that caused it to fail when `tree_ID` was `NA` (as it is in conditions
  with no observations). It now falls back on the information in
  `plot_ID` when `tree_ID` is in the data frame but `NA`
  ([\#149](https://github.com/Evans-Ecology-Lab/forestTIME/issues/149)).
- [`fia_estimate()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_estimate.md)
  now returns the additional variables `DRIBIO_FOLIAGE`, `VOLTSGRS`, and
  `VOLTSSND` in addition to `DRYBIO_AG` and `CARBON_AG`.
- Code to deal with negative extrapolated values has moved to
  [`adjust_mortality()`](https://evans-ecology-lab.github.io/forestTIME/reference/adjust_mortality.md).
  Therefore, the results of
  [`interpolate_data()`](https://evans-ecology-lab.github.io/forestTIME/reference/interpolate_data.md)
  may now contain negative numbers, which are non-sensible. Use
  [`fia_annualize()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_annualize.md)
  whenever possible to ensure sensible results.
- [`fia_download()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_download.md)
  arguments have changed. `keep_zip` now defaults to `TRUE`. `extract`
  options have changed from `TRUE`/`FALSE` to `"forestTIME"`, `"rFIA"`,
  `"all"`, or `"none"` to extract just files needed by `forestTIME`,
  those used by `rFIA` (for compatibility), all files, or none.
- Fixed a bug in interpolation of `CONDPROP_UNAJ`. Now the workflow
  retains all “empty” conditions (i.e. `CONDID`s with no trees in them)
  and properly interpolates `CONDPROP_UNADJ` so the proportion for all
  conditions in a plot in a year sum to 1 (within rounding error)
  ([\#64](https://github.com/Evans-Ecology-Lab/forestTIME/issues/64)).
- [`fia_annualize()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_annualize.md)
  now adds and `EXPNS` column calculated as the total land area of the
  state in acres divided by the number of plots in the interpolated
  data. It *should* be usable in the same ways the `EXPNS` column in the
  “raw” FIA data can be used.
- Renames the `state_codes` dataset to `state_areas` and adds a column
  for state land area in acres.
