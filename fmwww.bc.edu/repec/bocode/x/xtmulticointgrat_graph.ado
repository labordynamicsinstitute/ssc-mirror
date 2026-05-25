*! xtmulticointgrat_graph v1.0.0  22may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Publication-quality diagnostic graphs after {bf:xtmulticointgrat}.
*!
*! Layouts:
*!   default     -- 2x3 dashboard (suitable for OBES / JBES / JAE figures)
*!   factors     -- factor time-paths + loadings heatmap
*!   residuals   -- idiosyncratic e_i,t spaghetti + stage-2 u_i,t
*!   stage       -- first-stage S_i,t cumulated residuals per panel
*!   adf         -- distribution of per-i ADF statistics with reference c.v.
*!   compact     -- single page minimal panel for presentations

program define xtmulticointgrat_graph
    version 14.0

    * Prefer persistent globals/matrices that survive across commands.
    * Fall back to r() outputs from a just-finished xtmulticointgrat call.
    tempname AdfMat LoadMat MqMat
    cap mat `AdfMat' = _xtmcg_adf_idio
    if _rc cap mat `AdfMat' = _xtmcg_adf_indiv
    if _rc cap mat `AdfMat' = r(adf_idio)
    if _rc cap mat `AdfMat' = r(adf_indiv)
    cap mat `LoadMat' = _xtmcg_loadings
    if _rc cap mat `LoadMat' = r(loadings)
    cap mat `MqMat' = _xtmcg_mq_factors
    if _rc cap mat `MqMat' = r(mq_factors)

    local r_trend    "${XTMCG_TREND}"
    if "`r_trend'" == ""    local r_trend    "`r(trend)'"
    local r_depvar   "${XTMCG_DEPVAR}"
    if "`r_depvar'" == ""   local r_depvar   "`r(depvar)'"
    local r_indep    "${XTMCG_INDEP}"
    if "`r_indep'" == ""    local r_indep    "`r(indep)'"
    local r_approach "${XTMCG_APPROACH}"
    if "`r_approach'" == "" local r_approach "`r(approach)'"
    local r_Nu = "${XTMCG_N}"
    if "`r_Nu'" == ""       local r_Nu = "`=r(N)'"
    local r_Tu = "${XTMCG_T}"
    if "`r_Tu'" == ""       local r_Tu = "`=r(T)'"

    syntax [, LAYout(string) SAVE(string) NAME(string) SCHeme(string) ///
              TItle(string) NOTE(string) SUBtitle(string) ///
              YColor(string) XColor(string) HEAtcolors(string) ///
              SCALE(real 1) APProach(string) TRend(string) ]

    * Sanity: at least one source of data must exist
    cap confirm variable _xtmcg_e_i
    local has_factor = (_rc == 0)
    cap confirm variable _xtmcg_u_i
    local has_indep  = (_rc == 0)
    cap confirm matrix `AdfMat'
    local has_adf = (_rc == 0)
    if !`has_factor' & !`has_indep' & !`has_adf' {
        di as err "no xtmulticointgrat output found in dataset or r()"
        di as err "run {bf:xtmulticointgrat} first"
        exit 301
    }

    if "`layout'"  == "" local layout default
    if "`scheme'"  == "" local scheme s1color
    if "`name'"    == "" local name xtmcg_diag
    if "`ycolor'"  == "" local ycolor navy
    if "`xcolor'"  == "" local xcolor maroon
    if "`heatcolors'" == "" local heatcolors "white forest_green"

    * Grab xtset time variable
    qui xtset
    local ivar = r(panelvar)
    local tvar = r(timevar)

    * Default approach inferred from saved vars
    if "`approach'" == "" {
        if "`r_approach'" != "" local approach "`r_approach'"
        else if `has_factor'    local approach "factors"
        else                     local approach "indep"
    }
    if "`trend'" == "" {
        local trend "`r_trend'"
        if "`trend'" == "" local trend "c"
    }

    local depv = "`r_depvar'"
    local indv = "`r_indep'"
    local Nu   = "`r_Nu'"
    local Tu   = "`r_Tu'"

    qui xtset
    local ivar = r(panelvar)
    local tvar = r(timevar)

    if "`title'" == "" {
        if "`approach'" == "indep" {
            local title "Panel multicointegration (cross-section independent)"
        }
        else {
            local title "Panel multicointegration with common factors"
        }
    }
    if "`subtitle'" == "" {
        local subtitle "BR-CS (2006)  N=`Nu', T=`Tu', det=`trend'"
    }
    if "`note'" == "" {
        local note ""
    }

    local gopts graphregion(color(white) margin(small))                           ///
                plotregion(color(white) margin(zero))                              ///
                scheme(`scheme') ysize(4) xsize(6)

    * ===================================================================
    *  Auto-pick layout
    * ===================================================================
    if "`approach'" == "indep" & "`layout'" == "default" {
        local layout adf
    }

    * ===================================================================
    *  LAYOUT: factors  --  time-paths of common factors + loadings heatmap
    * ===================================================================
    if "`layout'" == "factors" | "`layout'" == "default" {
        cap confirm variable _xtmcg_F1
        if _rc {
            di as err "no estimated factors found in dataset"
            exit 198
        }
        unab fvars : _xtmcg_F*
        local nf : word count `fvars'

        local flines
        local flegend
        local fcolors "navy maroon forest_green dkorange teal cranberry sienna"
        local cidx = 0
        foreach fv of local fvars {
            local ++cidx
            local col : word `cidx' of `fcolors'
            if "`col'" == "" local col gs8
            local flines `flines' (line `fv' `tvar', lcolor(`col') lwidth(medthick))
            local fnum = subinstr("`fv'", "_xtmcg_F", "", 1)
            local flegend `flegend' `cidx' "F`fnum'"
        }

        qui twoway `flines',                                                     ///
            name(g_factors, replace) `gopts'                                      ///
            title("(a) Estimated common factors  F̂_t", size(small) color(black)) ///
            ytitle("Common factor (level)") xtitle("`tvar'")                      ///
            yline(0, lp(dash) lc(gs10))                                            ///
            legend(order(`flegend') rows(1) size(vsmall) region(lwidth(none)))

        * Loadings heatmap (factor x panel)  -- use heatplot if available
        cap confirm matrix `LoadMat'
        if _rc == 0 {
            cap which heatplot
            local has_heat = (_rc == 0)
            if `has_heat' {
                preserve
                    clear
                    local Nl = rowsof(`LoadMat')
                    local rl = colsof(`LoadMat')
                    qui set obs `=`Nl' * `rl''
                    qui gen _xtmcg_loadP = mod(_n - 1, `Nl') + 1
                    qui gen _xtmcg_loadF = floor((_n - 1)/`Nl') + 1
                    qui gen double _xtmcg_loadV = .
                    forvalues i = 1/`Nl' {
                        forvalues j = 1/`rl' {
                            qui replace _xtmcg_loadV = `LoadMat'[`i', `j']        ///
                                if _xtmcg_loadP == `i' & _xtmcg_loadF == `j'
                        }
                    }
                    cap heatplot _xtmcg_loadV _xtmcg_loadF _xtmcg_loadP,          ///
                        name(g_load, replace) `gopts'                              ///
                        title("(b) Factor loadings π_i,k", size(small) color(black)) ///
                        xtitle("Factor index") ytitle("Panel index")               ///
                        colors(`heatcolors')                                        ///
                        cuts(-2(0.25)2)
                restore
            }
            else {
            * Fallback: bar chart of average abs loading per factor
            tempname L
            mat `L' = `LoadMat'
            local rl = colsof(`L')
            local Nl = rowsof(`L')
            preserve
                clear
                qui set obs `rl'
                qui gen factor = _n
                qui gen double mean_abs = .
                qui gen double sd_load = .
                forvalues j = 1/`rl' {
                    local s = 0
                    local s2 = 0
                    forvalues i = 1/`Nl' {
                        local s  = `s' + abs(`L'[`i', `j'])
                        local s2 = `s2' + `L'[`i', `j']^2
                    }
                    qui replace mean_abs = `s'/`Nl' in `j'
                    qui replace sd_load = sqrt(`s2'/`Nl' - (`s'/`Nl')^2) in `j'
                }
                qui graph bar (asis) mean_abs, over(factor)                       ///
                    name(g_load, replace) `gopts'                                  ///
                    title("(b) Mean |loading| per factor", size(small)             ///
                    color(black)) ytitle("Mean |π_i,k|")
                restore
            }
        }
    }

    * ===================================================================
    *  LAYOUT: residuals  --  idiosyncratic e_i,t and stage-2 u_i,t spaghetti
    * ===================================================================
    if "`layout'" == "residuals" | "`layout'" == "default" {
        cap confirm variable _xtmcg_e_i
        if _rc {
            di as err "no idiosyncratic component found (run with common factors)"
        }
        else {
            qui xtline _xtmcg_e_i, overlay name(g_eidio, replace) `gopts'         ///
                title("(c) Idiosyncratic component  e_i,t  (spaghetti)",          ///
                    size(small) color(black))                                       ///
                ytitle("e_i,t") xtitle("`tvar'")                                    ///
                legend(off) yline(0, lp(dash) lc(gs10))

            qui xtline _xtmcg_u_i, overlay name(g_ui, replace) `gopts'            ///
                title("(d) Stage-2 residual  u_i,t  (spaghetti)",                  ///
                    size(small) color(black))                                       ///
                ytitle("u_i,t") xtitle("`tvar'")                                    ///
                legend(off) yline(0, lp(dash) lc(gs10))
        }
    }

    * ===================================================================
    *  LAYOUT: stage  --  cumulated stage-1 residual S_i,t spaghetti
    * ===================================================================
    if "`layout'" == "stage" | "`layout'" == "default" {
        cap confirm variable _xtmcg_S_i
        if _rc {
            * skip
        }
        else {
            qui xtline _xtmcg_S_i, overlay name(g_S, replace) `gopts'             ///
                title("(e) Cumulated stage-1 residual  S_i,t = Σϑ̂_i",            ///
                    size(small) color(black))                                       ///
                ytitle("S_i,t") xtitle("`tvar'")                                    ///
                legend(off) yline(0, lp(dash) lc(gs10))
        }
    }

    * ===================================================================
    *  LAYOUT: adf  --  distribution of per-i ADF t-stats with reference c.v.
    * ===================================================================
    if "`layout'" == "adf" | "`layout'" == "default" {
        if `has_adf' {
            local Na = rowsof(`AdfMat')
            preserve
                clear
                qui set obs `Na'
                qui gen panel_i = _n
                qui gen double adf_t = .
                qui gen double adf_rho = .
                qui gen long lag = .
                forvalues i = 1/`Na' {
                    qui replace adf_rho = `AdfMat'[`i', 1] in `i'
                    qui replace adf_t   = `AdfMat'[`i', 2] in `i'
                    qui replace lag     = `AdfMat'[`i', 4] in `i'
                }
                local cv5  = -2.86
                if "`trend'" == "ct" | "`trend'" == "ctt" local cv5 = -3.41
                if "`trend'" == "none" local cv5 = -1.95

                qui histogram adf_t, name(g_adfhist, replace) `gopts'              ///
                    title("(f) Distribution of per-i ADF t-statistics",            ///
                        size(small) color(black))                                   ///
                    xtitle("ADF t-statistic") ytitle("Density")                     ///
                    fcolor(`ycolor'%50) lcolor(`ycolor')                            ///
                    xline(`cv5', lp(dash) lc(maroon))                               ///
                    note("5% asymptotic c.v. = `cv5'", size(vsmall))
                qui graph dot adf_t, over(panel_i, sort(adf_t))                    ///
                    name(g_adfdot, replace) `gopts'                                 ///
                    title("(g) Per-i ADF t-stats (sorted)",                         ///
                        size(small) color(black))                                   ///
                    yline(`cv5', lp(dash) lc(maroon))                               ///
                    ytitle("ADF t") marker(1, msize(small) mcolor(`ycolor'))
            restore
        }
    }

    * ===================================================================
    *  COMBINE PANELS
    * ===================================================================
    if "`layout'" == "default" {
        local glist
        foreach g in g_factors g_load g_eidio g_ui g_S g_adfhist {
            cap graph describe `g'
            if !_rc local glist `glist' `g'
        }
        if "`glist'" != "" {
            graph combine `glist', cols(2)                                         ///
                name(`name', replace) iscale(`=0.7*`scale'')                         ///
                title("`title'", size(small) color(black))                           ///
                subtitle("`subtitle'", size(vsmall) color(gs6))                      ///
                note("`note'", size(vsmall) color(gs8))                              ///
                graphregion(color(white)) scheme(`scheme')
        }
    }
    else if "`layout'" == "adf" {
        cap graph describe g_adfhist
        if !_rc {
            cap graph describe g_adfdot
            if !_rc {
                graph combine g_adfhist g_adfdot, cols(2) name(`name', replace)   ///
                    iscale(0.85) title("`title'", size(small)) subtitle("`subtitle'", ///
                    size(vsmall)) note("`note'", size(vsmall))                       ///
                    graphregion(color(white)) scheme(`scheme')
            }
            else graph display g_adfhist, name(`name', replace)
        }
    }
    else if "`layout'" == "compact" {
        local glist
        foreach g in g_factors g_eidio {
            cap graph describe `g'
            if !_rc local glist `glist' `g'
        }
        if "`glist'" != "" {
            graph combine `glist', cols(1) name(`name', replace) iscale(1)       ///
                title("`title'", size(small)) subtitle("`subtitle'", size(vsmall)) ///
                note("`note'", size(vsmall)) graphregion(color(white))            ///
                scheme(`scheme')
        }
    }
    else if "`layout'" == "factors" {
        cap graph describe g_load
        if !_rc {
            graph combine g_factors g_load, cols(2) name(`name', replace)        ///
                iscale(0.9) title("`title'", size(small))                          ///
                subtitle("`subtitle'", size(vsmall)) note("`note'", size(vsmall)) ///
                graphregion(color(white)) scheme(`scheme')
        }
        else graph display g_factors, name(`name', replace)
    }
    else if "`layout'" == "residuals" {
        graph combine g_eidio g_ui, cols(1) name(`name', replace) iscale(0.9)     ///
            title("`title'", size(small)) subtitle("`subtitle'", size(vsmall))     ///
            note("`note'", size(vsmall)) graphregion(color(white)) scheme(`scheme')
    }
    else if "`layout'" == "stage" {
        graph display g_S, name(`name', replace)
    }

    if "`save'" != "" {
        graph export "`save'", replace
        di as txt "Saved graph to: " as res "`save'"
    }
end
