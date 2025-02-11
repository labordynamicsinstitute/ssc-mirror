/*#####################################################
#  Version 1.0.2
#  Author: Hannes Serruys
#  Last updated: 12/12/2024
#####################################################*/

if "$EUROMOD_PATH" == "" {
	global EUROMOD_PATH = "C:/Program Files/EUROMOD/Executable"
}
capture mata: mata drop get_latest_version()
capture mata: 
	void get_latest_version(string dirPath)
	{
		real col, row
		string matrix dirList

		// Get the list of directories and files
		dirList = sort(dir(dirPath,"dirs","v*.*.*"),1)
		if (rows(dirList) > 0) {
			st_local("latest_version",dirList[rows(dirList)])
		}
	}

end
mata: get_latest_version("$EUROMOD_PATH")
if "`latest_version'" != "" {
	global EUROMOD_PATH = "$EUROMOD_PATH/`latest_version'"
}
local wd = c(pwd)
cd "$EUROMOD_PATH"
capture program EM_StataPlugin, plugin using ("$EUROMOD_PATH/StataPlugin.plugin")
capture program drop euromod_getinfo
quietly cd "`wd'"
program define euromod_getinfo, rclass
	local wd = c(pwd)
	syntax , model(string) [country(string) system(string) parId(string) all dataset(string) extension(string) switchvalue]
	if "`system'" != "" & "`country'" == "" {
			di in r "Need country argument in order to identify system."
			error -1
	}
	if "`parId'" != "" & "`system'" == "" {
		di in r "Need system argument in order to identify parameter."
		error -1
	}
	//Using option all, all possible information is returned, otherwise the most specific information is returned
	if "`all'" == "all" {
		plugin call EM_StataPlugin, "xmlInfo" "`model'"
		if  "`country'" != "" {
			//getting country specific information
			capture noisily plugin call EM_StataPlugin, "setIterators" "`model'" "`country'"
			di in r "`errorMessageEM'"
			if (_rc != 0) {
				quietly cd "`wd'"
				error -1
				exit
			}
			capture noisily plugin call EM_StataPlugin, "xmlInfoCountry" "`model'" "`country'"
			di in r "`errorMessageEM'"
			if (_rc != 0) {
				quietly cd "`wd'"
				error -1
				exit
			}
		}
		
		//get system specific information if specified
		if  "`system'" != "" {
			//getting system specific information
			capture noisily plugin call EM_StataPlugin, "xmlInfoSystem" "`model'" "`country'" "`system'"
			di in r "`errorMessageEM'"
			if (_rc != 0) {
				quietly cd "`wd'"
				error -1
				exit
			}
		}
		
		if parId != "" { 
			capture noisily plugin call EM_StataPlugin, "xmlInfoSystem" "`model'" "`country'" "`system'" "`parId'"
			di in r "`errorMessageEM'"
			if (_rc != 0) {
				quietly cd "`wd'"
				error -1
				exit
			}
		}
	}
	else {
		if "`parId'" != "" { 
			capture noisily plugin call EM_StataPlugin, "xmlInfoPar" "`model'" "`country'" "`system'" "`parId'"
			di in r "`errorMessageEM'"
			if (_rc != 0) {
				quietly cd "`wd'"
				error -1
				exit
			}
		}
		else if "`switchvalue'" != "" {
			if "`extension'" == "" | "`dataset'" == "" | "`system'" == "" { 
				di "extension, dataset and system are non-optional when retrieving the value of a switch."
			}
			capture noisily plugin call EM_StataPlugin, "getExtensionSwitchValue" "`model'" "`country'" "`system'" "`dataset'" "`extension'"
			if (_rc != 0) {
				quietly cd "`wd'"
				error -1
				exit
			}
		}
		else if "`dataset'" != "" {
			capture noisily plugin call EM_StataPlugin, "xmlInfoDataset" "`model'" "`country'" "`dataset'"
			di in r "`errorMessageEM'"
			if (_rc != 0) {
				quietly cd "`wd'"
				error -1
				exit
			}
		}
		else if "`system'" != "" {
			capture noisily plugin call EM_StataPlugin, "xmlInfoSystem" "`model'" "`country'" "`system'"
			if (_rc != 0) {
				quietly cd "`wd'"
				error -1
				exit
			}
		}
		else if "`country'" !=  "" {
			capture noisily plugin call EM_StataPlugin, "xmlInfoCountry" "`model'" "`country'"
			di in r "`errorMessageEM'"
			if (_rc != 0) {
				quietly cd "`wd'"
				error -1
				exit
			}
			capture noisily plugin call EM_StataPlugin, "setIterators" "`model'" "`country'"
			di in r "`errorMessageEM'"
			if (_rc != 0) {
				quietly cd "`wd'"
				error -1
				exit
			}
		} 
		else {
			capture noisily plugin call EM_StataPlugin, "xmlInfo" "`model'"
			di in r "`errorMessageEM'"
			if (_rc != 0) {
				quietly cd "`wd'"
				error -1
				exit
			}
		}
		
	}
	
	
	// Setting return List Macros
	plugin call EM_StataPlugin, "setReturnList"
	foreach local_connector in `return_list_locals_connector' {
		return local `local_connector' "`rlm`local_connector''"
	}
	quietly cd "`wd'"
end