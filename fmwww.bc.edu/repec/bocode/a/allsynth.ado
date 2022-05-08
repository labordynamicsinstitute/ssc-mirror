*! version 1.0  Justin Wiltshire 05/06/2022 - Wrapper adding functionality to -synth- package

program allsynth, eclass sortpreserve byable(recall)
	version 15.1 // Not tested on earlier versions
	graph close _all
	graph drop _all
	preserve

	* Check if data is tsset with panel and time vars
	qui tsset
	local tvar `r(timevar)'
	local pvar "`r(panelvar)'"
	if "`tvar'" == "" {
		di as err "Panel unit variable missing. Please use -tsset panelvar timevar-"
		exit 198
	}

	if "`pvar'" == "" {
		di as err "Panel time variable missing. Please use -tsset panelvar timevar-"
		exit 198
	}
	
	* Confirm -synth- program is installed
	capture synth
	if _rc == 199 {
		di as err "-synth- package and its ancillary data must be installed. Type -ssc install synth, replace all-"
		exit 198
	}
			
	* Confirm -distinct- program is installed
	capture distinct
	if _rc == 199 {
		di as err "-distinct- package must be installed. Type -ssc install distinct-"
		exit 198
	}
	
	* Confirm -elasticregress- program is installed if one of the bcorrect() options -ridge-, -lasso-, or -elastic- are specified
	capture elasticregress
	if _rc == 199 {
		di as err "-elasticregress- package must be installed. Type -ssc install elasticregress-"
		exit 198
	}

	* Set parameters
	#delimit ;
		syntax anything,
			[
			TRUnit(numlist min=1 max=1 int sort)
			TRPeriod(numlist min=1 max=1 int sort) 
			COUnit(numlist min=2 int sort) 
			xperiod(numlist min=1 >=0 int sort) 
			mspeperiod(numlist  min=1 >=0 int sort) 
			resultsperiod(numlist min=1 >=0 int sort) 
			unitnames(varlist max=1 string) 
			FIGure 
			Keep(string)
			BCORrect(string)
			GAPFIGure(string)
			PVALues
			PLACeboskeep
			TRANSform(string)
			STACKed(string)
			REPlace 
			customV(numlist) 
			margin(real 0.005) 
			maxiter(integer 1000) 
			sigf(integer 12)
			bound(integer 10) 
			nested 
			allopt 
			* 
			]
			;
		#delimit cr

	* Define tempvars
	tempvar Xco Xcotemp Xtr Xtrtemp Zco Ztr Yco Ytr subsample misscheck conlabel _trU _trP
	
	* Populate user-specified options with user inputs
		#delimit ;
			local 
				inputlist "
				counit
				xperiod
				mspeperiod
				resultsperiod
				keep
				unitnames 
				customv
				margin
				maxiter
				sigf
				bound
				";
			#delimit cr	
			
	* Parse keep() if keep(something, replace) is specified
	capture assert strpos("`keep'", ",") == 0
	if _rc != 0 {
		local pq = strpos("`keep'", ",") - 1
		local q = strpos("`keep'", ",") + 1
		if "`replace'" == "" {
			local replace = trim(substr("`keep'", `q', .))
		}
		local keep = substr("`keep'", 1, `pq')
	}
	
	* Ensure any specified .dta extension in keep() won't cause problems
	local keep = subinstr("`keep'", ".dta", "", .)
	
	* Get keep directory
	local _Filename = trim("`keep'")
	capture assert strpos("`_Filename'", "/") == 0
	if _rc != 0 {
		local _Filename = reverse("`_Filename'")
		local pq = strpos("`_Filename'", "/") - 1
		local q = strpos("`_Filename'", "/") + 1
		local _Filepath = reverse(substr("`_Filename'", `q', .))
		local _Filename = reverse(substr("`_Filename'", 1, `pq'))
	}
	* Or \
	capture assert strpos("`_Filename'", "\") == 0
	if _rc != 0 {
		local _Filename = reverse("`_Filename'")
		local pq = strpos("`_Filename'", "\") - 1
		local q = strpos("`_Filename'", "\") + 1
		local _Filepath = reverse(substr("`_Filename'", `q', .))
		local _Filename = reverse(substr("`_Filename'", 1, `pq'))
	}

	* Ensure _Filepath and _Filename have no spaces
	capture assert strpos("`_Filepath'", " ") == 0
	if _rc != 0 {
		di as err "The keep() directory cannot have any spaces, but -`_Filepath' contains a space. Re-specify the filepath"
		exit 198
	}
	capture assert strpos("`_Filename'", " ") == 0
	if _rc != 0 {
		di as err "The keep() file name cannot have any spaces, but -`_Filename'- contains a space. Re-specify the file name"
		exit 198
	}

	* If stacked() option is specified
	if "`stacked'" != "" {
		
		* Ensure keep() is specified, as unintentionally forgetting to keep() is a costly mistake
		if "`keep'" == "" {
			di as err "The allsynth option stacked() is specified, but keep(file, replace) is not specified. The allsynth option keep(file, replace) must be specified when the stacked() option is specified"
			exit 198
		}
		if "`replace'" == "" {
			di as err "The allsynth option stacked() is specified, and keep(file) is specified, but replace is not specified. The allsynth option keep(file, replace) must be specified when the stacked() option is specified"
			exit 198
		}
	
		* Parse stacked() option
		capture assert strpos("`stacked'", ",") == 0
		if _rc != 0 {
			local pq = strpos("`stacked'", ",") - 1
			local q = strpos("`stacked'", ",") + 1
			local stackedopts = substr("`stacked'", `q', .)
			local stacked = substr("`stacked'", 1, `pq')
		}
		local stacked2 "`stacked'"
		local stackedopts2 "`stackedopts'"
		local stackedcheck "trunits trperiods"
		local stackedoptscheck "clear sampleavgs eventtime avgweights donorcond donorcond2 donorcond3 donorcond4 donorif balanced unique_w figure"
		local stsize : list sizeof stacked2
		local stoptssize : list sizeof stackedopts2
		
		* Ensure trunits() and trperiods() are properly defined
		local s3
		while `stsize' > 0 {
			gettoken s stacked2 : stacked2, bind
			capture assert strpos("`s'", "(") == 0
			if _rc != 0 {
				gettoken _Entry s2 : s, parse("(")				
			}
			local s2 = subinstr("`s2'", "(", "", .)
			local s2 = subinstr("`s2'", ")", "", .)
			if "`_Entry'" == "trunits" {
				qui gen `_trU' = `s2'
				capture assert inlist(`_trU', 0, 1)
				if _rc != 0 {
					di as err "Ensure `s2' is a dummy variable assigning a 1 to all treated units and a 0 to all untreated units in the panel unit variable `pvar'"
				exit 198
				}
				qui levelsof `pvar' if `_trU' == 1, local(trUnits)
				local _trUsize : list sizeof trUnits
				qui levelsof `pvar' if `_trU' == 0, local(dpUnits)
				local _dpUsize : list sizeof dpUnits
				capture assert `_trUsize' > 1
				if _rc != 0 {
					di as err "stacked(trunits(`s2') ... ) is specified. `s2' must indicate at least 2 treated units"
					exit 198
				}
				capture assert `_dpUsize' > 1
				if _rc != 0 {
					di as err "stacked(trunits(`s2') ... ) is specified. `s2' must indicate at least 2 donor pool (untreated) units"
					exit 198
				}
			}
			if "`_Entry'" == "trperiods" {
				qui gen `_trP' = `s2'
				qui recode `_trP' (0=.)
				local trP "`s2'"
			}
			local stsize : list sizeof stacked2
			local s3 "`s3' `_Entry'"
		}
		
		capture assert trim("`s3'") == "trunits trperiods" | trim("`s3'") == "trperiods trunits"
		if _rc != 0 {
			di as err "The allsynth option stacked() is misspecified. stacked(trunits(varlist) trperiods(varlist) [, options]) is required, but one or both of trunits() and trperiods() is incorrectly specified [e.g. as -trunit()- or -trp()-  or -trunitss()-] or something else is also specified"
			exit 198
		}
		qui levelsof `tvar', local(periodS)
		foreach u of local trUnits {
			qui sum `_trP' if `pvar' == `u'
			local _trPeriod = r(mean)
			capture assert `_trP' == `_trPeriod' if `pvar' == `u' & !mi(`_trP')
			if _rc != 0 {
				di as err "Multiple treatment periods (`trP') are observed for treated unit (`pvar' == `u'). Remove (`pvar' == `u') from your treated units, or restrict `trP' to observe a single treatment period for (`pvar' == `u') and take note of the implications for interpreting the results"
				exit 198
			}
			local trPcheck : list _trPeriod in periodS
			if `trPcheck' == 0 {
				if "`_trPeriod'" == "." {
					di as err "`trP' is missing for treated unit (`pvar' == `u'). `trP' must define the treatment period for each treated unit"
					exit 198
				}
				else {
					di as err "`trP' observes `_trPeriod' as the treatment period for treated unit (`pvar' == `u'), but `_trPeriod' is not found in timevar `tvar'"
					exit 198
				}
			}
		}
		
		foreach u of local dpUnits {
			capture assert mi(`_trP') if (`pvar' == `u')
			if _rc != 0 {
				di as err "A treatment period (`trP') is observed for donor pool unit (`pvar' == `u'). Remove (`pvar' == `u') from your donor pool, or if (`pvar' == `u') is actually untreated then set `trP' to missing (.) for (`pvar' == `u')"
				exit 198
			}
		}
		capture assert "`s3'" == " trunits trperiods" | "`s3'" == " trperiods trunits"
		if _rc != 0 {
			di as err "The allsynth option stacked() is misspecified. Use the syntax allsynth ..., ... stacked(trunits(varlist) trperiods(varlist), clear [options]), where trunits(), trperiods(), and the -clear- option are required"
			exit 198
		}
		
		* Ensure options for stacked() are properly specified, and record the user-specified values
		local s4
		local s5
		while `stoptssize' > 0 {
			gettoken s stackedopts2 : stackedopts2, bind
			capture assert strpos("`s'", "(") == 0
			if _rc != 0 {
				gettoken _Entry s2 : s, parse("(")				
			}
			if _rc == 0 {
				gettoken _Entry s2 : s
			}
			if "`_Entry'" != "figure" & strpos("`_Entry'", "donorcond") == 0 & "`_Entry'" != "donorif" {
				local s2 = subinstr("`s2'", "(", "", .)
				local s2 = subinstr("`s2'", ")", "", .)
			}
			if "`_Entry'" == "figure" | strpos("`_Entry'", "donorcond") != 0 | "`_Entry'" == "donorif" {
				local s2 = subinstr("`s2'", "(", "", 1)
				local s2 = reverse(subinstr(reverse("`s2'"), ")", "", 1))
			}
			local s2 = trim("`s2'")
			if "`_Entry'" == "clear" {
				local _stClear "`s'"
				local s4 "`s4' `_Entry'"
			}
			if "`_Entry'" == "sampleavgs" {
				if "`pvalues'" == "" {
					di as err "The `_Entry'() option of the allsynth option stacked() is specified, but the allsynth option -pvalues- is not specified. Specify the allsynth option -pvalues- or do not specify `_Entry'() in the allsynth stacked()"
					exit 198
				}
				local _stSampleavgs "`s2'"
				capture assert round(`_stSampleavgs') == `_stSampleavgs' & `_stSampleavgs' >= 30
				if _rc != 0 {
					di as err "The `_Entry'() option of the allsynth option stacked() is misspecified. If `_Entry'() is specified, it can only accept an integer value of at least 30"
					exit 198
				}
				local s4 "`s4' `_Entry'"
			}
			if "`_stSampleavgs'" == "" & "`pvalues'" != "" {
					local _stSampleavgs "100"
				}
			if "`_Entry'" == "eventtime" {
				local _Eventtimesize : list sizeof s2
				local _Eventtime "`s2'"
				local _stEventtimemin
				local _stEventtimemax
				forval et = 0/1 {
					gettoken _e _Eventtime : _Eventtime
					capture assert round(`_e') == `_e'
					if _rc != 0 | `_Eventtimesize' != 2 {
						di as err "The `_Entry'() option of the allsynth option stacked() is misspecified. If `_Entry'() is specified, it can only accept exactly two integers which indicated the range of event-time periods to consider"
						exit 198
					}
					if `et' == 0 {
						capture assert `_e' < 0 & `_Eventtime' > 0
						if _rc == 0 {
							local _stEventtimemin = `_e'
							local _stEventtimemax = `_Eventtime'
						}
						if _rc != 0 {
							capture assert `_e' > 0 & `_Eventtime' < 0
								if _rc == 0 {
									local _stEventtimemin = `_Eventtime'
									local _stEventtimemax = `_e'
								}
								if _rc != 0 {
								di as err "The `_Entry'() option of the allsynth option stacked() is misspecified. One of the two integers must be strictly negative, and the other must be strictly positive"
								exit 198
							}
						}
					}
				}
				local s4 "`s4' `_Entry'"
			}
			if "`_Entry'" == "avgweights" {
				capture assert !mi(`s2') if `_trU' == 1
				if _rc != 0 {
					di as err "The `_Entry'() option of the allsynth option stacked() is misspecified. If `_Entry'() is specified, it can only accept a numeric variable with no missing observations for any treated unit"
					exit 198
				}
				qui levelsof `pvar' if `_trU' == 1, local(unitlist)
				foreach u of local unitlist {
					qui sum `s2' if `pvar' == `u'
					capture assert `s2' == r(mean) if `pvar' == `u'
					if _rc != 0 {
						di as err "`s2' is specified as a weight variable in the `_Entry'() option of the allsynth option stacked(), but it varies within units (`pvar'). The weighting variable specified within avgweights() must be non-missing and constant for each unit"
						exit 198
					}
				}
				local _stAvgweights "`s2'"
				local s4 "`s4' `_Entry'"
			}
			if "`_Entry'" == "donorcond" {
				capture assert strpos("`s2'", ",") == 0
				if _rc != 0 {
					local q = strpos("`s2'", ",") + 1
					local _stDonorCond2 = trim(substr("`s2'", `q', .))
					gettoken _stDonorCond1 s2 : s2, parse(",")
				}
				if _rc == 0 {
					local _stDonorCond1 "`s2'"
				}
				local s4 "`s4' `_Entry'"
			}
			if "`_Entry'" == "donorcond2" {
				capture assert strpos("`s2'", ",") == 0
				if _rc != 0 {
					local q = strpos("`s2'", ",") + 1
					local _stDonorCond4 = trim(substr("`s2'", `q', .))
					gettoken _stDonorCond3 s2 : s2, parse(",")
				}
				if _rc == 0 {
					local _stDonorCond3 "`s2'"
				}
				local s4 "`s4' `_Entry'"
			}
			if "`_Entry'" == "donorcond3" {
				capture assert strpos("`s2'", ",") == 0
				if _rc != 0 {
					local q = strpos("`s2'", ",") + 1
					local _stDonorCond6 = trim(substr("`s2'", `q', .))
					gettoken _stDonorCond5 s2 : s2, parse(",")
				}
				if _rc == 0 {
					local _stDonorCond5 "`s2'"
				}
				local s4 "`s4' `_Entry'"
			}
			if "`_Entry'" == "donorcond4" {
				capture assert strpos("`s2'", ",") == 0
				if _rc != 0 {
					local q = strpos("`s2'", ",") + 1
					local _stDonorCond8 = trim(substr("`s2'", `q', .))
					gettoken _stDonorCond7 s2 : s2, parse(",")
				}
				if _rc == 0 {
					local _stDonorCond7 "`s2'"
				}
				local s4 "`s4' `_Entry'"
			}
			if "`_Entry'" == "donorif" {
				local _stDonorif "`s2'"
				local s4 "`s4' `_Entry'"
			}
			if "`_Entry'" == "balanced" {
				local _stBalanced "`s'"
				local s4 "`s4' `_Entry'"
			}
			if "`_Entry'" == "unique_w" {
				local _stUnique_w "`s'"
				local s4 "`s4' `_Entry'"
			}
			if "`_Entry'" == "figure" {

				* Parse figure()
				capture assert strpos("`s2'", ",") == 0
				if _rc != 0 {
					local pq = strpos("`s2'", ",") - 1
					local q = strpos("`s2'", ",") + 1
					local stfigureopts = trim(substr("`s2'", `q', .))
					local s2 = substr("`s2'", 1, `pq')
				}
				local _stFigure "`s2'"
				if "`pvalues'" == "" & strpos("`_stFigure'", "placebos") != 0 {
					di as err "`_Entry'(`_stFigure') is specified in the allsynth option stacked(), but the allsynth option -pvalues- is not specified. Specify the allsynth option -pvalues- or do not specify -placebos- in the `_Entry'() option of the allsynth option stacked()"
					exit 198
				}
				
				* Identify the stfigure savefile if defined
				local stfigureopts2 "`stfigureopts'"
				local sttwo : list sizeof stfigureopts2
				while `sttwo' > 0 {
					gettoken g stfigureopts2 : stfigureopts2, bind
					capture assert strpos("`g'", "save(") == 0
					if _rc != 0 {
						local _saveEntry "`g'"
						local stfigureopts = subinstr("`stfigureopts'", "`_saveEntry'", "", .)
					}
					local sttwo = `sttwo' - 1
				}
				capture assert strpos("`_saveEntry'", "replace") == 0
				if _rc != 0 {
					local stfigsavereplace ", replace"
				}
				gettoken stfigsave : _saveEntry, parse(",")
				local stfigsave = subinstr("`stfigsave'", "save(", "", .)
				local stfigsave = subinstr("`stfigsave'", ")", "", .)
				local _saveEntry
				
				* Set graph export default as .pdf unless other extension is specified
				capture assert strpos("`stfigsave'", ".") == 0
				if _rc == 0 {
					local stfigsave = subinstr("`stfigsave'", "`stfigsave'", "`stfigsave'.pdf", .)
				}
				if _rc != 0 {
					local _stFigsavename = trim("`stfigsave'")
					capture assert strpos("`_stFigsavename'", "/") == 0
					if _rc != 0 {
						local _stFigsavename = reverse("`_stFigsavename'")
						local pq = strpos("`_stFigsavename'", "/") - 1
						local q = strpos("`_stFigsavename'", "/") + 1
						local _stFigpath = reverse(substr("`_stFigsavename'", `q', .))
						local _stFigsavename = reverse(substr("`_stFigsavename'", 1, `pq'))
						local _slash "/"
					}
					* Or \
					capture assert strpos("`_stFigsavename'", "\") == 0
					if _rc != 0 {
						local _stFigsavename = reverse("`_stFigsavename'")
						local pq = strpos("`_stFigsavename'", "\") - 1
						local q = strpos("`_stFigsavename'", "\") + 1
						local _stFigpath = reverse(substr("`_stFigsavename'", `q', .))
						local _stFigsavename = reverse(substr("`_stFigsavename'", 1, `pq'))
						local _slash "\"
					}
					gettoken g _stFigsavename : _stFigsavename, parse(".")
					local g "`g'`_stFigsavename'"
					local stfigsave "`_stFigpath'`_slash'`g'"
				}
				local stfigsave = subinstr("`stfigsave'", "`stfigsave'", "graph export `stfigsave'", .)
				local s4 "`s4' `_Entry'"
			}
			local stoptssize : list sizeof stackedopts2
			local s3 "`s3' `_Entry'"
			local s5 "`s5' `_Entry'"
		}

		* Ensure no other options are specified
		local s4 = trim("`s4'")
		local s5 = trim("`s5'")
		local ssize : list sizeof s5
		while `ssize' > 0 {
			qui gettoken s s5 : s5
			capture assert strpos("`s4'", "`s'") != 0
			if _rc != 0 {
				di as err "-`s'- is not a valid option for the stacked() option of allsynth"
				exit 198
			}
			local ssize = `ssize' - 1
		}
		
		* Ensure clear is specified if stacked() is specified
		capture assert "`_stClear'" != ""
		if _rc != 0 {
			di as err "The allsynth option stacked() is specified but -clear- is not specified within stacked(). -clear- must be specified within stacked as all existing `filename'.dta files in the specified keep() directory will be erased. Specify -clear- as -allsynth ..., ... stacked(trunits(varlist) trperiods(varlist), clear [options]-"
			exit 198
		}
		
		* Clear older files
		local _Slash
		if "`_Filepath'" != "" {
			local _Slash "/"
		}
		if "`_stClear'" != "" {
			local filelist: dir "`_Filepath'" files "*.dta"
			foreach f of local filelist {
				if strpos("`f'", "`filename'_`pvar'") != 0 {
					di
					di as txt "Erasing existing `f' file..."
					qui erase "`_Filepath'`_Slash'`f'"
				}
			}
		}
	}	

	* Set _trU and _trP if stacked() is not specified
	if "`stacked'" == "" {
	
		* Confirm trunit() and trperiod() are specified if stacked() is not specified
		if "`trunit'" == "" | "`trperiod'" == "" {
			di as err "options trunit() and trperiod() required if option stacked() is not specified"
			exit 198
		}
		qui gen `_trU' = (`pvar' == `trunit')
		qui gen `_trP' = `trperiod' if `_trU' == 1
	}
	
	* Preserve the user-specified macros
	local _userMacros "anything counit xperiod mspeperiod resultsperiod unitnames figure keep bcorrect gapfigure pvalues transform stacked replace customv margin maxiter sigf bound nested allopt"
	foreach m of local _userMacros {
		local `m'2 ``m''
	}
	
	* Save tempfile
	tempfile corebase
	qui save "`corebase'", replace
	
	* Loop through the treated units (including a single treated unit)
	qui levelsof `pvar' if `_trU' == 1, local(_trUnitslist)
	foreach trunit of local _trUnitslist {
		graph close _all
		graph drop _all
		qui use "`corebase'", clear
		
		* Restore the user-specified macros
		foreach m of local _userMacros {
			local `m' "``m'2'"
		}
		
		* Set filesave macro suffix for many treated units
		if "`stacked'" != "" {
			local multisave "_`pvar'`trunit'"
		}
		
		* Rename keep file for each treated unit if stacked() is specified
		local keep "`keep'`multisave'"
		
		* Get the treated period for this treated unit
		qui sum `_trP' if `pvar' == `trunit'
		local trperiod = r(mean)
			
		* Temporarily drop the other treated units
		qui drop if `_trU' == 1 & `pvar' != `trunit'
		
		* Keep donor pool units specified in donorif, if donorif() is specified
		if "`_stDonorCond1'" != "" | "`_stDonorCond3'" != "" {
			`_stDonorCond1'
			`_stDonorCond2'
			`_stDonorCond3'
			`_stDonorCond4'
			`_stDonorCond5'
			`_stDonorCond6'
			`_stDonorCond7'
			`_stDonorCond8'
		}
		if "`_stDonorif'" == "" & ("`_stDonorCond1'" != "" | "`_stDonorCond3'" != "" | "`_stDonorCond5'" != "" | "`_stDonorCond7'" != "") {
		di
			di as err "donorif() must be specified if donorcond(), donorcond2(), donorcond3(), or donorcond4() are specified"
			exit 198
		}
		if "`_stDonorif'" != "" {
			di
			di "Restricting donor pool for treated `pvar' == `trunit', as specified"
			qui keep if `_trU' == 1 | `_stDonorif'
		}

		* If avgweights() is specified in stacked(), observe the weight in a macro
		if "`_stAvgweights'" != "" {
			qui sum `_stAvgweights' if `pvar' == `trunit'
			local avgweights = r(mean)
		}
	
		* Capture `tvar' format
		tempfile core
		qui save "`core'", replace
		qui desc, replace clear
		qui levelsof format if name == "`tvar'", local(x)
		local _tVarformat = subinstr(`x', "`", "", .)
		qui use "`core'", clear

		* `tvar' values and count
		qui levelsof `tvar', local(_t)
		local tsize : list sizeof _t
				
		* Require keep be specified if pvalues is specified
		if "`pvalues'" != "" & "`keep'" == "" {
			di as err "pvalues is specified but -keep()- is not specified. As it can take considerable time to run pvalues, -keep()- is likely desirable and must be specified"
			exit 198
		}
				
		* Keep placebo estimates if pvalues is specified and keep is specified
		if "`pvalues'" != "" {
			local placeboskeep = 1
		}

		* Initialize bcorrect specification locals
		local bcorrectnosave = 0
		local bcorrectmerge = 0
		local bcorrectsave = 0
		local bcorrectfigure = 0
		local bcorrectposonly = 0
		local bcorrectridge = 0
		local bcorrectlasso = 0
		local bcorrectelastic = 0
		
		* Parse the bcorrect() string
		foreach s of local bcorrect {
			capture assert "`s'" == "nosave" | "`s'" == "merge" | "`s'" == "figure" | "`s'" == "posonly" | "`s'" == "ridge" | "`s'" == "lasso" | "`s'" == "elastic"
			if _rc != 0 {
				di as err "bcorrect() contains an invalid specification. Only -nosave- or -merge-, and the options -figure- AND one of -posonly-, -ridge-, -lasso-, and -elastic- are allowed. Specifying bcorrect() without any options will be treated as if bcorrect() is not specified"
				exit 198
			}
			local bcorrect`s' = 1
		}
		if `bcorrectnosave' == 1 & `bcorrectmerge' == 1 {
			di as err "bcorrect() contains an invalid specification. Only one of -nosave- or -merge- is allowed. It may be combined with the bcorrect() options -figure- AND one of -posonly-, -ridge-, -lasso-, or -elastic-"
			exit 198
		}
		if (`bcorrectfigure' == 1 | `bcorrectposonly' == 1 | `bcorrectridge' == 1 | `bcorrectlasso' == 1 | `bcorrectelastic' == 1) & (`bcorrectnosave' == 0 & `bcorrectmerge' == 0) {
			di as err "bcorrect() contains an invalid specification. One of -nosave- or -merge- must be specified if any of -figure-, -posonly-, -ridge-, -lasso-, or -elastic- are specified"
			exit 198
		}
		local bcoroptsum = `bcorrectposonly' + `bcorrectridge' + `bcorrectlasso' + `bcorrectelastic'
		if !inlist(`bcoroptsum', 0, 1) {
			di as err "bcorrect() contains an invalid option specification. Only one of -posonly-, -ridge-, -lasso-, and -elastic- may be specified. This is in addition to -figure-, which may be specified along with one of these options"
			exit 198
		}
		foreach s in nosave merge {
			if `bcorrect`s'' == 1 {
				local bcorrect "`s'"
			}
		}
		
		* Alert if bcorrect(merge) is specified but keep() is not specified
		if "`bcorrect'" == "merge" {
			capture assert "`keep'" != ""
			if _rc != 0 {
				di as err "bcorrect(`bcorrect') is specified, but keep() is not specified. Either specify keep() or change the bcorrect() specification to -nosave-"
				exit 198
			}
		}
		local bcorreg "reg"
		if `bcorrectridge' == 1 {
			local bcorreg "ridgeregress"
		}
		if `bcorrectlasso' == 1 {
			local bcorreg "lassoregress"
		}
		if `bcorrectelastic' == 1 {
			local bcorreg "elasticregress"
		}
		
		* Initialize gapfigure specification locals
		local gapfigclassic = 0
		local gapfigbcorrect = 0
		local gapfigplacebos = 0
		local gapfiglineback = 0
		
		* Parse the gapfig() string to capture any specified twoway options
		capture assert strpos("`gapfigure'", ",") == 0
		if _rc != 0 {
			local pq = strpos("`gapfigure'", ",") - 1
			local q = strpos("`gapfigure'", ",") + 1
			local gftwopts = substr("`gapfigure'", `q', .)
			local gapfigure = substr("`gapfigure'", 1, `pq')
		}

		* Identify the graph savefile if defined
		local gftwopts2 "`gftwopts'"
		local gftwo : list sizeof gftwopts2
		while `gftwo' > 0 {
			gettoken g gftwopts2 : gftwopts2, bind
			 capture assert strpos("`g'", "save(") == 0
			if _rc != 0 {
				local _saveEntry "`g'"
				local gftwopts = subinstr("`gftwopts'", "`_saveEntry'", "", .)
			}
			local gftwo = `gftwo' - 1
		}
		capture assert strpos("`_saveEntry'", "replace") == 0
		if _rc != 0 {
			local gapfigsavereplace ", replace"
		}
		gettoken gapfigsave : _saveEntry, parse(",")
		local gapfigsave = subinstr("`gapfigsave'", "save(", "", .)
		local gapfigsave = subinstr("`gapfigsave'", ")", "", .)

		* Set graph export default as .pdf unless other extension is specified
		capture assert strpos("`gapfigsave'", ".") == 0
		if _rc == 0 {
			local gapfigsave = subinstr("`gapfigsave'", "`gapfigsave'", "`gapfigsave'`multisave'.pdf", .)
		}
		if _rc != 0 {
			local _stFigsavename = trim("`gapfigsave'")
			capture assert strpos("`_stFigsavename'", "/") == 0
			if _rc != 0 {
				local _stFigsavename = reverse("`_stFigsavename'")
				local pq = strpos("`_stFigsavename'", "/") - 1
				local q = strpos("`_stFigsavename'", "/") + 1
				local _stFigpath = reverse(substr("`_stFigsavename'", `q', .))
				local _stFigsavename = reverse(substr("`_stFigsavename'", 1, `pq'))
				local _slash "/"
			}
			* Or \
			capture assert strpos("`_stFigsavename'", "\") == 0
			if _rc != 0 {
				local _stFigsavename = reverse("`_stFigsavename'")
				local pq = strpos("`_stFigsavename'", "\") - 1
				local q = strpos("`_stFigsavename'", "\") + 1
				local _stFigpath = reverse(substr("`_stFigsavename'", `q', .))
				local _stFigsavename = reverse(substr("`_stFigsavename'", 1, `pq'))
				local _slash "\"
			}
			gettoken g _stFigsavename : _stFigsavename, parse(".")
			local g "`g'`multisave'`_stFigsavename'"
			local gapfigsave "`_stFigpath'`_slash'`g'"
		}
		local gapfigsave = subinstr("`gapfigsave'", "`gapfigsave'", "graph export `gapfigsave'", .)	

		* Parse the remaining gapfig() string
		if strpos("`gapfigure'", "save") != 0 {
			di as err "The save() option for gapfigure() must be specified to the right of the comma e.g. gapfigure(classic bcorrect, save(filename))"
			exit 198
		}
		foreach s of local gapfigure {
			capture assert "`s'" == "classic" | "`s'" == "bcorrect" | "`s'" == "placebos" | "`s'" == "lineback"
			if _rc != 0 {
				di as err "gapfigure() contains an invalid option specification. Only -classic-, -bcorrect-, -placebos-, and/or -lineback- are allowed. Specifying gapfigure() without an option will be treated as if gapfigure() is not specified"
				exit 198
			}
			local gapfig`s' = 1
		}
		if `gapfigclassic' == 1 & `gapfigbcorrect' == 1 & `gapfigplacebos' == 1 {
			di as err "gapfigure() contains an invalid specification. gapfigure can contain at most two of its -classic-, -bcorrect-, and placebos- at once"
			exit 198
		}
		
		* Ensure bcorrect() is specified if gapfigure(bcorrect) is specified, and pvalues is specified if gapfigure(placebos) is specified
		if `gapfigbcorrect' == 1 {
			capture assert "`bcorrect'" != ""
			if _rc != 0 {
				di as err "gapfigure(`gapfigure') was specified, but the allsynth option bcorrect() was not specified. bcorrect() must be specified as -nosave- or -merge- in order to graph gapfigure(`gapfigure')"
				exit 198
			}
		}
		if `gapfigplacebos' == 1 {
			capture assert "`pvalues'" != ""
			if _rc != 0 {
				di as err "gapfigure(`gapfigure') was specified, but the allsynth option -pvalues- was not specified. -pvalues- must be specified in order to graph gapfigure(`gapfigure')"
				exit 198
			}
			capture assert "`keep'" != ""
			if _rc != 0 {
				di as err "gapfigure(`gapfigure') was specified, but -keep- was not specified. -keep- must be specified in order to graph gapfigure(`gapfigure')"
				exit 198
			}
			if `gapfigclassic' == 1 & "`bcorrect'" != "" {
				di as err "gapfigure(`gapfigure') was specified, but the allsynth option bcorrect() was also specified. When bcorrect() is specified, {cmd:allsynth} will estimate any specified placebo runs as bias-corrected, and cannot graph these together with the classic synthetic control gap. Remove the bcorrect() specification or specify gapfigure(bcorrect placebos)"
				exit 198
			}
			capture assert `gapfigclassic' == 1 | `gapfigbcorrect' == 1
			if _rc != 0 {
				di as err "gapfigure(`gapfigure') was specified, but -placebos- cannot be specified without exactly one of -classic- or -bcorrect- also being specified in gapfigure()"
				exit 198
			}
		}
		
		* Set local if nested is specified (in case nested optimization fails)
		local caploc ""
		if "`nested'" == "nested" {
			local caploc "capture noisily"
		}
		
		* Separate out the replace option from the specified keep() file if both are inside the parentheses
		local kno : list sizeof keep
		if `kno' != 1 {
			gettoken k keep : keep
			local k : subinstr local k "," ""
			local k : subinstr local k ".dta" ""
			local keep : subinstr local keep "," ""
			local keep : subinstr local keep " " "", all
			if "`keep'" == "replace" {
				local replace "replace"
			}
			local keep "`k'"
		}
		
		* Capture actual treated unit
		qui local actreat "`trunit'"
		
		* Initialize flag macro
		local mspe_flag = 0
		
		* Initialize pl_unit macro
		local pl_unit		
		
		* Check if intervention period is among timevar values
		qui levelsof `tvar', local(levt)
		loc checkinput: list trperiod in levt
		if `checkinput' == 0 {
			di as err "`tvar' of treatment is not found in timevar. Check trperiod()"
			exit 198
		}
		
		* Parse the transform() string to separate varlist from transform_type
		capture assert strpos("`transform'", ",") == 0
		if _rc != 0 {
			local pq = strpos("`transform'", ",") - 1
			local q = strpos("`transform'", ",") + 1
			local transtype = substr("`transform'", `q', .)
			local transform = substr("`transform'", 1, `pq')
		}
		
		* Ensure transform() is properly specified if not empty
		if "`transtype'" != "" {
			capture assert "`transform'" != ""
			if _rc != 0 {
				di as err "transform(, `transtype') is specified but no varlist is specified. Specify at least one variable in the data set"
				exit 198
			}
			if _rc == 0 {
				foreach transVar of local transform {
					capture assert `transVar'
					if _rc != 0 {
						di as err "transform(`transform', `transtype') is specified but `transVar' does not exist as a variable in the data set. Specified at least one variable in the data set"
						exit 198
					}
				}
			}
		}

		local transtypedemean = 0
		local transtypenormalize = 0
		foreach s of local transtype {
			capture assert "`s'" == "demean" | "`s'" == "normalize"
			if _rc != 0 {
				di as err "transform() contains an invalid transform_type specification. Only -demean- or -normalize- is allowed"
				exit 198
			}
			local transtype`s' = 1
		}
		if `transtypedemean' == 1 & `transtypenormalize' == 1 {
			di as err "transform() contains an invalid option specification. Exactly one of transform_type -demean- or -normalize- must be specified as: transform(varlist, transform_type)"
			exit 198
		}
		if `transtypedemean' == 1 | `transtypenormalize' == 1 {
			assert "`transform'" != ""
			if _rc != 0 {
				di as err "transform( ,`transtype') is specified but no varlist is provided. Specify at least one variable to transform as transform(varlist, transform_type)"
				exit 198
			}
		}
		
		* Normalize specified variables to final pre-treatment period
		local gaptitle ""
		local gaptitlepct ""
		if `transtypenormalize' != 0 {
			local gaptitle "Normalized"
			local gaptitlepct "(%)"
			local _trperiodM1 = `trperiod' - 1
			foreach normVar of local transform { 
				capture assert `normVar' if `tvar' == `_trperiodM1'
				if _rc != 0 {
					di as err "The variable `normVar' was specified for normalization but is either not found in the data set or is zero in `_trperiodM1' for at least one unit. Remove affected units from the sample or remove `normVar' from varlist in transform()"
					exit 198
				}
				capture assert strpos("`anything'", "`normVar'") != 0
				if _rc != 0 {
					di as err "The variable `normVar' was specified for normalization but is not specified as either an outcome variable or a predictor variable. Remove `normVar' from varlist in normalize(), or add it to the list of predictor variables"
					exit 198
				}
				capture assert strpos("`anything'", "`normVar'(`_trperiodM1')") == 0
				if _rc != 0 {
					di as err "The variable `normVar' was specified for normalization but `normVar'(`_trperiodM1') was specified as a predictor. This is not allowed because `normVar' is being normalized to its `_trperiodM1' values. Remove `normVar'(`_trperiodM1') from the list of predictor variables or remove `normVar' from varlist in transform()"
					exit 198
				}
				di "Normalizing `normVar' to `_trperiodM1' values"
				qui gen _XnormVar = `normVar' if `tvar' == `_trperiodM1'
				bysort `pvar': egen _xXnormVar = max(_XnormVar)
				qui replace `normVar' = 100*`normVar'/_xXnormVar
				drop _XnormVar _xXnormVar
			}
		}
		
		* Demean specified variables
		if `transtypedemean' != 0 {
			local gaptitle "Demeaned"
			local _trperiodM1 = `trperiod' - 1
			foreach dmVar of local transform {
				capture assert `dmVar'
				if _rc != 0 {
					di as err "The variable `dmVar' was specified for de-meaning but is not found in the data set. Remove `dmVar' from varlist in transform()"
					exit 198
				}
				capture assert `dmVar'
				if _rc != 0 {
					di as err "The variable `dmVar' was specified for de-meaning but is not found in the data set. Check transform()"
					exit 198
				}
				capture assert strpos("`anything'", "`dmVar'") != 0
				if _rc != 0 {
					di as err "The variable `dmVar' was specified for normalization but is not specified as either an outcome variable or a predictor variable. Remove `dmVar' from varlist in transform(), or add it to the list of predictor variables"
					exit 198
				}
				di "De-meaning `dmVar'"
				bysort `pvar': egen _XdmVar = mean(`dmVar') if `tvar' < `trperiod'
				bysort `pvar': egen _xXdmVar = max(_XdmVar)
				qui replace `dmVar' = `dmVar' - _xXdmVar
				qui replace `dmVar' = 0.000001 if `dmVar' == 0
				drop _XdmVar _xXdmVar
			}
		}
		
		* Continue if bias-correction option specified
		if "`bcorrect'" != "" | "`pvalues'" != "" {

			* Preserve original user inputs for -synth- command
			foreach u of local inputlist {
				qui local `u'local ``u''
			}	
						
			***** Check Remaining User Inputs

			*** Treated and control unit ID numbers

			* Confirm treated unit is in panelvar
			qui levelsof `pvar', local(levp)
			loc checkinput: list trunit in levp
			if `checkinput' == 0 {
				di as err "Treated unit is not found in panelvar. Check tr()"
				exit 198
			}

			*** Get control units ID numbers

			* If user does not specify co(), use all units in pvar except the one in tr()
			if "`counit'" == "" {
				local counit : subinstr local levp "`trunit'" " ", all word
			}
			
			* Identify donor pool
			qui gen dXonor_pooL = 0
			di
			di "Identifying donor pool..."
			di
			foreach dU of local counit {
				qui replace dXonor_pooL = 1 if `pvar' == `dU'
			}
			
			* Else check if all user supplied co() units are found in panelvar
			else {
				loc checkinput: list counit in levp
				if `checkinput' == 0 {
					di as err "At least one control unit is not found in panelvar. Check co()"
					exit 198
				}

				* Check if treated unit is among the specified control units
				loc checkinput: list trunit in counit
				if `checkinput' == 1 {
					di as err "Treated unit appears among user-specified control units. Check co() and tr()"
					exit 198
				}
			}

			* If panelvar has labels, grab them
			local clab: value label `pvar'

			* If unitname is specified, grab the label
			if "`unitnames'" != "" {

				* Check if var exists
				capture confirm string var `unitnames'
				if _rc {
					di as err "`unitnames' does not exist as a (string) variable in dataset"
					exit 198
				}
				
				* Check if it has a value for all units
				tempvar pcheck
				qui egen `pcheck' = sd(`pvar') , by(`unitnames')
				qui sum `pcheck'
				if r(sd) != 0 {
					di as err "`unitnames' varies within units of `pvar' - revise unitnames variable "
					exit 198
				}
				local clab "`pvar'"
				qui gen index = _n
				
				* Label the pvar accoringly
				foreach i in `levp' {
					qui su index if `pvar' == `i', meanonly
					local label = `unitnames'[`r(max)']
					local value = `pvar'[`r(max)']
					qui label define `clab' `value' `"`label'"', modify
				}
				label value `pvar' `clab'
			}
				
			* Grab treated label for figure and control unit names
			if "`clab'" != "" {
				local tlab: label `clab' `trunit' , strict
				foreach i in `counit' {
					local label : label `clab' `i'
					local colabels `"`colabels', `label'"'
				}
				local colabels : list clean colabels
				local colabels : subinstr local colabels "," ""
				local colabels : list clean colabels
			}
			if "`tlab'" == "" {
				local tlab "treated unit"
			}

			***** Build the pre-treatment period
			
			* By default, minimum of time var up to intervention (exclusive) is pre-treatment period
			qui levelsof `tvar' if `tvar' < `trperiod' , local(preperiod)

			* Set xperiod (over which all predictors are averaged) to whole pre-period if not user-specified
			if "`xperiod'" == "" {
				numlist "`preperiod'" , min(1) integer sort
				local xperiod "`r(numlist)'"
			}
			
			* Otherwise, check whether user-specified xperiod is among timevar
			else {
				loc checkinput: list xperiod in levt
				if `checkinput' == 0 {
					di as err "at least one time `tvar' specified in xperiod() not found in timevar"
					exit 198
				}
			}

			* Set mspeperiod (over which all loss is minimized) to whole pre-period if not user-specified
			if "`mspeperiod'" == "" {
				numlist "`preperiod'" , min(1) integer sort
				local mspeperiod "`r(numlist)'"
			}
			* Otherwise, check if user-specified mspeperiod is among timevar
			else {
				loc checkinput: list mspeperiod in levt
				if `checkinput' == 0 {
					di as err "at least one time `tvar' specified in mspeperiod() not found in timevar"
					exit 198
				}
			}

			* Set resultsperiod (over which results are plotted) to whole treated-period if not user-specified
			if "`resultsperiod'" == "" {
				numlist "`levt'" , min(1) integer sort
				local resultsperiod "`r(numlist)'"
			}
			* Otherwise, check if user-specified mspeperiod is among timevar
			else {
				loc checkinput: list resultsperiod in levt
				if `checkinput' == 0 {
					di as err "at least one time `tvar' specified in resultsperiod() not found in timevar"
					exit 198
				}
			}
			
			* Duplicate the anything macro
			local everything `anything'
			
			* Get dependent variable
			gettoken ordvar everything: everything
			capture confirm numeric var `ordvar'
			if _rc {
				di as err "`ordvar' does not exist as a (numeric) variable in dataset"
				exit 198
			}
			
			* Replace abbreviated ordvar name if it is abbreviated
			unab var : `ordvar'
			local anything = subinstr("`anything'", "`ordvar' ", "`var' ", 1)
			local ordvar "`var'"
			
			/* Ensure there are no duplicates in the list of predictors
			local everything2 "`everything'"
			local evsize : list sizeof everything2
			local everything
			while `evsize' > 0 {
				gettoken predvar everything2: everything2
				capture assert regexm("`everything2'", "`predvar'") == 0
				if _rc == 0 {
					local everything "`everything' `predvar'"
				}
				local evsize = `evsize' - 1
			}
			local anything "`ordvar'`everything'"
			local anything2 "`anything'"*/

			* Check at least one predictor variable is specified
			if "`everything'" == "" {
				di as err "No predictor variables specified. Supply at least one predictor variable"
				exit 198
			}
			
			/******* Temporarily rename control variables to allow for long names
			local xthing
			local ything
			
			* Capture unique variable lists and separate period specifications
			foreach v of local anything {
				local p = strpos("`v'", "(") - 1
				if `p' != -1 {
					local q = strpos("`v'", "(")
					local vapp = substr("`v'", `q', .)
					local v = substr("`v'", 1, `p')
					capture assert `v'
					if _rc == 0 {
						local xthing "`xthing' `v'"
						local ything "`ything' `vapp'"
					}
				}
				if `p' == -1 {
					local xthing "`xthing' `v'"
					local ything "`ything' (NO)"
				}
			}
			
			* Rename the dependent variable and update the xthing local
			gettoken dvar: xthing
			local dvar2 = substr("`dvar'", 1, 8)
			local xthing = subinword("`xthing'", "`dvar'", "`dvar2'_Y", .)
			rename `dvar' `dvar2'_Y

			* Rename variables and create new version of xthing local with new names
			local j = 0
			local zthing "`xthing'"
			foreach v of local xthing {
				if "`v'" != "`dvar2'_Y" {
					local j = `j' + 1
					local v2 = substr("`v'", 1, 8)
					local zthing = subinword("`zthing'", "`v'", "`v2'_X`j'", .)
					capture assert `v'
					if _rc == 0 {
						qui rename `v' `v2'_X`j'
					}
				}
			}

			* Re-define the anything local with the new variable names
			local ct: word count `zthing'
			local listthing
			while `ct' > 0 {
				gettoken a zthing: zthing
				gettoken b ything: ything
				local listthing "`listthing' `a'`b'"
				local ct = `ct' - 1
			}
			local anything = subinstr("`listthing'", "(NO)", "", .)*/
			
			* Get dependent variable with new name and re-define the everything local
			gettoken dvar everything: anything
			capture confirm numeric var `dvar'
			if _rc {
				di as err "`dvar' does not exist as a (numeric) variable in dataset"
				exit 198
			}
			
			* Check at least one predictor variable is specified
			if "`everything'" == "" {
				di as err "No predictor variables specified. Please supply at least one predictor variable"
				exit 198
			}
				
			*** Create X matrices

			* Create empty storage matrices for treated and controls
			local trno : list sizeof trunit
			local cono : list sizeof counit
			local indvarsno : list sizeof everything
			qui mata: emptymat(`trno')
			mat `Xtr' = emat
			qui mata: emptymat(`cono')
			mat `Xco' = emat
			
			* Confirm there are at least K + 2 control units for K predictor variables
			local conocheck = `cono' - `indvarsno'
			if `conocheck' <= 1 & "`bcorrect'" != "" {
				di as err "Not enough control units to complete de-bias procedure given the given the specified number of predictors, K. Please supply at least K + 2 control units"
				exit 198
			}
			
			* Confirm 
			if "`everything'" == "" {
				di as err "No predictor variables specified. Please supply at least one predictor variable"
				exit 198
			}
			
			* Begin variable construction
			while "`everything'" != "" {

				* Get token
				gettoken p everything: everything, bind

				* Check if there is an open paranthesis in this particular token
				local whereq = strpos("`p'", "(")
				
				* If not, token is just a varname; so check whether it is a (numeric) variable
				if `whereq' == 0 {
					capture confirm numeric var `p'
					
					if _rc {
						di as err "`p' does not exist as a (numeric) variable in dataset"
						exit 198
					}
					
					* Get the variable
					unab var: `p'
					
					* Replace abbreviated varname in anything macro
					local anything = subinstr("`anything'", " `p'", " `var'", 1)
					
					* Use xperiod for time (user-defined or default)
					local xtime "`xperiod'"
					
					* Set empty label for regular time period
					local xtimelab ""
				}
				
				* If yes, token is varname plus time. Disentangle the two
				else {
					
					* Get variable
					local var = substr("`p'",1,`whereq'-1)
					unab var2: `var'
					
					* Replace abbreviated varname in p and anything macros
					local p = subinstr("`p'", "`var'", "`var2'", 1)
					local anything = subinstr("`anything'", " `var'(", " `var2'(", .)
					local whereq = strpos("`p'", "(")
					
					* Confirm it's numeric
					qui capture confirm numeric var `var'
					if _rc {
						di as err "`var' does not exist as a (numeric) variable in dataset"
						exit 198
					}
					
					* Get the time token
					local xtime = substr("`p'",`whereq'+1,.)
					
					* Allow "/" numlist convention
					local xtime = subinstr("`xtime'", "/", "(1)", .)
					
					* Save time token to use for label (and varnames for bias-correction regression)
					local xtimelab `xtime'
					local xtimelab : subinstr local xtimelab " " "", all
					local xtimelab : subinstr local xtimelab "(" "_", all
					local xtimelab : subinstr local xtimelab ")" "_"
					local xtimelab : subinstr local xtimelab ")" ""

					* Check whether there is a second opening paranthesis (if this is a numlist)
					local wherep = strpos("`xtime'", "(")
					
					* If no second opening parenthesis, delete potential &s and the closing parenthesis
					if `wherep' == 0 {
						local xtime : subinstr local xtime "&" " ", all
						local xtime : subinstr local xtime ")" " ", all
					}
					
					* If yes, this is a numlist. Remove both closing parantheses, then put first back in
					else {
						local xtime : subinstr local xtime ")" " ", all
						local xtime : subinstr local xtime " " ")"
					}
				
					* Observe the individual integer elements of the numlist sorted smallest to largest
					numlist "`xtime'" , min(1) integer sort
					local xtime "`r(numlist)'"
					
					* Confirm user-supplied xtime period (xperiod) is a value of timevar
					loc checkinput: list xtime in levt
					if `checkinput' == 0 {
						di as err "For predictor `var', some specified `tvar's are not found in panel timevar"
						exit 198
					}
				}

				****** Average over xtime period for variable var
				
				*** Controls

				* Define subsample. Just control units and periods from xtime()
				qui reducesample, tno("`xtime'") uno("`counit'") genname(`subsample')

				* Aggregate over periods
				agmat `Xcotemp', cvar(`var') opstat("mean") sub(`subsample') ulabel("control units") checkno(`cono') tilab("`xtimelab'")

				*** Treated
				
				* Define subsample just treated unit and xtime() periods
				qui reducesample , tno("`xtime'") uno("`trunit'") genname(`subsample')

				* Aggregate over periods
				agmat `Xtrtemp' , cvar(`var') opstat("mean") sub(`subsample') ulabel("treated unit") checkno(`trno') tilab("`xtimelab'")

				* Name matrices
				if "`xtimelab'" == "" {
					mat coln `Xcotemp' = "`var'_xperiodmean"
					mat coln `Xtrtemp' = "`var'_xperiodmean"
				}
				else {
					mat coln `Xcotemp' = "`var'_`xtimelab'"
					mat coln `Xtrtemp' = "`var'_`xtimelab'"
				}

				* Take the final variable and cbind it to the store matrix
				mat `Xtr' = `Xtr',`Xtrtemp'
				mat `Xco' = `Xco',`Xcotemp'
			} 
				
			*** Close the while loop through the everything string

			* Rownames for final X matrixes
			mat rown `Xco' = `counit'
			mat rown `Xtr' = `trunit'

			* Transpose
			mat `Xtr' = (`Xtr')'
			mat `Xco' = (`Xco')'
			
			* Create ID matrix
			mat Xid = [`trunit']
			foreach i of local counit {
				mat Xid = Xid\[`i']
			}
			
			* Combine for bias-correction
			mat Xbc = `Xtr',`Xco'
			mat Xbc = Xbc'
			mat Xbc = Xid, Xbc
			
			* Gather treated and included control units in a single macro
			local counit : subinstr local counit "  " "", all
			local units "`trunit' `counit'"
			
			* Only run through for the treated unit if pvalues is not specified
			if "`pvalues'" == "" {
				local units `trunit'
			}
			local uno : list sizeof units
			local counitlist : subinstr local counit " " ",", all
			
			* Set macros
			tempvar Xbcx
			qui egen `Xbcx' = min(`tvar')
			qui local firstper = `Xbcx'
			qui drop `Xbcx'
			tempvar Xbcx
			qui egen `Xbcx' = max(`tvar')
			qui local lastper = `Xbcx'
			qui drop `Xbcx'
			qui distinct(`pvar') if `pvar' == `trunit'
			qui local n1 = r(ndistinct)
			local n0 : list sizeof counit
			*qui distinct(`pvar') if inlist(`pvar', `counitlist')
			*qui local n0 = r(ndistinct)
			local idfirst : word 1 of `units'
			qui levelsof `tvar', local(tvars)
			local trtvars `tvars'
			while "`trvars'" != "`trperiod'" {
				qui gettoken trvars trtvars : trtvars
			}
			local trtvars `trvars'`trtvars'
			local T : list sizeof tvars
			local T1 : list sizeof trtvars
			local T0 = `T' - `T1'			
			
			* Save the Xbc matrix as variables
			qui tempfile core2
			qui save "`core2'", replace
			qui clear
			qui svmat Xbc, names(matcol)
			
			* Rename the predictor variables
			foreach v of varlist _all {
				local vname : subinstr local v "Xbc" ""
				qui rename `v' `vname'
			}
			qui rename c1 `pvar'
			
			* Save the predictor variables in a macro and get the number for sparsity analysis
			local predvars
			foreach v of varlist _all {
				if "`v'" != "`pvar'" {
					local predvars "`predvars' `v'"
				}
			}
			local predno : list sizeof predvars
			
			* Merge with the original data
			qui tempfile Xbc
			qui save "`Xbc'", replace
			qui use "`core2'", clear
			qui merge m:1 `pvar' using `Xbc', nogen norep
			
			***** Run the synthetic control estimation and bias-correction regressions
			
			* Capture control units
			qui local unitsdup `units'
			qui local counit `units'

			* Get token
			gettoken unitid : counit
			
			*** Run across all intended units
			local zz ""
			local d = 1
			foreach i of local units {
				gettoken j counit : counit
				local trunit `i'
				
				* Reset the data for each run
				if `i' != `actreat' {
					qui use "`core'", clear
				}
				tempfile core
				qui save "`core'", replace

				* Re-populate user-specified options with user inputs
				foreach u of local inputlist {
					if !inlist("`u'", "", "keep", "counit", "customv") {
						qui local `u' "`u'(``u'local')"
					}
					if "`u'" == "customv" & "`nested'" == "" {
						qui local `u' "`u'(``u'local')"
					}
					if "`u'" == "keep" & "`placeboskeep'" == "" & "`i'" == "`trunit'" {
						qui local `u' "`u'(``u'local')"
					}
					if "`u'" == "keep" & "`placeboskeep'" == "" & "`i'" != "`trunit'" {
						qui local `u' ""
					}
					if "`u'" == "keep" & "`placeboskeep'" != "" {
						qui local `u' "`u'(``u'local'_`pvar'_`i')"
					}
				}
			
				* Display message and set macros
				if `trunit' == `actreat' & "`bcorrect'" != "" {
					local qu ""
					di 
					di 
					di "Bias-correcting the plain vanilla -synth- estimate for `pvar' `actreat'"
					di 
				}
				if `trunit' != `actreat' {
					local qu "qui"
					local caploc "capture"
				}
				local treatfig ""
				
				* Run the synthetic control and capture the weights
				#delimit ;
					`caploc' synth 
						`anything', 
						trunit(`trunit') 
						trperiod(`trperiod') 
						counit(`counit')
						`xperiod'
						`mspeperiod'
						`resultsperiod' 
						`unitnames'
						`treatfig' 
						`keep' 
						`replace'
						`customv'
						`margin'
						`maxiter'
						`sigf'
						`bound'
						`nested'
						`allopt';
					#delimit cr

				* If nested optimization was specified and failed, run without nesting for control units only
				if _rc != 0 /*== 504*/ & "`trunit'" == "`actreat'" {
					local rc = _rc
					di as err "Nested optimization failed for treated unit `pvar' == `trunit'.  Re-specify or attempt without -nested- option"
					exit `rc'
				}
				local pl_rc = 0
				if _rc != 0 /*== 504*/ & "`trunit'" != "`actreat'" {
					local pl_rc = _rc
					local pl_unit = "`pl_unit' `trunit'"
					di as err "Nested optimization failed for placebo run `pvar' == `trunit'. Calculating W-matrix using default V-matrix"
					#delimit ;
						`caploc' synth 
							`anything', 
							trunit(`trunit') 
							trperiod(`trperiod') 
							counit(`counit')
							`xperiod'
							`mspeperiod'
							`resultsperiod' 
							`unitnames'
							`treatfig' 
							`keep' 
							`replace'
							`customv'
							`margin'
							`maxiter'
							`sigf'
							`bound'
							`allopt';
						#delimit cr
				}
				
				qui mat Y_t_`i' = e(Y_treated)
				qui mat Y_s_`i' = e(Y_synthetic)
				qui mat gap_`i' = Y_t_`i' - Y_s_`i'
				qui mat w = e(W_weights)
				forval w = 1/`n0' {
					if `w' == 1 {
						qui mat W = w[`w',2]
					}
					if `w' != 1 {
						qui mat W = W\w[`w',2]
					}
					if `w' == `n0' {
						qui mat W = W'
					}
				}
				
				* Save the ereturn matrices
				mat X_b = e(X_balance)
				mat _eRMSPE = e(RMSPE)
				mat _eV_matrix = e(V_matrix)
				mat _eX_balance = e(X_balance)
				mat _eW_weights = e(W_weights)
				mat _eY_synthetic = e(Y_synthetic)
				mat _eY_treated = e(Y_treated)
				
				* Identify positively-weighted donors if bcorrect() option -posonly- is specified
				local aW ""
				if `bcorrectposonly' == 1 {
					qui mat C_Ww = e(W_weights)
					tempfile posonly_O
					qui save "`posonly_O'", replace
					qui clear
					qui svmat C_Ww, names(v)
					qui rename v1 `pvar'
					qui gen poswt = (v2 > 0) + 0.0001*(v2 == 0)
					qui levelsof `pvar' if v2 > 0
					qui keep `pvar' poswt
					tempfile posonly_W
					qui save "`posonly_W'", replace
					qui use "`posonly_O'", clear
					qui merge m:1 `pvar' using "`posonly_W'", nogen norep
					qui recode poswt (.=0)
					local aW "[aw=poswt]"
				}
				
				* Run-time warning
				if `bcorrectridge' == 1 | `bcorrectlasso' == 1 | `bcorrectelastic' == 1 {
					di ""
					di "Estimating the bias from inexact matching on predictor variables using one of ridge, lasso, or elastic net regression. This may take a long time...
					di ""
				}
				
				* Predict the outcomes given predictor values for all included units
				qui gen pred_y = .
				local y_bc_list ""
				foreach y of local tvars {
					/*local predvars2
					foreach v of local predvars {
						capture assert "`v'" != "outcome_var_`y'_"
						if _rc == 0 {
							local predvars2 "`predvars2' `v'"
						}
					}*/
					local predvars2 "`predvars'"
					qui `bcorreg' `dvar' `predvars2' if dXonor_pooL == 1 & `tvar' == `y' `aW'
					qui predict pred_y_`y'
					qui replace pred_y = pred_y_`y' if `tvar' == `y'
					qui drop pred_y_`y'
					local y_bc_list "`y_bc_list' y_bc`y'"
				}
				
				* Calculate bias-corrected outcomes
				qui gen y_bc = `dvar' - pred_y

				* Put in matrices
				qui keep y_bc `pvar' `tvar'
				qui reshape wide y_bc, i(`pvar') j(`tvar')
				qui mkmat `y_bc_list' if `pvar' == `trunit', matrix(Y1)
				qui mkmat `y_bc_list' if `pvar' != `trunit', matrix(Y0)

				* Apply the synthetic control weights to the bias-corrected outcomes for the donor pool
				forval q = 1/`T' {	
					qui local y : word `q' of `tvars'
					forval r = 1/`n0' {
						if `r' == 1 {
							qui mat Y0_`q' = Y0[`r',`q']
						}
						if `r' != 1 {
							qui mat Y0_`q' = Y0_`q'\Y0[`r',`q']
						}
						if `r' == `n0' {
							qui mat Yhat_`y' = W*Y0_`q'
						}
					}
					if `q' == 1 {
						qui mat Yhat = Yhat_`y'
						qui mat `pvar' = [`i']
						qui mat `tvar' = [`y']
					}
					if `q' != 1 {
						qui mat Yhat = Yhat\Yhat_`y'
						qui mat `pvar' = `pvar'\[`i']
						qui mat `tvar' = `tvar'\[`y']
					}
				}
				qui mat Y1 = Y1'
				if `i' == `actreat' {
					mat bcorrfig = Y1,Yhat,`tvar'
				}

				* Calculate the bias-corrected synthetic control "gap" for treated unit and placebo runs (if pvalues specified)
				mat gap_bc_`i' = Y1 - Yhat
				mat gap_bc_`i' = [`pvar',`tvar',gap_`i',gap_bc_`i']
				if "`bcorrect'" == "merge" {
					mat gap_bc_`i' == [Y1,Yhat,gap_bc_`i']
				}
				
				* Check if the predictors of the treated unit fall within the convex hull of those of the donor pool
				qui mat X_d = X_b[1..`predno',1] - X_b[1..`predno',2]
				qui mat Xd = X_d'
				qui mat XX = Xd*X_d
				qui clear
				qui svmat XX, names(x)
				local chzero = x1
				
				* Identify if weighting matrix of actually-treated unit is sparse
				if `trunit' == `actreat' {
					qui clear
					mat Wzeros = W'
					qui svmat Wzeros, names(w)
					qui gen x = (w1 != 0)
					qui egen nonzerows = total(x)
					qui keep if _n == 1
					local nonzerows = nonzerows
					
					* Identify if W-matrix is likely unique
					mat uW = J(`tsize',1,0)
					if (`predno' >= `nonzerows') & `chzero' != 0 {
						mat uW = J(`tsize',1,1)
					}
				}
			
				*Display messages
				if "`zz'" == "`actreat'"  & "`bcorrect'" != "" & "`pvalues'" == "" {
					di ""
					di "Applying bias-correction procedure to -synth- estimates...
					di ""
				}
				if "`zz'" == "`actreat'" & "`pvalues'" != "" {
					di ""
					di "Estimating synthetic controls using in-space placebo treatments for treated unit `pvar' == `actreat'. This could take awhile...
					di ""
				}
				if `trunit' != `actreat' {
					di "`d' of `n0' (donor pool unit `pvar' == `i' for treated unit `pvar' == `actreat')"
					local d = `d' + 1
				}
				
				* Replace the treated unit at the end of the counit macro
				local zz `i'
				local counit `counit' `i'
			}
			di
			di "Saving results..."
					
			* Reset the treated unit to the actually treated unit
			local trunit = `actreat'
			
			* Set the placement of the dotted vertical line 
			local trpm1 = `trperiod' - `gapfiglineback'
			
			* Graph figure, if specified
			if "`figure'" == "figure" {
				qui clear
				mat classicfig = Y_t_`actreat',Y_s_`actreat',`tvar'
				qui svmat classicfig, names(v)
				format v3 `_tVarformat'
				#delimit ;
					twoway 
						(line v1 v3, lcolor(black)) 
						(line v2 v3, lpattern(dash) lcolor(black)), 
						ytitle("`gaptitle' `ordvar' `gaptitlepct'") 
						xtitle("`tvar'") 
						xline(`trpm1', lpattern(shortdash) lcolor(black))
						legend(label(1 "`tlab'") label(2 "synthetic `tlab'"))
						name(classic_sc);
					#delimit cr
			}
			
			* Graph bcorrect(figure), if specified
			if `bcorrectfigure' == 1 {
				qui clear
				qui svmat bcorrfig, names(v)
				format v3 `_tVarformat'
				#delimit ;
					twoway 
						(line v1 v3, lcolor(black)) 
						(line v2 v3, lpattern(dash) lcolor(black)), 
						ytitle("`gaptitle' `ordvar' `gaptitlepct'") 
						xtitle("`tvar'") 
						xline(`trpm1', lpattern(shortdash) lcolor(black))
						legend(rows(2) label(1 "`tlab', bias-corrected") label(2 "synthetic `tlab', bias-corrected"))
						name(bias_corrected_sc);
					#delimit cr
			}
			
			* Save the matrices to a data set
			tempfile core2
			foreach i of local units {
				qui clear
				mat gap_bc_`i' = gap_bc_`i',uW
				qui svmat gap_bc_`i', names(v)
				if "`bcorrect'" == "nosave" | "`bcorrect'" == "" {
					qui rename v1 `pvar'
					qui rename v2 `tvar'
					format `tvar' `_tVarformat'
					qui rename v3 gap
					qui rename v4 gap_bc
					qui rename v5 unique_W
				}
				if "`bcorrect'" == "merge" {
					qui rename v1 _Y_treated_bc
					qui rename v2 _Y_synthetic_bc
					qui rename v3 `pvar'
					qui rename v4 `tvar'
					format `tvar' `_tVarformat'
					qui rename v5 gap
					qui rename v6 gap_bc
					qui rename v7 unique_W
				}
				if `i' == `idfirst' {
					qui save "`core2'", replace
				}
				if `i' != `idfirst' {
					qui append using "`core2'"
					qui save "`core2'", replace
				}
			}
			
			* Save trunit (and avgweights) to dataset if stacked() is specified
			if "`stacked'" != "" {
				qui gen trunit = `actreat'
				qui gen trperiod = `trperiod'
				if "`_stAvgweights'" != "" {
					qui gen _stAvgweights = `avgweights'
				}
			}

			*** Calculate the RMSPEs and RMSPE p-values
			if "`pvalues'" != "" {
				
				* Generate the RMSPE for T
				qui gen rmspe = .
				qui levelsof(`pvar'), local(id)
				bysort `tvar': gen N = _N
				foreach i of local id {
					qui egen xpre = total(gap^2) if `tvar' < `trperiod' & `pvar' == `i'
					qui gen xpre2 = xpre/`T0'
					qui egen mspe_pre = max(xpre2) if `pvar' == `i'
					qui drop x*
					
					* Treated period
					foreach tt of local trtvars {
						qui egen xpost2 = mean(gap^2) if inrange(`tvar', `trperiod', `tt') & `pvar' == `i'
						qui egen mspe_post_`tt' = max(xpost2) if `pvar' == `i'
						qui replace rmspe = mspe_post_`tt'/mspe_pre if `pvar' == `i' & `tvar' == `tt'
						qui drop x* mspe_post_`tt'
					}
					qui drop mspe*
				}
				
				* Generate RMSPE-ranked p-values
				qui gsort `tvar' -rmspe
				bysort `tvar': gen rmspe_rank = _n  if `tvar' >= `trperiod'
				qui gen p = rmspe_rank/N if `tvar' >= `trperiod'
				qui order `pvar' `tvar' gap rmspe* p N
				
				* Calculate the bias-corrected RMSPE and p-values
				if "`bcorrect'" != "" {
			
					* Generate the bias-corrected RMSPE for T
					qui gen rmspe_bc = .
					qui levelsof(`pvar'), local(id)
					foreach i of local id {
						qui egen xpre = total(gap_bc^2) if `tvar' < `trperiod' & `pvar' == `i'
						qui gen xpre2 = xpre/`T0'
						qui egen mspe_pre = max(xpre2) if `pvar' == `i'
						qui drop x*
						
						* If the pre-period bias-corrected MSPE = 0 (e.g. because all pre-period outcomes are specified as predictors), set to 1
						if mspe_pre == 0 {
							local mspe_flag = 1
						}
						qui recode mspe_pre (0=1)

						* Treated period
						foreach tt of local trtvars {
							qui egen xpost2 = mean(gap_bc^2) if inrange(`tvar', `trperiod', `tt') & `pvar' == `i'
							qui egen mspe_post_`tt' = max(xpost2) if `pvar' == `i'
							qui replace rmspe_bc = mspe_post_`tt'/mspe_pre if `pvar' == `i' & `tvar' == `tt'
							qui drop x* mspe_post_`tt'
						}
						qui drop mspe*
					}

					* Generate RMSPE-ranked p-values
					qui gsort `tvar' -rmspe_bc
					bysort `tvar': gen rmspe_bc_rank = _n if `tvar' >= `trperiod'
					qui gen p_bc = rmspe_bc_rank/N if `tvar' >= `trperiod'
					qui order `pvar' `tvar' gap gap_bc rmspe* p p_bc N
				}
			}
					
			* If bcorrect() is specified as -merge-, combine results into one file
			if "`bcorrect'" == "merge" {
				di
				di "Combining data files"
				qui label var _Y_treated_bc "Bias-corrected treated outcome. Only useful for calculating the gap"
				qui label var _Y_synthetic_bc "Bias-corrected synthetic outcome. Only useful for calculating the gap"
				if "`placeboskeep'" != "" {
					tempfile ests
					qui save "`ests'", replace
					foreach i of local units {
					
						* Drop observations with missing _time from the unit-specific keep files
						qui use "`keeplocal'_`pvar'_`i'.dta", clear
						qui drop if mi(_time)
						qui save "`keeplocal'_`pvar'_`i'.dta", replace
						
						* Merge
						qui use "`ests'", clear
						qui rename `tvar' _time
						qui keep if `pvar' == `i'
						qui sort `pvar' _time
						qui merge 1:1 _time using "`keeplocal'_`pvar'_`i'.dta", nogen norep
						qui order `pvar' _time gap gap_bc rmspe* p p_bc N _Co_Number _W_Weight _Y_treated* _Y_synthetic*
						if `i' != `idfirst' {
							qui append using "`keeplocal'"
						}
						qui save "`keeplocal'", `replace'
						qui erase "`keeplocal'_`pvar'_`i'.dta"
					}
				}
				if "`placeboskeep'" == "" {
					qui rename `tvar' _time
					qui keep if `pvar' == `actreat'
					qui sort `pvar' _time 
					qui merge 1:m _time using `keeplocal', nogen norep
					qui order `pvar' _time gap gap_bc _Co_Number _W_Weight _Y_treated* _Y_synthetic*
				}
				
				* Save and adjust for display
				capture save "`keeplocal'", `replace'
				qui rename _time `tvar'
				qui drop _Co_Number _W_Weight _Y_*
			}
			if "`placeboskeep'" != "" & ("`bcorrect'" == "nosave" | "`bcorrect'" == "") {
				tempfile ests
				qui save "`ests'", replace
				foreach i of local units {
					
					* Drop observations with missing _time from the unit-specific keep files
					qui use "`keeplocal'_`pvar'_`i'.dta", clear
					qui drop if mi(_time)
					qui save "`keeplocal'_`pvar'_`i'.dta", replace
						
					* Merge
					qui use "`ests'", clear
					qui rename `tvar' _time
					qui keep if `pvar' == `i'
					qui sort `pvar' _time
					qui merge 1:1 _time using "`keeplocal'_`pvar'_`i'.dta", nogen norep
					qui order `pvar' _time gap rmspe rmspe_rank p N _Co_Number _W_Weight _Y_treated _Y_synthetic
					if `i' != `idfirst' {
						qui append using "`keeplocal'"
					}
					qui save "`keeplocal'", `replace'
					qui erase "`keeplocal'_`pvar'_`i'.dta"
				}
				tempfile ests
				qui save "`ests'", replace
				qui drop *_bc*
				qui save "`keeplocal'", `replace'
				qui use "`ests'", clear
				
				* Adjust for display
				qui rename _time `tvar'
				qui drop _Co_Number _W_Weight _Y_*
			}
					
			* Return results
			qui save "`core2'", replace
			ereturn clear
			ereturn mat Y_treated _eY_treated
			ereturn mat Y_synthetic _eY_synthetic
			ereturn mat W_weights _eW_weights
			ereturn mat X_balance _eX_balance
			ereturn mat V_matrix _eV_matrix
			ereturn mat RMSPE _eRMSPE
			mat unW = uW[1,1]
			mat colnames unW = Unique_W
			ereturn mat unique_W unW
			keep if `pvar' == `trunit'
			if "`placeboskeep'" == "" & "`bcorrect'" != "" {
				mkmat gap gap_bc, mat(gaps)
				mat colnames gaps = Gap BCorr_Gap
				mat rownames gaps = `_t'
				ereturn mat gaps gaps
				mkmat `tvar' gap gap_bc, mat(results)
				mat results = results,uW
				mat colnames results = `tvar' Gap BCorr_Gap Unique_W
				mat rownames results = `_t'
				ereturn mat results results
			}
			if "`placeboskeep'" != "" & "`bcorrect'" == "" {
				mkmat gap, mat(gaps)
				mat colnames gaps = Gap
				mat rownames gaps = `_t'
				ereturn mat gaps gaps
				mkmat p, mat(pvalues)
				mat colnames pvalues = RMSPE_p
				mat rownames pvalues = `_t'
				ereturn mat pvalues pvalues
				mkmat `tvar' gap p, mat(results)
				mat results = results,uW
				mat colnames results = `tvar' Gap RMSPE_p Unique_W
				mat rownames results = `_t'
				ereturn mat results results
			}
			if "`placeboskeep'" != "" & "`bcorrect'" != "" {
				mkmat p p_bc, mat(pvalues)
				mat colnames pvalues = RMSPE_p BCorr_RMSPE_p
				mat rownames pvalues = `_t'
				ereturn mat pvalues pvalues
				mkmat `tvar' gap p gap_bc p_bc, mat(results)
				mat results = results,uW
				mat colnames results = `tvar' Gap RMSPE_p BCorr_Gap BCorr_RMSPE_p Unique_W
				mat rownames results = `_t'
				ereturn mat results results
			}
			qui use "`core2'", clear
			
			* Drop *_bc* results if bcorrect() not specified
			if "`bcorrect'" == "" {
				qui drop *_bc*
			}
			
			* Drop trunit, trperiod and avgweights from display
			capture assert trunit
			if _rc == 0 {
				qui drop trunit trperiod
			}
			capture assert _stAvgweights
			if _rc == 0 {
				qui drop _stAvgweights 
			}
			* Display results
			di ""
			di "Treated unit (`pvar' == `trunit') results:"
			di ""
			list if `pvar' == `trunit'
			
			* Prepare gapfigure() graph if specified
			if "`gapfigure'" != "" {
				graphgaps, tvar(`tvar') pvar(`pvar') figure(`gapfigure') trperiod(`trperiod') tvarformat(`_tVarformat') actreat(`actreat') tlab(`tlab') gaptitle(`gaptitle') gaptitlepct(`gaptitlepct') gftwopts(`gftwopts') figuresave(`gapfigsave') figurereplace(`gapfigsavereplace')
			}
			
			* Indicate if bias-corrected pre-treatment MSPE was 0 (and thus set to 1)
			if "`pvalues'" != "" & `mspe_flag' == 1 {
				di ""
				di "{hline}"
				di as err "Warning: bias-corrected pre-treatment MSPE was 0 because the set of predictors included pre-treatment outcomes for all pre-treatment `tvar's."
				di ""
				di " Bias-corrected pre-treatment MSPE adjusted to 1. rmspe_bc is now the MSPE at each t > T0"
				di ""
				di "{hline}"
			}
			
			* Indicate if treated-unit weighting matrix is not sparse or not unique
			if (`nonzerows' > `predno') & `chzero' != 0 {
				di ""
				di "{hline}"
				di as err "Warning: the -synth- weighting matrix W for treated unit (`pvar' == `actreat') contains more non-zero weights than predictor variables and is likely not unique. Consider adjusting the number of predictor variables or appropriately restricting the donor pool"
				di ""
				di "{hline}"
			}
			if `chzero' == 0 {
				di ""
				di "{hline}"
				di as err "Warning: the vector of predictor variables for treated unit (`pvar' == `actreat') falls within the convex hull of the columns of the matrix of predictors for the donor pool. The -synth- weighting matrix W is not unique. Consider adjusting the number of predictor variables or appropriately restricting the donor pool"
				di ""
				di "{hline}"
			}
			
			* Indicate if nested optimization failed for one or more of the placebo runs, and was replaced by non-nested optimization
			if `pl_rc' != 0 {
				di ""
				di "{hline}"
				di as err "Note: Nested optimization failed for placebo run(s) `pvar' == (`pl_unit'). Synthetic control W-matrix calculated using default V-matrix for the placebo runs for `pvar' == (`pl_unit')"
				di ""
				di "{hline}"
			}
		}
		
		*** Otherwise, proceed with standard -synth- command
		if "`bcorrect'" == "" & "`pvalues'" == "" {
			di ""
			di "{hline}"
			di ""
			di "No bias-correction specified. Proceeding with standard -synth- estimation..."
			di ""
			if "`counit'" != "" {
				local counitlist : subinstr local counit " " ",", all
				local n0 : list sizeof counit
				*qui distinct(`pvar') if inlist(`pvar', `counitlist')
				*qui local n0 = r(ndistinct)	
			}
			if "`counit'" == "" {
				qui distinct(`pvar')
				qui local n0 = r(ndistinct) - 1
			}
			local predno : list sizeof anything
			local predno = `predno' - 1

			* Run the synthetic control and capture the weights
			#delimit ;
				synth 
					`anything', 
					trunit(`trunit') 
					trperiod(`trperiod') 
					counit(`counit')
					xperiod(`xperiod')	
					mspeperiod(`mspeperiod')
					resultsperiod(`resultsperiod' )
					unitnames(`unitnames')
					`figure' 
					keep(`keep') 
					`replace'
					`customv'
					margin(`margin')
					maxiter(`maxiter')
					sigf(`sigf')
					bound(`bound')
					`nested'
					`allopt';
				#delimit cr

			di
			di 
			di as txt "Plain vanilla -synth- estimates provided. No bias correction or p-value calculations specified or applied." 
			di 
			di as txt "{hline}"	
			
			* Calculate the gap and analyze W-matrix
			qui mat Y_t = e(Y_treated)
			qui mat Y_s = e(Y_synthetic)
			qui mat gap = Y_t - Y_s
			qui mat w = e(W_weights)
			forval w = 1/`n0' {
				if `w' == 1 {
					qui mat W = w[`w',2]
				}
				if `w' != 1 {
					qui mat W = W\w[`w',2]
				}
				if `w' == `n0' {
					qui mat W = W'
				}
			}
			
			* Restrict to treated unit for graph and save the gap
			qui keep if `pvar' == `trunit'
			qui svmat gap, names(gap)
			rename gap1 gap
			
			* Graph results if gapfigure is specified
			if "`gapfigure'" != "" {
				graphgaps, tvar(`tvar') pvar(`pvar') figure(`gapfigure') trperiod(`trperiod') tvarformat(`_tVarformat') actreat(`actreat') tlab(`tlab') gaptitle(`gaptitle') gaptitlepct(`gaptitlepct') gftwopts(`gftwopts') figuresave(`gapfigsave') figurereplace(`gapfigsavereplace')
			}
			
			* Check if the predictors of the treated unit fall within the convex hull of those of the donor pool
			qui mat X_b = e(X_balance)
			qui mat X_d = X_b[1..`predno',1] - X_b[1..`predno',2]
			qui mat Xd = X_d'
			qui mat XX = Xd*X_d
			qui clear
			qui svmat XX, names(x)
			local chzero = x1
			
			* Identify if weighting matrix of actually-treated unit is sparse
			qui clear
			mat Wzeros = W'
			qui svmat Wzeros, names(w)
			qui gen x = (w1 != 0)
			qui egen nonzerows = total(x)
			qui keep if _n == 1
			local nonzerows = nonzerows
			
			* Identify if W-matrix is likely unique
			mat uW = J(`tsize',1,0)
			if (`predno' >= `nonzerows') & `chzero' != 0 {
				mat uW = J(`tsize',1,1)
			}
			
			* Save the gap results as a variable
			qui svmat gap, names(gap)
			rename gap1 gap
			qui gen `tvar' = .
			local t = 1
			foreach tval of local _t {
				qui replace `tvar' = `tval' if _n == `t'
				local t = `t' + 1
			}
			
			* Return aditional results
			mat colnames gap = Gap
			ereturn mat gaps gap
			mat unW = uW[1,1]
			mat colnames unW = Unique_W
			ereturn mat unique_W unW
			mkmat `tvar' gap, mat(results)
			mat results = results,uW
			mat colnames results = `tvar' Gap Unique_W
			mat rownames results = `_t'
			ereturn mat results results	
			
			* Indicate if pre-treatment MSPE was 0 (and thus set to 1 for RMSPE calculation)
			if "`pvalues'" != "" & `mspe_flag' == 1 {
				di ""
				di "{hline}"
				di as err "Warning: pre-treatment MSPE was 0 because the set of predictors included pre-treatment outcomes for all pre-treatment `tvar's."
				di ""
				di " Pre-treatment MSPE adjusted to 1. rmspe_bc is now the MSPE at each t > T0"
				di ""
				di "{hline}"
			}

			
			* Indicate if treated-unit weighting matrix is not sparse or not unique
			if (`nonzerows' > `predno') & `chzero' != 0 {
				di ""
				di "{hline}"
				di as err "Warning: the -synth- weighting matrix W for treated unit (`pvar' == `actreat') contains more non-zero weights than predictor variables and is likely not unique. Consider adjusting the number of predictor variables or appropriately restricting the donor pool"
				di ""
				di "{hline}"
			}
			if `chzero' == 0 {
				di ""
				di "{hline}"
				di as err "Warning: the vector of predictor variables for treated unit (`pvar' == `actreat') falls within the convex hull of the columns of the matrix of predictors for the donor pool. The -synth- weighting matrix W is not unique. Consider adjusting the number of predictor variables or appropriately restricting the donor pool"
				di ""
				di "{hline}"
			}
			* Save trunit (and avgweights) to dataset if stacked() is specified
			if "`stacked'" != "" {
				qui use "`keep'", clear
				qui gen trunit = `actreat'
				qui gen trperiod = `trperiod'
				qui gen `pvar' = `actreat'
				if "`_stAvgweights'" != "" {
					qui gen _stAvgweights = `avgweights'
				}
				mat gap = e(gaps)
				mat unique_W = e(unique_W)
				qui svmat gap, names(gap)
				qui svmat unique_W, names(unique_W)
				rename (gap1 unique_W1) (gap unique_W)
				qui save "`keep'", `replace'
			}
		}
	}

	* Stack, if specified
	if "`stacked'" != "" {
		sampleplacebos,	tvar(`tvar') pvar(`pvar') filename(`_Filename') tvarformat(`_tVarformat') filepath("`_Filepath'") avgs("`_stSampleavgs'") emin("`_stEventtimemin'") emax("`_stEventtimemax'") avgwts("_stAvgweights") balance("`_stBalanced'") uW("`_stUnique_w'") figure("`_stFigure'") figureopts("`stfigureopts'") figuresave("`stfigsave'") figurereplace("`stfigsavereplace'") gaptitle("`gaptitle'") gaptitlepct("`gaptitlepct'")
	}
	
	* Citation reminder
	di
	di as smcl "{cmd:________________________________}"
	di
	di as smcl "{cmd:allsynth is a user-written command made freely-available to the research community. Please cite the paper:}"
	di
	di as smcl `"{browse "https://justinwiltshire.com/s/allsynth_Wiltshire.pdf":Wiltshire, Justin C., 2022.  allsynth: (Stacked) Synthetic Control Bias-Correction Utilities for Stata. Working paper.}"'
	di
	di "{hline}"
end

*** Subroutines by Justin C. Wiltshire

* Subroutine sampleplacebos: samples placebo averages to create the sample empirical ditribution of placebo average treatment effects */ 
program sampleplacebos, rclass
	version 15.1
	#delimit ;
		syntax , 
		tvar(string)
		pvar(string)
		filename(string)
		tvarformat(string)
		[
		filepath(string)
		avgs(numlist min=1 max=1 >0 integer) 
		emin(numlist min=1 max=1 <0 integer) 
		emax(numlist min=1 max=1 >0 integer) 
		avgwts(string) 
		balance(string)
		uW(string)
		figure(string)
		figureopts(string)
		figuresave(string)
		figurereplace(string)
		gaptitle(string)
		gaptitlepct(string)
		* 
		]
		;
	#delimit cr

	* Set seed 
	set seed 12345
	
	* Tempfiles
	tempfile core
	tempfile core2
	tempfile core3

	* Get filelist
	local filelist: dir "`filepath'" files "*.dta"
	local _Slash
	if "`filepath'" != "" {
		local _Slash "/"
	}
	
	* Loop over the files
	di as txt " "
	di "Stacking the estimates..."
	di
	
	* Append the estimates and adjust as appropriate
	local counter = 0
	foreach f of local filelist {
		if strpos("`f'", "`filename'_`pvar'") != 0 {
			qui use "`filepath'`_Slash'`f'", clear
			qui rename _time `tvar'
			if `counter' == 0 {
				capture assert `avgwts'
				if _rc != 0 {
					local avgwts ""
				}
				capture assert `pvar'
				if _rc != 0 {
					local pvar ""
				}
			}
			qui keep `pvar' `tvar' gap* unique_W trunit trperiod `avgwts'
			qui gen _tm = `tvar'
			format _tm `tvarformat'
			if "`emin'" != "" {
				qui replace _tm = `tvar' - trperiod
				qui keep if inrange(_tm, `emin', `emax')
			}
			if `counter' > 0 {
				qui append using "`core'"
			}
			qui save "`core'", replace
			local counter = `counter' + 1
		}
	}

	* Calculate the estimated average treatment effect for treated units
	di "Calculating the estimated average treatment effect for treated units"
	di
	qui use "`core'", clear
	if "`uW'" != "" {
		qui levelsof trunit if unique_W == 0, local(droptrunits)
		if "`droptrunits'" != "" {
			di
			di as txt "Treated units `droptrunits' do not have unique W matrices and are being dropped as -unique_w- is specified in the allsynth option stacked()"
			di
		}
		qui levelsof trunit if unique_W == 1, local(keeptrunits)
		if "`keeptrunits'" == "" {
			di
			di as err "No treated units are left after dropping units without unique W matrics. Try a different specification"
			exit 198
		}
		if "`droptrunits'" == "" {
			di
			di as txt"All treated units have unique W matrices"
			di
		}
		qui keep if unique_W == 1
	}
	qui sum trperiod
	local trperiod = r(mean)
	capture assert trperiod == `trperiod' if !mi(trperiod)
	if _rc != 0 & "`emin'" == "" {
		local emin = -5
		local emax = 5
		qui replace _tm = `tvar' - trperiod
		qui keep if inrange(_tm, `emin', `emax')
	}
	if "`emin'" != "" {
		local trperiod = 0
		qui sum `tvar'
		local eperiods = r(max) - r(min)
		format _tm %9.0g
	}
	qui save "`core'", replace
	qui keep if `pvar' == trunit
	if "`balance'" != "" {
		qui levelsof `pvar', local(_Units)
		local nunits : list sizeof _Units
		bysort _tm: gen _tmCount = _N
		qui keep if _tmCount == `nunits'
	}
	if "`avgwts'" != "" {
		local awts "[aw=`avgwts']"
	}
	collapse (mean) gap* `awts', by(_tm)
	qui compress
	qui save "`filepath'`_Slash'`filename'_ate.dta", replace
	list 
	di
	di as txt "Estimated average treatment effects saved in `filepath'`_Slash'`filename'_ate.dta"
	di
	
	* Sample the placebo average treatment effects if specified
	if "`avgs'" != "" {
		di "Randomly sampling `avgs' placebo average treatment effects. This could take a while..."
		di
		qui use "`core'", clear
		qui levelsof trunit, local(trunits)
		qui drop if `pvar' == trunit
		qui save "`core2'", replace		
		forval n = 1/`avgs' {
			
			* Randomly select a placebo treated unit from each actually treated unit
			qui use "`core2'", clear
			qui gen p = runiform() if `tvar' == trperiod
			qui sort trunit p
			bysort trunit: gen px = (_n == 1)
			bysort `pvar' trunit: egen keepdonor = max(px)
			qui keep if keepdonor == 1
			qui sort `pvar' `tvar'
			
			* Calculate the sample average treatment effect
			if "`balance'" != "" {
				qui sum trunit
				qui levelsof trunit, local(_Units)
				local nunits : list sizeof _Units
				bysort _tm: gen _tmCount = _N
				qui keep if _tmCount == `nunits'
			}
			collapse (mean) gap* `awts', by(_tm)
			qui compress
			qui gen _placeboID = `n'
			if `n' > 1 {
				qui append using "`core3'"
			}
			qui save "`core3'", replace

		}
		qui append using "`filepath'`_Slash'`filename'_ate.dta"
		qui replace _placeboID = 0 if mi(_placeboID)
		qui save "`core3'", replace
		
		*** Calculate the RMSPEs and RMSPE p-values
		local pvar _placeboID
		local tvar _tm
		qui sum `tvar'
		local T0 = `trperiod' - r(min)
		local T1 = r(max) - `trperiod' + 1
		qui levelsof `tvar' if `tvar' >= `trperiod', local(trtvars)
		qui gen rmspe = .
		qui levelsof(`pvar'), local(id)
		bysort `tvar': gen N = _N
		foreach i of local id {
			qui egen xpre = total(gap^2) if `tvar' < `trperiod' & `pvar' == `i'
			qui gen xpre2 = xpre/`T0'
			qui egen mspe_pre = max(xpre2) if `pvar' == `i'
			qui drop x*
				
			* Treated period
			foreach tt of local trtvars {
				qui egen xpost2 = mean(gap^2) if inrange(`tvar', `trperiod', `tt') & `pvar' == `i'
				qui egen mspe_post_`tt' = max(xpost2) if `pvar' == `i'
				qui replace rmspe = mspe_post_`tt'/mspe_pre if `pvar' == `i' & `tvar' == `tt'
				qui drop x* mspe_post_`tt'
			}
			qui drop mspe*
		}
				
		* Generate RMSPE-ranked p-values
		qui gsort `tvar' -rmspe
		bysort `tvar': gen rmspe_rank = _n  if `tvar' >= `trperiod'
		qui gen p = rmspe_rank/N if `tvar' >= `trperiod'
		qui order `pvar' `tvar' gap rmspe* p N
			
		* Calculate the bias-corrected RMSPE and p-values if bcorrect() specified
		capture assert gap_bc
		if _rc != 111 {
			
			* Generate the bias-corrected RMSPE for T
			qui gen rmspe_bc = .
			qui levelsof(`pvar'), local(id)
			foreach i of local id {
				qui egen xpre = total(gap_bc^2) if `tvar' < `trperiod' & `pvar' == `i'
				qui gen xpre2 = xpre/`T0'
				qui egen mspe_pre = max(xpre2) if `pvar' == `i'
				qui drop x*
						
				* If the pre-period bias-corrected MSPE = 0 (e.g. because all pre-period outcomes are specified as predictors), set to 1
				if mspe_pre == 0 {
					local mspe_flag = 1
				}
				qui recode mspe_pre (0=1)

				* Treated period
				foreach tt of local trtvars {
					qui egen xpost2 = mean(gap_bc^2) if inrange(`tvar', `trperiod', `tt') & `pvar' == `i'
					qui egen mspe_post_`tt' = max(xpost2) if `pvar' == `i'
					qui replace rmspe_bc = mspe_post_`tt'/mspe_pre if `pvar' == `i' & `tvar' == `tt'
					qui drop x* mspe_post_`tt'
				}
				qui drop mspe*
			}

			* Generate RMSPE-ranked p-values
			qui gsort `tvar' -rmspe_bc
			bysort `tvar': gen rmspe_bc_rank = _n if `tvar' >= `trperiod'
			qui gen p_bc = rmspe_bc_rank/N if `tvar' >= `trperiod'
			qui order `pvar' `tvar' gap gap_bc rmspe* p p_bc N
		}
		qui save "`filepath'`_Slash'`filename'_ate_distn.dta", replace
		qui sort `pvar' `tvar'
		list if `pvar' == 0
		di
		di as txt "Sample distribution saved in `filepath'`_Slash'`filename'_ate_distn.dta"
		di
	}	
	
	* Graph figure if specified
	local _Stacked "stacked"
	if "`figure'" != "" {
		local atefilename "`filepath'`_Slash'`filename'_ate.dta"
		local distfilename "`filepath'`_Slash'`filename'_ate_distn.dta"
		graphgaps, tvar(_tm) pvar(`pvar') figure(`figure') trperiod(`trperiod') tvarformat(`tvarformat') stacked(`_Stacked') avgs(`avgs') atefilename(`atefilename') distfilename(`distfilename') actreat(0) gaptitle(`gaptitle') gaptitlepct(`gaptitlepct') gftwopts(`figureopts') eperiods(`eperiods') figuresave(`figuresave') figurereplace(`figurereplace')
	}
end

* Subroutine graphgaps: creates figures as specified
program graphgaps, rclass
	version 15.1
	#delimit ;
		syntax,
		tvar(string)
		pvar(string)
		figure(string)
		trperiod(string)
		tvarformat(string)
		[
		stacked(string)
		avgs(string)
		atefilename(string)
		distfilename(string)
		actreat(string)
		gaptitle(string)
		gaptitlepct(string)
		gftwopts(string)
		tlab(string)
		eperiods(integer 0)
		figuresave(string)
		figurereplace(string)
		* 
		]
		;
		#delimit cr

	graph close _all
	graph drop _all
		
	* Load the data if plotting for stacked()
	if "`stacked'" != "" {
		if "`avgs'" == "" {
			qui use "`atefilename'", clear
			qui gen _placeboID = 0
			local pvar "_placeboID"
		}
		if "`avgs'" != "" {
			qui use "`distfilename'", clear
		}
	}
	
	* Parse the figure() string
	local gapfigclassic = 0
	local gapfigbcorrect = 0
	local gapfigplacebos = 0
	local gapfiglineback = 0
	foreach s of local figure {
		capture assert "`s'" == "classic" | "`s'" == "bcorrect" | "`s'" == "placebos" | "`s'" == "lineback"
		local gapfig`s' = 1
	}

	* Prepare gapfigure() graph
	qui sum `tvar'
	local tlabmin = r(min)
	local tlabmax = r(max)
	local tlabinc = round((`tlabmax' - `tlabmin')/6, 1)
	if `trperiod' == 0 & inrange(`eperiods', 2, 19) {
		local tlabinc = 1
	}
	qui sum gap if `pvar' == `actreat'
	local gapmin = r(min)
	local gapmax = r(max)
	if `gapfigbcorrect' == 0 {
		qui gen _tmpmin = `gapmin'
		qui gen _tmpmax = `gapmax'
	}
	if `gapfigbcorrect' == 1 {
		qui sum gap_bc if `pvar' == `actreat'
		local gapbcmin = r(min)
		local gapbcmax = r(max)
		qui gen _tmpmin = min(`gapmin', `gapbcmin')
		qui gen _tmpmax = max(`gapmax', `gapbcmax')
	}
	qui gen ylab = max(abs(_tmpmin),abs(_tmpmax))
	qui sum ylab
	local ylab = r(max)
	qui drop _tmpmin _tmpmax ylab
	local u = 0
	local c = 1
	forval s = -2(1)20 {
		if `s' == -2 {
			local v = 0.01
			if inrange(`ylab', `u', `v') {
				local yext = `v'
				local ylabext = `v'
			}
		}
		if `s' == -1 {
			local v = 0.1
			if inrange(`ylab', `u', `v') {
				local yext = `v'
				local ylabext = `v'
			}
		}
		if `s' == 0 {
			local v = 1
			if inrange(`ylab', `u', `v') {
				local yext = `v'
				local ylabext = `v'
			}
		}
		if inrange(`s', 1, 10) {
			local v = 5*`s'
			if inrange(`ylab', `u', `v') {
				local yext = `v'
				if `s' > 2 {
					local yext = `v' + 10
				}
				local ylabext = `yext' - 5
				if `s' <= 2 {
					local ylabext = `yext'
				}
				if inlist(`s', 4, 6, 8, 10) {
					local ylabext = `yext'
				}
			}
		}
		if `s' > 10 {
			if inlist(`s', 11, 13, 15, 17, 19) {
				local c = `c' + 1
				local v = 10^`c'
			}
			if inlist(`s', 12, 14, 16, 18, 20) {
				local v = 5*(10^`c')
			}
			if inrange(`ylab', `u', `v') {
				local yext = `v'
				local ylabext = `v'
			}
		}
		local u = `v'
	}
	local u = 0
	local c = 1
	forval s = -2(1)4 {
		if `s' == -2 {
			local v = 0.01
			if inrange(`ylabext', `u', `v') {
				local yinc = 0.005
			}
		}
		if `s' == -1 {
			local v = 0.1
			if inrange(`ylabext', `u', `v') {
				local yinc = 0.05
			}
		}
		if `s' == 0 {
			local v = 1
			if inrange(`ylabext', `u' + 0.1, `v') {
				local yinc = 0.5
			}
		}			
		if `s' == 1 {
			local v = 5
			if inrange(`ylabext', `u' + 0.1, `v') {
				local yinc = 2
			}
		}
		if `s' == 2 {
			local v = 15
			if inrange(`ylabext', `u' + 0.1, `v') {
				local yinc = 5
			}
		}
		if `s' == 3 {
			local v = 35
			if inrange(`ylabext', `u' + 0.1, `v') {
				local yinc = 10
			}
		}
		if `s' == 4 {
			if inrange(`yext', `u' + 0.1, 60) {
				local yinc = 20
			}
		}
		if `yext' > 60 {
			local yinc = `yext'/2
		}
		local u = `v'
	}

	local trpm1 = `trperiod' - `gapfiglineback'
	local gapfigc ""
	local gapfigbc ""
	local gapfigcleg " "
	local gapfigbcleg ""
	local cleglabo ""
	local bcleglabo ""
	local cleglabc ""
	local bcleglabc ""
	local gapfigfake "(line gap `tvar' if `pvar' == `actreat', lp(solid) lcolor(white))"
	local fakeleglabo "label( 1 "
	local fakeleglabc ")"
	local gapfigfakeleg ""
	if `gapfigclassic' == 1 {
		local gapfigc "(line gap `tvar' if `pvar' == `actreat', lp(solid) lcolor(black))"
		local cleglabo "label(2 "
		local cleglabc ")"
		local gapfigcleg "Classic SC"
		if "`stacked'" != "" {
			local gapfigcleg "Average classic SC"
		}
		local cname "classic_"
	}
	if `gapfigbcorrect' == 1 {
		local gapfigbc "(line gap_bc `tvar' if `pvar' == `actreat', lp(solid) lcolor(black))"
		local bcleglabo "label(2 "
		local bcleglabc ")"
		local gapfigbcleg "Bias-corrected SC"
		if "`stacked'" != "" {
			local gapfigbcleg "Average bias-corrected SC"
		}
		local bcname "bias_corrected_"
	}
	if `gapfigclassic' == 1 & `gapfigbcorrect' == 1 {
		local gapfigfake ""
		local gapfigc "(line gap `tvar' if `pvar' == `actreat', lp(shortdash) lcolor(black))"
		local cleglabo "label(1 "
		local fakeleglabo ""
		local fakeleglabc " "
	}
	
	* Define the default twoway options
	local opt_yscale "yscale(range(-`yext' `yext'))"
	local opt_ylabel "ylabel(-`ylabext'(`yinc')`ylabext', nogrid tlcolor(black))"
	local opt_xline "xline(`trpm1', lp(".#") lcolor(black))"
	local opt_yline "yline(0, lp(dash) lcolor(gs4))"
	local opt_plotregion "plotregion(margin(0 0 0 0) ilstyle(solid))"
	local opt_title "title(" ") "
	local opt_xtitle "xtitle(" ") "
	local opt_ytitle "ytitle("`gaptitle' Gap `gaptitlepct'") "
	local opt_xlabel "xlabel(`tlabmin'(`tlabinc')`tlabmax', angle(90) tlcolor(black)) "
	local opt_graphregion "graphregion(fcolor(white)) "
	local opt_legend "legend(rows(2) `fakeleglabo'`gapfigfakeleg'`fakeleglabc' `cleglabo'`gapfigcleg'`cleglabc' `bcleglabo'`gapfigbcleg'`bcleglabc') "
	local opt_ysize "ysize(4)"
	local opt_xsize "xsize(4)"
	local opt_name "name(st_`cname'`bcname'gaps)"
	
	* Parse twopts
	local definedopts "yscale ylabel xline yline plotregion title xtitle ytitle xlabel graphregion legend ysize xsize name"
	local gftwopts2 "`gftwopts'"
	local gftwo : list sizeof gftwopts2
	while `gftwo' > 0 {
		gettoken g gftwopts2 : gftwopts2, bind
		foreach d of local definedopts {
			capture assert strpos("`g'", "`d'") == 1
			if _rc == 0 {
				local g2 "`g'"
				if strpos("`g'", "title") != 0 {
					local g2 = subinstr("`g'", ",", "", .)
				}
				local opt_`d' "`g2'"
				local gftwopts = subinstr("`gftwopts'", "`g'", "", .)
			}
		}
		local gftwo : list sizeof gftwopts2
	}
		
	* Graph gapfigure() if gapfigure(placebos) not specified
	if (`gapfigclassic' == 1 | `gapfigbcorrect' == 1) & `gapfigplacebos' == 0 {
		
		* Make the graph
		#delimit ;
			twoway 
				`gapfigfake' `gapfigc' `gapfigbc',
				`opt_yscale' `opt_ylabel'
				`opt_xline' `opt_yline' 
				`opt_plotregion'
				`opt_title'
				`opt_xtitle' `opt_ytitle'
				`opt_xlabel' `opt_graphregion'
				`opt_legend'
				`opt_ysize' `opt_xsize'
				`opt_name'
				`gftwopts';
			#delimit cr
	}
				
	* Prepare data if gapfigure(placebos) specified
	if `gapfigplacebos' == 1 {
		local gap "gap"
		local placleglab "Classic SC"
		local placlabd "donor pool units"
		if "`stacked'" != "" {
			local placleglab "Avg classic SC"
			local tlab "treated units"
			local placlabd "sample placebos"
		}
		if `gapfigbcorrect' == 1 {
			local gap "gap_bc"
			local placleglab "Bias-corrected SC"
			if "`stacked'" != "" {
				local placleglab "Avg bias-corrected SC"
			}
		}
		keep `tvar' `gap' `pvar'
						
		* Create locals for the placebo results and put treatment effects in percent terms
		qui levelsof(`pvar'), local(id)
		local numpvar: word count `id'
		local numpvarp1 = `numpvar' + 1
		local placebos
		foreach i of local id {
			local placebos "`placebos' (line `gap' `tvar' if `pvar' == `i' & `actreat' != `i' & inrange(`gap', -`yext', `yext'), lwidth(thin) lcolor(gs12) lp(solid))"
		}
		
		* Re-define the default twoway options as necessary
		local opt_legend "legend(rows(2) order(`numpvarp1' "`placleglab', `tlab'" `numpvar' "`placleglab', `placlabd'"))"
		local opt_name "name(st_`cname'`bcname'placebos_gaps)"
			
		* Create the gapfigure() graph if gapfigure(placebos) specified
		#delimit ;
			twoway  
				`placebos' (line `gap' `tvar' if `pvar' == `actreat', lwidth(medthick) lcolor(black) lp(solid)),
				`opt_yscale' `opt_ylabel'
				`opt_xline' `opt_yline' 
				`opt_plotregion'
				`opt_title'
				`opt_xtitle' `opt_ytitle'
				`opt_xlabel' `opt_graphregion'
				`opt_legend'
				`opt_ysize' `opt_xsize'
				`opt_name'
				`gftwopts';
			#delimit cr
	}

	* Export the graph if specified
	qui `figuresave' `figurereplace'

