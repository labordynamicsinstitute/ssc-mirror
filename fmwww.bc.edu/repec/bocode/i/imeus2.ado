*! imeus2  1.0.0  CFBaum  24jul2026
*! Install ucommunity-contributed routines referenced in IMEUS2 examples
program define imeus2
version 14
local pkglist estout ivendog ivreg2 makematrix  mvcorr mvsumm nnest outtable overid rollreg semean statsmat tsmktim tsspell whitetst xtabond2 ranktest
foreach p of local pkglist { 
    display " Installing `p' from SSC..."
    ssc install `p', replace
}
display _n "All packages referenced in IMEUS2 examples successfully installed..."
display _n "Use the adoupdate command to ensure that these routines remain up to date."
end
