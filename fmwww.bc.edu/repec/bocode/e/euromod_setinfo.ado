/*#####################################################
#  Version 1.0.4
#  Author: Hannes Serruys
#  Last updated: 12/12/2024
#####################################################*/

if "$EUROMOD_PATH" == "" {
	global EUROMOD_PATH = "C:/Program Files/EUROMOD/Executable"
}
capture mata: mata drop get_latest_version()
mata: 
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

capture program EM_StataPlugin, plugin using ("$EUROMOD_PATH/StataPlugin.plugin")
capture program drop euromod_setinfo
program define euromod_setinfo, rclass
	syntax , model(string) country(string) system(string) parId(string) newParValue(string)
	if "`system'" != "" & "`country'" == "" {
			di in r "Need country argument in order to identify system."
			error -1
	}
	if "`parId'" != "" & "`system'" == "" {
		di in r "Need system argument in order to identify parameter."
		error -1
	}
	if "`parId'" != "" & "`newParValue'" == "" {
		di in r "Need parId argument in order to identify parameter."
		error -1
	}
	di "`newParValue'"
	if "`parId'" != "" { 
		capture plugin call EM_StataPlugin, "setXmlInfoPar" "`model'" "`country'" "`system'" "`parId'" "`newParValue'"
		di in r "`errorMessageEM'"
		if _rc != 0 {
			qui cd "`wd'"
		}
		
	}
	else{
		exit
	}

	// Setting return List Macros
	plugin call EM_StataPlugin, "setReturnList"
	foreach local_connector in `return_list_locals_connector' {
		return local `local_connector' "`rlm`local_connector''"
	}
end