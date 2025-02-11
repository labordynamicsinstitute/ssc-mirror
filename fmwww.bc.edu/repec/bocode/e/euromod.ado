/*#####################################################
#  Version 1.0.4
#  Author: Hannes Serruys
#  Last updated: 12/12/2024
%  Corresponding: EUROMOD version 3.7.10
#####################################################*/
global EUROMOD_CONNECTOR_VERSION = "3.7.10"
qui set linesize 255

capture mata: mata drop *get_latest_version()
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
if "$EUROMOD_PATH" == "" {
	global EUROMOD_PATH = "C:/Program Files/EUROMOD/Executable"
}
if "`latest_version'" != "" {
	global EUROMOD_PATH = "$EUROMOD_PATH/`latest_version'"
}
quietly adopath + "$EUROMOD_PATH"
capture confirm file "${EUROMOD_PATH}/stataplugin.plugin"

// Check the return code to determine if the file exists
if _rc != 0 {
	display as error "Expected to find a stataplugin on the path: ${EUROMOD_PATH}. Make sure to have downloaded the latest version of EUROMOD. (minimum version $EUROMOD_CONNECTOR_VERSION )"
	exit _rc
}
program define euromod
	
	version 15.1
	
    gettoken first rest : 0, parse(", ")
       if "`first'" == "run" {
			local subcommand = "euromod_run"
	   } 
	   else if "`first'" == "getdata" {
			local subcommand = "getdata"
	   }
	   else if "`first'" == "getinfo" {
			local subcommand = "euromod_getinfo"
	   }
	   else if "`first'" == "setinfo" {
			local subcommand = "`euromod_setinfo'"
	   }
	   else {
			di as err "No valid subcommand specified."
			error `-1'
	   }
       `subcommand'`rest'
end
