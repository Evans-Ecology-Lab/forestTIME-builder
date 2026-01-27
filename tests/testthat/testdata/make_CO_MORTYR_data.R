load_all()
library(dplyr)
CO_data <- fia_load("CO") |> fia_tidy()
CO_interpolated <- CO_data |>
  filter(
    tree_ID %in%
      c(
        "1_8_119_80086_3_12", # alive in MORTYR
        "1_8_119_85646_4_1" # dead in MORTYR
      )
  ) |>
  expand_data() |>
  interpolate_data()
CO_subset <-
  CO_interpolated |>
  select(
    plot_ID,
    tree_ID,
    YEAR,
    MORTYR,
    interpolated,
    DIA,
    HT,
    ACTUALHT,
    CR,
    CULL,
    STATUSCD,
    STANDING_DEAD_CD,
    DECAYCD,
    RECONCILECD,
    COND_STATUS_CD,
    CARBON_AG,
    DRYBIO_AG,
    SPCD
  )

saveRDS(CO_subset, testthat::test_path("testdata/CO_MORTYR.rds"))
