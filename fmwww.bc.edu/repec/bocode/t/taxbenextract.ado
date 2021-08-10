 					**********************************************
					* Program developed by: Desbuquois Alexandre *
					
	 	 
* Version 1.2 
* 29/09/2016

/*
Compared to version 1.1, the creation of a global `path' is not necessary anymore.
If the function cannot identify TAXBEN's files in the working directory, these latter
will directly be downloaded from the OECD website.
The input option has also been slightly modified.
*/	

/***************************************  
									   *
Desbuquois Alexandre				   *
desbuquois.alexandre@gmail.com		   * 
Or									   *
alexandre.desbuquois@ens-cachan.fr	   *
									   *
***************************************/

program define taxbenextract  
version 13
	syntax namelist(min=2) [, CHildnumber(string) SWOrks(string) PWage_level(string) PDays(string) SWAge_level(string) SDays(string) PRIMBEN(string) SA(string) ntcp_ee(string) ntcp_er(string) Countrylist(string) TINTOWork(string) CHILDCARE(string) CCPT(string) POSTCCI(string) Start(string) End(string) ADAGE(string) CAGE1(string) CAGE2(string) CAGE3(string) CAGE4(string) UEMonth(string) HCost(string) Vname(string) ISOcountrynames(string) GRaph(string) SPLIT(string) PREFWage(string) SREFWage(string) DERIVDecompos(string) INput(string) OUTput(string) save(string) clear ] 
	tokenize `namelist'
	local Rtype = substr("`1'",6,.)
	local marstat "`2'"

