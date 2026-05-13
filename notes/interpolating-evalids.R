load_all()
library(tidyverse)
db <- fia_load(
  "DE",
  dir = system.file("exdata", package = "forestTIME")
)
data_annualized <- db |>
  fia_tidy() |>
  fia_annualize(use_mortyr = FALSE) |>
  fia_allometry()

# Create pop info, left join to annualized data, interpolate with midpt switch

POP_PLOT_STRATUM_ASSGN <- db$POP_PLOT_STRATUM_ASSGN |>
  fia_add_composite_ids() |>
  dplyr::select(plot_ID, INVYR, EVALID, ESTN_UNIT, STRATUMCD) |>
  dplyr::distinct()

POP_STRATUM <- db$POP_STRATUM |>
  dplyr::select(EVALID, ESTN_UNIT, STRATUMCD, P1POINTCNT) |>
  dplyr::distinct()

POP_ESTN_UNIT <- db$POP_ESTN_UNIT |>
  dplyr::select(EVALID, ESTN_UNIT, P1PNTCNT_EU, AREA_USED)

POP_EVAL <- db$POP_EVAL |>
  dplyr::select(
    EVAL_CN = CN,
    EVAL_GRP_CN,
    EVALID,
    START_INVYR,
    END_INVYR,
    EVAL_DESCR
  ) |>
  dplyr::mutate(dplyr::across(dplyr::ends_with("CN"), as.character))

POP_EVAL_TYP <- db$POP_EVAL_TYP |>
  dplyr::select(EVAL_GRP_CN, EVAL_CN, EVAL_TYP) |>
  dplyr::mutate(dplyr::across(dplyr::ends_with("CN"), as.character)) |>
  summarize(
    .by = c(EVAL_GRP_CN, EVAL_CN),
    EXPCURR = any(EVAL_TYP == "EXPCURR"),
    EXPVOL = any(EVAL_TYP == "EXPVOL")
  )

pop_eval_type <- full_join(
  POP_EVAL,
  POP_EVAL_TYP,
  by = join_by(EVAL_CN, EVAL_GRP_CN)
) |>
  select(EVALID, START_INVYR, END_INVYR, EVAL_DESCR, EXPCURR, EXPVOL)

pop_info <- POP_PLOT_STRATUM_ASSGN |>
  left_join(
    POP_STRATUM,
    by = join_by(EVALID, ESTN_UNIT, STRATUMCD)
  ) |>
  left_join(POP_ESTN_UNIT, by = join_by(EVALID, ESTN_UNIT)) |>
  left_join(pop_eval_type, by = join_by(EVALID)) |>
  # filter(EXPCURR | EXPVOL) |>
  arrange(plot_ID, INVYR)

# Every **YEAR** must have the same definition of strata and estimation units
# for this to be useful, so that means we need to pick a common `END_INVYR`
# for every `INVYR` **across** plots.

# TODO: Actually, not sure the above is true.  We could instead choose EVALIDs
# at a plot level, such that we pick the earliest common `END_INVYR` per plot
# per year, which could potentially capture more plots.

# For each INVYR, choose the END_INVYR with the most plots in either eval
# type that is closest to the INVYR.

# all the plots within a year should have the same EVALID (not sure that's true)

yrs_to_choose <- pop_info |>
  dplyr::mutate(
    END_INVYR_EXPCURR = dplyr::if_else(EXPCURR, END_INVYR, NA),
    END_INVYR_EXPVOL = dplyr::if_else(EXPVOL, END_INVYR, NA)
  ) |>
  dplyr::group_by(INVYR, END_INVYR) |>
  dplyr::summarize(
    n = sum(
      END_INVYR_EXPCURR == END_INVYR & END_INVYR_EXPVOL == END_INVYR,
      na.rm = TRUE
    )
  ) |>
  dplyr::group_by(INVYR) |>
  dplyr::filter(n == max(n)) |>
  dplyr::filter(END_INVYR == min(END_INVYR))


pop_info_long <-
  # filtering join so only one row per INVYR x plot_ID x eval type
  right_join(pop_info, yrs_to_choose, by = join_by(INVYR, END_INVYR))


