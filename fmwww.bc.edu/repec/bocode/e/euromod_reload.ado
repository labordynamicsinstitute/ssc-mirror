global EUROMOD_COMMAND_VERSION = "1.1.2"
// Minimum EUROMOD software version these commands require (keep in sync with euromod.ado).
global EUROMOD_CONNECTOR_VERSION = "3.7.10"
/*#####################################################
#  Version 1.1.2
#  Author: Hannes Serruys
#  Last updated: 11/30/2025
#####################################################*/
if "$EUROMOD_PATH" == "" {
	global EUROMOD_PATH = "C:/Program Files/EUROMOD/Executable"
}

capture program EM_StataPlugin, plugin using ("$EUROMOD_PATH/StataPlugin.plugin")
program define euromod_reload
	// change working directory to path for plugin for plugin to function correctly. Problem with linking of CLR library with stata plugin, because lib file needs to be in the working directory.
    version 15.1
	syntax, MODel(string) 
	plugin call EM_StataPlugin, "reload"  "`model'"
end
