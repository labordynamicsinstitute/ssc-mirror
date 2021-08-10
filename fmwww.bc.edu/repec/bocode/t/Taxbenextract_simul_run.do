			*************************************************
			** Prepare simulated files to run TAXBEN_modif **
			*************************************************
 

****************************************
* Version 1.1				 		   *
* Desbuquois Alexandre		 		   *
* desbuquois.alexandre@gmail.com	   *
* OR								   *
* alexandre.desbuquois@ens-cachan.fr   *
****************************************



/*

This program prepares the files to be used by the TAXBEN model. It adds some 
variables to the initial model, and also implements the options proposed
by the taxbenextract function.

*/




quietly{
set more off
cd "${path}"


** Preserve the existing data.

count
if r(N)>0{
	global initial = r(N)
	tempfile temp_taxbenextract
	save `temp_taxbenextract', replace
}
else{
	global initial = 0
}

clear

********************************************************************************

	*******************************
	** Prepare the simulated files 

global ch_care_ref = $ch_care
global cc_pt_ref   = $cc_pt
global post_cc_ref = $post_cc


di as input "Creating  the data  ... "
  
 foreach marital in $marital_stat{
	foreach kids in $childn{
		forvalues year=$min_year (1) $max_year{
		if "$ctry_list"=="all"{
				local add = `year' 
			}
			foreach c in ${ctry_list`add'} {
			
			cd "${path}/Control_files"
			use Standard_allcountrys_${Final_year}.dta, clear

			*cd "${path_baseline}"
			*use Baseline.dta, clear
			
			keep if country == "`c'" 
			keep if _n==1
			
			count
			if `r(N)'==0{
				use Standard_allcountrys_${Final_year}.dta, clear
				sort country
				keep if _n==1
				replace country="`c'"
				local cap_country= upper("`country'")
				
				forvalues var_modif = 1/12{
					foreach vaaar of varlist outvar`var_modif'{
						replace `vaaar' = subinstr(`vaaar',"al","`c'",1)
						replace `vaaar' = subinstr(`vaaar',"AL","`cap_country''",1)
						}
				}
				
				replace runcmnt = subinstr(runcmnt,"al","`c'",1)
				replace runcmnt = subinstr(runcmnt,"AL","`cap_country'",1)
			}
				

			
			
			local cond_di     = substr("$ctry_list",1,2)
			global sv_ctry	  = "`c'"
			global sv_kids    = "`kids'"
			global sv_year    = `year'
			global sv_marital = "`marital'"			
			local chd_nb      = substr("`kids'",1,1)
			replace nch       = `chd_nb'
			
			replace yr=`year'
			if "`marital'"=="single"  replace mars = 0
			if "`marital'"=="married" replace mars = 1
			
			replace run_type		  = $run_type
			
			local enf = substr("`kids'",1,1)
			
			replace nch = `enf'
			
			tostring principal_inc  , replace force 
			tostring principal_pinc , replace force
			tostring principal_days , replace force
			
			tostring spouse_inc	    , replace force
			tostring spouse_pinc    , replace force
			tostring spouse_days    , replace force
			
			replace principal_inc     = "$PWage_level"
			replace principal_pinc    = "$PWage_level"
			
			replace principal_days	  = "$Pdays"
			 
			
			replace intowork              = $TINTOW
			gen    chcare			      = $ch_care
			gen    cc_parttime		      = $cc_pt	
			replace allowsa			      = $allow_sa
			replace primsa			      = $incl_sa
			gen    postccinc		      = $post_cc
			
			
			if "$marital_stat"=="single"{
				replace sp_works		  = 0
				replace spouse_inc 		  = "0"
				replace spouse_pinc		  = "0"
				replace spouse_days		  = "0"
				global j_fixed 			  = 0 
			} 
			
			if "$marital_stat"=="married"{
				replace sp_works 		  = $spouse_works
				if $spouse_works==1{
					replace spouse_inc    = "$SEWage_level"
					replace spouse_pinc   = "$SEWage_level"	
					replace spouse_days   = "$SEdays"
					global j_fixed = 1
				}
				if $spouse_works == 2 | $spouse_works == 0 {
					replace spouse_inc	  = "0" 
					replace spouse_pinc   = "0" 
					replace spouse_days   = "0"
					global j_fixed = 0 
					}
				} 
			
		 
			global CHIL = substr("`kids'",1,1)
			
			cap program drop run_control
			
			cd "${path_baseline}"		
			do Taxbenextract_TAXBEN_modif.do
			
			global date  =  `year'
			global family  `kids'
			global marital `marital'
			global wageP wgP1_wgS${j_fixed}
			
			if "`kids'"=="0child" {
				global ch_care = 0
				global cc_pt   = 0
				global post_cc = 0
				
			}
			else{
				global ch_care = $ch_care_ref
				global cc_pt   = $cc_pt_ref
				global post_cc = $post_cc_ref
			}
			
			
			local chd_nber = substr("`kids'",1,1)
					
			if `chd_nber'==0{
			forvalues child=1/4{
				global CHAGE`child' = 0
				}
			}
					
		
			if `chd_nber'==1{
				global CHAGE1 = $CHAGE1_ref
				global CHAGE2 = 0
				global CHAGE3 = 0
				global CHAGE4 = 0
			}
				
			if `chd_nber'==2{
				global CHAGE1 = $CHAGE1_ref
				global CHAGE2 = $CHAGE2_ref
				global CHAGE3 = 0
				global CHAGE4 = 0
			}
					
			if `chd_nber'==3{
				global CHAGE1 = $CHAGE1_ref
				global CHAGE2 = $CHAGE2_ref
				global CHAGE3 = $CHAGE3_ref
				global CHAGE4 = 0
			}	
				
			if `chd_nber'==4{
				global CHAGE1 = $CHAGE1_ref
				global CHAGE2 = $CHAGE2_ref
				global CHAGE3 = $CHAGE3_ref
				global CHAGE4 = $CHAGE4_ref
			}
			
			
			run_control	
			
			* Sometimes the cleaning strategy in Taxbenextract_TAXBEN_modif does not work perfectly. Repeat this strategy.
			if "$vname" != "details"{ 

			*Ideal variable list (some of them just don't exist):
			global vlist GROSS`x' NET PoAW`x' PoAW_p PoAW_s Benefits Taxes Net_Taxes METR1 METR2 METR3 METR1_SC METR1_IT METR1_SA METR1_HB METR1_FB METR1_UB METR1_IW      ///
					  METR2_SC METR2_IT METR2_SA METR2_HB METR2_FB METR2_UB METR2_IW METR3_SC METR3_IT METR3_SA METR3_HB METR3_FB METR3_UB METR3_IW inc_tax_rate`x'        ///
					  employee_ssc_rate`x'	tot_cash_rate`x' spouse_w marstat age k1 k2 k3 k4 IT`x' SC`x' SC_p SC_s SC_general SC_general_s SC_general_p SC_NTCP           ///
					  SC_NTCP_s SC_NTCP_p tot_wedge`x' $name_selected_wage HB`x' HB_p HB_s FB`x' AW`x' FB_s FB_p UB`x' UB_s UB_p UI`x' UI UI_p UI_s UA UA`x' UA_p          ///
					  UA_s MATER`x' MATER_s MATER_p PATER`x' PATER_p PATER_s PARENT`x' SA`x' SA_s SA_p SSCR`x' SSCR_p SSCR_s SSCR_general SSCR_general_s SSCR_general_p    ///
					  SSCR_NTCP SSCR_NTCP_s SSCR_NTCP_p IW workdayp earnings workdays spousinc Receive_UB Po${name_selected_wage} time prv_earn_p cc_benefit cc_subsidy    ///
			 		  Month_unemployed Replacement_rate Net_replacement_rate CC_Fee cc_fee cc_Fee country YEAR nch 


				foreach v of varlist _all{
					if strpos("$vlist", " `v' ")==0{
						drop `v'
					}
				}	
			}
			

			cd "${path}/outputs"
			
			use "`c'_${wageP}_${sv_marital}_${sv_kids}${sv_year}.dta", clear
			qui count
			drop if _n==_N
			cap drop age
			*rename *`c' *
			gen country  = "`c'"
			cap su marstat
			if _rc!=0{
				cap rename marst marstat
					if _rc!=0{
						cap gen marstat = 0 if "$marital_stat" == 0
						cap gen marstat = 1 if "$marital_stat" == 1
					}
			}
					
			gen adult_age    = $adage						

			cap replace adult_age  = $adage if missing(adult_age)
			
			
			* Drop latest obs: METR impossible to compute. Drop also first (empty) obs
			if $run_type >1 & $run_type <5 {
				cap drop n
				cap drop identif
				cap drop max_identif
				gen  n           = 1
				gen identif      = sum(n)
				cap egen max_identif = max(identif)
				if _rc!=0{
					 su identif 
					 gen max_identif =  `r(max)'
				}
				drop if identif == max_identif
				cap drop max_identif identif n
				drop if _n==1
			}
			
			* Add some variables
			
			if $run_type > 1{ 
						
				 gen ATR			  =  (Taxes/(workdays*spousinc/5+workdayp*earnings/5)) *100
				 label var ATR "Average Tax Rate - Household Level"
							
				 gen ATR_p		  = (Taxes/(workdayp*earnings/5)) *100
				 label var ATR_p "Average Tax Rate - Principal"
				
				 gen ATR_s		  = (Taxes/(workdays*spousinc/5)) *100
				 label var ATR_s "Average Tax Rate - Secondary"						

				 gen AETR		 =  ( Net_Taxes/(workdays*spousinc/5+workdayp*earnings/5) ) *100
				 label var AETR "Average Effective Tax Rate - Household Level"
							
				 gen AETR_p		 =  ( Net_Taxes/(workdayp*earnings/5) ) *100
				 label var AETR_p "Average Effective Tax Rate - Principal"
							
				 gen AETR_s		 =  ( Net_Taxes/(workdays*spousinc/5) ) *100
				 label var AETR_s "Average Effective Tax Rate - Secondary"
			}
			
			if $run_type <= 1{
						
				 gen ATR			  =  (Taxes/Benefits) *100
				 label var ATR "Average Tax Rate - Household Level"						

				 gen AETR		 =  ( Net_Taxes/Benefits ) *100
				 label var AETR "Average Effective Tax Rate - Household Level"
							
			}
			
			
							
						
			forvalues m=1/4{
				 gen ch`m'     = 1 if k`m'>0
				 replace ch`m' = 0 if missing(ch`m')
				 rename k`m' age_ch`m'
			}

			 gen nch       =.
			 label var nch "Number of child"
			 replace nch   = ch1+ch2+ch3+ch4

			forvalues i=1/4{
				 drop ch`i'
			}
														 
			if $run_type < 2{
				cap rename time Month_unemployed
				cap label var Month_unemployed "Unemployment (month)"
				cap gen Replacement_rate     = (UB / prv_earn_p )*100
				cap gen Net_replacement_rate = (( Benefits - Taxes)/prv_earn_p)*100
				cap drop inc_tax_rate employee_ssc_rate tot_cash_rate  tot_wedge
			}
							
			if $run_type > 1{
				foreach gender in "s" "p"{
					tempvar pre_hours
					cap gen `pre_hours'     = 0.4
					if _rc!=0{
						replace `pre_hours'     = 0.4
						}
					replace `pre_hours' = 0 in 1
									
					tempvar check1 check2
					cap gen `check1' = 1 if workday`gender'[_n]!=workday`gender'[_n-1] & workday`gender'[_n]!=workday`gender'[_n+1]
					if _rc!=0{
						replace `check1' = 1 if workday`gender'[_n]!=workday`gender'[_n-1] & workday`gender'[_n]!=workday`gender'[_n+1]
						}
					cap egen `check2'= total(`check1')
					if _rc!=0{
						cap drop `check2'
						egen `check2'= total(`check1')
						}
									
					count
					if `check2'==`r(N)'{
						cap drop Hours_`gender'
						gen Hours_`gender' = round(sum(`pre_hours'),0.01) 
						}
					else{
						cap drop Hours_`gender'
						gen Hours_`gender' =  workday`gender'*40/5
						}
					}
				}
								
			 cap drop YEAR
			 gen YEAR = $sv_year
			 
			 
			 *******************************************************************
		
			* Additional Variables:
			
				*hhtype:
			
			gen str hhtype = "."
            replace hhtype = "Single"   if "$marital_stat" == "single"
            replace hhtype = "1earnerC" if "$marital_stat" == "married" & $spouse_works != 1
            replace hhtype = "2earnerC" if "$marital_stat" == "married" & $spouse_works == 1
            replace hhtype = hhtype + substr("`kids'",1,1) + "C" 
	
			
				* Benefit_source
				
			gen str Primary_Benefit_source = "."
			replace Primary_Benefit_source = "SA" if $incl_sa == 1
			replace Primary_Benefit_source = "UB" if $incl_sa == 0
			
				* Allow Social Assistance:
				
			gen str Allow_sa = "."
			replace Allow_sa = "Yes" if $allow_sa == 1
			replace Allow_sa = "No"  if $allow_sa == 0
			
				* NTCP
			foreach status in "_ee" "_er"{					
				gen str NTCP`status' = "."
				replace NTCP`status' = "Yes" if ${ntcp`status'}==1
				replace NTCP`status' = "No"  if ${ntcp`status'}==0
			}
			
			
			*******************************************************************
					 			 
			 tempfile `c'`marital'`kids'`year'S${j_fixed}
			 save ``c'`marital'`kids'`year'S${j_fixed}', replace
			}
		}
	}
}

cap drop __*
cap drop _*
macro drop sv_marital sv_kids sv_year sv_ctry
di as input "Preparing the data  ..."

 	 
*******************************************************************************

if "$ctry_list"=="all"{
	forvalues year = $min_year/$max_year{	
	 local ctry1_`year' = substr("${ctry_list`year'}",1,2)
	 local ctry2_`year' `ctry1_`year''
	 local test_ctry`year' = wordcount("${ctry_list`year'}")
	if `test_ctry`year''==1{  
		 global ctry2_list`year' =  "${ctry_list`year'}"
		}
		if `test_ctry`year''>1{
			 global ctry2_list`year' = substr("${ctry_list`year'}",3,.)
		}
	}	
}
else{		   
	 local ctry1 = substr("$ctry_list",1,2)
	 local ctry2 `ctry1'

	 local test_ctry = wordcount("$ctry_list")
	if `test_ctry'==1{  
		global ctry2_list = "$ctry_list"
	}
	if `test_ctry'>1{
	 global ctry2_list = substr("$ctry_list",3,.)
	}
}
	 
  
		*******************************************	
		*Combine files for each year across country

		
 foreach kids in $childn{
	foreach marital in $marital_stat{
		forvalues year = $min_year / $max_year{		
			if "$ctry_list"=="all"{
				 use ``ctry2_`year''`marital'`kids'`year'S${j_fixed}', clear
					if `test_ctry`year''>1{
						foreach c in ${ctry2_list`year'}{
									 append using ``c'`marital'`kids'`year'S${j_fixed}', force
									 duplicates drop
								}
							}
						}
			else{		
				 use ``ctry2'`marital'`kids'`year'S${j_fixed}', clear
					if `test_ctry'>1{
						foreach c in $ctry2_list{
									 append using ``c'`marital'`kids'`year'S${j_fixed}', force
									 duplicates drop
								}
							}
						}
				 tempfile `marital'`kids'`year'S${j_fixed}
				 save ``marital'`kids'`year'S${j_fixed}', replace
				
			}
		} 
	}


		 							 
									 
		********************
		*Combine everything:
		
 foreach kids in $childn{ 
	foreach marital in $marital_stat {
		 use ``marital'`kids'${min_year}S${j_fixed}', clear
		if $min_year != $max_year{		
			 local t = $min_year + 1
			forvalues year=`t'/$max_year{
				 append using ``marital'`kids'`year'S${j_fixed}', force
			}
		}

	 tempfile `marital'`kids'S${j_fixed}
	 save ``marital'`kids'S${j_fixed}', replace
	}
}
 
 local child3 = substr("$childn",1,6)
 local child4 `child3'

 local test4 = wordcount("$childn")
 if `test4'>1{
	 local child5 $childn
	 local child6: list child5 - child4
	 global childnn `child6'
}


 foreach marital in $marital_stat{
	 use ``marital'`child4'S${j_fixed}', clear
	if `test4'>1{
	foreach kids in $childnn{
		 append using ``marital'`kids'S${j_fixed}', force
		}
	} 
	 cap drop __*
	 cap drop *__*
	
	 duplicates drop
	 tempfile NIDAT_FINAL_`marital'	
	 cap drop tt
	 bys country YEAR: gen tt = _n
	 bys country YEAR: egen max_tt = max(tt)
	 drop if tt == max_tt
	 cap drop tt max_tt	 
	 save `NIDAT_FINAL_`marital'', replace
}  


 ********************************************************************************

 
		*********************
		* Graph option:
 

if "$graph"!=""{
	set graphics off
	di as input "Creating the graphs ... "
	tempfile graphs
	save `graphs', replace
	foreach c in $ctry_list {
	use `graphs', clear
	global Graph_parm = wordcount("$ctry_list")
	global cc=upper("`c'")
	keep if country=="`c'"
	
	
	
	cd "${path}"
	cap mkdir "gph"
	if _rc!=0{
	}
	cd "${path}/gph" 
	
	if $run_type > 1 & $run_type < 5 {
	 cap mkdir "rtype${run_type}"
	if _rc!=0{
	
		}
	}
	
	if $run_type < 2{
	 cap mkdir "rtype${run_type}"
	if _rc!=0{
	
		}
	}
	
	
	tempvar gph
	gen `gph' = _n
	
	cap drop test
	egen test= group(country YEAR nch workdays workdayp `gph')
	
	xtset test YEAR 
	
	bys country: egen MinYear = min(YEAR)
	local Minyear = MinYear[1]
	bys country: egen MaxYear = max(YEAR)
	local Maxyear = MaxYear[1]
	
	cap drop MinChild
	bys country YEAR: egen MinChild = min(nch) if !missing(nch)
	global Min_child = MinChild[1]
	cap drop MaxChild
	bys country YEAR: egen MaxChild = max(nch) if !missing(nch)
	global Max_child = MaxChild[1]
	
	bys country YEAR: egen MinMarstat= min(marstat)
	local Minmarstat = MinMarstat[1]
	bys country YEAR: egen MaxMarstat= max(marstat)
	local Maxmarstat = MaxMarstat[1]
	
	tempfile graphs2
	save `graphs2', replace

	 
	if $run_type > 1 & $run_type < 5{
	 cd "$path/gph/rtype${run_type}"
	 
	 
	if "$input_location"!="" & "$input_location"!="PARSPROG"{
		cap mkdir "$input_location"
		local ajout = "/$input_location"		
	}
	else{
	}
	
	cd "$path/gph/rtype${run_type}`ajout'"
	
	 cap mkdir "$cc"
	if _rc!=0{
	}
	
	
	
	 cd "$path/gph/rtype${run_type}`ajout'/${cc}"
	
	
	bys country: keep if YEAR==MinYear | YEAR==MaxYear
	
	 
	* Put caps on variable of interest in line with the baseline TAXBEN thresholds.
	* These caps are important for graphs aspects.
	
	foreach v of varlist METR1 ATR AETR{
		local note = "If necessary, data have been capped at a max level of 120 and a min level of -20"
		replace `v' = 120 if `v'>120
		replace `v' = -20 if `v'<-20
		

		forvalues married=`Minmarstat' (1) `Maxmarstat' {
		if `married'==0 local marital = "Single"
		if `married'==1 local marital = "Married"
			forvalues kids= $Min_child / $Max_child {
				foreach v of varlist METR1 ATR AETR{
					if `Minyear'==`Maxyear'{
					
						 twoway (scatter `v' PoAW if YEAR==`Minyear' & country=="`c'" & marstat==`married' & nch==`kids' , connect(l l) msize(vsmall vsmall) legend(on order(2 "`v' `Minyear'" )))   ///
						(scatter `v' PoAW if YEAR==`Maxyear' & country=="`c'" & marstat==`married' & nch==`kids' , connect(l l) msize(vsmall vsmall) title("`v' Evolution - `Minyear'") 					///
						subtitle("$cc, `marital' with `kids' child") ytitle("`v'", size(small)) graphregion(color(white)) note("`note'", size(vsmall)) saving("${path}/gph/rtype${run_type}`ajout'/${cc}/`v'`c'`Minyear'_`marital'`kids'child.gph" , replace ))
					}
	
					else{
					
						 twoway (scatter `v' PoAW if YEAR==`Minyear' & country=="`c'" & marstat==`married' & nch==`kids' , connect(l l) msize(vsmall vsmall) legend(on order(1 "`v' `Minyear'" 2 "`v' `Maxyear'" ))) 	///
						(scatter `v' PoAW if YEAR==`Maxyear' & country=="`c'" & marstat==`married' & nch==`kids' , connect(l l) msize(vsmall vsmall) title("`v' Evolution - `Minyear'-`Maxyear'") 								///
						subtitle("$cc, `marital' with `kids' child") ytitle("`v'", size(small)) graphregion(color(white)) note("`note'", size(vsmall)) saving("${path}/gph/rtype${run_type}`ajout'/${cc}/`v'`c'`Minyear'_`Maxyear'_`marital'`kids'child.gph" , replace )) 
					
					}
				}
			} 
		}
	}
}
			
			
			
	if $run_type == 0 {
	
	 cd "$path/gph/rtype${run_type}"
	 
	 
	 if "$input_location"!="" & "$input_location"!="PARSPROG"{
		cap mkdir "$input_location"
		local ajout = "/$input_location"		
	}
	else{
	}
	
	cd "$path/gph/rtype${run_type}`ajout'"
	
	
	cap mkdir "${cc}"
	if _rc!=0{
	}
		
	 cd "$path/gph/rtype${run_type}`ajout'/${cc}"

		forvalues married=`Minmarstat' (1) `Maxmarstat' {
		if `married'==0 local marital "Single"
		if `married'==1 local marital "Married"
		forvalues kids=$Min_child (1) $Max_child {
			
			use `graphs2', clear

	
			keep if marstat==`married' & nch==`kids'
			
			label var Month_unemployed  "Unemployment spell (in month)"

			
			cap ds UB
			if _rc==0{
			local graph_list`married'`kids' "UB"
			label var UB 				"Unemployment Benefits"
			}
			if _rc!=0{
			}
			

			
		    cap mean(UA)			
			if _rc == 0 {
			mat b=e(b)
			gen temp=b[1,1]
			local temp`c'`married'`kids' = temp[1]
			drop temp
			if (`temp`c'`married'`kids''!=0 & !missing(`temp`c'`married'`kids'') & `temp`c'`married'`kids''<.){
			local graph_list`married'`kids' "`graph_list`married'`kids'' UA"
			label var UA 				"Unemployment Assistance"
				}
			}
			if _rc!=0{	
			local exclude "UA"
			local graph_list`married'`kids': list uniq graph_list`married'`kids'
			local graph_list`married'`kids': list graph_list`married'`kids' - exclude
			 cap mean(UA_p)
			if _rc == 0 {
			mat b  = e(b)
			gen temp = b[1,1]
			local temp`c'`married'`kids' = temp[1]
			drop temp
			if `temp`c'`married'`kids''!=0 & !missing(`temp`c'`married'`kids'') & `temp`c'`married'`kids''<.{
			local graph_list`married'`kids' "`graph_list`married'`kids'' UA_p"
			label var UA_p 			"UA received by principal"
					}
				}
			}
							
			
			cap mean(UI_p)
			if _rc==0 {
			mat b = e(b)
			gen temp = b[1,1]
			local temp`c'`married'`kids' = temp[1]
			drop temp
			if `temp`c'`married'`kids''!=0 & !missing(`temp`c'`married'`kids'') & `temp`c'`married'`kids''<.{
			local graph_list`married'`kids' "`graph_list`married'`kids'' UI_p"
			label var UI_p			    "Unemployment Insurance - Principal"
				}
			}

			
			
			local exclude "UB"			
			local graph_decompos`married'`kids': list graph_list`married'`kids' - exclude
			local num`married'`kids': word count `graph_decompos`married'`kids''

			di "`num`married'`kids''"
			di "`graph_decompos`married'`kids''"
			
			
			if `num`married'`kids''==0{
			* Some countries like australia do not provide any help.
			}
			
			else{
			
			foreach v in `graph_decompos`married'`kids''{
			gen `v'_gd  = `v'/earnings*100
			label var `v'_gd "`v' as % of $name_selected_wage_p"
			gen `v'_gdPrev =  `v'/prv_earn_p*100
			label var `v'_gdPrev "`v' as % of prev. earnings"
			order `v'_gd*
			}
			
			if `num`married'`kids''==2{	
				local longueur = length("`graph_decompos`married'`kids''")
				if `longueur'==5{
				local gd1 = substr("`graph_decompos`married'`kids''",1,2)
				local gd2 = substr("`graph_decompos`married'`kids''",4,2)
				}
				if `longueur'>5 & substr("`graph_decompos`married'`kids''",3,1)== " "{
				local gd1 = substr("`graph_decompos`married'`kids''",1,2)
				local gd2 = substr("`graph_decompos`married'`kids''",4,4)
				}
				if `longueur'>5 & substr("`graph_decompos`married'`kids''",3,1)== "_"{
				local gd1 = substr("`graph_decompos`married'`kids''",1,4)
				local gd2 = substr("`graph_decompos`married'`kids''",6,4)
				}
			}
			
			
			if `num`married'`kids''==1{
				local longueur = length("`graph_decompos`married'`kids''")
				if `longueur'==2{
				local gd1 = substr("`graph_decompos`married'`kids''",1,2)
				}
				if `longueur'==4{
				local gd1 = substr("`graph_decompos`married'`kids''",1,4)
				}
			} 

			local PW = $PWage_level*100
			local SW = $SEWage_level*100
			local Couuntry=upper("`c'")
			if "`Minyear'"!="`Maxyear'" local Year_title="`Minyear'-`Maxyear'"
			if "`Minyear'"=="`Maxyear'" local Year_title="`Minyear'"
			}
			


			if `num`married'`kids''==2{
				foreach x in "gd" "gdPrev"{
					forvalues i=1/2{
					 cap mean(`gd`i''_`x')
					mat b = e(b)
					gen temp=b[1,1]
					local temp_gd`i'_`x' = temp[1]
					drop temp
					}
				}	
			}
			
			
			if `num`married'`kids''==2{
				foreach x in "gd" "gdPrev"{
				if "`x'"=="gd" 		local h = "$name_selected_wage_p"
				if "`x'"=="gdPrev"  local h = "PrevWg"
				if "`gd1'_`x'"=="UI_p" | "`gd2'_`x'"=="UI_p" local g = "UI_p: unemployment insurance received by the principal" 
				if "`Minyear'"!="`Maxyear'" local Year_title="`Minyear'-`Maxyear'"
				if "`Minyear'"=="`Maxyear'" local Year_title="`Minyear'"
				if "`Minyear'"!="`Maxyear'" local size = "vsmall"
				if "`Minyear'"=="`Maxyear'" local size = "small"
				
				foreach v of varlist `gd1'_`x' `gd2'_`x' {
					if (`v'>120 | `v'<-20) local note = "Data for `v' have been capped at a max level of 120 and a min level of -20"
					replace `v'=120 if `v'>120
					replace `v'=-20 if `v'<-20
				}
				
					if `married'==1{
						local subtitle = "Previous wage level : P: `PW' % of $name_selected_wage_p - S: `SW' % of $name_selected_wage_s"
						local note1    = "Principal supposed to work $Pdays days/week (8h per day), secondary $SEdays days."
					}
					if `married'==0{
						local subtitle = "Previous wage level : P: `PW' % of $name_selected_wage_p"
						local note1    = "Principal supposed to work $Pdays days/week (8h per day)."
					}
					
					if (`temp_gd1_`x''!=0 & !missing(`temp_gd1_`x'') & `temp_gd2_`x''!=0 & !missing(`temp_gd2_`x'')){	
					local e = "UB = `gd1'+`gd2'"
					
						
					twoway (scatter `gd1'_`x' Month_unemployed if country=="`c'" & marstat==`married' & nch==`kids', msize(`size')) ///
							   (scatter `gd2'_`x' Month_unemployed if country=="`c'" & marstat==`married' & nch==`kids', msize(`size') ylabel(,labsize(tiny)) by(YEAR, title("UB decomposition over unemployment spell - `Couuntry' - `Year_title'") 									///
								subtitle("`subtitle'") legend("`e'" ring(5.5)) graphregion(color(white)) note("`note1'" "`e'" "`note'") cap("`g'", size(vsmall)))  ///
								saving("${path}/gph/rtype${run_type}`ajout'/${cc}/UB`h'decomp`Minyear'to`Maxyear'_`marital'`kids'child.gph", replace))
								}
							
					if ((`temp_gd1_`x''==0 | missing(`temp_gd1_`x'')) & `temp_gd2_`x''!=0 & !missing(`temp_gd2_`x'')){
					local e = "UB = `gd2'"
					twoway (scatter `gd2'_`x' Month_unemployed if country=="`c'" & marstat==`married' & nch==`kids', msize(`size') ylabel(,labsize(tiny)) by(YEAR, title("UB decomposition over unemployment spell - `Couuntry' - `Year_title'") 									  ///
								subtitle("`subtitle'") legend("`e'" ring(5.5)) graphregion(color(white)) note("`note1'" "`e'" "`note'") cap("`g'", size(vsmall)))  ///
								saving("${path}/gph/rtype${run_type}`ajout'/${cc}/UB`h'decomp`Minyear'to`Maxyear'_`marital'`kids'child.gph", replace))
								}
								
					if ((`temp_gd2_`x''==0 | missing(`temp_gd2_`x'')) & `temp_gd1_`x''!=0 & !missing(`temp_gd1_`x'')){	
					local e = "UB = `gd1'"
				 twoway (scatter `gd1'_`x' Month_unemployed if country=="`c'" & marstat==`married' & nch==`kids', msize(`size') ylabel(,labsize(tiny)) by(YEAR, title("UB decomposition over unemployment spell - `Couuntry' - `Year_title'")  									  ///
								subtitle("`subtitle'") legend("`e'" ring(5.5)) graphregion(color(white)) note("`note1'" "`e'" "`note'") cap("`g'", size(vsmall)))  ///
								saving("${path}/gph/rtype${run_type}`ajout'/${cc}/UB`h'decomp`Minyear'to`Maxyear'_`marital'`kids'child.gph", replace))
								}						
							}
						}
						
			if `num`married'`kids''==1{
			foreach x in "gd" "gdPrev"{
			if "`x'"=="gd" 		local h = "$name_selected_wage "
			if "`x'"=="gdPrev"  local h = "PrevWg"
			if "`gd1'_gd"=="UI_p" local g = "UI_p: unemployment insurance received by the principal" 
			if "`Minyear'"!="`Maxyear'" local Year_title="`Minyear'-`Maxyear'"
			if "`Minyear'"=="`Maxyear'" local Year_title="`Minyear'"
			if "`Minyear'"!="`Maxyear'" local size = "vsmall"
			if "`Minyear'"=="`Maxyear'" local size = "small"
			local e = "UB = `gd1'"
			if `married'==1{
				local subtitle = "Previous wage level : P: `PW' % of $name_selected_wage_p - S: `SW' % of $name_selected_wage_s"
				local note1    = "Principal supposed to work $Pdays days/week (8h per day), secondary $SEdays days."
			}
			if `married'==0{
				local subtitle = "Previous wage level : P: `PW' % of $name_selected_wage_p"
				local note1    = "Principal supposed to work $Pdays days/week (8h per day)."
			}
			
				 twoway (scatter `gd1'_`x' Month_unemployed if country=="`c'" & marstat==`married' & nch==`kids', msize(`size') ylabel(,labsize(tiny)) by(YEAR, title("UB decomposition over unemployment spell - `Couuntry' - `Year_title'") 			///
							subtitle("`subtitle'") graphregion(color(white)) note("`note1'") cap("`g'" "`e'", size(vsmall))) ///
							saving("${path}/gph/rtype${run_type}`ajout'/${cc}/UB`h'decomp`Minyear'to`Maxyear'_`marital'`kids'child.gph", replace))
							}
						}
			
			
			local graph_list4`married'`kids': list uniq graph_list`married'`kids'
			foreach v in `graph_list4`married'`kids''{
			 cap mean(`v')
			mat b = e(b)
			gen temp=b[1,1]
			local temp = temp[1]
			drop temp
			local PW = $PWage_level*100
			local SW = $SEWage_level*100
			if ( `temp'!=0 & !missing(`temp') ){
			if "`Minyear'"!="`Maxyear'" local Year_title="`Minyear'-`Maxyear'"
			if "`Minyear'"=="`Maxyear'" local Year_title="`Minyear'"
			if "`Minyear'"!="`Maxyear'" local size = "vsmall"
			if "`Minyear'"=="`Maxyear'" local size = "small"	
			local Couuntry=upper("`c'")
			if `married'==1{
				local subtitle = "Previous wage level : P: `PW' % of $name_selected_wage_p - S: `SW' % of $name_selected_wage_s"
				local note1    = "Principal supposed to work $Pdays days/week (8h per day), secondary $SEdays days."
			}
			if `married'==0{
				local subtitle = "Previous wage level : P: `PW' % of $name_selected_wage_p"
				local note1    = "Principal supposed to work $Pdays days/week (8h per day)."
			}
			if "`v'"=="UI_p" local g = "UI_p: unemployment insurance received by the principal" 
			 twoway (scatter `v' Month_unemployed if country=="`c'" & marstat==`married' & nch==`kids', msize(`size') ylabel(,labsize(tiny)) by(YEAR, title("`a' evolution over unemployment spell - `Couuntry' - `Year_title'")     		    ///
							subtitle("`subtitle'") graphregion(color(white)) note("`note1'") cap("`g'", size(vsmall))) ///
							saving("${path}/gph/rtype${run_type}`ajout'/${cc}/`v'`Minyear'to`Maxyear'_`marital'`kids'child.gph", replace))
						}
					}
				}
			}
		}
	
	
	if $run_type == 1{
	
	 cd "$path/gph/rtype${run_type}"
	 
	 if "$input_location"!="" & "$input_location"!="PARSPROG"{
		cap mkdir "$input_location"
		local ajout = "/$input_location"		
	}
	else{
	}
	
	cd "$path/gph/rtype${run_type}`ajout'"
	
	
	cap mkdir "${cc}"
	if _rc!=0{
	}
		
	 cd "$path/gph/rtype${run_type}`ajout'/${cc}"

		forvalues married=`Minmarstat' (1) `Maxmarstat' {
		if `married'==0 local marital "Single"
		if `married'==1 local marital "Married"
			forvalues kids=$Min_child (1) $Max_child {
			
			use `graphs2', clear
			
			keep if nch==`kids' & marstat==`married'
			
			label var prv_earn_p "Previous earnings"
			
			 cap ds UB
			if _rc==0{
			local graph_list`married'`kids' "UB"
			label var UB 				"Unemployment Benefits"
			}
			if _rc!=0{
			}
			

			
			 cap mean(UA)			
			if _rc == 0 {
			mat b=e(b)
			gen temp=b[1,1]
			local temp`c'`married'`kids' = temp[1]
			drop temp
			if (`temp`c'`married'`kids''!=0 & !missing(`temp`c'`married'`kids'') & `temp`c'`married'`kids''<.){
			local graph_list`married'`kids' "`graph_list`married'`kids'' UA"
			label var UA 				"Unemployment Assistance"
				}
			}
			if _rc!=0{	
			local exclude "UA"
			local graph_list`married'`kids': list uniq graph_list`married'`kids'
			local graph_list`married'`kids': list graph_list`married'`kids' - exclude
			 cap mean(UA_p)
			if _rc == 0 {
			mat b  = e(b)
			gen temp = b[1,1]
			local temp`c'`married'`kids' = temp[1]
			drop temp
			if `temp`c'`married'`kids''!=0 & !missing(`temp`c'`married'`kids'') & `temp`c'`married'`kids''<.{
			local graph_list`married'`kids' "`graph_list`married'`kids'' UA_p"
			label var UA_p 			"UA received by principal"
					}
				}
			}
			
			 cap mean(UI_p)
			if _rc==0 {
			mat b = e(b)
			gen temp = b[1,1]
			local temp`c'`married'`kids' = temp[1]
			drop temp
			if `temp`c'`married'`kids''!=0 & !missing(`temp`c'`married'`kids'') & `temp`c'`married'`kids''<.{
			local graph_list`married'`kids' "`graph_list`married'`kids'' UI_p"
			label var UI_p			    "Unemployment Insurance - Principal"
				}
			}
 
			tempvar nber base
			bys YEAR marstat nch: gen `nber' = _n
			bys YEAR marstat nch: gen `base' = prv_earn_p if _n==100
			forvalues i=`Minyear'(1)`Maxyear'{
			tempvar maximum 			
			egen `maximum'= max(`base') if YEAR==`i'
			replace `base'=`maximum' if missing(`base')
					}
			
			cap drop prv_earn_p_AW 
			bys marstat nch: gen prv_earn_p_AW     = prv_earn_p/`base'*100
			replace prv_earn_p_AW = round(prv_earn_p_AW,1) 
			label var prv_earn_p_AW "Prev. earnings (% of mean previous earnings)"
			
			local graph_list2`married'`kids': list uniq graph_list`married'`kids'
			
			 
			foreach v of varlist `graph_list2`married'`kids''{	
			bys marstat nch: gen `v'_prev = `v'/prv_earn_p*100
			label var `v'_prev "`v' as % of prev. earnings"
			bys marstat nch: gen `v'_$name_selected_wage_p    = `v'/$name_selected_wage_p  * 100
			label var `v'_AW "`v' as % of AW"
			local graph_list3`married'`kids' `graph_list3`married'`kids'' `v'_prev `v'_$name_selected_wage_p 
			}
			
			
			local graph_list4`married'`kids': list uniq graph_list3`married'`kids'

					
			foreach v of varlist `graph_list4`married'`kids'' {
			 cap mean(`v')
			mat b = e(b)
			gen temp=b[1,1]
			local temp = temp[1]
			drop temp
			local PW = $PWage_level * 100
			local SW = $SEWage_level * 100
			if ( `temp'!=0 & !missing(`temp') ){
			if "`v'"=="UI_p_prev" local g = "UI_p: unemployment insurance received by the principal" 
			if "`v'"=="UA_p_prev" local g = "UA_p: unemployment assistance received by the principal" 
			if "`v'"=="UI_p_prev" | "`v'"=="UI_p" local a = substr("`v'",1,4)
			if "`v'"=="UA_p_prev" | "`v'"=="UA_p" local a = substr("`v'",1,4)
			if "`v'"=="UA_prev"   | "`v'"=="UA_p" local a = substr("`v'",1,2)
			if "`v'"=="UB_prev"   | "`v'"=="UB_p" local a = substr("`v'",1,2)
			local ctry = lower("${cc}")
			if "`Minyear'"!="`Maxyear'" local Year_title="`Minyear'-`Maxyear'"
			if "`Minyear'"=="`Maxyear'" local Year_title="`Minyear'"
			if "`Minyear'"!="`Maxyear'" local size = "vsmall"
			if "`Minyear'"=="`Maxyear'" local size = "small"
			if `married'==1{
				local subtitle = "Previous wage level : P: `PW' % of $name_selected_wage_p - S: `SW' % of $name_selected_wage_s"
				local note1    = "Principal supposed to work $Pdays days/week (8h per day), secondary $SEdays days."
			}
			if `married'==0{
				local subtitle = "Previous wage level : P: `PW' % of $name_selected_wage_p"
				local note1    = "Principal supposed to work $Pdays days/week (8h per day)."
			}
			
			 twoway (scatter `v' prv_earn_p_AW if country=="`ctry'" & marstat==`married' & nch==`kids', msize(`size') ylabel(,labsize(tiny)) by(YEAR, title(" `a' generosity - ${cc} - `Year_title'")  	                									  ///
							subtitle("`subtitle'") graphregion(color(white)) note("`note1'", size(vsmall)) cap("`g'", size(vsmall))) ///
							saving("${path}/gph/rtype${run_type}`ajout'/${cc}/`v'`Minyear'to`Maxyear'_`marital'`kids'child.gph", replace)) 
						}		
					}			
				}
			}
		}		
	}
}

 set graphics on
				
			


if "$graph"!=""{
	use `graphs', clear
}


