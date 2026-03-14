*! version 6.0.0 24Jan2026


***********************************************

program define ggt, rclass

version 18.0

syntax, outcomevar(varname) orgchoice(varname) indID(varname) orgID(varname) choicechar(varlist numeric)  ///
 	[, orgchar(varlist max=10) indchar(varlist numeric max=100) niter(numlist integer max=1 min=1) alphapriorvar(numlist max=1 min=1) ///
	gammapriorvar(numlist max=1 min=1) deltapriorvar(numlist max=1 min=1) ///
	 priortau(numlist max=2 min=2) savedraws(str) noselection noCONStant]

quietly {

*restrict to single processor for plugin stability 
	local user_procs=c(processors) 
	set processors 1

*** Check options are appropriately specified *** 

*check that variable names are not too long (stata max is 32 and prefix are a_, g_, b_, and b_orgFE_)
	foreach var of local indchar {
		if (strlen("`var'")>30){
			display as error "Variable name '`var'' exceeds 30 characters. Please rename."
			set processors `user_procs'
			exit 500
		}
	}
	foreach var of local choicechar {
		if (strlen("`var'")>30){
			display as error "Variable name '`var'' exceeds 30 characters. Please rename."
			set processors `user_procs'
			exit 500
		}
	}

	foreach var of local orgchar {
		local strvar0=strlen("`var'")	
		tempvar strvar1
		tempvar strvar2
		capture confirm string variable `var'
			if _rc {
				tostring `var', gen (`strvar1') force
			}		
			else {
				gen strL `strvar1'=`var'
			}
		gen `strvar2'=length(`strvar1')
		su `strvar2'
		local strvar0=`strvar0'+`r(max)'+1
		if `strvar0'>30 {
			display as error "`var': Either variable name or values are too long. Please shorten."
			set processors `user_procs'
			exit 500
		}
	}


	tempvar strvar 
	capture confirm string variable `orgID'
	if _rc { 
		tostring `orgID', gen (`strvar') force
	}
	else {
		gen strL `strvar'=`orgID'
	}
	 count if length(`strvar')>24
	if r(N)>0 {
		display as error "orgID has values exceeding 24 characters in length. Please shorten."
		set processors `user_procs'
		exit 500
	}
	

*check niter is larger than 100 (and is a multiple of 100)
	if("`niter'"!=""){
		local check1=(`niter'>=100)
		local check2=mod(`niter', 100)
		if(`check1'!=1 | `check2'!=0){
			display as error "Number of Iterations must be a multiple of 100"
			set processors `user_procs'
			exit 501
		}
	}

*check second element of tauprior is integer
	if ("`priortau'"!=""){
		local check=`: word 2 of `priortau''
		if (mod(`check',1)!=0){
			display as error "Second element of priortau must be an integer"
			set processors `user_procs'
		exit 501
		}
	}

*check deltapriorvar in (0,1)
	if("`deltapriorvar'"!=""){
		local check=(`deltapriorvar'>0 & `deltapriorvar'<1)
		if (`check'!=1){
			display as error "Delta prior variance parameter must be greater than 0 and less than 1"
			set processors `user_procs'
			exit 501
		}
	}


*check if savedraws is given, and use default as outfile if not 
*define outfile
	if ("`savedraws'"!=""){
		local outfile="`savedraws'"
	} 
	else {
		local outfile="temp_GGT_output.csv"
	}


*check there is a valid filename in savedraws if given 
    	if (strpos("`outfile'", ".csv") == 0) {
        	display as error "savedraws() must specify a valid .csv filename, e.g., savedraws(\"myfile.csv\")"
		set processors `user_procs'
        exit 503.5
    		}
   
*check if file name exists, and exit with error if so 
	if (fileexists("`outfile'")==1) {
		display as error "`outfile' already exists. choose a different file name for savedraws()."
		set processors `user_procs'
        	exit 502
		}

*check no variable name conflicts for those needed in data for C plugin
	local constraint_varlist temp_ggt_* temp_Z_diff* type*
	foreach var in `constraint_varlist'  {
	    capture ds `var'
	    if ("`r(varlist)'"!=""){
	        display as error "Please rename variables to avoid conflict in GGT code: `var'"
		 set processors `user_procs'
		exit 503
	   }
	}

*** Process for other ggt data checks *** 

*set seed using system time (milliseconds since 01jan1960)
	local now = mod(clock("`c(current_date)' `c(current_time)'", "DMYhms"), 2^30)
	set seed `now'
*generate random integer ID for file naming 
	scalar rand_id=floor(runiform()*1e6)
	local randomID=string(rand_id, "%06.0f")

*preserve user's dataset 
	tempfile user_data_`randomID'
	save `user_data_`randomID''

*add person and org IDs to new tempfile
	egen temp_ggt_persid=group(`indID') 
	egen temp_ggt_orgID=group(`orgID')
	tempfile temp_ggt_master_`randomID'   
	save `temp_ggt_master_`randomID''

*create tempfile for org data that is needed for variable re-naming later
	tempfile org_dat_temp

*define tempvars needed for remaining data checks
	tempvar temp_GGT_flag temp_GGT_min temp_GGT_max temp_GGT_outcomesum temp_GGT_choicesum


*Check that each org appears once per individual
	 egen `temp_GGT_flag' = count(temp_ggt_orgID), by(temp_ggt_persid)
	 su `temp_GGT_flag', meanonly
	if r(min) != r(max) {
	    display as error "Each individual must have the same number of organization rows"
	use `user_data_`randomID'', clear
	 set processors `user_procs'
	    exit 504
	}

* Check that each person appears once per organization
	 cap drop `temp_GGT_flag'
	 egen `temp_GGT_flag' = count(temp_ggt_persid), by(temp_ggt_orgID)
	 su `temp_GGT_flag', meanonly
	if r(min) != r(max) {
	    display as error "Each organization must have the same number of individual rows"
		use `user_data_`randomID'', clear
		 set processors `user_procs'
	    exit 504
	}
	

*check outcomevar is 0 1 and sum to 0 or 1 for a given patient
	 replace `temp_GGT_flag'=0
	 replace `temp_GGT_flag'=1 if (`outcomevar'!=1 & `outcomevar'!=0)
	 su `temp_GGT_flag'
	local error=r(max)
	if (`error'!=0){
		display as error "outcomevar must be binary {0,1}"
		use `user_data_`randomID'', clear
		 set processors `user_procs'
		exit 504
	}
	 replace `temp_GGT_flag'=0
	 bysort temp_ggt_persid: egen `temp_GGT_outcomesum'=sum(`outcomevar') 
	 su temp_ggt_orgID
	local lastOrg=r(max)
	 replace `temp_GGT_flag'=1 if (`temp_GGT_outcomesum'!=`lastOrg' & `temp_GGT_outcomesum'!=0)
	 su `temp_GGT_flag'
	local error=r(max)
	if (`error'!=0){
		display as error "outcomevar must be constant within individuals"
		use `user_data_`randomID'', clear
		 set processors `user_procs'
		exit 504
	}	


*check orgchoice are 0 1 and sum to 1 
	 replace `temp_GGT_flag'=0
	 replace `temp_GGT_flag'=1 if (`orgchoice'!=1 & `orgchoice'!=0)
	 su `temp_GGT_flag'
	local error=r(max)
	if (`error'!=0){
		display as error "orgchoice must be binary {0,1}"
		use `user_data_`randomID'', clear
		 set processors `user_procs'
		exit 504
	}

	 replace `temp_GGT_flag'=0
	 bysort temp_ggt_persid: egen `temp_GGT_choicesum'=sum(`orgchoice') 
	 replace `temp_GGT_flag'=1 if (`temp_GGT_choicesum'!=1)
	 su `temp_GGT_flag'
	local error=r(max)
	if (`error'!=0){
		display as error "orgchoice must sum to 1 within individuals"
		use `user_data_`randomID'', clear
		 set processors `user_procs'
		exit 504
	}


* Check that indchar are the same within individual 
	drop `temp_GGT_flag'
	foreach ind_var in `indchar' {
		cap drop `temp_GGT_min' `temp_GGT_max'
		egen double `temp_GGT_min'=min(`ind_var'), by(`indID')
		egen double `temp_GGT_max'=max(`ind_var'), by(`indID')
		count if `temp_GGT_min'!=`temp_GGT_max'
		if r(N)>0 {
			display as error "indchar `ind_var' must be the same within individual"
			use `user_data_`randomID'', clear
			set processors `user_procs'
			exit 504
		}
	}
	
* Check that orgchar are the same within organization
	tempvar orgcheck1 orgcheck2
	foreach org_var in `orgchar' {
		cap drop `orgcheck1' `orgcheck2' 
		egen `orgcheck1'=group(`org_var')
		egen `orgcheck2'=mean(`orgcheck1'), by(`orgID')
		count if `orgcheck1'!=`orgcheck2'
		if r(N)>0 {
			display as error "orgchar `org_var' must be the same within organization"
			use `user_data_`randomID'', clear
			set processors `user_procs'
			exit 504
		}
	}	


*** Create temp .csv files for C code *** 
 
*check if filename already exists, and save as tempfile if not 
	foreach prefix in Inddata Orgdata Zdata {
		local filename="temp_GGT_`prefix'`randomID'.csv"
		capture confirm file "`filename'"
		if !_rc {
			display as error "File name conflict. Please re-run or clean the directory." 
			use `user_data_`randomID'', clear
			 set processors `user_procs'
			exit 505
		}
		local `prefix'file "`filename'"
	}

* check that bayesqaul`randomID',  "temp_GGT_useroptions.txt" and "initial.log" do not already exist
	capture confirm file "temp_GGT_useroptions.txt"
	if !_rc {
			display as error "temp_GGT_useroptions: File name conflict. Please re-name or clean the directory." 
			use `user_data_`randomID'', clear
			 set processors `user_procs'
			exit 506
		}
	capture confirm file "initial.log"
	if !_rc {
			display as error "initial.log: File name conflict. Please re-name or clean the directory." 
			use `user_data_`randomID'', clear
			 set processors `user_procs'
			exit 506
		}
	capture confirm file "bayesqual`randomID'.log"
	if !_rc {
			display as error "bayesqual`randomID'.log: File name conflict. Please re-name or clean the directory." 
			use `user_data_`randomID'', clear
			 set processors `user_procs'
			exit 506
		}


*get temp_GGT_Inddata.csv for C code
	gen temp_ggt_choice_number = .
	replace temp_ggt_choice_number = temp_ggt_orgID if `orgchoice' == 1
	collapse (mean) `outcomevar' `indchar' (max) temp_ggt_choice_number, by(temp_ggt_persid)
	gen temp_ggt_cons=1
	rename temp_ggt_persid indID
	rename `outcomevar' outcomevar 
	rename temp_ggt_choice_number choice
	local j=2
	if ("`constant'"=="noconstant"){
		drop temp_ggt_cons
		local j=1
	}
	foreach var in `indchar'{
		rename `var' x`j'
		local j=`j'+1
	}
	cap rename temp_ggt_cons x1
	order indID outcomevar choice 
	cap order x*, after(choice) sequential
	sort indID
	 export delimited using "`Inddatafile'"

	clear
	use `temp_ggt_master_`randomID'' 
	

*get temp_GGT_Orgdata.csv for C code
	local orgcharcount: word count `orgchar' 
	if(`orgcharcount'==0){
		collapse (firstnm) `orgID', by(temp_ggt_orgID)
		rename temp_ggt_orgID orgID_recode
		rename `orgID' orgID
		keep orgID orgID_recode
		 save `org_dat_temp'
		 export delimited using "`Orgdatafile'"
	} 
	else {
		local i=1
		foreach var in `orgchar'{
		egen temp_ggt_orgchar`i'=group(`var')
		local i=`i'+1
		}
	collapse (mean) temp_ggt_orgchar* (firstnm) `orgID' `orgchar', by(temp_ggt_orgID)
	rename temp_ggt_orgID orgID_recode
	rename `orgID' orgID
	forvalues k=1/`orgcharcount'{ 
		rename temp_ggt_orgchar`k' type`k'
	}
	order orgID orgID_recode
	cap order type*, after(orgID_recode) sequential 
	sort orgID_recode
	 save `org_dat_temp'
	keep orgID orgID_recode type*
	 export delimited using "`Orgdatafile'"
	}


	clear
	use `temp_ggt_master_`randomID'' 


