			*********************************************
			**	MODIFIED VERSION OF TAXBEN.DO FOR THE  **
			**	TAXBEN EXTRACT FUNCTION				   **
			*********************************************
			
			
 
*****************************************
* taxbenextract v1.1					*
* Desbuquois Alexandre					*
* desbuquois.alexandre@gmail.com		*
* OR									*
* alexandre.desbuquois@ens-cachan.fr	*	
*****************************************


/*
The following code modifies the taxben dofile developed
by the OECD (ELS).
I dearly thank Sean Gibson for his help in the understanding of the program.
*/

	
* Program to set default values if options not used:

capture program drop defval

program define defval

	version 7

	args mvar defaultval
	
	if ("${`mvar'}" == "") | ("${`mvar'}" == ".") {
	
		// If missing, set to default
		
		global `mvar' `defaultval'
	}
 

end


capture program drop initopts

program define initopts

	version 7
	
	args mvar cfvar defaultval
	
	global `mvar'				// Clear macro variable
	
	capture global `mvar' = `cfvar'[1]	// Attempt to read control file
	
	defval `mvar' `"`defaultval'"'		// If still missing, set to default

end

	
	
	
	
set more off

* read in code for METR calculations (metr.do must be in same folder as this .do file)
* Baseline do metr.do
do taxbenextract_metr.do
	
	

**************************************************************************************************************************************************
*   
*                                                           Run using control file
*
**************************************************************************************************************************************************

macro drop DB*

capture program drop run_control
program define run_control

* Herwig Immervoll
* version 01/09/2003
* Updated by David Barber 02/14/2005
* Updated by chen Yuong (04/03/2006)
* Updated by Tatiana Gordine 20/10/07
* Updated by Dominique Paturot 03-03-08

* this sub-program
*   1. reads the control file
*   2. loops over the number of runs specified in control file using the parameters specified for each run
*   3. calls sub-program <run_pers_prog> which does the tax-benefit calcs and generates output

	version 7
	noisily
	
	global caller cfile

	
	
/* 1. read control file - Changed 02/14/2005 */

	/* Using string functions, or reassigning the argument `1' to another variable */
	/* causes strings longer than 64 characters to be truncated. I am thus removing */
	/* the following string functions. 14-02-2005 DB */
	 
	/* local c_file = trim("`1'") */
	/* local c_file = lower("`c_file'") */
	
	*display "   reading control file <" "`1'" ">..."
	
	/* Here, also, the string functions cause long file names to be truncated */
	/* if substr("`c_file'", -3, .) == ".do" { do "`c_file'" } */
	/* else { if substr("`c_file'", -4, .) == ".dta" { use "`c_file'" } */
	
	/* New version: First, assume it is a data file, and 'use' it - DB 02/14/2005 */
	capture use "`1'"
	if _rc {
		/* If there was an error with the 'use' command, see if it is a do file - DB 02/14/2005 */
		capture do "`1'"
		if _rc {
			*display as error "Choice of control file invalid (must be either <*.dta> or <*.do>)."
			}
		} 
	cd "${path}"
	capture mkdir "outputs"	
	* Efficiency gains: Locate all saved files into the same folder.	
	global OUTPATH = "outputs/"
	
	
    capture mkdir "$OUTPATH"
