*! 1.0 Thierry.Buclin 23 November 2024
program define predperf, rclass sortpreserve byable(recall) 
		*** This program computes classical predictive performance descriptors resulting from
		*** the comparison of one or two predictors (A and B) with corresponding "true" observations (Y).
		*** It is directly inspired from: 
		*** Sheiner LB, Beal SL. Some suggestions for measuring predictive performance. 
		*** J Pharmacokinet Biopharm. 1981;9(4):503-12. DOI: 10.1007/BF01060893
		*** Code by Thierry Buclin, Clinical Pharmacology Service, Lausanne University Hospital, 2024 
		*** E-mail: thierry.buclin(at)chuv.ch
		*** Version 1.0

*** INITIALIZATION ***
	version 18
	syntax varlist(min=2 max=3 numeric) [if] [in] [aweight fweight /], [LEvel(cilevel) DF(string) SIg MEtrics(integer 0) REl LOg FLoor(real 0) NOgraph *]

	if `metrics' == 0 & "`rel'" == "" &  "`log'" == "" {
		local metrics = 1
		local q = "ME"
		local r = "RMSE"
		local s = "  "
		local v = "SD"
	}
	else if `metrics' == 1 {
		if "`rel'" != "" {
			display as error "Warning: the {it:rel} option will be ignored as the {it:metrics} option is set to 1"
		}
		if "`log'" != "" {
			display as error "Warning: the {it:log} option will be ignored as the {it:metrics} option is set to 1"
		}
		local metrics = 1
		local q = "ME"
		local r = "RMSE"
		local s = "  " 
		local v = "SD"
	}
	else if `metrics' == 2 | ("`rel'" == "rel" & `metrics' == 0) {
		if "`log'" != "" {
			display as error "Warning: the {it:log} option will be ignored as the {it:metrics} option is set to 2 (i.e. {it:rel} option)"
		}
		local metrics = 2
		local q = "MPE"
		local r = "RMSPE"
		local s = " " 
		local v = "SDP"
	}
	else if `metrics' == 3 | ("`log'" == "log" & `metrics' == 0) {
		if "`rel'" != "" {
			display as error "Warning: the {it:rel} option will be ignored as the {it:metrics} option is set to 3  (i.e. {it:log} option)"
		}
		local metrics = 3
		local q = "MLE"
		local r = "RMSLE"
		local s = " " 
		local v = "SDL"
	}
	else {
		display as error "Warning: the {it:metrics} option cannot take the value of `metrics' and will be set to 1"
		local metrics = 1
		local q = "ME"
		local r = "RMSE"
		local s = "  "
	}
	local nvar : word count `varlist'
		*** number of variables. i.e. 2 or 3

	tokenize `varlist'
	args y a b
		*** y = observed true values Y
		*** a = values of predictor A
		*** b = values of predictor B (optional)
	local ndf = 0
		*** number of df values
	local df1 = 0
	local df2 = 0
		*** degrees of freedom
	if "`df'" != "" {
		local ndf : word count `df'
		if `ndf' > 2 {
			display as error "Too many arguments defined in option df()"
			error 198
		}
		if `ndf' == 2 & `nvar' == 2 {
			display as error "Only one value of df() needs to be defined"
			error 198
		}
		if `ndf' == 1 & `nvar' == 3 {
			display as error "Two values of df() need to be defined"
			error 198
		}
		local df1 : word 1 of `df'
		if `df1' < 0 | `df1' != floor(`df1') {
			display as error "The option df() only admits zero or positive integers"
			error 198
		}
		if `ndf' == 2 {
			local df2 : word 2 of `df'
			if `df2' < 0 | `df2' != floor(`df2') {
				display as error "The option df() only admits zero or positive integers"
				error 198
			}
		}
	}
	local dfmax = max(`df1', `df2')
	*** highest value for degree of freedom
	if "`level'" == "" {
		local level = c(level)
	}

	marksample touse
	quietly count 
	local n0 = r(N)
		*** total number of lines in the dataset
	quietly count if `touse' 
	local n = r(N)
		*** number of lines devoid from missing values

*** PRELIMINARY CHECKS ***
	if `n' == 0 {
		display as error "No data to compute predictive performance descriptors"
		error 2000 
	}
	if `n' <= `dfmax' + 1 {
		display as error "Insufficient data to compute predictive performance descriptors with a df of `dfmax' "
		error 2001 
	}

	quietly summarize `y' if `touse' 
	if `metrics' == 3 & r(min) + `floor'<= 0 {
		if `floor' == 0 {
			display as error "Logarithmic performance indices cannot be calculated with nonpositive values of `y'"
			display as error "(unless the {it:floor} option is used to correct for nonpositive `y' values)"
			}
		else {
			display as error "Logarithmic performance indices cannot be calculated as some negative values of `y'"
			display as error "are not corrected by the {it:floor} value of `floor'"
		}
		error 411
	}
	quietly summarize `a' if `touse' 
	if `metrics' == 3 & r(min) + `floor'<= 0 {
		if `floor' == 0 {
			display as error "Logarithmic performance indices cannot be calculated with nonpositive values of `a'"
			display as error "(unless the {it:floor} option is used to correct for nonpositive `a' values)"
			}
		else {
			display as error "Logarithmic performance indices cannot be calculated as some negative values of `a'"
			display as error "are not compensated by the {it:floor} value of `floor'"
		}
		error 411
	}
	if `nvar' == 3 & `metrics' == 3 {
		quietly summarize `b' if `touse' 
		if r(min) + `floor' <= 0 {
			if `floor' == 0 {
				display as error "Logarithmic performance indices cannot be calculated with nonpositive values of `b'"
				display as error "(unless the {it:floor} option is used to correct for nonpositive `b' values)"
				}
			else {
				display as error "Logarithmic performance indices cannot be calculated as some negative values of `b'"
				display as error "are not compensated by the {it:floor} value of `floor'"
			}
		error 411
		}
	}
	if `floor' != 0 & `metrics' != 3 {
		display as error "Warning: the {it:floor} option is not used unless the {it:log} option is active or the {it:metrics} option is set to 3"
	}

	tempvar w
	quietly generate `w' = `touse'
	local nw = `n'
		*** Sum of weights
	local wscheme = " "
	if "`weight'" != "" {
		local wscheme = "[`weight' = `w']"
		*** weighting option in calculations and graphs
		quietly replace `w' = `exp' * `touse'
		quietly summarize `w'
		local nw = r(sum)
		if "`weight'" == "aweight" {
			quietly replace `w' = `w' * `n' / `nw'
			local nw = `n'
			*** If weights are aweights, they are renormalized so that their sum becomes = n
		}
		else if "`weight'" == "fweight" {
			local n = `nw'
			*** if weights are fweights, data are considered replicates and n is adjusted accordingly
		}
	}

*** COMPUTATION ***
	tempvar e02 ea ea2 ea02 eb eb2 eb02 eab eab2
	*** e02 = squared errors between y and the naive predictor mean(y) or geom.mean(y)  
	*** ea  = errors between y and a
	*** ea2 = squared errors between y and a
	*** ea02 = differences between e02 and ea2 
	quietly ameans `y' `wscheme' if `touse' 
	if `metrics' == 1 {
		local my = r(mean)
		quietly generate `e02' = (`y' - `my')^2
		quietly generate `ea' = (`a' - `y')
		}
	else if `metrics' == 2  {
		local my = r(mean)
		quietly generate `e02' = (`y' - `my')^2 / `y'^2
		quietly generate `ea' = (`a' - `y') / `y'
	}
	else if `metrics' == 3  {
		local my = r(mean_g)
		quietly generate `e02' = (log(`y' + `floor') - log(`my' + `floor'))^2
		quietly generate `ea' = (log(`a' + `floor') - log(`y' + `floor'))
	}
	quietly generate `ea2' = `ea'^2
	quietly generate `ea02' = `e02' - `ea2'
	quietly summarize `ea' `wscheme' if `touse' 
	local mea = r(mean)
	local mease = r(sd)/sqrt(`n')
	quietly summarize `ea2' `wscheme' if `touse' 
	local msea = r(mean)*`n'/(`n' - `df1')
	local msease = r(sd)/sqrt(`n')
	quietly summarize `ea02' `wscheme' if `touse' 
	local msea0 = r(mean)*`n'/(`n' - `df1')
	local msea0se = r(sd)/sqrt(`n')

	if `nvar' == 3 {
		*** eb   = errors between y and b
		*** eb2  = squared errors between y and b
		*** eb02 = differences between e02 and eb2 
		*** eab  = differences between ea and eb
		*** eab2 = differences between ea2 and eb2 
		if `metrics' == 1 { 
			quietly generate `eb' = (`b' - `y')
			quietly generate `eab' = (`b' - `a')
		}
		else if `metrics' == 2 {
			quietly generate `eb' = (`b' - `y') / `y'
			quietly generate `eab' = (`b' - `a') / `y'
		}
		else if `metrics' == 3 {
			quietly generate `eb' = (log(`b' + `floor') - log(`y' + `floor'))
			quietly generate `eab' = (log(`b' + `floor') - log(`a' + `floor'))
		}
		quietly generate `eb2' = `eb'^2
		quietly generate `eb02' = `e02' - `eb2'
		quietly generate `eab2' = `eb2' - `ea2'
		quietly summarize `eb' `wscheme' if `touse' 
		local meb = r(mean)
		local mebse = r(sd)/sqrt(`n') 
		quietly summarize `eb2' `wscheme' if `touse' 
		local mseb = r(mean)*`n'/(`n' - `df2')
		local msebse = r(sd)/sqrt(`n')
		quietly summarize `eb02' `wscheme' if `touse' 
		local mseb0 = r(mean)*`n'/(`n' - `df2')
		local mseb0se = r(sd)/sqrt(`n')
		quietly summarize `eab' `wscheme' if `touse' 
		local meab = r(mean)
		local meabse = r(sd)/sqrt(`n')
		quietly summarize `eab2' `wscheme' if `touse' 
		local mseab = r(mean)*`n'/(`n' - `dfmax')
		local mseabse = r(sd)/sqrt(`n')
	}

*** STORAGE OF RESULTS ***
	return scalar N = `n'
	return scalar level = `level'
	return scalar df_1 = `df1'
	if `metrics' <= 2 {
		return scalar me_1 = `mea'
		return scalar me_lb_1 = `mea' - invnt(`n' - 1, 0, 0.5 + `level'/200)*`mease'
		return scalar me_ub_1 = `mea' + invnt(`n' - 1, 0, 0.5 + `level'/200)*`mease'
	}
	else if `metrics' == 3 {
		return scalar me_1 = exp(`mea')
		return scalar me_lb_1 = exp(`mea' - invnt(`n' - 1, 0, 0.5 + `level'/200)*`mease')
		return scalar me_ub_1 = exp(`mea' + invnt(`n' - 1, 0, 0.5 + `level'/200)*`mease')
	}
	return scalar p_me_1 =  2*ttail(`n' - 1, abs(`mea'/`mease'))
	return scalar rmse_1 = sqrt(`msea')
	return scalar rmse_lb_1 = sqrt(`msea' - invnt(`n' - 1, 0, 0.5 + `level'/200)*`msease')
	return scalar rmse_ub_1 = sqrt(`msea' + invnt(`n' - 1, 0, 0.5 + `level'/200)*`msease')
	return scalar p_rmse_1 = 2*ttail(`n' - 1, abs(`msea0'/`msea0se'))

	if `nvar' == 3 {
		return scalar df_2 = `df2'
		if `metrics' <= 2 {
			return scalar me_2 = `meb'
			return scalar me_lb_2 = `meb' - invnt(`n' - 1, 0, 0.5 + `level'/200)*`mebse'
			return scalar me_ub_2 = `meb' + invnt(`n' - 1, 0, 0.5 + `level'/200)*`mebse'
		}
		else if `metrics' == 3 {
			return scalar me_2 = exp(`meb')
			return scalar me_lb_2 = exp(`meb' - invnt(`n' - 1, 0, 0.5 + `level'/200)*`mebse')
			return scalar me_ub_2 = exp(`meb' + invnt(`n' - 1, 0, 0.5 + `level'/200)*`mebse')
		}
		return scalar p_me_2 =  2*ttail(`n' - 1, abs(`meb'/`mebse'))
		return scalar rmse_2 = sqrt(`mseb')
		return scalar rmse_lb_2 = sqrt(`mseb' - invnt(`n' - 1, 0, 0.5 + `level'/200)*`msebse')
		return scalar rmse_ub_2 = sqrt(`mseb' + invnt(`n' - 1, 0, 0.5 + `level'/200)*`msebse')
		return scalar p_rmse_2 = 2*ttail(`n' - 1, abs(`mseb0'/`mseb0se'))
		if `metrics' <= 2 {
			return scalar me_12 = `meab'
			return scalar me_lb_12 = `meab' - invnt(`n' - 1, 0, 0.5 + `level'/200)*`meabse'
			return scalar me_ub_12 = `meab' + invnt(`n' - 1, 0, 0.5 + `level'/200)*`meabse'
		}
		else if `metrics' == 3 {
			return scalar me_12 = exp(`meab')
			return scalar me_lb_12 = exp(`meab' - invnt(`n' - 1, 0, 0.5 + `level'/200)*`meabse')
			return scalar me_ub_12 = exp(`meab' + invnt(`n' - 1, 0, 0.5 + `level'/200)*`meabse')
		}
		return scalar p_me_12 = 2*ttail(`n' - 1, abs(`meab'/`meabse'))
		return scalar rmse_12 = sign(`mseab')*sqrt(abs(`mseab'))
		return scalar rmse_lb_12 = sign(`mseab' - invnt(`n' - 1, 0, 0.5 + `level'/200)*`mseabse')*sqrt(abs(`mseab' - invnt(`n' - 1, 0, 0.5 + `level'/200)*`mseabse'))
		return scalar rmse_ub_12 = sign(`mseab' + invnt(`n' - 1, 0, 0.5 + `level'/200)*`mseabse')*sqrt(abs(`mseab' + invnt(`n' - 1, 0, 0.5 + `level'/200)*`mseabse'))
		return scalar p_rmse_12 = 2*ttail(`n' - 1, abs(`mseab'/`mseabse'))
	}

