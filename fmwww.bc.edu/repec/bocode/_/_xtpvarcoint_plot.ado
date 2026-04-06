*! _xtpvarcoint_plot.ado — Publication-Quality Graphs
*! IRF, FEVD, eigenvalue, and factor plots
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _xpvc_plot
program define _xpvc_plot, rclass
  version 14.0
  syntax [, PLOTtype(string) VARiable(numlist integer) ///
    SHOck(numlist integer) SAVing(string) TITle(string)]
  
  if "`plottype'" == "" local plottype "irf"
  local plottype = lower("`plottype'")
  
  if "`plottype'" == "irf" {
    _xpvc_plot_irf, variable(`variable') shock(`shock') ///
      saving(`saving') title(`title')
  }
  else if "`plottype'" == "fevd" {
    _xpvc_plot_fevd, variable(`variable') saving(`saving') ///
      title(`title')
  }
  else if "`plottype'" == "eigenvalues" {
    _xpvc_plot_eigenvalues, saving(`saving') title(`title')
  }
  else {
    di in red "unknown plot type: `plottype'"
    di in red "use: irf, fevd, or eigenvalues"
    exit 198
  }
end

// ============================================================
// IRF Plot
// ============================================================
capture program drop _xpvc_plot_irf
program define _xpvc_plot_irf
  syntax [, VARiable(numlist integer) SHOck(numlist integer) ///
    SAVing(string) TITle(string)]
  
  * Get IRF data from r()
  tempname irf_mat irf_lo irf_hi
  capture matrix `irf_mat' = _xpvc_IRF
  if _rc {
    di in red "IRF results not found. Run irf or sboot first."
    exit 301
  }
  
  local n_ahead = rowsof(`irf_mat') - 1
  local dim_K = int(sqrt(colsof(`irf_mat')))
  
  * Check for bootstrap CIs
  local has_ci = 0
  capture matrix `irf_lo' = _xpvc_IRF_lo
  if !_rc local has_ci = 1
  capture matrix `irf_hi' = _xpvc_IRF_hi
  if _rc local has_ci = 0
  
  * Default: plot all
  if "`variable'" == "" {
    numlist "1/`dim_K'"
    local variable "`r(numlist)'"
  }
  if "`shock'" == "" {
    numlist "1/`dim_K'"
    local shock "`r(numlist)'"
  }
  
  * Create temporary dataset
  preserve
  qui {
    clear
    set obs `= `n_ahead' + 1'
    gen h = _n - 1
    
    foreach v of local variable {
      foreach s of local shock {
        local col = (`v' - 1) * `dim_K' + `s'
        gen irf_`v'_`s' = .
        forvalues i = 1/`= `n_ahead' + 1' {
          replace irf_`v'_`s' = `irf_mat'[`i', `col'] in `i'
        }
        
        if `has_ci' {
          gen lo_`v'_`s' = .
          gen hi_`v'_`s' = .
          forvalues i = 1/`= `n_ahead' + 1' {
            replace lo_`v'_`s' = `irf_lo'[`i', `col'] in `i'
            replace hi_`v'_`s' = `irf_hi'[`i', `col'] in `i'
          }
        }
      }
    }
    
    * Generate plots
    local plots ""
    local n_plots = 0
    
    foreach v of local variable {
      foreach s of local shock {
        local n_plots = `n_plots' + 1
        
        if `has_ci' {
          local plots `plots' ///
            (rarea lo_`v'_`s' hi_`v'_`s' h, ///
              fcolor(gs14) lcolor(gs14) lwidth(none)) ///
            (line irf_`v'_`s' h, lcolor(navy) lwidth(medthick))
        }
        else {
          local plots `plots' ///
            (line irf_`v'_`s' h, lcolor(navy) lwidth(medthick))
        }
      }
    }
    
    if "`title'" == "" local title "Impulse Response Functions"
    
    twoway `plots' ///
      (function y=0, range(0 `n_ahead') lcolor(gs10) lpattern(dash)), ///
      title("`title'", size(medium)) ///
      xtitle("Horizon", size(small)) ///
      ytitle("Response", size(small)) ///
      legend(off) ///
      graphregion(color(white)) ///
      plotregion(margin(small)) ///
      scheme(s2color)
    
    if "`saving'" != "" {
      graph export "`saving'", replace
      di in gr "Graph saved to: `saving'"
    }
  }
  restore
end

// ============================================================
// FEVD Plot
// ============================================================
capture program drop _xpvc_plot_fevd
program define _xpvc_plot_fevd
  syntax [, VARiable(numlist integer) SAVing(string) TITle(string)]
  
  tempname fevd_mat
  capture matrix `fevd_mat' = _xpvc_FEVD
  if _rc {
    di in red "FEVD results not found. Run fevd first."
    exit 301
  }
  
  local n_ahead = rowsof(`fevd_mat') - 1
  local dim_K = int(sqrt(colsof(`fevd_mat')))
  
  if "`variable'" == "" {
    numlist "1/`dim_K'"
    local variable "`r(numlist)'"
  }
  
  preserve
  qui {
    clear
    set obs `= `n_ahead' + 1'
    gen h = _n - 1
    
    foreach v of local variable {
      forvalues s = 1/`dim_K' {
        local col = (`v' - 1) * `dim_K' + `s'
        gen fevd_`v'_`s' = .
        forvalues i = 1/`= `n_ahead' + 1' {
          replace fevd_`v'_`s' = `fevd_mat'[`i', `col'] in `i'
        }
      }
    }
    
    * Generate stacked area plots
    foreach v of local variable {
      local area_plots ""
      forvalues s = 1/`dim_K' {
        local area_plots `area_plots' ///
          (area fevd_`v'_`s' h, lcolor(gs8) lwidth(vthin))
      }
      
      if "`title'" == "" local title_use "FEVD — Variable `v'"
      else local title_use "`title'"
      
      twoway `area_plots', ///
        title("`title_use'", size(medium)) ///
        xtitle("Horizon", size(small)) ///
        ytitle("Share", size(small)) ///
        graphregion(color(white)) ///
        scheme(s2color)
    }
    
    if "`saving'" != "" {
      graph export "`saving'", replace
    }
  }
  restore
end

// ============================================================
// Eigenvalue Plot (companion matrix)
// ============================================================
capture program drop _xpvc_plot_eigenvalues
program define _xpvc_plot_eigenvalues
  syntax [, SAVing(string) TITle(string)]
  
  tempname A_mat
  capture matrix `A_mat' = _xpvc_A
  if _rc {
    di in red "VAR coefficients not found."
    exit 301
  }
  
  if "`title'" == "" local title "Eigenvalues of Companion Matrix"
  
  local dim_K = rowsof(`A_mat')
  local dim_p = colsof(`A_mat') / `dim_K'
  
  * Compute eigenvalues in Mata and plot
  local n_eig = `dim_K' * `dim_p'
  
  preserve
  
  * Build dataset for eigenvalue scatter + unit circle
  qui clear
  qui set obs `= `n_eig' + 100'
  qui gen x = .
  qui gen y = .
  qui gen circle_x = .
  qui gen circle_y = .
  
  * Generate unit circle points (last 100 obs)
  qui replace circle_x = cos((_n - `n_eig' - 1) / 99 * 2 * _pi) ///
    if _n > `n_eig'
  qui replace circle_y = sin((_n - `n_eig' - 1) / 99 * 2 * _pi) ///
    if _n > `n_eig'
  
  * Call Mata outside qui{} block to avoid parse errors
  mata: _xpvc_plot_eigen_helper("`A_mat'")
  
  qui twoway (line circle_y circle_x, lcolor(gs10) lpattern(dash)) ///
         (scatter y x if _n <= `n_eig', ///
           mcolor(navy) msymbol(circle) msize(medium)), ///
    title("`title'", size(medium)) ///
    xtitle("Re", size(small)) ///
    ytitle("Im", size(small)) ///
    aspectratio(1) ///
    legend(off) ///
    graphregion(color(white)) ///
    scheme(s2color)
  
  if "`saving'" != "" {
    qui graph export "`saving'", replace
  }
  
  restore
end

mata:
mata set matastrict off

void _xpvc_plot_eigen_helper(string scalar A_mat_name)
{
  real matrix A, C, V
  real colvector ev_vals
  real scalar dim_K, dim_p, n, i
  real colvector re_vec, im_vec, idx
  
  A = st_matrix(A_mat_name)
  dim_K = rows(A)
  dim_p = cols(A) / dim_K
  C = _xpvc_companion(A, dim_p)
  
  eigensystem(C, V, ev_vals)
  
  n = length(ev_vals)
  re_vec = Re(ev_vals')
  im_vec = Im(ev_vals')
  idx = (1::n)
  
  st_store(idx, "x", re_vec)
  st_store(idx, "y", im_vec)
}

end
