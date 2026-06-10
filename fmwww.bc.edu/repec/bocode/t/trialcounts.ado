*! version 1.0	1.6.2026
*! Matthew Burnell

/* DESCRIPTION
trialcounts is program for calculating the number of subjects recruited to, and the number having reached subsequent scheduled visits, in a clinical trial based on supplied linear piecewise recruitment functions at a specific point in 'trial time'. From these are derived the 'recruitment weights' which can be used for the mixedpower program (for calculating power for linear mixed models). trialcounts also calculates the dropout probabilities assuming a supplied (weibull/lognormal) function and produces the integrated weights (which could also be supplied to mixedpower - mixedpower itself can also calculate integrated weights from supplied dropout and recruitment weights). These weights are used by mixedpower to weight separate test statistics formed from each cohort of subjects defined by the number of visits they reach to calculate the overall test statistic and hence power or sample size. 
trialcounts can calculate recruitment numbers/weights with a maximum n specified, and crucially also search over a timelist to find the timepoint (with associated weights) when a target n is reached for any of the scheduled visits, taking into account both the supplied recruitment pw functions and the dropout function. 
Plots of the functions can be produced to help establish the credibility of the supplied parameters
*/

program define trialcounts , rclass
	version 17.0 
	syntax, SCHEDule(numlist ascending >=0 min=2 max=101)	/// schedule list of time incl. baseline
			ENDS(string)									/// timepoints of end of each piecewise (linear) recruitment function: numlist ascending >0 min=1 max=100
			RATES(string)				/// recruitment rate for each piecewise function: numlist  >=0 min=1 max=100
			[ 												/// 
			DROPouts(numlist >=0 <=1)	  		 			///	numlist values of p(making visit to k and no further) due to dropout
			QUADratic 										/// make first recruitment function piece a quadratic to produce gradual increase in recruitment with one function
			MAXN(numlist integer min=1 max=1 >0)			/// maximum number to be recruited into trial. If not specified final number essentially based on evaluation of final pw function (final end) 
			TIMElist(numlist ascending >0 min=1)			/// time at which numbers in trial to be evaluated.  If not specified then time point for final ENDS+las t SCHEDule element is assumed i.e. time when last recruited have had full FU. More than one number implies a search 
			SEARCH(numlist integer >0 min=2 max=2)			/// search for required n at visit k. 
			DRFunction(string)								/// dropout function (weibull/lognormal/gompertz) with proportion left at final visit (shape parameter also needed).
			RGRaph											/// recruitment graph
			DGRaph											/// dropout graphs
			RGOPTS(string)									/// options to pass to recruitment function plot
			DHGOPTS(string)									/// options to pass to dropout hazard function plots
			DSGOPTS(string)									/// options to pass to dropout survival function plots
			NOLInes											/// no red visit count/time intersection lines 
			REName(string)									/// name for the recruitment function plot
			DHName(string)									/// name for the dropout hazard function plot
			DSName(string)									/// name for the dropout surival function plot
			DISP2											/// also display rescaled weights that sum to 1
			NOHEADer										/// no header display
			COMPact											/// show table in compact form
			]

if "`noheader'"=="" {
		
		di _n "{it:trialcounts}" as text " - program for recruitment and dropout functions in trials (version 1.0): author M.Burnell"
		di as text "MRC Centre of Research Excellence in Clinical Trial Innovation, UCL, London WC1V 6LJ, UK" 		
	}			
			
**# required options			



** Schedule, ENDS and RATES list - inbuilt Stata syntax check is sufficient for parsing SCHEDule, ENDS and RATES

	* Length of schedule list:
		local sched_length = 0
		foreach i of numlist `schedule' {
			local sched_length = `sched_length' + 1			
			}
		
	* Decant the schedule numlist into locals
		local j = 1 // counter - position number
		foreach i of numlist `schedule' {
			local sched`j' = `i'
			local j=`j'+1
		}
	
	*check if numlist or varname version for rates
	
	local ratetype: word 1 of `rates'
	capture confirm numeric variable `ratetype' 
	if !_rc {
		gettoken rvarname rindex : rates
		capture numlist "`rindex'", integer ascending min(1) max(120)
		if _rc {
			dis as error "numlist in rates() not supplied correctly"
		exit 198
		}
		local orig_rates
		foreach ri of numlist `rindex' {
			local orate=`rvarname'[`ri']
			local orig_rates "`orig_rates' `orate'"
			local rates `orig_rates'
		}
		
		capture numlist "`orig_rates'",  range(>=0) min(1) max(120)
		if _rc {
			dis as error "values taken from '`rvarname'' variable not in correct numlist specification"
		exit 198
		}
	}
	if _rc {
		capture numlist "`rates'",  range(>=0) min(1) max(120)
		if _rc {
			local rp1=substr("`rates'",1,1)
			capture confirm number `rp1'
			if _rc {
				dis as error "variable '`ratetype'' not found"
			exit 198
			}
			if !_rc {
				dis as error "numlist in rates() not supplied correctly"
		exit 198
			}			
		}
		local orig_rates `r(numlist)'
		local rates `orig_rates'
	}
	
		*check if numlist or varname version for ends
	
	local endtype: word 1 of `ends'
	capture confirm numeric variable `endtype' 
	if !_rc {
		capture confirm numeric variable `rvarname' 
		if _rc {
				dis as error "rates() must be varname version if ends() is varname version"
		exit 198
			}
		local evarname `endtype'	
		local orig_ends
		foreach ei of numlist `rindex' {
			local oend=`evarname'[`ei']
			local orig_ends "`orig_ends' `oend'"
			local ends `orig_ends'
		}
		
		capture numlist "`orig_ends'",  range(>=0) min(1) max(120) ascending
		if _rc {
			dis as error "values taken from '`evarname'' variable not in correct numlist specification"
		exit 198
		}
	}
	if _rc {
		capture numlist "`ends'",  range(>=0) min(1) max(120) ascending
		if _rc {
			local ep1=substr("`ends'",1,1)
			capture confirm number `ep1'
			if _rc {
				dis as error "variable '`endtype'' not found"
			exit 198
			}
			if !_rc {
				dis as error "numlist in ends() not supplied correctly"
		exit 198
			}			
		}
		local orig_ends `r(numlist)'
		local ends `orig_ends'
	}
	
	
	* Decant the ends numlist into locals
	*local orig_ends `ends' // also store original ends list
	local k = 1 // counter - position number
	foreach i of numlist `ends' {
			local end`k' = `i'
			local k=`k'+1
		}

		* Decant the rates numlist into locals
	*local orig_rates `rates' // also store original ends list	
	local k = 1 // counter - position number
	foreach i of numlist `rates' {
			local rate`k' = `i'
			local k=`k'+1
		}

	** Check Rates and End length match (if numlist versions)
	local ends_length: word count `ends'
	local rates_length: word count `rates'
	if `ends_length'!=`rates_length' {
				dis as error _n "Length of ends() numlist must match length of rates() numlist"
		exit 198
	}
	
	local origends_length=`ends_length'
	local origrates_length=`rates_length'
	local maxt=`sched`sched_length''+`end`rates_length'' // total length of FU unless otherwise specified

