*! version 1.4.0 16aug2025
capture program drop stackdid
program define stackdid, rclass
        version 15
        
/* SYNTAX */
        
        syntax [anything]               /*
        */      [aw fw pw iw] [if] [in] /*
        */      [,                      /*
        */      TReatment(varname numeric) /*
        */      GRoup(varname)          /*
        */      Window(string)          /*
        */      nevertreat              /*
        */      poisson                 /*
        */      nobuild                 /*
        */      noREGress               /*
        */      clear                   /*
        */      saving(string)          /*
        */      noLOG                   /* 
        */      Absorb(varlist fv)      /*
	*/	sw 			/*
        */      *                       /* estimator-specific options other than absorb()
        */      ]
  
        * Confirm required options, or nobuild, specified
        if ("`treatment'"=="" | "`group'"=="") & ("`build'"=="") {
                di as err "treatment() and group() are required unless nobuild is specified"
                exit 198
        }
		
	* Confirm dependencies installed
	if ("`regress'"=="") {
		if ("`poisson'"!="") {
			cap which ppmlhdfe 
			if (_rc) {
				di as err "package ppmlhdfe required: " as smcl "{bf:{stata ssc describe ppmlhdfe}}"
				exit 199
			}
			else	local cmd "ppmlhdfe"
		}
		else {
			cap which reghdfe 
			if (_rc) {
				di as err "package reghdfe required: " as smcl "{bf:{stata ssc describe reghdfe}}"
				exit 199
			}
			else	local cmd "reghdfe"
		}
	}
	
	* Catch incompatible syntax 
	if ("`weight'`exp'"!="") {
		if ("`sw'"!="") {
			di as err "weights are not allowed with sw"
			exit 198
		}
		else	local w [`weight'`exp']
	}
	if ("`sw'"!="")	local w [aweight=_sw]
	
	* Interact fixed effects with _cohort
	if ("`absorb'"!="") {
		while ("`absorb'"!="") {
			gettoken a absorb: absorb
			local absorb_cohort `absorb_cohort' `a'#_cohort
		}
	} 
	else	local absorb_cohort _cohort
	local abs absorb(`absorb_cohort')

        
/* BUILD */

        if ("`build'"=="") {
			
		* Assert data is xtset'ed
                capture xtset // sorts data too.
                if (_rc) | inlist("","`r(panelvar)'","`r(timevar)'") {
                        di as err "must xtset data with panelvar and timevar"
                        exit 198
                }
                local unit `r(panelvar)'
                local time `r(timevar)'
		
                * Parse window()
		if ("`window'"!="") {
			gettoken pre post: window
			capture assert `pre'<`post' & inrange(0,`pre',`post'-1)
			if (_rc) {
				di as err "option window() specified incorrectly"
				exit 198
			}
		}
                
                * Assert varnames are available
		capture ds _cohort
		if (!_rc) {
			di as err "varname _cohort must be available"
			exit 110 
                }
		
		* Note to self: Is the following check worth it?
                * Assert treatment takes values {0,1,.}
                capture assert inlist(`treatment',0,1,.) `if' `in', fast
                if (_rc) { 
                        di as err "`treatment' is not a 0/1/. variable"
                        exit 450
                }
		
		* Preserve and filter
		preserve
		if ("`if'`in'"!="") {
			qui keep `if' `in'
			local if 
			local in 
		}

                * Helper macros 
                local ttype: type `time' // `time' datatype
                local tfmt : format `time' // `time' format
                if ("`log'"!="") local nolog "quietly" // suppress build log
		local N_original = _N 
		local N_fmt = strlen("`N_original'") + (floor(strlen("`N_original'") / 3))
		tempvar treat_prev treat_event nevertreated treated latest_treat lost_treat gained_treat stacked reps
				
		* Find event times
                sort `group' `time'
                qui gen byte `treat_prev' = `treatment'[_n-1] if (`group'[_n-1]==`group' & `time'[_n-1]+1==`time')
                qui gen byte `treat_event' = (`treatment'==1 & `treat_prev'==0)
                qui levelsof `time' if (`treat_event'==1), local(cohorts)
		
		* Find event times v2
		qui egen byte `treat_prev' = max()
		
		* Issue warning if treatment is impermanent 
		capture assert (`treatment'==1) if (`treat_prev'==1), fast
		local permanent = (_rc==0)
		if (!`permanent') di as txt "impermanent treatment detected"
		drop `treat_prev'
		
		* Print event times
		`nolog' di _n as text "treatment cohorts: " as result "`cohorts'"		
		
                * Initialize cohort identifier and nevertreated identifier
                qui gen `ttype' _cohort = . // missing means original, nonmissing means stacked...
		format _cohort `tfmt'
                label var _cohort "-stackdid- treatment cohort"
                if ("`nevertreat'"!="") qui egen byte `nevertreated' = min(`treatment'==0), by(`group')
                
                * For each cohort...
                foreach co in `cohorts' {     
                        
                        * (helper: treated/control ... {1:treatment cohort, 0:control, .:neither})
                        qui egen byte `treated' = max(cond(`time'==`co',`treat_event'==1,.)), by(`group')
                        qui replace `treated' = 0 if (missing(`treated') & `treatment'==0) // recover controls where cohort year is not observed
                        if ("`nevertreat'"!="") qui replace `treated' = . if (`treated'==0 & `nevertreated'==0)
			
			* (helper: to-stack marker)
			tempvar tostack`co'
			local tostacks `tostacks' `tostack`co''

                        * (1): grab everything within window of event
			if ("`window'"!="") {
				qui gen byte `tostack`co'' = inrange(`time',`pre'+`co',`post'+`co'-1) if !missing(`treated')
			}
			else {
				qui gen byte `tostack`co'' = !missing(`treated')
			}
			
			if (!`permanent') {
				* (2): remove latest treatment and prior
				qui egen `ttype' `latest_treat' = max(cond(`treatment'==1,`time',.)) if (`tostack`co''==1 & `time'<`co'), by(`group')
				qui replace `tostack`co'' = 0 if (`tostack`co''==1 & `treatment'==1 & `time'<=`latest_treat' & !missing(`latest_treat'))
				drop `latest_treat'
				
				* (3): remove if treated group loses treatment status post-event
				qui egen `ttype' `lost_treat' = min(cond(`treatment'==0,`time',.)) if (`treated'==1 & `co'<`time'), by(`group')
				qui replace `tostack`co'' = 0 if (`treated'==1 & `lost_treat'<=`time' & !missing(`lost_treat'))
				drop `lost_treat'
			}
				
                        * (4): remove if control group gains treatment status post-event
                        if ("`nevertreat'"=="") {
                                qui egen `ttype' `gained_treat' = min(cond(`treatment'==1,`time',.)) if (`treated'==0 & `co'<=`time'), by(`group')
                                qui replace `tostack`co'' = 0 if (`treated'==0 & `gained_treat'<=`time' & !missing(`gained_treat'))
                                drop `gained_treat'
                        }
			drop `treated'
			
			* Print description
			qui sum `treatment' if (`tostack`co''==1 & `time'>=`co'), meanonly
			if (r(mean)==1) {
				local cohorts: list cohorts - co
				local res ": omitted (no valid controls)"
			}
			else {
				qui count if `tostack`co''
				local res ": " %`N_fmt'.0fc r(N) " obs"
			}
			`nolog' di as text "cohort " as result "`co'" as text "`res'"
		}
		if ("`nevertreat'"!="") drop `nevertreated'
		drop `treat_event'
		
		* Generate sample weight (inverse frequency)
		if ("`clear'"!="") | ("`saving'"!="") | ("`sw'"!="") {
			qui egen `reps' = rownonmiss(`tostacks')
			qui gen _sw = 1/`reps'
			label var _sw "-stackdid- sample weight"
			drop `reps'
		}
		
		* Create stacks using -expand-
		if ("`cohorts'"!="") {
			`nolog' di as text "stacking" _cont
			foreach co of local cohorts {
				qui expand 2 if (`tostack`co''==1) in 1/`N_original', gen(`stacked')
				qui replace _cohort = `co' if (`stacked'==1)
				drop `tostack`co'' `stacked'
				`nolog' di as text "." _cont
			}
			local N_stacked = _N - `N_original'
			`nolog' di
		}
		else {
			`nolog' di as text "nothing to stack"
			local N_stacked 0
		}
        }
        
/* ESTIMATE */
        
        if ("`regress'"=="") {
		di
		
		* Confirm data are stacked
		cap ds _cohort
		if (_rc>0) & ("`build'"!="") {
			di as err "_cohort not found; data do not appear to be stacked"
			exit 111
		}
		
		* Executes regression
                `cmd' `anything' `w' `if' `in', `abs' `options'
                return local regline "`e(cmdline)'"
        }
        
/* CLEAN UP */
        
	* Apply clear/saving options
	if ("`build'"=="") {
		if ("`clear'"!="") {
			restore, not
			qui drop in 1/`N_original'
			if ("`saving'"!="") {
				di 
				save `saving'
			}
		}
		else if ("`saving'"!="") {
			qui drop in 1/`N_original'
			di
			save `saving'
			restore
		}
		else	restore
	}

        
/* RETURNS + MESSAGES */

        if ("`build'"=="") {
                return local treatment "`treatment'"
                return local group "`group'"
                return local window "`window'"
                return scalar N_original = `N_original'
                return scalar N_stacked = `N_stacked'
        }
        return local cmdline "stackdid `0'"
end

* Note. The author recommends visually decomposing stacked data:
* table (`group') (`time') (_cohort), nototal statistic(firstnm `treatment')