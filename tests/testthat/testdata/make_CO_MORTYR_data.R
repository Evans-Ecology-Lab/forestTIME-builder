load_all()
library(dplyr)
CO_data <- fia_load("CO") |> fia_tidy()
CO_subset <- CO_data |>
  filter(
    tree_ID %in%
      c(
        "1_8_119_80086_3_12", # alive in MORTYR
        "1_8_119_85646_4_1", # dead in MORTYR
        "1_8_41_89994_2_15" # woodland sp
      )
  ) |>
  expand_data() |>
  interpolate_data()

saveRDS(CO_subset, testthat::test_path("testdata/CO_MORTYR.rds"))