** Optional Options	
	
	* DROPOUTS  
	
	* Is there a dropout list specified?
		if "`dropouts'"!= "" & "`drfunction'"!= "" {
		dis as error _n "Either supply own dropout probability list - dropouts() - or specify a dropout function - drfunction()"
		exit 198
			}
			
		local drop_yes = 0
		if "`dropouts'"!="" local drop_yes = 1
		
	* Drop matrix must be same length as Schedule matrix
			* Length of dropout list
		if `drop_yes'==1 {	
			local drop_length = 0
			foreach i of numlist `dropouts' {
				local drop_length = `drop_length ' + 1
			}
			* Is this equal to schedule matrix?
			if `sched_length' != `drop_length' {
				dis as error _n "Dropout list length must correspond with visit schedule length"
				exit 198
			}
		}

	* Check dropout list sum ==1 (with tolerance allowed)
	
		if `drop_yes'==1 {
			
			local drsum=0
			local j = 1 // counter - position number
			foreach drop of numlist `dropouts' {
				local dr`j' = `drop'
				local j = `j' + 1
				local drsum = `drsum' + `drop'
					}
		* Check the drop matrix adds up = 1 (100%) (with tolerance allowed)
			if `drsum' < 1-0.00001 | `drsum' > 1.00001 {
				display as error _n "Dropout probabilities must sum to 1"
				exit 198
				}	
		}
		
		** Dropout function 
		if "`drfunction'"!="" {
			if strmatch(`"`drfunction'"',"*,*") {
				local drf=subinstr(`"`drfunction'"', ",", " ", 1)
				
			}
			else {
				di as error "drfunction() incorrectly specified - comma needed after function name"
				exit 198
			}
		
			gettoken name drf: drf, parse(" ")
			parse_streg, `name'
			local name `s(name_f)'
			if "`name'"=="weibull" { 
				 parse_wei, `drf'  // parsing weibull model subroutine, at end of .ado
			}
			else if "`name'"=="lognormal" {
				parse_logn, `drf'
			}
			else if "`name'"=="gompertz" {
				parse_gomp, `drf'
			}
			else if "`name'"=="loglogistic" {
				parse_loglog, `drf'
			}
			else if "`name'"=="ggamma" {
				parse_ggamma, `drf'
			}
			else {
				di as error "drfunction() incorrectly specified - possible function names are 'weibull', 'lognormal', 'gompertz', 'loglogistic' and 'ggamma'"
				exit 198
			}
		}
	
	
	
	* picking up s-returned locals
		if "`name'"!="ggamma" {
				local p `s(p)'
				local S_schmax `s(S_schmax)'
				local lambda `s(lambda)'
			}
			else  {
				local p `s(p)'
				local kappa `s(kappa)'
				local lambda `s(lambda)'
			}

	
	
	** check if timelist specified (if not make time =maxt) and if so is it a single value or multiple

	   if "`timelist'"=="" {
		local timelist= `maxt'  // will also restate and display message about imputed time value after maxn section, in case last end is shortened due to recruitment limit
		local tlorig=0
		
	   }
	   else {
	   	local tlorig=1
	   }
		if "`timelist'"!="" {
			local tllength: word count `timelist'
		}
		local t1: word 1 of `timelist' // time of first value for search
		
	  ** Parse Search option
	  local target=.
	  if "`timelist'"!="" & `tllength'==1 & "`search'"!="" {
			display as error  "Search function option - search() - only applicable when supplied timelist() is of length at least 2 to search over"
			exit 198
	  }
	  if "`search'"!="" {
	  	local target: word 1 of `search'
		local sched_n: word 2 of `search'
		if `sched_n'>`sched_length' {
			display as error  "visit number in search() is larger than number of visits given in schedule()"
			exit 198
		}
		if `sched`sched_n''>=`t1' {
			display as error  "starting of value of search range (=`t1') needs to be larger than the time of the target visit (t=`sched`sched_n'')"
			exit 198
		}
	  }
	  
	  ** Graphs
	  
	  if "`rgraph'"=="" {
			if "`rgopts'"!="" | "`rename'"!="" | "`nolines'"!="" {
				di as error "cannot specify rgopts(), rename() or nolines without indicating rgraph"
				exit 198
			}
	  }

	  if "`dgraph'"=="" {
			if "`dhgopts'"!="" | "`dsgopts'"!="" | "`dhname'"!="" | "`dsname'"!="" {
					di as error "cannot specify dhgopts(), dsgopts(), dhname() or dsname() without indicating dgraph"
					exit 198
			}
	  }
	  
	  
	** DOES MAXN (IF SPECIFIED) IMPACT THE SUPPLIED RECRUITMENT FUNCTION
		
	local stop=0  // start of section for establishing if maxn & tstop comes into play to then alter the pw functions to relfect maxn...
	if "`maxn'"!="" {


		local time= `maxt'
		local recfunction=0
		forvalues i=1/`=`rates_length'+1' {

			if `i'==1 {
				
				local condt`i' cond(0<`time' & `time'<=`end`i'',1,0)
				local tstar=cond(0<`time' & `time'<=`end`i'', `time',`end`i'')
				local rect`i'=`rate`i''*(`tstar'-0)
				if "`quadratic'"!="" {
					local rect`i'=`rate`i''*(`tstar'-0)^2
				}
				if `rect`i''>=`maxn' {
					local stop=1
					local fi=`i'
					local tstop=`maxn'/`rate`i''
					local rect`i'=`rate`i''*(`tstop'-0)
					if "`quadratic'"!="" {
						local tstop=(`maxn'/`rate`i'')^0.5
						local rect`i'=`rate`i''*(`tstop'-0)^2
					}
				}
				local funct`i'=`rect`i''*`condt`i''
				local recfunction="`recfunction' +`funct`i''"
				
			}
			
			if `i'>1 & `i'<=`rates_length' 	{
				if `stop'==0 {
					local condt`i' cond(`end`=`i'-1''<`time' & `time'<=`end`i'',1,0)
					local tstar=cond(0<`time' & `time'<=`end`i'', `time',`end`i'')
					local rect`i'=`rate`i''*(`tstar'-`end`=`i'-1'')+ `rect`=`i'-1''
					if `rect`i''>=`maxn' {
						local stop=1
						local fi=`i'
						local tstop=(`maxn'-`rect`=`i'-1'')/`rate`i''+`end`=`i'-1''
						local rect`i'=`rate`i''*(`tstop'-`end`=`i'-1'')+ `rect`=`i'-1''	
						local condt`i' cond(`end`=`i'-1''<`tstop' & `tstop'<=`end`i'',1,0)
					}
					local funct`i' =`rect`i''*`condt`i''
					
					local recfunction= "`recfunction' +`funct`i''"
					* noi di "`rect`i''*`condt`i'' `tstop'"
				}
				else {
					
					local rect`i'=`rect`=`i'-1''
				}
			}
			if `i'==`=`rates_length'+1'	{
				if `stop'==0 {
				local condt`i' cond(`time'>`end`=`i'-1'',1,0)

				}
				if `stop'==1 {
					local condt`i' cond(`time'>`tstop',1,0)	
				}
				local tstar=cond(`end`=`i'-1''<=`time' & `time'<=`maxt', `time',`maxt')
				local rect`i'= `rect`=`i'-1''*(1-`stop')
				local funct`i' =`rect`i''*`condt`i''
				* noi di "`rect`i''*`condt`i'' `tstop'"
				local recfunction= "`recfunction' +`funct`i''"
			}
		} 
		
		if `stop'==1 {
			local newends
			local newrates
			forvalues pends=1/`fi' {
				local ne: word `pends' of `ends'
				if `pends'==`fi'  {
					local ne=`tstop'
				}
					local newends "`newends' `ne'"
					local nr: word `pends' of `rates'
					local newrates "`newrates' `nr'"
			}
		
			local ends `newends'  
			local rates `newrates'
		}
		
		* Decant the ends numlist into locals AGAIN! for new ends
		local k = 1 // counter - position number
		foreach i of numlist `ends' {
				local end`k' = `i'
				local k=`k'+1
			}

			* Decant the rates numlist into locals AGAIN! for new rates
		local k = 1 // counter - position number
		foreach i of numlist `rates' {
				local rate`k' = `i'
				local k=`k'+1
			}

		local rates_length: word count `rates'

		local maxt=`sched`sched_length''+`end`rates_length'' // total length of FU based on new final ends

	}
	// end of section for establishing if maxn & tstop comes into play...
	
	
		if `tlorig'==0 {
			local timelist=`maxt' // new maxt instead
			 di as err "note: timelist() not supplied - recruitment function evaluated at time last recruited subject (t="%5.2f `end`rates_length'' ") completes follow-up i.e. had last visit (t="%5.2f `sched`sched_length'' ") at t=" %5.2f `maxt' ""
	   }
	
	
** ACTUAL SECTION FOR CALCULATING RECRUITMENT FUNCTION, DROPOOUT FUNCTION, THEIR INTEGRATION AND SEARCHING OVER TIMELIST USING THE POSSIBLE 'NEWENDS' AND 'NEWRATES'
	
	local current0=-1
	local c=1 // timelist counter - note, will update at end of timelist loop so can use qualifier statement for lopp running
	local current`c'=`current0'+1 // jiggery-pokery to make counter work for first c (current1 gets compared to current0 later (i.e if `current`c''<=`current`=`c'-1''))
	local tllength=0
	foreach time of numlist `timelist' { // counting length of timelist - need to know if just single value, the standard case)
	
		local tllength=`tllength'+1
	}

	foreach time of numlist `timelist' {  // start of search loop
	
		if `current`c''+0.0000001<`target' & `current`c''>`current`=`c'-1''+0.0000001 { // evaluate if not yet reached target and current is still increasing - with small tolerances included
			local time`c'=`time'
			
			** RECRUITMENT WEIGHTS
			
			local recfunction=0
			local visit=0
			foreach v of numlist `schedule' `end`rates_length'' {  // also need to evaluate recfunction at time=last end to obtain the number to be recruited if maxn not specified/reached
				
				local visit=`visit'+1
				local recfunction`visit'=0
				if `visit'==`sched_length'+1 {
					local timev=`v'
				}
				else {
					local timev=`time'-`v'
				}
				
				forvalues i=1/`=`rates_length'+1' { 

					if `i'==1 { // first piece (rate)
						
						local condt`i' cond(0<`timev' & `timev'<=`end`i'',1,0)
						local tstar=cond(0<`timev' & `timev'<=`end`i'', `timev',`end`i'')
						local rect`i'=`rate`i''*(`tstar'-0)
						if "`quadratic'"!="" {
							local rect`i'=`rate`i''*(`tstar'-0)^2
						}
						local funct`visit'`i'=`rect`i''*`condt`i''
						local recfunction`visit'="`recfunction`visit'' +`funct`visit'`i''"
						
					}
					
					if `i'>1 & `i'<=`rates_length' 	{  // all the interim pieces (rates)
				
						local condt`i' cond(`end`=`i'-1''<`timev' & `timev'<=`end`i'',1,0)
						local tstar=cond(0<`timev' & `timev'<=`end`i'', `timev',`end`i'')
						local rect`i'=`rate`i''*(`tstar'-`end`=`i'-1'')+ `rect`=`i'-1''
						local funct`visit'`i'=`rect`i''*`condt`i''
						local recfunction`visit'="`recfunction`visit'' +`funct`visit'`i''"
										
					}
					if `i'==`=`rates_length'+1'	{  // last (flat) piece from final end to end+sched span
						
						local condt`i' cond(`timev'>`end`=`i'-1'',1,0)
						local tstar=cond(`end`=`i'-1''<=`timev' & `timev'<=`maxt', `timev',`maxt')
						local rect`i'= `rect`=`i'-1''
						local funct`visit'`i'=`rect`i''*`condt`i''
						local recfunction`visit'="`recfunction`visit'' +`funct`visit'`i''"

					}
				} // end of rate loop

				
				local rf`visit'=`recfunction`visit''
				
				
			} // end of visit loop
			
			local visit=0
			local recwsum=0
			local recwgts 
			local rfdiffs 
			foreach v of numlist `schedule' {
				local visit=`visit'+1 
				if `visit'==`sched_length' {
					local rfdiff`visit'=`rf`visit''
				}
				else {
					local rfdiff`visit'=`rf`visit''-`rf`=`visit'+1'' // difference in numbers between visits counters
				}
				local rfdiffs "`rfdiffs' `rfdiff`visit''"
				
				if `stop'==0 {
					local recweight`visit'=`rfdiff`visit''/`rf`=`sched_length'+1''  // divide diff by total recruited based on function i.e. at last end t 
				}
				if `stop'==1 {
					local recweight`visit'=`rfdiff`visit''/`maxn'  // divide diff by specified maxn if reached
				}
				local recwgts "`recwgts' `recweight`visit''"
				local recwsum=`recweight`visit''+`recwsum'
			}
			
		tempname recs rsum
		mat `recs'=J(1,`sched_length',0)	
			forvalues rw=1/`sched_length' {
				local rw`rw': word `rw' of `recwgts'
				mat `recs'[1,`rw']=`rw`rw''
			}
	   

	 
		
				** DROPOUT WEIGHTS
				
		if "`drfunction'"!="" {		
					
			local schmax=`sched`sched_length''
			if  "`S_schmax'"!="" {
				if "`name'"=="weibull" local lambda= -ln(`S_schmax')/`schmax'^`p'
				if "`name'"=="lognormal" local lambda= ln(`schmax')-invnormal(1-`S_schmax')*`p'
				if "`name'"=="gompertz" & `p'!=0 local lambda= -ln(`S_schmax')/((`p'^-1)*(exp(`p'*`schmax')-1))
				if "`name'"=="gompertz" & `p'==0 local lambda=-ln(`S_schmax')/`schmax'^`p'
				if "`name'"=="loglogistic" local lambda=((((`S_schmax')^-1)-1)^`p')/`schmax'
			}
			else {
				if "`name'"=="weibull" local S_schmax=exp(-`lambda'*`schmax'^`p')
				if "`name'"=="lognormal" local S_schmax=1-normal((ln(`schmax')-`lambda')/`p')
				if "`name'"=="gompertz"  & `p'!=0 local S_schmax=exp(-`lambda'*(`p'^-1)*(exp(`p'*`schmax')-1))
				if "`name'"=="gompertz"  & `p'==0 local S_schmax=exp(-`lambda'*`schmax')
				if "`name'"=="loglogistic"  local S_schmax=(1+(`lambda'*`schmax')^(1/`p'))^-1
				if "`name'"=="ggamma" {
					local gz= (sign(`kappa')*(ln(`schmax')-`lambda')/`p')
					local gamma=abs(`kappa')^-2
					local gu=(`gamma'*exp(abs(`kappa')*`gz'))

					if `kappa'<0 local S_schmax=gammap(`gamma',`gu')
					if `kappa'>0 local S_schmax=1-gammap(`gamma',`gu')
					if `kappa'==0 local S_schmax=1-normal(`gz')
				} 
			}
			
			local lambda_rd: di %4.3f `lambda'
			local S_schmax_rd: di %4.3f `S_schmax'
			local p_rd: di %4.3f `p'
			if "`name'"=="ggamma" local kappa_rd:di %4.3f `kappa'
			
			local i=0
			foreach t of numlist `schedule'  { 
				local i=`i'+1
				if "`name'"=="weibull" local S`i'=(exp(-`lambda'*`t'^`p') )
				if "`name'"=="lognormal" & `t'!=0 local S`i'=1-normal((ln(`t')-`lambda')/`p')
				if "`name'"=="lognormal" & `t'==0 local S`i'=1
				if "`name'"=="gompertz"  & `p'!=0 local S`i'=exp(-`lambda'*(`p'^-1)*(exp(`p'*`t')-1))
				if "`name'"=="gompertz"  & `p'==0 local S`i'=exp(-`lambda'*`t')
				if "`name'"=="loglogistic"  local S`i'=(1+(`lambda'*`t')^(1/`p'))^-1
				if "`name'"=="ggamma" {
					local gz= (sign(`kappa')*(ln(`t')-`lambda')/`p')
					local gamma=abs(`kappa')^-2
					local gu=(`gamma'*exp(abs(`kappa')*`gz'))
					if `t'!=0 {
						if `kappa'<0 local  S`i'=gammap(`gamma',`gu')
						if `kappa'>0 local  S`i'=1-gammap(`gamma',`gu')
						if `kappa'==0 local  S`i'=1-normal(`gz')
					}
					if `t'==0 local S`i'=1
				} 
				local survlist "`survlist' `S`i''"
			}
			
			local i=0
			local Swgts
			foreach t of numlist `schedule' {
				
				local i=`i'+1 
				if `i'==`sched_length' {
					local Sdiff`i'=`S`i''
				}
				else {
					local Sdiff`i'=`S`i''-`S`=`i'+1'' // difference in dropout survival between visits counters
				}
				local Swgts "`Swgts' `Sdiff`i''"
					
			}
			
		}
		
		if "`dropouts'"!="" {
			local Swgts "`dropouts'"
		}
		
		if "`dropouts'"=="" & "`drfunction'"=="" { // no dropouts so weights are zero for all except final visit, where weight==1
			
			local Swgts
			forvalues i=1/`sched_length' {
				if `i'==`sched_length' {
					local d0`i'=1
				}
				else {
					local d0`i'=0
				}
				local Swgts "`Swgts' `d0`i''"		
			}
		}
		
		tempname drops
		mat `drops'=J(1,`sched_length',0)	
			forvalues dr=1/`sched_length' {
				local drpo: word `dr' of `Swgts'
				mat `drops'[1,`dr']=`drpo'
			}

		
			** Integration of Recwgts and dropout wgts
			if "`recwgts'"!="" &  "`Swgts'"!="" {  

				local count: word count `recwgts'
				
				local finalwgts`c'
				forval i = 1/`count' {
					local weight_`i'
					local w_inv = 1
					local w1: word `i' of `recwgts'
			
					forval j = 1/`i' {
						local w2: word `j' of `Swgts'

						if `i' == `j' {
							local weight_`j' =`weight_`j'' + `w1'*`w_inv'
						}
						else {
							local weight_`j' =`weight_`j'' + `w1'*`w2'
						}
						
						local w_inv =`w_inv' - `w2'		
					}
					
				}
				
				
				forvalues i=1/`count' {
					local  finalwgts`c' "`finalwgts`c'' `weight_`i''"
				} 
								
			}
				
	

				
			** getting the cumulative counts (also calculate unique counts) reaching each visit	
	
				local cumwgts=0
				local uwgts=0
				local cumwgtslist`c'
				local uwgtslist`c'
				foreach n of numlist `count'/1 {
					if `stop'==0 {
						
						local cumwgts=`cumwgts'+`weight_`n''*`rf`=`sched_length'+1''  // multiply integrated weight by total recruited based on function i.e. at last end t 
						local uwgts=`weight_`n''*`rf`=`sched_length'+1''
					}
					if `stop'==1 {
						local cumwgts=`cumwgts'+`weight_`n''*`maxn'  // multiply integrated weight by specified maxn if reached
						local uwgts=`weight_`n''*`maxn' 
					}
					
				local cumwgtsrev=`cumwgts'
				local uwgtsrev=`uwgts'	
				local cumwgtslist`c'="`cumwgtsrev' `cumwgtslist`c'' "
				local uwgtslist`c'="`uwgtsrev' `uwgtslist`c'' "
					}
				
				
			** Seeing how the current value of number reaching visit k matches up to target and next step...
			if "`search'"!="" {
				local sres inrange
				local current: word `sched_n' of `cumwgtslist`c''
				if `c'==`tllength' {
					local iteration=`c'
					if `current'<=`target' {
						
						local warning "warning: target not reached with maximum time value supplied"
						local sres toolow
					}	
				}				
				if `current'+0.0000001>`target' & `tllength'>1 {  // time and cumwgtlist if target reached
					local iteration =`c'
					if `c'==1 {
							local warning "warning: target achieved with first time value supplied and actual necessary time may be shorter"
							local sres toohigh
					}
				}

				if  `current'<=`current`c''+0.0000001 & `tllength'>1 { // time and cumwgtlist if visitk count not increased i.e use previous result
					local iteration=`=`c'-1'
					if `current'<=`target' {
						local warning "warning: visit count stationary and target not reached with time values supplied "
						local sres toolow
					}
				}	
			}
				
			** for single time value only
				if `tllength'==1 { // time and cumwgtlist if visitk count not increased i.e use previous result
					local iteration=`c'
				}
				
			** add to counter and establish latest current`c'
				if `tllength'>1 { 
					local c=`c'+1
					local current`c': word `sched_n' of `cumwgtslist`=`c'-1''
				}
			}
			
	}
	
	if "`warning'"!="" {
		 di  as err "`warning'"
	}

	local timedi: di %9.2f `time`iteration''
	local finalwgts="`finalwgts`iteration''"
	local uwgtslist="`uwgtslist`iteration''"
	local cumwgtslist="`cumwgtslist`iteration''"
	
	tempname fins
	mat `fins'=J(1,`sched_length',0)	
		forvalues fw=1/`sched_length' {
			local fw`fw': word `fw' of `finalwgts'
			mat `fins'[1,`fw']=`fw`fw''
		}
	
	tempname uws
	mat `uws'=J(1,`sched_length',0)	
		forvalues uw=1/`sched_length' {
			local uw`uw': word `uw' of `uwgtslist'
			mat `uws'[1,`uw']=`uw`uw''
		}
	
	tempname cws
	mat `cws'=J(1,`sched_length',0)	
		forvalues cw=1/`sched_length' {
			local cw`cw': word `cw' of `cumwgtslist'
			mat `cws'[1,`cw']=`cw`cw''
		}
	

	local fwsum=0
	forvalues i=1/`sched_length' {
		local fwsum`i': word `i' of `finalwgts'
		local fwsum=`fwsum'+`fwsum`i''
	}
	local fwsumdi: di %5.4f `fwsum'
	local ucsum=0
	forvalues i=1/`sched_length' {
		local ucsum`i': word `i' of `uwgtslist'
		local ucsum=`ucsum'+`ucsum`i''
	}
	local ucsumdi: di %5.1f `ucsum'
	local total=`ucsum'/`fwsum'
	local totaldi: di %5.1f `total'
	
	
	local offset 36
	di _n as result "Trial Summary"
	 di  _s(2) as text "total number (planned)" _col(`=`offset'-2') "="  _col(`offset') as res `totaldi' // total to be recruited
	 di  _s(2) as text "at time="as res `timedi' as text " total recruited"   _col(`=`offset'-2') "="  _col(`offset') as res `ucsumdi' // total to be recruited

	 ** display table header
	 
	 local width=9
	 if "`compact'"!="" local width=6
	 local start=18
	 di _n as result "Table of visit probability weights and counts"
	  local headlist1  // display visit number
	 forvalues i=1/`sched_length' {
			
			local hdi`i' "visit `i'"
			if "`compact'"!="" local hdi`i' "v_`i'"
			local headlist1 "`headlist1' " _col(`=`start'+`width'*(`i'-1)') "`hdi`i''"
		}
		local headlist2 // di the times of those visits
	 forvalues i=1/`sched_length' {
			local h`i': word `i' of `schedule'
			if mod(`h`i'',1)!=0 local hrd`i': di %-2.1f `h`i''
			if mod(`h`i'',1)==0 local hrd`i': di %-1.0f `h`i''
			local hdi`i' "time=`hrd`i''"
			if "`compact'"!="" local hdi`i' "t=`hrd`i''"
			local headlist2 "`headlist2' " _col(`=`start'+`width'*(`i'-1)') "`hdi`i''"
		}	
	 
	 local fwdilist // di the final integrated weights
	 forvalues i=1/`sched_length' {
			local fw`i': word `i' of `finalwgts'

			local fwdi`i': di %5.4f `fw`i''
			if "`compact'"!="" local fwdi`i': di %4.3f `fw`i''
			local fwdilist="`fwdilist' _col(`=`start'+`width'*(`i'-1)') `fwdi`i''"
		}
		
	 local fwlist2 // for returning
	 local fwlist2SP // for returning
	 local fwdilist2 // optionally di the final integrated weights where forced to sum to 1 (for slopepoweri)
	 forvalues i=1/`sched_length' {
			local fw`i': word `i' of `finalwgts'
			local fw2`i'=`fw`i''*`total'/`ucsum'
			local fwdi2`i': di %5.4f `fw2`i''
			if "`compact'"!="" local fwdi2`i': di %4.3f `fw2`i''
			local fwdilist2="`fwdilist2' _col(`=`start'+`width'*(`i'-1)') `fwdi2`i''"
			local fwlist2="`fwlist2' `fw2`i''"
			if `i'<`sched_length' {
				local fwlist2SP="`fwlist2SP' `fw2`i''"  // weights to input into slopepoweri
			}
		}	
	local fwsum2=`fwsum'*`total'/`ucsum'
	local fwsum2di: di %5.4f `fwsum2'
	if "`compact'"!="" local fwsum2di: di %4.3f `fwsum2'
	
	 local ucdilist // di the unique counts
	 forvalues i=1/`sched_length' {
			local uc`i': word `i' of `uwgtslist'
			local ucdi`i': di %5.1f `uc`i''
			if "`compact'"!="" local ucdi`i': di %5.0f `uc`i''
			local ucdilist="`ucdilist' _col(`=`start'+`width'*(`i'-1)') `ucdi`i''"
		}	
	 local ccdilist // di the cumulative counts
	 forvalues i=1/`sched_length' {
			local cc`i': word `i' of `cumwgtslist'
			local ccdi`i': di %5.1f `cc`i''
			if "`compact'"!="" local ccdi`i': di %5.0f `cc`i''
			local ccdilist="`ccdilist' _col(`=`start'+`width'*(`i'-1)') `ccdi`i''"
		}
		
