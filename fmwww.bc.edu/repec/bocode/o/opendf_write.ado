/*----------------------------------------------------------------------------------
  opendf_write.ado: loads data from opendf format (zip) to Stata
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
*! opendf_write.ado: saves a Stata (.dta) dataset in the opendf format 
*! version 2.1.0

program define opendf_write 
    version 16
    syntax anything [,input(string) languages(string) variables(varlist) odf_version(string) REPLACE VERBOSE]
    preserve
    local replaceit 0
    if (`"`replace'"' != "") local replaceit 1
    local output=`anything'
    if (strpos("`output'", ".zip") == 0){
      if ("`odf_version'" == "1.0.0" | strpos("`output'", ".odf")>0){
        local output = "`output'.zip"
      }
      else {
        local output = "`output'.odf.zip"
      }
    } 
    capture confirm file "`output'"
    if (_rc == 0 & `replaceit'==0){
      di as error "file `output' already exists"
			exit 602
    }
    
    if (`"`languages'"' == "") {
	  	local languages "all"
	  }
    if (`"`input'"' != "") {
      capture quietly use "`input'", clear
      if _rc!=0{
        if (_rc==601 | _rc==610) {
          di as error "Error: `input' is not a valid Stata dataset (.dta). Insert (the path to a) valid dataset (.dta) or leave argument 'input' empty to use the dataset loaded in Stata."
          exit _rc
        }
        else {
          use "`input'", clear
        }
      }
    }

    if "`odf_version'" == ""{
      local odf_version = "1.1.0"
    }
    if (`"`variables'"' != "" & `"`variables'"'!= "all") {
	  	    keep `variables'
	  }

    local wd: pwd
    if (strpos("`output'", "\")==0 & strpos("`output'", "/")==0){
      local output= "`wd'/`output'"
    }
    
    * check numeric variables for extended missings and replace extended missings with normal missings
    foreach var of varlist * {
	    capture confirm numeric variable `var'
	    if (_rc == 0) {
		    capture assert `var' <= . , fast
		    if (_rc  == 9) {
			    local extensive_missings="TRUE"
			    replace `var'=. if `var'>.
		    }
		    else if (_rc) {
			    display as err  "unexpected error"
			    exit _rc
		    }
	    }
    }
    if ("`extensive_missings'"=="TRUE"){
	    di as red "Warning: extensive missings in numeric variables (.a, .b, ..., .z) are not compatible to ODF specification."
	    di as red "Extensive missings were replaced by ordinary missing (.). Value labels of extended missings are not written to ODF-file."
	    di as red "To keep value labels of extended missings, replace extended missings with integers and transfer value labels to ne value."
    }

    opendf_dta2csv, languages(`languages') input(`input') output_dir("`c(tmpdir)'") odf_version("`odf_version'")
    capture opendf_csv2zip, output(`"`output'"') input("`c(tmpdir)'") variables_arg("yes") export_data("yes") odf_version("`odf_version'") `verbose'
    if (_rc != 0) {
      di as error "Error in writing `output'. There might be problems with the writing permissions in the output folder or with some metadata."
      if (`"`verbose'"' != "") {
        opendf_csv2zip , output(`"`output'"') input("`c(tmpdir)'") variables_arg("yes") export_data("yes") odf_version("`odf_version'") `verbose'
      }
      exit _rc
    }
    capture confirm file `"`output'"'
    if _rc == 0 {
      di "{text: Dataset successfully saved in opendf-format to {it:`output'}.}"
    }
end