* addition of low case function to redfeine the variables, 26-11-09.
	quietly foreach var of varlist _all {
	
	local low = lower("`var'")
	capture rename `var' `low'
	
	}

	save "${OUTPATH}ctrl_data",replace
	
	local nRuns = _N
	
	* Download wage data:
	cd "${taxbenextract_path_inputs}"
	use input_wages.dta, clear
	cd "${path}"
	
	save "${OUTPATH}aw",replace


	* allow lower case variable name

	forvalue run = 1/`nRuns' {

		* restore control file info
		clear
		quietly set obs 10
		use "${OUTPATH}ctrl_data" in `run'

		*display "run `run':"
		global run_no = `run'

		* read comments to be included at bottom of output file
		global RUNCMNT = runcmnt[1]			/* `run' is the number of the run */
		global RUNCMNT = trim("$RUNCMNT")
		*display "$RUNCMNT"

		* read output file name
		global OUTFILE = outfile[1]
		global OUTFILE = trim("$OUTFILE") 
		*display "outfile`run': $OUTFILE"
		
		* read country
		global DB_ms = country[1]
		global DB_ms = trim("$DB_ms") 
		global DB_ms = lower("$DB_ms")
		*display "$DB_ms"

		********************************************* New addition: chen Yuong (04/03/2006)**********************************************
		* read def_wage
		global DB_avgw = def_wage[1]
		*display "$DB_avgw"
		
		********************************************* End of addition *******************************************************************
		
		* read year
		local annee1 = yr[1]
		if length("`annee1'")>2{
			local annee2 = substr("`annee1'",3,2)
			global DB_YR = `annee2'
		}
		else{
			global DB_YR = "`annee1'"
			}
		global full_yr = yr[1]
		global DB_YR = trim("$DB_YR")
		local l : length global DB_YR
		if `l' < 2 {
			cap global DB_YR = "0$DB_YR"		/* add a leading "0" to the year if only one digit */
			cap global full_yr = "0$full_yr"
		}
		
		global full_yr = "20$full_yr"
	
		* read fraction of APW or AW to be used as reference earnings
		global SHR = ref_earn[1]
		*display $SHR

		* read type of model run
		global SELECT = run_type[1]
		*display $SELECT

		* read marital status
		global DB_mars = mars[1] + 1	/* program expects 1: not married, 2: married as result from user choice (further down converted into marst=0/1) */
		*display $DB_mars

		* read "spouse works" switch
		global DB_WS = sp_works[1]
		*display $DB_WS
		
		* read "Child Care YES/NO" switch
		
		global ch_care = $ch_care

		
		/* new childcare switch, 25-03-11, DP*/
		
		global cc_pt = $cc_pt
		

		* read "Compute Income Measures POST-CHILD CARE COST" switch
		
		global post_cc = $post_cc
		
		* set/read number of children
		if "$CHAGE1"!="0" {
			global CHIL = ($CHAGE1>0 + $CHAGE2>0 + $CHAGE3>0 + $CHAGE4>0)
		}
		if "$CHAGE1"!="0" {
							
			global CHIL = nch[1]
		}
			
			
		* Get adult's ages
				
		global adage = $adage
		
		* Get contribution record

		initopts crec cont_record "= max(0, ($adage - 18) * 12)"
		
		*global crec

		*capture global crec = cont_record[1]
		
		*if ("$crec" == ".") | ("$crec" == "")	{
		
		*	global crec = max(0, ($adage - 18) * 12)
		
		*}

		* read "primary benefit is Social Assistance" switch
					
		global incl_sa = primsa[1]
			
		* read "allow Social Assistance" switch
			
		global allow_sa = allowsa[1]
		

		* read "Write Taxes and Contributions as Negative Values" switch
		
		*initopts taxAsNeg taxasneg
		
		global taxAsNeg = 1
		
		*display "$taxAsNeg"
		
		
		****************** chen, 25/01/2006 **************************
		* read "Definition of APW/AW " switch
		* set direction of definition choice to "avgw" by default			
		
		initopts avgw def_wage 1
		
		*global avgw = 1
		
		*capture global avgw = def_wage[1]
		
		*display "$avgw"
						

				
******************************** from person two earn.do (23/05/2006) *******************************
* Read optional parameters from control file:
* if not specified in control file then appropriate default values are used depending on scenario

// Following macro vars now default to "", as expected by person single earn.do and person two earn.do
		
		/* whether or not spouse is insured */
				
		global sps_ins = spouse_ins[1]
				
		* spousal earnings as fraction of reference earnings (1=100%)
		
		
		global sps_inc = spouse_inc[1]
		  		
		* principal's earnings as fraction of reference earnings (1=100%)
			
		
		global pri_inc = principal_inc[1]
		
		* spousal previous earnings as fraction of reference earnings (1=100%)
			
		
		global sps_pinc = spouse_pinc[1]
				
		* principal's previous earnings as fraction of reference earnings (1=100%) */
		
		
		global pri_pinc = principal_pinc[1]
					

		* spouse's number of days per week worked */
		
		
		global sps_dw = spouse_days[1] 
				
		* principal's number of days per week worked */
		/* reset value to begin with */
			
		*initopts pri_dw principal_days
		
		global pri_dw = principal_days[1]
	
		
************************************************ end of addition *******************************************************
		
		
		* read list of variables to be written to output
		* capture gen str1 outvars = ""
		local n = 0
		local add = ""
		global OUTVARS ""
		while "`add'" != "." {
			local n = `n'+1
				*di "n: `n'"
			local add = ""
			local varname = "outvar`n'" + "[1]"
			capture local add = `varname'
				*di "add: `add'"
			local add = trim("`add'")
			if "`add'" != "." & "`add'" != "" {
				global OUTVARS "$OUTVARS `add' "
			}
			else {
				local add = "."
			}
			*di "$OUTVARS"
		}
		
		* 3. run household generator and t/b calcs plus generate output based on specified run parameters
		quietly run_pers_prog
		
		
				
	} /* loop over model runs */

