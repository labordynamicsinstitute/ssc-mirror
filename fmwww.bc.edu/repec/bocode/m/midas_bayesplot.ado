cap program drop midas_bayesplot
program define midas_bayesplot
version 17.0

// Verify last estimation was midas mh or midas hmc
if `"`e(cmd)'"' != "midas_mh" & `"`e(cmd)'"' != "midas_hmc" {
    di as err "midas bayesplot requires prior midas mh or midas hmc estimation"
    exit 301
}

capture preserve

// Load MCMC chain data
// Strategy: try e(midas_sim_data) matrix first (HMC stores this),
// then e(midas_filename) file path (MH stores this),
// then e(filename) file path (HMC also stores this),
// then fallback to default paths.

local loaded = 0

// Method 1: e(midas_sim_data) matrix (available after midas hmc)
capture {
    mat _bpdata = e(midas_sim_data)
    local nr = rowsof(_bpdata)
    local nc = colsof(_bpdata)
    if `nr' > 1 & `nc' >= 7 {
        clear
        qui svmat _bpdata, names(col)
        local loaded = 1
    }
}
capture matrix drop _bpdata

// Method 2: e(midas_filename) file (available after midas mh)
if `loaded' == 0 {
    local simfile `"`e(midas_filename)'"'
    if `"`simfile'"' != "" {
        capture use `"`simfile'"', clear
        if _rc == 0 local loaded = 1
    }
}

// Method 3: e(filename) file (available after midas hmc)
if `loaded' == 0 {
    local simfile `"`e(filename)'"'
    if `"`simfile'"' != "" {
        capture use `"`simfile'"', clear
        if _rc == 0 local loaded = 1
    }
}

// Method 4: fallback paths
if `loaded' == 0 {
    foreach trypath in "C:/ado/personal/midas_sim_data.dta" ///
        "`c(sysdir_personal)'midas_sim_data.dta" ///
        "`c(pwd)'/midas_sim_data.dta" {
        capture use "`trypath'", clear
        if _rc == 0 {
            local loaded = 1
            continue, break
        }
    }
}

if `loaded' == 0 {
    di as err "MCMC chain data not found. Run {bf:midas mh} or {bf:midas hmc} first."
    exit 601
}

// Handle both variable naming conventions:
// midas_sim_data.dta uses "chainvar", bayesmh output uses "_chain"
capture keep chainvar logitsen logitspe varlogitsen varlogitspe covvars corrvars
if _rc != 0 {
    // Try bayesmh variable names (eq1_p*, eq0_p*, _chain)
    capture keep _chain eq1_p* eq0_p*
    if _rc != 0 {
        di as err "MCMC chain data not found in expected format."
        exit 111
    }
    // Rename to standard names
    rename _chain chainvar
    gen double logitsen = eq1_p1
    gen double logitspe = eq1_p2
    gen double varlogitsen = eq0_p2^2
    gen double varlogitspe = eq0_p3^2
    gen double corrvars = eq0_p1
    gen double covvars = corrvars * sqrt(varlogitsen) * sqrt(varlogitspe)
    keep chainvar logitsen logitspe varlogitsen varlogitspe covvars corrvars
}
set graphics off
local plist ""
local tlist ""
local aclist ""
local kdlist ""
local bgrlist ""
local bmcplots "logitsen logitspe  varlogitsen varlogitspe covvars corrvars"
local num = wordcount("`bmcplots'")
local margopts "imargin(0 0 0 0)"
local plotopts "title("") xtitle("") ylabel("") xlabel("")"
forvalues k = 1/`num' {
local p: di word("`bmcplots'",`k')
local plist "`plist' para`k'"
local tlist "`tlist' trace`k'"
local aclist "`aclist' ac`k'"
local kdlist "`kdlist' kd`k'"
local bgrlist "`bgrlist' bgr`k'"
qui tw function y=0, range(0 0) name(para`k', replace) lc(none) ///
ytitle("`p'", orientation(horizontal) size(huge)) ysca(noline) xsca(off) ///
plotregion(style(none)) graphregion(style(none)) `plotopts'
qui bmctrace `p', goptions(name(trace`k', replace) ///
ytitle("") `plotopts') chain(chainvar) overlay
qui bmcac `p', goptions(name(ac`k', replace) ytitle("")  `plotopts' note(""))  
qui bmcdens `p', goptions(name(kd`k', replace) ytitle("")  `plotopts') 
qui bmcbgr `p', goptions(lcolor(blue) name(bgr`k', replace) ///
 ytitle("") `plotopts') chain(chainvar) 
}
graph combine `plist', col(1) name(paraplot, replace) ///
title("") fxsize(20) 
graph combine `tlist', col(1) name(traceplot, replace) ///
title("Trace") `margopts'
graph combine `aclist', col(1) name(acplot, replace) ///
title("Autocorrelation") `margopts'
graph combine `kdlist', col(1) name(kdplot, replace) ///
title("Density") `margopts'
graph combine `bgrlist', col(1) name(bgrplot, replace) ///
title("Gelman-Rubin") `margopts'
set graphics on
gr combine paraplot traceplot kdplot acplot bgrplot, row(1) ///
ycommon `margopts' 

cap restore
end

*============================================================================
* mcmctrace:  Trace (history) plots of an MCMC analysis
* Author:    John Thompson
* Date:      Dec 2012
*Modified/renamed June 2024
*============================================================================

program bmctrace, sortpreserve
   version 12.1
   syntax varlist [if] [in] , [ ///
   GOPTions(string asis)        /// options passed to graph twoway
   CGOPTions(string asis)       /// options passed to graph combine
   Iteration(varname)           /// variable for the x-axis
   Chain(varname)               /// variable denoting the chain number
   Level(cilevel)               /// level for credible limits
   OVERlay                      /// overlay the traces of all chains onto one graph
   ]
   marksample touse

*---------------------------------
* check options
*---------------------------------
   if "`chain'" == "" & "`overlay'" != "" {
      di as err "warning: overlay ignored - only works with multiple chains"
      local overlay ""
   }
