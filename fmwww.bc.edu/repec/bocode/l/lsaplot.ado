*! Copyright 2026 Li Linze
*! Version 1.7.4
*! Requires Stata 14.0 or above

capture program drop lsaplot
program define lsaplot
    version 14.0
    
    * ----------------------------------------------------
    * Syntax
    * ----------------------------------------------------
    syntax varlist(min=1 numeric fv) [if] [in], ///
        Treat(varname) ///      Treatment variable
        ID(varname) ///         Panel ID
        Time(varname) ///       Panel Time
        [ ///
        Start(string) ///       Start
        End(string) ///         End
        Base(integer -1) ///    Base
        LEvel(integer 95) ///   CI
        CLuster(varname) ///    SE
        Absorb(string) ///      FE
        Title(string) ///       Title
        Name(string) ///        Name
        NoGraph ///             Suppress
        KeepData ///            Data
        BIN TRIM ///            Modes
        ]

    * ----------------------------------------------------
    * 1. Parsing Name
    * ----------------------------------------------------
    local n_opt ""
    if "`name'" != "" {
        tokenize "`name'", parse(",")
        local clean_n "`1'"
        local n_opt "name(`clean_n', replace)"
    }

    * ----------------------------------------------------
    * 2. Checks & Logic
    * ----------------------------------------------------
    if "`bin'" != "" & "`trim'" != "" {
        di as error "Error: 'bin' and 'trim' mutually exclusive."
        exit 198
    }

    capture graph set window fontface "Times New Roman"
    capture graph set window fontfacemono "Times New Roman"
    capture graph set window fontfacesans "Times New Roman"

    local engine "xtreg"
    local use_time_dummy "yes"
    local run_absorb ""

    if "`absorb'" != "" {
        local engine "reghdfe"
        local use_time_dummy "no"
        local run_absorb "`absorb'"
    }
    else {
        if "`cluster'" != "" & "`cluster'" != "`id'" {
            local engine "reghdfe"
            local use_time_dummy "no"
            local run_absorb "`id' `time'"
            di as txt "Note: Auto-switching to 'reghdfe'."
        }
    }

    set more off
    local depvar : word 1 of `varlist'
    local controls : subinstr local varlist "`depvar'" ""
    
    if "`engine'" == "reghdfe" {
        capture which reghdfe
        if _rc {
            di as error "Error: 'reghdfe' required."
            exit 199
        }
    }
    if "`engine'" == "xtreg" {
        capture xtset
        if _rc {
            di as error "Error: Data not xtset."
            exit 198
        }
    }

    * ----------------------------------------------------
    * 3. Data Processing
    * ----------------------------------------------------
    marksample touse
    if "`cluster'" != "" {
        capture confirm variable `cluster'
        if _rc { 
            di as error "Error: Cluster var not found." 
            exit 111 
        }
        quietly replace `touse' = 0 if missing(`cluster')
    }
    
    preserve
    quietly keep if `touse'
    
    tempvar rel_t
    quietly gen `rel_t' = `time' - `treat'
    quietly replace `rel_t' = . if `treat' == 0 | `treat' == .
    
    quietly summarize `rel_t'
    if r(N) == 0 {
        di as error "Error: No treated observations."
        restore
        exit 2000
    }

    local min_d = r(min)
    local max_d = r(max)
    local s_win = cond("`start'" == "", `min_d', real("`start'"))
    local e_win = cond("`end'"   == "", `max_d', real("`end'"))

    if `s_win' > `e_win' {
         local temp = `s_win'
         local s_win = `e_win'
         local e_win = `temp'
    }

    if "`trim'" != "" {
        di as txt "Mode: TRIMMING [`s_win', `e_win']"
        quietly drop if (`rel_t' < `s_win' | `rel_t' > `e_win') & `rel_t' != .
    }
    else if "`bin'" != "" {
        di as txt "Mode: BINNING [`s_win', `e_win']"
        quietly replace `rel_t' = `s_win' if `rel_t' <= `s_win' & `rel_t' != .
        quietly replace `rel_t' = `e_win' if `rel_t' >= `e_win' & `rel_t' != .
    }

    * === Fix: Even tighter padding (0.1) ===
    local scale_min = `s_win' - 0.1
    local scale_max = `e_win' + 0.1

    capture drop _ls_ev_*
    local d_vars ""
    local v_count 0
    forvalues k = `s_win'/`e_win' {
        if `k' != `base' {
            if `k' < 0  local name "m`=abs(`k')'"
            else        local name "p`k'"
            quietly count if `rel_t' == `k'
            if r(N) > 0 {
                quietly gen byte _ls_ev_`name' = (`rel_t' == `k')
                local d_vars "`d_vars' _ls_ev_`name'"
                local v_count = `v_count' + 1
            }
        }
    }
    if `v_count' == 0 {
        di as error "Error: No dummies generated."
        restore
        exit 2001
    }

    * ----------------------------------------------------
    * 4. Regression
    * ----------------------------------------------------
    local vce_cmd = cond("`cluster'"!="", "cluster `cluster'", "robust")

    if "`engine'" == "xtreg" {
        di as txt "Running xtreg..."
        capture noisily xtreg `depvar' `d_vars' `controls' i.`time', fe vce(`vce_cmd')
    }
    else {
        di as txt "Running reghdfe..."
        if "`use_time_dummy'" == "yes" {
            capture noisily reghdfe `depvar' `d_vars' `controls' i.`time', absorb(`run_absorb') vce(`vce_cmd')
        }
        else {
            capture noisily reghdfe `depvar' `d_vars' `controls', absorb(`run_absorb') vce(`vce_cmd')
        }
    }

    if _rc != 0 {
        di as error "Regression Failed."
        restore
        exit _rc
    }

    * ----------------------------------------------------
    * 5. Extraction
    * ----------------------------------------------------
    tempfile plot_data
    tempname memhold
    postfile `memhold' rel_time coef lb ub using "`plot_data'", replace
    
    local alpha = (100 - `level') / 100
    capture local df = e(df_r)
    if _rc!=0 | "`df'"=="" | "`df'"=="." {
        local t_crit = invnormal(1 - `alpha'/2)
    }
    else {
        local t_crit = invttail(`df', `alpha'/2)
    }

    forvalues k = `s_win'/`e_win' {
        if `k' == `base' {
            post `memhold' (`k') (0) (0) (0)
        }
        else {
            if `k' < 0  local name "m`=abs(`k')'"
            else        local name "p`k'"
            capture local b = _b[_ls_ev_`name']
            if _rc == 0 {
                 local se = _se[_ls_ev_`name']
                 if `se' == 0 | `se' == . {
                     post `memhold' (`k') (.) (.) (.)
                 }
                 else {
                     local low = `b' - `t_crit' * `se'
                     local high = `b' + `t_crit' * `se'
                     post `memhold' (`k') (`b') (`low') (`high')
                 }
            }
            else {
                 post `memhold' (`k') (.) (.) (.)
            }
        }
    }
    postclose `memhold'

    * ----------------------------------------------------
    * 6. Plotting (Maximize Space)
    * ----------------------------------------------------
    if "`nograph'" == "" {
        use "`plot_data'", clear
        sort rel_time
        
        if "`title'" == "" local t_str "Event Study Estimates"
        else local t_str "`title'"
        local s_str "Dependent Variable: `depvar'"
        
        local m_tag ""
        if "`bin'" != "" local m_tag "(Binned)"
        if "`trim'" != "" local m_tag "(Trimmed)"
        local c_tag "Robust"
        if "`cluster'" != "" local c_tag "Cluster: `cluster'"
        local note_str "lsaplot: `engine'`m_tag' | `c_tag' | `level'% CI"
        
        di as txt "Rendering Figure..."

        * === Optimization V1.7.4 ===
        * 1. Remove Aspect Ratio (Kills giant white side-bars)
        * 2. Set GraphRegion Margin to precise values (l=5 r=5) to maximize width
        *    while protecting labels from being cut off.
        * 3. RCAP remains medium/gs5/medthick (High visibility).
        * 4. Scale range tighter (0.1 padding).
        
        twoway ///
        (rcap lb ub rel_time, lc(gs5) lp(solid) lw(medium) msize(medium)) ///
        (scatter coef rel_time, mc(dknavy) msymbol(O) msize(medium)), ///
        `n_opt' /// 
        yline(0, lc(black) lp(dash) lw(vthin)) ///
        xline(`base', lc(cranberry) lp(dash) lw(medthin)) ///
        legend(off) ///
        title(`"`t_str'"', size(medium) color(black)) ///
        subtitle(`"`s_str'"', size(small)) ///
        xtitle("Time Relative to Event", margin(small)) ///
        ytitle("Estimate", margin(small)) ///
        xlabel(`s_win'(1)`e_win', grid glcolor(gs15) glpattern(solid) labsize(small)) ///
        ylabel(, grid glcolor(gs15) glpattern(solid) angle(0) labsize(small) format(%5.2f)) ///
        graphregion(color(white) margin(l=5 r=5 t=2 b=2)) ///  <--- Precise Minimal Margins
        plotregion(lcolor(black) lw(vthin) margin(medium)) ///
        xscale(range(`scale_min' `scale_max')) ///
        note(`"`note_str'"', size(medium)) 
    }

    if "`keepdata'" != "" {
        restore, not
    }
    else {
        restore
    }
end