global caller

end 









******************************************************************************************************************************************************
*
*                                                       PERS_PROG
*
******************************************************************************************************************************************************
*
capture program drop run_pers_prog
program define run_pers_prog

	cd "${path}"
	capture mkdir "outputs"	
	global OUTPATH = "outputs/"
    capture mkdir "$OUTPATH"

* this sub-program
*     1. generates household types for each of the runs (APW values, <person.do>, etc.)
*     2. reads tax-benefit parameters for each of the runs (<XXparmYY.do>, etc.)
*     3. runs tax-benefit calculations (<XXprogYY.do>) for each of the runs
*     4. writes output

/*
	local file "`1'"
	local cmnt "`2'" 
	local outvars "`3'"
	* recover spaces in strings being passed into the sub-program
	local file = subinstr("`file'", "#%", " ", .)
	local cmnt = subinstr("`cmnt'", "#%", " ", .)
	local outvars = subinstr("`outvars'", "#%", " ", .)
	
*/
	
if "$DB_ms"=="all" {

	global DB_ms "$all_country"
		
}
	
global full_yr = "$DB_YR"
	
if $full_yr < 95 {
		
	global full_yr = "20$full_yr"
}
	
else {
		
	global full_yr = "19$full_yr"
	
}

local q "$DB_YR"

local matrix1 "$DB_ms"

