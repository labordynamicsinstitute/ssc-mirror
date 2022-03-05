*! intspec.ado	Version 2.2		RL Kaufman	02/10/2019

***	 	2.0 added functionality for mlogit.
***		2.1 set matsize to 676 if max_matsize >= 676, needed for plotting and saving plotdata
***		2.2 fixed problem of glob sfx2 containing "~"
***		2.3 fixed problem of glob sfx2 containing "_" or other non alphanumeric characters


***  Check then Save interaction specifcation for re-use

program intspec, rclass
version 14.2
args trash
tempname estint

*** PRESERVE DATA & CURRENT ESTIMATES ON EXIT

preserve

est store `estint' 

*** Clear previous $sfx2 globals if exist
loc sfx11 "`=abbrev("x`c(username)'",10)'icalc"
glob sfx2 "`=subinstr("`=strtoname("`sfx11'",0)'","_","x",.)'"

glob sfx2  =subinstr("$sfx2","~","",.)

loc mygloblist:  all globals "*$sfx2"
if "`mygloblist'" != "" mac drop `mygloblist'

glob eqnum$sfx2 = 1
loc addeqn ""

glob eqbase$sfx2 "1"
glob eqlist$sfx2 "1"
glob eqnum$sfx2 =1
glob eqnumlist$sfx2 "1"
glob ordcatnum$sfx2 ""

if inlist("`e(cmd)'","mlogit","ologit","oprobit") == 1  & strmatch("`0'","*eqn*") == 0 {
	glob eqbase$sfx2 "`e(baselab)'"
	if "`e(baselab)'" == "" glob eqbase$sfx2 "`e(k_eq_base)'"
	glob eqlist$sfx2 "`e(eqnames)'"
	glob eqnum$sfx2 : list sizeof global(eqlist$sfx2)
	qui levelsof `e(depvar)' , loc(enum)
	glob eqnumlist$sfx2 "`enum'"
	if "`e(cmd)'" != "mlogit" { 
		loc labnm : val lab `e(depvar)'
		loc basen: word 1 of `enum'
		loc valnm: label `labnm' `basen'
		glob eqbase$sfx2 = subinstr("`valnm'"," ","_",4)
		glob eqlist$sfx2 ""
		foreach  num in `enum' {
			loc valnm: label `labnm' `num'
			glob eqlist$sfx2 "${eqlist$sfx2} `=subinstr("`valnm'"," ","_",4)'"
		}
		glob ordcatnum$sfx2 : list sizeof global(eqlist$sfx2)
		glob eqnum$sfx2 =1 
	}
}
loc ee = ${eqnum$sfx2}
forvalues i=1/`ee' {
	if `ee' > 1 & "`e(cmd)'" != "ologit" & "`e(cmd)'" != "oprobit'" {	
	loc ename: word `i' of ${eqlist$sfx2} 
	if "${eqbase$sfx2}" == "`ename'" {
		loc ename: word `=`i'+1' of ${eqlist$sfx2} 
		if `i' !=1 	loc ename: word `=`i'-1' of ${eqlist$sfx2} 
	}	
	loc addeqn "eqn(`ename')"
	}
	
	global intspec$sfx2 "`0' `addeqn' "
	definefm , ${intspec$sfx2} eqnow(`i') cmdnm(`e(cmd)')
	loc mygloblist:  all globals "*$sfx"
	loc gstp: list sizeof mygloblist
	qui {
		file open globsave using `c(tmpdir)'/globsaveeq`i'$sfx2.do , write replace text
		forvalues i=1/`gstp' {
			loc gg: word `i' of `mygloblist'
		file write globsave `"glob `gg'  "$`gg'""' _n
		}
		file write globsave "gen esamp$sfx = e(sample)" _n
		file close globsave
	}
mac drop `mygloblist'
}
qui est restore `estint'

** set matsize if < 676 needed for plotting and saving plotdata
if `c(max_matsize)' < 676 noi disp in red "warning: maximum matsize (`c(max_matsize)') < minimum needed (676) for saving plot data.  May cause errors."
if `c(matsize)' < 676 & `c(max_matsize)' > 675 set matsize 676

end
