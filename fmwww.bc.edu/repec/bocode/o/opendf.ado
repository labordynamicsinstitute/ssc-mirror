/*----------------------------------------------------------------------------------
  opendf.ado: functions to work with data in opendf format (zip)
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
*! opendf.ado: provides programs to work with opendf data format
*! version 2.0.0 - 27 August 2024 - SSC Initial Release

program define opendf, rclass 
	version 16
	syntax [anything], [INPUT(string) OUTPUT(string) SAVE(string) LANGUAGES(string) VARIABLES(string) VERSION(string) LOCATION(string) ROWRange(string) COLRange(string) csv_loc(string) variables_arg(string) export_data(string) input_zip(string) output_dir(string) REPLACE CLEAR VERBOSE]
	local _fun = `"`anything'"'
	tokenize `"`_fun'"'

	if ("`1'"=="read"){
		opendf_read `"`2'"', rowrange(`rowrange') colrange(`colrange') `clear' save("`save'") `replace' `verbose'
	}

	if ("`1'"=="write"){
		opendf_write `"`2'"', input("`input'") languages("`languages'") variables("`variables'") `replace' `verbose'
	}
	
	if ("`1'"=="installpython"){
		opendf_installpython, version("`version'") location("`location'")
	}
	if ("`1'"=="removepython"){
		opendf_removepython, version("`version'") location("`location'")
	}

	if ("`1'"=="docu"){
		opendf_docu `"`2'"', languages("`languages'")
	}

	if ("`1'"=="csv2dta"){
		opendf_csv2dta, csv_loc(`csv_loc') rowrange(`rowrange') colrange(`colrange') `clear' save("`save'") `replace' `verbose'
	}
	if ("`1'"=="csv2zip"){
		opendf_csv2zip, output(`output') input(`input') variables_arg(`variables_arg') export_data(`export_data')
	}

	if ("`1'"=="dta2csv"){
		opendf_dta2csv, output_dir(`output_dir') languages("`languages'") input(`input')
	}

	if ("`1'"=="zip2csv"){
		opendf_zip2csv, input_zip(`input_zip') output_dir(`output_dir') languages(`languages') `verbose'
	}
end
