/*----------------------------------------------------------------------------------
  opendf_dta2csv: builds csv files containing data and meta data from Stata dataset (.dta)
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
*! opendf_dta2csv.ado: loads data from csvs including meta data to build a Stata dataset
*! version 2.0.2 - 28 August 2024 - SSC Initial Release


program define opendf_dta2csv 
	version 16
    	syntax, output_dir(string) [languages(string) input(string)]
	if (c(N) == 0 & c(k)==0) {
    	di as error "Dataset is empty."
    	exit
  	}

	*if output_dir is not temp dir or if we are in linux, we add / to the path
	if ("`output_dir'" != "`c(tmpdir)'" | "`c(os)'"=="Unix"){
      		local output_dir = "`output_dir'/"
    	}
	*Save dataset as data.csv
	quietly: export delimited "`output_dir'data",  nolabel replace quote
	
	
	*save original data as tempfile
	quietly: tempfile orig_datatempfile 
	quietly: save `orig_datatempfile'
	
	qui keep in 1
	*save empty data as tempfile (with only one row) to accelerate loading the metadata in loops
	quietly: tempfile datatempfile 
	quietly: save `datatempfile'

	if ("`languages'" == "") {
		local languages="all"
	}

	if ("`languages'" == "all") {
		local _languages: char _dta[_lang_list]
	}
	else {
		local _languages= "`languages'"
	}

	if (`"`_languages'"' == "") {
		local _languages="default"
	}

	local study : char _dta[study]
	local dataset : char _dta[dataset]
	local url : char _dta[url]
	local label = ""
	local default_exists=0
	foreach l in `_languages'{
		if ("`l'"=="default"){
			quietly: local description_`l' : char _dta[description]
			quietly: label language `l'
			quietly: local label_`l' : data label
			local default_exists=1
		}
		else {
			quietly: local description_`l' : char _dta[description_`l']
			quietly: label language `l'
			quietly: local label_`l' : data label
		}
	}
	clear
	quietly {
		set obs 1
		gen study = "`study'"
		gen dataset = "`dataset'"
		foreach l in `_languages'{
			if "`l'"=="default"{
				if "`label_`l''"!="" gen label = `"`label_`l''"'
				if `"`description_`l''"'!= "" gen description = `"`description_`l''"'
			}
			else {
				if "`label_`l''"!="" gen label_`l' = `"`label_`l''"'
				if `"`description_`l''"'!= "" gen description_`l' = `"`description_`l''"'
			}
		}
		gen url="`url'"
		
		*order columns (check whether label/description without language tag exist)
		capture confirm variable description, exact
		if (_rc==0) {
			local _description_ description
		}
		capture confirm variable description_
		if (_rc==0) {
			local _description_ `_description_' description_*
		}
		capture confirm variable label, exact
		if (_rc==0) {
			local _label_ label
		}
		capture confirm variable label_
		if (_rc==0) {
			local _label_ `_label_' label_*
		}
		
		order study dataset `_label_' `_description_' url
	}
	*drop empty labels and descriptions columns
	foreach var of varlist * {
		qui replace `var' = "" if `var'=="."
        if ("`var'" =="label" | "`var'" == "description"){
            qui count if missing(`var')
		    if (`=r(N)' == c(N)) drop `var'
        }     
	}
	*save dataset metadata as dataset.csv in output directory
	quietly: export delimited "`output_dir'dataset", replace quote

	*******   export variables meta data to variables.csv**************

	quietly {
		use `datatempfile', clear
		local _nvar "`c(k)'"
		clear
		*create empty dataframe with variables metadata with variables: variable, label, label_`languages', description, description_`l', url, type
		set obs `_nvar'
		gen variable=""
		foreach l in `_languages'{
			if ("`l'"=="default"){
				gen label=""
				gen description=""
			}
			else {
				gen label_`l'=""
				gen description_`l'=""
			}
		}
		gen url=""
		gen type=""

		*save as temp file
		tempfile variablestempfile 
		save `variablestempfile'
		*Now for each variable save the metadata to the variables tempfile
		use `datatempfile', clear
		local _nvar_counter = 0
		foreach var of varlist _all {
			local _nvar_counter = `_nvar_counter'+1
			local variable = "`var'"
			local url : char `var'[url]
			local type : char `var'[type]
			local label = ""
			foreach l in `_languages'{
				if ("`l'"=="default"){
					local description_`l' : char `var'[description]
				}
				else {
					local description_`l' : char `var'[description_`l']
				}
				label language `l'
				local label_`l' : var label `var'
			}
			use `variablestempfile', clear
			replace variable in `_nvar_counter' = "`variable'"
			replace url in `_nvar_counter' = "`url'"
			replace type in `_nvar_counter' = "`type'"
			
			foreach l in `_languages'{
				if "`l'"=="default"{
					if `"`description_`l''"'!= "" replace description in `_nvar_counter' = `"`description_`l''"'
					if `"`label_`l''"'!= "" replace label in `_nvar_counter' = "`label_`l''"
				}
				else {
					if `"`description_`l''"'!= "" replace description_`l' in `_nvar_counter' = `"`description_`l''"'
					if `"`label_`l''"'!= "" replace label_`l' in `_nvar_counter' = "`label_`l''"
				}
			}
			save `variablestempfile', replace
			use `datatempfile', clear
		}
		use `variablestempfile', clear
		*order columns (check whether label/description without language tag exist)
		capture confirm variable description, exact
		if (_rc==0) {
			local _description_ description
		}
		capture confirm variable description_
		if (_rc==0) {
			local _description_ `_description_' description_*
		}
		capture confirm variable label, exact
		if (_rc==0) {
			local _label_ label
		}
		capture confirm variable label_
		if (_rc==0) {
			local _label_ `_label_' label_*
		}
		
		order variable `_label_' type `_description_' url
		
		*drop empty labels and descriptions columns
		foreach var of varlist * {
			qui replace `var' = "" if `var'=="."
            if ("`var'" =="label" | "`var'" == "description"){
                qui count if missing(`var')
		        if (`=r(N)' == `_nvar') drop `var'
            }     
		}
	}
	*save variables metadata as variables.csv in output directory
	quietly: export delimited "`output_dir'variables", replace quote
	





	************     export variable labels to categories.csv    *****************

	quietly {
		*load dataset again
		use `datatempfile', clear
		*count how many value labels there are in total
		local _nvaluelabels=0
		qui label dir
		foreach _lbl in `r(names)' {
			label list `_lbl'
			local _nvaluelabels = `_nvaluelabels'+r(k)
		}
		local _nvaluelabels = "`_nvaluelabels'"
		clear
		
		*generate empty dataset for the variable labels
		set obs `_nvaluelabels'
		gen variable=""
		gen value=.
		foreach l in `_languages'{
			if ("`l'"=="default"){
				gen label=""
			}
			else {
				gen label_`l'=""
			}
		}


				
		tempfile categoriestempfile 
		save `categoriestempfile'
		use `datatempfile', clear
		local _row_categories_out = 0
		foreach var of varlist _all{
			local _nvaluelabel=0
			*find out if a variable has any label:
			local _has_label=0
			local _lblname ""
			foreach l in `_languages'{
				capture qui label language `l '
				capture qui local _lblname: value label `var'
				capture label list `_lblname'
				if ("`_lblname'"!= "" & _rc==0){
					local _has_label=1
				}				
			}
			*check for label for string variable
			local _values = ""
			local _variable_type : type `var'
			if strpos("`_variable_type'", "str") == 1 {
				local _values : char `var'[labelled_values]
				if ( "`_values'" != ""){
					local _has_label=1
					foreach l in `_languages'{
						local _labels_`l' : char `var'[value_labels_`l']
					}
				}
			}

			if (strpos("`_variable_type'", "str") == 1 & `_has_label' == 1) {
				use `categoriestempfile', clear
				while "`_values'" != "" {
					local _nvaluelabel = `_nvaluelabel' + 1
					if (c(N) < `_nvaluelabel') {
						set obs `_nvaluelabel'
					}
					replace variable = "`var'" in `_nvaluelabel'
					if (strpos("`_values'", "<;>") >0) {
						local _val = substr("`_values'", 1, strpos("`_values'", "<;>")-1)
						di "`_val'"
						replace value = `_val' in `_nvaluelabel'
						local _values = substr("`_values'", strpos("`_values'", "<;>")+3, strlen("`_values'"))
						foreach l in `_languages'{
							local _lab = substr("`_labels_`l''", 1, strpos("`_labels_`l''", "<;>")-1)
							di "`_lab'"
							if ("`l'" != "default"){
								replace label_`l' = "`_lab'" in `_nvaluelabel'
							}
							else {
								replace label = "`_lab'" in `_nvaluelabel'
							}
							local _labels_`l' = substr("`_labels_`l''", strpos("`_labels_`l''", "<;>")+3, strlen("`_labels_`l''"))
						}
					}
					else {
						local _val = "`_values'"
						di "`_val'"
						replace value = `_val' in `_nvaluelabel'
						local _values=""
						foreach l in `_languages'{
							local _lab = "`_labels_`l''"
							di "`_lab'"
							if ("`l'" != "default"){
								replace label_`l' = "`_lab'" in `_nvaluelabel'
							}
							else {
								replace label = "`_lab'" in `_nvaluelabel'
							}
							local _labels_`l' = ""
						} 
					}
				}
				save `categoriestempfile', replace	
				use `datatempfile', clear
			}
			else {
				*find lowest and highest value that has a label
				if (`_has_label'==1){
					quietly label list `_lblname'
					local _min_val=`r(min)'
					local _max_val=`r(max)'
					foreach l in `_languages'{
						local _lblname ""
						capture qui label language `l '
						capture qui local _lblname: value label `var'
						if ("`_lblname'"!= ""){
							quietly label list `_lblname'
							if (`_min_val'>`r(min)') local _min_val=`r(min)'
							if (`_max_val'<`r(max)') local _max_val=`r(max)'
						}
					}
					*for each value between the lowest and the highest value, we check whether a value label exists for every language and assign it to _lbl_de1 (first value label in German)
					forvalues _val=`_min_val'/`_max_val'{
						local _value_has_any_label=0
						foreach l in `_languages'{
							quietly label language `l'
							local _lblname ""
							capture qui local _lblname: value label `var'
							if ("`_lblname'"!= ""){
								local _lbl: label `_lblname' `_val'
								if ("`_lbl'" != "`_val'") {
									if (`_value_has_any_label'==0){
										local _nvaluelabel = `_nvaluelabel' + 1
										local _val`_nvaluelabel'=`_val'
										local _value_has_any_label=1
									}
									local _lbl_`l'`_nvaluelabel'=`"`_lbl'"'
								}
							}
							
						}
					}
					use `categoriestempfile', clear
					forvalues i=1/`_nvaluelabel'{
						local _row_categories_out = `_row_categories_out' + 1
						replace variable in `_row_categories_out'="`var'"
						replace value in `_row_categories_out'=`_val`i''
						foreach l in `_languages'{
							if ("`l'"=="default"){
								replace label in `_row_categories_out'=`"`_lbl_`l'`i''"'
							}
							else {
								replace label_`l' in `_row_categories_out'=`"`_lbl_`l'`i''"'
							}
						}
					}
					save `categoriestempfile', replace
					use `datatempfile', clear
				}
			}
			
		}	
	}
	quietly: use `categoriestempfile', clear 
	*order columns
	capture confirm variable label, exact
	if (_rc==0) {
		local _label_ label
	}
	capture confirm variable label_
	if (_rc==0) {
		local _label_ `_label_' label_*
	}	
	order variable value `_label_' 
	
	*drop empty rows
	quietly: drop if variable == ""
	*drop empty labels and descriptions
	foreach var of varlist * {
			if ("`var'"!="value") qui replace `var' = "" if `var'=="."
            if ("`var'"=="label"){
                quietly: qui count if missing(`var')
			    quietly: if (`=r(N)' == c(N)) drop `var'
            }     
		}
	*save variables metadata as variables.csv in output directory
	quietly: export delimited "`output_dir'categories", replace quote
	quietly: use `orig_datatempfile', clear
end