*get temp_GGT_Zdata.csv for C code 
	su temp_ggt_orgID
	local lastOrg=r(max)
	tempvar temp_lastorg 
	gen `temp_lastorg'=(temp_ggt_orgID==`lastOrg')
	local l=1
	foreach var in `choicechar'{
		tempvar temp_lastorg_val temp_lastorg_val_all 
		gen `temp_lastorg_val'=`temp_lastorg'*`var'
		bysort temp_ggt_persid: egen `temp_lastorg_val_all'=max(`temp_lastorg_val')
		gen temp_Z_diff_`l'=`var'-`temp_lastorg_val_all'
		cap drop `temp_lastorg_val' `temp_lastorg_val_all' 
		local l=`l'+1
	}

	 drop if temp_ggt_orgID==`lastOrg'
	rename temp_ggt_persid indID
	rename temp_ggt_orgID orgID
	local zcount: word count `choicechar' 
	if(`zcount'==0){
		keep indID orgID
	} 
	else {
		keep indID orgID temp_Z_diff*
	}
	if(`zcount'>0){	
		local l=`l'-1
		forvalues n=1/`l'{
			rename temp_Z_diff_`n' choicechar`n'
		}
	}
	order indID orgID
	cap order choicechar*, after(orgID) sequential
	sort indID orgID
	 export delimited using "`Zdatafile'"
	clear
	use `temp_ggt_master_`randomID''  