cd "${path}/outputs"




********************************************************************************


		*************************
		* ISO country name option




if "$ISO"!=""{
	 gen country_ISO         =.
	 gen country_num		 =.
	 tostring country_ISO, replace force
	
	 replace country_ISO  = "FRA" if country=="fr"
	 replace country_num  = 250   if country=="fr"
	
	 replace country_ISO  = "AUS" if country=="al"
	 replace country_num  = 36 	  if country=="al"
	
	 replace country_ISO  = "AUT" if country=="at"
	 replace country_num  = 40 	  if country=="at"
	
	 replace country_ISO  = "BEL" if country=="be"
	 replace country_num  = 56	  if country=="be"
	
	 replace country_ISO  = "BGR" if country=="bg"
	 replace country_num  = 100	  if country=="bg"
	
	 replace country_ISO  = "CAN" if country=="ca"
	 replace country_num  = 124	  if country=="ca"
	
	 replace country_ISO  = "CHL" if country=="cl"
	 replace country_num  = 152	  if country=="cl"
	
	 replace country_ISO  = "CZE" if country=="cz"
	 replace country_num  = 203   if country=="cz"
	
	 replace country_ISO  = "DNK" if country=="dk"
	 replace country_num  = 208	  if country=="dk"
	
	 replace country_ISO  = "EST" if country=="ee"
	 replace country_num  = 233	  if country=="ee"
	
	 replace country_ISO  = "FIN" if country=="fn"
	 replace country_num  = 246	  if country=="fn"
	
	 replace country_ISO  = "DEU" if country=="ge"
	 replace country_num  =  276  if country=="ge"
	
	 replace country_ISO  = "GRC" if country=="gc"
	 replace country_num  = 300	  if country=="gc"
	
	 replace country_ISO  = "HUN" if country=="hu"
	 replace country_num  = 348	  if country=="hu"
	
	 replace country_ISO  = "ISL" if country=="ic"
	 replace country_num  = 352	  if country=="ic"
	
	 replace country_ISO  = "IRL" if country=="ir"
	 replace country_num  = 375	  if country=="ir"
	
	 replace country_ISO  = "ISR" if country=="il"
	 replace country_num  = 376	  if country=="il"
	
	 replace country_ISO  = "ITA" if country=="it"
	 replace country_num  = 380	  if country=="it"
	
	 replace country_ISO  = "JPN" if country=="jp"
	 replace country_num  = 392   if country=="jp"
	
	 replace country_ISO  = "PRK" if country=="rk"
	 replace country_num  = 408   if country=="rk"
	
	 replace country_ISO  = "LUX" if country=="lx"
	 replace country_num  = 442   if country=="lx"
	
	 replace country_ISO  = "NLD" if country=="nl"
	 replace country_num  = 528   if country=="nl"
	
	 replace country_ISO  = "NZL" if country=="nz"
	 replace country_num  = 554   if country=="nz"
	
	 replace country_ISO  = "NOR" if country=="nw"
	 replace country_num  = 578   if country=="nw"
	
	 replace country_ISO  = "POL" if country=="pl"
	 replace country_num  = 616   if country=="pl"
	
	 replace country_ISO  = "PRT" if country=="pt"
	 replace country_num  = 620   if country=="pt"
	
	 replace country_ISO  = "SVK" if country=="sk"
	 replace country_num  = 703   if country=="sk"
	
	 replace country_ISO  = "SVN" if country=="si"
	 replace country_num  = 705   if country=="si"
	
	 replace country_ISO  = "ESP" if country=="sp"
	 replace country_num  = 724   if country=="sp" 
	
	 replace country_ISO  = "SWE" if country=="sw"
	 replace country_num  = 752   if country=="sw"
	
	 replace country_ISO  = "CHE" if country=="sz"
	 replace country_num  = 756   if country=="sz"
	
	 replace country_ISO  = "TUR" if country=="tr"
	 replace country_num  = 792   if country=="tr"
	
	 replace country_ISO  = "GBR" if country=="uk"
	 replace country_num  = 826   if country=="uk"
	
	 replace country_ISO  = "USA" if country=="us"
	 replace country_num  = 840   if country=="us"
	
	 replace country_ISO  = "BGR" if country=="bg"
	 replace country_num  = 100   if country=="bg"
	
	 replace country_ISO  = "CYP" if country=="cy"
	 replace country_num  = 196   if country=="cy"
	
	 replace country_ISO  = "LVA" if country=="lv"
	 replace country_num  = 428   if country=="lv"
	
	 replace country_ISO  = "LTU" if country=="lt"
	 replace country_num  = 440   if country=="lt"
	
	 replace country_ISO  = "MLT" if country=="mt"
	 replace country_num  = 470   if country=="mt"
	
	 replace country_ISO  = "ROM" if country=="ro"
	 replace country_num  = 642   if country=="ro"
	
	}
	
	  

