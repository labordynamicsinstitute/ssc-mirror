*! xtquantilebreak_graph.ado — Visualization for xtquantilebreak
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.0.0

program define xtquantilebreak_graph
  syntax, betapath(name) brkmat(name) reginfo(name) regcoef(name) regse(name) ///
    k(integer) pp(integer) tmin(integer) tt(integer) ///
    quantiles(string) cnames(string) depvar(string) level(cilevel) [ HEATmap ]

  local K = `k'
  local za = invnormal(1 - (100 - `level') / 200)

  * journal-style colour ramp (low -> high quantile)
  local qcol1 "31 119 180"
  local qcol2 "44 160 44"
  local qcol3 "214 39 40"
  local qcol4 "148 103 189"
  local qcol5 "255 127 14"
  local qcol6 "23 190 207"
  local qcol7 "227 119 194"
  local qcol8 "140 86 75"
  local qcol9 "127 127 127"

  * shared, sparse time-axis labels (avoid overlap in small combined panels)
  local xend  = `tmin' + `tt' - 1
  local xstep = max(1, round((`tt' - 1) / 5))
  local xlab  "`tmin'(`xstep')`xend'"

  * ====================================================================
  * 1. COEFFICIENT STEP PATHS — one panel per regressor, lines = quantiles
  * ====================================================================
  local panels ""
  forvalues d = 1/`pp' {
    local cn : word `d' of `cnames'

    qui {
      preserve
      clear
      set obs `tt'
      gen time = _n + `tmin' - 1
      forvalues kk = 1/`K' {
        local col = (`kk' - 1) * `pp' + `d'
        gen coef`kk' = `betapath'[_n, `col']
      }
      * CI ribbon only when a single quantile is requested (avoids clutter)
      if `K' == 1 {
        gen cilo = .
        gen cihi = .
        local nr = rowsof(`reginfo')
        forvalues r = 1/`nr' {
          local s = `reginfo'[`r', 3]
          local e = `reginfo'[`r', 4]
          local sv = `regse'[`r', `d']
          local cv = `regcoef'[`r', `d']
          forvalues t = `s'/`e' {
            replace cilo = `cv' - `za' * `sv' in `t'
            replace cihi = `cv' + `za' * `sv' in `t'
          }
        }
      }

      * break vlines (union across quantiles for this regressor's panel)
      local xlines ""
      forvalues kk = 1/`K' {
        forvalues t = 2/`tt' {
          if `brkmat'[`kk', `t'] == 1 {
            local bt = `t' + `tmin' - 1
            local xlines "`xlines' xline(`bt', lcolor(gs12) lpattern(dash) lwidth(vthin))"
          }
        }
      }

      * build line plot calls
      local plots ""
      if `K' == 1 {
        local plots `"(rarea cilo cihi time, color("`qcol1'%18") lwidth(none))"'
      }
      forvalues kk = 1/`K' {
        local qc "`qcol`kk''"
        if "`qc'" == "" local qc "0 0 0"
        local plots `"`plots' (line coef`kk' time, lcolor("`qc'") lwidth(medthick) connect(stepstair))"'
      }

      twoway `plots' , `xlines' ///
        title("{bf:`cn'}", size(medsmall) color(black)) ///
        xtitle("") ytitle("Coefficient", size(small)) ///
        yline(0, lcolor(gs10) lwidth(vthin)) ///
        legend(off) ///
        graphregion(color(white)) plotregion(color(white) margin(small)) ///
        xlabel(`xlab', labsize(vsmall) grid glcolor(gs15)) ///
        ylabel(, labsize(vsmall) angle(0) grid glcolor(gs15)) ///
        name(qb_p`d', replace) nodraw
      restore
    }
    local panels "`panels' qb_p`d'"
  }

  * dedicated legend cell with one key per quantile (multi-quantile only);
  * lines carry missing data so the plot is empty but the keys still render
  local combine "`panels'"
  if `K' > 1 {
    qui {
      preserve
      clear
      set obs 2
      gen t = _n
      local lplots ""
      local leg2 ""
      forvalues kk = 1/`K' {
        local qc "`qcol`kk''"
        if "`qc'" == "" local qc "0 0 0"
        gen coef`kk' = .
        local lplots `"`lplots' (line coef`kk' t, lcolor("`qc'") lwidth(medthick))"'
        local q : word `kk' of `quantiles'
        local leg2 `"`leg2' `kk' "{&tau}=`q'""'
      }
      local legrows = cond(`K' > 4, 2, 1)
      twoway `lplots' , ///
        yscale(off) xscale(off) ///
        legend(order(`leg2') rows(`legrows') size(small) region(lstyle(none)) ///
               symxsize(*.5) colgap(*.6)) ///
        title("") graphregion(color(white)) ///
        plotregion(color(white) lstyle(none) margin(zero)) ///
        name(qb_leg, replace) nodraw
      restore
    }
    local combine "`panels' qb_leg"
  }

  local cols = cond(`pp' <= 1 & `K' == 1, 1, 2)
  graph combine `combine', cols(`cols') name(qb_paths, replace) ///
    title("{bf:Quantile coefficient paths with structural breaks}", size(medsmall)) ///
    graphregion(color(white)) imargin(small)

  * ====================================================================
  * 2. BREAK-TIMING MAP — when do breaks occur across quantiles?
  * ====================================================================
  qui {
    preserve
    clear
    * count breaks
    local nb = 0
    forvalues kk = 1/`K' {
      forvalues t = 2/`tt' {
        if `brkmat'[`kk', `t'] == 1 local nb = `nb' + 1
      }
    }
    if `nb' > 0 {
      set obs `nb'
      gen btime = .
      gen qlev = .
      local r = 0
      forvalues kk = 1/`K' {
        local q : word `kk' of `quantiles'
        forvalues t = 2/`tt' {
          if `brkmat'[`kk', `t'] == 1 {
            local r = `r' + 1
            replace btime = `t' + `tmin' - 1 in `r'
            replace qlev = `q' in `r'
          }
        }
      }
      * y labels = quantiles
      local ylab ""
      forvalues kk = 1/`K' {
        local q : word `kk' of `quantiles'
        local ylab `"`ylab' `q'"'
      }
      twoway (scatter qlev btime, msymbol(D) msize(medlarge) ///
                mcolor("214 39 40") mlcolor(black) mlwidth(vthin)) , ///
        title("{bf:Structural break timing across quantiles}", size(medium) color(black)) ///
        subtitle("`depvar'", size(small)) ///
        xtitle("Time", size(small)) ytitle("Quantile {&tau}", size(small)) ///
        ylabel(`ylab', labsize(small) angle(0) grid glcolor(gs15)) ///
        xlabel(`xlab', labsize(small) grid glcolor(gs15)) ///
        graphregion(color(white)) plotregion(color(white) margin(medium)) ///
        legend(off) name(qb_breaks, replace)
    }
    else {
      di as txt "(no breaks detected; break-timing map skipped)"
    }
    restore
  }
end
