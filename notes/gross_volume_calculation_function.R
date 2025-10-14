# fmt: skip
gross_volume_calc <- function(i_vol_loc_grp, i_spcd, i_dia, i_balive, i_sicond, i_stdorgcd, i_statuscd, i_treeclcd, i_sitree,
                              i_ht, i_boleht, i_wdldstem, i_standing_dead_cd){
  
  ## If a tree is < 5 inches DBH, a non-standing dead tree, or has statuscd in (0, 3) then return NA
  if(i_dia < 5.0 | (i_statuscd == 2 & i_standing_dead_cd == 0) | i_statuscd %in% c(0,3)){
    
    return(NA_real_)
    
  }else{
    
    #####################################################################
    ## Select the row from the config table that matches vol_loc_grp/spcd
    #####################################################################
    config <- volcfgrs_coef_eq$config_table %>% 
      filter(vol_loc_grp == i_vol_loc_grp & spcd == i_spcd) %>% 
      select(-created_by)
    
    ###############################################################################
    ## Get the coefficients that correspond to the table/spcd from the config table
    ###############################################################################
    coefs <- volcfgrs_coef_eq[[config$coef_table]] %>% 
      filter(spcd == config$coef_table_spcd) %>% 
      select(-spcd)
    
    if(nrow(coefs) == 1){
      
      # If there are only one set of coefficients then put all data together
      tree_data <- bind_cols(tibble(dia = i_dia,
                                    balive = i_balive,
                                    sicond = i_sicond,
                                    stdorgcd = i_stdorgcd,
                                    statuscd = i_statuscd,
                                    treeclcd = i_treeclcd,
                                    sitree = i_sitree,
                                    ht = i_ht,
                                    boleht = i_boleht,
                                    wdldstem = i_wdldstem),
                             config,
                             coefs)
      
    }else if(config$coef_table %in% c("RMRS_coefs_6", "S_coefs_2")){
      
      # Species in these tables need to be joined by spcd and number of woodland stems
      if(is.na(i_wdldstem)){
        # Default to one stem if wdldstem is null
        tree_data <- bind_cols(tibble(dia = i_dia,
                                      balive = i_balive,
                                      sicond = i_sicond,
                                      stdorgcd = i_stdorgcd,
                                      statuscd = i_statuscd,
                                      treeclcd = i_treeclcd,
                                      sitree = i_sitree,
                                      ht = i_ht,
                                      boleht = i_boleht,
                                      wdldstem = i_wdldstem),
                               config,
                               coefs %>% 
                                 filter(num_of_stems == "1"))
        
      }else{
        
        tree_data <- bind_cols(tibble(dia = i_dia,
                                      balive = i_balive,
                                      sicond = i_sicond,
                                      stdorgcd = i_stdorgcd,
                                      statuscd = i_statuscd,
                                      treeclcd = i_treeclcd,
                                      sitree = i_sitree,
                                      ht = i_ht,
                                      boleht = i_boleht,
                                      wdldstem = i_wdldstem),
                               config,
                               coefs %>% 
                                 filter(num_of_stems == ifelse(i_wdldstem > 1, "2 or more", "1")))
        
      }
      
    }else if(config$coef_table == "S_coefs_1"){
      
      # Species in this table need to be joined by spcd and size (which may include stand origin)
      if(i_spcd %in% c(111,131) & i_dia >= 1.0 & i_dia < 5.0){
        
        # spcd 111 and 131 saplings need stand origin
        tree_data <- bind_cols(tibble(dia = i_dia,
                                      balive = i_balive,
                                      sicond = i_sicond,
                                      stdorgcd = i_stdorgcd,
                                      statuscd = i_statuscd,
                                      treeclcd = i_treeclcd,
                                      sitree = i_sitree,
                                      ht = i_ht,
                                      boleht = i_boleht,
                                      wdldstem = i_wdldstem),
                               config,
                               coefs %>% 
                                 filter(size == ifelse(i_stdorgcd > 0, "planted sapling", "sapling")))
        
      }else{
        
        # All other spcd/sizes just need size info
        tree_data <- bind_cols(tibble(dia = i_dia,
                                      balive = i_balive,
                                      sicond = i_sicond,
                                      stdorgcd = i_stdorgcd,
                                      statuscd = i_statuscd,
                                      treeclcd = i_treeclcd,
                                      sitree = i_sitree,
                                      ht = i_ht,
                                      boleht = i_boleht,
                                      wdldstem = i_wdldstem),
                               config,
                               coefs %>% 
                                 filter(size == case_when(i_dia >= 1.0 & i_dia < 5.0 ~ "sapling",
                                                          i_spcd < 300 & i_dia >= 5.0 & i_dia < 9.0 ~ "poles",
                                                          i_spcd >= 300 & i_dia >= 5.0 & i_dia < 11.0 ~ "poles",
                                                          i_spcd < 300 & i_dia >= 9.0 ~ "sawtimber",
                                                          i_spcd >= 300 & i_dia >= 11.0 ~ "sawtimber")))
      }
    }
    
    #########################
    ## Calculate gross volume
    #########################
    grsvol <- switch(tree_data$equation,
                     
                     "NC_eq_1" = tree_data %>% 
                       mutate(calc_volcfgrs = if_else(is.na(sitree),
                                                      NA_real_,
                                                      b1 * sitree^b2 * (1 - exp(b3 * dia^b4)))) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs < 0, 0, calc_volcfgrs)),
                     
                     "NC_eq_2" = tree_data %>% 
                       mutate(x2 = case_when(sitree < 20 ~ as.numeric(20),
                                             sitree > 120 ~ as.numeric(120),
                                             TRUE ~ as.numeric(sitree)),
                              x3 = case_when(balive < 50 ~ as.numeric(50),
                                             balive > 350 ~ as.numeric(350),
                                             TRUE ~ as.numeric(balive))) %>% 
                       mutate(V2 = b12 + b13 * (1 - exp(-b14*dia))^b15 * x2^b16 * (b17 - (4/dia))^b18 * x3^b19) %>% 
                       mutate(calc_volcfgrs = if_else(is.na(x2) | is.na(x3),
                                                      NA_real_,
                                                      (b0 + b1 * dia + b2 * 4 + b3 * dia^2 + b4 * dia^2 * V2 + b5 * V2^2 + b6 * V2 * 4^2 +
                                                         b7 * dia^2 * V2^3 + b8 * dia^2 * V2^2 * 4) * b9 * (b10 + b11 * dia) / 100)) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs < 0, 0, calc_volcfgrs)),
                     
                     "NC_eq_3" = tree_data %>% 
                       mutate(V1 = dia^2 * ht * 10^-3) %>% 
                       mutate(calc_volcfgrs = if_else(V1 <= b3,
                                                      b0 + b1 * V1 + b2 * V1^2,
                                                      b0 + b1 * V1 + b2 * (3 * b3^2 - (2 * b3^3 / V1)))) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0, 0.1, calc_volcfgrs)),
                     
                     "NC_eq_4" = tree_data %>% 
                       mutate(calc_volcfgrs = if_else((dia^2 * ht) <= b1,
                                                      b2 + b3 * dia^2 * ht,
                                                      b4 + b5 * dia^2 * ht)) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0, 0.1, calc_volcfgrs)),
                     
                     "NE_eq" = tree_data %>% 
                       mutate(calc_volcfgrs = if_else(is.na(boleht),
                                                      NA_real_,
                                                      b0 + b1 * dia^b2 + b3 * dia^b4 * boleht^b5)),
                     
                     "S_eq_1" = tree_data %>% 
                       mutate(calc_volcfgrs = if_else(dia >= 5 & !is.na(ht),
                                                      b0 + (b1 * dia^2 * ht),
                                                      NA_real_)),
                     
                     "S_eq_2" = tree_data %>% 
                       mutate(V1 = dia^2 * ht * 10^-3) %>% 
                       mutate(calc_volcfgrs = if_else(V1 <= b3,
                                                      b0 + b1 * V1 + b2 * V1^2,
                                                      b0 + b1 * V1 + b2 * (3 * b3^2 - (2 * b3^3 / V1)))) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0, 0.1, calc_volcfgrs)),
                     
                     "S_eq_3" = tree_data %>% 
                       mutate(V1 = dia^2 * ht * 10^-3) %>% 
                       mutate(calc_volcfgrs = if_else(V1 <= b6,
                                                      b1 + b2 * V1 + b3 * V1^2,
                                                      b4 + b2 * V1 - (b5 / V1))) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0, 0.1, calc_volcfgrs)),
                     
                     "S_eq_4" = tree_data %>% 
                       mutate(calc_volcfgrs = if_else(dia < 21,
                                                      (b1 + b2 * dia^2 * ht) - (b3 + b4 * ((4^3 * ht) / dia^b5) + b6 * dia^2),
                                                      (b7 + b8 * dia^2 * ht) - (b9 + b10 * ((4^3 * ht) / dia^b11) + b12 * dia^2))) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0 & dia >= 1.0, 0.1, calc_volcfgrs)),
                     
                     "S_eq_5" = tree_data %>% 
                       mutate(calc_volcfgrs = (b1 + b2 * dia^2 * ht) - (b3 + b4 * ((4^3 * ht) / (dia^b5)) + b6 * dia^2)) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0 & dia >= 1.0, 0.1, calc_volcfgrs)),
                     
                     "RM_eq_1" = tree_data %>% 
                       mutate(calc_volcfgrs = (b1 + b2 * dia^2 * ht) - (b3 + b4 * ((4^3 * ht)/(dia^b5)) + b6 * dia^2)) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0 & dia >= 1.0, 0.1, calc_volcfgrs)),
                     
                     "RM_eq_2" = tree_data %>% 
                       mutate(calc_volcfgrs = ifelse((dia^2 * ht) <= b5,
                                                     b1 + b2 * dia^2 * ht,
                                                     b3 + b4 * dia^2 * ht)) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0 & dia >= 1.0, 0.1, calc_volcfgrs)),
                     
                     "RM_eq_3" = tree_data %>% 
                       mutate(V1 = b5 * dia^b6 * ht^b7) %>% 
                       mutate(calc_volcfgrs = V1 - (V1 * (b1 * ((4 / b2)^b3 / dia^b4)))) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0, 0.1, calc_volcfgrs)),
                     
                     "RM_eq_4" = tree_data %>% 
                       mutate(calc_volcfgrs = if_else(((dia^2 * ht) <= b5) | (dia < 21 & b5 == 0),
                                                      b1 + b2 * dia^2 * ht,
                                                      b3 + b4 * dia^2 * ht)) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0, 0.1, calc_volcfgrs)),
                     
                     "RM_eq_5" = tree_data %>% 
                       mutate(calc_volcfgrs = if_else(dia < 21,
                                                      (b1 + b2 * dia^2 * ht) - (b3 + b4 * ((4^3 * ht)/(dia^b5)) + b6 * dia^2),
                                                      (b7 + b8 * dia^2 * ht) - (b9 + b10 * ((4^3 * ht)/(dia^b11)) + b12 * dia^2))) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0 & dia >= 1.0, 0.1, calc_volcfgrs)),
                     
                     "RM_eq_6" = tree_data %>% 
                       mutate(calc_volcfgrs = if_else(dia >= 5,
                                                      b0 + b1 * dia^2 * ht,
                                                      NA_real_)) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0 & !is.na(calc_volcfgrs), 0.1, calc_volcfgrs)),
                     
                     "RM_eq_7" = tree_data %>% 
                       mutate(V1 = dia^2 * ht * 10^-3) %>% 
                       mutate(calc_volcfgrs = if_else(V1 <= b3,
                                                      b0 + b1 * V1 + b2 * V1^2,
                                                      b0 + b1 * V1 + b2 * (3 * b3^2 - (2 * b3^3 / V1)))) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0, 0.1, calc_volcfgrs)),
                     
                     "RM_eq_8" = tree_data %>% 
                       mutate(x1 = min(c(dia, 60))) %>% 
                       mutate(V1 = b6 * x1^2 * (b7 + b8 * ht - (b9 * x1 * ht / (ht + b10))) * ht * (ht / (ht + b10))^2) %>% 
                       mutate(V1 = if_else(V1 <= 0, 2, V1)) %>% 
                       mutate(calc_volcfgrs = ((V1 + b1) / (b2 + b3 * exp(b4 * x1))) + b5) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0, 1, calc_volcfgrs)),
                     
                     "RM_eq_9" = tree_data %>% 
                       mutate(calc_volcfgrs = case_when(is.na(ht) ~ 0.1,
                                                        dia < 5 ~ 0.1,
                                                        spcd < 300 & dia < 9 ~ b1 + b2 * dia^2 * ht,
                                                        spcd >= 300 & dia < 11 ~ b1 + b2 * dia^2 * ht,
                                                        TRUE ~ b3 + b4 * dia^2 * ht)) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0, 0.1, calc_volcfgrs)),
                     
                     "RM_eq_10" = tree_data %>% 
                       mutate(calc_volcfgrs = case_when(dia >= 3 & ht > 0 & wdldstem == 1 ~ (b0 + b1 * (dia^2 * ht)^b2 + b3)^3,
                                                        dia >= 3 & ht > 0 & wdldstem != 1 ~ (b0 + b1 * (dia^2 * ht)^b2)^3,
                                                        TRUE ~ 0.1)) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0, 0.1, calc_volcfgrs)),
                     
                     "RM_eq_11" = tree_data %>% 
                       mutate(V1 = dia^2 * ht * 10^-3) %>% 
                       mutate(calc_volcfgrs = if_else(V1 <= b6,
                                                      b1 + b2 * V1 + b3 * V1^2,
                                                      b4 + b2 * V1 - (b5 / V1))) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0, 0.1, calc_volcfgrs)),
                     
                     "RM_eq_12" = tree_data %>% 
                       mutate(calc_volcfgrs = case_when(dia >= 3 & ht > 0 & wdldstem == 1 ~ (b0 + b1 * (dia^2 * ht)^b2 + b3)^3,
                                                        dia >= 3 & ht > 0 & wdldstem != 1 ~ (b0 + b1 * (dia^2 * ht)^b2)^3,
                                                        TRUE ~ 0)) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs < 0, 0.1, calc_volcfgrs)),
                     
                     "PNW_eq_1" = tree_data %>% 
                       mutate(calc_volcfgrs = ((10^b1 * dia^b2 * ht^b3 * b4) / ((b5 * (1 + b6 * exp(b7 * (dia/10)))) * 
                                                                                  (b8 * dia^2 + b9) + b10)) * ((b11 * dia^2 - b9) / b4)),
                     
                     "PNW_eq_2" = tree_data %>% 
                       mutate(x1 = max(c(dia, 6))) %>% 
                       mutate(V1 = b2 + b3 * (ht/x1)) %>% 
                       mutate(V1 = case_when(V1 > 0.4 ~ 0.4,
                                             V1 < 0.3 ~ 0.3,
                                             TRUE ~ V1)) %>% 
                       mutate(calc_volcfgrs = b1 * x1^2 * ht * V1),
                     
                     "PNW_eq_3" = tree_data %>% 
                       mutate(x1 = max(c(dia, 6))) %>% 
                       mutate(V1 = b2 + b3 * ht^-1 + b4 * (ht^2 / x1)) %>% 
                       mutate(V1 = case_when(V1 > 0.4 ~ 0.4,
                                             V1 < 0.3 ~ 0.3,
                                             TRUE ~ V1)) %>% 
                       mutate(calc_volcfgrs = b1 * x1^2 * ht * V1),
                     
                     "PNW_eq_4" = tree_data %>% 
                       mutate(x1 = max(c(dia, 6))) %>% 
                       mutate(V1 = b2 + b3 * ht^-1) %>% 
                       mutate(V1 = if_else(V1 < 0.27, 0.27, V1)) %>% 
                       mutate(calc_volcfgrs = b1 * x1^2 * ht * V1),
                     
                     "PNW_eq_5" = tree_data %>% 
                       mutate(calc_volcfgrs = case_when(dia >= 3 & ht > 0 & wdldstem == 1 ~ (b0 + b1 * (dia^2 * ht)^b2 + b3)^3,
                                                        dia >= 3 & ht > 0 & wdldstem != 1 ~ (b0 + b1 * (dia^2 * ht)^b2)^3,
                                                        TRUE ~ 0.1)) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0, 0.1, calc_volcfgrs)),
                     
                     "PNW_eq_6" = tree_data %>% 
                       mutate(x1 = min(c(dia,60))) %>% 
                       mutate(V1 = b6 * x1^2 * (b7 + b8 * ht - (b9 * x1 * ht / (ht + b10))) * ht * (ht / (ht + b10))^2) %>% 
                       mutate(V1 = if_else(V1 <= 0, 2, V1)) %>% 
                       mutate(calc_volcfgrs = ((V1 + b1) / (b2 + b3 * exp(b4 * x1))) + b5) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0, 1, calc_volcfgrs)),
                     
                     "PNW_eq_7" = tree_data %>% 
                       mutate(x1 = max(c(dia, 6))) %>% 
                       mutate(V1 = b2 + b3 * (ht^2/x1)) %>% 
                       mutate(V1 = case_when(V1 > 0.4 ~ 0.4,
                                             V1 < 0.3 ~ 0.3,
                                             TRUE ~ V1)) %>% 
                       mutate(calc_volcfgrs = b1 * x1^2 * ht * V1),
                     
                     "PNW_eq_8" = tree_data %>% 
                       mutate(x1 = max(c(dia, 6))) %>% 
                       mutate(V1 = b2 + b3 * x1^-1) %>% 
                       mutate(V1 = case_when(V1 > 0.4 ~ 0.4,
                                             V1 < 0.3 ~ 0.3,
                                             TRUE ~ V1)) %>% 
                       mutate(calc_volcfgrs = b1 * x1^2 * ht * V1),
                     
                     "PNW_eq_9" = tree_data %>% 
                       mutate(calc_volcfgrs = ((exp(b1 + b2 * log(dia) + b3 * (log(ht))^2 + (b4 / ht^2) + b5 * log(ht)) * b6) / 
                                                 ((b7 * (1 + b8 * exp(b9 * (dia/10)))) * (b10 * dia^2 + b11) + b12)) * ((b13 * dia^2 - b11) / b6)),
                     
                     "PNW_eq_10" = tree_data %>% 
                       mutate(x1 = max(c(dia, 6))) %>% 
                       mutate(V1 = b2 + (b3 * (ht / x1) - b4 * (ht^2 / x1))) %>% 
                       mutate(V1 = case_when(V1 > 0.4 ~ 0.4,
                                             V1 < 0.3 ~ 0.3,
                                             TRUE ~ V1)) %>% 
                       mutate(calc_volcfgrs = b1 * x1^2 * ht * V1),
                     
                     "PNW_eq_11" = tree_data %>%
                       mutate(V1 = b1 + b2 * log10(dia) * log10(ht) + b3 * (log10(dia))^2 + b4 * log10(dia) + b5 * log10(ht) + b6 * (log10(ht))^2) %>% 
                       mutate(calc_volcfgrs = ((10^V1 * b7) / ((b8 * (1 + b9 * exp(b10 * (dia/10)))) * (b11 * dia^2 + b12) + b13)) * 
                                ((b14 * dia^2 - b12) / b7)),
                     
                     "PNW_eq_12" = tree_data %>% 
                       mutate(calc_volcfgrs = ((exp(b1 + b2 * log(dia) + b3 * log(ht)) * b4) / 
                                                 ((b5 * (1 + b6 * exp(b7 * (dia/10)))) * (b8 * dia^2 + b9) + b10)) * 
                                ((b11 * dia^2 - b9) / b4)),
                     
                     "PNW_eq_13" = tree_data %>% 
                       mutate(calc_volcfgrs = ((10^(b1 + b2 * log10(dia) + b3 * log10(ht) + b4 * dia) * b5) / 
                                                 ((b6 * (1 + b7 * exp(b8 * (dia/10)))) * (b9 * dia^2 + b10) + b11)) * ((b12 * dia^2 - b10) / b5)),
                     
                     "PNW_eq_14" = tree_data %>% 
                       mutate(calc_volcfgrs = (b1 * dia^b2 * ht^b3 * b4) / ((b5 * (1 + b6 * exp(b7 * (dia/10)))) * (b8 * dia^2 + b9) + b10) *
                                ((b11 * dia^2 - b9) / b4)),
                     
                     "PNW_eq_15" = tree_data %>% 
                       mutate(x2 = ifelse(spcd %in% c(361,631), min(c(ht, 120)), ht)) %>% 
                       mutate(calc_volcfgrs = b1 * dia^b2 * x2^b3),
                     
                     "PNW_eq_16" = tree_data %>% 
                       mutate(x2 = max(c(ht, 18))) %>% 
                       mutate(V3 = (x2 + b25 - (dia / b26)) / (x2 + b5)) %>% 
                       mutate(V2 = V3^2.5) %>% 
                       mutate(V1 = (b4 * dia^2 * (x2 + b5) * 
                                      (b6 * V2 + b7 * V2 * dia * 10^-3 + b8 * V2 * x2 * 10^-3 + b9 * V2 * x2 * dia * 10^-5 +
                                         b10 * V2 * x2^2 * 10^-6 + b11 * V2 * sqrt(x2) * 10^-3 + b12 * V3^4 * dia * 10^-3 +
                                         b13 * V3^4 * x2 * 10^-3 + b14 * V3^33 * x2 * dia * 10^-6 + b15 * V3^33 * sqrt(x2) * 10^-4 +
                                         b16 * V3^41 * x2^2 * 10^-7) * b3) / 
                                ((b17 + b18 * b19^(dia + b20)) * ((b21 * (1 + b22 * exp(b23 * (dia/10)))) * (b1 * dia^2 + b2) + b24))) %>% 
                       mutate(calc_volcfgrs = V1 * ((b1 * dia^2 - b2) / b3)),
                     
                     "PNW_eq_17" = tree_data %>% 
                       mutate(calc_volcfgrs = ((b1 * dia^2 * ht * b2) / 
                                                 ((b3 * (1 + b4 * exp(b5 * (dia/10)))) * (b6 * dia^2 + b7) + b8)) * ((b9 * dia^2 - b7) / b2)),
                     
                     "PNW_eq_18" = tree_data %>% 
                       mutate(V1 = dia^2 * ht * 10^-3) %>% 
                       mutate(calc_volcfgrs = if_else(V1 <= b6,
                                                      b1 + b2 * V1 + b3 * V1^2,
                                                      b4 + b2 * V1 - (b5/V1))) %>% 
                       mutate(calc_volcfgrs = if_else(calc_volcfgrs <= 0, 0.1, calc_volcfgrs))
    ) %>% 
      select(calc_volcfgrs) %>% 
      pull()
  }
}
