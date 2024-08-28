/*----------------------------------------------------------------------------------
  opendf_installpython.ado: for windows users: copies python to the Stata ado folder or a specified location. Default is version 3.12.
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
*! opendf_installpython.ado: for windows users: copies python to the Stata ado folder or a specified location. Default is version 3.12.
*! version 2.0.0 - 27 August 2024 - SSC Initial Release


program define opendf_installpython 
	version 16
	syntax, [VERSION(string) LOCATION(string)]
	*Returns error of we are not in wondows and exit
	if (c(os) != "Windows"){
	  di as error "The command {it:opendf installpython} is only working for Windows. To install python manually for your operating system go to:"
		di as error `"{Stata "view browse https://www.python.org/downloads/":https://www.python.org/downloads/}"'
		exit
	}
	
	if (`"`version'"' == "") {
		local _py_version= "3.12"
	}
	else {
		local _py_version="`version'"
	}
	
	local _wd "`c(pwd)'"
	if (`"`location'"' == "") {
		local _path_to_python "`c(sysdir_plus)'python`_py_version'"
	} 
	else {
	    local _path_to_python "`location'/python`_py_version'"
	}
	*download link from website
	local _download_link https://www.python.org/ftp/python/`_py_version'.0/python-`_py_version'.0-embed-amd64.zip
	capture qui mkdir "`_path_to_python'"
	qui local _path_to_python "subinstr("`_path_to_python'", "/", "\", .)"
	qui local _path_to_python: di `_path_to_python'
	qui copy `_download_link' "`_path_to_python'\python`_py_version'.zip", replace
	qui cd `_path_to_python'
	qui unzipfile "`_path_to_python'\python`_py_version'.zip"
	qui erase "`_path_to_python'\python`_py_version'.zip"
    *Message to print if epython is working now
    capture set python_exec `_path_to_python'\python.exe
    capture qui python: print()
    if (_rc==0){
        noisily di "Python sucessfully installed."
        noisily di "python.exe located at {it:`_path_to_python'\python.exe} "
        noisily di "To activate the python version manually execute: {it:set python_exec `_path_to_python'\python.exe}"
    }
    *restore working directory
	qui cd "`_wd'"
end
