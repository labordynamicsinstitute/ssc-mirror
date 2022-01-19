*! version 1.0  2022-01-18 Mark Chatfield

*I shortened Nick Cox's command: niceloglabels, v1.1.0  24 August 2020 
program niceloglabels_shorter  
        gettoken first 0 : 0, parse(" ,")  
        capture confirm numeric variable `first' 
        if _rc == 0 {
                syntax [if] [in] , Local(str) Style(str) [ Fudge(real 1) ] 
                local varlist `first'  
                marksample touse 
                quietly count if `touse'        
                if r(N) == 0 exit 2000 
        } 
        else { 
                confirm number `first' 
                gettoken second 0 : 0, parse(" ,") 
                syntax , Local(str) Style(str) [ Fudge(real 1) ]
                if _N < 2 { 
                        preserve 
                        quietly set obs 2 
                }        
                tempvar varlist touse 
                gen `varlist' = cond(_n == 1, `first', `second') 
                gen byte `touse' = _n <= 2 
        }       

        local style = trim(subinstr("`style'", " ", "", .)) 
        
        tempname dmin dmax 
        su `varlist' if `touse', meanonly 
        scalar `dmin' = r(min) 
        scalar `dmax' = r(max) 
    
        tempvar logx 
        quietly {
                if "`style'" == "2" {
                        gen double `logx' = log10(`varlist')/log10(2) if `touse'
                }
                else if "`style'" == "3" { 
                        gen double `logx' = log10(`varlist')/log10(3) if `touse'
                }
                else gen double `logx' = log10(`varlist') if `touse' 
        }

        su `logx', meanonly 
        // default is to bump (minimum, maximum) (down, up) by 1%
        // otherwise we can be trapped by precision problems, 
        // e.g. floor(log10(1000)) is returned as 2 not 3
        local lmin = ceil(r(min) * (100 - sign(r(min)) * `fudge')/100) 
        local lmax = floor(r(max) * (100 + sign(r(max)) * `fudge')/100) 

		if "`style'" == "1" { 
                forval n = `lmin'/`lmax' { 
                        local this = 10^`n'
                        local all `all' `this' 
                } 
        }
         else if "`style'" == "125" { 
                local nm1 = `lmin' - 1 
                if `dmin' <= 2 * 10^`nm1' & `dmax' >= 2 * 10^`nm1' { 
                        local this = 2 * 10^`nm1' 
                        local all `this' 
                }

                if `dmin' <= 5 * 10^`nm1' & `dmax' >= 5 * 10^`nm1' { 
                        local this = 5 * 10^`nm1' 
                        local all `all' `this' 
                } 

                forval n = `lmin'/`lmax' { 
                        local this = 10^`n' 

                        if `dmax' >= 2 * 10^`n' { 
                                local that = 2 * 10^`n' 
                         }
                        else local that 

                        if `dmax' >= 5 * 10^`n' { 
                                local tother = 5 * 10^`n'                   
                        }
                        else local tother 
                         
                        local all `all' `this' `that' `tother'
                }
        } 
        c_local `local' `"`all'"'  
end 



**for when gmean or amean appears on the x-axis (when log scale)
program define nicexlabels, rclass
syntax varlist
	su `varlist' 
	local min = r(min)
	local max = r(max)
	
	niceloglabels_shorter `varlist', local(la125) style(125)
	local numswith125 = wordcount("`la125'")

	if `numswith125' >= 3 {
		local xla "`la125'"
		niceloglabels_shorter `varlist', local(la1) style(1)
		local numswith1 = wordcount("`la1'")
		if `numswith1' >= 3 local xla "`la1'"
	}	
	else {
		_natscale `min' `max' 9
		if r(min) < `min' local xlabstart = r(min) + r(delta)  // as bottom one can end up off the axis!
		else local xlabstart = r(min)
		local xla "`xlabstart' (`=r(delta)') `=r(max)'"
	}	
	return local xla "`xla'"
end	