*** DISPLAY OF RESULTS ***
	display
	if `metrics' == 1 {
		display in smcl as text "Absolute predictive performance for the prediction of {bf:`y'}"
		display in smcl as text "(`q' = bias = mean difference, `r' = imprecision, both in units of `y')"
	}
	else if `metrics' == 2 {
		display in smcl as text "Relative predictive performance for the prediction of {bf:`y'}"
		display in smcl as text "(`q' = relative bias, `r' = relative imprecision, both in percentage ratio)"
	}	
	else if `metrics' == 3 {
		display in smcl as text "Relative predictive performance for the prediction of {bf:`y'}"
		display in smcl as text "(`q' = relative bias = geometric mean ratio, and `r' = relative imprecision)"
	}
	if `dfmax' != 0 {
		display in smcl as text "(RMSE is corrected by `df' degrees of freedom)"
	}
	display
	display in smcl as text "   Predictor {c |}      `s'`q'  [`level'% conf. interval] {c |}     `s'`r'  [`level'% conf. interval]"
	display "{hline 13}{c +}{hline 33}{c +}{hline 32}" 
	display as text %12s abbrev("`a'",12) " {c |} " /*
		*/  as result %9.0g return(me_1) "  " %9.0g return(me_lb_1) "  " %9.0g return(me_ub_1) " {c |} " /*
		*/  as result %9.0g return(rmse_1) "  " %9.0g return(rmse_lb_1) "  " %9.0g return(rmse_ub_1) 
	if "`sig'" != "" {
		display as text "             {c |}          `s'P(|`q'|>0) = " as result %6.4f return(p_me_1) /* 
		*/	as text "   {c |}   `s'P(|`v' - `r'|>0) = " as result %6.4f return(p_rmse_1)
	}
	
	if `nvar' == 3 {
		display as text %12s abbrev("`b'",12) " {c |} " /*
		*/  as result %9.0g return(me_2) "  " %9.0g return(me_lb_2) "  " %9.0g return(me_ub_2) " {c |} " /*
		*/  as result %9.0g return(rmse_2) "  " %9.0g return(rmse_lb_2) "  " %9.0g return(rmse_ub_2) 
		if "`sig'" != "" {
			display as text "             {c |}          `s'P(|`q'|>0) = " as result %6.4f return(p_me_2) /* 
			*/	as text "   {c |}   `s'P(|`v' - `r'|>0) = " as result %6.4f return(p_rmse_2)
		}
		display "{hline 13}{c +}{hline 33}{c +}{hline 32}" 
		if `metrics' <= 2 {
			display as text %12s "  difference {c |} " /*
			*/  as result %9.0g return(me_12) "  " %9.0g return(me_lb_12) "  " %9.0g return(me_ub_12) " {c |} " /*
			*/  as result %9.0g return(rmse_12) "  " %9.0g return(rmse_lb_12) "  " %9.0g return(rmse_ub_12)
		}
		else {
			display as text %12s "ratio | diff {c |} " /*
			*/  as result %9.0g return(me_12) "  " %9.0g return(me_lb_12) "  " %9.0g return(me_ub_12) " {c |} " /*
			*/  as result %9.0g return(rmse_12) "  " %9.0g return(rmse_lb_12) "  " %9.0g return(rmse_ub_12)
		}
		if "`sig'" != "" {
			display as text "             {c |}       `s'P(|`q' diff|) = " as result %6.4f return(p_me_12) /* 
			*/	as text "   {c |}       P(|`r' diff|) = " as result %6.4f return(p_rmse_12)
		}
	}
	
	display	
	if `metrics' == 3 {
		if `nvar' <= 2 {
			display in smcl as text "(Note: no bias <=> `q'=1)"
		}
		else {
			display in smcl as text "(Note: no bias <=> `q'=1; difference of bias is expressed as ratio of MLE)"
		}
	}
	if `n' == `n0' {
		display as text "Number of observations: {bf:`n'}"
	}
	else {
		display as text "Number of observations included: {bf:`n'} (out of `n0' lines in datafile)"
	}