*** Create User Option text file for C code *** 

*save local for niter_check for later return check 
	if("`niter'"!=""){
		local niter_check=`niter'
	}
	else {
		local niter_check=100000
	} 

*prepping to send options to C code 
	foreach var in niter alphapriorvar gammapriorvar deltapriorvar priortau{
		if ("``var''"!=""){
			local `var'="`var'(``var''),"
		}
	}


*define inputfilenameadd 
	local inputfilenameadd ="inputfilenameadd(`randomID'),"

*define outputfilename
	local outputfilename="outputfilename(`outfile')"
	
*add comma to end of selection if noselection option 
	if ("`selection'"=="noselection"){
		local selection_out="noselection,"
	} 
	else {
		local selection_out=""
	}


*write file and delete 
	 file open useroptions using "temp_GGT_useroptions.txt", write 
	file write useroptions "`niter' `alphapriorvar' `gammapriorvar' `deltapriorvar' `priortau' `selection_out' `inputfilenameadd' `outputfilename' "
	file close useroptions

*** Call C Code *** 

*calling C code	
	cap program drop callCcode
	callCcode

*** Read in Output and change variable names *** 
	*iter, tau, delta are not changed
	*alphaX -> aX_choicecharname 
	*gammaX -> gX_indcharname
	*if no orchars specified, beta_orgatt1_type1--J -> b_orgID_orgID
	*if orchars specified, beta_orgattX_typeY -> b_orgcharname_orgcharvalue 
	*tauX->t_orgcharname t_orgID
 
