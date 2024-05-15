********************************************************************************
* allcatplot
********************************************************************************

	/*

	The allcatplot Stata program does not plot all or any cat(s) on a graph. Instead, it ensures that all predefined response categories for a variable, including those that were not selected, are included in a graph. Traditional plotting methods omit such unselected categories, potentially skewing interpretation. allcatplot uses the predefined value labels to identify and label such omitted response options and add them to the graph as zero-height bars. Additionaly, it also supports custom lists, labels and graph customization directly through the program syntax.

	This program is especially useful for surveys and assessments utilizing likert scales or other structured response options, where it offers a holistic view of all potential responses in the graph, including those that weren't selected, thereby ensuring a comprehensive understanding of the full range of response options.

	Additionally, allcatplot can be used to do the opposite of what its name suggests: exclude specific categories from the graph for clarity or analytical purposes. For instance, in a dataset with varied selections across options A, B, C, and D for a specific variable, the program can be configured to display only the responses for options A, B, and C (or any other combination of the four in any order of your choice). This doesn't eliminate the data for option D but merely hides it from the graph, with the displayed bar heights accurately reflecting the frequencies or percentages of responses for the displayed options as per the total count.

	*/


cap prog drop 	allcatplot
program 		allcatplot

    version 11.2
    

syntax varlist (max=1)					///
			   [if]            			/// 
               [in],           			/// 
			   [Over(string asis)]		///
			   [List(string asis)] 		///
			   [RElabel(string asis)]	///
			   [Freq]					///
			   [Sort]					///
			   [Title(string asis)]		///
			   [Missing]				///
			   [Recast(string asis)] 	///
               [Graphopts(string asis)] 