*** GRAPH ***
	quietly summarize `y'
	local top = r(max)
	local bottom = r(min)
	*** lowest and highest values among y, a and b
	quietly summarize `a'
	local top = max(`top', r(max))
	local bottom = min(`bottom', r(min))
	if `nvar' == 3 {
		quietly summarize `b'
		local top = max(`top', r(max))
		local bottom = min(`bottom', r(min))
	}
	if `metrics' == 3 {
		local bottom = max(`bottom', `floor')
	}
	graph drop _all
	set graphics off

	if `nvar' >= 2 {
		if `metrics' == 1 {
			local m	= return(me_1)
			local r1 = return(rmse_1)
			local r2 = 2*return(rmse_1)
			local bm = `bottom' + max(0, `m')
			local b0 = `bottom'
			local b1 = `bottom' + `r1'
			local b2 = `bottom' + `r2'
			local tm = `top' + min(0, `m')
			local t0 = `top'
			local t1 = `top' - `r1'
			local t2 = `top' - `r2'
			*** coefficients and extremities for lines added over the scatterplot
			twoway (scatter `y' `a' `wscheme') /*
			*/ (function y = x - `m', range(`bm' `tm') lpattern(solid) color(stc2)) /*
			*/ (function y = x, range(`b0' `t0') lpattern(longdash) color(stc3)) /*
			*/ (function y = x + `r1', range(`b0' `t1') lpattern(dash) color(stc3)) /*
			*/ (function y = x - `r1', range(`b1' `t0') lpattern(dash) color(stc3)) /*
			*/ (function y = x + `r2', range(`b0' `t2') lpattern(shortdash) color(stc3)) /*
			*/ (function y = x - `r2', range(`b2' `t0') lpattern(shortdash) color(stc3)) /*
			*/ if `touse' , aspect(1) xscale(range(`r0' `t0')) yscale(range(`r0' `t0')) /*
			*/   xtitle("Predictions: `a'") ytitle("Observations: `y'") legend(off) name(grapha)
		}
		if `metrics' == 2 {
			local m	= return(me_1)
			local r1 = return(rmse_1)
			local r2 = 2*return(rmse_1)
			local bm = `bottom' * (1 + max(0, `m'))
			local b0 = `bottom'
			local b1 = `bottom' * (1 + `r1')
			local b2 = `bottom' * (1 + `r2')
			local tm = `top' / (1 - min(0, `m'))
			local t0 = `top'
			local t1 = `top' / (1 + `r1')
			local t2 = `top' / (1 + `r2')
			twoway (scatter `y' `a' `wscheme') /*
			*/ (function y = x * (1 - `m'), range(`bm' `tm') lpattern(solid) color(stc2)) /*
			*/ (function y = x, range(`b0' `t0') lpattern(longdash) color(stc3)) /*
			*/ (function y = x * (1 + `r1'), range(`b0' `t1') lpattern(dash) color(stc3)) /*
			*/ (function y = x / (1 + `r1'), range(`b1' `t0') lpattern(dash) color(stc3)) /*
			*/ (function y = x * (1 + `r2'), range(`b0' `t2') lpattern(shortdash) color(stc3)) /*
			*/ (function y = x / (1 + `r2'), range(`b2' `t0') lpattern(shortdash) color(stc3)) /*
			*/ if `touse' , aspect(1) xscale(range(`r0' `t0')) yscale(range(`r0' `t0')) /*
			*/   xtitle("Predictions: `a'") ytitle("Observations: `y'") legend(off) name(grapha)
		}
			if `metrics' == 3 {
			local m	= return(me_1)
			local r1 = return(rmse_1)
			local r2 = 2*return(rmse_1)
			local b0 = `bottom'
			local bm = `bottom' * max(1, `m')
			local b1 = `bottom' * exp(`r1')
			local b2 = `bottom' * exp(`r2')
			local tm = `top' * min(1, `m')
			local t0 = `top'
			local t1 = `top' / exp(`r1')
			local t2 = `top' / exp(`r2')
			twoway (scatter `y' `a' `wscheme') /*
			*/ (function y = x / `m', range(`bm' `tm') lpattern(solid) color(stc2)) /*
			*/ (function y = x, range(`b0' `t0') lpattern(longdash) color(stc3)) /*
			*/ (function y = x * exp(`r1'), range(`b0' `t1') lpattern(dash) color(stc3)) /*
			*/ (function y = x / exp(`r1'), range(`b1' `t0') lpattern(dash) color(stc3)) /*
			*/ (function y = x * exp(`r2'), range(`b0' `t2') lpattern(shortdash) color(stc3)) /*
			*/ (function y = x / exp(`r2'), range(`b2' `t0') lpattern(shortdash) color(stc3)) /*
			*/ if `touse' , aspect(1) xscale(log range(`r0' `t0')) yscale(log range(`r0' `t0')) /*
			*/   xtitle("Predictions: `a'") ytitle("Observations: `y'") legend(off) name(grapha)
		}
	}

	if `nvar' == 3 {
		if `metrics' == 1 {
			local m	= return(me_2)
			local r1 = return(rmse_2)
			local r2 = 2*return(rmse_2)
			local bm = `bottom' + max(0, `m')
			local b0 = `bottom'
			local b1 = `bottom' + `r1'
			local b2 = `bottom' + `r2'
			local tm = `top' + min(0, `m')
			local t0 = `top'
			local t1 = `top' - `r1'
			local t2 = `top' - `r2'
			twoway (scatter `y' `b' `wscheme') /*
			*/ (function y = x - `m', range(`bm' `tm') lpattern(solid) color(stc2)) /*
			*/ (function y = x, range(`b0' `t0') lpattern(longdash) color(stc3)) /*
			*/ (function y = x + `r1', range(`b0' `t1') lpattern(dash) color(stc3)) /*
			*/ (function y = x - `r1', range(`b1' `t0') lpattern(dash) color(stc3)) /*
			*/ (function y = x + `r2', range(`b0' `t2') lpattern(shortdash) color(stc3)) /*
			*/ (function y = x - `r2', range(`b2' `t0') lpattern(shortdash) color(stc3)) /*
			*/ if `touse' , aspect(1) xscale(range(`r0' `t0')) yscale(range(`r0' `t0')) /*
			*/   xtitle("Predictions: `b'") ytitle("Observations: `y'") legend(off) name(graphb)
		}
		if `metrics' == 2 {
			local m	= return(me_2)
			local r1 = return(rmse_2)
			local r2 = 2*return(rmse_2)
			local bm = `bottom' * (1 + max(0, `m'))
			local b0 = `bottom'
			local b1 = `bottom' * (1 + `r1')
			local b2 = `bottom' * (1 + `r2')
			local tm = `top' / (1 - min(0, `m'))
			local t0 = `top'
			local t1 = `top' / (1 + `r1')
			local t2 = `top' / (1 + `r2')
			twoway (scatter `y' `b'  `wscheme') /*
			*/ (function y = x * (1 - `m'), range(`bm' `tm') lpattern(solid) color(stc2)) /*
			*/ (function y = x, range(`b0' `t0') lpattern(longdash) color(stc3)) /*
			*/ (function y = x * (1 + `r1'), range(`b0' `t1') lpattern(dash) color(stc3)) /*
			*/ (function y = x / (1 + `r1'), range(`b1' `t0') lpattern(dash) color(stc3)) /*
			*/ (function y = x * (1 + `r2'), range(`b0' `t2') lpattern(shortdash) color(stc3)) /*
			*/ (function y = x / (1 + `r2'), range(`b2' `t0') lpattern(shortdash) color(stc3)) /*
			*/ if `touse' , aspect(1) xscale(range(`r0' `t0')) yscale(range(`r0' `t0')) /*
			*/   xtitle("Predictions: `b'") ytitle("Observations: `y'") legend(off) name(graphb)
		}
			if `metrics' == 3 {
			local m	= return(me_2)
			local r1 = return(rmse_2)
			local r2 = 2*return(rmse_2)
			local b0 = `bottom'
			local bm = `bottom' * max(1, `m')
			local b1 = `bottom' * exp(`r1')
			local b2 = `bottom' * exp(`r2')
			local tm = `top' * min(1, `m')
			local t0 = `top'
			local t1 = `top' / exp(`r1')
			local t2 = `top' / exp(`r2')
			twoway (scatter `y' `b' `wscheme') /*
			*/ (function y = x / `m', range(`bm' `tm') lpattern(solid) color(stc2)) /*
			*/ (function y = x, range(`b0' `t0') lpattern(longdash) color(stc3)) /*
			*/ (function y = x * exp(`r1'), range(`b0' `t1') lpattern(dash) color(stc3)) /*
			*/ (function y = x / exp(`r1'), range(`b1' `t0') lpattern(dash) color(stc3)) /*
			*/ (function y = x * exp(`r2'), range(`b0' `t2') lpattern(shortdash) color(stc3)) /*
			*/ (function y = x / exp(`r2'), range(`b2' `t0') lpattern(shortdash) color(stc3)) /*
			*/ if `touse' , aspect(1) xscale(log range(`r0' `t0')) yscale(log range(`r0' `t0')) /*
			*/   xtitle("Predictions: `b'") ytitle("Observations: `y'") legend(off) name(graphb)
		}
	}

	set graphics on
	if "`nograph'" == "" {
		if `nvar' == 2 { 
			graph combine grapha
		}
		else if `nvar' == 3 { 
			graph combine grapha graphb
		}
	}	
end


