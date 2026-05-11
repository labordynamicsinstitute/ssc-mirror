*! version 1.0.0  11May2026  Conditional SEMs in Generalizability Theory
*! Univariate single-facet crossed design (persons x items)
*! Implements Brennan (1998) and Brennan (2001, secs. 2.3, 5.4.1)
*! Author:  Rene Gempp <rene.gempp@udp.cl>

capture program drop gtcsem
program define gtcsem, rclass
    version 16.0
    
    syntax varlist(min=2 numeric) [if] [in], [ ///
        NItemsd(real 0)               ///
        Method(string)                ///
        SEmethod(string)              ///
        Generate(name)                ///
        CUTpoint(real -9999999)       ///
        BOOTb(integer 1000)           ///
        BOOTseed(integer 0)           ///
        TRUNCneg                      ///
        TRUNCvc                       ///
        SMooth                        ///
        EXCLudeextremes               ///
        noDOTs                        ///
        Replace                       ///
    ]
    
    /* sentinel: cutpoint not specified */
    local has_cut = (`cutpoint' != -9999999)
    
    /* ========================================================
       Defaults and validation
       ======================================================== */
    
    if "`method'"   == "" local method   "full"
    if "`semethod'" == "" local semethod "analytical"
    
    local method   = lower("`method'")
    local semethod = lower("`semethod'")
    
    if !inlist("`method'", "full", "large_a", "uncorrelated", "all") {
        di as error "method() must be one of: full, large_a, uncorrelated, all"
        exit 198
    }
    
    if !inlist("`semethod'", "analytical", "bootstrap", "both") {
        di as error "semethod() must be one of: analytical, bootstrap, both"
        exit 198
    }
    
    if `bootb' < 100 {
        di as error "bootb() must be at least 100."
        exit 198
    }

    if "`excludeextremes'" != "" & "`smooth'" == "" {
        di as error "excludeextremes requires smooth."
        exit 198
    }
    
    if "`generate'" == "" local generate "csem"
    local prefix `generate'
    
    marksample touse
    
    quietly count if `touse'
    local A = r(N)
    local Iobs : word count `varlist'
    
    if `A' < 2 {
        di as error "At least 2 persons are required."
        exit 2001
    }
    if `Iobs' < 2 {
        di as error "At least 2 items are required."
        exit 2001
    }
    
    if `nitemsd' == 0 {
        local D = `Iobs'
    }
    else {
        local D = `nitemsd'
    }
    
    if `D' <= 0 {
        di as error "nitemsd() must be positive."
        exit 198
    }
    
    /* missing-data check */
    tempvar rowmiss
    quietly egen `rowmiss' = rowmiss(`varlist') if `touse'
    quietly count if `touse' & `rowmiss' > 0
    if r(N) > 0 {
        di as error "Missing item scores detected. Complete balanced data required."
        exit 459
    }
    
    /* ========================================================
       Output variable bookkeeping
       
       Naming convention (short suffixes):
         _score, _abs_ev, _abs_csem, _abs_ev_sm, _abs_csem_sm
         _vabs_an, _cov_xim
         _rel_ev,  _rel_csem,  _rel_ev_sm,  _rel_csem_sm
         _rel_ev_full, _rel_csem_full, _rel_ev_sm_full, _rel_csem_sm_full
         _rel_ev_la,   _rel_csem_la,   _rel_ev_sm_la,   _rel_csem_sm_la
         _rel_ev_unc,  _rel_csem_unc,  _rel_ev_sm_unc,  _rel_csem_sm_unc
         _vrev_an, _vrev_an_full, _vrev_an_la, _vrev_an_unc
       ======================================================== */
    
    local outvars `prefix'_score `prefix'_abs_ev `prefix'_abs_csem ///
                  `prefix'_cov_xim `prefix'_vabs_an
    
    /* bootstrap variance columns (in addition to analytical) */
    local has_boot = inlist("`semethod'", "bootstrap", "both")
    if `has_boot' {
        local outvars `outvars' `prefix'_vabs_bs
    }
    
    if "`smooth'" != "" {
        local outvars `outvars' `prefix'_abs_ev_sm `prefix'_abs_csem_sm
    }
    
    if "`method'" == "all" {
        local outvars `outvars' ///
            `prefix'_rel_ev_full   `prefix'_rel_csem_full   `prefix'_vrev_an_full ///
            `prefix'_rel_ev_la     `prefix'_rel_csem_la     `prefix'_vrev_an_la   ///
            `prefix'_rel_ev_unc    `prefix'_rel_csem_unc    `prefix'_vrev_an_unc  ///
            `prefix'_rel_ev        `prefix'_rel_csem        `prefix'_vrev_an
        if `has_boot' {
            local outvars `outvars' ///
                `prefix'_vrev_bs_full `prefix'_vrev_bs_la `prefix'_vrev_bs_unc `prefix'_vrev_bs
        }
        if "`smooth'" != "" {
            local outvars `outvars' ///
                `prefix'_rel_ev_sm_full `prefix'_rel_csem_sm_full ///
                `prefix'_rel_ev_sm_la   `prefix'_rel_csem_sm_la   ///
                `prefix'_rel_ev_sm_unc  `prefix'_rel_csem_sm_unc  ///
                `prefix'_rel_ev_sm      `prefix'_rel_csem_sm
        }
    }
    else {
        local outvars `outvars' ///
            `prefix'_rel_ev `prefix'_rel_csem `prefix'_vrev_an
        if `has_boot' {
            local outvars `outvars' `prefix'_vrev_bs
        }
        if "`smooth'" != "" {
            local outvars `outvars' `prefix'_rel_ev_sm `prefix'_rel_csem_sm
        }
    }
    
    if "`replace'" != "" {
        foreach v of local outvars {
            capture drop `v'
        }
    }
    else {
        foreach v of local outvars {
            capture confirm new variable `v'
            if _rc {
                di as error ///
                    "Variable `v' already exists. Use option replace or generate(other_prefix)."
                exit 110
            }
        }
    }
    
    /* ========================================================
       Per-person ingredients (single loop over items)
       ======================================================== */
    
    tempvar pm rowss rowQ4 covitem ssresidrow sspersonrow
    
    quietly egen double `pm' = rowmean(`varlist') if `touse'
    quietly summarize `pm' if `touse', meanonly
    tempname grand SSitem
    scalar `grand'  = r(mean)
    scalar `SSitem' = 0
    
    quietly generate double `rowss'      = 0 if `touse'
    quietly generate double `rowQ4'      = 0 if `touse'
    quietly generate double `covitem'    = 0 if `touse'
    quietly generate double `ssresidrow' = 0 if `touse'
    
    foreach x of varlist `varlist' {
        quietly summarize `x' if `touse', meanonly
        tempname imean idev
        scalar `imean' = r(mean)
        scalar `idev'  = scalar(`imean') - scalar(`grand')
        scalar `SSitem' = scalar(`SSitem') + `A' * (scalar(`idev')^2)
        
        quietly replace `rowss'      = `rowss'      + (`x' - `pm')^2 if `touse'
        quietly replace `rowQ4'      = `rowQ4'      + (`x' - `pm')^4 if `touse'
        quietly replace `covitem'    = `covitem'    + (`x' - `pm') * scalar(`idev') if `touse'
        quietly replace `ssresidrow' = `ssresidrow' + (`x' - `pm' - scalar(`idev'))^2 if `touse'
    }
    
    /* ========================================================
       ANOVA sums of squares and variance components
       ======================================================== */
    
    quietly generate double `sspersonrow' = (`pm' - scalar(`grand'))^2 if `touse'
    quietly summarize `sspersonrow' if `touse', meanonly
    tempname SSperson SSresid
    scalar `SSperson' = `Iobs' * r(mean) * r(N)
    
    quietly summarize `ssresidrow' if `touse', meanonly
    scalar `SSresid' = r(mean) * r(N)
    
    tempname dfp dfi dfr MSp MSi MSr s2p s2i s2r
    scalar `dfp' = `A' - 1
    scalar `dfi' = `Iobs' - 1
    scalar `dfr' = (`A' - 1) * (`Iobs' - 1)
    scalar `MSp' = scalar(`SSperson') / scalar(`dfp')
    scalar `MSi' = scalar(`SSitem')   / scalar(`dfi')
    scalar `MSr' = scalar(`SSresid')  / scalar(`dfr')
    scalar `s2p' = (scalar(`MSp') - scalar(`MSr')) / `Iobs'
    scalar `s2i' = (scalar(`MSi') - scalar(`MSr')) / `A'
    scalar `s2r' = scalar(`MSr')
    
    if "`truncvc'" != "" {
        if scalar(`s2p') < 0 scalar `s2p' = 0
        if scalar(`s2i') < 0 scalar `s2i' = 0
        if scalar(`s2r') < 0 scalar `s2r' = 0
    }
    
    /* ========================================================
       Per-person error variances and SEMs
       ======================================================== */
    
    tempvar abs_ev cov_xim rel_full rel_la rel_unc abs_csem
    tempvar rcs_full rcs_la rcs_unc
    
    quietly generate double `abs_ev'   = `rowss' / ((`Iobs' - 1) * `D') if `touse'
    quietly generate double `cov_xim'  = `covitem' / (`Iobs' - 1) if `touse'
    quietly generate double `abs_csem' = sqrt(max(`abs_ev', 0)) if `touse'
    
    quietly generate double `rel_full' = ///
        ((`A' + 1) / (`A' - 1)) * `abs_ev' + scalar(`s2i') / `D' - ///
        (`A' / (`A' - 1)) * (2 * `cov_xim' / `D') if `touse'
    
    quietly generate double `rel_la' = ///
        `abs_ev' + scalar(`s2i') / `D' - 2 * `cov_xim' / `D' if `touse'
    
    quietly generate double `rel_unc' = ///
        `abs_ev' - scalar(`s2i') / `D' if `touse'
    
    if "`truncneg'" == "" {
        quietly generate double `rcs_full' = cond(`rel_full' >= 0, sqrt(`rel_full'), .) if `touse'
        quietly generate double `rcs_la'   = cond(`rel_la'   >= 0, sqrt(`rel_la'),   .) if `touse'
        quietly generate double `rcs_unc'  = cond(`rel_unc'  >= 0, sqrt(`rel_unc'),  .) if `touse'
    }
    else {
        quietly generate double `rcs_full' = sqrt(max(`rel_full', 0)) if `touse'
        quietly generate double `rcs_la'   = sqrt(max(`rel_la',   0)) if `touse'
        quietly generate double `rcs_unc'  = sqrt(max(`rel_unc',  0)) if `touse'
    }
    
    /* ========================================================
       Analytical SE — exact formulas (conditional on items,
       Gaussian residuals). The sampling variance of each
       per-person estimator depends only on S_b = sum(b_i^2),
       sigma_pi^2 (= MSr) and I, so it is constant across
       persons under the model.
       ======================================================== */

    tempname S_b var_sp2_s var_cp_s cov_sc_s
    tempname v_abs_s v_full_s v_la_s v_unc_s
    tempname alpha_la gamma_la alpha_full gamma_full

    /* S_b = sum_i (b_i^2), where b_i = mean(X[,i]) - grand_mean.
       SSitem = A * sum_i (b_i^2), so S_b = SSitem / A. */
    scalar `S_b' = scalar(`SSitem') / `A'

    scalar `var_sp2_s' = ///
        4 * scalar(`s2r') * scalar(`S_b') / ((`Iobs' - 1)^2) + ///
        2 * (scalar(`s2r')^2) / (`Iobs' - 1)
    scalar `var_cp_s'  = ///
            scalar(`s2r') * scalar(`S_b') / ((`Iobs' - 1)^2)
    scalar `cov_sc_s'  = ///
        2 * scalar(`s2r') * scalar(`S_b') / ((`Iobs' - 1)^2)

    /* abs:           alpha = 1/D,                gamma = 0           */
    /* uncorrelated:  alpha = 1/D,                gamma = 0           */
    /* large_a:       alpha = 1/D,                gamma = -2/D        */
    /* full:          alpha = (A+1)/((A-1)*D),    gamma = -2A/((A-1)*D) */

    scalar `v_abs_s' = scalar(`var_sp2_s') / (`D'^2)
    scalar `v_unc_s' = scalar(`v_abs_s')

    scalar `alpha_la' =  1 / `D'
    scalar `gamma_la' = -2 / `D'
    scalar `v_la_s' = ///
        (scalar(`alpha_la')^2) * scalar(`var_sp2_s') + ///
        (scalar(`gamma_la')^2) * scalar(`var_cp_s')  + ///
        2 * scalar(`alpha_la') * scalar(`gamma_la') * scalar(`cov_sc_s')

    scalar `alpha_full' =      (`A' + 1) / ((`A' - 1) * `D')
    scalar `gamma_full' = -2 *  `A'      / ((`A' - 1) * `D')
    scalar `v_full_s' = ///
        (scalar(`alpha_full')^2) * scalar(`var_sp2_s') + ///
        (scalar(`gamma_full')^2) * scalar(`var_cp_s')  + ///
        2 * scalar(`alpha_full') * scalar(`gamma_full') * scalar(`cov_sc_s')

    /* Truncate negatives. */
    if scalar(`v_abs_s')  < 0  scalar `v_abs_s'  = 0
    if scalar(`v_unc_s')  < 0  scalar `v_unc_s'  = 0
    if scalar(`v_la_s')   < 0  scalar `v_la_s'   = 0
    if scalar(`v_full_s') < 0  scalar `v_full_s' = 0

    tempvar vabs vfull vla vunc
    quietly generate double `vabs'  = scalar(`v_abs_s')  if `touse'
    quietly generate double `vfull' = scalar(`v_full_s') if `touse'
    quietly generate double `vla'   = scalar(`v_la_s')   if `touse'
    quietly generate double `vunc'  = scalar(`v_unc_s')  if `touse'
    
    /* ========================================================
       Bootstrap SE (Mata): item-resampling for each person.
       Mata writes BSVARS (A x 4) and also stores results
       directly into Stata variables via st_store.
       ======================================================== */
    
    tempvar vabs_bs vfull_bs vla_bs vunc_bs
    tempname BSVARS
    
    /* Always pre-create the variables; populate either with bootstrap or missing */
    quietly generate double `vabs_bs'  = .
    quietly generate double `vfull_bs' = .
    quietly generate double `vla_bs'   = .
    quietly generate double `vunc_bs'  = .
    
    if `has_boot' {
        if `bootseed' != 0 {
            set seed `bootseed'
        }
        
        local show_dots = ("`dots'" != "nodots")
        local dots_step_val = max(1, ceil(`A'/200))
        local mata_dots = `dots_step_val' * `show_dots'
        
        /* Place sigma2(item) into a named scalar that Mata reads */
        capture scalar drop gtcsem_s2i
        scalar gtcsem_s2i = scalar(`s2i')
        
        if `show_dots' {
            di as text _n "Bootstrap (B = `bootb', dots: 1 per `dots_step_val' person(s), 50 per line)"
        }
        
        capture noisily mata: _gtcsem_boot_wrap("`varlist'", "`touse'", `bootb', `D', `A', `mata_dots', "`vabs_bs'", "`vfull_bs'", "`vla_bs'", "`vunc_bs'", "`BSVARS'")
        local mata_rc = _rc
        
        capture scalar drop gtcsem_s2i
        
        if `mata_rc' != 0 {
            di as error "Mata bootstrap failed (rc = `mata_rc')."
            exit `mata_rc'
        }
    }
    
    /* ========================================================
       Smoothing (Brennan 2001, p.162):
         Quadratic regression of error variance on score.
         OLS guarantees mean(fitted) = mean(observed).
         Captures b0, b1, b2, R2, RMSE, n per fit into SMOOTHFITS.
       ======================================================== */
    
    tempvar pm2 abs_ev_sm rel_full_sm rel_la_sm rel_unc_sm
    tempvar abs_csem_sm rcs_full_sm rcs_la_sm rcs_unc_sm
    
    tempname SMOOTHFITS
    
    /* Floor/ceiling detection for smoothing fit sample.
       Cases with all items at the empirical min (floor) or all at the
       empirical max (ceiling) are structurally degenerate (zero
       intra-person item variance), so when -excludeextremes- is on
       they are dropped from the regression and their smoothed
       values are left missing. */
    tempvar fitsample
    quietly gen byte `fitsample' = `touse'
    local n_floor   = 0
    local n_ceiling = 0
    local n_fit     = `A'

    if "`smooth'" != "" & "`excludeextremes'" != "" {
        tempvar rmin_ rmax_
        quietly egen `rmin_' = rowmin(`varlist') if `touse'
        quietly egen `rmax_' = rowmax(`varlist') if `touse'

        local gmin = .
        local gmax = .
        foreach v of local varlist {
            quietly summarize `v' if `touse', meanonly
            if `gmin' >= . | r(min) < `gmin' local gmin = r(min)
            if `gmax' >= . | r(max) > `gmax' local gmax = r(max)
        }

        quietly count if `touse' & `rmin_' == `gmin' & `rmax_' == `gmin'
        local n_floor = r(N)
        quietly count if `touse' & `rmin_' == `gmax' & `rmax_' == `gmax'
        local n_ceiling = r(N)

        quietly replace `fitsample' = 0 if `touse' & ///
            ((`rmin_' == `gmin' & `rmax_' == `gmin') | ///
             (`rmin_' == `gmax' & `rmax_' == `gmax'))
        quietly count if `fitsample' == 1
        local n_fit = r(N)

        if `n_fit' < 5 {
            di as error "excludeextremes leaves n_fit = `n_fit' (< 5). " ///
                "Too few non-extreme cases to fit a quadratic."
            exit 2001
        }
    }

    if "`smooth'" != "" {
        quietly generate double `pm2' = `pm'^2 if `touse'

        /* Pre-create the destination variables (helpers will replace) */
        quietly generate double `abs_ev_sm'   = . if `touse'
        quietly generate double `rel_full_sm' = . if `touse'
        quietly generate double `rel_la_sm'   = . if `touse'
        quietly generate double `rel_unc_sm'  = . if `touse'

        tempname b sf_abs sf_full sf_la sf_unc

        _gtcsem_qfit `abs_ev'   `abs_ev_sm'   `pm' `pm2' `fitsample'
        matrix `sf_abs' = (r(b0), r(b1), r(b2), r(R2), r(RMSE), r(n))

        _gtcsem_qfit `rel_full' `rel_full_sm' `pm' `pm2' `fitsample'
        matrix `sf_full' = (r(b0), r(b1), r(b2), r(R2), r(RMSE), r(n))

        _gtcsem_qfit `rel_la'   `rel_la_sm'   `pm' `pm2' `fitsample'
        matrix `sf_la'  = (r(b0), r(b1), r(b2), r(R2), r(RMSE), r(n))

        _gtcsem_qfit `rel_unc'  `rel_unc_sm'  `pm' `pm2' `fitsample'
        matrix `sf_unc' = (r(b0), r(b1), r(b2), r(R2), r(RMSE), r(n))
        
        /* Build SMOOTHFITS matrix according to method */
        if "`method'" == "all" {
            matrix `SMOOTHFITS' = ///
                (`sf_abs' \ `sf_full' \ `sf_la' \ `sf_unc')
            matrix rownames `SMOOTHFITS' = abs_ev rel_ev_full ///
                                            rel_ev_la rel_ev_unc
        }
        else if "`method'" == "full" {
            matrix `SMOOTHFITS' = (`sf_abs' \ `sf_full')
            matrix rownames `SMOOTHFITS' = abs_ev rel_ev
        }
        else if "`method'" == "large_a" {
            matrix `SMOOTHFITS' = (`sf_abs' \ `sf_la')
            matrix rownames `SMOOTHFITS' = abs_ev rel_ev
        }
        else { /* uncorrelated */
            matrix `SMOOTHFITS' = (`sf_abs' \ `sf_unc')
            matrix rownames `SMOOTHFITS' = abs_ev rel_ev
        }
        matrix colnames `SMOOTHFITS' = b0 b1 b2 R2 RMSE n
        
        if "`truncneg'" == "" {
            quietly generate double `abs_csem_sm' = ///
                cond(`abs_ev_sm'   >= 0, sqrt(`abs_ev_sm'),   .) if `touse'
            quietly generate double `rcs_full_sm' = ///
                cond(`rel_full_sm' >= 0, sqrt(`rel_full_sm'), .) if `touse'
            quietly generate double `rcs_la_sm' = ///
                cond(`rel_la_sm'   >= 0, sqrt(`rel_la_sm'),   .) if `touse'
            quietly generate double `rcs_unc_sm' = ///
                cond(`rel_unc_sm'  >= 0, sqrt(`rel_unc_sm'),  .) if `touse'
        }
        else {
            quietly generate double `abs_csem_sm' = sqrt(max(`abs_ev_sm',   0)) if `touse'
            quietly generate double `rcs_full_sm' = sqrt(max(`rel_full_sm', 0)) if `touse'
            quietly generate double `rcs_la_sm'   = sqrt(max(`rel_la_sm',   0)) if `touse'
            quietly generate double `rcs_unc_sm'  = sqrt(max(`rel_unc_sm',  0)) if `touse'
        }
    }
    
    /* ========================================================
       Write output variables
       ======================================================== */
    
    quietly generate double `prefix'_score    = `pm'       if `touse'
    quietly generate double `prefix'_abs_ev   = `abs_ev'   if `touse'
    quietly generate double `prefix'_abs_csem = `abs_csem' if `touse'
    quietly generate double `prefix'_cov_xim  = `cov_xim'  if `touse'
    quietly generate double `prefix'_vabs_an  = `vabs'     if `touse'
    
    if `has_boot' {
        quietly generate double `prefix'_vabs_bs  = `vabs_bs' if `touse'
    }
    
    if "`smooth'" != "" {
        quietly generate double `prefix'_abs_ev_sm   = `abs_ev_sm'   if `touse'
        quietly generate double `prefix'_abs_csem_sm = `abs_csem_sm' if `touse'
    }
    
    if "`method'" == "full" {
        quietly generate double `prefix'_rel_ev    = `rel_full' if `touse'
        quietly generate double `prefix'_rel_csem  = `rcs_full' if `touse'
        quietly generate double `prefix'_vrev_an   = `vfull'    if `touse'
        if `has_boot' {
            quietly generate double `prefix'_vrev_bs = `vfull_bs' if `touse'
        }
        if "`smooth'" != "" {
            quietly generate double `prefix'_rel_ev_sm   = `rel_full_sm' if `touse'
            quietly generate double `prefix'_rel_csem_sm = `rcs_full_sm' if `touse'
        }
    }
    else if "`method'" == "large_a" {
        quietly generate double `prefix'_rel_ev    = `rel_la' if `touse'
        quietly generate double `prefix'_rel_csem  = `rcs_la' if `touse'
        quietly generate double `prefix'_vrev_an   = `vla'    if `touse'
        if `has_boot' {
            quietly generate double `prefix'_vrev_bs = `vla_bs' if `touse'
        }
        if "`smooth'" != "" {
            quietly generate double `prefix'_rel_ev_sm   = `rel_la_sm' if `touse'
            quietly generate double `prefix'_rel_csem_sm = `rcs_la_sm' if `touse'
        }
    }
    else if "`method'" == "uncorrelated" {
        quietly generate double `prefix'_rel_ev    = `rel_unc' if `touse'
        quietly generate double `prefix'_rel_csem  = `rcs_unc' if `touse'
        quietly generate double `prefix'_vrev_an   = `vunc'    if `touse'
        if `has_boot' {
            quietly generate double `prefix'_vrev_bs = `vunc_bs' if `touse'
        }
        if "`smooth'" != "" {
            quietly generate double `prefix'_rel_ev_sm   = `rel_unc_sm' if `touse'
            quietly generate double `prefix'_rel_csem_sm = `rcs_unc_sm' if `touse'
        }
    }
    else { /* all */
        quietly generate double `prefix'_rel_ev_full   = `rel_full' if `touse'
        quietly generate double `prefix'_rel_csem_full = `rcs_full' if `touse'
        quietly generate double `prefix'_vrev_an_full  = `vfull'    if `touse'
        
        quietly generate double `prefix'_rel_ev_la     = `rel_la' if `touse'
        quietly generate double `prefix'_rel_csem_la   = `rcs_la' if `touse'
        quietly generate double `prefix'_vrev_an_la    = `vla'    if `touse'
        
        quietly generate double `prefix'_rel_ev_unc    = `rel_unc' if `touse'
        quietly generate double `prefix'_rel_csem_unc  = `rcs_unc' if `touse'
        quietly generate double `prefix'_vrev_an_unc   = `vunc'    if `touse'
        
        quietly generate double `prefix'_rel_ev        = `rel_full' if `touse'
        quietly generate double `prefix'_rel_csem      = `rcs_full' if `touse'
        quietly generate double `prefix'_vrev_an       = `vfull'    if `touse'
        
        if `has_boot' {
            quietly generate double `prefix'_vrev_bs_full = `vfull_bs' if `touse'
            quietly generate double `prefix'_vrev_bs_la   = `vla_bs'   if `touse'
            quietly generate double `prefix'_vrev_bs_unc  = `vunc_bs'  if `touse'
            quietly generate double `prefix'_vrev_bs      = `vfull_bs' if `touse'
        }
        
        if "`smooth'" != "" {
            quietly generate double `prefix'_rel_ev_sm_full   = `rel_full_sm' if `touse'
            quietly generate double `prefix'_rel_csem_sm_full = `rcs_full_sm' if `touse'
            quietly generate double `prefix'_rel_ev_sm_la     = `rel_la_sm'   if `touse'
            quietly generate double `prefix'_rel_csem_sm_la   = `rcs_la_sm'   if `touse'
            quietly generate double `prefix'_rel_ev_sm_unc    = `rel_unc_sm'  if `touse'
            quietly generate double `prefix'_rel_csem_sm_unc  = `rcs_unc_sm'  if `touse'
            quietly generate double `prefix'_rel_ev_sm        = `rel_full_sm' if `touse'
            quietly generate double `prefix'_rel_csem_sm      = `rcs_full_sm' if `touse'
        }
    }
    
    /* ========================================================
       Overall (population-level) error variances and coefficients
       
       sigma^2(I)     = sigma^2(i)/D            (Brennan eq 2.26)
       sigma^2(pI)    = sigma^2(pi)/D           (Brennan eq 2.27)
       sigma^2(delta) = sigma^2(pI)             (Brennan eq 2.34)
       sigma^2(Delta) = sigma^2(I)+sigma^2(pI)  (Brennan eq 2.32)
       Erho2 = sigma^2(p) / [sigma^2(p)+sigma^2(delta)]   (eq 2.40)
       Phi   = sigma^2(p) / [sigma^2(p)+sigma^2(Delta)]   (eq 2.41)
       ======================================================== */
    
    tempname s2I s2pI abs_ev_o abs_sem_o rel_ev_o rel_sem_o erho2 phi
    
    scalar `s2I'  = scalar(`s2i') / `D'
    scalar `s2pI' = scalar(`s2r') / `D'
    
    scalar `abs_ev_o'  = scalar(`s2I') + scalar(`s2pI')
    scalar `abs_sem_o' = sqrt(scalar(`abs_ev_o'))
    scalar `rel_ev_o'  = scalar(`s2pI')
    scalar `rel_sem_o' = sqrt(scalar(`rel_ev_o'))
    
    if scalar(`s2p') + scalar(`rel_ev_o') > 0 {
        scalar `erho2' = scalar(`s2p') / (scalar(`s2p') + scalar(`rel_ev_o'))
    }
    else {
        scalar `erho2' = .
    }
    if scalar(`s2p') + scalar(`abs_ev_o') > 0 {
        scalar `phi' = scalar(`s2p') / (scalar(`s2p') + scalar(`abs_ev_o'))
    }
    else {
        scalar `phi' = .
    }
    
    /* Phi(lambda) (Brennan & Kane 1977; Brennan 2001 eq. 2.55):
         Phi(lambda) = [s2(p) + (Xbar - lambda)^2 - s2(Xbar)] /
                       [s2(p) + (Xbar - lambda)^2 - s2(Xbar) + s2(Delta)]
       where s2(Xbar) = [s2(p) + s2(I) + s2(pI)] / n_p   (eq. 2.38)
    */
    
    tempname phi_lambda s2_xbar dev2 num_phl den_phl
    scalar `phi_lambda' = .
    if `has_cut' {
        scalar `s2_xbar' = (scalar(`s2p') + scalar(`s2I') + scalar(`s2pI')) / `A'
        scalar `dev2'    = (scalar(`grand') - `cutpoint')^2
        scalar `num_phl' = scalar(`s2p') + scalar(`dev2') - scalar(`s2_xbar')
        scalar `den_phl' = scalar(`num_phl') + scalar(`abs_ev_o')
        if scalar(`den_phl') > 0 {
            scalar `phi_lambda' = scalar(`num_phl') / scalar(`den_phl')
        }
    }
    
    /* ========================================================
       Build return matrices
       ======================================================== */
    
    tempname VC ANOVA OVERALL COEFS
    
    matrix `VC' = (scalar(`s2p'), scalar(`s2i'), scalar(`s2r'))
    matrix colnames `VC' = p i pi
    matrix rownames `VC' = sigma2
    
    matrix `ANOVA' = ///
        ( scalar(`dfp'), scalar(`SSperson'), scalar(`MSp'), scalar(`s2p') \  ///
          scalar(`dfi'), scalar(`SSitem'),   scalar(`MSi'), scalar(`s2i') \  ///
          scalar(`dfr'), scalar(`SSresid'),  scalar(`MSr'), scalar(`s2r') )
    matrix colnames `ANOVA' = df SS MS sigma2
    matrix rownames `ANOVA' = p i pi
    
    matrix `OVERALL' = ///
        ( scalar(`abs_ev_o') \ scalar(`abs_sem_o') \ ///
          scalar(`rel_ev_o') \ scalar(`rel_sem_o') )
    matrix colnames `OVERALL' = estimate
    matrix rownames `OVERALL' = abs_ev abs_sem rel_ev rel_sem
    
    if `has_cut' {
        matrix `COEFS' = ( scalar(`erho2') \ scalar(`phi') \ scalar(`phi_lambda') )
        matrix colnames `COEFS' = estimate
        matrix rownames `COEFS' = erho2 phi phi_lambda
    }
    else {
        matrix `COEFS' = ( scalar(`erho2') \ scalar(`phi') )
        matrix colnames `COEFS' = estimate
        matrix rownames `COEFS' = erho2 phi
    }
    
    /* ========================================================
       Return r() results
       ======================================================== */
    
    if "`smooth'" != "" {
        tempname SMOOTHFITS_R
        matrix `SMOOTHFITS_R' = `SMOOTHFITS'
        return matrix smooth_fits = `SMOOTHFITS_R'
        if "`excludeextremes'" != "" {
            return scalar n_floor   = `n_floor'
            return scalar n_ceiling = `n_ceiling'
            return scalar n_fit     = `n_fit'
        }
    }
    if `has_boot' {
        return matrix boot = `BSVARS'
        return scalar bootb    = `bootb'
        return scalar bootseed = `bootseed'
    }
    return matrix coefficients = `COEFS'
    return matrix overall      = `OVERALL'
    return matrix anova        = `ANOVA'
    return matrix vc           = `VC'
    
    if `has_cut' {
        return scalar cutpoint   = `cutpoint'
        return scalar phi_lambda = scalar(`phi_lambda')
    }
    return scalar phi   = scalar(`phi')
    return scalar erho2 = scalar(`erho2')
    
    return scalar relative_sem       = scalar(`rel_sem_o')
    return scalar relative_error_var = scalar(`rel_ev_o')
    return scalar absolute_sem       = scalar(`abs_sem_o')
    return scalar absolute_error_var = scalar(`abs_ev_o')
    
    return scalar sigma2_pi = scalar(`s2r')
    return scalar sigma2_i  = scalar(`s2i')
    return scalar sigma2_p  = scalar(`s2p')
    
    return scalar nitems_D   = `D'
    return scalar I_observed = `Iobs'
    return scalar A          = `A'
    
    return local smooth          "`smooth'"
    return local excludeextremes "`excludeextremes'"
    return local prefix          "`prefix'"
    return local semethod        "`semethod'"
    return local method          "`method'"

    /* Also stash the same identifiers as dataset characteristics so
       that gtcsem_plot can recover them even after intervening
       r-class commands have wiped r(). */
    char _dta[gtcsem_prefix]          "`prefix'"
    char _dta[gtcsem_method]          "`method'"
    char _dta[gtcsem_semethod]        "`semethod'"
    char _dta[gtcsem_smooth]          "`smooth'"
    char _dta[gtcsem_excludeextremes] "`excludeextremes'"
    
    /* ========================================================
       Display
       ======================================================== */
    
    di as text ""
    di as text _dup(64) "-"
    di as text "Conditional SEMs in Generalizability Theory"
    di as text _dup(64) "-"
    di as text "Design          :  univariate single-facet (p x i, crossed)"
    di as text "Persons (n_p)   :  " as result `A'
    di as text "G-study items   :  " as result `Iobs'
    if `D' != `Iobs' {
        di as text "D-study items   :  " as result `D' ///
           as text "  (extrapolated; n_i' != n_i)"
    }
    else {
        di as text "D-study items   :  " as result `D'
    }
    di as text "Method          :  " as result "`method'"
    di as text "SE method       :  " as result "`semethod'"
    if "`smooth'" != "" {
        di as text "Smoothing       :  " as result "quadratic on observed score"
        if "`excludeextremes'" != "" {
            di as text "Smoothing fit   :  " ///
               as result "n_fit = `n_fit'" ///
               as text " (excluded " as result `n_floor' ///
               as text " floor + " as result `n_ceiling' ///
               as text " ceiling case(s))"
        }
    }
    if `has_cut' {
        di as text "Cutpoint        :  " as result %12.6f `cutpoint'
    }
    di as text "Output prefix   :  " as result "`prefix'"
    di as text ""
    
    di as text "ANOVA table"
    di as text _dup(64) "-"
    di as text "  Effect    df              SS              MS         sigma^2"
    di as text _dup(64) "-"
    di as text "  p     " ///
       as result %8.0f scalar(`dfp') "  " ///
       as result %14.6f scalar(`SSperson') "  " ///
       as result %14.6f scalar(`MSp') "  " ///
       as result %12.6f scalar(`s2p')
    di as text "  i     " ///
       as result %8.0f scalar(`dfi') "  " ///
       as result %14.6f scalar(`SSitem') "  " ///
       as result %14.6f scalar(`MSi') "  " ///
       as result %12.6f scalar(`s2i')
    di as text "  pi    " ///
       as result %8.0f scalar(`dfr') "  " ///
       as result %14.6f scalar(`SSresid') "  " ///
       as result %14.6f scalar(`MSr') "  " ///
       as result %12.6f scalar(`s2r')
    di as text ""
    
    di as text "D-study error variances and SEMs (n_i' = " as result `D' as text ")"
    di as text _dup(64) "-"
    di as text "  sigma^2(Delta) = " as result %10.6f scalar(`abs_ev_o') ///
       as text "      sigma(Delta) = " as result %8.6f scalar(`abs_sem_o') ///
       as text "  (absolute)"
    di as text "  sigma^2(delta) = " as result %10.6f scalar(`rel_ev_o') ///
       as text "      sigma(delta) = " as result %8.6f scalar(`rel_sem_o') ///
       as text "  (relative)"
    di as text ""
    
    di as text "Reliability-like coefficients"
    di as text _dup(64) "-"
    di as text "  Generalizability coef.    E rho^2     = " as result %8.4f scalar(`erho2')
    di as text "  Dependability coef.       Phi         = " as result %8.4f scalar(`phi')
    if `has_cut' {
        di as text "  Dep. coef. for cutpoint   Phi(lambda) = " ///
           as result %8.4f scalar(`phi_lambda') ///
           as text "   (lambda = " as result %6.3f `cutpoint' as text ")"
    }
    di as text ""
    
    if "`smooth'" != "" {
        di as text "Quadratic smoothing fits  (y = b0 + b1*score + b2*score^2)"
        di as text _dup(74) "-"
        di as text "  Quantity              b0         b1         b2        R^2       RMSE"
        di as text _dup(74) "-"
        local nrows = rowsof(`SMOOTHFITS')
        local rnames : rowfullnames `SMOOTHFITS'
        forvalues r = 1/`nrows' {
            local rname : word `r' of `rnames'
            local rname_padded = "`rname'" + "                  "
            local rname_padded = substr("`rname_padded'", 1, 18)
            di as text "  `rname_padded'  " ///
               as result %9.5f `SMOOTHFITS'[`r', 1] "  " ///
               as result %9.5f `SMOOTHFITS'[`r', 2] "  " ///
               as result %9.5f `SMOOTHFITS'[`r', 3] "  " ///
               as result %9.4f `SMOOTHFITS'[`r', 4] "  " ///
               as result %9.5f `SMOOTHFITS'[`r', 5]
        }
        di as text ""
    }
    
    if `has_boot' {
        /* Compute summary statistics across persons */
        tempname mean_an_abs mean_bs_abs mean_an_rel mean_bs_rel
        quietly summarize `prefix'_vabs_an, meanonly
        scalar `mean_an_abs' = r(mean)
        quietly summarize `prefix'_vabs_bs, meanonly
        scalar `mean_bs_abs' = r(mean)
        quietly summarize `prefix'_vrev_an, meanonly
        scalar `mean_an_rel' = r(mean)
        quietly summarize `prefix'_vrev_bs, meanonly
        scalar `mean_bs_rel' = r(mean)
        
        di as text "Mean variance of estimator across persons"
        di as text _dup(64) "-"
        if "`semethod'" == "both" {
            di as text "  Quantity         Analytical       Bootstrap       Ratio (Bs/An)"
            di as text _dup(64) "-"
            di as text "  abs_ev      " ///
               as result %14.6e scalar(`mean_an_abs') "  " ///
               as result %14.6e scalar(`mean_bs_abs') "   " ///
               as result %8.4f (scalar(`mean_bs_abs')/scalar(`mean_an_abs'))
            di as text "  rel_ev      " ///
               as result %14.6e scalar(`mean_an_rel') "  " ///
               as result %14.6e scalar(`mean_bs_rel') "   " ///
               as result %8.4f (scalar(`mean_bs_rel')/scalar(`mean_an_rel'))
        }
        else {
            /* bootstrap only */
            di as text "  Quantity                  Bootstrap"
            di as text _dup(40) "-"
            di as text "  abs_ev      " as result %14.6e scalar(`mean_bs_abs')
            di as text "  rel_ev      " as result %14.6e scalar(`mean_bs_rel')
        }
        di as text ""
    }
    
    di as text "Per-person CSEMs written to dataset (prefix: " ///
       as result "`prefix'" as text ")"
end


/* ============================================================
   Helper: _gtcsem_qfit
   ============================================================
   Quadratic regression of yvar on pmv and pm2v, generates yhat
   with the OLS-fitted values, and returns coefficients, R^2,
   RMSE, and N as r() scalars.
   
   Arguments (positional):
     yvar     - Y variable (input, must exist)
     yhat     - name of variable to create with fitted values
     pmv      - regressor: observed score
     pm2v     - regressor: observed score squared
     touse    - sample selector
   ============================================================ */

capture program drop _gtcsem_qfit
program define _gtcsem_qfit, rclass
    args yvar yhat pmv pm2v touse_var
    tempname b
    quietly regress `yvar' `pmv' `pm2v' if `touse_var'
    matrix `b' = e(b)
    local b0 = `b'[1, 3]
    local b1 = `b'[1, 1]
    local b2 = `b'[1, 2]
    local r2_   = e(r2)
    local n_    = e(N)
    /* RMSE = sqrt(SSE / N) (population-style, matches R csem_g1f).
       Stata's e(rmse) = sqrt(SSE / (N-k-1)) is reported by `regress`
       but we use the unadjusted RMSE for cross-package parity. */
    local rmse_ = sqrt(e(rss) / e(N))
    /* yhat must already exist (caller pre-creates it) */
    quietly replace `yhat' = ///
        `b0' + `b1' * `pmv' + `b2' * `pm2v' if `touse_var'
    return scalar b0   = `b0'
    return scalar b1   = `b1'
    return scalar b2   = `b2'
    return scalar R2   = `r2_'
    return scalar RMSE = `rmse_'
    return scalar n    = `n_'
end


/* ============================================================
   Mata bootstrap implementation
   ============================================================
   _gtcsem_boot_wrap() reads the data via st_data, performs
   item-resampling bootstrap for each person, writes per-person
   variances to BSVARS matrix in Stata, and stores results in
   the four bootstrap variables via st_store.
   
   Parity with R:
   - Logic verified against bootstrap_csem_g1f() in R: identical
     numbers per person when using the same seed and PRNG.
     (R and Stata use different PRNGs, so numbers will differ
     at finite B but converge as B grows.)
   ============================================================ */

mata:
mata clear

void _gtcsem_boot_wrap(string scalar varlist,
                        string scalar touse,
                        real scalar B,
                        real scalar D,
                        real scalar A,
                        real scalar dots_step,
                        string scalar vabs_bs_name,
                        string scalar vfull_bs_name,
                        string scalar vla_bs_name,
                        string scalar vunc_bs_name,
                        string scalar BSVARS_name)
{
    real matrix X, idx_mat, Xb, bb_mat, Xb_c, results
    real rowvector item_means_row
    real colvector b_full_col, xrow, pm_b
    real colvector rowss, rowvar, abs_ev, cov_b
    real colvector full_b, larg_b, unco_b
    real scalar I, a, i, grand, sigma2_item
    real scalar fact_full, fact_full_cov, dots_drawn
    
    /* Read sigma^2(item) from named Stata scalar */
    sigma2_item = st_numscalar("gtcsem_s2i")
    
    /* Load X (A x I) restricted to touse */
    X = st_data(., varlist, touse)
    I = cols(X)
    
    item_means_row = mean(X)
    grand          = mean(item_means_row')
    b_full_col     = (item_means_row :- grand)'
    
    fact_full     = (A + 1) / (A - 1)
    fact_full_cov = A / (A - 1)
    
    results = J(A, 4, .)
    
    Xb     = J(B, I, 0)
    bb_mat = J(B, I, 0)
    
    dots_drawn = 0
    
    for (a = 1; a <= A; a++) {
        xrow = X[a, .]'
        
        /* B x I matrix of integer indices in [1, I] */
        idx_mat = ceil(I :* runiform(B, I))
        
        for (i = 1; i <= I; i++) {
            Xb[., i]     = xrow[idx_mat[., i]]
            bb_mat[., i] = b_full_col[idx_mat[., i]]
        }
        
        pm_b   = (Xb * J(I, 1, 1)) :/ I    /* row sums / I */
        Xb_c   = Xb :- (pm_b * J(1, I, 1))
        rowss  = (Xb_c :* Xb_c) * J(I, 1, 1)
        rowvar = rowss :/ (I - 1)
        abs_ev = rowvar :/ D
        cov_b  = (Xb_c :* bb_mat) * J(I, 1, 1) :/ (I - 1)
        
        full_b = fact_full :* abs_ev :+ sigma2_item / D :- 
                 fact_full_cov :* (2 :* cov_b :/ D)
        larg_b = abs_ev :+ sigma2_item / D :- 2 :* cov_b :/ D
        unco_b = abs_ev :- sigma2_item / D
        
        results[a, 1] = variance(abs_ev)
        results[a, 2] = variance(full_b)
        results[a, 3] = variance(larg_b)
        results[a, 4] = variance(unco_b)
        
        if (dots_step > 0 & mod(a, dots_step) == 0) {
            printf(".")
            dots_drawn = dots_drawn + 1
            if (mod(dots_drawn, 50) == 0) {
                printf("   %g\n", a)
            }
            displayflush()
        }
    }
    
    if (dots_step > 0 & mod(dots_drawn, 50) != 0) {
        printf("   %g\n", A)
        displayflush()
    }
    
    /* Store per-person variances directly into Stata variables */
    st_store(., vabs_bs_name,  touse, results[., 1])
    st_store(., vfull_bs_name, touse, results[., 2])
    st_store(., vla_bs_name,   touse, results[., 3])
    st_store(., vunc_bs_name,  touse, results[., 4])
    
    /* Also expose results as a Stata matrix */
    st_matrix(BSVARS_name, results)
    st_matrixcolstripe(BSVARS_name,
        (J(4, 1, ""), ("v_abs"\"v_full"\"v_la"\"v_unc")))
}
end