*---------------------------------
* count number of parameters
*---------------------------------
   local np : word count `varlist'
*---------------------------------
* count number of chains
*---------------------------------
   if "`chain'" == "" {
      local nc = 1
   }
   else {
      qui levelsof `chain' if `touse', local(clist)
      local nc : word count `clist'
   }
   if "`overlay'" == "" {
      local np = `np'*`nc'
   }
   if `np' > 1 local nodraw "nodraw"
*---------------------------------
* create x-axis variable
*---------------------------------
   tempvar t h
   if "`iteration'" == "" {
      if "`chain'" == "" gen `t' = _n
      else {
         gen `h' = _n
         sort `chain' `h'
         by `chain': egen `t' = seq()
      }
      local orderlab = "Iteration"
   }
   else {
      gen `t' = `iteration'
      local orderlab : variable label `iteration'
      if "`orderlab'" == "" local orderlab "`iteration'"
   }
*---------------------------------
* Graph for each variable
*---------------------------------
   sort `chain' `t'
   local i = 0
   local cs = ""
   foreach v of varlist `varlist' {
*---------------------------------
* plot each chain
*---------------------------------
      if "`chain'" == "" {
*---------------------------------
* Single chain
*---------------------------------
         local i = `i' + 1
         tempfile t`i'
         local s = "saving(`t`i''.gph,replace)"
         local cs "`cs' `t`i''.gph"
*---------------------------------
* find median & credible interval
*---------------------------------
         qui centile `v' if `touse'
         local md = r(c_1)
         local cl = (100-`level')/2
         qui centile `v' if `touse' , cen(`cl')
         local lb = r(c_1)
         local cl = 100-`cl'
         qui centile `v' if `touse' , cen(`cl')
         local ub = r(c_1)
         qui line `v' `t' if `touse' , xtitle("`orderlab'") yline(`md' , lp(solid)) ///
         yline(`lb' , lp(dash)) yline(`ub' , lp(dash)) `goptions' `s' `nodraw'
      }
      else {
         if "`overlay'" != "" {
*---------------------------------
* Several chains - overlayed
*---------------------------------
            local i = `i' + 1
            tempfile t`i'
            local s = "saving(`t`i''.gph,replace)"
            local cs "`cs' `t`i''.gph"
*---------------------------------
* find credible intervals
*---------------------------------
            qui centile `v' if `touse'
            local md = r(c_1)
            qui centile `v' if `touse' , cen(2.5)
            local lb = r(c_1)
            qui centile `v' if `touse' , cen(97.5)
            local ub = r(c_1)
            local pc ""
            forvalues c = 1 / `nc' {
               local pc "`pc' (line `v' `t' if `touse' & chain == `c')"
            }
            qui twoway `pc' , xtitle("`orderlab'") yline(`md' , lp(solid)) ///
            yline(`lb' , lp(dash)) yline(`ub' , lp(dash)) legend(off) `s' `nodraw' `goptions'
         }
         else {
*---------------------------------
* Several chains - not overlayed
*---------------------------------
            foreach c of local clist {
*---------------------------------
* find credible intervals
*---------------------------------
               qui centile `v' if `touse' & chain == `c'
               local md = r(c_1)
               qui centile `v' if `touse' & chain == `c' , cen(2.5)
               local lb = r(c_1)
               qui centile `v' if `touse' & chain == `c' , cen(97.5)
               local ub = r(c_1)
               local i = `i' + 1
               tempfile t`i'
               local s = "saving(`t`i''.gph,replace)"
               local cs "`cs' `t`i''.gph"
               qui line `v' `t' if `touse' & chain == `c' , xtitle("`orderlab' (chain `c')") yline(`md' , lp(solid)) ///
               yline(`lb' , lp(dash)) yline(`ub' , lp(dash)) `s' `nodraw' `goptions'
            }
         }
      }
   }
