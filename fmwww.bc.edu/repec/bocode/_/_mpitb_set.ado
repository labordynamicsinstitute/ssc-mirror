*! part of -mpitb- the MPI toolbox

cap program drop _mpitb_set		
program define _mpitb_set , rclass
	syntax , [Name(string) d1(string) DEscription(string) d2(string) d3(string) /// 
				d4(string) d5(string) d6(string) d7(string) d8(string) d9(string) ///
				d10(string) CLEAR REPLACE] 

	* syntax checks and parsing
	if ("`clear'" == "" & "`name'" == "") | ("`clear'" != "" & "`name'" != "") {
		di as err "Please choose {bf:clear} or {bf:name()} option!"
		exit 198
	}
	if "`name'" != "" & "`d1'" == "" {
		di as err "Option {bf:d1()} required with option {bf:name().}"
		exit 198
	}

	if "`clear'" != "" & "`replace'" != "" {
		di as err "Please choose {bf:clear} or {bf:replace}."
		exit 198
	}
	if length("`name'") > 10 {
		di as err "`name' too long."
		exit 198
	}

	if "`replace'" == "" & "`clear'" == "" {
		loc MPInames `_dta[MPITB_names]'
		if `: list name in MPInames' == 1 {
			di as err "MPI specification {bf:`name'} already exists! Change name or set option {bf:replace}."
			exit 198
		}
	}

	* parsing dimensions 
	forval i = 1/10 {
		// di "d`i': `d`i''"						// for debug
		if ("`d`i''" != "") {
			parse_d `d`i'' // did(`i')					// parse both content and id of dimension
			
			loc d`i'_vars `s(d_vars)'				// dimension-specific locals
			loc d`i'_name `s(d_name)'
			if ("`d`i'_name'" == "") loc d`i'_name d`i'
		
			loc vars `vars' `d`i'_vars' 				// MPI-specific locals 	(indicators variables)
			loc d_names `d_names' `d`i'_name'			// 			(names of dimensions)
		}
	}
	* plausibility check: unique indicator
	loc dupvars : list dups vars
	if "`dupvars'" != "" {
		di as err "Found repeated deprivation indicators: {bf:`dupvars'}."
		exit 198
	} 
	* check binary nature of indicators
	foreach v of varlist `vars' {
		cap: assert inlist(`v',0,1) if !mi(`v')
		if _rc == 9 {
			di as err "Deprivation indicator ({bf:`v'}) with values out of range. "
			exit 198 
		}
	}
	
	* delete all MPI-chars
	loc clist : char _dta[]
	foreach c of local clist {
		if "`clear'" != "" {
			if (strmatch("`c'","MPI*")) char _dta[`c'] ""			
		}
		if "`replace'" != "" {
			if (strmatch("`c'","MPI_`name'*")) char _dta[`c'] ""			
		}
	}

	if "`clear'" == "" {
		* update name list
		loc names `_dta[MPITB_names]' `name'
		loc names : list uniq names
		loc names : list sort names

		* return
		ret loc cmd "mpi_set"
		ret loc name "`name'"
		ret loc dep_vars "`vars'"
		ret loc dim_names "`d_names'"
		forval i = 1/10 {
			ret loc dim_`d`i'_name'_vars `d`i'_vars'
		}
		* store as chars
		char _dta[MPITB_names] "`names'"
		char _dta[MPITB_`name'_dep_vars] "`vars'"
		char _dta[MPITB_`name'_dim_names] "`d_names'"
		char _dta[MPITB_`name'_desc] `description'
		forval i = 1/10 {
			char _dta[MPITB_`name'_dim_`d`i'_name'_vars] "`d`i'_vars'"
		}
	}
end

*******************************************
*** program to parse syntax for mpi_set ***
*******************************************
capture program drop parse_d
program define parse_d , sclass
syntax varlist , [Name(name) did(numlist max=1 integer) dimw(numlist max=1)]
	if length("`name'") > 6 {
		di as err "dimension name {bf:`name'} too long."
		exit 198
	}
	foreach v of varlist `varlist' {
		if length("`v'") > 10 {
			di as err "variable name {bf:`v'} too long."
		exit 198
		}
	}
	
	sret clear
	sret loc d_name "`name'"
	sret loc d_vars "`varlist'"
	sret loc d_wgt "`dimw'"
end
