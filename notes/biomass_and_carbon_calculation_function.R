# fmt: skip
biomass_carbon_calc <- function(i_spcd, i_dia, i_diahtcd, i_volcfsnd){
  
  if( !exists("ref_species_table") ){
    stop("You must have the FIA ref_species table as a tibble object named \"ref_species_table\" in the global environment")
  }
  
  tree_data <- bind_cols(ref_species_table %>%
                           filter(spcd == i_spcd),
                         tibble(dia = i_dia,
                                diahtcd = i_diahtcd,
                                volcfsnd = i_volcfsnd)) %>% 
    mutate(calc_type = case_when(dia < 5 & (is.na(woodland) | woodland == "") & diahtcd == 1  ~ "sapling",
                                 dia < 5 & woodland == "X" & diahtcd == 1                     ~ "sapling",
                                 dia < 5 & woodland == "X" & diahtcd == 2                     ~ "wdld_sapling",
                                 dia >= 5 & woodland == "X" & diahtcd == 1                    ~ "tree",
                                 dia >= 5 & woodland == "X" & diahtcd == 2                    ~ "wdld_tree",
                                 dia >= 5 & (is.na(woodland) | woodland == "") & diahtcd == 2 ~ "wdld_tree",
                                 TRUE                                                         ~ "tree"))
  
  switch(tree_data$calc_type,
         
         "sapling" = tree_data %>% 
           mutate(total_AG_biomass_Jenkins = exp(jenkins_total_b1 + jenkins_total_b2 * log(dia * 2.54)) * 2.2046,
                  foliage_ratio = exp(jenkins_foliage_ratio_b1 + jenkins_foliage_ratio_b2 / (dia * 2.54)),
                  root_ratio = exp(jenkins_root_ratio_b1 + jenkins_root_ratio_b2 / (dia * 2.54))) %>%
           mutate(calc_drybio_bole = NA_real_,
                  calc_drybio_top = NA_real_,
                  calc_drybio_stump = NA_real_,
                  calc_drybio_sapling = (total_AG_biomass_Jenkins - (total_AG_biomass_Jenkins * foliage_ratio)) * jenkins_sapling_adjustment,
                  calc_drybio_wdld_spp = NA_real_,
                  calc_drybio_bg = total_AG_biomass_Jenkins * root_ratio * jenkins_sapling_adjustment,
                  calc_foliage_biomass = total_AG_biomass_Jenkins * foliage_ratio * jenkins_sapling_adjustment),
         
         "wdld_sapling" = tree_data %>% 
           mutate(total_AG_biomass_Jenkins = exp(jenkins_total_b1 + jenkins_total_b2 * log(dia * 2.54)) * 2.2046,
                  foliage_ratio = exp(jenkins_foliage_ratio_b1 + jenkins_foliage_ratio_b2 / (dia * 2.54)),
                  root_ratio = exp(jenkins_root_ratio_b1 + jenkins_root_ratio_b2 / (dia * 2.54))) %>%
           mutate(calc_drybio_bole = NA_real_,
                  calc_drybio_top = NA_real_,
                  calc_drybio_stump = NA_real_,
                  calc_drybio_sapling = NA_real_,
                  calc_drybio_wdld_spp = (total_AG_biomass_Jenkins - (total_AG_biomass_Jenkins * foliage_ratio)) * jenkins_sapling_adjustment,
                  calc_drybio_bg = total_AG_biomass_Jenkins * root_ratio * jenkins_sapling_adjustment,
                  calc_foliage_biomass = total_AG_biomass_Jenkins * foliage_ratio * jenkins_sapling_adjustment),
         
         "wdld_tree" = tree_data %>% 
           mutate(total_AG_biomass_Jenkins = exp(jenkins_total_b1 + jenkins_total_b2 * log(dia * 2.54)) * 2.2046,
                  foliage_ratio = exp(jenkins_foliage_ratio_b1 + jenkins_foliage_ratio_b2 / (dia * 2.54)),
                  root_ratio = exp(jenkins_root_ratio_b1 + jenkins_root_ratio_b2 / (dia * 2.54))) %>%
           mutate(foliage_biomass_Jenkins = total_AG_biomass_Jenkins * foliage_ratio,
                  root_biomass_Jenkins = total_AG_biomass_Jenkins * root_ratio) %>% 
           mutate(calc_drybio_wdld_spp = (volcfsnd * (bark_vol_pct / 100) * (bark_spgr_greenvol_drywt * 62.4)) + 
                    ((volcfsnd - (volcfsnd * (bark_vol_pct / 100))) * (wood_spgr_greenvol_drywt * 62.4))) %>% 
           mutate(CRMadj = calc_drybio_wdld_spp/(total_AG_biomass_Jenkins - foliage_biomass_Jenkins)) %>%
           mutate(calc_drybio_bole = NA_real_,
                  calc_drybio_top = NA_real_,
                  calc_drybio_stump = NA_real_,
                  calc_drybio_sapling = NA_real_,
                  calc_drybio_bg = root_biomass_Jenkins * CRMadj,
                  calc_foliage_biomass = foliage_biomass_Jenkins),
         
         "tree" = tree_data %>% 
           mutate(total_AG_biomass_Jenkins = exp(jenkins_total_b1 + jenkins_total_b2 * log(dia * 2.54)) * 2.2046,
                  stem_ratio = exp(jenkins_stem_wood_ratio_b1 + jenkins_stem_wood_ratio_b2 / (dia * 2.54)),
                  bark_ratio = exp(jenkins_stem_bark_ratio_b1 + jenkins_stem_bark_ratio_b2 / (dia * 2.54)),
                  foliage_ratio = exp(jenkins_foliage_ratio_b1 + jenkins_foliage_ratio_b2 / (dia * 2.54)),
                  root_ratio = exp(jenkins_root_ratio_b1 + jenkins_root_ratio_b2 / (dia * 2.54))) %>%
           mutate(stem_biomass_Jenkins = total_AG_biomass_Jenkins * stem_ratio,
                  bark_biomass_Jenkins = total_AG_biomass_Jenkins * bark_ratio) %>% 
           mutate(bole_biomass_Jenkins = stem_biomass_Jenkins + bark_biomass_Jenkins,
                  foliage_biomass_Jenkins = total_AG_biomass_Jenkins * foliage_ratio,
                  root_biomass_Jenkins = total_AG_biomass_Jenkins * root_ratio) %>% 
           mutate(stump_vosb = (pi * dia^2)/(4*144) * 
                    (((1 - raile_stump_dob_b1)^2 * 1 + 11 * raile_stump_dob_b1 * (1 - raile_stump_dob_b1) * log(1 + 1) - (30.25/(1 + 1)) * raile_stump_dob_b1^2) - 
                       ((1 - raile_stump_dob_b1)^2 * 0 + 11 * raile_stump_dob_b1 * (1 - raile_stump_dob_b1) * log(0 + 1) - (30.25/(0 + 1)) * raile_stump_dob_b1^2)),
                  stump_visb = (pi * dia^2)/(4*144) * 
                    (((raile_stump_dib_b1 - raile_stump_dib_b2)^2 * 1 + 11 * raile_stump_dib_b2 * (raile_stump_dib_b1 - raile_stump_dib_b2) * log(1 + 1) - (30.25/(1 + 1)) * raile_stump_dib_b2^2) - 
                       ((raile_stump_dib_b1 - raile_stump_dib_b2)^2 * 0 + 11 * raile_stump_dib_b2 * (raile_stump_dib_b1 - raile_stump_dib_b2) * log(0 + 1) - (30.25/(0 + 1)) * raile_stump_dib_b2^2))) %>% 
           mutate(stump_biomass_Raile = (stump_visb * wood_spgr_greenvol_drywt * 62.4) + ((stump_vosb - stump_visb) * bark_spgr_greenvol_drywt * 62.4)) %>% 
           mutate(top_biomass_Jenkins = total_AG_biomass_Jenkins - bole_biomass_Jenkins - foliage_biomass_Jenkins - stump_biomass_Raile) %>% 
           mutate(calc_drybio_bole = (volcfsnd * wood_spgr_greenvol_drywt * 62.4) + 
                    (volcfsnd * (bark_vol_pct/100) * bark_spgr_greenvol_drywt * 62.4)) %>%
           mutate(CRMadj = calc_drybio_bole/bole_biomass_Jenkins) %>%
           mutate(calc_drybio_top = top_biomass_Jenkins * CRMadj,
                  calc_drybio_stump = stump_biomass_Raile * CRMadj,
                  calc_drybio_sapling = NA_real_,
                  calc_drybio_wdld_spp = NA_real_,
                  calc_drybio_bg = root_biomass_Jenkins * CRMadj,
                  calc_foliage_biomass = foliage_biomass_Jenkins * CRMadj)
         ) %>% 
    mutate(calc_drybio_ag = sum(calc_drybio_bole, calc_drybio_top, calc_drybio_stump,
                                calc_drybio_sapling, calc_drybio_wdld_spp, na.rm = TRUE),
           calc_drybio_ag_fol = sum(calc_drybio_bole, calc_drybio_top, calc_drybio_stump,
                                    calc_drybio_sapling, calc_drybio_wdld_spp, calc_foliage_biomass, na.rm = TRUE)) %>% 
    mutate(calc_carbon_ag = calc_drybio_ag * 0.5,
           calc_carbon_ag_fol = calc_drybio_ag_fol * 0.5,
           calc_carbon_bg = calc_drybio_bg * 0.5) %>%
    select(calc_drybio_bole,
           calc_drybio_top,
           calc_drybio_stump,
           calc_drybio_sapling,
           calc_drybio_wdld_spp,
           calc_drybio_bg,
           calc_foliage_biomass,
           calc_drybio_ag,
           calc_drybio_ag_fol,
           calc_carbon_ag,
           calc_carbon_ag_fol,
           calc_carbon_bg)
  
}
