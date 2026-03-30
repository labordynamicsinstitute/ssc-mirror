*! xtbreakmodel_graph.ado — Visualization for xtbreakmodel
*! Author: Dr Merwan Roudane
*! Version 1.0.0

program define xtbreakmodel_graph
  syntax, method(string) nbreaks(name) regime(name) ///
         alpha(name) se(name) ///
         n(integer) tt(integer) p(integer) g(integer) ///
         tmin(integer) tmax(integer) ///
         depvar(string) indepvars(string) ///
         level(cilevel)

  local za = invnormal(1 - (100 - `level') / 200)
  local K = `p'
  local G_groups = `g'
  if `G_groups' < 1 local G_groups = 1

  * ====================================================================
  * COEFFICIENT PATH PLOTS
  * ====================================================================

  local kk_idx = 0
  foreach xv of local indepvars {
    local kk_idx = `kk_idx' + 1

    if "`method'" == "gagfl" {
      * -----------------------------------------------------------
      * GAGFL: One panel per group, then combine
      * -----------------------------------------------------------
      forvalues gg = 1/`G_groups' {
        local nb_g = `nbreaks'[1, `gg']
        local n_reg = `nb_g' + 1

        qui {
          preserve
          clear
          set obs `tt'
          gen time = _n + `tmin' - 1
          gen coef = .
          gen ci_lo = .
          gen ci_hi = .

          forvalues rr = 1/`n_reg' {
            local s_t = `regime'[`rr', `gg']
            if `rr' < `n_reg' {
              local e_t = `regime'[`rr'+1, `gg'] - 1
            }
            else {
              local e_t = `tt'
            }
            local cv = `alpha'[`rr', (`gg'-1)*`K' + `kk_idx']
            local sv = `se'[`rr', (`gg'-1)*`K' + `kk_idx']
            forvalues t = `s_t'/`e_t' {
              replace coef = `cv' in `t'
              replace ci_lo = `cv' - `za' * `sv' in `t'
              replace ci_hi = `cv' + `za' * `sv' in `t'
            }
          }

          * Break date vertical lines
          local xlines ""
          if `nb_g' > 0 {
            forvalues bb = 2/`=`nb_g'+1' {
              local bd = `regime'[`bb', `gg']
              local bd_time = `bd' + `tmin' - 1
              local xlines "`xlines' xline(`bd_time', lcolor(cranberry) lpattern(dash) lwidth(medthin))"
            }
          }

          local gcol "navy"
          if `gg' == 2 local gcol "dkgreen"
          if `gg' == 3 local gcol "dkorange"
          if `gg' >= 4 local gcol "purple"

          twoway (rarea ci_lo ci_hi time, color(`gcol'%15) lwidth(none)) ///
                 (line coef time, lcolor(`gcol') lwidth(medthick)) ///
                 , `xlines' ///
                 title("Group `gg': `xv'", size(medium)) ///
                 subtitle("Breaks: `nb_g' | `level'% CI", size(small)) ///
                 xtitle("Time") ytitle("Coefficient") ///
                 legend(order(2 "Estimate" 1 "`level'% CI") rows(1) size(vsmall)) ///
                 scheme(s2color) ///
                 graphregion(color(white)) plotregion(color(white)) ///
                 name(coef_g`gg'_`kk_idx', replace) nodraw

          restore
        }
      }
      
      * Combine all group panels
      local combine_list ""
      forvalues gg = 1/`G_groups' {
        local combine_list "`combine_list' coef_g`gg'_`kk_idx'"
      }
      
      graph combine `combine_list', ///
          title("{bf:GAGFL — Regime-Specific Coefficients: `xv'}", size(medium)) ///
          subtitle("Okui & Wang (2021) | Dashed lines = structural breaks", size(small)) ///
          graphregion(color(white)) ///
          note("N = `n', T = `tt', G = `G_groups'") ///
          name(gagfl_`kk_idx', replace)
    }
    else {
      * -----------------------------------------------------------
      * Single-panel methods: PLS / BFK / SaRa
      * -----------------------------------------------------------
      local nb_all = `nbreaks'[1, 1]
      local n_reg = `nb_all' + 1

      qui {
        preserve
        clear
        set obs `tt'
        gen time = _n + `tmin' - 1
        gen coef = .
        gen ci_lo = .
        gen ci_hi = .

        forvalues rr = 1/`n_reg' {
          local s_t = `regime'[`rr', 1]
          if `rr' < `n_reg' {
            local e_t = `regime'[`rr'+1, 1] - 1
          }
          else {
            local e_t = `tt'
          }
          local cv = `alpha'[`rr', `kk_idx']
          local sv = `se'[`rr', `kk_idx']
          forvalues t = `s_t'/`e_t' {
            replace coef = `cv' in `t'
            replace ci_lo = `cv' - `za' * `sv' in `t'
            replace ci_hi = `cv' + `za' * `sv' in `t'
          }
        }

        * Break date vertical lines  
        local xlines ""
        if `nb_all' > 0 {
          forvalues bb = 2/`=`nb_all'+1' {
            local bd = `regime'[`bb', 1]
            local bd_time = `bd' + `tmin' - 1
            local xlines "`xlines' xline(`bd_time', lcolor(cranberry) lpattern(dash) lwidth(medthin))"
          }
        }

        local mtitle ""
        local msub ""
        if "`method'" == "pls" {
          local mtitle "AGFL — Adaptive Group Fused Lasso"
          local msub "Qian & Su (2016) | Common structural breaks"
        }
        else if "`method'" == "bfk" {
          local mtitle "BFK — Sequential Least Squares"
          local msub "Baltagi, Feng & Kao (2016)"
        }
        else if "`method'" == "sara" {
          local mtitle "SaRa — Screening and Ranking"
          local msub "Li, Xiao & Chen (2025)"
        }

        twoway (rarea ci_lo ci_hi time, color(navy%15) lwidth(none)) ///
               (line coef time, lcolor(navy) lwidth(medthick)) ///
               , `xlines' ///
               title("{bf:`mtitle': `xv'}", size(medium)) ///
               subtitle("`msub' | Dashed lines = breaks", size(small)) ///
               xtitle("Time") ytitle("Coefficient") ///
               legend(order(2 "Estimate" 1 "`level'% CI") rows(1) size(small)) ///
               scheme(s2color) ///
               graphregion(color(white)) plotregion(color(white)) ///
               note("N = `n', T = `tt', Breaks = `nb_all'") ///
               name(coef_`kk_idx', replace)

        restore
      }
    }
  }
end