cap program drop intervallimits
program define intervallimits, rclass

        syntax varname, p100(numlist max=1 >0 <100) cilevel(numlist) ///
		[ticonfidence(numlist max=1 >0 <100) ticonfidence2(numlist max=1 >0 <100) ticonfidence3(numlist max=1 >0 <100)  exp] 

		local p = `p100'/100
		
		su `varlist'
		local N = r(N)
		local mean = r(mean)
		local sd = r(sd)
		
		*Limits of Agreement  [Bland and Altman 1999]
		local kloa = invnorm(1 - (1 - `p')/2) 
		
		*LoA CI (exact) Carkeet 2015, from Owen 1968
		local df = `N'-1
		local np = `kloa'*sqrt(`N')
		local smallgamma = (100-`cilevel')/200
		local biggamma   = (100+`cilevel')/200
		local kouterciloa =  invnt(`df',`np',`biggamma') / sqrt(`N')
		local kinnerciloa =  invnt(`df',`np',`smallgamma') / sqrt(`N')
		
		*for CI bias
		local kcibias = invt(`N'-1, (100+`cilevel')/200) / sqrt(`N')
		
        *prediction interval  
		local kpi = invt((`N' - 1), 1 - (1 - `p')/2) * sqrt(1 + 1/`N')
		
		*100p% tolerance interval with ticonfidence% confidence [Howe 1969, lambda_3]
		if "`ticonfidence'" != "" {
			local kti = invnorm(1 - (1 - `p')/2) * sqrt(1 + 1/`N') * sqrt((`N' - 1) / invchi2(`N' - 1,1 - `ticonfidence'/100)) * sqrt(1 + (`N' - 3 - invchi2(`N' - 1,1 - `ticonfidence'/100))/2/(`N' + 1)^2) 
			if "`exp'" == "" {
				return scalar tilow = `mean' - `kti' * `sd' 
				return scalar tiupp = `mean' + `kti' * `sd'
			}
			else {
				return scalar tilow = exp(`mean' - `kti' * `sd')
				return scalar tiupp = exp(`mean' + `kti' * `sd')
			}	
		}
		if "`ticonfidence2'" != "" {
			local kti2 = invnorm(1 - (1 - `p')/2) * sqrt(1 + 1/`N') * sqrt((`N' - 1) / invchi2(`N' - 1,1 - `ticonfidence2'/100)) * sqrt(1 + (`N' - 3 - invchi2(`N' - 1,1 - `ticonfidence2'/100))/2/(`N' + 1)^2) 
			if "`exp'" == "" {
				return scalar ti2low = `mean' - `kti2' * `sd' 
				return scalar ti2upp = `mean' + `kti2' * `sd'
			}
			else {
				return scalar ti2low = exp(`mean' - `kti2' * `sd')
				return scalar ti2upp = exp(`mean' + `kti2' * `sd')
			}	
		}
		if "`ticonfidence3'" != "" {
			local kti3 = invnorm(1 - (1 - `p')/2) * sqrt(1 + 1/`N') * sqrt((`N' - 1) / invchi2(`N' - 1,1 - `ticonfidence3'/100)) * sqrt(1 + (`N' - 3 - invchi2(`N' - 1,1 - `ticonfidence3'/100))/2/(`N' + 1)^2) 
			if "`exp'" == "" {
				return scalar ti3low = `mean' - `kti3' * `sd' 
				return scalar ti3upp = `mean' + `kti3' * `sd'
			}
			else {
				return scalar ti3low = exp(`mean' - `kti3' * `sd')
				return scalar ti3upp = exp(`mean' + `kti3' * `sd')
			}	
		}
		if "`exp'" == "" {
			return scalar cilloalow = `mean' - `kouterciloa' * `sd'
			return scalar cilloaupp = `mean' - `kinnerciloa' * `sd'
			return scalar ciuloalow = `mean' + `kinnerciloa' * `sd'
			return scalar ciuloaupp = `mean' + `kouterciloa' * `sd'			
			return scalar lloa = `mean' - `kloa' * `sd' 
			return scalar uloa = `mean' + `kloa' * `sd'        
			return scalar pilow = `mean' - `kpi' * `sd' 
			return scalar piupp = `mean' + `kpi' * `sd'		
			return scalar cibiaslow = `mean' - `kcibias'*`sd'
			return scalar cibiasupp = `mean' + `kcibias'*`sd'
			return scalar mean = `mean'
			return scalar sd = `sd'
		}
		else {
			return scalar cilloalow = exp(`mean' - `kouterciloa' * `sd')
			return scalar cilloaupp = exp(`mean' - `kinnerciloa' * `sd')
			return scalar ciuloalow = exp(`mean' + `kinnerciloa' * `sd')
			return scalar ciuloaupp = exp(`mean' + `kouterciloa' * `sd')
			return scalar lloa = exp(`mean' - `kloa' * `sd') 
			return scalar uloa = exp(`mean' + `kloa' * `sd')        
			return scalar pilow = exp(`mean' - `kpi' * `sd')
			return scalar piupp = exp(`mean' + `kpi' * `sd')	
			return scalar cibiaslow = exp(`mean' - `kcibias'*`sd')
			return scalar cibiasupp = exp(`mean' + `kcibias'*`sd')
			return scalar mean = exp(`mean')
			return scalar sd = exp(`sd')	    
		}
		return scalar N = `N'
end


 
program define blandaltman, sortpreserve rclass

version 11.0

syntax varlist (min=2 max=2 numeric) [if] [in], plot(string asis) [ ///
	Level(numlist max=1 >=1 <100) ///
	PREDINTerval piopts(string asis) ///
	TICONFidence(numlist >=1 <100 max=1) tiopts(string asis) ///
	ticonfidence2(numlist >=1 <100 max=1) tiopts2(string asis) ///
	ticonfidence3(numlist >=1 <100 max=1) tiopts3(string asis) ///	
	Horizontal ///
	HBIAS biasopts(string asis) /// 
	HLOA loaopts(string asis) ///
	NOREGbias regbiasopts(string asis) /// 
	NOREGLOA regloaopts(string asis)  ///
	NOREGOutput /// not documented
	cibias cibiasopts(string asis) ///
	ciloa ciloaopts(string asis) ///	
	scopts(string asis) ///
	cilevel(numlist >=1 <100 max=1) /// 
	name(string asis) ///
	addplot(string asis) * ///
	]

	
if regexm("`plot'", "difference") == 0 & regexm("`plot'", "ratio") == 0 & regexm("`plot'", "percentmean") == 0 & regexm("`plot'", "percentlmean") == 0 {
        display as err "must specify in plot() one or more of: difference percentmean percentlmean ratio"
        exit 198
}

if "`horizontal'" != "" {
	local hbias "hbias"
	local hloa "hloa"
	local noregbias "noregbias"
	local noregloa "noregloa"	
}

*assume hbias requested if hloa, predinterval or ticonfidence specified
if "`hloa'" != "" | "`predinterval'" != "" | "`ticonfidence'" != "" | "`ticonfidence2'" != "" | "`ticonfidence3'" != ""  local hbias "hbias"

*can't have CI for bias/loa unless bias/loa horizontal
if "`horizontal'" == "" & "`hbias'" == "" local cibias ""
if "`horizontal'" == "" & "`hloa'" == "" local ciloa ""


if ("`cilevel'"=="") local cilevel 95
if ("`level'"=="") local level 95
local z196 = invnormal((100+`level')/200)   // will take value 1.96 unless change level  
 

local cibiasoptsall `" mc(gs11) lc(gs11) lp(dash) mangle(80) `cibiasopts' "'
local ciloaoptsall  `" mc(gs11) lc(gs11)          mangle(80) `ciloaopts' "'
local myscopts "msym(oh) mcol(gs1)"
local mybiasopts "lc(gs11) lp(dash)"
local myloaopts "lc(gs11)"
local myregbiasopts "lc(gs11) lp(dash)"
local myregloaopts "lc(gs11)"
local mypiopts "lc(green)"
local mytiopts "lc(blue)"
local mytiopts2 "lc(brown)"
local mytiopts3 "lc(purple)"

if "`noregoutput'" != "" local maybequi "qui"

preserve
marksample touse
qui keep if `touse'  
qui count 
if r(N) == 0 error 2000

tokenize `varlist'
local var1 `1'
local var2 `2'
local shortvar1 = abbrev("`var1'", 10)
local shortvar2 = abbrev("`var2'", 10)
local name1 : variable label `1'
local name2 : variable label `2'
di " "
di as res "A: `var1'" _c
di as res _col(26)  "`name1'"
di as res "B: `var2'" _c
di as res _col(26)  "`name2'"
  
  
tempvar diff amean gmean diffpercentamean diffpercentlmean ratio lnratio lngmean lnamean
  qui {
  gen `diff'= (`var1'-`var2')
  gen `amean'= (`var1'+`var2')/2
  gen `gmean'= exp( (log(`var1')+log(`var2')) /2 )
  gen `diffpercentamean' = 100*`diff'/`amean'
  gen `diffpercentlmean' = 100*(log(`var1')-log(`var2')) 
  gen `ratio' = `var1'/`var2'  if `var1'>0 & `var2'>0  // so don't have any negatives
  gen `lnratio' = log(`ratio') 
  gen `lngmean' = log(`gmean')
  gen `lnamean' = log(`amean')
  }

	*I wouldn't need this if I wrote everything tw plot1 || plot2 || plot3, instead of tw (plot1) (plot2) (plot3)
	if `"`addplot'"' != "" {
		local addplot `" ( `addplot' ) "'
		local addplot = subinstr(`"`addplot'"', "||", ")(", 100)
	}	
	*di `"`addplot'"'  
  
    return scalar level = `level'
	if "`ticonfidence'" != ""  return scalar ticonfidence = `ticonfidence' 
	if "`ticonfidence2'" != ""  return scalar ticonfidence2 = `ticonfidence2' 
	if "`ticonfidence3'" != ""  return scalar ticonfidence3 = `ticonfidence3' 
	if ("`ciloa'" != "" | "`cibias'" != "") return scalar cilevel = `cilevel'
  

*****difference*****
if regexm("`plot'", "difference") { 
	di " "
	qui su `amean'      // varies according to plot()
	local xmin = r(min)
	local xmax = r(max)
	
	
	*next 6 lines vary according to plot()
	qui count if `var1' < 0 | `var2' < 0
	*if r(N) >0  di in red "NB some observations have `var1' < 0  or `var2' < 0"
	qui su `diff'
	local ymin = r(min)
	local ymax = r(max)	

	
	qui intervallimits `diff', p100(`level') ticonfidence(`ticonfidence') ticonfidence2(`ticonfidence2') ticonfidence3(`ticonfidence3') cilevel(`cilevel')
	local ext "d"  
	
	if `=r(uloa)' > `ymax' local ymax = r(uloa)
	if `=r(lloa)' < `ymin' local ymin = r(lloa)
	local lineequality "yline(0, lc(gs0))"
	if `ymin' > 0 | `ymax' < 0  local lineequality ""	
	
	if "`ciloa'" != "" {
	    local drawciloa  `" (pcarrowi `=r(ciuloalow)' `xmax' `=r(ciuloaupp)' `xmax'  `=r(ciuloaupp)' `xmax' `=r(ciuloalow)' `xmax'   `=r(cilloalow)' `xmax' `=r(cilloaupp)' `xmax'  `=r(cilloaupp)' `xmax' `=r(cilloalow)' `xmax', `ciloaoptsall') "'
		return scalar ciuloaupp_`ext' = r(ciuloaupp)
		return scalar ciuloalow_`ext' = r(ciuloalow)
		return scalar cilloaupp_`ext' = r(cilloaupp)
		return scalar cilloalow_`ext' = r(cilloalow)				
	}	
	if "`cibias'" != "" {
	    local drawcibias  `" (pcarrowi `=r(cibiaslow)' `xmax' `=r(cibiasupp)' `xmax'  `=r(cibiasupp)' `xmax' `=r(cibiaslow)' `xmax', `cibiasoptsall') "'
		return scalar cibiasupp_`ext' = r(cibiasupp)
		return scalar cibiaslow_`ext' = r(cibiaslow)
	}

	if "`ticonfidence'" != ""	{
		local tioptsall `" range(`xmin' `xmax') `mytiopts' `tiopts'"'		
	    local drawti `" (function y = `=r(tilow)', `tioptsall')  (function y = `=r(tiupp)', `tioptsall') "'
		return scalar tiupp_`ext' = r(tiupp)
		return scalar tilow_`ext' = r(tilow)
	}
	if "`ticonfidence2'" != ""	{
		local tiopts2all `" range(`xmin' `xmax') `mytiopts2' `tiopts2'"'		
	    local drawti2 `" (function y = `=r(ti2low)', `tiopts2all')  (function y = `=r(ti2upp)', `tiopts2all') "'
		return scalar ti2upp_`ext' = r(ti2upp)
		return scalar ti2low_`ext' = r(ti2low)
	}
	if "`ticonfidence3'" != ""	{
		local tiopts3all `" range(`xmin' `xmax') `mytiopts3' `tiopts3'"'		
	    local drawti3 `" (function y = `=r(ti3low)', `tiopts3all')  (function y = `=r(ti3upp)', `tiopts3all') "'
		return scalar ti3upp_`ext' = r(ti3upp)
		return scalar ti3low_`ext' = r(ti3low)
	}
	
	local pioptsall `" range(`xmin' `xmax') `mypiopts' `piopts'"'	
	if "`predinterval'" != "" {
	    local drawpi `" (function y = `=r(pilow)', `pioptsall')  (function y = `=r(piupp)', `pioptsall') "'
		return scalar piupp_`ext' = r(piupp)
		return scalar pilow_`ext' = r(pilow)
	}
	
	local loaoptsall `" range(`xmin' `xmax') `myloaopts' `loaopts'"'	
	if "`hloa'" != "" {
	    local drawloa `" (function y = `=r(lloa)', `loaoptsall')  (function y = `=r(uloa)', `loaoptsall') "' 
		return scalar uloa_`ext' = r(uloa)
		return scalar lloa_`ext' = r(lloa)
	}		
	
	local biasoptsall `" range(`xmin' `xmax') `mybiasopts' `biasopts'"'	
	if "`hbias'" != "" {
	    local drawbias `" (function y = `=r(mean)', `biasoptsall') "'
	}
	
	return scalar sd_`ext' = r(sd)        // gsd if plot(ratio)
	return scalar mean_`ext' = r(mean)	  // gmean if plot(ratio)
	return scalar N_`ext' = r(N)


*next 4 lines vary according to plot()
di as res "DIFFERENCES..."
di as txt "Calculation" _c
di as txt _col(26) "N        Mean         SD       Interval(s)"  
di as res "A-B" _c


di as res _col(22) %5.0f `=r(N)' _c
di as res _col(30) %9.0g `=r(mean)' _c
di as res _col(41) %9.0g `=r(sd)'

