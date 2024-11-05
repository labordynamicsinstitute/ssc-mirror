*! version 1.0.2  31oct2024  I I Bolotov
program define xtrevu, rclass
	version 16.0
	/*
		Reverse the order of values of time series and panel data variables by  
		substituting the original values or by creating new variables with a    
		prefixed identifier. If a "colon" command is provided, an estimation    
		procedure is executed on the inverted variables. The results of this    
		estimation, including predictions, residuals, and others, are stored as 
		either existing variables or new ones. Additionally, a comprehensive    
		post-estimation command can be executed.
		
		Author: Ilya Bolotov, MBA, Ph.D.                                        
		Date: 20 February 2024                                                  
	*/
	// syntax                                                                   
	if  trim(`"`0'"') == ""                                 {
		di as err "something required"
		exit 100
	}
	tokenize `"`0'"', parse(":")
	loc    0   `1'
	syntax																	///
	varlist [if] [in] [,													///
		replace PREfix(string)												///
		Type(string) Xb(string) Residuals(string) Stdp(string) force		///
		PREestimation(string asis) POSTestimation(string asis)				///
	]
	// adjust and preprocess options                                            
	if `"`replace'`prefix'"' == ""    & trim(`"`3'"') == "" {
		di as err "must specify either replace/prefix option or a : command"
		exit 198
	}
	if `"`prefix'"'                                   != "" {
		qui conf name  `prefix'
	}
	if `"`xb'`residuals'`stdp'"'                      != "" {
		qui conf name  `xb'   `residuals'   `stdp'
	}
	foreach var  in   "`xb'" "`residuals'" "`stdp'"         {
		cap conf var   `var',  ex
		if  ! _rc &   "`var'"  != ""  &   `"`force'"' == "" {
			di as err "option {bf:force} required for xb(), residuals(), "	///
					  "and stdp() to overwrite existing variables"
			exit 198
		}
	}
	tempvar          panelvar touse predict
	tempfile         tmpf
	// invert the value order of xtset data                                     
	preserve
	qui xtset
	if  "`r(panelvar)'" != ""       loc     panelvar  `r(panelvar)'
	else                            qui g  `panelvar'  = 1
	loc timevar     `r(timevar)'
	qui levelsof    `panelvar',     l(values)
	qui g           `touse'  = .
	mata:            X       = .
	foreach i    in `values'                          {
		qui replace `touse'         = cond(`panelvar' == `i', 1, 0) `if' `in'
		mata: for (i=1; i<=cols((v = tokens("`varlist'"))); i++) {;         ///
			      if  (st_isnumvar(v[i]))                                   ///
			           st_view( (x=J(0,0,. )), ., v[i], "`touse'");         ///
			      else st_sview((x=J(0,0,"")), ., v[i], "`touse'");         ///
			      x[.,.] = x[rows(x)..1,.];                                 ///
			  };
	}
	drop            `touse'
	mata:            mata drop i v x
	/* rename variables                                                       */
	if `"`prefix'"'                 != ""             {
		foreach var  of varl       `varlist'          {
			rename  `var'          `prefix'`var'
		}
		qui ds      `=ustrregexra("`varlist'","(^|\s)(.)","$1`prefix'$2",1)'
		loc          varlist       `r(varlist)'
	}
	// run : command (if specified)                                             
	if trim(`"`3'"')                != ""             {
		`preestimation'
		di as txt _n "  all {bf:lags} should be interpreted as {bf:leads}"	///
				  _n
		`3'
		/* run postestimation command/program (= multiple commands)           */
		`postestimation'
		cap conf mat e(b)
		if ! _rc     {
			foreach newvar in "xb" "residuals" "stdp" {
				if  "``newvar''"    != ""             {
					qui {
						predict       `type'         `predict', `newvar'
						cap conf var ``newvar'',      ex
						if  ! _rc                     {
							replace  ``newvar'' =    `predict'
							drop      `predict'
						}
						else rename   `predict'                ``newvar''
					}
				}
			}
		}
	}
	// replace/generate new variables                                           
	qui keep        `=cond(! strpos("`panelvar'","_"),"`panelvar'","")'		///
					`timevar'												///
					`=cond(`"`replace'`prefix'"'!="", "`varlist'", "")'		///
					`varlist' `xb' `residuals' `stdp'
	qui save        `tmpf',         replace
	****
	restore
	qui merge   1:1 `=cond(! strpos("`panelvar'","_"),"`panelvar'","")'		///
					`timevar'       using `tmpf',  update replace  force nogen
end