end

*** Subroutines by Jens Hainmueller (from synth.ado package)

* Subroutine reducesample: creates subsample marker for specified periods and units */
program reducesample, rclass
	version 9.2
	syntax , tno(numlist >=0 integer) uno(numlist integer) genname(string)
	qui tsset
	local tvar `r(timevar)'
	local pvar `r(panelvar)'
	local tx: subinstr local tno " " ",", all
	local ux: subinstr local uno " " ",", all
	qui gen `genname' =  0
	foreach cux of numlist `uno' {
		qui replace `genname' = 1 if inlist(`tvar',`tx') & `pvar'==`cux'
	}
end

* Subroutine gettabstatmat: heavily reduced version of SSC "tabstatmat" program by Nick Cox */
program gettabstatmat
	version 9.2
	syntax name(name=matout)
	local I = 1
	while "`r(name`I')'" != "" {
		local ++I
	}
	local --I
	tempname tempmat
	forval i = 1/`I' {
		matrix `tempmat' = nullmat(`tempmat') \ r(Stat`i')
		local names   `"`names' `"`r(name`i')'"'"'
	}
	matrix rownames `tempmat' = `names'
	matrix `matout' = `tempmat'
end


* Subroutine agmat: aggregate x-values over time, checks missing, and returns predictor matrix
program agmat
	version 9.2
	syntax name(name=finalmat), cvar(string) opstat(string) sub(string) ulabel(string) checkno(string) [ tilab(string) ]
	qui tsset
	local pvar `r(panelvar)'
	qui tabstat `cvar' if `sub' == 1 , by(`pvar') s(`opstat') nototal save
	qui gettabstatmat `finalmat'
	if matmissing(`finalmat') {
	qui local checkdimis : display `checkdimis'
	if "`tilab'" == "" {
		di as err "`ulabel': for at least one unit, predictor `cvar' is missing for ALL periods specified"
			exit 198
		}
		else {
			di as err "`ulabel': for at least one unit, predictor `cvar'(`tilab' is missing for ALL periods specified"
			exit 198
		}
	}
	qui drop `sub'
end