if "`hloa'" != "" {	
	di as txt _col(28) "`level'% limits of agreement:" _c
	di as res _col(53) %9.0g `=r(lloa)' _c
	di as res _col(63) %9.0g `=r(uloa)'
}
if "`predinterval'" != "" {
	di as txt _col(28) "`level'% prediction interval:" _c	
	di as res _col(53) %9.0g `=r(pilow)' _c
	di as res _col(63) %9.0g `=r(piupp)'
}
if "`ticonfidence'" != "" {
	di as txt _col(9) "`level'% tolerance interval with `ticonfidence'% confidence:" _c	
	di as res _col(53) %9.0g `=r(tilow)' _c
	di as res _col(63) %9.0g `=r(tiupp)'
}
if "`ticonfidence2'" != "" {
	di as txt _col(9) "`level'% tolerance interval with `ticonfidence2'% confidence:" _c	
	di as res _col(53) %9.0g `=r(ti2low)' _c
	di as res _col(63) %9.0g `=r(ti2upp)'
}
if "`ticonfidence3'" != "" {
	di as txt _col(9) "`level'% tolerance interval with `ticonfidence3'% confidence:" _c	
	di as res _col(53) %9.0g `=r(ti3low)' _c
	di as res _col(63) %9.0g `=r(ti3upp)'
}
if "`ciloa'" != "" {
	di as txt _col(38) "`cilevel'% CI (LLOA):" _c	   
	di as res _col(53) %9.0g `=r(cilloalow)' _c
	di as res _col(63) %9.0g `=r(cilloaupp)'	
	di as txt _col(38) "`cilevel'% CI (ULOA):" _c	   
	di as res _col(53) %9.0g `=r(ciuloalow)' _c
	di as res _col(63) %9.0g `=r(ciuloaupp)'
}
if "`cibias'" != "" {
	di as txt _col(32) "`cilevel'% CI (Mean diff.):" _c	   // varies according to plot()
	di as res _col(53) %9.0g `=r(cibiaslow)' _c
	di as res _col(63) %9.0g `=r(cibiasupp)'	
}

*next section varies according to plot()
	if "`noregbias'" == "" {
	    if "`noregoutput'" == "" {
		    di " "
		    di as txt ". regress difference mean"
		}	
		`maybequi' reg `diff' `amean' 
		local b0 = _b[_cons]
	    local b1 = _b[`amean']
			di as txt _col(15) "-> regression-based bias:" _c
			di as res _col(46) %9.0g `b0' _c
			di as txt _col(55) " + " _c
			di as res _col(57) %9.0g `b1' _c 
			di as txt _col(67) " × Mean(A,B)"
			return scalar regbias_cons_`ext' = `b0'	
			return scalar regbiasslope_`ext' = `b1'	
		
		local regbiasoptsall `" range(`xmin' `xmax') `myregbiasopts' `regbiasopts'"'	
		local drawregbias `" (function y = `b0'+`b1'*x, `regbiasoptsall') "'
		
		if "`noregloa'" == "" {
			if "`noregoutput'" == ""  {
				di " "
				di as txt ". regress adj_abs_resid mean"
			}
			tempvar resid adjabsresid
			qui predict `resid', resid
			qui gen `adjabsresid'  = abs(`resid')*sqrt(_pi/2)  // i take a different but equivalent approach to Bland and Altman 1999
			`maybequi' reg `adjabsresid' `amean'              
			local c0 = _b[_cons]   
			local c1 = _b[`amean']
			di as txt _col(15) "-> regression-based SD:" _c
			di as res _col(46) %9.0g `c0' _c
			di as txt _col(55) " + " _c
			di as res _col(57) %9.0g `c1' _c 
			di as txt _col(67) " × Mean(A,B)"
			return scalar regsd_cons_`ext' = `c0'	
			return scalar regsdslope_`ext' = `c1'	
			
			qui drop `resid' `adjabsresid'			   			
			
			local regloaoptsall `" range(`xmin' `xmax') `myregloaopts' `regloaopts'"'
			local drawregloa  `" (function y = `b0'+`b1'*x - `z196'*(`c0'+`c1'*x), `regloaoptsall')  (function y = `b0'+`b1'*x + `z196'*(`c0'+`c1'*x), `regloaoptsall') "' 
				
			local reglloa_cons = `b0' - `z196'*`c0'
			local reglloaslope = `b1' - `z196'*`c1'
			local reguloa_cons = `b0' + `z196'*`c0'
			local reguloaslope = `b1' + `z196'*`c1'	
				
			di as txt _col(15) "-> regression-based `level'% LLOA:" _c
			di as res _col(46) %9.0g `reglloa_cons' _c
			di as txt _col(55) " + " _c
			di as res _col(57) %9.0g `reglloaslope' _c 
			di as txt _col(67) " × Mean(A,B)"

			di as txt _col(15) "-> regression-based `level'% ULOA:" _c
			di as res _col(46) %9.0g `reguloa_cons' _c
			di as txt _col(55) " + " _c
			di as res _col(57) %9.0g `reguloaslope' _c 
			di as txt _col(67) " × Mean(A,B)"			
						
			return scalar reguloa_cons_`ext' = `reguloa_cons'
			return scalar reguloaslope_`ext' = `reguloaslope'			
			return scalar reglloa_cons_`ext' = `reglloa_cons'
			return scalar reglloaslope_`ext' = `reglloaslope'
		}
	}