if `sched_length'<=20 {	
	local div=16
	di  _col(`div') "{c |}"	as text "`headlist1'"
	di  _col(`div') "{c |}" 	as text	"`headlist2'" _col(`=`start'+`width'*(`sched_length'-0)') "sum"
	di  _dup(`=`div'-1') "{c -}" _col(`div') "{c +}"	_dup(`=`start'+`width'*(`sched_length'-0)-12') "{c -}" 
	di  as text "final weights " _col(`div') "{c |}" as res  `fwdilist' _col(`=`start'+`width'*(`sched_length'-0)') `fwsumdi'
	if "`disp2'"!="" {
		di as text "f_wgts rescale" _col(`div') "{c |}" as res `fwdilist2' _col(`=`start'+`width'*(`sched_length'-0)') `fwsum2di'
	}
	di as text  "unique counts " _col(`div') "{c |}"  as res `ucdilist' _col(`=`start'+`width'*(`sched_length'-0)') `ucsumdi'
	di  as text "sum counts " _col(`div') "{c |}"  as res `ccdilist' 
}
else di as error "Standard output table not supplied if schedule list length is greater than 20. See return list for required scalars, matrices and macros of results"

	** return some matrices...
	
	tempname scheds
		mat `scheds'=J(1,`sched_length',0)	
			forvalues s=1/`sched_length' {
				local s`s': word `s' of `schedule'
				mat `scheds'[1,`s']=`s`s''
			}		
	   
		tempname fins2
	mat `fins2'=J(1,`sched_length',0)	
		forvalues fwr=1/`sched_length' {
			local fwr`fwr': word `fwr' of `fwlist2'
			mat `fins2'[1,`fwr']=`fwr`fwr''
		}
	
	local ends_length2: word count `ends'
	local rates_length2: word count `rates'
	
		tempname eds
	mat `eds'=J(1,`origends_length',0)	
		forvalues ed=1/`origends_length' {
			local ed`ed': word `ed' of `orig_ends'
			mat `eds'[1,`ed']=`ed`ed''
		}
		
	tempname rts
	mat `rts'=J(1,`origrates_length',0)	
		forvalues rt=1/`origrates_length' {
			local rt`rt': word `rt' of `orig_rates'
			mat `rts'[1,`rt']=`rt`rt''
		}
		
	tempname eds2
	mat `eds2'=J(1,`ends_length2',0)	
		forvalues ed2=1/`ends_length2' {
			local ed2`ed2': word `ed2' of `ends'
			mat `eds2'[1,`ed2']=`ed2`ed2''
		}
		
	tempname rts2
	mat `rts2'=J(1,`rates_length2',0)	
		forvalues rt2=1/`rates_length2' {
			local rt2`rt2': word `rt2' of `rates'
			mat `rts2'[1,`rt2']=`rt2`rt2''
		}	
	
	