*---------------------------------
* combine plots if needed
*---------------------------------
   if `np' > 1 {
      qui graph combine `cs' , `cgoptions'
   }
end


*============================================================================
* MC_DENSITY:  Estimated posterior density based on an MCMC run using Stata's kdensity command
* Author:      John Thompson
* Date:        Dec 2012
* Modified and renamed June 2024
*============================================================================

program bmcdens, rclass
   version 12.1
   syntax varlist [if] [in] , [ ///
   Lbounds(string)              /// lboundser limit of density range
   Ubounds(string)              /// upper limit of density range
   KOPTions(string asis)        /// options passed to kdensity
   GOPTions(string asis)        /// options passed to graph twoway
   CGOPTions(string asis)       /// options passed to graph combine
   Save(string)                 /// .dta file for saving the plotting points
   ADDplot(string)              /// second plot added to the density
   ]
   
   quietly {
      marksample touse
*---------------------------------
* count number of parameters
*---------------------------------
      local np : word count `varlist'
      if `np' > 1 local nodraw "nodraw"
*---------------------------------
* set upper & lboundser limits
*---------------------------------
      tokenize "`lbounds'"
      forvalues j = 1/`np' {
         if "``j''" != "" local lbounds`j' "``j''"
         else local lbounds`j' "."
      }
      tokenize "`ubounds'"
      forvalues j = 1/`np' {
         if "``j''" != "" local ubounds`j' "``j''"
         else local ubounds`j' "."
      }
*---------------------------------
* details of save file
*---------------------------------
      tokenize `"`save'"',parse(",")
      local save = trim(subinstr(`"`1'"',`"""',"",.))
      local dreplace `"`3'"'
*---------------------------------
* process each variable
*---------------------------------
      tempvar y x f id my
      local cs ""
      local j = 0
      foreach v of varlist `varlist' {
         local ++j
         local vlab : var lab `v'
         if "`vlab'" == "" {
            local vlab "`v'"
         }
         preserve
         keep if `touse'
         gen `y' = `v'
*---------------------------------
* if bounded - reflect
*---------------------------------
         local set = 1
         gen `my' = 1
         local stacklist ""
         if "`lbounds`j''" != "." {
            tempvar ylb`j' mlb`j'
            gen `ylb`j'' = `lbounds`j'' - (`y'-`lbounds`j'')
            local set = `set' + 1
            gen `mlb`j'' = 0
            local stacklist "`mlb`j'' `ylb`j''"
         }
         if "`ubounds`j''" != "."{
            tempvar yub`j' mub`j'
            gen `yub`j'' = `ubounds`j'' + (`ubounds`j''-`y')
            local set = `set' + 1
            gen `mub`j'' = 0
            local stacklist "`stacklist' `mub`j'' `yub`j''"
         }
         if `set' > 1 {
            stack `my' `y' `stacklist' , into(`my' `y') clear
            su `y' if `my' == 1
            local bw = 100*r(sd)/(r(N)^0.8)
            local bw = "bw(`bw')"
         }
         local n = min(_N,250)
         kdensity `y' , gen(`x' `f') nograph n(`n') `bw' `koptions'
         if "`lbounds`j''" != "." {
            cap drop if `x' < `lbounds`j''
         }
         if "`ubounds`j''" != "."{
            cap drop if `x' > `ubounds`j''
         }
         replace `f' = `set'*`f'
*---------------------------------
* produce the plot
*---------------------------------
         if `np' > 1 {
            tempfile t`j'
            local s `"saving("`t`j''.gph",replace)"'
            local cs `"`cs' "`t`j''.gph" "'
         }
         twoway (line `f' `x' ) (`addplot'), legend(off) ///
         ytitle("Density") xtitle("`vlab'") `s' `nodraw' `goptions'
*---------------------------------
* find mode
*---------------------------------
         su `f'
         tempvar m`v'
         gen `m`v'' = `x'*(`f' == r(max))
         su `m`v''
         local mode`v' = r(sum)
*---------------------------------
* save plotting points
*---------------------------------
         if "`save'" != "" {
            gen `id' = `j'
            keep `id' `x' `f'
            drop if `f' == .
            if `j' > 1 {
               append using `save'
            }
            save `save' , `dreplace'
         }
         restore
      }
