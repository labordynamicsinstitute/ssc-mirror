*! version 1.2.1 17feb2025
capture program drop stackdid
program define stackdid, rclass
        version 11
        
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
        */      absorb(varlist fv)      /*
		*/		sw 						/*
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
        
/* BUILD */

        if ("`build'"=="") {
			
				* Assert data is xtset'ed
                capture xtset
                if (_rc) | inlist("","`r(panelvar)'","`r(timevar)'") {
                        di as err "must xtset data with panelvar and timevar"
                        exit 198
                }
                local unit `r(panelvar)'
                local time `r(timevar)'
                
				* Note to self: Is the following check worth it?
                * Assert treatment takes values {0,1,.}
                capture assert inlist(`treatment',0,1,.) `if' `in'
                if (_rc) { 
                        di as err "`treatment' is not a 0/1/. variable"
                        exit 450
                }

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
                foreach vname in _cohort _cohort_time _cohort_group {
                        capture ds `vname'
                        if (!_rc) {
                                di as err "varname `vname' must be available"
                                exit 110 
                        }
                }
                tempvar treat_prev treat_event nevertreated tostack treated latest_treat lost_treat gained_treat stacked

                * Helper macros 
                local ttype: type `time' // `time' datatype
                local tfmt : format `time' // `time' format
                if ("`log'"!="") local nolog "quietly" // suppress build log
                if ("`if'"!="") local ampif = subinstr("`if'","if","&",1) // replace if w/ ampersand

                * Preserve
				preserve
				
				* Find event times
                sort `group' `time'
                qui gen byte `treat_prev' = `treatment'[_n-1] if (`group'[_n-1]==`group' & `time'[_n-1]+1==`time')
                qui gen byte `treat_event' = (`treatment'==1 & `treat_prev'==0)
                qui levelsof `time' if (`treat_event'==1), local(cohorts)
                `nolog' di _n as text "treatment cohorts: " as result "`cohorts'"
                drop `treat_prev'
                
                * Initialize cohort identifier and nevertreated identifier
                qui gen `ttype' _cohort = . // missing means original, nonmissing means stacked...
                if ("`nevertreat'"!="") qui egen byte `nevertreated' = min(`treatment'==0), by(`group')
                
                * For each cohort...
                foreach co of local cohorts {                
                        
                        * (helper: treated/control ... {1:treatment cohort, 0:control, .:neither})
                        qui egen byte `treated' = max(cond(`time'==`co',`treat_event'==1,.)), by(`group')
                        qui replace `treated' = 0 if (missing(`treated') & `treatment'==0) // recover controls where cohort year is not observed
                        if ("`nevertreat'"!="") qui replace `treated' = . if (`treated'==0 & `nevertreated'==0)

                        * (1): grab everything within window of event
						if ("`window'"!="") {
								qui gen byte `tostack' = inrange(`time',`pre'+`co',`post'+`co'-1) if missing(_cohort) & !missing(`treated') `ampif' `in'
						}
						else {
								qui gen byte `tostack' = (missing(_cohort) & !missing(`treated')) `ampif' `in'
						}
						
                        * (2): remove latest treatment and prior
                        qui egen `ttype' `latest_treat' = max(cond(`treatment'==1,`time',.)) if (`tostack'==1 & `time'<`co'), by(`group')
                        qui replace `tostack' = 0 if (`tostack'==1 & `treatment'==1 & `time'<=`latest_treat' & !missing(`latest_treat'))

                        * (3): remove if treated group loses treatment status post-event
                        qui egen `ttype' `lost_treat' = min(cond(`treatment'==0,`time',.)) if (`treated'==1 & `co'<`time'), by(`group')
                        qui replace `tostack' = 0 if (`treated'==1 & `lost_treat'<=`time' & !missing(`lost_treat'))

                        * (4): remove if control group gains treatment status post-event
                        if ("`nevertreat'"=="") {
                                qui egen `ttype' `gained_treat' = min(cond(`treatment'==1,`time',.)) if (`treated'==0 & `co'<=`time'), by(`group')
                                qui replace `tostack' = 0 if (`treated'==0 & `gained_treat'<=`time' & !missing(`gained_treat'))
                                drop `gained_treat'
                        }

                        * (5): create stack using -expand-
                        drop `treated' `latest_treat' `lost_treat'
                        `nolog' di as text "cohort " as result "`co'" as text " stacked " _cont
                        `nolog' expand 2 if (`tostack'==1), gen(`stacked')
                        qui replace _cohort = `co' if (`stacked'==1)
                        drop `tostack' `stacked'
                }
				di
				
				* Generate fixed effects
                qui egen _cohort_time = group(_cohort `time') if !missing(_cohort), autotype
                qui egen _cohort_unit = group(_cohort `unit') if !missing(_cohort), autotype 
				
				* Generate sample weight (inverse frequency)
				if ("`clear'"!="") | ("`sw'"!="") {
						qui bysort `unit' `time': gen _sw = 1/(_N-1) 
						label var _sw "-stackdid- sample weight"
				}
                
                * Label saved (non-temporary) variables 
                format _cohort `tfmt'
                label var _cohort "-stackdid- treatment cohort"
                label var _cohort_time "-stackdid- cohort-time fixed effect"
                label var _cohort_unit "-stackdid- unit-cohort fixed effect"
                
                * Clean up & grab N
                qui count if missing(_cohort)
                local N_orig = r(N)
                qui count if !missing(_cohort)
                local N_stacked = r(N)
                
        }
        
/* ESTIMATE */
        
        if ("`regress'"=="") {
                local abs absorb(`absorb' _cohort_time _cohort_unit)
				local w = cond(("`sw'"!=""), "[aweight=_sw]", "[`weight'`exp']")
                `cmd' `anything' `w' `if' `in', `abs' `options'
                return local regline "`e(cmdline)'"
        }
        
/* CLEAN UP */
        
		* Apply clear/saving options
		if ("`build'"=="") {
				if ("`clear'"!="") {
						restore, not
						qui drop if missing(_cohort)
						if ("`saving'"!="") {
								di 
								save `saving'
						}
				}
				else if ("`saving'"!="") {
						qui drop if missing(_cohort)
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
                return scalar N_orig = `N_orig'
                return scalar N_stacked = `N_stacked'
        }
        return local cmdline "stackdid `0'"
end

* Note. The author recommends visually decomposing stacked data:
* table (`group') (`time') (_cohort), nototal statistic(firstnm `treatment')