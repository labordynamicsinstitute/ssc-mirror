/*----------------------------------------------------------------------------------
  opendf_csv2dta.ado: loads data from csvs including meta data to build a Stata dataset
    Copyright (C) 2024  Tom Hartl (thartl@diw.de)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    For a copy of the GNU General Public License see <http://www.gnu.org/licenses/>.

-----------------------------------------------------------------------------------*/
*! opendf_csv2dta.ado: loads data from csvs including meta data to build a Stata dataset
*! version 2.0.2 - 28 August 2024 - SSC Initial Release

program define opendf_csv2dta 
	version 16
	syntax, csv_loc(string) [ROWRange(string) COLRange(string) SAVE(string) REPLACE CLEAR VERBOSE]
	local replaceit 0
		if (`"`replace'"' != "") local replaceit 1
		
	local saveit 0
	if (`"`save'"' != "") {
		local saveit 1
		local save: subinstr local save "\" "`c(dirsep)'", all
		local save `save'
	}

	local clearit 0
		if (`"`clear'"' != "") local clearit 1

	if `replaceit' == 1 & `saveit' == 0 {
		noisily: display as error "option {bf:replace} requires option {bf:save}"
		exit 459
	}	
	if `replaceit' == 0 & `saveit' == 1 {
		capture: confirm file "`save'"
		if _rc == 0 {
			noisily: display as error "file `save' already exists"
			exit 602
		} 
	}
	local saveit 0
	if (`"`save'"' != "") {
		local saveit 1
		local save: subinstr local save "\" "`c(dirsep)'", all
		local save `save'
	}

	local verboseit 0
	if (`"`verbose'"' != "") {
		local verboseit 1
	}

	if (`"`rowrange'"' != ""){
		* Define the local macro with the string
		local _rowrangeraw "`rowrange'"

		* Find the position of the colon
		local pos = strpos("`_rowrangeraw'", ":")

		* Extract the parts before and after the colon
		local part1 = substr("`_rowrangeraw'", 1, `pos' - 1)
		local part2 = substr("`_rowrangeraw'", `pos' + 1, .)

		* Convert the parts to scalars, handling potential missing values
		scalar scalar1 = cond("`part1'" == "", ., real("`part1'"))
		scalar scalar2 = cond("`part2'" == "", ., real("`part2'"))

		*add 1 to the row range to skip the header and paste it to the new input for rowrange
		if (scalar1 != .) {
			scalar scalar1 = scalar1 + 1
			local rowstart `=scalar1'
		}
		else {
			local rowstart ""
		}
		if (scalar2 != .) {
			scalar scalar2 = scalar2 + 1
			local rowend `=scalar2'
		}
		else {
			local rowend ""
		}

		local rowrange "`rowstart':`rowend'"
	}
	
	*global to save all warnings
	global warnings ""
	*locals for occurence of warning type
	local _valuelabelforstringvariable=0
	local _datasetlabelmissing=0
	local _metadatafornonexistingvariable=0
	local _vallabelfornonexistingvariable=0
	local _varlabelmissing=0
	local _valuelabelmissing=0
	*replace backlashes with lashes
	quietly: local csv_loc: subinstr local csv_loc "\" "`c(dirsep)'", all


	*Directory where to save csvs
	quietly: import delimited "`csv_loc'/dataset.csv", varnames(1) case(preserve) encoding(UTF-8) bindquote(strict) maxquotedrows(10000) asdouble `clear'
	*remove gravis (`) from strings to avert errors
	foreach var of varlist _all{
		local _variable_type : type `var'
		if strpos("`_variable_type'", "str") == 1{
			qui: replace `var' = subinstr(`var', "`=char(96)'", "'",.) 
		}
	}
	*count number of characteristics
	local dataset_nchar = 0
	*loop over each characteristic (column)
	*The name of characteristic 1 is saved in local macro dataset_char1_name
	*The value of characteristic 1 is saved in local macro dataset_char1_label
	foreach var of varlist _all {
		local dataset_nchar = `dataset_nchar'+1
		local dataset_char`dataset_nchar'_name = "`var'"
		local dataset_char`dataset_nchar'_label = `var' in 1
	}


	quietly: import delimited "`csv_loc'/variables.csv", varnames(1) case(preserve) encoding(UTF-8) bindquote(strict) maxquotedrows(10000) asdouble clear
	*remove gravis (`) from strings to avert errors
	foreach var of varlist _all{
		local _variable_type : type `var'
		if strpos("`_variable_type'", "str") == 1{
			qui: replace `var' = subinstr(`var', "`=char(96)'", "'",.) 
		}
	}
	*number of variables
	local _nvar = _N
	*loop over each variable (row)
	forvalues i=1(1)`_nvar' {
		*counter for number of characteristics
		local _var`i'nchar = 0
		*loop over each characteristic (column)
		*The name of characteristic 1 of variable 1 is saved in local macro _var1_char_name1
		*The value of characteristic 1 of variable 1 is saved in local macro _var1_char_label1
		foreach var of varlist _all {
			local _var`i'nchar = `_var`i'nchar'+1
			local _var`i'_char_name`_var`i'nchar'= "`var'"
			local _var`i'_char_label`_var`i'nchar'= `var' in `i'
		}
	}
	 	
	*Import variable value labels
	quietly: import delimited "`csv_loc'/categories.csv", varnames(1) case(preserve) encoding(UTF-8) bindquote(strict) maxquotedrows(10000) asdouble clear
	*remove gravis (`) from strings to avert errors
	foreach var of varlist _all{
		local _variable_type : type `var'
		if strpos("`_variable_type'", "str") == 1{
			qui: replace `var' = subinstr(`var', "`=char(96)'", "'",.) 
		}
	}
	*save row numbers (number of value labels)
	local nvalue_labels=`r(N)'

	if (`nvalue_labels'>0){
		*loop over each value label (each row of dataset)
		forvalues i=1/`nvalue_labels'{
			if (`i'==1){
				*counter for number of variables to label
				local n_variable_to_label=1
				*counter for number of value label for this variable
				local nvalues=1
				*Save variable name as local
				local _varname`n_variable_to_label' = variable in `i'
				*save value of value label as local
				local _var`n_variable_to_label'_value`nvalues' = value in `i'
				*save language label of value as local
				foreach x of varlist _all{
					if strpos("`x'", "label")>0{
						if ("`x'" == "label"){
							local _var`n_variable_to_label'_label`nvalues'_landefault = `x'[`i']
						} 
						else {
							local _label_language = subinstr("`x'", "label_", "", .)
							local _var`n_variable_to_label'_label`nvalues'_lan`_label_language' = `x'[`i']
						}
						
					}
				}
				
				
			}
			if(`i'>1){
				local j = `i'-1
				local actual_var=variable in `i'
				local last_var=variable in `j'
				if ("`actual_var'" == "`last_var'"){
					local nvalues=`nvalues'+1
					local _var`n_variable_to_label'_value`nvalues' = value in `i'
					foreach x of varlist _all{
						if strpos("`x'", "label")>0{
							if ("`x'" == "label"){
								local _var`n_variable_to_label'_label`nvalues'_landefault = `x'[`i']
							} 
							else {
								local _label_language = subinstr("`x'", "label_", "", .)
								local _var`n_variable_to_label'_label`nvalues'_lan`_label_language' = `x'[`i']
							}
						}
					}		
				}
				if ("`actual_var'" != "`last_var'"){
					local _var`n_variable_to_label'_nvals = `nvalues'
					local nvalues=1
					local n_variable_to_label=`n_variable_to_label'+1
					local _varname`n_variable_to_label' = "`actual_var'"
					local _var`n_variable_to_label'_value`nvalues' = value in `i'
					foreach x of varlist _all{
						if strpos("`x'", "label")>0{
							if ("`x'" == "label"){
								local _var`n_variable_to_label'_label`nvalues'_landefault = `x'[`i']
							} 
							else {
								local _label_language = subinstr("`x'", "label_", "", .)
								local _var`n_variable_to_label'_label`nvalues'_lan`_label_language' = `x'[`i']
							}
						}
					}
				}
			}
			if (`i'==`nvalue_labels'){
				local _var`n_variable_to_label'_nvals = `nvalues'
			}
		}
	}

	

	*Import Data
	quietly: import delimited "`csv_loc'/data.csv", varnames(1) rowrange(`rowrange') colrange(`colrange') case(preserve) encoding(UTF-8) asdouble clear	
	*Indicates whether a default language exists (if there are descriptions or labels without language tag)
	local default_exists=0
	local language_counter=0

	*assign dataset labels and characteristics
	forvalues i=1/`dataset_nchar' {
			if (strpos("`dataset_char`i'_name'", "label")>0){
				if ("`dataset_char`i'_name'"=="label"){
					quietly: label language default
					label data "`dataset_char`i'_label'"
					* If no language is defined, the label is assigned to the language default
					if `default_exists'==0{
						local language_counter=`language_counter'+1
						local _language`language_counter'="default"
						local default_exists=1
					}
				}
				else {
					local _label_language = subinstr("`dataset_char`i'_name'", "label_", "", .)
					capture quietly: label language `_label_language', new
					if (_rc==110) {
					quietly: label language `_label_language'
					}
					else {
					local language_counter=`language_counter'+1
					local _language`language_counter'="`_label_language'"
					quietly: label data "`dataset_char`i'_label'"
				}
				
				}
				
			}
		if (strpos("`dataset_char`i'_name'", "label")==0){
			char _dta[`dataset_char`i'_name'] "`dataset_char`i'_label'"
		}
	}
	*assign variable labels and characteristics
	forvalues i=1(1)`_nvar' {
		forvalues j=1(1)`_var`i'nchar'{
			if ("`_var`i'_char_name`j''"=="variable"){
				local _varcode=`"`_var`i'_char_label`j''"'
				}
			capture confirm variable `_varcode', exact
			if (_rc == 0){
				if strpos("`_var`i'_char_name`j''", "label")>0{
					if ("`_var`i'_char_name`j''"=="label"){
						quietly: label language default
						label var `_varcode' `"`_var`i'_char_label`j''"'
						if `default_exists'==0{
							local language_counter=`language_counter'+1
							local _language`language_counter'="`_label_language'"
							local default_exists=1
						}
					}
					if ("`_var`i'_char_name`j''"!="label"){
						local _label_language = subinstr("`_var`i'_char_name`j''", "label_", "", .)
						capture label language `_label_language'
						if (_rc == 111){
							quietly: label language `_label_language', new
							local language_counter=`language_counter'+1
							local _language`language_counter'="`_label_language'"
							local _datasetlabelmissing=1
							global warnings= `"$warnings {p}{red: Warning: No Dataset Label defined for Language{it: `_label_language'}.}{p_end}"'
						}
						quietly: label var `_varcode' `"`_var`i'_char_label`j''"'
					}
				}
				if "`_var`i'_char_name`j''"!="variable" & strpos("`_var`i'_char_name`j''", "label")==0 {
					char `_varcode'[`_var`i'_char_name`j''] `"`_var`i'_char_label`j''"'
				}
			}
			else {
				local _metadatafornonexistingvariable=1
				global warnings= `"$warnings {p}{red: Metadata for{it: `_varcode'} not assigned: variable not in the dataset.}{p_end}"'
			}	
		}
	}
	foreach var of varlist _all{
		forvalues l = 1/`language_counter'{
			quietly: label language `_language`l''
			local _varlabel : variable label `var'
			if "`_varlabel'" == ""{
				local _varlabelmissing=1
				global warnings= `"$warnings {p}{red: Warning: No Label defined for Variable{it: `var'} for Language{it: `_language`l''}.}{p_end}"'
			}
		}
	}
	if (`nvalue_labels'>0){
		*Build value labels from locals
		forvalues i=1/`n_variable_to_label'{
			forvalues j=1/`_var`i'_nvals'{
				if (`j'==1){
					forvalues l = 1/`language_counter'{
						if `"`_var`i'_label`j'_lan`_language`l'''"' != ""{
							capture label define _var`i'_labels_`_language`l'' `_var`i'_value`j'' `"`_var`i'_label`j'_lan`_language`l'''"'
							if (_rc == 198){
								di "{red: Warning: Invalid value of value label. Label `_var`i'_label`j'_lan`_language`l''' for `_var`i'_value`j'' of variable `_varname`i'' was not assigned.}"
							}
						}
					}	
				}
				if `j'>1 {
					forvalues l = 1/`language_counter'{
						if `"`_var`i'_label`j'_lan`_language`l'''"' != ""{
							capture label define _var`i'_labels_`_language`l'' `_var`i'_value`j'' `"`_var`i'_label`j'_lan`_language`l'''"', add
							if (_rc == 198){
								di "{red: Warning: Invalid value of value label. Label `_var`i'_label`j'_lan`_language`l''' for `_var`i'_value`j'' of variable `_varname`i'' was not assigned.}"
							}
						}
					}
				}
			}
		}

		*Assign value labels to Variables
		forvalues i=1/`n_variable_to_label'{
			capture confirm variable `_varname`i'', exact
			if (_rc == 0){
				local _variable_type : type `_varname`i''
				if strpos("`_variable_type'", "str") == 1 {
					forvalues j=1/`_var`i'_nvals'{
						if (`j'==1){
							local _values = "`_var`i'_value`j''"
							forvalues l = 1/`language_counter'{
								local _labels_`l' = "`_var`i'_label`j'_lan`_language`l'''"
							}
						}
						else {
							local _values = "`_values'<;>`_var`i'_value`j''"
							forvalues l = 1/`language_counter'{
								local _labels_`l' = "`_labels_`l''<;>`_var`i'_label`j'_lan`_language`l'''"
							}
						}
					}
					char `_varname`i''[labelled_values] `_values'
					forvalues l = 1/`language_counter'{
						char `_varname`i''[value_labels_`_language`l''] `_labels_`l''
					}
					
				}
				if strpos("`_variable_type'", "str") != 1 {
					forvalues l = 1/`language_counter'{
						qui label language `_language`l''
						capture label list _var`i'_labels_`_language`l''
						if (_rc == 111 & "`_language`l''" != "default") {
							local _valuelabelmissing=1
							global warnings= `"$warnings {p}{red: Warning: No Value Labels defined for Variable{it: `_varname`i''} for Language{it: `_language`l'' }.}{p_end}"'
						}
						if (_rc == 0) {
							label values `_varname`i'' _var`i'_labels_`_language`l''
						}
					}
				}
			} 
			else {
				local _vallabelfornonexistingvariable=1
				global warnings= `"$warnings {p}{red: Value Labels for {it: `_varname`i''} not assigned: variable not in the dataset.}{p_end}"'
			}
		}	
	}
	
	
	if (`default_exists'!=1){
		capture label language default, delete
	}
	else {
		if (`verboseit'==1) {
			di "{red: Your dataset contains labels and/or descriptions without a language tag. The labels have been assigned to the language default.}"
		}
	}
	if `saveit'==1 {
		quietly: save `"`save'"', `replace'
	}
	if (`_datasetlabelmissing'==1 & `verboseit'==1) di `"{red: Warning: No Dataset Label defined for one or more Languages. For further information display global {it:warnings}}"'
	if (`_metadatafornonexistingvariable'==1 & `verboseit'==1) di `"{red: Warning: Some Variable Metadata could not be assigned: variable(s) not in the dataset. For further information display global {it:warnings}}"'
	if (`_vallabelfornonexistingvariable'==1 & `verboseit'==1) di `"{red: Warning: Some Value Labels could not be assigned: variable(s) not in the dataset. For further information display global {it:warnings}}"'
	if (`_valuelabelforstringvariable'==1 & `verboseit'==1) di `"{red: Warning: Some Value Labels were not assigned because Variable is a string Variable. For further information display global {it:warnings}}"'
	if (`_varlabelmissing'==1 & `verboseit'==1) di `"{red: Warning: No Label defined for some Variables for some Languages. For further information display global {it:warnings}}"'
	if (`_valuelabelmissing'==1 & `verboseit'==1) di `"{red: Warning: No Value Labels defined for some Variables. For further information display global {it:warnings}}"'
	qui label language `_language1'
end
