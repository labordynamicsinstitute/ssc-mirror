*! probgenextval version 1.0.1
*! Performs Estimations of Binary 
*! Generalized Extreme Value Models
*! Diallo Ibrahima Amadou
*! All comments are welcome, 30Nov2021
 


/* Main Program */
capture program drop probgenextval
program probgenextval, eclass byable(onecall) sortpreserve properties(or svyb svyj svyr swml mi)
    version 16.0
    if _by() {
			local by "by `_byvars' `_byrc0':"
    }
	if replay() {
		    if (`"`e(cmd)'"' != "probgenextval") error 301
                    if _by() {
							error 190
                    }
		    Replay `0'
	}
	else  `by' Estimate `0'
end



/* Estimation Program */
program Estimate, eclass byable(recall) sortpreserve
	syntax varlist(fv ts) [if] [in] 	///
		[fweight pweight iweight] [,	///
		vce(passthru)					///
		noLOg							///
		noCONStant						///
		noLRTEST						///
		OFFset(varname numeric)			///
		EXPosure(varname numeric)		///
        Level(cilevel)					///
		init          					///
		OR *							///
	]
	mlopts mlopts, `options'
	local cns `s(constraints)'
    local title "title("Binary Generalized Extreme Value Estimations Results")"
	gettoken lhs rhs : varlist
	_fv_check_depvar `lhs'
	if "`weight'" != "" {
		local wgt "[`weight'`exp']"
	}	
	if "`log'" != "" {
		local qui quietly
	}
	if "`offset'" != "" {
		local offopt "offset(`offset')"
	}
	if "`exposure'" != "" {
		local expopt "exposure(`exposure')"
	}
	marksample touse
	markout `touse' `offset' `exposure' 
	_vce_parse `touse', opt(Robust oim opg)			///
		argopt(CLuster): `wgt' , `vce'				
	quietly {
			if "`init'" != "" {
								cloglog `lhs' `rhs'	///
								`wgt' if `touse',	/// 
								`constant' `offopt'	///
								`expopt' `mlopts' `vce'
								tempname b0vect b1vect
								matrix define `b0vect' = e(b)
								matrix define `b1vect' = (`b0vect', 0.01)
								local initopt "init(`b1vect', copy)"
			}
	}	
	`qui' di as txt _n "Fitting full model:"
	ml model lf probgenextval_ll					///
		(GEV: `lhs' = `rhs',						///
                    `constant' `offopt' `expopt')	///
		(cxi: )										///
		`wgt' if `touse',							///
		`vce'										///
		`log'										///
		`mlopts'									///
		`initopt'                             		///
        missing										///
		maximize                               	    ///
		`title'
	ereturn scalar k_aux = 1
	ereturn local predict probgenextval_p
	ereturn local cmd probgenextval
	ereturn local cmdline "probgenextval `0'"
	Replay , level(`level') `or'
end



/* Replay Program */
program Replay
	syntax [, Level(cilevel) OR ]
	ml display , level(`level') `or'
end