*---------------------------------
* rename variables in saved file
*---------------------------------
      if `"`save'"' != "" {
         preserve
         use `"`save'"' , clear
         rename `id' plot
         rename `f' f
         rename `x' x
         save `"`save'"' , `dreplace'
         restore
      }
*-------------------------
* combined plot
*-------------------------
      if `np' > 1 {
         graph combine `cs' , `cgoptions'
      }
  }
*---------------------------------
* Display and return posterior mode
*---------------------------------
   di as text _dup(35) "-"
   di as txt "Parameter" _col(20) "Posterior mode"
   di as text _dup(35) "-"
   local i = 0
   foreach v of varlist `varlist' {
      di as txt "`v'" _col(20) as res %10.3f `mode`v''
      local ++i
      return scalar mode`i' = `mode`v''
   }
   di as text _dup(35) "-"
   
end

*============================================================================
* mcmcac:  Autocorrelation plots - wrapper for Stata's ac and pac commands
* Author: John Thompson
* Date:   Dec 2012
* Modified and renamed June 2024
*============================================================================

program bmcac
   version 12.1
   syntax varlist [if] [in] , [ ///
   PAC                        ///  pac instead of ac
   GOPTions(string asis)      ///  options for plotting individual graphs
   CGOPTions(string asis)     ///  options for combining graphs
   ACOPTions(string asis)     ///  options sent to ac
   Save(string)               ///  .dta file to save plotting points
   ]
   
   quietly {
      marksample touse , novarlist

*-----------------------------
* Count number of plots
*-----------------------------
      local np : word count `varlist'
      if `np' > 1 local nodraw "nodraw"      
*-----------------------------
* parse the save option
*-----------------------------
      tokenize `"`save'"',parse(",")
      local save = trim(subinstr(`"`1'"',`"""',"",.))
      local dreplace `"`3'"'
*-----------------------------
* save any existing tsset
*-----------------------------
      cap tsset
      local oldt = r(timevar)
*-----------------------------
* create each plot
*-----------------------------      
      tempvar t plot corr lag
      gen `t' = _n
      tsset `t'
      local plots ""
      local i = 0
      foreach v of varlist `varlist' {
         local i = `i' + 1
         tempfile t`i'
         local plots "`plots' `t`i''.gph"
*-----------------------------
* call ac or pac
*-----------------------------         
         if "`pac'" != "" {
            pac `v' if `touse' , `acoptions' `goptions' saving("`t`i''.gph",replace) gen(`corr') `nodraw'
         }
         else {
            ac `v' if `touse' , `acoptions' `goptions' saving("`t`i''.gph",replace) gen(`corr') `nodraw'
         }
*-----------------------------
* if needed save the points
*-----------------------------
         if "`save'" != "" {
            preserve
            keep `corr'
            gen `plot' = `i'
            gen `lag' = _n
            if `i' > 1 {
               append using "`save'"
               save "`save'" , replace
            }
            else {
               save "`save'" , `dreplace'
            }
            restore
         }
         drop `corr'
      }
*-----------------------------
* combine plots if needed
*-----------------------------
      if `np' > 1 {
         graph combine `plots' , `cgoptions'
      }
*-----------------------------
* tidy the saved points
*-----------------------------      
      if "`save'" != "" {
         preserve
         use "`save'", clear
         rename `plot' plot
         rename `corr' r
         rename `lag' lag
         drop if r == .
         sort plot lag
         save "`save'", replace
         restore
      }
*-----------------------------
* restore the old tsset
*-----------------------------
      cap tsset `oldt'
   }
end



*============================================================================
* mcmcbgr:  plot convergence of serveral chains
* Author:  John Thompson
* Date:    Dec 2012
* Modified and renamed: June 2024
*============================================================================

program bmcbgr , sortpreserve
   version 12.1
   syntax varlist (max = 1 min = 1) [if] [in] , ///
   Chain(varname) [       ///  chain identifier
   GOPTions(string asis)  ///  options for the separate graphs
   CGOPTions(string asis) ///  options for combining the two graphs
   Iteration(varname)     ///  variable giving the iteration number
   M(integer 20)          ///  number of plotting points
   ]
   
*---------------------------------
* Check options
*---------------------------------
   if `m' < 1 {
      di as err "mcmcintervals: option m must be positive"
      exit(499)
   }
