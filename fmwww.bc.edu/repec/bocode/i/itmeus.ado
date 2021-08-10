*! itmeus  1.0.2  CFBaum  23feb2009
*  Install user-written routines referenced in ITMEUS examples
*  created  7 Jul 2006 13:55:04
*  updated 16 Apr 2007 to add margeff
*  updated 23 feb 2009 to add ranktest (requires Stata 9.2, needed by current ivreg2)
program define itmeus
version 8.2
local pkglist estout ivendog ivreg2 makematrix margeff mvcorr mvsumm nnest outtable overid rollreg semean statsmat tsmktim tsspell whitetst xtabond2 ranktest
foreach p of local pkglist { 
    display " Installing `p' from SSC..."
    ssc install `p', replace
}
display _n "All packages referenced in ITMEUS examples successfully installed..."
display _n "In Stata 9, you may use the adoupdate command to ensure"
display "that these routines remain up to date."
end