quietly{	


************************	
* Set globals:

global Max_run_type  = 6 
global Min_run_type  = 0
global maxday		 = 11
global maxwage		 = 220
global max_step		 = 3
global min_step		 = 1

global adult_def_age = 40 
global min_adult_age = 18

global Ctry_Rtype6 	"dk fr ge hu it jp uk us"
global authorized_wage = "q10 q20 q25 q30 q40 q50 q60 q70 q75 q80 q90 Median Med APW AW MW"	

************************ 

set more off, permanently

global path = "`c(pwd)'"
if "$path" == ""{
	di as input in red "Error: the current working directory cannot be identified"
}

local necessary_cond = substr("$path",-9,.)
if "`necessary_cond'" == "\PARSPROG" | "`necessary_cond'" == "/PARSPROG"{
	local length_path = length("$path")
	global path = substr("$path", 1, `length_path'-9)
}


if "$path"!=""{
	cap cd "${path}/PARSPROG"
	if _rc!=0{
		di as input "Note: files not found in working directory. Downloading from http://www.oecd.org/els/soc/Models.zip"
		copy http://www.oecd.org/els/soc/Models.zip Models.zip
		unzipfile Models.zip
	}
}
 

if "`input'"!=""{
	local input				     = "`input'"
	cap cd "$path/`input'"
	if _rc!=0{
		di as input in red "Error: The input path indicated (`input') does not exist and/or is not located into the same super/parent folder as the whole OECD TAXBEN model"
		exit
	}
	else{
		global input_location    = "`input'"
	}
}
else{
	global input_location        = "PARSPROG"
}	


if "`output'"!= ""{
	global outpath_taxbenextract = "`output'"
}
if "`output'"==""{
	global outpath_taxbenextract = ""
}


if substr("`1'",1,5)!="rtype"{
	di as input in red `"Error: The first compulsory argument is "rtypeX", with X={$Min_run_type,...,$Max_run_type} "'
	exit
}
if length("`2'")>7 | ("`2'"!="married" & "`2'"!="single"){
	di as input in red `"Error: The second compulsory argument can only be "married" or "single" "'
	exit
}
	

 cd "${path}/${input_location}"
 global taxbenextract_path_inputs = "${path}\inputs"
 
 
			**********************************
			* Identify available countries:
			
* This process is time consuming, so just do it once			

if "$taxbenextract_identif_strat"!="done" {

*Identify path to access the Baseline.dta file
	clear
	macro drop Init* Final* Term* all_country* ctry_list* 
	findfile taxbenextract.ado 
	local length = length("`r(fn)'")
	global path_baseline = substr("`r(fn)'",1, `length'-17)

	local end_numlist    = substr("$Final_year",3,.)
		if "`end_numlist'"==""{
			local end_numlist = 23 
		}
	local begin_numlist  = substr("$Init_year",4,1) 
		if "`begin_numlist'" == ""{
			local begin_numlist = 1
		}

	di as input "Identifying country/year availability (only for the first use of the function)  ..."
	cd "$taxbenextract_path_inputs"

	use input_wages.dta, clear
	su year
	global Init_year = `r(min)'
	global Final_year = `r(max)'
	keep country
	duplicates drop
	levelsof country, local(ctryy) clean
	global all_country = lower("`ctryy'")
	
	local consistency_ckeck = length("$all_country")
	
	if `consistency_ckeck'==0{
		di as input in red "Error: The global path specified does not lead to the TAXBEN files"
		exit
		}
	else{
		if `consistency_ckeck'<10 & "`input'"=="" {
			di as input "NB: Most of the OECD country files are missing in the path you have specified"
		}
	}
		
	
				*********************************
				* For each country, identify info availability:
				
	use input_wages.dta, clear
	foreach country in $all_country{
		su year 		if country == "`country'"
		global Init_year_`country'  = `r(min)'
		global Term_year_`country' = `r(max)'
	}
	
	forvalues year = $Init_year / $Final_year{
		preserve
		keep if year==`year'
		*local current_year = `year'  - 2000
		levelsof country, local(cty) clean
		*global ctry_list`current_year' = "`cty'"
		global ctry_list`year' = "`cty'"
		restore
	}
	
	macro drop Init_year_fake
	global taxbenextract_identif_strat = "done"
	clear
}



				**************************************					
		 
	
	if "`start'" != ""{
	 
	 
	if "`start'">= "$Init_year" & "`start'"<= "$Final_year" & ( round(`start',1)-`start'==0){
		global min_year = `start'
		}
	
	if (round(`start',1)-`start'!=0){
		di as input in red "Error: Year has to be an integer"
		exit
		}
		
	if "`start'"<"$Init_year"{
		if "$input_location"=="PARSPROG"{
			di as input in red "Error: Data availability starts in $Init_year"
			exit
			}
		else{
			di as input in red "Error: Data availability starts in $Init_year in the $input_location folder you want to use"
			exit
			}
		}
	if "`start'">"$Final_year"{	
		if "$input_location"=="PARSPROG"{
			di as input in red "Error: Data are available only up to $Final_year"
			exit
			}
		else{
			di as input in red "Error: Data are only available up to $Final_year in the $input_location folder you want to use"
			exit
			}
		}
	}
	
	
	if "`start'" == "" {
	
	if "`end'"==""{
		global min_year = 2010
		}
	if "`end'"!=""{
		if "`end'"<="$Final_year" & "`end'">="$Init_year"{
			global min_year = round(`end',1)
			}
		else{
			if "`end'">"$Final_year"{
				di as input in red "Error: Final year has to be smaller or equal to $Final_year"
				exit
				}
			if "`end'"<"$Init_year"{
				di as input in red " Error: Final year has to be larger or equal to $Init_year"
				exit
				}
			}
		}
	}
	    
		
		**************************************
		
	     
	if "`end'" != ""{ 
	
		if ("`end'">="`start'" & ( round(`end',1)-`end'==0) & "`end'"<="$Final_year") {
			global max_year= `end'
		}
	   
		if (round(`end',1)-`end'!=0){
			di as input in red "Error: Year has to be an integer"
			exit
		}
		
		if "`end'">"$Final_year"{
			if "$input_location"=="PARSPROG"{
				di as input in red "Error: Data are available only up to $Final_year"
				exit
				}
			else{
				di as input in red "Error: Data are available only up to $Final_year in the $input_location folder you want to use"
				exit
			}
		}
		if "`end'"<"$Init_year"{
			if "$input_location"=="PARSPROG"{
				di as input in red "Error: Data availability starts in $Init_year"
				exit
				}
			else{
				di as input in red "Error: Data availability starts in $Init_year in the $input_location folder you want to use"
				exit
			}
		}
	}
	 
	
	if "`end'" == ""{ 
		if "`start'"==""{
			global max_year = 2010
			}
		if "`start'"!="" {
			if "`start'">="$Init_year" & "`start'"<="$Final_year"{
				global max_year = round(`start',1)
				}
			else{
				if "`start'">"$Final_year"{
					di as input in red "Error: Initial year has to be lower or equal to $Final_year"
					exit
					}
				if "`start'"<"$Init_year"{
					di as input in red "Error: Initial year has to be larger or equal to $Init_year"
					exit
					}
				}
			}
		}
	
	
	if $min_year > $max_year {
		di as input in red "Error: Initial year cannot be larger than the final year selected"
		exit
		}
	
			
				**************************************

				
	if "`countrylist'" !="" {
	
		if "`countrylist'"=="all"{
			global ctry_list = "`countrylist'"
			}
		else{		
			local test1 = wordcount("`countrylist'")
			local test2=`test1'*2+ `test1'-1

			*First serie of test
			
			if `test1'==1 & length("`countrylist'")!=2{
				if "$input_location"=="PARSPROG"{
					di as input in red "Error: `countrylist' is not part of TAXBEN country codes"
					exit
					}
				else{
					di as input in red "Error: `countrylist' is not available in the $input_location folder you have created"
					exit
					}
				}
			
			forvalues value = 2/30{
				if `value'==1{
					local value2 = 2
				}
				else{
					local value2 = `value'*2 +`value' -1
				}				
				if `test1'==`value' & length("`countrylist'")!=`value2' {
					di as input in red "Error: At least one country name is mis-specified"
					exit
				}
			}
			
			
			*Second serie of test
			local ctry_list_untr1
			local test3
			forvalues f= 1(3)`test2' {
			if length("`countrylist'")==`test2' { 
					local ctry_test`f'    = substr(lower("`countrylist'"),`f',2)
					local up_ctry_test`f' = upper("`ctry_test`f''")
					
					if (strpos("$all_country", "`ctry_test`f''")!=0) {
						local test3 = `test3' + 1
					   }
					if (strpos("$all_country", "`ctry_test`f''")==0) {
						if "$input_location"=="PARSPROG"{
							di as input in red "Error: `ctry_test`f'' is not part of TAXBEN country codes"
							exit
							}
						else{
							di as input in red "Error: `ctry_test`f'' is not available in the $input_location folder you want to use"
							exit
							}
						} 

					if ( "$max_year" > "${Term_year_`ctry_test`f''}" ){
						if "$input_location"=="PARSPROG"{
							di as input in red `"Error: Information are available only up to ${Term_year_`ctry_test`f''} for country `up_ctry_test`f'' "'
							exit
							}
						else{
							di as input in red `"Error: In the $input_location folder you want to use, information are available only up to ${Term_year_`ctry_test`f''} for country `ctry_test`f'' "'
							exit
						}
					}
					
					if ( "${Init_year_`ctry_test`f''}" > "$min_year"  ){
						if "$input_location"=="PARSPROG"{
							di as input in red `"Error: Information availability starts in ${Init_year_`ctry_test`f''} for country `up_ctry_test`f'' "'
							exit
							}
						else{
							di as input in red `"Error: In the $input_location folder you want to use, information availability starts in ${Init_year_`ctry_test`f''} for country `up_ctry_test`f'' "'
							exit
							}
						}
					
					if ( ("${Init_year_`ctry_test`f''}" <= "$min_year") & ("$max_year" <= "${Term_year_`ctry_test`f''}") ){
						local validated_ctry  = "`ctry_test`f''"
						local ctry_list_untr1 = "`ctry_list_untr1' `validated_ctry'"
						}				
					}
				}
				
				
			if length("`countrylist'")!=`test2' {
				di as input in red "Error: Country codes contain only two digits."
				exit
				}
			
			if `test3'!=`test1'{
				di as input in red "Error: At least one country name is mis-specified."
				exit
			}
		 local ctry_list_untr2 = "`ctry_list_untr1'"	
		 global ctry_list: list uniq ctry_list_untr2
		 
		}
	}
							
	if "`countrylist'" == "" {
		global ctry_list "al be ge fr sz uk us"
	}			
	
	  			
				**************************************				
		 
		
	if (`Rtype'>$Max_run_type  | `Rtype'< $Min_run_type){
		di as input in red "Error: Run-types are between $Min_run_type and $Max_run_type"
		exit
	}
	if `Rtype'==6{
		if "$min_year"!="2003" | "$max_year" !="2003"{
			di as input in red "Error: Run type 6 is only available for 2003"
			exit
		}
		if "$min_year"=="2003" & "$max_year"=="2003"{
			local test1 = wordcount("$ctry_list")
			local test2=`test1'*2+ `test1'-1
			if length("$ctry_list")==`test2' {
				forvalues f=1(3)`test2'{
					local ctry_test`f'=substr(lower("$ctry_list"),`f',2)
					if strpos("$Ctry_Rtype6", "`ctry_test`f''" )!=0 {
					   local testtest = `testtest' + 1
								}
					if strpos("$Ctry_Rtype6", "`ctry_test`f''" )==0 {
						local testtest = 0
								}
							}
				if `testtest'==`test1'{
					global run_type = round(`Rtype',1)
					global SELECT   = round(`Rtype',1)

						}
				if `testtest'!=`test1'{
					di as input in red "Error: Run type 6 is only available in 2003 for Denmark (dk), France (fr), Germany (ge), Hungary (hu), Italy (it), Japan (jp), United Kingdom (uk) and the United States (us)"
					exit
					}
				}
			}
		}
		
	if `Rtype'==5{
		if "$min_year"<"2004" | "$max_year"<"2004"{
			di as input in red "Error: Run type 5 is only available after 2003"
			exit 
		}
		if "$min_year">"2008" | "$max_year">"2008"{
			di as input in red "Error: Run type 5 is only available up to 2008"
			exit
		}
		if "$min_year">"2003" & "$max_year"<"2009" & "$min_year"<="$max_year"{
			global run_type 	 = round(`Rtype',1)
			global SELECT        = round(`Rtype',1)
			global ch_care     = 1
			global CHILD_care_pt = 1
		
		}
	}
	
	if `Rtype'==0 |`Rtype'==1 | `Rtype'==2 | `Rtype'==3 | `Rtype'==4 { 
		global run_type = round(`Rtype',1)
		global SELECT   = round(`Rtype',1)
	}
	
	
	if $run_type ==6{
		global child = 1
	}
	else{
		global child = 0
	}

  
	
				**************************************	
	
	
	if "`marstat'" == "single" | "`marstat'" == "married" {
		if "`marstat'" == "single" & $run_type == 3{
			di as input in red "Error: Run-type 3 requires to select married individuals"
			exit
		}
		else{
			global marital_stat "`marstat'"
		}
	if ~("`marstat'" == "single" | "`marstat'" == "married") {
		di as input in red "Error: Marital status should be either (1) single, (2) married"
		exit
		}
	}
	
	
				**************************************		
								
	if "`childnumber'"==""{
		local childnumber2 = ""
	}
	else{
		local childnumber2 = "`childnumber'child"
	}
				
	if "`childnumber2'"==""{ 
		global childn "2child"
	}	
	
	if "`childnumber2'"!=""{ 
	if "`childnumber2'"=="0child"   | "`childnumber2'"=="1child"   | "`childnumber2'"=="2child"   |  "`childnumber2'"=="3child"  | ///
	   "`childnumber2'"=="4child"   | "`childnumber2'"=="0-1child" | "`childnumber2'"=="0-2child" | "`childnumber2'"=="0-3child" | ///
	   "`childnumber2'"=="0-4child" | "`childnumber2'"=="1-2child" | "`childnumber2'"=="1-3child" | "`childnumber2'"=="1-4child" | ///
	   "`childnumber2'"=="2-3child" | "`childnumber2'"=="2-4child" | "`childnumber2'"=="3-4child" {
		global child_ref = "`childnumber2'"
		if "`childnumber2'" == "0child"{
			if $run_type > 4{
				di as input in red "Error: run-type $run_type requires a positive number of kids"
				exit
				}
			else{
				global childn "0child"
			}
		}
		if "`childnumber2'" == "1child"{
			global childn "1child"
		}
		if "`childnumber2'" == "2child"{
			global childn "2child"
		}
		if "`childnumber2'" == "3child"{
			global childn "3child"
		}
		if "`childnumber2'" == "4child"{
			global childn "4child"
		}
		if "`childnumber2'" == "0-1child"{
			if $run_type > 4{
				di "NB: Run-type $run_type requires positive number of kids. Configuration with 0 child will be ignored."
				global childn = "1child"
				}
			else{
				global childn "0child 1child"
			}
		}
		if "`childnumber2'" == "0-2child"{
			if $run_type > 4{
				di "NB: Run-type $run_type requires positive number of kids. Configuration with 0 child will be ignored."
				global childn "1child 2child"
				}
			else{
				global childn "0child 1child 2child"
			}
		}
		if "`childnumber2'" == "0-3child"{
			if $run_type > 4{
				di "NB: Run-type $run_type requires positive number of kids. Configuration with 0 child will be ignored."
				global childn "1child 2child 3child"
				}
			else{
				global childn "0child 1child 2child 3child"
			}
		}
		if "`childnumber2'" == "0-4child"{
			if $run_type > 4{
				di "NB: Run-type $run_type requires positive number of kids. Configuration with 0 child will be ignored."
				global childn "1child 2child 3child 4child"
				}
			else{
				global childn "0child 1child 2child 3child 4child"
			}
		}		
		if "`childnumber2'" == "1-2child" | "`childnumber2'" == "2-1child" {
			global childn "1child 2child"
		}
		if "`childnumber2'" == "1-3child" | "`childnumber2'" == "3-1child"{
			global childn "1child 2child 3child"
		}
		if "`childnumber2'" == "1-4child" | "`childnumber2'" == "4-1child"{
			global childn "1child 2child 3child 4child"
		}
		if "`childnumber2'" == "2-3child" | "`childnumber2'" == "3-2child"{
			global childn "2child 3child"
		}
		if "`childnumber2'" == "2-4child" | "`childnumber2'" == "4-2child"{
			global childn "2child 3child 4child"
		}
		if "`childnumber2'" == "3-4child" | "`childnumber2'" == "4-3child"{ 
			global childn "3child 4child"
		}
	} 
}
	if ~("`childnumber2'"=="0child"   | "`childnumber2'"=="1child"   | "`childnumber2'"=="2child"   |  "`childnumber2'"=="3child"  | ///
		 "`childnumber2'"=="4child"   | "`childnumber2'"=="0-1child" | "`childnumber2'"=="0-2child" | "`childnumber2'"=="0-3child" | ///
	     "`childnumber2'"=="0-4child" | "`childnumber2'"=="1-2child" | "`childnumber2'"=="1-3child" | "`childnumber2'"=="1-4child" | ///
	     "`childnumber2'"=="2-3child" | "`childnumber2'"=="2-4child" | "`childnumber2'"=="3-4child" | "`childnumber2'"==""		   | ///
		 "`childnumber2'"=="2-1child" | "`childnumber2'"=="3-1child" | "`childnumber2'"=="4-1child" | "`childnumber2'"=="3-2child" | ///
		 "`childnumber2'"=="4-2child" | "`childnumber2'"=="4-3child") {
		   di as input in red "Error: child number should be either (1) i, with i from 1 to 4, or (2) i-j with j>i, i from a (0<a<3) to 3 and j from a+1 to 4"
		   exit
	   }
	    
	 
				****************************************
			
			
	if "`prefwage'" == ""{
			global selected_wage_p      = "Average Worker"
			global name_selected_wage_p = "AW"
		}
		
	if "`prefwage'"!= ""{
		if strpos("$authorized_wage", "`prefwage'")==0{
			di as input in red `"Error: `prefwage' is not part of the option. You have the choice between all the deciles (q10..q90), the quartiles (q25, q50, q75), the median (median) , the Average Production Wage (APW), the Average Wage (AW) and the Minimum Wage (MW)"'
			exit
		}
		if strpos("$authorized_wage", "`prefwage'")!=0{
			forvalues decile = 10(10)90{
				if lower("`prefwage'") == "q`decile'"{
					global selected_wage_p      = "All `decile'"
					global name_selected_wage_p = "Wage_q`decile'" 
					*label var $name_selected_wage "`quartile'th decile of the wage distribution"
					}
				}
			foreach quartile of numlist 25 75{
				if lower("`prefwage'") == "q`quartile'"{
					global selected_wage_p      = "All `quartile'"
					global name_selected_wage_p = "Wage_q`quartile'"
					*label var $name_selected_wage "`quartile'th quartile of the wage distribution"
					}
				}
			if lower("`prefwage'") == "aw"{
				global selected_wage_p      = "Average Worker"
				global name_selected_wage_p = "AW"
				*label var $name_selected_wage "Average Wage"
				}
			if lower("`prefwage'") == "apw" {
				global selected_wage_p      = "Average Production Worker"
				global name_selected_wage_p = "APW"
				*label var $name_selected_wage "Average Production Worker wage"
				}
			if lower("`prefwage'") == "median" | lower("`prefwage'") == "med" {
				global selected_wage_p      = "Median"
				global name_selected_wage_p = "Median"
				*label var $name_selected_wage "Median Wage"
				}
			if lower("`prefwage'") == "mw"{
				global selected_wage_p      = "Minimum wage Statutory"
				global name_selected_wage_p = "Minimum_Wage"
				}
			}
		}
		 
	   
						********************					
			
	if "`srefwage'" == ""{
			global selected_wage_s      = "Average Worker"
			global name_selected_wage_s = "AW"
		}
		
	if "`srefwage'"!= ""{
		if strpos("$authorized_wage", "`srefwage'")==0{
			di as input in red `"Error: `srefwage' is not part of the option. You have the choice between all the deciles (q10..q90), the quartiles (q25, q50, q75), the median (median) , the Average Production Wage (APW), the Average Wage (AW) and the Minimum Wage (MW)"'
			exit
		}
		 
		if "$marital_stat" == "single"{
			di as input in red "Your choice of `srefwage' for the reference wage of the secundary earner will be ignored since you have selected a single individual"
		}
		if "$marital_stat"=="married"{
			if "`sworks'"!="1" {
				di "NB: Your choice of `srefwage' for the reference wage of the secundary earner will be ignored since this latter does not work (se(0) or se(2))"
			}
			if "`swage_level'"<="0"{
				di "NB: Your choice of `srefwage' for the reference wage of the secundary earner will be ignored since this latter does not earn a positive wage"
			}
			if "`sdays'"=="0"{
				di "NB: Your choice of `srefwage' for the reference wage of the secundary earner will be ignored since this latter does not work a positive number of days"
			}
		}
				
		if strpos("$authorized_wage", "`srefwage'")!=0{
			forvalues decile = 10(10)90{
				if lower("`srefwage'") == "q`decile'"{
					global selected_wage_s      = "All `decile'"
					global name_selected_wage_s = "Wage_q`decile'" 
					*label var $name_selected_wage "`quartile'th decile of the wage distribution"
					}
				}
			foreach quartile of numlist 25 75{
				if lower("`srefwage'") == "q`quartile'"{
					global selected_wage_s      = "All `quartile'"
					global name_selected_wage_s = "Wage_q`quartile'"
					*label var $name_selected_wage "`quartile'th quartile of the wage distribution"
					}
				}
			if lower("`srefwage'") == "aw"{
				global selected_wage_s      = "Average Worker"
				global name_selected_wage_s = "AW"
				*label var $name_selected_wage "Average Wage"
				}
			if lower("`srefwage'") == "apw" {
				global selected_wage_s      = "Average Production Worker"
				global name_selected_wage_s = "APW"
				*label var $name_selected_wage "Average Production Worker wage"
				}
			if lower("`srefwage'") == "median" | lower("`srefwage'") == "med" {
				global selected_wage_s      = "Median"
				global name_selected_wage_s = "Median"
				*label var $name_selected_wage "Median Wage"
				}
			if lower("`srefwage'") == "mw"{
				global selected_wage_s      = "Minimum wage Statutory"
				global name_selected_wage_s = "Minimum_Wage"
			}
		}
	}
		 
	   
		
		
				****************************************
	
				
	if "`sworks'" == ""{
		if $run_type == 3 {
			global spouse_works = 1
			}
		else{
			global spouse_works = 0
		} 
	}
				
	   
	if "`sworks'"!=""{ 
	if ("`sworks'"=="0" |   "`sworks'"=="1" | "`sworks'"=="2" ) {
		if "`sworks'" =="0" {
			if $run_type == 3 {
				di as input in red "Error: Run type 3 varies the number of hours worked by the patner, partner has to work (se(1) has to be selected)"
				exit
			}
			if $run_type != 3 {
				global spouse_works = 0
			}
		}
		if "`sworks'" =="1"{
			global spouse_works = 1
		}
		if "`sworks'" =="2"{
			global spouse_works = 2
		}
	}
		if ("`marstat'"=="single" & ("`sworks'"=="1" | "`sworks'"=="2")){
		di as input in red "Error: you cannot be single and have a partner (working or available to work)"
		exit
		}
	
	if ~("`sworks'"=="0" |   "`sworks'"=="1" | "`sworks'"=="2") {
		di as input in red "Error: Secondary works takes three values: 1 if she/he works, 0 she/he does not, and 2 if she/he is available to work"
		exit
		}
	}
	
	
				**************************************
				
				
	if "`pwage_level'"!=""{
		if (`pwage_level'>$maxwage | `pwage_level'<0){
			di as input in red "Error: The wage level of the principal is expressed in percentage term of the average wage of the country in the corresponding year. It has to be positive, and lower than $maxwage (percent of the reference wage)"
			exit
			}
		else{
			global PWage_level = `pwage_level'/100
			global pri_inc     = "`pwage_level'"
			global pri_pinc    = "`pwage_level'"

			}
		if $run_type == 4{
			di as input "NB: The choice of the wage level for the principal will be ignored due to the run-type choice ($run_type)."
			global PWage_level = "1"
			global pri_inc     = "1"
			global pri_pinc    = "1"

		}
	}
	if "`pwage_level'"==""{
			global PWage_level = "1"
			global pri_inc     = "1"
			global pri_pinc    = "1"
	}
				
				
				**************************************
				
				
	if "`swage_level'"!=""{
		if "`marstat'"=="single"{
			di as input in red "A single-person couple cannot have a second member earning a wage"
			exit
		}
		if (`swage_level'>$maxwage | `swage_level'<0){
			di as input in red "Error: The wage level of the secondary earner is expressed in percentage term of the average wage of the country in the corresponding year. It has to be positive, and lower than $maxwage (times the average wage)"
			exit
		}
		if (("$spouse_works"=="2" | "$spouse_works"=="0") & `swage_level' >0) {
			di as input in red "Error: Secondary earner cannot earn a positive wage is she is declared as non working (sworks=0)"
			exit
		}
		if ("$spouse_works"=="1" & `swage_level'==0 ){
			di as input in red "Error: The secondary earner cannot work without receiving any wage"
			exit
		}
		if ($run_type == 3 & `swage_level'==0 ){
			di as input in red "Error: Run type 3 relies on variations of the number of hours worked by the partner. She/he has to work a positive number of hours, and thus to receive a positive wage level"
			exit
			}
		if ("$spouse_works"=="1" & `swage_level'> 0 & `swage_level'<=$maxwage & "`marstat'"=="married"){
			global SEWage_level = `swage_level'/100
			global sps_inc      = "`swage_level'"
			global sps_pinc     = "`swage_level'"
			}
	}
	if "`swage_level'"==""{
		global SEWage_level =  "1"
		global sps_inc      =  "1"
		global sps_pinc     =  "1"
		}				
				
				**************************************
				
	if "`pdays'"!=""{
		if (`pdays'>$maxday | `pdays'<0){
			di as input in red "Error: Number of days worked cannot be negative. 5 days correspond to a 40 hours week"
			exit
			}
		if ($PWage_level > 0 & `pdays'==0){
			di as input in red "Error: Principal earner cannot earn a positive wage by working zero days"
			exit
			}
		if (`pdays'>0 & `pdays'<=$maxday & $PWage_level==0){
			di as input in red "Error: Principal cannot work a positive number of days without receiving any wage"
			exit
			}
		if (`pdays'>0 & `pdays'<=$maxday  & $PWage_level>0 & $PWage_level<=$maxwage){
			global Pdays = "`pdays'"
			global wd_p	 = "`pdays'"
			if $run_type < 3 {
				di as input "NB: The choice of $Pdays days worked by the principal will be ignored due to the run-type choice ($run_type)."
				global Pdays = "0"
				global wd_p  = "0"
			}
		}

	}
	if "`pdays'"==""{
		if $run_type >= 2{
			global Pdays = "5"
			global wd_p  = "5"
		}
		else{
			global Pdays = "0"
			global wd_p  = "0"
		}
	}
	
	 
				**************************************
	
	
				
	if "`sdays'"!=""{
		if "`marstat'"=="single"{
			di as input in red "Error: A single-person couple cannot contain a second member working"
			exit
		}
		if ((`sdays'>$maxday | `sdays'<0) | (("$spouse_works"=="2" | "$spouse_works"=="0") & `sdays'>0) | (`sdays'>0 & "$SEWage_level"=="0")){
			di as input in red "Error: Number of days worked cannot be negative. 5 days correspond to a 40 hours/week. If partner does not work, her/his days number cannot be positive."
			exit
		}
		if `sdays'==0 & $run_type ==3{
			di as input in red "Error: Run type 3 relies on variations of the number of hours worked by the partner. She/he has to work a positive number of hours, and thus to receive a positive wage level"
			exit
		}
		if ("`marstat'"=="married" & (("$spouse_works"=="1" & `sdays'>0 & `sdays'<$maxday & "$SEWage_level">"0")  | (("$spouse_works"=="0" | "$spouse_works"=="2") & `sdays'==0 & "$SEWage_level"=="0"))){
			global SEdays = "`sdays'"
			global wd_s   = "`sdays'"
			}
		if $run_type == 3 {
			di as input "NB: The choice of $SEdays days worked by the secondary earner will be ignored due to the run-type choice ($run_type)."
			global SEdays = "0"
			global wd_s   = "0"
			}
	}
	if "`sdays'"==""{
		if $run_type != 3{
			global SEdays = "5" 
			global wd_s   = "5"
			}
		else{
			global SEdays = "0"
			global wd_s   = "0"
			}			
	}

		
		
				**************************************
	
	
	if "`primben'"!=""{
		local uub = lower("`primben'")
		if ("`uub'" != "ub" & "`uub'" != "sa"){
			di as input in red "Primary benefits can only take the form of unemployment benefits (UB) or social assistance (SA)"
			exit
		}
		if "`uub'"=="ub"{ 
			global incl_sa = 0
		}
		if "`uub'"=="sa"{ 
			global incl_sa = 1
		}
	}

		
	 
	if "`primben'"==""{
		if $run_type <2 {
			global incl_sa = 0
			}
		else{
			global incl_sa = 1
		}
	}
	
	global incl_SA = $incl_sa
	
	
				**************************************
	
	
	if "`sa'"!=""{
		local saa = lower("`sa'")
		if ("`saa'" != "yes" & "`saa'" != "no"){
			di as input in red "You can only authorise (yes) or not (no) the individual to receive social assistance payments"
			exit
		}
		if "`saa'"=="yes"{ 
			global allow_sa = 1
		}
		if "`saa'"=="no"{ 
			global allow_sa = 0
		}
	}

		
	
	if "`sa'"==""{
		global allow_sa = 1
	}
	
	global allow_SA = $allow_sa
	
	
				**************************************
		
		if "`ntcp_ee'" == "" {
				global ntcp_ee = 1
		}
		
		if "`ntcp_ee'" != ""{
			local small_ntcp_ee = lower("`ntcp_ee'")
			if "`small_ntcp_ee'"=="yes" | "`small_ntcp_ee'"=="no" {
				if "`small_ntcp_ee'"=="yes"{
					global ntcp_ee = 1
				}
				if "`small_ntcp_ee'"=="no" {
					global ntcp_ee = 0
				}
			}
			
			else{
				di as input in red "Error: You can only activate (yes) or desactivate (no) NTCP paid by employees"
				exit
			}
		}

		
		
		if "`ntcp_er'" == "" {
				global ntcp_er = 1
		}
		
		if "`ntcp_er'" != ""{
			local small_ntcp_er = lower("`ntcp_er'")
			if "`small_ntcp_er'"=="yes" | "`small_ntcp_er'"=="no" {
				if "`small_ntcp_er'"=="yes"{
					global ntcp_er = 1
				}
				if "`small_ntcp_er'"=="no" {
					global ntcp_er = 0
				}
			}
			
			else{
				di as input in red "Error: You can only activate (yes) or desactivate (no) NTCP paid by employers"
				exit
			}
		}
	
	
				**************************************
				

				
				
	if "`tintowork'"==""{
	global TINTOW = 0
	}
	
	if "`tintowork'"!=""{
		local intow = lower("`tintowork'")
		if "`intow'"=="yes"{
			global TINTOW = 1
			}
		if "`intow'"=="no"{
			global TINTOW = 0
			}
		if "`intow'"!="yes" & "`intow'"!="no"{
			di as input in red "Error, you can only activate transition into work (yes) or desactivate it (no)"
			exit
		}
	}  
	
	
global intoWork = $TINTOW
global intowork = $TINTOW
	
	
				**************************************
				
				
	if "`childcare'" == ""{  
	local hmchild=wordcount("$childn")
		if `hmchild'==1{
			if "$childn"=="0child"{
			global ch_care = 0
			}
			else{
			global ch_care = 1
			}
		}
		if `hmchild'>1{
		global ch_care = 1
		}
	}
	
	if "`childcare'" != ""{
		local kids_care = lower("`childcare'")
		if "`kids_care'"=="yes"{
			local hmchild=wordcount("$childn")
				if `hmchild'==1{
					if "$childn"=="0child"{
						di as input in red "Error, you cannot receive childcare benefits if you do not have kids"
						exit
						}
					else{
						global ch_care = 1
					}
				}
				if `hmchild'>1{
					global ch_care = 1
				}
			}
		if "`kids_care'"=="no"{
			if $run_type == 5{
				di as input "NB: Your choice of no childcare benefits will be ignored due to the selected run-type"
				global ch_care = 1
			}
			else{
				global ch_care = 0
				}
			}
		if "`kids_care'"!="yes" & "`kids_care'"!="no"{
			di as input in red "Error, you can only ask to activate child care (yes) or not (no)"
			exit
		} 
	} 	
	
	 
	
				**************************************
				
				
				
	if "`ccpt'"==""{
	global cc_pt = 0
	}
	
	if "`ccpt'"!=""{
		if "`ccpt'"=="0" {
			global cc_pt = "`ccpt'"
		}
		if ( "`ccpt'"=="1" | "`ccpt'"=="2"){
		local hmchild=wordcount("$childn")
			if `hmchild'==1{
				if "$childn"=="0child"{
				di as input in red "Error: You cannot justify part-time job for childcare purpose if you do not have kids"
				exit
				}
				else{
				global cc_pt = "`ccpt'"
				}
			}
			if `hmchild'>1{
			global cc_pt = "`ccpt'"
			}
		}

		if "`ccpt'"!="0" & "`ccpt'"!="1" & "`ccpt'"!="2"{
			di as input in red "Error, child care part time (ccpt) can only take three value, 0 ('full-time'), 1 ('hypo part-time') or 2 ('actual part-time')"
			exit
		}
	}
	
	
	
				**************************************
				
				
	if "`postcci'"==""{
		global post_cc = 0
	}
	
	if "`postcci'"!=""{
		if "`postcci'"=="yes"{
			local hmchild=wordcount("$childn")
			if `hmchild'==1{
				if "$childn"=="0child"{
					di as input in red "You cannot deduce childcare costs when you do not have kids"
					exit
				}
				else{
					global post_cc = 1
				}
			}
		}
		if "`postcci'"=="no"{
				global post_cc = 0
			}
		if "`postcci'"!="yes" & "`postcci'"!="no"{
			di as input in red "Error, you can only activate (yes) post child care income, or desactivate it (no)"
			exit
		}
	}
	
	
				
				**************************************
				
				
	if "`adage'"== ""{
		global adage = $adult_def_age
	}
	
	if "`adage'"!=""{
	local Adultage = substr("`adage'",1,2)
	if `Adultage'< $min_adult_age {
		di as input in red "Error: age cannot be lower than $min_adult_age"
		exit
		}
	if `Adultage'>=70{
		di as input in red "Error: people cannot work after 70 years old. The model is not made for these individuals"
		exit
		}
	if `Adultage'>0 & `Adultage'<70{
		global adage = `Adultage'
		}
	}
				
				
				
				**************************************
	 
	local nber_of_child = wordcount("$childn")
		if `nber_of_child' ==1 {
			local chd_nber=substr("$childn",1,1)
			}
		if `nber_of_child' ==2{
			local chd_nber1     = substr("$childn",1,1)
			local chd_nber_pre2 = substr("$childn",8,8)
			local chd_nber2     = substr("`chd_nber_pre2'",1,1)
			local chd_nber      = max(`chd_nber1', `chd_nber2')
			}
		if `nber_of_child' ==3{
			local chd_nber1     = substr("$childn",1,1)
			local chd_nber_pre2 = substr("$childn",8,8)
			local chd_nber2     = substr("`chd_nber_pre2'",1,1)
			local chd_nber_pre3 = substr("$childn",15,15)
			local chd_nber3        = substr("`chd_nber_pre3'",1,1)
			local chd_nber      = max(`chd_nber1', `chd_nber2', `chd_nber3')
			}
		if `nber_of_child' ==4{
			local chd_nber1     = substr("$childn",1,1)
			local chd_nber_pre2 = substr("$childn",8,8)
			local chd_nber2     = substr("`chd_nber_pre2'",1,1)
			local chd_nber_pre3 = substr("$childn",15,15)
			local chd_nber3        = substr("`chd_nber_pre3'",1,1)
			local chd_nber_pre4 = substr("$childn",22,22)
			local chd_nber4     = substr("`chd_nber_pre4'",1,1)
			local chd_nber      = max(`chd_nber1', `chd_nber2', `chd_nber3', `chd_nber4')
			}
		if `nber_of_child' ==5{
			local chd_nber1     = substr("$childn",1,1)
			local chd_nber_pre2 = substr("$childn",8,8)
			local chd_nber2     = substr("`chd_nber_pre2'",1,1)
			local chd_nber_pre3 = substr("$childn",15,15)
			local chd_nber3        = substr("`chd_nber_pre3'",1,1)
			local chd_nber_pre4  = substr("$childn",22,22)
			local chd_nber4     = substr("`chd_nber_pre4'",1,1)
			local chd_nber_pre5 = substr("$childn",29,29)
			local chd_nber5     = substr("`chd_nber_pre5'",1,1)
			local chd_nber      = max(`chd_nber1', `chd_nber2', `chd_nber3', `chd_nber4', `chd_nber5')
		}
			
					****************************
					
				if `chd_nber'==0{
					if "`cage1'"!="" | "`cage2'"!="" | "`cage3'"!="" | "`cage4'"!="" {
						di as input in red "Error: If you select zero kid, you cannot choose kid's age"
						exit
						}
					else{
						forvalues child=1/4{
						global CHAGE`child' = 0
						}
					}
				}
					
		
				if `chd_nber'==1{
					if "`cage2'"!="" | "`cage3'"!="" | "`cage4'"!="" {
						di as input in red "Error: If you only select one kid, you cannot choose the age of more that one kid"
						exit
						}
					
				if "`cage2'"=="" | "`cage3'"=="" | "`cage4'"=="" {
					if "`cage1'"=="" & $ch_care ==1{
						global CHAGE1_ref = 3
						global CHAGE2_ref = 0
						global CHAGE3_ref = 0
						global CHAGE4_ref = 0
					}
					if "`cage1'"=="" & $ch_care !=1{
						global CHAGE1_ref = 6
						global CHAGE2_ref = 0
						global CHAGE3_ref = 0
						global CHAGE4_ref = 0
					}					
					
					if "`cage1'"!=""{
						if `cage1'<30{
							global CHAGE1_ref = "`cage1'"
						}
						if `cage1'>30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						global CHAGE2_ref = 0
						global CHAGE3_ref = 0
						global CHAGE4_ref = 0
					}					
				}
			}
				
				
					****************************

				
				
				if `chd_nber'==2{
					if "`cage3'"!="" | "`cage4'"!="" {
						di as input in red "Error: If you only select two kids, you cannot choose the age of more that two kids"
						exit
						}
					
					if "`cage1'"=="" & "`cage2'"==""{
						if $ch_care ==1{
							global CHAGE1_ref = 3
							global CHAGE2_ref = 2
							global CHAGE3_ref = 0
							global CHAGE4_ref = 0
						}
						if $ch_care !=1{
							global CHAGE1_ref = 6
							global CHAGE2_ref = 4
							global CHAGE3_ref = 0
							global CHAGE4_ref = 0
						}
					}
					
					if "`cage1'"!="" & "`cage2'"==""{
						if `cage1'<30{
					global CHAGE1_ref = "`cage1'"
						}
						if `cage1'>=30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
					global CHAGE3_ref = 0
					global CHAGE4_ref = 0
						if $ch_care ==1{
							global CHAGE2_ref = 2
						}
						if $ch_care !=1{
							global CHAGE2_ref = 4
						}
					} 
					
					
					if "`cage1'"=="" & "`cage2'"!=""{
						if `cage2'<30{
							global CHAGE2_ref = "`cage2'"
							}
						if `cage2'>=30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}	
						if $ch_care ==1{
							global CHAGE1_ref = 3
						}
						if $ch_care !=1{
							global CHAGE1_ref = 6
						}
						global CHAGE3_ref = 0
						global CHAGE4_ref = 0
					}
						
						
					if "`cage1'"!="" & "`cage2'"!=""{
						if `cage1'<30 & `cage2'<30{
							global CHAGE1_ref = "`cage1'"
							global CHAGE2_ref = "`cage2'"
							
						}
						if `cage1'>=30 | `cage2'>=30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						global CHAGE3_ref = 0
						global CHAGE4_ref = 0
					}
				}

				
					****************************
				
				
				
				if `chd_nber'==3{
					if "`cage4'"!="" {
						di as input in red "Error: If you only select three kids, you cannot choose the age of more that three kids"
						exit
						}
						
						
					if "`cage1'"=="" & "`cage2'"=="" & "`cage3'"=="" & "`cage4'"==""{
						if $ch_care ==1{
							global CHAGE1_ref = 3
							global CHAGE2_ref = 2
							global CHAGE3_ref = 5
						}
						if $ch_care !=1{
							global CHAGE1_ref = 6
							global CHAGE2_ref = 4
							global CHAGE3_ref = 10
						}
						global CHAGE4_ref = 0
						}
						
						
					
					if "`cage1'"!="" & "`cage2'"!="" & "`cage3'"!=""{
						if `cage1'<30 & `cage2'<30  & `cage3'<30{
							global CHAGE1_ref = "`cage1'"
							global CHAGE2_ref = "`cage2'"
							global CHAGE3_ref = "`cage3'"
							global CHAGE4_ref = 0
						}
						if "`cage1'">"30" | "`cage2'">"30" | "`cage3'">"30"{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
					}
					
					if "`cage1'"!="" & "`cage2'"=="" & "`cage3'"==""{
						if `cage1'<30{
							global CHAGE1_ref = "`cage1'"
						}
						if `cage1'>30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						
						if $ch_care ==1{
							global CHAGE2_ref = 2
							global CHAGE3_ref = 5
						}
						if $ch_care !=1{
							global CHAGE2_ref = 4
							global CHAGE3_ref = 10
						}
					global CHAGE4_ref = 0
					}
					
					if "`cage1'"=="" & "`cage2'"!="" & "`cage3'"==""{
						if `cage2'<30{
							global CHAGE2_ref = "`cage2'"
						}
						if `cage2'>30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						
						if $ch_care ==1{
							global CHAGE1_ref = 3
							global CHAGE3_ref = 5
						}
						if $ch_care !=1{
							global CHAGE1_ref = 6
							global CHAGE3_ref = 10
						}
					global CHAGE4_ref = 0
					}
					
					if "`cage1'"=="" & "`cage2'"=="" & "`cage3'"!=""{
						if `cage3'<30{
							global CHAGE3_ref = "`cage3'"
						}
						if `cage3'>30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						
						if $ch_care ==1{
							global CHAGE1_ref = 3
							global CHAGE2_ref = 2
						}
						if $ch_care !=1{
							global CHAGE1_ref = 6
							global CHAGE2_ref = 4
						}
					global CHAGE4_ref = 0
					}
					
			
					if "`cage1'"!="" & "`cage2'"!="" & "`cage3'"==""{
						if `cage1'<30 & `cage2'<30{
							global CHAGE1_ref = "`cage1'"
							global CHAGE2_ref = "`cage2'"
						}
						if `cage1'>=30 | `cage2'>=30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						if $ch_care ==1{
							global CHAGE3_ref = 5
						}
						if $ch_care !=1{
							global CHAGE3_ref = 10
						}
						global CHAGE4_ref = 0
					}
					
					if "`cage1'"!="" & "`cage2'"=="" & "`cage3'"!=""{
						if `cage1'<30 & `cage3'<30{
							global CHAGE1_ref = "`cage1'"
							global CHAGE3_ref = "`cage3'"
						}
						if `cage1'>=30 | `cage3'>=30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						if $ch_care ==1{
							global CHAGE2_ref = 2
						}
						if $ch_care !=1{
							global CHAGE2_ref = 4
						}
						global CHAGE4_ref = 0
					}
					
					if "`cage1'"=="" & "`cage2'"!="" & "`cage3'"!=""{
						if `cage2'<30 & `cage3'<30{
							global CHAGE2_ref = "`cage2'"
							global CHAGE3_ref = "`cage3'"
						}
						if "`cage2'">="30" | "`cage3'">="30"{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						if $ch_care ==1{
							global CHAGE1_ref = 3
						}
						if $ch_care !=1{
							global CHAGE1_ref = 6
						}
						global CHAGE4_ref = 0
					}
				}
					
					
					
					****************************	
					
					
				if `chd_nber'==4{
				
					if "`cage1'"!="" & "`cage2'"!="" & "`cage3'"!="" & "`cage4'"!=""{
						if `cage1'<30 & `cage2'<30 & `cage3'<30 & `cage4'<30{
							global CHAGE1_ref = "`cage1'"
							global CHAGE2_ref = "`cage2'"
							global CHAGE3_ref = "`cage3'"
							global CHAGE4_ref = "`cage4'"
						}
						if `cage1'>=30 | `cage2'>=30 | `cage3'>=30 | `cage4'>=30 {
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
					}
					
					
					if "`cage1'"=="" & "`cage2'"=="" & "`cage3'"=="" & "`cage4'"==""{
						if $ch_care ==1{
							global CHAGE1_ref = 3
							global CHAGE2_ref = 2
							global CHAGE3_ref = 5
							global CHAGE4_ref = 4
						}
						if $ch_care !=1{
							global CHAGE1_ref = 6
							global CHAGE2_ref = 4
							global CHAGE3_ref = 10
							global CHAGE4_ref = 8
						}
					}
						
						
					if "`cage1'"!="" & "`cage2'"=="" & "`cage3'"=="" & "`cage4'"==""{
						if `cage1'<30{
							global CHAGE1_ref = "`cage1'"
						}
						if `cage1'>30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						
						if $ch_care ==1{
							global CHAGE2_ref = 2
							global CHAGE3_ref = 5
							global CHAGE4_ref = 4
						}
						if $ch_care !=1{
							global CHAGE2_ref = 4
							global CHAGE3_ref = 10
							global CHAGE4_ref = 8
						}
					}
					
					if "`cage1'"=="" & "`cage2'"!="" & "`cage3'"=="" & "`cage4'"==""{
						if `cage2'<30{
							global CHAGE2_ref = "`cage2'"
						}
						if `cage2'>30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						
						if $ch_care ==1{
							global CHAGE1_ref = 3
							global CHAGE3_ref = 5
							global CHAGE4_ref = 4
						}
						if $ch_care !=1{
							global CHAGE1_ref = 6
							global CHAGE3_ref = 10
							global CHAGE4_ref = 8
						}
					}
					
					if "`cage1'"=="" & "`cage2'"=="" & "`cage3'"!="" & "`cage4'"==""{
						if `cage3'<30{
							global CHAGE3_ref = "`cage3'"
						}
						if `cage3'>30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						
						if $ch_care ==1{
							global CHAGE1_ref = 3
							global CHAGE2_ref = 2
							global CHAGE4_ref = 4
						}
						if $ch_care !=1{
							global CHAGE1_ref = 6
							global CHAGE2_ref = 4
							global CHAGE4_ref = 8
						}
					}
					
					if "`cage1'"=="" & "`cage2'"=="" & "`cage3'"=="" & "`cage4'"!=""{
						if `cage4'<30{
							global CHAGE4_ref = "`cage4'"
						}
						if `cage4'>30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						
						if $ch_care ==1{
							global CHAGE1_ref = 3
							global CHAGE2_ref = 2
							global CHAGE3_ref = 5
						}
						if $ch_care !=1{
							global CHAGE1_ref = 6
							global CHAGE2_ref = 4
							global CHAGE3_ref = 10
						}
					}
					
					
					if "`cage1'"!="" & "`cage2'"!="" & "`cage3'"=="" & "`cage4'"==""{
						if `cage1'<30 & `cage2'<30{
							global CHAGE1_ref = "`cage1'"
							global CHAGE2_ref = "`cage2'"
						}
						if `cage1'>=30 | `cage2'>=30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						if $ch_care ==1{
							global CHAGE3_ref = 5
							global CHAGE4_ref = 4
						}
						if $ch_care !=1{
							global CHAGE3_ref = 10
							global CHAGE4_ref = 8
						}
					}
					
					if "`cage1'"!="" & "`cage2'"=="" & "`cage3'"!="" & "`cage4'"==""{
						if `cage1'<30 & `cage3'<30{
							global CHAGE1_ref = "`cage1'"
							global CHAGE3_ref = "`cage3'"
						}
						if `cage1'>=30 | `cage3'>=30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						if $ch_care ==1{
							global CHAGE2_ref = 2
							global CHAGE4_ref = 4
						}
						if $ch_care !=1{
							global CHAGE2_ref = 4
							global CHAGE4_ref = 8
						}
					}
					
					if "`cage1'"!="" & "`cage2'"=="" & "`cage3'"=="" & "`cage4'"!=""{
						if `cage1'<30 & `cage4'<30{
							global CHAGE1_ref = "`cage1'"
							global CHAGE4_ref = "`cage4'"
						}
						if `cage1'>=30 | `cage4'>=30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						if $ch_care ==1{
							global CHAGE2_ref = 2
							global CHAGE3_ref = 5
						}
						if $ch_care !=1{
							global CHAGE2_ref = 4
							global CHAGE3_ref = 10
						}
					}
					
					
					if "`cage1'"=="" & "`cage2'"!="" & "`cage3'"!="" & "`cage4'"==""{
						if `cage2'<30 & `cage3'<30{
							global CHAGE2_ref = "`cage2'"
							global CHAGE3_ref = "`cage3'"
						}
						if `cage2'>=30 | `cage3'>=30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						if $ch_care ==1{
							global CHAGE1_ref = 3
							global CHAGE4_ref = 4
						}
						if $ch_care !=1{
							global CHAGE1_ref = 6
							global CHAGE4_ref = 8
						}
					}
					
					if "`cage1'"=="" & "`cage2'"!="" & "`cage3'"=="" & "`cage4'"!=""{
						if `cage2'<30 & `cage4'<30{
							global CHAGE2_ref = "`cage2'"
							global CHAGE4_ref = "`cage4'"
						}
						if `cage2'>=30 | `cage4'>=30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						if $ch_care ==1{
							global CHAGE1_ref = 3
							global CHAGE3_ref = 5
						}
						if $ch_care !=1{
							global CHAGE1_ref = 6
							global CHAGE3_ref = 10
						}
					}
					
					if "`cage1'"=="" & "`cage2'"=="" & "`cage3'"!="" & "`cage4'"!=""{
						if `cage3'<30 & `cage4'<30{
							global CHAGE3_ref = "`cage3'"
							global CHAGE4_ref = "`cage4'"
						}
						if `cage3'>=30 | `cage4'>=30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						if $ch_care ==1{
							global CHAGE1_ref = 3
							global CHAGE2_ref = 2
						}
						if $ch_care !=1{
							global CHAGE1_ref = 6
							global CHAGE2_ref = 4
						}
					}
					

					if "`cage1'"!="" & "`cage2'"!="" & "`cage3'"!="" & "`cage4'"==""{
						if `cage1'<30  & `cage2'<30 & `cage3'<30{
							global CHAGE1_ref = "`cage1'"
							global CHAGE2_ref = "`cage2'"
							global CHAGE3_ref = "`cage3'"
						}
						if `cage1'>=30 | `cage2'>=30 | `cage3'>=30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						if $ch_care ==1{
							global CHAGE4_ref = 4
						}
						if $ch_care !=1{
							global CHAGE4_ref = 8
						}
					}
					
					if "`cage1'"=="" & "`cage2'"!="" & "`cage3'"!="" & "`cage4'"!=""{
						if `cage4'<30  & `cage2'<30 & `cage3'<30{
							global CHAGE4_ref = "`cage4'"
							global CHAGE2_ref = "`cage2'"
							global CHAGE3_ref = "`cage3'"
						}
						if `cage4'>=30 | `cage2'>=30 | `cage3'>=30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						if $ch_care ==1{
							global CHAGE1_ref = 3
						}
						if $ch_care!=1{
							global CHAGE1_ref = 6
						}
					}
					
					if "`cage1'"!="" & "`cage2'"=="" & "`cage3'"!="" & "`cage4'"!=""{
						if `cage4'<30  & `cage1'<30 & `cage3'<30{
							global CHAGE4_ref = "`cage4'"
							global CHAGE1_ref = "`cage1'"
							global CHAGE3_ref = "`cage3'"
						}
						if `cage4'>=30 | `cage1'>=30 | `cage3'>=30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						if $ch_care ==1{
							global CHAGE2_ref = 2
						}
						if $ch_care !=1{
							global CHAGE2_ref = 4
						}
					}
					
										
					if "`cage1'"!="" & "`cage2'"!="" & "`cage3'"=="" & "`cage4'"!=""{
						if `cage1'<30  & `cage2'<30 & `cage4'<30{
							global CHAGE1_ref = "`cage1'"
							global CHAGE2_ref = "`cage2'"
							global CHAGE4_ref = "`cage4'"
						}
						if `cage1'>=30 | `cage2'>=30 | `cage4'>=30{
							di as input in red "Error: Age of kids cannot exceed 30 years old"
							exit
						}
						if $ch_care ==1{
							global CHAGE3_ref = 5
						}
						if $ch_care !=1{
							global CHAGE3_ref = 10
						}
					}
				}
						
			
				**************************************
				
				
	if "`uemonth'"== ""{
		global ue_months = 2
	}
	
	if "`uemonth'" != ""{
		local unemp_month = round(`uemonth',1)
		global ue_months  = `unemp_month'
	}
								
				
				**************************************
				
				
	if "`hcost'"== "" {
		global h_cost = 0.2
	}
	
	if "`hcost'"!= ""{
		if `hcost'>=1{
			di as input in red "Error: The model is not made for people spending more than their income in housing cost"
			exit
		}
		if `hcost'<0{
			di as input in red "Error: Renting cost cannot be negative"
			exit
		}
		if `hcost'>=0 & `hcost'<1{
			global h_cost = "`hcost'"
		}
	}
				
			
				
				**************************************
				
		 		
	if "`vname'"!=""{
		if "`vname'" == "details"{
			if wordcount("$ctry_list")==1 & "$ctry_list"!="all"{
				global vname = "details"
				}
			if wordcount("$ctry_list")!=1 | "$ctry_list"=="all"{
				di as input in red "Error: You can keep all information if you select only one country"
				exit
			}
		}
		else{
			global vname = "`vname'" 
		}
	}
	
	if "`vname'"==""{
		global vname = ""
	}
	
			  ****************************************
			  
			  
	if "`isocountrynames'" != ""{
		local isoo = lower("`isocountrynames'")
		if "`isoo'"!="yes" & "`isoo'"!="no"{
			di as input in red "You can only ask to have (yes) or do not have (no) country codes and names"
			exit
		}
		if "`isoo'"=="yes"{
			global ISO = "`isocountrynames'"
		}
		if "`isoo'"=="no"{
			global ISO = ""
		}
	}
	

	if "`isocountrynames'" == ""{
		global ISO = ""
	}
	  
	
		    ****************************************
			
	if "`graph'" != ""{
	local graphh = lower("`graph'")
	if "`graphh'"!="yes" & "`graph'"!="no"{
		di as input in red "You can only ask to have (yes) or do not have (no) graphs"
		exit
		}
	if "`graphh'"=="yes" & ($incl_sa == 1 & $allow_sa == 0 ) & ($run_type == 0 | $run_type == 1){
		di as input in red "Error: to activate the graph option with run type 0 or 1, please also activate unemployment benefits [primben(ub)] or social assistance [sa(yes)]"
		exit
	}
	if "`graphh'"=="yes"{
		if $run_type == 6 | $run_type == 5{
			di as input "NB: The graph option is not available with run-type $run_type, your choice will be ignored"
			global graph ""
			}
		else{
			global graph = "`graph'" 
			}
		}
	if "`graphh'"=="no"{ 
		global graph ""
		}
	}
	
	if "`graph'"==""{ 
		global graph ""
	}
	
	
	
		    ****************************************
			
	if "`split'" == ""{
		global split = "no"
	}
	
	if "`split'" != ""{
		local small_split = lower("`split'")
		if "`small_split'"!="yes" & "`small_split'"!="no"{
			di as input in red "Error: The split option can only be activated (yes) or disactivated (no)"
			exit
		}
		if "`small_split'"=="yes"{
			global split = "yes"
		}
		if "`small_split'"=="no"{
			global split = "no"
		}
	}	

	
		    ****************************************
	
	
	if "`derivdecompos'"== ""{
		global derivd = "no"
	}
	if "`derivdecompos'" != ""{
		local dd = lower("`derivdecompos'")
		if "`dd'"!="no" & "`dd'"!="yes"{
			di as input in red "Error: You can only activate (yes) or desactivate (no) the dervative decomposition"
			exit
			}
		if "`dd'"=="no"{
			global derivd = "`dd'"
			}
		if "`dd'"=="yes"{
			if $run_type <2 {
				di as input in red "You cannot ask for the derivative decomposition with run-type $run_type"
				exit
				}
			else{
				global derivd = "`dd'"
				}
			}
		if ("`dd'"=="yes" & length("$vname")>1 & length("$vname")<7){
		di as input `"NB: When asking for the derivative decomposition, you should keep all the resulting variables. If you only want to keep the result of the decomposition, select "METR*" in the vname option"'
			}
	}
	
	
		    ****************************************

	if "`save'"!=""{
		global Taxbenextract_save_name = "`save'"
	}
	else{
		global Taxbenextract_save_name = ""
	}
			
			****************************************

	if "`clear'" == "clear"{
		clear
	}


			****************************************
 cd "${path_baseline}"
 do Taxbenextract_simul_run.do
 duplicates drop
 drop if missing(marstat)
 
 
}

end 
