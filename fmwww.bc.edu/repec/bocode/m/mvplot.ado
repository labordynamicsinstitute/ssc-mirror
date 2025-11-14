*! version 1.0 \ Daniel Krähmer \ 11 November 2025

program mvplot
	version 16
	syntax [if] [in],						///
		coef(varname numeric)				///
		DECisions(varlist min=1 numeric)	///
		IREGression(str)					///
		[									///
		bins(integer 20)					///
		rowgap(real -1)						///
		pangap(real 0)						///
		se(varname numeric)					///
		sig(varname)						///
		iregnostar							///
		iregnose							///
		KDLine(str)							///
		KDAarea(str)						///
		KDNpoints(real 100)					///
		KDKernel(str)						///
		* 									///
		]
	
qui{
	*** PRELIMINARIES ***
	
	* Test fatal conditions
	local iregression = lower("`iregression'")
	
	if !inlist("`iregression'", "ols", "wls") {
		di as err "iregression() incorrectly specified. Must be OLS or WLS."
		exit 
	}
	if "`iregression'" == "wls" & "`se'" == "" {
		di as err "iregression(wls) requires se()."
		exit 
	}
	if "`sig'" != "" {
		qui levelsof `sig', clean
		if !inlist("`r(levels)'", "0", "1", "0 1") {
			di as err "sig() incorrectly specified. Must be binary (0/1)."
			exit 
		}
	}

	* Preserve original data
	preserve 
	
	* Drop ineligible observations
	marksample touse						// 	if/in
	quietly count if `touse'
    if `r(N)' == 0 {
		error 2000
    }
	keep if `touse' == 1
	drop if missing(`coef')					// 	coef
	foreach d in `decisions' {				// 	decisions
		qui drop if missing(`d')
	}
	
	
	*** PREPROCESSING *** 
	
	* Prepare frames
	frame pwf
	local dframe 		`r(currentframe)'	// default frame
	
	tempname iframe 
	frame create 		`iframe'			// influence frame
	
	tempname pframe
	frame create 		`pframe'			// plotting frame
	frame `pframe': 	set obs 1
	
	
	* Run influence regression
	if "`iregression'" == "ols" {
		local cmd regress
		local opt
	} 
	if "`iregression'" == "wls" {
		local cmd vwls
		local opt , sd(se)
	} 
	`cmd' `coef' i.(`decisions') `opt'
	
	
	* Save results in matrix
	tempname imat
	matrix `imat' = r(table)
	
	
	* Clean matrix
	local stats: rowfullnames `imat'		// rows names: statistics
	local preds: colfullnames `imat'		// column names: predictors
	
	
	* Separate variable names and levels	
	foreach l in `c(alpha)' {
		if !strpos("`preds'", "_`l'_"){
			local sep _`l'_
			continue, break
		}
	}	
	local preds: subinstr local preds "." "`sep'", all
	foreach p in `preds' {
		local preds2 `"`preds2' "h`p'""'
	}
	matrix colnames `imat' = `preds2'
	
	
	* Save results as data
	frame change `iframe'
	svmat `imat', names(col)
	
	rename h*`sep'* *[2]`sep'*[1]			// clean
	rename *b *
	
	gen stat = ""							// label
	local c: word count `stats'
	forvalues i = 1/`c' {
		replace stat = "`:word `i' of `stats''" in `i'
	}
	drop h_cons 							// reduce
	keep if inlist(stat, "b", "pvalue", "se")
	
	qui ds stat, not						// reshape
	rename (`r(varlist)') h_=
	reshape long h_, i(stat) j(par_val) string
	reshape wide h_, i(par_val) j(stat) string
	rename  h_* 	*
	rename 	pvalue  p
	
	split par_val, parse("`sep'") 
	rename par_val1 par
	rename par_val2 val
	
	if "`iregnostar'" == "" {
		gen stars = ""
		replace stars = "*"		if !missing(p) & p<0.05
		replace stars = "**" 	if !missing(p) & p<0.01
		replace stars = "***"	if !missing(p) & p<0.001
	} 
	
	* Reorder by abs. influence
	gen b_abs = abs(b)
	recode b_abs (0 = .)
	bysort par: egen b_abs_max = max(b_abs)
	gsort -b_abs_max -b_abs, mfirst 
	
	
	* Switch to main frame and calculate density distributions
	frame change `dframe'
	foreach var in atx xa ya xs ys id {
		tempvar `var'
	}
	qui sum `coef', meanonly
	range `atx' r(min) r(max) `kdnpoints'
	kdensity `coef', kernel(`kdkernel') gen(`xa' `ya') at(`atx') nogr 
	local bw `r(bwidth)'
	
	if "`sig'" != "" {
		kdensity `coef' if `sig' == 1, ///
			kernel(`kdkernel') gen(`xs' `ys') at(`atx') nogr width(`bw') 
		qui sum `sig', meanonly
		replace `ys' = `ys' * `r(mean)'
		local sig_shading (area `ys' `xs', ///
			yaxis(1 2) color(black%50) lwidth(none) `kdarea')
	}
	gen `id' = _n
	levelsof `atx'
	local newobs `r(r)'
	
	
	* Port density distributions to plotting frame
	frame change `pframe'
	set obs `newobs'
	gen `id' = _n
	
	frlink 1:1 `id', frame(`dframe')
	frget `xa' = `xa' `ya' = `ya', from(`dframe')
	if "`sig'" != "" frget `xs' = `xs' `ys' = `ys', from(`dframe') 
	drop `dframe' `id'
	
	
	* Determine a reasonable rowgap (unless specified)
	frame change `pframe'
	sum `ya', meanonly
	local ymax = `r(max)'
	local ymax 	: display %9.2f `ymax'
	local yhalf = `ymax' / 2
	
	frame `iframe': count
	if "`rowgap'" == "-1" {
		local rowgap = (`ymax')/ `r(N)'
	}
	
	
	* Create y variables for bottom panel
	frame change `iframe'
	frame `pframe': gen y0 = 0
	local j = 1
	forvalues i = 1/`=_N' {
		if par[`i'] != par[`=`i' - 1'] {
			frame `pframe': ///
				gen double y`j' = y`=`j' - 1' - 1.5 * `rowgap' - `pangap'
			local toskip `toskip' `j'
			local ++j
		}
		frame `pframe': gen double y`j' = y`=`j' - 1' - `rowgap'
		local ++j
	}
	local n_rows = `j' - 1
	
	
	* Slice distribution into horizontal bins of equal width 
	frame change `dframe'
	sum `coef', meanonly
	local min 	= `r(min)'
	local max 	= `r(max)'
	local width = (`max'-`min')/`bins'
	
	egen bin = cut(`coef'), at(`min'(`width')`max') ico
	replace bin = bin + 1
	replace bin = 1 		if `coef' == `min'
	replace bin = `bins' 	if `coef' >= `max' & !missing(`coef')
	
	sum `xa', meanonly 
	frame change `pframe'
	gen start = `r(min)' in 1
	forvalues i = 1/`bins' {
		gen end`i' = `min' + `i' * `width' in 1
	}
	
	
	* Loop over rows and bins to plot heatmap
	frame change `iframe'
	local s = 0
	local f = 1
	forvalues i = 1/`n_rows' {		// rows
		
		local par = par[`f']
		local val = val[`f']
		
		local temp `i'
		local check: list toskip & temp
		if "`check'" != "" {		// header row
			local ++s
			frame `pframe': local y = y`i'[1]
			frame `dframe': local labnew : var label `par'
			local ymlab_parval `ymlab_parval' `y' `"{bf:`labnew'}"'
		}
		else {						// bins
			forvalues j = `bins'(-1)1 {	
				frame `dframe': qui count if bin == `j'
				local n_all `r(N)'
				if `n_all' != 0 {	// shading
					frame `dframe': qui count if `par' == `val' & bin == `j'
					local share = 100*(`r(N)'/`n_all')
					local share : display %3.2f `share'
				}
				else local share = 0
				
				* Prepare bars
				local bars `bars' (rbar start end`j' y`i' if _n == 1,  ///
					horizontal lc(none) barwidth(`rowgap') fi(`share') ///
					pstyle(p`s'))
			}
			
			* Add ymlabels for parameter values (left)
			frame `pframe': local y = y`i'[1]
			frame `dframe': local lbl_name : 	value label `par'
			if "`lbl_name'" == "" {
				local labnew `par'
			}
			else {
				frame `dframe': local labnew: 		label `lbl_name' `val'	
			}
			local ymlab_parval `ymlab_parval' `y' `"`labnew'"'
			
			* Add ymlabels for influence estimates (right)
			frame `iframe': sum b if par == "`par'" & val == "`val'", meanonly
			if `r(mean)' == 0	local iregval "{it:Ref.}"
			else {
				local iregval 		= `r(mean)'
				local iregval		: display %3.2f `iregval'
				if `iregval' > 0 	local iregval "+`iregval'"
				
				if "`iregnose'" == "" {
					frame `iframe': ///
						sum se if par == "`par'" & val == "`val'", meanonly
					local se 		= `r(mean)'
					local se		: display %3.2f `se'
					local iregval `iregval' (`se')
				}
				if "`iregnostar'" == "" {
					frame `iframe': levelsof stars if par == "`par'" & ///
						val == "`val'", clean local(stars)
					local iregval `iregval'`stars'
				}
			}
			local ymlab_ireg `ymlab_ireg' `y' `"`iregval'"'
			
			local ++f
		}
	}
	
	
	*** PLOTTING *** 
	frame change `pframe'
	
	if "`pangap'" == "" local yinf = 1.5*`rowgap' 
	else 				local yinf = 1.5*`rowgap' + `pangap'
	local ymlab_ireg `ymlab_ireg' -`yinf'  "{bf:Influence}"
	
	#delimit ;
	twoway 

		/* Plot top panel */ 
		`sig_shading'
		(line `ya' `xa', color(black) yaxis(1 2) `kdline')
		
		/* Plot bottom panel */
		`bars'
		
		/* Options */
		, 
		legend(off)
		ytitle("Density", axis(1) just(right) bexpand margin(t=15 r=-5))
		xtitle("Target Coefficient", margin(top))
		
		ylab(0 `yhalf' `ymax', nogrid angle(0) axis(1))	/* Left y-axis */
		yscale(lcolor(black) axis(1))
		ymlab(`ymlab_parval', 	angle(0) axis(1) tlcolor(none))
		
		ylab(`ymax', notick nolab nogrid axis(2))		/* Right y-axis */
		yscale(lcolor(none) axis(2))
		ymlab(`ymlab_ireg', angle(0) axis(2) tlcolor(none))
		
		plotregion(margin(t=0))
		
		`options'
	;
	#delimit cr
	
	* Restore original data
	frame change `dframe'
	restore  
}
end