** RGRAPH
	local function 
	forvalues i=1/`=`rates_length'+1' {

		if `i'==1 {
			local condx`i' cond(0<x & x<=`end`i'',1,0)
			local recx`i' (`rate`i''*(x-0))  // function piece needed for twoway plotting
			if "`quadratic'"!="" {
					local recx`i' (`rate`i''*(x-0)^2)
				}
			local rect`i'=(`rate`i''*(`end`i''-0)) // function evaluation need to give next piece to tell where to start plot  from
			if "`quadratic'"!="" {
					local rect`i'=(`rate`i''*(`end`i''-0)^2)
				}
			local funct`i' `recx`i''*`condx`i''
			local function "`function' `funct`i''"
			
		}
		if `i'>1 & `i'<=`rates_length'	{
			local condx`i' cond(`end`=`i'-1''<x & x<=`end`i'',1,0)
			local recx`i' (`rate`i''*(x-`end`=`i'-1'')+ `rect`=`i'-1'')
			local rect`i'=(`rate`i''*(`end`i''-`end`=`i'-1'')+ `rect`=`i'-1'')
			local funct`i' +`recx`i''*`condx`i''
			local function "`function' `funct`i''"
		}
		if `i'==`=`rates_length'+1'	{
			local condx`i' cond(`end`=`i'-1''<x & x<=`maxt', 1,0)
			local recx`i'= `rect`=`i'-1''
			local funct`i' `recx`i''*`condx`i''
			local function= "`function' +`funct`i''"
			
		}
		
	}

