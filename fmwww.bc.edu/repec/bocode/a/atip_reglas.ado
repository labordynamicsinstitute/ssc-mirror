*! atip_reglas.ado v1.0.0  Andres Talavera  INEI/DNCE  21jul2026
program define atip_reglas, rclass
    version 14
    syntax varname(numeric), GROUP(varlist) ///
        [RULES(string) SDTHRESH3(real 3) SDTHRESH2(real 2) ///
         ZTHRESH(real 2) ZSYMMETRIC MAHALTHRESH(real 8) GEN(name) CLASSIC]
    if "`rules'" == "" local rules "sd3 sd2 zscore iqr mahal"
    if "`gen'"   == "" local gen "OUTLIERS"
    tempvar touse n_casos desvia media qtl1 qtl3
    quietly gen byte `touse' = !missing(`varlist')
    quietly bys `group': gen `n_casos' = _N if `touse'
    tempvar media_c desvia_c
    quietly bys `group': egen `desvia_c' = sd(`varlist') if `touse'
    quietly bys `group': egen `media_c'  = mean(`varlist') if `touse'
    if "`classic'" != "" {
        quietly gen double `media'  = `media_c'
        quietly gen double `desvia' = `desvia_c'
    }
    else {
        tempvar absdev media_r desvia_r
        quietly bys `group': egen `media_r' = median(`varlist') if `touse'
        quietly gen double `absdev' = abs(`varlist' - `media_r') if `touse'
        quietly bys `group': egen `desvia_r' = median(`absdev') if `touse'
        quietly replace `desvia_r' = `desvia_r' * 1.4826
        quietly gen double `media'  = cond(`desvia_r'==0 & `desvia_c'>0, `media_c',  `media_r')
        quietly gen double `desvia' = cond(`desvia_r'==0 & `desvia_c'>0, `desvia_c', `desvia_r')
        quietly count if `desvia_r'==0 & `desvia_c'>0 & `touse'
        if r(N) > 0 {
            di as text "Aviso: " as res r(N) as text " observaciones con MAD=0 (empates mayoritarios en la mediana del grupo) -- se uso media/DE como respaldo para esos casos"
        }
    }
    if strpos("`rules'","sd3") {
        capture drop SD_MEAN_3
        gen byte SD_MEAN_3 = 1 if (`varlist' > `media'+`sdthresh3'*`desvia' | ///
                                    `varlist' < `media'-`sdthresh3'*`desvia') & `desvia'~=.
        replace SD_MEAN_3 = 0 if (`varlist'<=`media'+`sdthresh3'*`desvia' & ///
                                   `varlist'>=`media'-`sdthresh3'*`desvia') & `desvia'~=0
        replace SD_MEAN_3 = . if `desvia'==0 | `n_casos'==1
    }
    if strpos("`rules'","sd2") {
        capture drop SD_MEAN_2
        gen byte SD_MEAN_2 = 1 if (`varlist' > `media'+`sdthresh2'*`desvia' | ///
                                    `varlist' < `media'-`sdthresh2'*`desvia') & `desvia'~=.
        replace SD_MEAN_2 = 0 if (`varlist'<=`media'+`sdthresh2'*`desvia' & ///
                                   `varlist'>=`media'-`sdthresh2'*`desvia') & `desvia'~=0
        replace SD_MEAN_2 = . if `desvia'==0 | `n_casos'==1
    }
    if strpos("`rules'","zscore") {
        capture drop ZSCORE_I ZSCORE
        gen double ZSCORE_I = (`varlist' - `media') / `desvia'
        if "`zsymmetric'" != "" {
            gen byte ZSCORE = 1 if abs(ZSCORE_I) > `zthresh' & ZSCORE_I~=.
            replace ZSCORE = 0 if abs(ZSCORE_I) <= `zthresh'
        }
        else {
            gen byte ZSCORE = 1 if ZSCORE_I > `zthresh' & ZSCORE_I~=.
            replace ZSCORE = 0 if ZSCORE_I <= `zthresh'
        }
        replace ZSCORE = . if `desvia'==0 | `n_casos'==1
    }
    if strpos("`rules'","iqr") {
        capture drop IQR
        quietly bys `group': egen `qtl1' = pctile(`varlist') if `touse', p(25)
        quietly bys `group': egen `qtl3' = pctile(`varlist') if `touse', p(75)
        tempvar iqr_val lim_inf lim_sup
        quietly gen double `iqr_val' = `qtl3' - `qtl1'
        quietly gen double `lim_sup' = cond(`iqr_val'==0 & `desvia_c'>0, ///
                                             `media_c'+`sdthresh2'*`desvia_c', `qtl3'+1.5*`iqr_val')
        quietly gen double `lim_inf' = cond(`iqr_val'==0 & `desvia_c'>0, ///
                                             `media_c'-`sdthresh2'*`desvia_c', `qtl1'-1.5*`iqr_val')
        gen byte IQR = 1 if `varlist' > `lim_sup' | `varlist' < `lim_inf'
        replace IQR = 0 if `varlist' <= `lim_sup' & `varlist' >= `lim_inf'
        replace IQR = . if `desvia'==0 | `n_casos'==1
        quietly count if `iqr_val'==0 & `desvia_c'>0 & `touse'
        if r(N) > 0 {
            di as text "Aviso: " as res r(N) as text " observaciones con IQR=0 (empates mayoritarios entre Q1 y Q3) -- se uso media+/-`sdthresh2'*DE como respaldo para la regla IQR en esos casos"
        }
    }
    if strpos("`rules'","mahal") {
        capture drop DIST MHLBS
        capture confirm variable ZSCORE_I
        if _rc {
            gen double ZSCORE_I = (`varlist' - `media') / `desvia'
        }
        gen double DIST = ZSCORE_I^2
        gen byte MHLBS = 1 if DIST>`mahalthresh' & DIST~=.
        replace MHLBS = 0 if DIST<=`mahalthresh'
    }
    capture drop `gen'
    gen byte `gen' = 0
    foreach r in SD_MEAN_3 SD_MEAN_2 ZSCORE IQR MHLBS {
        capture confirm variable `r'
        if !_rc {
            replace `gen' = 1 if `r'==1
        }
    }
    quietly count if `gen'==1
    return scalar n_outliers = r(N)
    di as text "Outliers detectados (`gen'==1): " as res r(N)
end