********************************************************************************


			**************************
			* Variable choice option:
			
			
/*
In case the user specifies only a specific policy variable, we nevertheless keep indispensable information
about the country, year, and household characteristics. A unique variable per se it meaningless with the model.
*/			

	
	if ("$vname"! = "" & "$vname"!="details"){
	local vname $vname
	if inlist("`vname'", "country")!=1{	 
		local vname  `vname'  country
	}
	if inlist("`vname'", "YEAR")!=1{
		local vname  `vname'  YEAR
	}
	if inlist("`vname'", "nch")!=1{
		local vname  `vname'  nch
	}
	if inlist("`vname'", "marstat")!=1{
		local vname  `vname'  marstat
	}
	if inlist("`vname'", "spouse_w")!=1{
		local vname  `vname' spouse_w
	}
	
	if $run_type >=2{	
		if inlist("`vname'", "PoAW*")!=1{
			local vname  `vname'  PoAW*
		}
		if inlist("`vname'", "METR1")!=1{
			local vname  `vname'  METR*
		}
		if inlist("`vname'", "ATR")!=1{
			local vname  `vname' ATR
		}
		if inlist("`vname'", "AETR")!=1{
			local vname  `vname' AETR
		}

	}
	
	if $run_type < 2{
		if inlist("`vname'", "Replacement_rate")!=1{
			local vname  `vname' Replacement_rate
		}
		if inlist("`vname'", "Month_unemployed")!=1{
			local vname  `vname' Month_unemployed
		}
		if inlist("`vname'", "UB*")!=1{
			local vname  `vname' UB*
		}
		if inlist("`vname'", "UI*")!=1{
			local vname  `vname' UI*
		}
		if inlist("`vname'", "UA*")!=1{
			local vname  `vname' UA*
		}
	}		

	 cap keep `vname'
	if _rc!=0 {
		di in red "Error: At least one variable name does not exist"
		exit
	}
}

	

********************************************************************************

		*********************
		* Order variables:

local order_var_ref = length("$name_selected_wage")
local order_var     =substr("$name_selected_wage",1,4)
		
if $run_type < 2 {
	order country* YEAR hhtype marstat nch Month_unemployed Replacement_rate Net_replacement_rate
}
if $run_type == 2 | $run_type == 3 | $run_type ==4 {
	if `order_var_ref'>3{
		order country* YEAR hhtype marstat nch PoAW* METR1 ATR AETR `order_var'*  AW earnings workdayp Hours_p  spouse_w  spousinc workdays Hours_s  			  ///
		      inc_tax_rate employee_ssc_rate tot_cash_rate tot_wedge
	}
	else{
	order country* YEAR hhtype marstat nch PoAW* METR1 ATR AETR $name_selected_wage AW earnings workdayp Hours_p  spouse_w  spousinc workdays Hours_s  			  ///
		  inc_tax_rate employee_ssc_rate tot_cash_rate tot_wedge
	}
}
if $run_type == 5{
	if `order_var_ref'>3{
	cap order country* YEAR hhtype marstat nch CC_Fee PoAW* METR1 ATR AETR `order_var'* AW earnings workdayp Hours_p spousinc spouse_w workdays Hours_s   ///
		      inc_tax_rate employee_ssc_rate tot_cash_rate tot_wedge
	if _rc!=0{
		cap order country* YEAR hhtype marstat nch PoAW* METR1 ATR AETR `order_var'* AW earnings workdayp Hours_p spousinc spouse_w workdays Hours_s      ///
				  inc_tax_rate employee_ssc_rate tot_cash_rate tot_wedge
		}
	}
	else{
	cap order country* YEAR hhtype marstat nch CC_Fee PoAW* METR1 ATR AETR $name_selected_wage AW earnings workdayp Hours_p spousinc spouse_w workdays Hours_s   ///
		      inc_tax_rate employee_ssc_rate tot_cash_rate tot_wedge
	if _rc!=0{
		cap order country* YEAR hhtype marstat nch PoAW* METR1 ATR AETR $name_selected_wage AW earnings workdayp Hours_p spousinc spouse_w workdays Hours_s      ///
				  inc_tax_rate employee_ssc_rate tot_cash_rate tot_wedge
		}
	}
}
if $run_type == 6 {	
	if `order_var_ref'>3{
	cap order country* YEAR hhtype marstat nch age* PoAW* METR1 ATR AETR `order_var'*  AW earnings workdayp Hours_p spousinc spouse_w workdays Hours_s 	     ///
		      inc_tax_rate employee_ssc_rate tot_cash_rate  tot_wedge
	if _rc!=0{
		cap order country* YEAR hhtype marstat nch PoAW* METR1 ATR AETR `order_var'* AW earnings workdayp Hours_p spousinc spouse_w workdays Hours_s   	 ///
				  inc_tax_rate employee_ssc_rate tot_cash_rate tot_wedge
		}
	}	
	else{
	cap order country* YEAR hhtype marstat nch age* PoAW* METR1 ATR AETR $name_selected_wage AW earnings workdayp Hours_p spousinc spouse_w workdays Hours_s 	     ///
			  inc_tax_rate employee_ssc_rate tot_cash_rate  tot_wedge
	if _rc!=0{
		cap order country* YEAR hhtype marstat nch PoAW* METR1 ATR AETR $name_selected_wage AW earnings workdayp Hours_p spousinc spouse_w workdays Hours_s   	 ///
				  inc_tax_rate employee_ssc_rate tot_cash_rate tot_wedge
		}
	}
}
	
	
********************************************************************************


		**********************
		* Saving and cleaning
 duplicates drop _all, force

tempfile METR${marital_stat}_`childnumber'Rtype${run_type}
save `METR${marital_stat}_`childnumber'Rtype${run_type}', replace
if "$Taxbenextract_save_name"!= ""{
	 if "$outpath_taxbenextract"==""{
		save ${Taxbenextract_save_name}.dta, replace
	 }
	if "$outpath_taxbenextract"!=""{
		cap mkdir "$outpath_taxbenextract"
		 cd "$path/outputs/$outpath_taxbenextract"
		 save ${Taxbenextract_save_name}.dta, replace
	 }	 
} 
	
cd "${path}/outputs"
	
if $initial > 0{
	 append using `temp_taxbenextract', force
	} 

foreach marit in $marital_stat{
	foreach kids in $childn {
	set more off
		forvalues year=$min_year/$max_year{ 
			foreach c in $ctry_list{
				cap cd  "${path}/outputs"
				cap erase `c'_wgP1_wgS${j_fixed}_`marit'_`kids'`year'.dta
			}	
		}
	}
} 



 cap erase ../outputs/aw.dta
 cap erase ../outputs/pers.dta
 cap erase ../outputs/pars.dta
 cap erase ../outputs/ctrl_data.dta

 cd "${path}"
 }