if `"`name'"' == "" local nameit "difference, replace"	
else local nameit `"`name'"'

*1st and 3rd lines vary according to plot()	
	tw (scatter `diff' `amean', ///
	`myscopts' `scopts') `drawregbias' `drawregloa' `drawbias' `drawloa' `drawpi' `drawti' `drawti2' `drawti3' `drawcibias' `drawciloa' `addplot', /// 
	ytitle("Difference:  `var1' - `var2'") xtitle("Mean of `var1' and `var2'") name(`nameit') ylab(, nogrid angle(horizontal)) ///
	`lineequality' legend(off) graphregion(color(white)) `options'   
}  




*****difference as a percent of the mean *****
if regexm("`plot'", "percentmean") { 
	di " "
	qui count if `var1' < 0 | `var2' < 0 | (`var1' == 0 & `var2' == 0 )
	if r(N) >0  di in red "now ignoring observations with `var1' < 0  or `var2' < 0  or both = 0"	
	qui drop  if `var1' < 0 | `var2' < 0 | (`var1' == 0 & `var2' == 0 ) 
	qui su `amean'      // varies according to plot()
	local xmin = r(min)
	local xmax = r(max)
	if r(N) == 0  di as err "no observations have (`var1' >= 0 and `var2' > 0) or (`var1' > 0 and `var2' >= 0)"	
	*xlabels
	qui nicexlabels `amean'
	local xla "`r(xla)'"
	
	*next 6 lines vary according to plot()
	qui su `diffpercentamean'
	local ymin = r(min)
	local ymax = r(max)

	
	qui intervallimits `diffpercentamean', p100(`level') ticonfidence(`ticonfidence') ticonfidence2(`ticonfidence2') ticonfidence3(`ticonfidence3') cilevel(`cilevel')
	local ext "pm"  

	if `=r(uloa)' > `ymax' local ymax = r(uloa)
	if `=r(lloa)' < `ymin' local ymin = r(lloa)
	local lineequality "yline(0, lc(gs0))"
	if `ymin' > 0 | `ymax' < 0  local lineequality ""	
	
	if "`ciloa'" != "" {
	    local drawciloa  `" (pcarrowi `=r(ciuloalow)' `xmax' `=r(ciuloaupp)' `xmax'  `=r(ciuloaupp)' `xmax' `=r(ciuloalow)' `xmax'   `=r(cilloalow)' `xmax' `=r(cilloaupp)' `xmax'  `=r(cilloaupp)' `xmax' `=r(cilloalow)' `xmax', `ciloaoptsall') "'
		return scalar ciuloaupp_`ext' = r(ciuloaupp)
		return scalar ciuloalow_`ext' = r(ciuloalow)
		return scalar cilloaupp_`ext' = r(cilloaupp)
		return scalar cilloalow_`ext' = r(cilloalow)				
	}	
	if "`cibias'" != "" {
	    local drawcibias  `" (pcarrowi `=r(cibiaslow)' `xmax' `=r(cibiasupp)' `xmax'  `=r(cibiasupp)' `xmax' `=r(cibiaslow)' `xmax', `cibiasoptsall') "'
		return scalar cibiasupp_`ext' = r(cibiasupp)
		return scalar cibiaslow_`ext' = r(cibiaslow)
	}

	if "`ticonfidence'" != ""	{
		local tioptsall `" range(`xmin' `xmax') `mytiopts' `tiopts'"'			
	    local drawti `" (function y = `=r(tilow)', `tioptsall')  (function y = `=r(tiupp)', `tioptsall') "'
		return scalar tiupp_`ext' = r(tiupp)
		return scalar tilow_`ext' = r(tilow)
	}
	if "`ticonfidence2'" != ""	{
		local tiopts2all `" range(`xmin' `xmax') `mytiopts2' `tiopts2'"'		
	    local drawti2 `" (function y = `=r(ti2low)', `tiopts2all')  (function y = `=r(ti2upp)', `tiopts2all') "'
		return scalar ti2upp_`ext' = r(ti2upp)
		return scalar ti2low_`ext' = r(ti2low)
	}
	if "`ticonfidence3'" != ""	{
		local tiopts3all `" range(`xmin' `xmax') `mytiopts3' `tiopts3'"'		
	    local drawti3 `" (function y = `=r(ti3low)', `tiopts3all')  (function y = `=r(ti3upp)', `tiopts3all') "'
		return scalar ti3upp_`ext' = r(ti3upp)
		return scalar ti3low_`ext' = r(ti3low)
	}

	local pioptsall `" range(`xmin' `xmax') `mypiopts' `piopts'"'	
	if "`predinterval'" != "" {
	    local drawpi `" (function y = `=r(pilow)', `pioptsall')  (function y = `=r(piupp)', `pioptsall') "'
		return scalar piupp_`ext' = r(piupp)
		return scalar pilow_`ext' = r(pilow)
	}
	
	local loaoptsall `" range(`xmin' `xmax') `myloaopts' `loaopts'"'	
	if "`hloa'" != "" {
	    local drawloa `" (function y = `=r(lloa)', `loaoptsall')  (function y = `=r(uloa)', `loaoptsall') "' 
		return scalar uloa_`ext' = r(uloa)
		return scalar lloa_`ext' = r(lloa)
	}		
	
	local biasoptsall `" range(`xmin' `xmax') `mybiasopts' `biasopts'"'	
	if "`hbias'" != "" {
	    local drawbias `" (function y = `=r(mean)', `biasoptsall') "'
	}
	
	return scalar sd_`ext' = r(sd)        
	return scalar mean_`ext' = r(mean)	  
	return scalar N_`ext' = r(N)


*next 4 lines vary according to plot()
di as res "PERCENTAGE DIFFERENCES (using Mean as denominator)..."
di as txt "Calculation" _c
di as txt _col(26) "N        Mean         SD       Interval(s)"  
di as res "100*(A-B)/[(A+B)/2]" _c 

di as res _col(22) %5.0f `=r(N)' _c
di as res _col(30) %9.0g `=r(mean)' _c
di as res _col(41) %9.0g `=r(sd)'

