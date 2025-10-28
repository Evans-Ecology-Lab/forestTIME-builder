library(forestTIME)
library(tidyverse)
# db <- rFIA::readFIA(dir = "fia", states = "RI")
db <- fia_load("RI")

# The start of fia_tidy():
PLOTGEOM <-
  db$PLOTGEOM |>
  dplyr::mutate(CN = as.character(CN)) |>
  dplyr::select(PLT_CN = CN, INVYR, ECOSUBCD)

PLOT <-
  db$PLOT |>
  dplyr::mutate(CN = as.character(CN)) |>
  fia_add_composite_ids() |>
  dplyr::select(
    plot_ID,
    PLT_CN = CN,
    INVYR,
    MACRO_BREAKPOINT_DIA, #for assigning TPA_UNADJ
    INTENSITY,
    SUBCYCLE
  )

COND <-
  db$COND |>
  dplyr::mutate(PLT_CN = as.character(PLT_CN)) |>
  fia_add_composite_ids() |>
  dplyr::select(
    plot_ID,
    PLT_CN,
    INVYR,
    CONDID,
    CONDPROP_UNADJ,
    PROP_BASIS, #for assigning TPA_UNADJ
    COND_STATUS_CD,
    STDORGCD
  )

TREE <-
  db$TREE |>
  dplyr::mutate(PLT_CN = as.character(PLT_CN)) |>
  fia_add_composite_ids() |>
  dplyr::select(
    plot_ID,
    tree_ID,
    INVYR,
    PLT_CN,
    CONDID,
    MORTYR,
    STATUSCD,
    RECONCILECD,
    DECAYCD,
    STANDING_DEAD_CD,
    DIA,
    CR,
    HT,
    ACTUALHT,
    CULL,
    SPCD,
    # Temporary workaround for woodland species is to linearly interpolate
    # carbon and biomass rather than re-calculated it.
    # TODO: Eventually remove these columns to avoid confusing users.
    CARBON_AG,
    DRYBIO_AG
  )

data <-
  COND |>
  dplyr::as_tibble() |>
  dplyr::left_join(
    TREE,
    by = dplyr::join_by(plot_ID, PLT_CN, CONDID, INVYR)
  ) |>
  dplyr::left_join(PLOT, by = dplyr::join_by(plot_ID, PLT_CN, INVYR)) |>
  dplyr::left_join(PLOTGEOM, by = dplyr::join_by(INVYR, PLT_CN))

# Instead of filtering to keep only INTENSITY == 1 & !SUBCYCLE %in% c(99, 00),
# keep only plots with EVALIDs that end in "01"

expcurr_plots <-
  db$POP_PLOT_STRATUM_ASSGN |>
  filter(str_detect(EVALID, "01$")) |>
  fia_add_composite_ids() |>
  pull(plot_ID) |>
  unique()

length(expcurr_plots) # 437 plots

# How many plots per year? (this is what we currently use for calculating our
# EXPNS)

data |>
  filter(plot_ID %in% expcurr_plots) |>
  group_by(INVYR) |>
  summarize(n_plots = length(unique(plot_ID)))

# Unfortunately these are not the numbers we are looking for to calculate EXPNS.
# The number we need is the total number of plots *in an EVALID* which spans
# multiple years, not the total number of plots in each INVYR.  It still leaves
# the question of what the equivalent to an EVALID is for interpolated data or
# if this approach even makes sense for annualized data.
