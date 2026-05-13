#' Scale interpolated tree-level biometric data to tree-level biomass and carbon using NSVB framework
#'
#' Estimates tree-level biomass and carbon variables using the National Scale Volume and
#' Biomass allometric equations (NSVB).
#'
#' @param data A data frame or tibble; generally the output of [fia_annualize()].
#'
#' @author David Walker
#' @references Westfall, J.A., Coulston, J.W., Gray, A.N., Shaw, J.D., Radtke,
#' P.J., Walker, D.M., Weiskittel, A.R., MacFarlane, D.W., Affleck, D.L.R.,
#' Zhao, D., Temesgen, H., Poudel, K.P., Frank, J.M., Prisley, S.P., Wang, Y.,
#' Sánchez Meador, A.J., Auty, D., Domke, G.M., 2024. A national-scale tree
#' volume, biomass, and carbon modeling system for the United States. U.S.
#' Department of Agriculture, Forest Service. \doi{doi:10.2737/wo-gtr-104}
#'
#' @returns A tibble with the additional columns `DRYBIO_AG` and `CARBON_AG`
#' that correspond to the FIAdb definitions of those variables.
#'
#' @examples
#' \dontrun{
#' library(forestTIME)
#' db <- fia_load("RI")
#' data_tidy <- fia_tidy(db)
#' data_annualized <- fia_annualize(data_tidy)
#' data_carbon <- fia_allometry(data_annualized)
#' }
#'
#'
#' @export
fia_allometry <- function(data) {
  data |>
    prep_carbon() |>
    tree_allometry()
}
