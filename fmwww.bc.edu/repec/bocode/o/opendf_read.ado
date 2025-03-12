/*----------------------------------------------------------------------------------
  opendf_read.ado: loads data from opendf format (zip) to Stata
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
*! opendf_read.ado: loads data from opendf format (zip) to Stata
*! version 2.1.0


			
program define opendf_read 
	version 16
	syntax anything [,LANGUAGES(string) ROWRange(string) COLRange(string) SAVE(string) REPLACE CLEAR VERBOSE]
	local input=`anything'
  	*If the data.zip is a web path, the data is downloaded to the temp-folder
	if strpos(`"`input'"', "http")>0 | strpos(`"`input'"', "www.")>0{
		local _tempdir "`c(tmpdir)'"
		if (substr("`_tempdir'", strlen("`_tempdir'"), strlen("`_tempdir'")) != "/" & substr("`_tempdir'", strlen("`_tempdir'"), strlen("`_tempdir'")) != "\"){
			local _tempdir = "`_tempdir'/"
    	}
	  	local _path_to_data `"`_tempdir'data.odf.zip"'
		quietly: copy `input' `_path_to_data', replace
		local input `_path_to_data'
	}
	*Check if file exists and add extension if .odf.zip (or .zip) if missing
	if strpos(`"`input'"', ".zip")==0{
		capture confirm file `"`input'.odf.zip"'
		if _rc == 0{
			local input = "`input'.odf.zip"
		}
		else {
			capture confirm file `"`input'.zip"'
			if _rc == 0{
				local input = "`input'.zip"
			}
			else {
				di as error "File `input'.odf.zip (and `input'.zip) not found."
				exit
			}
		}
	}
	capture confirm file `"`input'"'
	if _rc != 0{
		di as error "File `input' not found."
		exit
	}

	if (`"`languages'"' != "") {
	  	local languages `languages'
	}
	else {
      	local languages "all"
    }
    local input_zip=`"`input'"'
    local csv_temp = "`c(tmpdir)'"
    opendf_zip2csv , input_zip(`input_zip') output_dir("`csv_temp'") languages(`languages') `verbose'
	opendf_csv2dta, csv_loc("`csv_temp'") rowrange(`rowrange') colrange(`colrange') odf_version("`r(odf_version)'") save(`save') `replace' `clear' `verbose'
end

