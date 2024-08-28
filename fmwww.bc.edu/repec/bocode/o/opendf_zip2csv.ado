/*----------------------------------------------------------------------------------
  opendf_zip2csv.ado: builds csv files containing data and meta data from a zip-folder containing a data-csv and a meta data xml using python scripts
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
*! opendf_zip2csv.ado: loads data from csvs including meta data to build a Stata dataset
*! version 2.0.0 - 27 August 2024 - SSC Initial Release

program define opendf_zip2csv 
    version 16
    syntax, input_zip(string) output_dir(string) languages(string) [VERBOSE]
    local verboseit 0
    if (`"`verbose'"' != "") {
	  local verboseit 1
    }
    if (substr("`output_dir'", strlen("`output_dir'"), strlen("`output_dir'")) != "/" & substr("`output_dir'", strlen("`output_dir'"), strlen("`output_dir'")) != "\"){
	local output_dir = "`output_dir'/"
    }

    *Check for working python version
    local _python_working=0
    capture python: print()
    if (_rc==0){
        local _python_working=1
    }
    else {
      local subdirs : dir "`c(sysdir_plus)'" dirs "python*"
      foreach x in `subdirs'{
        if (`_python_working'==0){
          capture set  python_exec "`c(sysdir_plus)'`x'\python.exe"
          capture python: print()
          if (_rc==0) {
            local _python_working 1
          }
        }
      }
    }

    if (`_python_working'==1){
        if (`verboseit'==1) di "Working Python Version available."
    }
    else {
      di "{red: Error: Python integration in Stata not available.}"
      di "{red: 1. To install python visit:}"
      di `"{p 10 10}{Stata "view browse https://www.python.org/downloads/":https://www.python.org/downloads/}{p_end}"'
      di "{red: 2. If you have a working python version on your PC but Stata doesn't find it automatically, you can activate it manually by indicating which python.exe to use with following command:}"
      di "{p 10 10}{red: {it:set python_exec  C:\...\python.exe}}{p_end}"
      di "{p 10 10}{red: and retry to run the opendf-function.}{p_end}"
      di "{red: 3. If you are using Windows, the opendf package also provides a function that installs a working python version to a specified path or to the directory of Stata packages (ado\plus folder).}"
      di "{p 10 10}{red: If you are running on Windows you can install python through the build-in opendf-function: {it:opendf installpython}}{p_end}"
      di `"{p 10 10}{red: You can specifiy a version with the argument {it:opendf installpython, version("3.8")}}{p_end}"'
      di `"{p 10 10}{red: You can specifiy a location to install python with the argument {it:opendf installpython, location("C:\Program Files\Python\Python3.8")}}{p_end}"'
      di `"{p 10 10}{red: If you specify the location manually, you have to tell Stata where the python.exe is located (see 2.)")}{p_end}"'
      exit
    }
    local input_zip = subinstr("`input_zip'", "\", "/", .)
    local output_dir = subinstr("`output_dir'", "\", "/", .)
    local _ado_path  "`c(sysdir_plus)'"
    if (substr("`_ado_path'", strlen("`_ado_path'"), strlen("`_ado_path'")) != "/" & substr("`_ado_path'", strlen("`_ado_path'"), strlen("`_ado_path'")) != "\"){
	local _ado_path = "`_ado_path'/"
    }
    local _path_to_py_ado "`_ado_path'py"
    if c(os) == "Windows" {
        local _path_to_py_ado = subinstr("`_path_to_py_ado'", "\", "/", .)
    }
    if (fileexists("`_path_to_py_ado'/xml2csv.py")!=1) {
	if ("`c(os)'"=="Unix" ){
	    local _username "`c(username)'"
	    local _path_to_py_ado = subinstr("`_path_to_py_ado'", "~", "/home/`_username'", .)
	}
    }
    if (fileexists("`_path_to_py_ado'/xml2csv.py")!=1){
	di as error("Error in finding the python script")
	exit
    }
    
    python: from sfi import Macro
    python: import sys
    python: import os
    python: input_zip=Macro.getLocal('input_zip')
    python: languages=Macro.getLocal('languages')
    python: output_dir=Macro.getLocal('output_dir')
    python: sys.path.append(Macro.getLocal('_path_to_py_ado'))
    python: import xml2csv
    python: xml2csv.make_csvs(input_zip=input_zip, output_dir=output_dir, languages=languages)
end