if "`hloa'" != "" {	
	di as txt _col(28) "`level'% limits of agreement:" _c
	di as res _col(53) %9.0g `=r(lloa)' _c
	di as res _col(63) %9.0g `=r(uloa)'
}
if "`predinterval'" != "" {
	di as txt _col(28) "`level'% prediction interval:" _c	
	di as res _col(53) %9.0g `=r(pilow)' _c
	di as res _col(63) %9.0g `=r(piupp)'
}
if "`ticonfidence'" != "" {
	di as txt _col(9) "`level'% tolerance interval with `ticonfidence'% confidence:" _c	
	di as res _col(53) %9.0g `=r(tilow)' _c
	di as res _col(63) %9.0g `=r(tiupp)'
}
if "`ticonfidence2'" != "" {
	di as txt _col(9) "`level'% tolerance interval with `ticonfidence2'% confidence:" _c	
	di as res _col(53) %9.0g `=r(ti2low)' _c
	di as res _col(63) %9.0g `=r(ti2upp)'
}
if "`ticonfidence3'" != "" {
	di as txt _col(9) "`level'% tolerance interval with `ticonfidence3'% confidence:" _c	
	di as res _col(53) %9.0g `=r(ti3low)' _c
	di as res _col(63) %9.0g `=r(ti3upp)'
}
if "`ciloa'" != "" {
	di as txt _col(38) "`cilevel'% CI (LLOA):" _c	   
	di as res _col(53) %9.0g `=r(cilloalow)' _c
	di as res _col(63) %9.0g `=r(cilloaupp)'	
	di as txt _col(38) "`cilevel'% CI (ULOA):" _c	   
	di as res _col(53) %9.0g `=r(ciuloalow)' _c
	di as res _col(63) %9.0g `=r(ciuloaupp)'
}
if "`cibias'" != "" {
	di as txt _col(31) "`cilevel'% CI (Mean %diff.):" _c	  // varies according to plot()
	di as res _col(53) %9.0g `=r(cibiaslow)' _c
	di as res _col(63) %9.0g `=r(cibiasupp)'	
}


*next section varies according to plot()
	if "`noregbias'" == "" {
	    if "`noregoutput'" == "" {
		    di " "
		    di as txt ". regress percentmean ln_mean"
		}	
		`maybequi' reg `diffpercentamean' `lnamean'  
		local b0 = _b[_cons]
	    local b1 = _b[`lnamean']
			di as txt _col(15) "-> regression-based bias:" _c
			di as res _col(42) %9.0g `b0' _c
			di as txt _col(51) " + " _c
			di as res _col(53) %9.0g `b1' _c 
			di as txt _col(63) " × ln(Mean(A,B))"
			return scalar regbias_cons_`ext' = `b0'	
			return scalar regbiasslope_`ext' = `b1'			
		
		local regbiasoptsall `" range(`xmin' `xmax') `myregbiasopts' `regbiasopts'"'	
		local drawregbias `" (function y = `b0'+`b1'*log(x), `regbiasoptsall') "'
		
		if "`noregloa'" == "" {
			if "`noregoutput'" == ""  {
				di " "
				di as txt ". regress adj_abs_resid ln_mean"
			}
			tempvar resid adjabsresid
			qui predict `resid', resid
			qui gen `adjabsresid'  = abs(`resid')*sqrt(_pi/2)  
			`maybequi' reg `adjabsresid' `lnamean'              
			local c0 = _b[_cons]   
			local c1 = _b[`lnamean']
			di as txt _col(11) "-> regression-based SD:" _c
			di as res _col(42) %9.0g `c0' _c
			di as txt _col(51) " + " _c
			di as res _col(53) %9.0g `c1' _c 
			di as txt _col(63) " × ln(Mean(A,B))"
			return scalar regsd_cons_`ext' = `c0'	
			return scalar regsdslope_`ext' = `c1'			
			
			qui drop `resid' `adjabsresid'			   			
			
			local regloaoptsall `" range(`xmin' `xmax') `myregloaopts' `regloaopts'"'
			local drawregloa  `" (function y = `b0'+`b1'*log(x) - `z196'*(`c0'+`c1'*log(x)), `regloaoptsall')  (function y = `b0'+`b1'*log(x) + `z196'*(`c0'+`c1'*log(x)), `regloaoptsall') "' 
			
			local reglloa_cons = `b0' - `z196'*`c0'
			local reglloaslope = `b1' - `z196'*`c1'
			local reguloa_cons = `b0' + `z196'*`c0'
			local reguloaslope = `b1' + `z196'*`c1'	
			
			di as txt _col(11) "-> regression-based `level'% LLOA:" _c
			di as res _col(42) %9.0g `reglloa_cons' _c
			di as txt _col(51) " + " _c
			di as res _col(53) %9.0g `reglloaslope' _c 
			di as txt _col(63) " × ln(Mean(A,B))"

			di as txt _col(11) "-> regression-based `level'% ULOA:" _c
			di as res _col(42) %9.0g `reguloa_cons' _c
			di as txt _col(51) " + " _c
			di as res _col(53) %9.0g `reguloaslope' _c 
			di as txt _col(63) " × ln(Mean(A,B))"
			
			return scalar reguloa_cons_`ext' = `reguloa_cons'
			return scalar reguloaslope_`ext' = `reguloaslope'			
			return scalar reglloa_cons_`ext' = `reglloa_cons'
			return scalar reglloaslope_`ext' = `reglloaslope'
		}
	}


if `"`name'"' == "" local nameit "percentmean, replace"	
else local nameit `"`name'"'

*1st and 3rd lines vary according to plot()	
	tw (scatter `diffpercentamean' `amean', ///
	`myscopts' `scopts') `drawregbias' `drawregloa' `drawbias' `drawloa' `drawpi' `drawti' `drawti2' `drawti3' `drawcibias' `drawciloa' `addplot', /// 
	ytitle("% Difference:  100(`shortvar1' - `shortvar2')/Mean") xtitle("Mean of `var1' and `var2'") name(`nameit') xsc(log) xlab(`xla') ylab(, nogrid angle(horizontal)) ///
	`lineequality' legend(off) graphregion(color(white)) `options'   
}  



*** now do the log stuff (which has the strictest requirements, i.e. A>0, B>0)


