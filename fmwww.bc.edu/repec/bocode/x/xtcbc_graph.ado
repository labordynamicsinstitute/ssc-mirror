*! xtcbc_graph.ado — Visualization for xtcbc
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.0.0 — 28 March 2026

program define xtcbc_graph
  version 14.0

  syntax, beta_mat(name) ///
    nbreaks_mat(name) break_dates_mat(name) alpha_mat(name) ///
    ic_mat(name) lambda_mat(name) initial_mat(name) ///
    tmin(integer) tmax(integer) p(integer) ///
    depvar(string) indepvars(string) ///
    opt_lambda(real) n_obs(integer)

  local TT = `tmax' - `tmin' + 1

  // Collect variable names
  local k_idx = 0
  foreach xv of local indepvars {
    local k_idx = `k_idx' + 1
    local varname_`k_idx' "`xv'"
  }

  // ====================================================================
  // GRAPH 1: Coefficient Path Plot
  // ====================================================================

  preserve
  clear

  qui set obs `TT'
  qui gen time = `tmin' + _n - 1

  forvalues k = 1/`p' {
    qui gen beta_`k' = .
    qui gen beta_init_`k' = .
    forvalues t = 1/`TT' {
      qui replace beta_`k' = `beta_mat'[`t', `k'] in `t'
      qui replace beta_init_`k' = `initial_mat'[`t', `k'] in `t'
    }
  }

  // Determine graph layout
  local ncols = 2
  local nrows = ceil(`p' / `ncols')

  // Build individual coefficient plots
  local combined_plots ""
  forvalues k = 1/`p' {
    local vname = "`varname_`k''"
    local nb = `nbreaks_mat'[1, `k']

    // Break lines
    local blines ""
    forvalues bb = 1/`nb' {
      local bd = `break_dates_mat'[`bb', `k']
      local bd_time = `bd' + `tmin' - 1
      local blines `"`blines' xline(`bd_time', lcolor(cranberry%70) lpattern(dash) lwidth(medthin))"'
    }

    // Break count label
    if `nb' == 0 {
      local break_label "no breaks"
    }
    else if `nb' == 1 {
      local break_label "1 break"
    }
    else {
      local break_label "`nb' breaks"
    }

    twoway ///
      (connected beta_`k' time, ///
        lcolor(navy) lwidth(medthick) ///
        msymbol(O) mcolor(navy) msize(medlarge)) ///
      (connected beta_init_`k' time, ///
        lcolor(gs10) lwidth(thin) lpattern(dash) ///
        msymbol(none)), ///
      `blines' ///
      title("{bf:`vname'}", size(medium)) ///
      subtitle("{it:`break_label'}", size(small) color(cranberry)) ///
      ytitle("Coefficient", size(small)) ///
      xtitle("", size(small)) ///
      xlabel(`tmin'(1)`tmax', labsize(vsmall) angle(0)) ///
      legend(off) ///
      graphregion(color(white)) plotregion(color(white)) ///
      name(cbc_coef_`k', replace) nodraw

    local combined_plots "`combined_plots' cbc_coef_`k'"
  }

  // Combine all coefficient plots
  graph combine `combined_plots', ///
    title("{bf:CBCL Estimated Coefficient Paths}", size(medlarge)) ///
    subtitle("Kaddoura (2025) — N=`n_obs', T=`TT'", size(small)) ///
    note("{it:Dashed red lines indicate estimated break dates}", ///
      size(vsmall)) ///
    rows(`nrows') ///
    graphregion(color(white)) ///
    name(xtcbc_coef_paths, replace)

  qui graph export "xtcbc_coefficients.png", ///
    name(xtcbc_coef_paths) replace width(1600)
  di in gr "  Graph saved: xtcbc_coefficients.png"

  restore

  // ====================================================================
  // GRAPH 2: Information Criterion Plot
  // ====================================================================

  preserve
  clear

  local ngrid_ic = rowsof(`ic_mat')
  qui set obs `ngrid_ic'
  qui gen lambda_val = .
  qui gen ic_val = .

  forvalues q = 1/`ngrid_ic' {
    qui replace lambda_val = `lambda_mat'[`q', 1] in `q'
    qui replace ic_val = `ic_mat'[`q', 1] in `q'
  }

  qui gen log_lambda = ln(lambda_val)

  twoway ///
    (line ic_val log_lambda, ///
      lcolor(navy) lwidth(medthick) sort) ///
    , ///
    xline(`= ln(`opt_lambda')', ///
      lcolor(cranberry) lpattern(dash) lwidth(medium)) ///
    title("{bf:Information Criterion}", size(medlarge)) ///
    subtitle("IC{sub:1}({&lambda}) with optimal {&lambda}*" ///
      " = " %8.6f `opt_lambda', size(small)) ///
    ytitle("IC{sub:1}({&lambda})", size(medium)) ///
    xtitle("log({&lambda})", size(medium)) ///
    legend(off) ///
    graphregion(color(white)) plotregion(color(white)) ///
    scheme(s2color) ///
    name(xtcbc_ic, replace)

  qui graph export "xtcbc_ic.png", ///
    name(xtcbc_ic) replace width(1200)
  di in gr "  Graph saved: xtcbc_ic.png"

  restore

  // ====================================================================
  // GRAPH 3: Break Timeline
  // ====================================================================

  preserve
  clear

  // Count total data points needed
  local total_breaks_g = 0
  forvalues k = 1/`p' {
    local nb = `nbreaks_mat'[1, `k']
    local total_breaks_g = `total_breaks_g' + `nb'
  }

  if `total_breaks_g' > 0 {
    qui set obs `total_breaks_g'
    qui gen coeff_id = .
    qui gen str32 coeff_name = ""
    qui gen break_time = .

    local obs_idx = 0
    forvalues k = 1/`p' {
      local nb = `nbreaks_mat'[1, `k']
      local vname = "`varname_`k''"
      forvalues bb = 1/`nb' {
        local obs_idx = `obs_idx' + 1
        local bd = `break_dates_mat'[`bb', `k']
        local bd_time = `bd' + `tmin' - 1
        qui replace coeff_id = `p' - `k' + 1 in `obs_idx'
        qui replace coeff_name = "`vname'" in `obs_idx'
        qui replace break_time = `bd_time' in `obs_idx'
      }
    }

    // Build value labels for y-axis
    forvalues k = 1/`p' {
      local rev_k = `p' - `k' + 1
      local vname = "`varname_`k''"
      label define coeff_lbl `rev_k' "`vname'", add
    }
    label values coeff_id coeff_lbl

    twoway ///
      (scatter coeff_id break_time, ///
        msymbol(D) mcolor(cranberry%80) msize(vlarge)), ///
      title("{bf:Estimated Break Dates by Coefficient}", ///
        size(medlarge)) ///
      subtitle("Kaddoura (2025) — CBCL Break Estimator", ///
        size(small)) ///
      ytitle("") ///
      xtitle("Time Period", size(medium)) ///
      xlabel(`tmin'(1)`tmax', angle(0)) ///
      ylabel(1/`p', valuelabel angle(0) labsize(small)) ///
      legend(off) ///
      graphregion(color(white)) plotregion(color(white)) ///
      scheme(s2color) ///
      name(xtcbc_timeline, replace)

    qui graph export "xtcbc_timeline.png", ///
      name(xtcbc_timeline) replace width(1200)
    di in gr "  Graph saved: xtcbc_timeline.png"
  }
  else {
    di in gr "  No breaks detected; timeline graph skipped."
  }

  restore

end
