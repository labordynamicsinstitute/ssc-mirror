*! 17mar2010 
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program hs 
version 11 
syntax anything, [Mark(string)] 
 
local subbed=subinstr(strtrim("`anything'")," ","_",.)

capture find_hlp_file `subbed'
if (_rc==111) capture find_hlp_file mf_`subbed'
if (_rc==111) mata: errel("help for `anything' not found")

*h `r(result)', name(help_viewer) mark(`mark') //name options is not working - first window opens as #1, second with name
h `r(result)', mark(`mark') nonew
*window manage forward command
end
 