*****difference as a percent of the Lmean *****
if regexm("`plot'", "percentlmean") { 
	di " "
	qui count if `var1' <= 0 | `var2' <= 0
	if r(N) >0  di as err "now ignoring observations with `var1' <= 0  or `var2' <= 0"
	qui drop  if `var1' <= 0 | `var2' <= 0  
	qui su `gmean'      // varies according to plot()
	local xmin = r(min)
	local xmax = r(max)
	if r(N) == 0  di as err "no observations have (`var1' > 0 and `var2' > 0)"
	*xlabels
	qui nicexlabels `gmean'
	local xla "`r(xla)'"
	
	
	*next 6 lines vary according to plot()
	qui su `diffpercentlmean'
	local ymin = r(min)
	local ymax = r(max)
	
	
	qui intervallimits `diffpercentlmean', p100(`level') ticonfidence(`ticonfidence') ticonfidence2(`ticonfidence2') ticonfidence3(`ticonfidence3') cilevel(`cilevel')
	local ext "plm"  
	
	if `=r(uloa)' > `ymax' local ymax = r(uloa)
	if `=r(lloa)' < `ymin' local ymin = r(lloa)
	local lineequality "yline(0, lc(gs0))"
	if `ymin' > 0 | `ymax' < 0  local lineequality ""
	
	if "`ciloa'" != "" {
	    local drawciloa  `" (pcarrowi `=r(ciuloalow)' `xmax' `=r(ciuloaupp)' `xmax'  `=r(ciuloaupp)' `xmax' `=r(ciuloalow)' `xmax'   `=r(cilloalow)' `xmax' `=r(cilloaupp)' `xmax'  `=r(cilloaupp)' `xmax' `=r(cilloalow)' `xmax', `ciloaoptsall') "'
		return scalar ciuloaupp_`ext' = r(ciuloaupp)
		return scalar ciuloalow_`ext' = r(ciuloalow)
		return scalar cilloaupp_`ext' = r(cilloaupp)
		return scalar cilloalow_`ext' = r(cilloalow)				
	}	
	if "`cibias'" != "" {
	    local drawcibias  `" (pcarrowi `=r(cibiaslow)' `xmax' `=r(cibiasupp)' `xmax'  `=r(cibiasupp)' `xmax' `=r(cibiaslow)' `xmax', `cibiasoptsall') "'
		return scalar cibiasupp_`ext' = r(cibiasupp)
		return scalar cibiaslow_`ext' = r(cibiaslow)
	}

	if "`ticonfidence'" != ""	{
		local tioptsall `" range(`xmin' `xmax') `mytiopts' `tiopts'"'			
	    local drawti `" (function y = `=r(tilow)', `tioptsall')  (function y = `=r(tiupp)', `tioptsall') "'
		return scalar tiupp_`ext' = r(tiupp)
		return scalar tilow_`ext' = r(tilow)
	}
	if "`ticonfidence2'" != ""	{
		local tiopts2all `" range(`xmin' `xmax') `mytiopts2' `tiopts2'"'		
	    local drawti2 `" (function y = `=r(ti2low)', `tiopts2all')  (function y = `=r(ti2upp)', `tiopts2all') "'
		return scalar ti2upp_`ext' = r(ti2upp)
		return scalar ti2low_`ext' = r(ti2low)
	}
	if "`ticonfidence3'" != ""	{
		local tiopts3all `" range(`xmin' `xmax') `mytiopts3' `tiopts3'"'		
	    local drawti3 `" (function y = `=r(ti3low)', `tiopts3all')  (function y = `=r(ti3upp)', `tiopts3all') "'
		return scalar ti3upp_`ext' = r(ti3upp)
		return scalar ti3low_`ext' = r(ti3low)
	}	

	local pioptsall `" range(`xmin' `xmax') `mypiopts' `piopts'"'	
	if "`predinterval'" != "" {
	    local drawpi `" (function y = `=r(pilow)', `pioptsall')  (function y = `=r(piupp)', `pioptsall') "'
		return scalar piupp_`ext' = r(piupp)
		return scalar pilow_`ext' = r(pilow)
	}
	
	local loaoptsall `" range(`xmin' `xmax') `myloaopts' `loaopts'"'	
	if "`hloa'" != "" {
	    local drawloa `" (function y = `=r(lloa)', `loaoptsall')  (function y = `=r(uloa)', `loaoptsall') "' 
		return scalar uloa_`ext' = r(uloa)
		return scalar lloa_`ext' = r(lloa)
	}		
	
	local biasoptsall `" range(`xmin' `xmax') `mybiasopts' `biasopts'"'	
	if "`hbias'" != "" {
	    local drawbias `" (function y = `=r(mean)', `biasoptsall') "'
	}
	
	return scalar sd_`ext' = r(sd)        
	return scalar mean_`ext' = r(mean)	  
	return scalar N_`ext' = r(N)


*next 4 lines vary according to plot()
di as res "PERCENTAGE DIFFERENCES (using Logarithmic Mean as denominator)..."
di as txt "Calculation" _c
di as txt _col(26) "N        Mean         SD       Interval(s)"  
di as res "100*(A-B)/LMean(A,B)" _c 

di as res _col(22) %5.0f `=r(N)' _c
di as res _col(30) %9.0g `=r(mean)' _c
di as res _col(41) %9.0g `=r(sd)'

if "`hloa'" != "" {	
	di as txt _col(28) "`level'% limits of agreement:" _c
	di as res _col(53) %9.0g `=r(lloa)' _c
	di as res _col(63) %9.0g `=r(uloa)'
}
if "`predinterval'" != "" {
	di as txt _col(28) "`level'% prediction interval:" _c	
	di as res _col(53) %9.0g `=r(pilow)' _c
	di as res _col(63) %9.0g `=r(piupp)'
}
if "`ticonfidence'" != "" {
	di as txt _col(9) "`level'% tolerance interval with `ticonfidence'% confidence:" _c	
	di as res _col(53) %9.0g `=r(tilow)' _c
	di as res _col(63) %9.0g `=r(tiupp)'
}
if "`ticonfidence2'" != "" {
	di as txt _col(9) "`level'% tolerance interval with `ticonfidence2'% confidence:" _c	
	di as res _col(53) %9.0g `=r(ti2low)' _c
	di as res _col(63) %9.0g `=r(ti2upp)'
}
if "`ticonfidence3'" != "" {
	di as txt _col(9) "`level'% tolerance interval with `ticonfidence3'% confidence:" _c	
	di as res _col(53) %9.0g `=r(ti3low)' _c
	di as res _col(63) %9.0g `=r(ti3upp)'
}
if "`ciloa'" != "" {
	di as txt _col(38) "`cilevel'% CI (LLOA):" _c	   
	di as res _col(53) %9.0g `=r(cilloalow)' _c
	di as res _col(63) %9.0g `=r(cilloaupp)'	
	di as txt _col(38) "`cilevel'% CI (ULOA):" _c	   
	di as res _col(53) %9.0g `=r(ciuloalow)' _c
	di as res _col(63) %9.0g `=r(ciuloaupp)'
}
if "`cibias'" != "" {
	di as txt _col(31) "`cilevel'% CI (Mean %diff.):" _c	  // varies according to plot()
	di as res _col(53) %9.0g `=r(cibiaslow)' _c
	di as res _col(63) %9.0g `=r(cibiasupp)'	
}


*next section varies according to plot()
	if "`noregbias'" == "" {
	    if "`noregoutput'" == "" {
		    di " "
		    di as txt ". regress percentlmean ln_gmean"
		}	
		`maybequi' reg `diffpercentlmean' `lngmean'  
		local b0 = _b[_cons]
	    local b1 = _b[`lngmean']
			di as txt _col(11) "-> regression-based bias:" _c
			di as res _col(41) %9.0g `b0' _c
			di as txt _col(50) " + " _c
			di as res _col(52) %9.0g `b1' _c 
			di as txt _col(62) " × ln(GMean(A,B))"
			return scalar regbias_cons_`ext' = `b0'	
			return scalar regbiasslope_`ext' = `b1'			
		
		local regbiasoptsall `" range(`xmin' `xmax') `myregbiasopts' `regbiasopts'"'	
		local drawregbias `" (function y = `b0'+`b1'*log(x), `regbiasoptsall') "'
		
		if "`noregloa'" == "" {
			if "`noregoutput'" == ""  {
				di " "
				di as txt ". regress adj_abs_resid ln_gmean"
			}	
			tempvar resid adjabsresid
			qui predict `resid', resid
			qui gen `adjabsresid'  = abs(`resid')*sqrt(_pi/2) 
			`maybequi' reg `adjabsresid' `lngmean'              
			local c0 = _b[_cons]   
			local c1 = _b[`lngmean']
			di as txt _col(11) "-> regression-based SD:" _c
			di as res _col(41) %9.0g `c0' _c
			di as txt _col(50) " + " _c
			di as res _col(52) %9.0g `c1' _c 
			di as txt _col(62) " × ln(GMean(A,B))"
			return scalar regsd_cons_`ext' = `c0'	
			return scalar regsdslope_`ext' = `c1'			
			
			qui drop `resid' `adjabsresid'			   			
			
			local regloaoptsall `" range(`xmin' `xmax') `myregloaopts' `regloaopts'"'
			local drawregloa  `" (function y = `b0'+`b1'*log(x) - `z196'*(`c0'+`c1'*log(x)), `regloaoptsall')  (function y = `b0'+`b1'*log(x) + `z196'*(`c0'+`c1'*log(x)), `regloaoptsall') "' 
			
			local reglloa_cons = `b0' - `z196'*`c0'
			local reglloaslope = `b1' - `z196'*`c1'
			local reguloa_cons = `b0' + `z196'*`c0'
			local reguloaslope = `b1' + `z196'*`c1'	
			
			di as txt _col(11) "-> regression-based `level'% LLOA:" _c
			di as res _col(41) %9.0g `reglloa_cons' _c
			di as txt _col(50) " + " _c
			di as res _col(52) %9.0g `reglloaslope' _c 
			di as txt _col(62) " × ln(GMean(A,B))"

			di as txt _col(11) "-> regression-based `level'% ULOA:" _c
			di as res _col(41) %9.0g `reguloa_cons' _c
			di as txt _col(50) " + " _c
			di as res _col(52) %9.0g `reguloaslope' _c 
			di as txt _col(62) " × ln(GMean(A,B))"
			
			return scalar reguloa_cons_`ext' = `reguloa_cons'
			return scalar reguloaslope_`ext' = `reguloaslope'			
			return scalar reglloa_cons_`ext' = `reglloa_cons'
			return scalar reglloaslope_`ext' = `reglloaslope'
		}
	}
	
	
