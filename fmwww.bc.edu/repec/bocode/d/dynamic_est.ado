

*! Meng Ke, allenmeng97@gmail.com, 2024-9-10
*! 1.1 2024.09.10


cap program drop dynamic_est
program define dynamic_est
	
	version 10

    // Adjust the syntax to not require quotes around options
    syntax varlist(min=1 max=1) [if],  /// 
	treat(varlist) time(varlist) ref(integer) [absorb(string)] ///
	[cluster(varlist)] [cov(string)] ///
	[level(string)] [treattype(string)] [figname(string)] ///
	[figtitle(string)] [figsubtitle(string)]  [regtype(string)]
	
	// Assign the first variable in varlist to y and the second to did
    local y : word 1 of `varlist'
    // local treat : word 2 of `varlist'
	
	// default options
	di "------------------------------------------------------------------------------------"
	di "reghdfe required"

	di "Option warning:"
	
	if "`regtype'" == ""{
	    local regtype = "reg"
		di "The option {regtype} was not specified, defaulting to {reg}"
	}
		
	if "`level'" == "" {
	    local level = "95"
		di "The option {level} was not specified, defaulting to {95%}"
	}	
	
	if "`treattype'" == ""{
		// local treattype = "binary"	// binary or intensity
		qui{
		levelsof `treat'
		local levelsoftreat = r(r)
		su `treat'
		if `levelsoftreat' == 2 & r(min) == 0 & r(max) == 1{
			local treattype = "binary"
		}
		if `levelsoftreat' > 2 {
			local treattype = "intensity"
		}
		}
		di "The option {treattype} was not specified, the treat var you entered should be {`treattype'}"
	}
		
	qui{
    // Summarize the year variable to find the range
	cap ren _ty xjsktf29186
    su `time', d
    local s_y = r(min)
    local e_y = r(max)
    local period = `e_y' - `s_y'
    local coef_t ""
	}
	
	qui{
	if `s_y' >=0 {
	    local gap = 0
		di "时间为正数，可直接运行"
	}
	
	if `s_y' < 0{
	    su `time', d
		gen _ty = `time' - r(min) + 1
		local gap = 1 -r(min)
		local time _ty
		local ref = `ref' + `gap'
		su `time', d
		local s_y = r(min)
		local e_y = r(max)
		local period = `e_y' - `s_y'
		local coef_t ""
	}
	}
	
	di "------------------------------------------------------------------------------------"
	qui{
	// Loop through the years to construct the coefficient time variables
	forv i = 1/`period' {
		local j = `i' + `s_y' - 1
		if `j' < `ref' {
			local coef_t "`coef_t' `=`s_y'-1+`i''"
			local coef_k "`coef_k' `=`i'-`gap''"
		}
		if `j' >= `ref' {
			local coef_t "`coef_t' `=`s_y'+`i''"
			local coef_k "`coef_k' `=`i'+1-`gap''"
		}
	}
	}
	// Display the constructed coef_t string for debugging purposes
	// di "`coef_t'"
	
	// binary or intensity?
	
	if "`treattype'" == "binary"{
		// binary
		if `gap' == 0{
	    di "INPUT TIME: natural time {standard-DID}"
		di "INPUT treatment type: binary"
		di "INPUT Y: `y'"
		di "INPUT COV: `cov'"
		di "INPUT absorb: `absorb'"
		di "INPUT Cluster: `cluster'"
		di "method `regtype'hdfe"
		di "------------------------------------------------------------------------------------"
		di ":::::::::RUN:::::::::"
		di "------------------------------------------------------------------------------------"
		
		// Execute the regression with or without cluster & absorb
		if "`cluster'" != ""{
			if "`absorb'" != ""{
				di "TWFE: `regtype'hdfe `y' i1.`treat'#i(`coef_t').`time' `cov' `if', absorb(`absorb') cluster(`cluster')"
				`regtype'hdfe `y' i1.`treat'#i(`coef_t').`time' `cov' `if', absorb(`absorb') cluster(`cluster') level(`level')
			}
			if "`absorb'" == ""{
				di "TWFE: `regtype'hdfe `y' i1.`treat'#i(`coef_t').`time' `cov' `if', noa cluster(`cluster')"
				`regtype'hdfe `y' i1.`treat'#i(`coef_t').`time' `cov' `if', noa cluster(`cluster') level(`level')
			}
		}
		
		if "`cluster'" == ""{
			if "`absorb'" != ""{
				di "TWFE: `regtype'hdfe `y' i1.`treat'#i(`coef_t').`time' `cov' `if', absorb(`absorb') vce(r)"
				`regtype'hdfe `y' i1.`treat'#i(`coef_t').`time' `cov' `if', absorb(`absorb') vce(r) level(`level')
			}
			if "`absorb'" == ""{
				di "TWFE: `regtype'hdfe `y' i1.`treat'#i(`coef_t').`time' `cov' `if', noa vce(r)"
				`regtype'hdfe `y' i1.`treat'#i(`coef_t').`time' `cov' `if', noa cluster(`cluster') level(`level')
			}
		}

	}
	
	if `gap' != 0{
	    di "INPUT TIME: relative time {staggered-DID}"
		di "INPUT treatment type: binary"
		di "INPUT Y: `y'"
		di "INPUT COV: `cov'"
		di "INPUT absorb: `absorb'"
		di "INPUT Cluster: `cluster'"
		di "method `regtype'hdfe"
		di "------------------------------------------------------------------------------------"
		di ":::::::::RUN:::::::::"
		di "------------------------------------------------------------------------------------"
		
		// Execute the regression with or without condition
		if "`cluster'" != ""{
			if "`absorb'" != "" {
				di "TWFE: `regtype'hdfe `y' i1.`treat'#i(`coef_k').`time' `cov' `if', absorb(`absorb') cluster(`cluster')"
				`regtype'hdfe `y' i1.`treat'#i(`coef_t').`time' `cov' `if' , absorb(`absorb') cluster(`cluster') level(`level')
			}
			if "`absorb'" == "" {
				di "TWFE: `regtype'hdfe `y' i1.`treat'#i(`coef_k').`time' `cov' `if', noa cluster(`cluster')"
				`regtype'hdfe `y' i1.`treat'#i(`coef_t').`time' `cov' `if' , noa cluster(`cluster') level(`level')
			}
		}
		if "`cluster'" == ""{
			if "`absorb'" != "" {
				di "TWFE: `regtype'hdfe `y' i1.`treat'#i(`coef_k').`time' `cov' `if', absorb(`absorb') vce(r)"
				`regtype'hdfe `y' i1.`treat'#i(`coef_t').`time' `cov' `if', absorb(`absorb') vce(r) level(`level')
			}
			if "`absorb'" == "" {
				di "TWFE: `regtype'hdfe `y' i1.`treat'#i(`coef_k').`time' `cov' `if', noa vce(r)"
				`regtype'hdfe `y' i1.`treat'#i(`coef_t').`time' `cov' `if' , noa vce(r) level(`level')
			}
		}
	}
	}
	
	if "`treattype'" == "intensity"{
		// intensity
		if `gap' == 0{
	    di "INPUT TIME: natural time {standard-DID}"
		di "INPUT treatment type: intensity"
		di "INPUT Y: `y'"
		di "INPUT COV: `cov'"
		di "INPUT absorb: `absorb'"
		di "INPUT Cluster: `cluster'"
		di "method `regtype'hdfe"
		di "------------------------------------------------------------------------------------"
		di ":::::::::RUN:::::::::"
		di "------------------------------------------------------------------------------------"
		
		// Execute the regression with or without condition
		if "`cluster'" != ""{
			if "`absorb'" != ""{
				di "TWFE: `regtype'hdfe `y' c.`treat'#i(`coef_t').`time' `cov' `if' , absorb(`absorb') cluster(`cluster')"
				`regtype'hdfe `y' c.`treat'#i(`coef_t').`time' `cov' `if' , absorb(`absorb') cluster(`cluster') level(`level')
			}
			if "`absorb'" == ""{
				di "TWFE: `regtype'hdfe `y' c.`treat'#i(`coef_t').`time' `cov' `if' , noa cluster(`cluster')"
				`regtype'hdfe `y' c.`treat'#i(`coef_t').`time' `cov' `if' , noa cluster(`cluster') level(`level')
			}
		}
		if "`cluster'" == ""{
			if "`absorb'" != ""{
				di "TWFE: `regtype'hdfe `y' c.`treat'#i(`coef_t').`time' `cov' `if' , absorb(`absorb') vce(r)"
				`regtype'hdfe `y' c.`treat'#i(`coef_t').`time' `cov' `if' , absorb(`absorb') vce(r) level(`level')
			}
			if "`absorb'" == ""{
				di "TWFE: `regtype'hdfe `y' c.`treat'#i(`coef_t').`time' `cov' `if' , noa vce(r)"
				`regtype'hdfe `y' c.`treat'#i(`coef_t').`time' `cov' `if' , noa vce(r) level(`level')
			}
		}
	}
	
	if `gap' != 0{
	    di "INPUT TIME: relative time {staggered-DID}"
		di "INPUT treatment type: intensity"
		di "INPUT Y: `y'"
		di "INPUT COV: `cov'"
		di "INPUT absorb: `absorb'"
		di "INPUT Cluster: `cluster'"
		di "method `regtype'hdfe"
		di "------------------------------------------------------------------------------------"
		di ":::::::::RUN:::::::::"
		di "------------------------------------------------------------------------------------"
		
		// Execute the regression with or without condition
		if "`cluster'" != ""{
			if "`absorb'" != ""{
				di "TWFE: `regtype'hdfe `y' c.`treat'#i(`coef_k').`time' `cov' `if', absorb(`absorb') cluster(`cluster')"
				`regtype'hdfe `y' c.`treat'#i(`coef_t').`time' `cov' `if' , absorb(`absorb') cluster(`cluster') level(`level')
			}
			if "`absorb'" == ""{
				di "TWFE: `regtype'hdfe `y' c.`treat'#i(`coef_k').`time' `cov' `if', noa cluster(`cluster')"
				`regtype'hdfe `y' c.`treat'#i(`coef_t').`time' `cov' `if' , noa cluster(`cluster') level(`level')
			}
		}
		if "`cluster'" == ""{
			if "`absorb'" != ""{
				di "TWFE: `regtype'hdfe `y' c.`treat'#i(`coef_k').`time' `cov' `if', absorb(`absorb') vce(r)"
				`regtype'hdfe `y' c.`treat'#i(`coef_t').`time' `cov' `if' , absorb(`absorb') vce(r) level(`level')
			}
			if "`absorb'" == ""{
				di "TWFE: `regtype'hdfe `y' c.`treat'#i(`coef_k').`time' `cov' `if', noa vce(r)"
				`regtype'hdfe `y' c.`treat'#i(`coef_t').`time' `cov' `if' , noa vce(r) level(`level')
			}
		}
	}
	}
	
	cap{
	mat N = e(N)
	local obs =  N[1,1]
	}
	
	// ↓↓↓↓↓ fig ↓↓↓↓↓ 
	if "`treattype'" == "intensity"{
	local length = `period' + 1
	mat M = J(`length',5,.)
	if "`level'" == "90"{
		forv i = `s_y' / `e_y'{
			local row = `i' - `s_y' + 1
			cap mat M[`row',1] = _b[c.`treat'#`i'.`time']
			cap mat M[`row',2] = _se[c.`treat'#`i'.`time']
			cap mat M[`row',3] = _b[c.`treat'#`i'.`time'] + 1.96 * _se[c.`treat'#`i'.`time']
			cap mat M[`row',4] = _b[c.`treat'#`i'.`time'] - 1.96 * _se[c.`treat'#`i'.`time']
			cap mat M[`row',5] = `i'
		}
	}
	if "`level'" == "95"{
		forv i = `s_y' / `e_y'{
			local row = `i' - `s_y' + 1
			cap mat M[`row',1] = _b[c.`treat'#`i'.`time']
			cap mat M[`row',2] = _se[c.`treat'#`i'.`time']
			cap mat M[`row',3] = _b[c.`treat'#`i'.`time'] + 2.33 * _se[c.`treat'#`i'.`time']
			cap mat M[`row',4] = _b[c.`treat'#`i'.`time'] - 2.33 * _se[c.`treat'#`i'.`time']
			cap mat M[`row',5] = `i'
		}
	}
	if "`level'" == "99"{
		forv i = `s_y' / `e_y'{
			local row = `i' - `s_y' + 1
			cap mat M[`row',1] = _b[c.`treat'#`i'.`time']
			cap mat M[`row',2] = _se[c.`treat'#`i'.`time']
			cap mat M[`row',3] = _b[c.`treat'#`i'.`time'] + 2.58 * _se[c.`treat'#`i'.`time']
			cap mat M[`row',4] = _b[c.`treat'#`i'.`time'] - 2.58 * _se[c.`treat'#`i'.`time']
			cap mat M[`row',5] = `i'
		}
	}
	}
	
	if "`treattype'" == "binary"{
	local length = `period' + 1
	mat M = J(`length',5,.)
	if "`level'" == "90"{
		forv i = `s_y' / `e_y'{
			local row = `i' - `s_y' + 1
			cap mat M[`row',1] = _b[1.`treat'#`i'.`time']
			cap mat M[`row',2] = _se[1.`treat'#`i'.`time']
			cap mat M[`row',3] = _b[1.`treat'#`i'.`time'] + 1.96 * _se[1.`treat'#`i'.`time']
			cap mat M[`row',4] = _b[1.`treat'#`i'.`time'] - 1.96 * _se[1.`treat'#`i'.`time']
			cap mat M[`row',5] = `i'
		}
	}
	if "`level'" == "95"{
		forv i = `s_y' / `e_y'{
			local row = `i' - `s_y' + 1
			cap mat M[`row',1] = _b[1.`treat'#`i'.`time']
			cap mat M[`row',2] = _se[1.`treat'#`i'.`time']
			cap mat M[`row',3] = _b[1.`treat'#`i'.`time'] + 2.33 * _se[1.`treat'#`i'.`time']
			cap mat M[`row',4] = _b[1.`treat'#`i'.`time'] - 2.33 * _se[1.`treat'#`i'.`time']
			cap mat M[`row',5] = `i'
		}
	}
	if "`level'" == "99"{
		forv i = `s_y' / `e_y'{
			local row = `i' - `s_y' + 1
			cap mat M[`row',1] = _b[1.`treat'#`i'.`time']
			cap mat M[`row',2] = _se[1.`treat'#`i'.`time']
			cap mat M[`row',3] = _b[1.`treat'#`i'.`time'] + 2.58 * _se[1.`treat'#`i'.`time']
			cap mat M[`row',4] = _b[1.`treat'#`i'.`time'] - 2.58 * _se[1.`treat'#`i'.`time']
			cap mat M[`row',5] = `i'
		}
	}
	}
	
	qui{
	preserve
		clear
		svmat M
		replace M1 = 0 if M5 == `ref'
		format M1 %9.2f
		format M2 %9.2f
		
		gen se = "(0" + string(round(M2,0.001))  + ")"
		replace se = "." if strmatch(se,"*.*") == 0
		replace se = "." if strmatch(se,"(0.)") == 1
		forv i = 1/9{
			replace se = regexr(se, "\(0([`i'])\.", "(`i'.")
		}
		
		gen coef = string(abs(round(M1,0.01)))
		replace coef = "0"+coef if strmatch(coef,".*") & M1 >=0 
		replace coef = "-"+coef if strmatch(coef,".*")==0 & M1 <0 
		replace coef = "-0"+coef if strmatch(coef,".*") & M1 <0
		replace coef ="" if M5 == `ref'
		
		gen sig_se = subinstr(se,"(","",.)
		replace sig_se = subinstr(sig_se,")","",.)
		destring sig_se,replace force
		replace sig_se = M1/M2
		replace se= "" if M5 == `ref'
			
		gen sig = "***" if abs(sig_se) > 2.58 & sig_se!=.
		replace sig = "**" if abs(sig_se) <= 2.58 & abs(sig_se) > 2.33 
		replace sig = "*" if abs(sig_se) <= 2.33 & abs(sig_se) > 1.96
		
		gen coef_sig = coef + sig
		
		if `gap' == 0{
			tw (rcap M3 M4 M5, lp(solid) lc(gs4)) /// 
			   (connect M1 M5 if M5 <=`ref', ms(o) mc(gs6) mlab(coef_sig) mlabp(1) lp(solid)) /// 
			   (connect M1 M5 if M5 >=`ref', ms(o) lc(gs6) mlab(coef_sig) mlabp(11) lp(solid)) /// 
			   (scatter M1 M5 if M5 <=`ref', ms(i) mlab(se) mlabp(5)) /// 
			   (scatter M1 M5 if M5 >= `ref', ms(i) mlab(se) mlabp(7)) /// 
			   , scheme(s1mono) legend(off) /// 
			   xline(`=`ref'+0.5' ,lp(shortdash)) /// 
			   yline(0,lp(shortdash)) xtitle("time") /// 
			   ytitle("coef. and `level'% CI") /// 
			   name("`figname'",replace) /// 
			   subtitle("`figsubtitle'") /// 
			   title("`figtitle'") note("observations: `obs'")
		}
		
		if `gap' != 0{
		replace M5 = M5 - `gap'
		local ref = `ref' - `gap'
		tw (rcap M3 M4 M5, lp(solid) lc(gs4)) /// 
		   (connect M1 M5 if M5 <=`ref', ms(o) mc(gs6) mlab(coef_sig) mlabp(1) lp(solid)) /// 
		   (connect M1 M5 if M5 >=`ref', ms(o) lc(gs6) mlab(coef_sig) mlabp(11) lp(solid)) /// 
		   (scatter M1 M5 if M5 <=`ref', ms(i) mlab(se) mlabp(5)) /// 
		   (scatter M1 M5 if M5 >= `ref', ms(i) mlab(se) mlabp(7)) /// 
		   , scheme(s1mono) legend(off) /// 
		   xline(`=`ref'+0.5' ,lp(shortdash)) /// 
		   yline(0,lp(shortdash)) xtitle("time") /// 
		   ytitle("coef. and `level'% CI") /// 
		   name("`figname'",replace) /// 
		   subtitle("`figsubtitle'") /// 
		   title("`figtitle'") note("observations: `obs'")
		}
	restore
	
	cap drop _ty
	cap ren xjsktf29186 _ty 
	}
	
end