local yline 
forvalues i=1/`=`sched_length''{
	if `timedi'-`sched`i''>0 {
		local yline "`yline' `rf`i''"
	}	
}	
local xline 
forvalues i=1/`=`sched_length''{
	if `timedi'-`sched`i''>0 {
		local xline "`xline' `=`timedi'-`sched`i'''"
	}
}
if `stop'==1 {
	local  time=`tstop'
}

 local endslist // nice di the ends if necessary
 forvalues i=1/`rates_length' {  // `ends_length' didn't get updated after maxt
		local e`i': word `i' of `ends'
		local edi`i': di %5.2g `e`i''
		local endslist="`endslist' `edi`i''"
	}
	local endslist=strtrim(stritrim("`endslist'"))
	
 local rateslist // nice di the ends if necessary
 forvalues i=1/`rates_length' {  // `ends_length' didn't get updated after maxt
		local ra`i': word `i' of `rates'
		local radi`i': di %5.2g `ra`i''
		if "`quadratic'"!="" & `i'==1 local radi`i' `radi`i''*
		local rateslist="`rateslist' `radi`i''"
	}	
	local rateslist=strtrim(stritrim("`rateslist'"))
	
if "`quadratic'"!="" local qnote "* first recruitment function is a quadratic rate"	

local maxtgr=`maxt'-0.0000001 // function wants to draw line down to x-axis if maxt is the same as range upper bound

local maxtdi: di %6.4g `maxt'
local maxtdi=strtrim("`maxtdi'")
if `stop'==1 {
	local maxntext "note maximum n=`maxn' applied"
} 

if "`rgraph'"!="" {
	if "`nolines'"=="" local lines yline(`yline', lc(red) lp(solid) lw(*0.2)) xline(`xline', lc(red) lp(solid) lw(*0.2))
	if "`rename'"=="" local rename _recf, replace
	
	twoway function y= `function', range(0 `maxtgr') `lines'  plotregion(margin(0 0 0 0)) name(`rename') xtitle(trial time) ytitle(number recruited) note("recruitment function (before dropout) with final follow-up at t=`maxtdi'. `maxntext'"  "rates=(`rateslist')  `qnote'" "endpoints=(`endslist')") `rgopts'
}

** dropout graphs

if "`dgraph'"!="" {
	if "`dhname'"=="" local dhname _drhazf, replace
	if "`dsname'"=="" local dsname _drSurvf, replace
	
	if "`name'"=="weibull" {
			twoway function y=`p'*(x^(`p'-1))*`lambda' , range(0 `schmax')  note("weibull hazard function with lambda=`lambda_rd' p=`p_rd' where S(t=`schmax')=`S_schmax_rd'") xtitle(time in years) ytitle(dropout hazard) name(`dhname') `dhgopts'

			twoway function y=exp(-`lambda'*x^`p') , range(0 `schmax')  note("weibull survival function with lambda=`lambda_rd' and p=`p_rd' where S(t=`schmax')=`S_schmax_rd'") xtitle(time in years) ytitle(dropout survival) name(`dsname') `dsgopts'

	}
	if "`name'"=="lognormal" {
			twoway function y=(normalden((ln(x)-`lambda' )/`p')/(x*`p'))/(1-normal((ln(x)-`lambda')/`p')) , range(0 `schmax')  note("lognormal hazard function with mu=`lambda_rd' sigma=`p_rd' where S(t=`schmax')=`S_schmax_rd'") xtitle(time in years) ytitle(dropout hazard) name(`dhname') `dhgopts'

			twoway function y=1-normal((ln(x)-`lambda')/`p') , range(0 `schmax')  note("lognormal survival function with mu=`lambda_rd' and sigma=`p_rd' where S(t=`schmax')=`S_schmax_rd'") xtitle(time in years) ytitle(dropout survival) name(`dsname') `dsgopts'

	}		
	if "`name'"=="gompertz" {
			twoway function y=`lambda'*exp(`p'*x) , range(0 `schmax')  note("gompertz hazard function with lambda=`lambda_rd' gamma=`p_rd' where S(t=`schmax')=`S_schmax_rd'") xtitle(time in years) ytitle(dropout hazard) name(_`dhname') `dhgopts'
		if `p'==0 {
			twoway function y=exp(-`lambda'*x), range(0 `schmax')  note("gompertz survival function with lambda=`lambda_rd' and gamma=`p_rd' where S(t=`schmax')=`S_schmax_rd'") xtitle(time in years) ytitle(dropout survival) name(`dsname') `dsgopts'
		}
		else{
			twoway function y=exp(-`lambda'*(`p'^-1)*(exp(`p'*x)-1)), range(0 `schmax')  note("gompertz survival function with lambda=`lambda_rd' and gamma=`p_rd' where S(t=`schmax')=`S_schmax_rd'") xtitle(time in years) ytitle(dropout survival) name(`dsname') `dsgopts'
		}
	}
	if "`name'"=="loglogistic" {
			twoway function y=((`lambda'^(1/`p'))*(1/`p')*(x^((1/`p')-1)))/(1+(`lambda'*x)^(1/`p')) , range(0 `schmax')  note("loglogistic hazard function with lambda=`lambda_rd' gamma=`p_rd' where S(t=`schmax')=`S_schmax_rd'") xtitle(time in years) ytitle(dropout hazard) name(`dhname') `dhgopts'

			twoway function y=(1+(`lambda'*x)^(1/`p'))^-1, range(0 `schmax')  note("loglogistic survival function with lambda=`lambda_rd' and gamma=`p_rd' where S(t=`schmax')=`S_schmax_rd'") xtitle(time in years) ytitle(dropout survival) name(`dsname') `dsgopts'

	}
	if "`name'"=="ggamma" {
			local gzA  (sign(`kappa')*(ln(x)-`lambda')/`p')
			local gammaA abs(`kappa')^-2
			local guA (`gammaA'*exp(abs(`kappa')*`gzA'))
			if `kappa'<0 local survfunc (gammap(`gammaA',`guA'))
			if `kappa'>0 local survfunc (1-(gammap(`gammaA',`guA')))
			if `kappa'==0 local survfunc (1-normal(`gzA'))
			
			if `kappa'!=0 local fdens (exp(((`gammaA'-0.5)*ln(`gammaA')) + (`gzA'*sqrt(`gammaA'))-`gammaA'*exp(`gzA'/sqrt(`gammaA')) -lngamma(`gammaA') - ln(x*`p')))
			//NEED TO ENTER DENSITY FOR WHEN KAPPA==0!!!
			local hazfunc `fdens'/`survfunc'
		
		
			twoway function y=`hazfunc' , range(0 `schmax')  note("generalized gamma hazard function with lambda=`lambda_rd' kappa=`kappa_rd' and sigma=`p_rd' where S(t=`schmax')=`S_schmax_rd'") xtitle(time in years) ytitle(dropout hazard) name(`dhname') `dhgopts'

			twoway function y=`survfunc',  range(0 `schmax')  note("generalized gamma survival function with lambda=`lambda_rd' kappa=`kappa_rd'  and sigma=`p_rd' where S(t=`schmax')=`S_schmax_rd'") xtitle(time in years) ytitle(dropout survival) name(`dsname') `dsgopts'

	}
}


*** RETURN SECTION
	** scalars - any single numbers (except for DO model parameters) have returned as scalars (as well as macros)
	tempname maxtime nmax totaln currn timeeval fwtsum
	 scalar `fwtsum'=`fwsum'
	if "`drfunction'"!="" {
		return scalar dSurv_max=`S_schmax'
		return scalar dshape=`p'
		return scalar drate=`lambda'
	}
	scalar `maxtime'=`maxt'
	if `stop'==1 {
		scalar `nmax'=`maxn'
	}
	scalar `currn'=`ucsum'
	scalar `totaln'=`total'
	scalar `timeeval'=`time`iteration''
	
	return scalar fwgtsum=`fwtsum'
	return scalar time_value=`timeeval'
	return scalar N_total=`totaln'
	return scalar N_current=`currn'
	if `stop'==1 {
		return scalar N_limit=`nmax'	
	}
	return scalar max_time=`maxtime'

	
	

	** macros - have included more or less everything as a macro return!
	return local search_result `"`sres'"'
	return local search search_yes
	return local sum_counts `"`cumwgtslist'"'
	return local unique_counts `"`uwgtslist'"'
	return local fw_slopepoweri `"`fwlist2SP'"'
	return local fw_rescale `"`fwlist2'"'
	return local fw_sum `"`fwsum'"'
	return local final_wgts `"`finalwgts'"'
	return local drop_wgts `"`Swgts'"'
	return local rec_wgts `"`recwgts'"'
	return local maxt `"`maxt'"'
	if "`drfunction'"!="" {
		return local model_name `"`name'"'
	}
	return local current_n `"`ucsum'"'
	return local total_n `"`total'"'
	return local time `"`time`iteration''"'
	return local maxn `"`maxn'"'
	return local timelist `"`timelist'"'
	return local rates `"`rates'"'
	return local ends `"`ends'"'
	return local orig_rates `"`orig_rates'"'
	return local orig_ends `"`orig_ends'"'
	return local schedule `"`schedule'"'
	return local cmd trialcounts
	return local cmdline `"trialcounts `0'"'

	** matrices
	return mat sumcts=`cws'
	return mat uniqcts=`uws'
	return mat rescalefwgts=`fins2'
	return mat finalwgts=`fins'	
	return mat recwgts=`recs'
	return mat dropwgts=`drops'
	return mat rates=`rts2'
	return mat ends=`eds2'
	return mat origrates=`rts'
	return mat origends=`eds'
	return mat schedlist=`scheds'	

end

capture program drop parse_wei
program parse_wei, sclass 
	version 17.0
	
	syntax, p(numlist min=1 max=1)  [s(numlist min=1 max=1 >0 <=1) l(numlist min=1 max=1 >0)]
	
	sreturn clear
	if "`s'"!="" & "`l'"!="" {
		di as error "cannot supply both s() and l() suboptions for 'weibull' function choice"
		exit 198
	}

	if "`s'"=="" & "`l'"=="" {
		di as error "must supply either s() and l() suboption for 'weibull' function choice"
		exit 198
	}

	if "`s'"!="" {
		sreturn local S_schmax=`s'
	}
	if "`l'"!="" {
		sreturn local lambda=`l'
	}
	if "`p'"!="" {
		sreturn local p=`p'
	}
	
	
end

capture program drop parse_logn
program parse_logn, sclass 
	version 17.0
	
	syntax, p(numlist min=1 max=1)  [s(numlist min=1 max=1 >0 <=1) l(numlist min=1 max=1 )]
	
	sreturn clear
	if "`s'"!="" & "`l'"!="" {
		di as error "cannot supply both s() and l() suboptions for 'lognormal' function choice"
		exit 198
	}

	if "`s'"=="" & "`l'"=="" {
		di as error "must supply either s() and l() suboption for 'lognormal' function choice"
		exit 198
	}

	if "`s'"!="" {
		sreturn local S_schmax=`s'
	}
	if "`l'"!="" {
		sreturn local lambda=`l'
	}
	if "`p'"!="" {
		sreturn local p=`p'
	}
	
	
end

capture program drop parse_gomp
program parse_gomp, sclass 
	version 17.0
	
	syntax, p(numlist min=1 max=1)  [s(numlist min=1 max=1 >0 <=1) l(numlist min=1 max=1 >0)]
	
	sreturn clear
	if "`s'"!="" & "`l'"!="" {
		di as error "cannot supply both s() and l() suboptions for 'gompertz' function choice"
		exit 198
	}

	if "`s'"=="" & "`l'"=="" {
		di as error "must supply either s() and l() suboption for 'gompertz' function choice"
		exit 198
	}

	if "`s'"!="" {
		sreturn local S_schmax=`s'
	}
	if "`l'"!="" {
		sreturn local lambda=`l'
	}
	if "`p'"!="" {
		sreturn local p=`p'
	}
	
	
end

capture program drop parse_loglog
program parse_loglog, sclass 
	version 17.0
	
	syntax, p(numlist min=1 max=1 >0)  [s(numlist min=1 max=1 >0 <=1) l(numlist min=1 max=1 >0)]
	
	sreturn clear
	if "`s'"!="" & "`l'"!="" {
		di as error "cannot supply both s() and l() suboptions for 'loglogistic' function choice"
		exit 198
	}

	if "`s'"=="" & "`l'"=="" {
		di as error "must supply either s() and l() suboption for 'loglogistic' function choice"
		exit 198
	}

	if "`s'"!="" {
		sreturn local S_schmax=`s'
	}
	if "`l'"!="" {
		sreturn local lambda=`l'
	}
	if "`p'"!="" {
		sreturn local p=`p'
	}
	
	
end

capture program drop parse_ggamma
program parse_ggamma, sclass 
	version 17.0
	
	syntax, p(numlist min=1 max=1 >0)  k(numlist min=1 max=1) l(numlist min=1 max=1 )
		
		sreturn clear
		sreturn local kappa=`k'
		sreturn local lambda=`l'
		sreturn local p=`p'
	
end	

capture program drop parse_streg
program parse_streg, sclass 
	version 17.0
	
	syntax, [Weibull GOMpertz LOGLogistic LOGNormal GGAMma]
		
		sreturn clear
		if "`weibull'"!="" local namef weibull
		if "`gompertz'"!="" local namef gompertz
		if "`loglogistic'"!="" local namef loglogistic
		if "`lognormal'"!="" local namef lognormal
		if "`ggamma'"!="" local namef ggamma

		sreturn local name_f `namef'
	
end