*---------------------------------
* Create plot
*---------------------------------
   quietly {
      preserve
      marksample touse
*---------------------------------
* count number of chains
*---------------------------------
      qui levelsof `chain' if `touse', local(clist)
      local nc : word count `clist'
* create x-axis variable
*---------------------------------
      tempvar t h
      if "`iteration'" == "" {
         gen `h' = _n
         sort `chain' `h'
         by `chain': egen `t' = seq()
         local orderlab = "Iteration"
      }
      else {
         gen `t' = `iteration'
         local orderlab : variable label `iteration'
         if "`orderlab'" == "" local orderlab "`iteration'"
      }
      keep if `touse'
      su `t'
      local mint = r(min)
      local maxlength = 0
      foreach c of local clist {
         su `t' if `chain' == `c'
         local maxlength = max(`maxlength',r(max))
      }
      sort `chain' `t'
      local binsize = `maxlength'/`m'
      local nbins = `m'
*---------------------------------
* calculate the plotting points
*---------------------------------
      tempvar I80 limit aI80 R dfm dfv df
      gen `I80' = .
      gen `limit' = .
      gen `dfm' = .
      gen `dfv' = .
      gen `df' = .
      
      local list ""
      local plot ""
      forvalues i = 1 / `nc' {
         tempvar I80_`i'
         gen `I80_`i'' = .
         local list "`list' `I80_`i''"
         local plot "`plot' (line `I80_`i'' `limit' , lpat(dash) )"
      }
      forvalues i = 1 / `nbins' {
         local upper = `i'*`binsize' + `mint'-1
         local half = `i'*`binsize'/2 + `mint'
         replace `limit' = `upper' in `i'
*---------------------------------
* variances
*---------------------------------
            su `varlist' if `t' < = `upper' & `t' > `half'
            local m = r(mean)
            local ss = 0
            local sv = 0
            forvalues j = 1 / `nc' {
               su `varlist' if `t' < = `upper' & `t' > `half' & `chain' == `j'
               replace `dfm' = r(mean) in `j'
               replace `dfv' = r(Var) in `j'
               replace `I80_`j'' = r(Var) in `i'
               local sv = `sv' + r(Var)
               local ss = `ss' + (r(mean)-`m')^2
               local n = r(N)
            }
            local W = `sv'/`nc'
            local B = `n'*`ss'/(`nc'-1)
            local splus = (`n'-1)*`W'/`n' + `B'/`n'
            local V = `splus' + `B'/(`n'*`nc')
            replace `I80' = `V' in `i'
            su `dfv'
            local v1 = r(Var)
            local vv = ((`n'-1)/`n')^2*r(Var)/`nc'+((`nc'+1)/(`nc'*`n'))^2*2*`B'*`B'/(`nc'-1)
            su `dfm'
            local gm = r(mean)
            local v2 = r(Var)
            corr `dfv' `dfm'
            local cv1 = r(rho)*sqrt(`v1'*`v2')
            replace `dfm' = `dfm'*`dfm'
            su `dfm'
            local v3 = r(Var)
            corr `dfv' `dfm'
            local cv2 = r(rho)*sqrt(`v1'*`v3')
            local vv = `vv' + (2*(`nc'+1)*(`n'-1)/(`nc'*`n'*`n'))*(`n'/`nc')*(`cv2'-2*`gm'*`cv1')
            local edf = 2*`V'*`V'/`vv'
            replace `df' = `edf' in `i'
      }
*---------------------------------
* Calculate R statistic
*---------------------------------
      egen `aI80' = rmean(`list')
         local Ylabel = "Variance Estimates"
         local Rlabel = "R"
         gen `R' = ((`df'+3)/(`df'+1))*`I80' / `aI80'
*---------------------------------
* Create upper and lower plots
*---------------------------------
      tempfile p1 p2
      line `R' `limit' , lcol(black) yline(1, lpa(dash) lcol(dknavy)) ytitle("`Rlabel'") xtitle("`orderlab'") ///
      saving(`p1'.gph , replace) `goptions' ylabel(,angle(0)) 
      
*---------------------------------
* save plotting points if needed
*---------------------------------
      restore
   }
end