qui {	
	
	********************************************************************************
	* Section 1: Standard set-up with details of program dependencies and temp files 
	********************************************************************************
			   
	/// this program requires the elabel program to search through predefined response categories
		
	cap which elabel
	if _rc == 111{
			
	display as err "	This module requires the 'elabel' package to search through predefined response categories."
	display as err "	You need to run:" 
	display as err "	ssc install elabel, replace"
	exit 198
}		   

	/// and it requires splitvallabels to format long value labels in graphs

	cap which splitvallabels
	if _rc == 111{
			
	display as err "	This module requires the 'splitvallabels' package to format long value labels."
	display as err "	You need to run:" 
	display as err "	ssc install splitvallabels, replace"
	exit 198
}		
			   
	/// by using preserve and restore, if the ado file aborts, the original data will be automatically restored
	
	/// advice provided by Kit Baum
	
	preserve
	
	/// locals for N and missing obs
	
		/// the locals for the number of observations and missing have to be calculated prior to using marksample as marksample correctly drops all missing values of varlist
	
	count if !(missing(`varlist'))
	local N `r(N)'
	
	count if missing(`varlist')
	local miss `r(N)'
	
	/// sample indicator for maping the [IF] condition
	
	marksample touse, strok
	keep if `touse' == 1
	
	/// this bit of code ensures that our program works with string variables as well
	
	ds `varlist', has(type string)
	local string_var `r(varlist)'
	
	if "`string_var'" != "" {		
	encode `varlist', gen (`varlist'e)
	drop  `varlist'
	rename `varlist'e `varlist'	
	}
	
	if "`over'" != "" {

	ds `over', has(type string)
	local string_var `r(varlist)'
	
	if "`string_var'" != "" {		
	encode `over', gen (`over'e)
	drop  `over'
	rename `over'e `over'	
	}
	
}
	
	********************************************************************************
	* Section 2: Setting locals that will be used later or in our graph
	********************************************************************************

	/// create locals for var label and value label
	
	local var_lab : variable label `varlist'
	
	/// if there is no var label, use the var name
	
	if "`var_lab'" == "" {
    local var_lab `varlist'
}

	local val_lab: 	value label `varlist'
	
	/// allow for various graph styles with vertical bars as default
	
	local graph_style   	bar
	
	if "`recast'" != "" {			
	local graph_style 		`recast'
	}	
	
	/// the graph defauls to a percentage graph
	
	if "`freq'" == "" {	
	local graph_dist	"percent"
	local graph_range 	"ytitle(Percent) ylabel(0(20)100)"  
	local graph_decimal "%9.1f"
	}
	
	/// but works effectively for frequency distributions as well
	
	if "`freq'" != "" {	
	local graph_dist	"_freq"
	local graph_range 	"ytitle(Frequency)" 
	local graph_decimal "%9.0f"
	}
	
	/// allow for sorting later
	
	if "`sort'" != "" {	
	local sort "sort(1) descending"
	}
	
	/// or default to the original order of the list provided by the user. Note: order_var is generated later. 
	
	if "`sort'" == "" {	
	local sort "sort(order_var)"
	}
	
	/// default title is the var label (or var name)
	
	if "`title'" == "" {	
	local title "`var_lab'"
	}
	
	/// missing observations are added as a subtitle (if requested)
		
	if "`missing'" == "" {	
	local subtitle "Number of observations = `N'"
	}
	
	if "`missing'" != "" {	
	local subtitle "Number of observations = `N' and missing observations = `miss'"
	}
	
	
	********************************************************************************
	* Section 3: Which values will be mapped? 
	********************************************************************************
	
	/// now, we move on to the values that will be mapped. if the user has requested for a default list of values, that request will be prioritized and will already be stored as a local called 'list'
	
	
	/// if the user has not requested for a customized list
	
	if "`list'" == "" {
		
		/// check to see if the varlist has a value label attached and populate the list local with all possible values of the variable
	
	if "`val_lab'" != "" {
	elabel list `val_lab'
	local list = "`r(values)'" 		
	}
	
		/// in the absence of value labels and a customized list, default to values in the dataset
	
	if "`val_lab'" == "" {		
	levelsof `varlist', local(list)
	}
		
	}
	
	/// if there is no value label attached to the variable, create a temporary one for the purposes of this program
	
	if "`val_lab'" == "" {	
	local val_lab allcatplot_lab	
	}
	
	********************************************************************************
	* Section 4: Relabelling directly through the program syntax
	********************************************************************************
			
	/// if the user has requested specific labels
	
	if "`relabel'" != "" {
		
	global call ""

	local list_len : 	word count `list'
	local lab_length : 	word count `relabel'
	
	/// check if lab_length is greater than list_len and drop redundant labels 
	
	if (`lab_length' > `list_len') {
    local lab_length `list_len'
}
	/// loop through each label and corresponding list value

	forval i = 1/`lab_length' {
	
   /// Extract the ith label and list value
	
	local current_list = 	word("`list'", `i')
	local current_label = 	subinstr(word("`relabel'", `i'), "_", " ", .)
	
	/// Populate the global call with the list and corresponding labels
	
	global call "${call} `current_list' "`current_label'""

}		
    label define `val_lab' $call, modify
    label values `varlist' `val_lab'
	macro drop call
	}

	
	********************************************************************************
	* Section 5: Simple graph with no disaggregation by another variable
	********************************************************************************
	
	if "`over'" == "" {	

	contract `varlist', percent(percent)
			
	foreach i of numlist `list' {
		
	/// this additional step is necessary because the varlist may have negative values and the negative sign (-) isn't allowed as part of a var name in Stata. Identified as a potential issue by Prabhmeet Kaur. 
	
	/// this step changes the negative signs to underscores when the variables are generated 
		
	local varname temp_v`i'
		
    if `i' < 0 {
        local varname = subinstr("`varname'", "-", "_", .)
    }
    
    gen 	`varname' = 0
    replace `varname' = `graph_dist' if `varlist' == `i'
	}

	collapse (sum) temp_v*
	
	
	* Reshape

	gen id = _n
	reshape long temp_v, i(id) j(val_lab) string

	/// adding the negative signs back 
	
	replace val_lab = subinstr(val_lab, "_", "-", .)
	destring val_lab, replace

	label values val_lab `val_lab'
	
	/// when you reshape, Stata ordes the values in ascending order rather than the structure of the temporary var and so we need a fix
	
	/// this bit of code ensures that the original order as requested by the user is used for the graph 
	
	gen order_var = .
	
	local i = 1

	foreach val in `list' {
    replace order_var = `i' if val_lab == `val'
	local i = `i' + 1
}

	/// splitvallabels ensures that values don't clash with each other but move to separate lines

	splitvallabels val_lab, length(9) nobreak recode
	
	graph `graph_style' (asis) temp_v, over(val_lab, `sort' label(labsize(small)) relabel(`r(relabel)')) ///
	title("`title'", size(medsmall)) ///
	subtitle("`subtitle'", size(small))  ///
	blabel(bar, format(`graph_decimal')) `graph_range' `graphopts' 
	
	}
	
	********************************************************************************
	* Section 6: With disaggregation
	********************************************************************************
	
	if "`over'" != "" {	
				
	tempfile loop
	save     `loop', replace	
		
	/// there may be no value label lists at all (even if there is a local for it)
		
	cap label save `val_lab'	using temp_va_lab, 	replace	
	
	local ov_lab: 	value label `over'
	cap label save `ov_lab' 	using temp_ov_lab, 	replace
	
	levelsof `over', local(categories)
		
	drop _all
	tempfile append
	save `append', emptyok replace
	
	/// we follow the same steps as earlier but for each category of 'over'
	
	foreach cat of local categories {
		    
	use `loop', clear
    keep if `over' == `cat'
    contract `varlist' `over', percent(percent)

	foreach i of numlist `list' {
		
    local varname temp_v`i'
	
    if `i' < 0 {
        local varname = subinstr("`varname'", "-", "_", .)
    } 
    gen 	`varname' = 0
    replace `varname' = `graph_dist' if `varlist' == `i'
}   
	collapse (sum) temp_v* (first) `over'
	
    append using `append'
	save `append', replace
}
	use `append', clear

	
	* Reshape

	gen id = _n
	reshape long temp_v, i(id) j(val_lab) string
	replace val_lab = subinstr(val_lab, "_", "-", .)
	destring val_lab, replace
	
	cap run temp_ov_lab
	cap label values `over' `ov_lab'
	
	cap run temp_va_lab
	cap label values val_lab `val_lab' 
	
	gen order_var = .
	
	local i = 1

	foreach val in `list' {
    replace order_var = `i' if val_lab == `val'
	local i = `i' + 1
}
	splitvallabels val_lab, length(9) nobreak recode
	
	graph `graph_style' (asis) temp_v, over(`over') over(val_lab, `sort' label(labsize(small)) relabel(`r(relabel)')) ///
	asyvars ///
	title("`title'", size(medsmall)) ///
	subtitle("`subtitle'", size(small))  ///
	blabel(bar, format(`graph_decimal')) legend(pos(6) row(1))  `graph_range' `graphopts' 
	
	cap erase temp_ov_lab.do	
	cap erase temp_va_lab.do
	}
	
	restore
	
	}	
end	
