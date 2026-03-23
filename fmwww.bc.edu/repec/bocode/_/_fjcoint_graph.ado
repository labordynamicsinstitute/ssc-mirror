*! _fjcoint_graph.ado -- Professional Visualization for Johansen-Fourier Tests
*! Part of fjcoint package
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define _fjcoint_graph
  version 14.0
  
  syntax, VARlist(string) TOUSE(string) MODel(integer) ///
         FREQ(integer) OPTion(integer) LAGs(integer) ///
         [TEst(string)]
  
  local m : word count `varlist'
  local v1 : word 1 of `varlist'
  
  * ---- Temporary variables ----
  qui {
    tempvar t_idx
    gen `t_idx' = _n if `touse'
    local T = _N
    
    * ---- Graph 1: Time Series with Fourier Fit ----
    * Build Fourier terms
    local fourier_vars ""
    if `option' == 1 {
      tempvar sin1 cos1
      gen double `sin1' = sin(2 * _pi * `freq' * `t_idx' / `T') if `touse'
      gen double `cos1' = cos(2 * _pi * `freq' * `t_idx' / `T') if `touse'
      local fourier_vars "`sin1' `cos1'"
    }
    else {
      forvalues j = 1/`freq' {
        tempvar sinj`j' cosj`j'
        gen double `sinj`j'' = sin(2 * _pi * `j' * `t_idx' / `T') if `touse'
        gen double `cosj`j'' = cos(2 * _pi * `j' * `t_idx' / `T') if `touse'
        local fourier_vars "`fourier_vars' `sinj`j'' `cosj`j''"
      }
    }
    
    regress `v1' `fourier_vars' if `touse'
    tempvar fjc_fit fjc_fourier_only fjc_resid
    predict double `fjc_fit' if `touse'
    predict double `fjc_resid' if `touse', residuals
    gen double `fjc_fourier_only' = `fjc_fit' - _b[_cons] if `touse'
  }
  
  * ---- Graph 1: Time Series + Fourier Fit ----
  local optlbl = cond(`option'==1, "Single", "Cumulative")
  
  twoway ///
    (line `v1' `t_idx', lcolor("25 84 166") lwidth(medthick)) ///
    (line `fjc_fit' `t_idx', lcolor("204 51 51") lwidth(medthick) lpattern(dash)), ///
    title("{bf:Time Series with Fourier Deterministic Fit}", size(medsmall) color(black)) ///
    subtitle("Frequency k = `freq' (`optlbl')", size(small) color(gs6)) ///
    ytitle("`v1'", size(small)) xtitle("Observation", size(small)) ///
    legend(order(1 "`v1'" 2 "Fourier fit (k=`freq')") rows(1) size(vsmall) pos(6) ///
      region(lcolor(gs12) fcolor(white))) ///
    graphregion(color(white) margin(small)) plotregion(color(white) margin(small)) ///
    ylabel(, labsize(vsmall) angle(0) grid glcolor(gs14)) ///
    xlabel(, labsize(vsmall) grid glcolor(gs14)) ///
    scheme(s2color) ///
    name(fjc_timeseries, replace) nodraw
  
  * ---- Graph 2: Isolated Fourier Component ----
  twoway ///
    (area `fjc_fourier_only' `t_idx', color("25 84 166%20") lcolor("25 84 166") lwidth(medium)), ///
    title("{bf:Fourier Smooth Break Approximation}", size(medsmall) color(black)) ///
    subtitle("Isolated trigonometric component (k = `freq')", size(small) color(gs6)) ///
    ytitle("f(t)", size(small)) xtitle("Observation", size(small)) ///
    yline(0, lcolor(gs8) lpattern(dash) lwidth(thin)) ///
    graphregion(color(white) margin(small)) plotregion(color(white) margin(small)) ///
    ylabel(, labsize(vsmall) angle(0) grid glcolor(gs14)) ///
    xlabel(, labsize(vsmall) grid glcolor(gs14)) ///
    scheme(s2color) ///
    name(fjc_fourier, replace) nodraw
  
  * ---- Graph 3: All Variables in System ----
  local plotcmd ""
  local leglab ""
  local pnum = 0
  local colors `""25 84 166" "204 51 51" "34 139 34" "148 103 189" "230 159 0""'
  
  foreach v of local varlist {
    local pnum = `pnum' + 1
    local col : word `pnum' of `colors'
    local plotcmd "`plotcmd' (line `v' `t_idx', lcolor("`col'") lwidth(medthick))"
    local leglab `"`leglab' label(`pnum' "`v'")"'
  }
  
  twoway `plotcmd', ///
    title("{bf:Variables in the Cointegration System}", size(medsmall) color(black)) ///
    ytitle("Value", size(small)) xtitle("Observation", size(small)) ///
    legend(rows(1) size(vsmall) pos(6) `leglab' ///
      region(lcolor(gs12) fcolor(white))) ///
    graphregion(color(white) margin(small)) plotregion(color(white) margin(small)) ///
    ylabel(, labsize(vsmall) angle(0) grid glcolor(gs14)) ///
    xlabel(, labsize(vsmall) grid glcolor(gs14)) ///
    scheme(s2color) ///
    name(fjc_variables, replace) nodraw
  
  * ---- Graph 4: Eigenvalue Bar Chart ----
  capture confirm matrix _fjc_eigenvals
  if _rc == 0 {
    local nev = rowsof(_fjc_eigenvals)
    qui {
      preserve
      clear
      set obs `nev'
      gen rank = _n
      gen eigenvalue = .
      forvalues i = 1/`nev' {
        replace eigenvalue = _fjc_eigenvals[`i', 1] in `i'
      }
      
      twoway ///
        (bar eigenvalue rank, barwidth(0.5) color("25 84 166%70") lcolor("25 84 166") lwidth(medium)), ///
        title("{bf:Ordered Eigenvalues}", size(medsmall) color(black)) ///
        subtitle("Johansen-Fourier rank test", size(small) color(gs6)) ///
        ytitle("Eigenvalue", size(small)) xtitle("Rank", size(small)) ///
        xlabel(1(1)`nev', labsize(vsmall)) ///
        ylabel(, labsize(vsmall) angle(0) grid glcolor(gs14)) ///
        graphregion(color(white) margin(small)) plotregion(color(white) margin(small)) ///
        scheme(s2color) ///
        name(fjc_eigenvals, replace) nodraw
      
      restore
    }
  }
  
  * ---- Graph 5: Residuals (regression residuals) ----
  twoway ///
    (line `fjc_resid' `t_idx', lcolor("34 139 34") lwidth(medium)), ///
    title("{bf:Regression Residuals}", size(medsmall) color(black)) ///
    subtitle("First variable regressed on Fourier terms", size(small) color(gs6)) ///
    ytitle("Residual", size(small)) xtitle("Observation", size(small)) ///
    yline(0, lcolor(gs8) lpattern(dash) lwidth(thin)) ///
    graphregion(color(white) margin(small)) plotregion(color(white) margin(small)) ///
    ylabel(, labsize(vsmall) angle(0) grid glcolor(gs14)) ///
    xlabel(, labsize(vsmall) grid glcolor(gs14)) ///
    scheme(s2color) ///
    name(fjc_residuals, replace) nodraw
  
  * ---- Combine ----
  capture confirm graph fjc_eigenvals
  if _rc == 0 {
    graph combine fjc_timeseries fjc_fourier fjc_eigenvals fjc_variables fjc_residuals, ///
      cols(2) iscale(0.45) ///
      title("{bf:Johansen-Fourier Cointegration Diagnostics}", size(small) color(black)) ///
      graphregion(color(white)) ///
      name(fjc_combined, replace)
  }
  else {
    graph combine fjc_timeseries fjc_fourier fjc_variables fjc_residuals, ///
      cols(2) iscale(0.45) ///
      title("{bf:Johansen-Fourier Cointegration Diagnostics}", size(small) color(black)) ///
      graphregion(color(white)) ///
      name(fjc_combined, replace)
  }
  
  di
  di in gr "  {bf:Graphs}: fjc_timeseries, fjc_fourier, fjc_variables,"
  di in gr "           fjc_residuals, fjc_eigenvals, fjc_combined"
  
end
