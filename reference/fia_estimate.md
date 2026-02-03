# Estimate biomass and carbon using NSVB framework

Estimates biomass and carbon variables using the National Scale Volume
and Biomass estimators (NSVB).

## Usage

``` r
fia_estimate(data)
```

## Arguments

- data:

  A data frame or tibble; generally the output of
  [`fia_annualize()`](https://evans-ecology-lab.github.io/forestTIME/reference/fia_annualize.md).

## Value

A tibble with the additional columns `DRYBIO_AG` and `CARBON_AG` that
correspond to the FIAdb definitions of those variables.

## References

Westfall, J.A., Coulston, J.W., Gray, A.N., Shaw, J.D., Radtke, P.J.,
Walker, D.M., Weiskittel, A.R., MacFarlane, D.W., Affleck, D.L.R., Zhao,
D., Temesgen, H., Poudel, K.P., Frank, J.M., Prisley, S.P., Wang, Y.,
Sánchez Meador, A.J., Auty, D., Domke, G.M., 2024. A national-scale tree
volume, biomass, and carbon modeling system for the United States. U.S.
Department of Agriculture, Forest Service.
[doi:10.2737/wo-gtr-104](https://doi.org/10.2737/wo-gtr-104)

## Author

David Walker

## Examples

``` r
if (FALSE) { # \dontrun{
library(forestTIME)
db <- fia_load("RI")
data_tidy <- fia_tidy(db)
data_annualized <- fia_annualize(data_tidy)
data_carbon <- fia_estimate(data_annualized)
} # }

```
