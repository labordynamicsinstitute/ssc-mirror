*! imeus2  1.0.1  CFBaum  26jul2026
*! Install community-contributed routines referenced in IMEUS2 examples
program define imeus2
version 14
local pkglist estout ivendog ivreg2 ivreg2h makematrix  mvcorr mvsumm nnest outtable overid ranktest rollreg semean statsmat tsmktim tsspell whitetst xtabond2 
foreach p of local pkglist { 
    display " Installing `p' from SSC..."
    ssc install `p', replace
}
display _n "All packages referenced in IMEUS2 examples successfully installed..."
display _n "Use the adoupdate command to ensure that these routines remain up to date."
end
