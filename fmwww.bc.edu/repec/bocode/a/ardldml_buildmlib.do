*! ardldml_buildmlib.do  1.0.0  24aug2026
*! Compile ardldml.mata into lardldml.mlib
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
*  Run from the package folder:   do ardldml_buildmlib.do
*
*  Why a library rather than a mata block inside the ado: Mata functions
*  defined in an ado file's trailing mata block belong to that ado and are
*  dropped from memory whenever Stata unloads it. ardldml_estat.ado and
*  ardldml_p.ado call the engine too, so it has to outlive any one ado.

version 14.0
clear

capture mata: mata drop ardldml_*()
capture erase lardldml.mlib

do ardldml.mata

mata:
mata mlib create lardldml, dir(.) replace
mata mlib add lardldml ardldml_*()
mata mlib index
end

di as result "built lardldml.mlib"
mata: mata describe using lardldml
