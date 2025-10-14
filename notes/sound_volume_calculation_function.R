# fmt: skip
sound_volume_calc <- function(i_volcfgrs, i_vol_loc_grp, i_spcd, i_treeclcd, i_dia, i_cull){
  
  if(i_vol_loc_grp %in% c("S23LCS", "S23LLS", "S23LPS") & !i_spcd %in% c(61, 66)){
    
    # Get the config info
    config <- volcfsnd_coef_eq$config_table %>% 
      filter(vol_loc_grp == i_vol_loc_grp & spcd == i_spcd) %>% 
      select(-created_by)
    
    # Get the region/spcd-specific coefs
    coefs <- volcfsnd_coef_eq[[config$coef_table]] %>%
      filter(spcd == config$coef_table_spcd &
               treeclcd == case_when(i_treeclcd == 2 ~ "2",
                                     i_treeclcd == 3 ~ "3",
                                     i_treeclcd == 31 ~ "31",
                                     TRUE ~ "Other"))
    
    # Calculate sound volume
    if(i_vol_loc_grp %in% c("S23LLS", "S23LPS")){
      
      # North Central Lakes States and Plains States - all spcd except 61 and 66
      return(i_volcfgrs * (1 - (((coefs$b1 * coefs$b2)/100))))
      
    }else{
      
      # North Central Central States (IA, IL, IN, MO) - all spcd except 61 and 66
      if(i_dia < coefs$b2){
        
        V1 <- coefs$b0 + coefs$b1 * i_dia
        V1 <- case_when(V1 > 100 ~ as.numeric(100),
                        V1 < 0 ~ as.numeric(0),
                        TRUE ~ as.numeric(V1))
        numerator <- ifelse((V1 * coefs$b3) > 98, 100, V1 * coefs$b3)
        
        return(i_volcfgrs * (1 - (numerator/100)))
        
      }else if(i_dia >= coefs$b2){
        
        V1 <- coefs$b0 + coefs$b1 * coefs$b2
        V1 <- case_when(V1 > 100 ~ as.numeric(100),
                        V1 < 0 ~ as.numeric(0),
                        TRUE ~ as.numeric(V1))
        numerator <- ifelse((V1 * coefs$b3) > 98, 100, V1 * coefs$b3)
        
        return(i_volcfgrs * (1 - (numerator/100)))
        
      }else{
        
        return(0)
        
      }
      
    }
    
    
  }else if(i_vol_loc_grp %in% c("S23LCS", "S23LLS", "S23LPS") & i_spcd == 66){
    
    # It appears spcd 66 in the NC states has sound volume = gross volume
    return(i_volcfgrs)
    
  }else{
    
    i_volcfgrs * (1 - (case_when(is.na(i_cull) ~ as.numeric(0),
                                 i_cull > 98 ~ as.numeric(100),
                                 TRUE ~ as.numeric(i_cull)) / 
                         100))
    
  }
  
}