if `"`name'"' == "" local nameit "percentlmean, replace"	
else local nameit `"`name'"'

*1st and 3rd lines vary according to plot()	
	tw (scatter `diffpercentlmean' `gmean', ///
	`myscopts' `scopts') `drawregbias' `drawregloa' `drawbias' `drawloa' `drawpi' `drawti' `drawti2' `drawti3' `drawcibias' `drawciloa' `addplot', /// 
	ytitle("% Difference:  100(`shortvar1' - `shortvar2')/LMean") xtitle("GMean of `var1' and `var2'") name(`nameit') xsc(log) xlab(`xla') ylab(,nogrid angle(horizontal)) ///
	`lineequality' legend(off) graphregion(color(white)) `options'   
} 



******Ratio*******
if regexm("`plot'", "ratio") { 
	di " "
	qui count if `var1' <= 0 | `var2' <= 0
	if r(N) >0  di in red "now ignoring observations with `var1' <= 0  or `var2' <= 0"
	qui drop  if `var1' <= 0 | `var2' <= 0 
	
	qui su `gmean'      // varies according to plot()
	local xmin = r(min)
	local xmax = r(max)
	if r(N) == 0  di as err "no observations have (`var1' > 0 and `var2' > 0)"
	*xlabels
	qui nicexlabels `gmean'
	local xla "`r(xla)'"
	

	qui su `ratio'      // varies according to plot()
	local ymin = r(min)
	local ymax = r(max)	
	
	
	*next 2 lines vary according to plot()
	qui intervallimits `lnratio', p100(`level') ticonfidence(`ticonfidence') ticonfidence2(`ticonfidence2') ticonfidence3(`ticonfidence3')  cilevel(`cilevel') exp  // all results have been exponentiated :)
	local ext "r"  
	
	
	if "`ciloa'" != "" {
	    local drawciloa  `" (pcarrowi `=r(ciuloalow)' `xmax' `=r(ciuloaupp)' `xmax'  `=r(ciuloaupp)' `xmax' `=r(ciuloalow)' `xmax'   `=r(cilloalow)' `xmax' `=r(cilloaupp)' `xmax'  `=r(cilloaupp)' `xmax' `=r(cilloalow)' `xmax', `ciloaoptsall') "'
		return scalar ciuloaupp_`ext' = r(ciuloaupp)
		return scalar ciuloalow_`ext' = r(ciuloalow)
		return scalar cilloaupp_`ext' = r(cilloaupp)
		return scalar cilloalow_`ext' = r(cilloalow)
		if `=r(ciuloaupp)' > `ymax' local ymax = r(ciuloaupp)
		if `=r(cilloalow)' < `ymin' local ymin = r(cilloalow)		
	}	
	if "`cibias'" != "" {
	    local drawcibias  `" (pcarrowi `=r(cibiaslow)' `xmax' `=r(cibiasupp)' `xmax'  `=r(cibiasupp)' `xmax' `=r(cibiaslow)' `xmax', `cibiasoptsall') "'
		return scalar cibiasupp_`ext' = r(cibiasupp)
		return scalar cibiaslow_`ext' = r(cibiaslow)
		if `=r(cibiasupp)' > `ymax' local ymax = r(cibiasupp)
		if `=r(cibiaslow)' < `ymin' local ymin = r(cibiaslow)		
	}

	if "`ticonfidence'" != ""	{
	    local tioptsall `" range(`xmin' `xmax') `mytiopts' `tiopts'"'	
		local drawti `" (function y = `=r(tilow)', `tioptsall')  (function y = `=r(tiupp)', `tioptsall') "'
		return scalar tiupp_`ext' = r(tiupp)
		return scalar tilow_`ext' = r(tilow)
		if `=r(tiupp)' > `ymax' local ymax = r(tiupp)
		if `=r(tilow)' < `ymin' local ymin = r(tilow)
	}
	if "`ticonfidence2'" != ""	{
		local tiopts2all `" range(`xmin' `xmax') `mytiopts2' `tiopts2'"'		
	    local drawti2 `" (function y = `=r(ti2low)', `tiopts2all')  (function y = `=r(ti2upp)', `tiopts2all') "'
		return scalar ti2upp_`ext' = r(ti2upp)
		return scalar ti2low_`ext' = r(ti2low)
		if `=r(ti2upp)' > `ymax' local ymax = r(ti2upp)
		if `=r(ti2low)' < `ymin' local ymin = r(ti2low)		
	}
	if "`ticonfidence3'" != ""	{
		local tiopts3all `" range(`xmin' `xmax') `mytiopts3' `tiopts3'"'		
	    local drawti3 `" (function y = `=r(ti3low)', `tiopts3all')  (function y = `=r(ti3upp)', `tiopts3all') "'
		return scalar ti3upp_`ext' = r(ti3upp)
		return scalar ti3low_`ext' = r(ti3low)
		if `=r(ti3upp)' > `ymax' local ymax = r(ti3upp)
		if `=r(ti3low)' < `ymin' local ymin = r(ti3low)		
	}	

	local pioptsall `" range(`xmin' `xmax') `mypiopts' `piopts'"'	
	if "`predinterval'" != "" {
	    local drawpi `" (function y = `=r(pilow)', `pioptsall')  (function y = `=r(piupp)', `pioptsall') "'
		return scalar piupp_`ext' = r(piupp)
		return scalar pilow_`ext' = r(pilow)
		if `=r(piupp)' > `ymax' local ymax = r(piupp)
		if `=r(pilow)' < `ymin' local ymin = r(pilow)		
	}
	
	local loaoptsall `" range(`xmin' `xmax') `myloaopts' `loaopts'"'	
	if "`hloa'" != "" {
	    local drawloa `" (function y = `=r(lloa)', `loaoptsall')  (function y = `=r(uloa)', `loaoptsall') "' 
		return scalar uloa_`ext' = r(uloa)
		return scalar lloa_`ext' = r(lloa)		
	}		
	if `=r(uloa)' > `ymax' local ymax = r(uloa)
	if `=r(lloa)' < `ymin' local ymin = r(lloa)	
		
	local biasoptsall `" range(`xmin' `xmax') `mybiasopts' `biasopts'"'	
	if "`hbias'" != "" {
	    local drawbias `" (function y = `=r(mean)', `biasoptsall') "'
	}
	
	return scalar gsd_`ext' = r(sd)         
	return scalar gmean_`ext' = r(mean)	  
	return scalar N_`ext' = r(N)


*next 4 lines vary according to plot()
di as res "RATIOS..."
di as txt "Calculation" _c
di as txt _col(26) "N       GMean        GSD       Interval(s)"  
di as res "A/B" _c 

di as res _col(22) %5.0f `=r(N)' _c
di as res _col(30) %9.0g `=r(mean)' _c
di as res _col(41) %9.0g `=r(sd)'