* Read output and return 0 if file does not exist or niter<nitercheck 
	clear
	if (fileexists("`outfile'")!=1){
		local return_val=0
	}
	else {
		import delimited using `outfile', clear
		su iter 
		if (`r(max)'<`niter_check'){
			local return_val=0
		} 
		else {
			local return_val=1
			}
	*give error if renaming fails but everything else runs fine. 
	capture {
	
	*rename gamma variables
		local j=1
		if ("`constant'"!="noconstant"){
			rename gamma1 g_constant
			local j=`j'+1
		}
		foreach var in `indchar'{
			*rename gamma`j' g`j'_`var'
			rename gamma`j' g_`var'
			local j=`j'+1
		}

	*rename alpha varibales 
		local j=1 
		foreach var in `choicechar'{
			*rename alpha`j' a`j'_`var'
			rename alpha`j' a_`var'
			local j=`j'+1
		}

	*rename beta variables
		*first get the xwalk between orgid and orgid_recode
		preserve 
			 use `org_dat_temp', clear
			sort orgID_recode
			 levelsof orgID, local(orgids)
		restore 

		*then rename of the orgFe beta_orgID_orgname (starts after the orgchars)
		local h=`orgcharcount'+1
		 ds beta_orgatt`h'_type*, has(type numeric)
		local orgfe_varlist `r(varlist)'
		local i=1
		foreach var of local orgfe_varlist {
			local newid: word `i' of `orgids'

			rename `var' b_orgID_`newid'
			local i=`i'+1
		}

		*then replace orgattX with orgchar varname and typeX with the orchar varname value
		local i=1
		foreach char in `orgchar'{
			
			*first get xwalk between that type and its values 
			preserve 
			 use `org_dat_temp', clear 
			collapse (firstnm) type`i', by(`char')
			sort type`i' 
			 levelsof `char', local(org_vals)
			restore 

			local t=1 
			 ds beta_orgatt`i'_type* 
			foreach var in `r(varlist)'{
				local var_val: word `t' of `org_vals'
				local newname1=subinstr("`var'","eta_orgatt`i'_", "_`char'_", 1)
				rename `var' `newname1'
				local newname2=subinstr("`newname1'", "type`t'","`var_val'", 1)
				rename `newname1' `newname2'
				local t=`t'+1
				}

			local i=`i'+1
		}

		*rename the taus- order: orgchar orgFE
		if (`orgcharcount'==0) {
			rename tau0 t_orgID
		}
		else {
			forvalues h=1/`orgcharcount'{
				local tnum=`h'-1
				local tname: word `h' of `orgchar'
				rename tau`tnum' t_`tname'
			}
			rename tau`orgcharcount' t_orgID
		}
	} 
	if _rc {
		display as error "Error encountered in ggt output variable renaming. See documentation for naming convention."
		clear 
	}
	else {
	*save the renamed file 
		 export delimited using "`outfile'", replace
		clear
		}
	}	

*** remove temp csv files if still in the folder ***

*check if filename still exists in folder, and erase if so
	foreach prefix in Inddata Orgdata Zdata {
		local filename="temp_GGT_`prefix'`randomID'.csv"
		if (fileexists("`filename'")){
			erase "`filename'"
		}
	}

****
	*return values and restore user input 
	return scalar success=`return_val'
	clear
	use `user_data_`randomID''
	set processors `user_procs'
	noisily display "complete. Success=`return_val'"
	
} 

end

	



