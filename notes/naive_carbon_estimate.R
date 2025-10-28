library(forestTIME)
library(tidyverse)
library(units) # helps with unit conversions

# standard annualization workflow (could read in parquet file instead)
db <- fia_load("RI")
data_tidy <- fia_tidy(db)
data_annualized <- fia_annualize(data_tidy)

# We'll need this later
state_area <- state_areas |>
  filter(state_abb == "RI") |>
  pull(state_land_area) |>
  set_units("acres")

plot_radius <- set_units(24, "ft")
plot_area <- pi * plot_radius^2 |> set_units("acres")

# What if plots were a random sample of the total area of the state? Because
# *every* tree is measured in each plot, we can calculate tons of carbon per
# acre by simply adding up the carbon of all the trees in each plot and dividing
# by the area of the plot. Then we can estimate carbon per acre for the state by
# just taking a mean across plots for each year.

naive <- data_annualized |>
  group_by(plot_ID, YEAR) |> # For every plot in every year...
  summarize(
    # get total carbon in tons
    total_carbon = set_units(CARBON_AG, "lb") |>
      set_units("tons") |>
      sum(na.rm = TRUE)
  ) |>
  mutate(
    # Divide by plot area to get carbon tons/acre
    carbon_per_acre = total_carbon / plot_area
  ) |>
  group_by(YEAR) |> # Then, for every year...
  summarize(
    # Get mean carbon tons/acre
    carbon_per_acre = mean(carbon_per_acre)
  ) |>
  mutate(
    # Estimate total carbon in the state by multiplying by the area of the state
    carbon_total = carbon_per_acre * state_area
  ) |>
  # convert everything with units to just plain numeric for easier plotting
  mutate(across(c(carbon_per_acre, carbon_total), drop_units))

naive

# How does this compare to rFIA?

library(rFIA)

db2 <- rFIA::readFIA(dir = "fia", states = "RI")
rfia_annual <- biomass(
  db2,
  treeType = "all",
  method = "annual",
  totals = TRUE
)

library(ggplot2)

ggplot() +
  geom_line(
    data = naive,
    aes(x = YEAR, y = carbon_per_acre, color = "random sample mean")
  ) +
  geom_line(data = rfia_annual, aes(x = YEAR, y = CARB_ACRE, color = "rFIA"))

ggplot() +
  geom_line(
    data = naive,
    aes(x = YEAR, y = carbon_total, color = "random sample mean")
  ) +
  geom_line(data = rfia_annual, aes(x = YEAR, y = CARB_TOTAL, color = "rFIA"))

# Pretty different!

# What if we did this without interpolation?
naive2 <- data_tidy |>
  group_by(plot_ID, INVYR) |> # For every plot in every year...
  summarize(
    # get total carbon in tons
    total_carbon = set_units(CARBON_AG, "lb") |>
      set_units("tons") |>
      sum(na.rm = TRUE)
  ) |>
  mutate(
    # Divide by plot area to get carbon tons/acre
    carbon_per_acre = total_carbon / plot_area
  ) |>
  group_by(INVYR) |> # Then, for every year...
  summarize(
    # Get mean carbon tons/acre
    carbon_per_acre = mean(carbon_per_acre)
  ) |>
  mutate(
    # Estimate total carbon in the state by multiplying by the area of the state
    carbon_total = carbon_per_acre * state_area
  ) |>
  # convert everything with units to just plain numeric for easier plotting
  mutate(across(c(carbon_per_acre, carbon_total), drop_units))

ggplot() +
  geom_line(
    data = naive,
    aes(x = YEAR, y = carbon_per_acre, color = "random sample mean")
  ) +
  geom_line(data = rfia_annual, aes(x = YEAR, y = CARB_ACRE, color = "rFIA")) +
  geom_line(
    data = naive2,
    aes(
      x = INVYR,
      y = carbon_per_acre,
      color = "random sample mean, no interpolation"
    )
  )

ggplot() +
  geom_line(
    data = naive,
    aes(x = YEAR, y = carbon_total, color = "random sample mean")
  ) +
  geom_line(data = rfia_annual, aes(x = YEAR, y = CARB_TOTAL, color = "rFIA")) +
  geom_line(
    data = naive2,
    aes(
      x = INVYR,
      y = carbon_total,
      color = "random sample mean, no interpolation"
    )
  )