if "`hloa'" != "" {	
	di as txt _col(28) "`level'% limits of agreement:" _c
	di as res _col(53) %9.0g `=r(lloa)' _c
	di as res _col(63) %9.0g `=r(uloa)'
}
if "`predinterval'" != "" {
	di as txt _col(28) "`level'% prediction interval:" _c	
	di as res _col(53) %9.0g `=r(pilow)' _c
	di as res _col(63) %9.0g `=r(piupp)'
}
if "`ticonfidence'" != "" {
	di as txt _col(9) "`level'% tolerance interval with `ticonfidence'% confidence:" _c	
	di as res _col(53) %9.0g `=r(tilow)' _c
	di as res _col(63) %9.0g `=r(tiupp)'
}
if "`ticonfidence2'" != "" {
	di as txt _col(9) "`level'% tolerance interval with `ticonfidence2'% confidence:" _c	
	di as res _col(53) %9.0g `=r(ti2low)' _c
	di as res _col(63) %9.0g `=r(ti2upp)'
}
if "`ticonfidence3'" != "" {
	di as txt _col(9) "`level'% tolerance interval with `ticonfidence3'% confidence:" _c	
	di as res _col(53) %9.0g `=r(ti3low)' _c
	di as res _col(63) %9.0g `=r(ti3upp)'
}
if "`ciloa'" != "" {
	di as txt _col(38) "`cilevel'% CI (LLOA):" _c	   
	di as res _col(53) %9.0g `=r(cilloalow)' _c
	di as res _col(63) %9.0g `=r(cilloaupp)'	
	di as txt _col(38) "`cilevel'% CI (ULOA):" _c	   
	di as res _col(53) %9.0g `=r(ciuloalow)' _c
	di as res _col(63) %9.0g `=r(ciuloaupp)'
}
if "`cibias'" != "" {
	di as txt _col(31) "`cilevel'% CI (GMean Ratio):" _c	  // varies according to plot()
	di as res _col(53) %9.0g `=r(cibiaslow)' _c
	di as res _col(63) %9.0g `=r(cibiasupp)'	
}


*next section varies according to plot()
	if "`noregbias'" == "" {
	    if "`noregoutput'" == "" {
		    di " "
		    di as txt ". regress ln_ratio ln_gmean"
		}	
		`maybequi' reg `lnratio' `lngmean'  
		local b0 = _b[_cons]
	    local b1 = _b[`lngmean']
			di as txt _col(11) "-> regression-based GMean Ratio:" _c
			di as res _col(47) %9.0g exp(`b0') _c
			di as txt _col(56) " × GMean(A,B)^" _c
			di as res _col(68) %9.0g `b1' 			
			return scalar regbias_cons_`ext' = exp(`b0')	
			return scalar regbiasslope_`ext' = `b1'	
		
		local regbiasoptsall `" range(`xmin' `xmax') `myregbiasopts' `regbiasopts'"'	
		local drawregbias `" (function y = exp(`b0'+`b1'*log(x)), `regbiasoptsall') "'
		
		if "`noregloa'" == "" {
			if "`noregoutput'" == ""  {
				di " "
				di as txt ". regress adj_abs_resid ln_gmean"
			}	
			tempvar resid adjabsresid
			qui predict `resid', resid
			qui gen `adjabsresid'  = abs(`resid')*sqrt(_pi/2)  
			`maybequi' reg `adjabsresid' `lngmean'              
			local c0 = _b[_cons]   
			local c1 = _b[`lngmean']
			di as txt _col(11) "-> regression-based GSD Ratio:" _c
			di as res _col(47) %9.0g exp(`c0') _c
			di as txt _col(56) " × GMean(A,B)^" _c
			di as res _col(68) %9.0g `c1' 			
			return scalar reggsd_cons_`ext' = exp(`c0')	
			return scalar reggsdslope_`ext' = `c1'				
			
			qui drop `resid' `adjabsresid'			   			
			
			local regloaoptsall `" range(`xmin' `xmax') `myregloaopts' `regloaopts'"'
			local drawregloa  `" (function y = exp(`b0'+`b1'*log(x) - `z196'*(`c0'+`c1'*log(x))), `regloaoptsall')  (function y = exp(`b0'+`b1'*log(x) + `z196'*(`c0'+`c1'*log(x))), `regloaoptsall') "' 
			
			local reglloafactr = exp(`b0' - `z196'*`c0')
			local reglloapower = `b1' - `z196'*`c1'
			local reguloafactr = exp(`b0' + `z196'*`c0')
			local reguloapower = `b1' + `z196'*`c1'	

			di as txt _col(11) "-> regression-based `level'% LLOA Ratio:" _c
			di as res _col(47) %9.0g `reglloafactr' _c
			di as txt _col(56) " × GMean(A,B)^" _c
			di as res _col(68) %9.0g `reglloapower' 			

			di as txt _col(11) "-> regression-based `level'% ULOA Ratio:" _c
			di as res _col(47) %9.0g `reguloafactr' _c
			di as txt _col(56) " × GMean(A,B)^" _c
			di as res _col(68) %9.0g `reguloapower'
			
			return scalar reguloafactr_`ext' = `reguloafactr'
			return scalar reguloapower_`ext' = `reguloapower'			
			return scalar reglloafactr_`ext' = `reglloafactr'
			return scalar reglloapower_`ext' = `reglloapower'
		}
	}

	*so labels can lie slightly outside the range     // unique to plot(ratio)
	local ymaxminratio = `ymax'/`ymin'
	local ymin = `ymin'*`ymaxminratio'^(-0.1)
	local ymax = `ymax'*`ymaxminratio'^(0.1)
	
	*next 3 lines vary according to plot()
	local lineequality "yline(1, lc(gs0))"
	if `ymin' > 1 | `ymax' < 1  local lineequality ""
	
	*yticks ... unique to ratio
	if (`ymin' < 0.5 & `ymax' > 1) | (`ymin' < 1 & `ymax' > 2) {
		local minup = ceil(10*`ymin')/10		
		if `ymax' < 5 {
			local maxdown = floor(10*`ymax')/10
			local yticks "ymtick(`minup' (.1) `maxdown')"
		}
		else {
			local maxdown = floor(`ymax')
			local yticks "ymtick(`minup' (.1) 2) ytick(2 (1) `maxdown')"			
		}
	}
	
	*ylabels ... unique to ratio
	if (`ymin' < 0.5 & `ymax' > 1) | (`ymin' < 1 & `ymax' > 2) | (`ymax'/`ymin' > 15) {
		 qui niceloglabels_shorter `ymin' `ymax', local(yla) style(125)
	}	
	else {
		_natscale `ymin' `ymax' 9
		if r(min) < `ymin' local ylabstart = r(min) + r(delta)  // bottom one can end up off axis!
		else local ylabstart = r(min)
		local yla "`ylabstart' (`=r(delta)') `=r(max)'"
		local yticks "ymtick(##2)"
	}	
	
	
if `"`name'"' == "" local nameit "ratio, replace"	
else local nameit `"`name'"'

*1st and 3rd lines vary according to plot()	
	tw (scatter `ratio' `gmean', ///
	`myscopts' `scopts') `drawregbias' `drawregloa' `drawbias' `drawloa' `drawpi' `drawti' `drawti2' `drawti3' `drawcibias' `drawciloa' `addplot', /// 
	ytitle("Ratio:  `var1' / `var2'") xtitle("GMean of `var1' and `var2'") name(`nameit') ///
	xsc(log) xlab(`xla') ysc(range(`ymin' `ymax') log) ylab(`yla', nogrid angle(horizontal)) `yticks'  ///
	`lineequality' legend(off) graphregion(color(white)) `options'   
} 
  
restore
end