foreach x of local matrix1 {
	
	if "$forced_wage" != "" {
	
		local wage_x $forced_wage
	
	}
	
	else {
	
		local wage_x `x'
	
	}
	cd "$path"
	use "${OUTPATH}aw", clear
	
	keep if country == "$sv_ctry"
	keep if year    == $sv_year
	preserve
	
	*Identify the selected refwafe for the principal:
	
	if "$selected_wage_p" == "Average Worker"{
		sort type
		keep if type                 == "$selected_wage_p" 
		global APW				     = value[1]
		global AW				     = $APW
		global true_AW			     = $APW
		global true_APW			     = $APW
		global value_selected_wage_p = $APW
		global percent 			   = 1
		}
	else{
		keep if  type == "$selected_wage_p" | type == "Average Worker"
		if substr("$selected_wage_p",1,1)=="A"{
			sort type
			global value_selected_wage_p = value[1]
			global APW				   	 = $value_selected_wage_p
			global AW 				   	 = $APW
			global true_APW	           	 = value[2]
			global true_AW 			   	 = $true_APW
			*global percent 			   	 = percent_value[1]
		}
		else{ 
			sort type
			global value_selected_wage_p = value[2]
			global APW				     = $value_selected_wage_p
			global AW				     = $APW
			global true_APW			     = value[1]
			global true_AW			     = $true_APW
			*global percent 			     = percent_value[2]
			}	
		}
	restore
	
	* Identify the selected reference wage for the secundary earner:
	
	if "$selected_wage_s" == "Average Worker"{
		sort type
		keep if type                 == "$selected_wage_s" 
		global APW				     = value[1]
		global AW				     = $APW
		*global true_AW			     = $APW
		*global true_APW			     = $APW
		global value_selected_wage_s = $APW
		global percent 			     = 1
		}
	else{
		keep if  type == "$selected_wage_s" | type == "Average Worker"
		if substr("$selected_wage_s",1,1)=="A"{
			sort type
			global value_selected_wage_s = value[1]
			global APW_s			   	 = $value_selected_wage_s
			global AW_s				   	 = $APW
			*global true_APW	           	 = value[2]
			*global true_AW 			   	 = $true_APW
			*global percent 			   	 = percent_value[1]
		}
		else{
			sort type
			global value_selected_wage_s = value[2]
			global APW_s				 = $value_selected_wage_s
			global AW_s				     = $AW
			*global true_APW			     = value[1]
			*global true_AW			     = $true_APW
			*global percent 			     = percent_value[2]
			}	
		}

	*********************************************
	* RUN PERS.DO FILE (GENERATES HOUSEHOLDS)
	*********************************************
	
	version 7		
	
	if $DB_mars==2 & $DB_WS==1 {
		cd "$path_baseline"
		quietly do "person_two_earn_taxbenextract.do"
		
	}
	
	else {
		cd "$path_baseline"
		quietly do "person_single_earn_taxbenextract.do"
		
	}
	
	version 7

	*********************************************
	* RUN PARM.DO FILE (READS TAX-BENEFIT PARAMETERS)
	*********************************************
	
	local parm_x `x'

	cd "$path"
	quietly do "$input_location/`parm_x'parm`q'"
	

	version 7
	
	gen aver=1

	*********************************************
	* MERGE THE TWO so both household characteristics and t/b params are accessible from dataset
	*********************************************
	clear
	
	set obs 10

	cap noisily use "${OUTPATH}pers"
	
	/* add APW variable and year*/
	cap gen AW 					  = $true_AW
	cap gen $name_selected_wage_p = $value_selected_wage_p
	cap gen $name_selected_wage_s = $value_selected_wage_s
	cap gen Percent_AW 			  = $percent
	cap noisily gen YEAR 		  = $full_yr

	/* merge in parameter dataset */

	cap noisily merge using "${OUTPATH}/pars"	/* x is the country code */
	
	cap noisily drop _merge		/* _merge is merely a status variable describing the outcome of the merge */	

	*********************************************
	* RUN TAX-BENEFIT CALCULATIONS
	*********************************************

	local prog_x `x'
 
	quietly do $input_location/`prog_x'prog`q'

	version 7
	
	 
	 
	 
	if $incl_sa == 0{
		gen Receive_UB=.
		tostring Receive_UB, replace force
		replace Receive_UB="YES"
	if _rc!=0{
		}
	}
	
	
	
	if $incl_sa==1{ 
		gen Receive_UB=.
		tostring Receive_UB, replace force
		replace Receive_UB="NO"
	}

		
	cap rename NETINC NET
	
	*capture generate EARN`x'=earnings
	capture generate EARN`x'= $value_selected_wage_p
	capture rename GRSRR GRR`x'
	 
	global metr_c = "`x'" 

	metr "`x'"		/* compute METRs */

	if $run_type >1 {
		cap generate PoAW					 = max(0, round((GROSS/($true_AW))*100, 0.1)) 
		*cap generate Po${name_selected_wage} = max(0, round((GROSS/($value_selected_wage))*100, 0.1))
	}

	/* change sign of taxes if specified or depending on run typ if nothing specified */
	
	if "$taxAsNeg" == "y" | "$taxAsNeg" == "1" {
	
		capture replace IT=-IT
		capture replace SC=-SC
		
	}
	
	if "$taxAsNeg" == "" {
	
		capture replace IT=-IT if ($SELECT==2 | $SELECT==3 | $run_type==2 | $run_type==3)
		capture replace SC=-SC if ($SELECT==2 | $SELECT==3 | $run_type==2 | $run_type==3)

	}	

gen inc_tax_rate      = IT/GROSS*100
gen employee_ssc_rate = SC/GROSS*100
gen tot_cash_rate     = (GROSS-NET)/GROSS*100
gen tot_wedge         = (GROSS-NET+SSCR)/(SSCR+GROSS)*100
 
 
********************************************************
********************************************************

gen PoAW_s               = ((workdays*spousinc/5)/${true_APW} )*100
label var PoAW_s "Earnings of the secundary earner expressed as a fraction of the AW" 
gen PoAW_p               = ((workdayp*earnings/5)/${true_APW} )*100
label var PoAW_p "Earnings of the principal earner expressed as a fraction of the AW"
replace PoAW_p           = round(PoAW_p, 0.1)
replace PoAW_s 	         = round(PoAW_s, 0.1)


cap gen Benefits         = HB + FB + SA + UB + IW 
cap ds cc_subsidy
if _rc==0{
	tempvar test1 test2
	gen `test1'  = 1 if cc_subsidy==. 
	egen `test2' = total(`test1')
	di `test2'
	replace Benefits = Benefits + cc_subsidy if `test2'<5
}

replace Benefits  = 0 if ((Benefits<0.01 & Benefits>0) | (Benefits>-0.01 & Benefits<0))
gen Taxes         = abs(IT) + abs(SC)
gen Net_Taxes     = abs(Taxes) - Benefits 
 

foreach var in "SSCR_p" "SSCR_s" "SSCR" "IT" "SC" "HB" "HB_p" "HB_s" "IW" "IW" "SA" "SA_p" "SA_s" "UA" "UA_p" "UA_s" ///
				"UI" "UI_p" "UI_s" "FB" "UB" "MATER_p" "MATER_s" "MATER" "PATER_p" "PATER" "PARENT" "cc_subsidy" {
				cap replace `var'=0 if missing(`var')
}


 
* Create a list containing all variable names:
 
if "$vname" != "details"{ 

*Ideal variable list (some of them just don't exist):

if "$split"=="yes"{
	global vlist GROSS NET PoAW PoAW_p PoAW_s Benefits Taxes Net_Taxes METR1 METR2 METR3 METR1_SC METR1_IT METR1_SA METR1_HB METR1_FB METR1_UB METR1_IW       ///
				 METR2_SC METR2_IT METR2_SA METR2_HB METR2_FB METR2_UB METR2_IW METR3_SC METR3_IT METR3_SA METR3_HB METR3_FB METR3_UB METR3_IW inc_tax_rate      ///
				 employee_ssc_rate	tot_cash_rate spouse_w marstat age k1 k2 k3 k4 IT SC SC_p SC_s SC_general SC_general_s SC_general_p SC_NTCP        ///
				 SC_NTCP_s SC_NTCP_p tot_wedge $name_selected_wage HB HB_p HB_s FB AW FB_s FB_p UB UB_s UB_p UI UI UI_p UI_s UA UA UA_p        ///
				 UA_s MATER MATER_s MATER_p PATER PATER_p PATER_s PARENT SA SA_s SA_p SSCR SSCR_p SSCR_s SSCR_general SSCR_general_s SSCR_general_p  ///
				 SSCR_NTCP SSCR_NTCP_s SSCR_NTCP_p IW workdayp earnings workdays spousinc Receive_UB Po${name_selected_wage} time prv_earn_p cc_benefit cc_subsidy  ///
				  Month_unemployed Replacement_rate Net_replacement_rate CC_Fee cc_fee cc_Fee nch YEAR hhtype Primary_Benefit_source Allow_sa NTCP_ee NTCP_er
}

if "$split"=="no"{
	global vlist GROSS NET PoAW PoAW_p PoAW_s Benefits Taxes Net_Taxes METR1 METR2 METR3 METR1_SC METR1_IT METR1_SA METR1_HB METR1_FB METR1_UB METR1_IW       ///
				 METR2_SC METR2_IT METR2_SA METR2_HB METR2_FB METR2_UB METR2_IW METR3_SC METR3_IT METR3_SA METR3_HB METR3_FB METR3_UB METR3_IW inc_tax_rate      ///
				 employee_ssc_rate	tot_cash_rate spouse_w marstat age k1 k2 k3 k4 IT SC SC_general  SC_NTCP tot_wedge $name_selected_wage HB    ///
				 FB AW UB UI UI UA UA MATER PATER PARENT SA SSCR SSCR_general SSCR_NTCP IW workdayp earnings workdays spousinc        ///
				 Receive_UB Po${name_selected_wage} time prv_earn_p cc_benefit cc_subsidy Month_unemployed Replacement_rate Net_replacement_rate CC_Fee cc_fee      ///
				 cc_Fee nch YEAR hhtype Primary_Benefit_source Allow_sa NTCP_ee NTCP_er GROSS
}




	foreach v of varlist _all{
		if strpos("$vlist", " `v' ")==0 & "`v'"!="GROSS" & "`v'"!="GROSS" {
			drop `v'
		}
	}	
}

********************************************************
********************************************************
	
 save "${path}/outputs/`x'_${wageP}_${sv_marital}_${sv_kids}${sv_year}.dta" , replace

}	

end