pop_info_wide <- pop_info_long |>
  dplyr::mutate(
    eval_type = dplyr::case_when(
      EXPCURR ~ "EXPCURR",
      EXPVOL ~ "EXPVOL"
    )
  ) |>
  dplyr::select(
    plot_ID,
    INVYR,
    EVALID,
    ESTN_UNIT,
    STRATUMCD,
    P1POINTCNT,
    P1PNTCNT_EU,
    AREA_USED,
    eval_type
  ) |>
  tidyr::pivot_wider(
    names_from = eval_type,
    values_from = c(
      EVALID,
      ESTN_UNIT,
      STRATUMCD,
      P1POINTCNT,
      P1PNTCNT_EU,
      AREA_USED
    )
  ) |>
  dplyr::mutate(
    EXPCURR = !is.na(EVALID_EXPCURR),
    EXPVOL = !is.na(EVALID_EXPVOL)
  ) |>
  dplyr::select(
    plot_ID,
    INVYR,
    EVALID_EXPCURR,
    EVALID_EXPVOL,
    ESTN_UNIT = ESTN_UNIT_EXPCURR,
    STRATUMCD = STRATUMCD_EXPCURR,
    P1POINTCNT = P1POINTCNT_EXPCURR,
    P1PNTCNT_EU = P1PNTCNT_EU_EXPCURR,
    AREA_USED = AREA_USED_EXPCURR,
    EXPCURR,
    EXPVOL
  ) |>
  dplyr::arrange(plot_ID, INVYR)

per_plot_year <- pop_info_wide |> count(plot_ID, INVYR) |> filter(n > 1)
if (nrow(per_plot_year) > 0) {
  cli::cli_abort(
    "More than one EVALID per plot x year x eval type was chosen!"
  )
}

# complete the data frame so it has all inventory years for all plots

pop_info_complete <- pop_info_wide |>
  tidyr::complete(tidyr::nesting(
    plot_ID = pop_info$plot_ID,
    INVYR = pop_info$INVYR
  ))
pop_info_complete


# join with annualized data and interpolate

pop_info_prepped <- pop_info_complete |>
  dplyr::mutate(dplyr::across(dplyr::where(is.numeric), function(x) {
    tidyr::replace_na(x, -999)
  })) |>
  dplyr::rename(YEAR = INVYR)

eval_cols <- c(
  "EVALID_EXPCURR",
  "EVALID_EXPVOL",
  "ESTN_UNIT",
  "STRATUMCD",
  "P1POINTCNT",
  "P1PNTCNT_EU",
  "AREA_USED",
  "EXPCURR",
  "EXPVOL"
)

data_with_pop_info <- dplyr::left_join(
  data_annualized,
  pop_info_prepped,
  by = dplyr::join_by(plot_ID, YEAR)
) |>
  dplyr::group_by(tree_ID) |>
  dplyr::arrange(YEAR) |>
  dplyr::mutate(dplyr::across(dplyr::all_of(eval_cols), step_interp)) |>
  dplyr::mutate(dplyr::across(
    dplyr::all_of(eval_cols[!eval_cols %in% c("EXPCURR", "EXPVOL")]),
    \(x) dplyr::na_if(x, -999)
  )) |>
  dplyr::ungroup() |>
  # Calculate P2POINTCNT as the number of plots in each stratum in each year
  # with an EXPCURR eval type
  dplyr::mutate(
    # Must include EVALID because the same ESTN_UNIT could mean different
    # things in different EVALIDs I think.
    .by = c(YEAR, EVALID_EXPCURR, ESTN_UNIT, STRATUMCD),
    P2POINTCNT = length(unique(plot_ID[EXPCURR]))
  )

data_with_pop_info


# plot lat and lon for visualization
plot_loc <- db$PLOTGEOM |>
  fia_add_composite_ids() |>
  select(plot_ID, LAT, LON) |>
  distinct() |> #unfortunately LAT and LON seem to change so we'll get the mean for now
  summarize(.by = plot_ID, across(c(LAT, LON), mean))

# These are the definitions we chose for ESTN_UNIT for each INVYR (in the raw data)
pop_info_complete |>
  left_join(plot_loc) |>
  filter(INVYR >= 2004) |>
  ggplot(aes(x = LON, y = LAT, color = factor(ESTN_UNIT))) +
  facet_wrap(vars(INVYR)) +
  geom_point(alpha = 0.2)

# This shows how they overlap after annualization
data_complete |>
  filter(!is.na(ESTN_UNIT)) |>
  left_join(plot_loc) |>
  group_by(YEAR, plot_ID, LAT, LON, ESTN_UNIT) |>
  summarize(LON = unique(LON), LAT = unique(LAT)) |>
  filter(YEAR >= 2004) |>
  ggplot(aes(x = LON, y = LAT, color = factor(ESTN_UNIT))) +
  facet_wrap(vars(YEAR)) +
  geom_point(alpha = 0.2)
