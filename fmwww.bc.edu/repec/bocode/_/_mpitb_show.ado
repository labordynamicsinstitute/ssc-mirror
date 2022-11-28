*! part of -mpitb- the MPI toolbox

cap program drop _mpitb_show
program define _mpitb_show 
	syntax , [Name(name) List RETurn]
	
	* syntax checks
	if "`name'`list'" == "" | ("`name'" != "" & "`list'" != "") {
		di as err "Please choose one of {bf:name()} and {bf:list}!"
		e 197
	}

	loc mpilist : char _dta[MPITB_names]
	
	* -list- option 
	if "`list'" != "" {
		if "`mpilist'" == "" {
			di as err "No MPI specification found. Run {bf:mpitb set} first!"
			e 197
		}
		else if "`mpilist'" != "" {
			di as txt "MPIs found:"
			foreach m in `mpilist' {
				di _col(3) "{stata _mpitb_show, name(`m'):`m'} " _col(15) "`_dta[MPITB_`m'_desc]'"
			}
		}
	}
	
	* -name- option
	if "`name'" != "" {
			* confirm main chars exists
			loc setrun : char _dta[MPITB_`name'_dep_vars]						// -mpi_set- was run?
			if "`setrun'" == "" {
				di in smcl as err "Deprivation indicators for {bf:name} not set." /// 
				_n "Please run {bf:mpitb set} first!"
				e 197
			}

		* retrieve locals from char
		loc dnames : char _dta[MPITB_`name'_dim_names]
		foreach d in `dnames' {
			loc dim_`d'_vars : char _dta[MPITB_`name'_dim_`d'_vars]
		}
		if "`return'" == "" {
			loc dep_vars_act : char _dta[MPITB_dep_vars_act]
			loc wgtsname : char _dta[MPITB_wgts_name]
			loc dimwgts : char _dta[MPITB_wgts_dim]
			loc depwgts : char _dta[MPITB_wgts_dep]
		}
		else if "`return'" != "" {
			if "`r(cmd)'" == "_mpitb_setwgts" {
				loc dep_vars_act = r(dep_vars_act)
				loc wgtsname = r(wgts_name)
				loc dimwgts = r(wgts_dim)
				loc depwgts = r(wgts_dep)
			}
			else {
				di as txt "Note: No returns found."
			}
		}

		* set values for chars not found
		if "`dimwgts'" == "" {
			foreach n in `dnames' {
				loc dimwgts "`dimwgts' . "
			}
			loc wgtsnote "--- weighting schemes not yet set ---"
		}
		
		loc dscrb : char _dta[MPITB_`name'_desc]
		if "`dscrb'" == "" {
			loc dscrbnote "no description provided"
		}
		else if "`dscrb'" != "" {
			loc dscrbnote `dscrb'
		}

		* main panel
		loc ri = c(linesize) - 80
		di in txt "{dlgtab 0 `ri':Specification}"
		di _col(1) as txt "Name: {bf:`name'}."
		di _col(1) as txt "Weighting scheme: {bf:`wgtsname'}." // _n(1)
		di _col(1) as txt in smcl "Description: `dscrbnote'"
		di _col(1) in smcl "{hline 80}"
		*di _col(1) as txt "Structure"
		loc i = 1
		foreach d in `dnames' {
			loc dw : word `i' of `dimwgts'
			di _col(1) as txt "Dimension `i++':" as res _col(14) "`d'" _col(25) "`:di %5.4f `dw''" /// 
			_col(35) as txt "(`dim_`d'_vars')"			// just disp all loc defined (for debug)
		}
		di _col(1) in smcl "{hline 80}"

		* weights panel
		*di as txt _col(1) "Indiciator weights:"
		loc i=0
		foreach j in `dep_vars_act' {
			loc depw : word `++i' of `depwgts'
			di as txt _col(1) "Indicator `i': " _col(14) as res "`j'" _col(25) as txt  "`:di %5.4f `depw''" 
		}
		if ("`wgtsnote'" != "") di as txt _col(1) "`wgtsnote'"
		di _col(1) in smcl "{hline 80}"

		* note panel
		* missing indicators
		if "`wgtsnote'" == "" {
			if "`_dta[MPITB_misind]'"  == "" {
				di _col(1) as txt "No missing indicator was found."
			}
			else {
				di _col(1) as txt "Note: missing indicators found: " as res "`_dta[MPITB_misind]'" as txt "."
			}
		}
		/*
		di _col(4) as txt _c "Available MPIs to display: " 

		foreach m in `mpilist' {
			di "{stata _mpitb_show,name(`m'):`m'} " _c
		}
		*/
	}
end
