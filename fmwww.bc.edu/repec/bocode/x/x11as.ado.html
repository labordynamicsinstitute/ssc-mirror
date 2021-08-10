!* x11as  Set up X13as spc file, execute, and return single SA series
!* v1.0.0 cfb 21aug2016
!* v1.0.1 cfb 23aug2016 Linux support
prog drop _all
mata: mata clear
prog def x11as, rclass
version 13
syntax varlist(max=1 numeric) [if] [in] [, DOUBLE]

// validate OS
if "$S_OS" != "MacOSX" & "$S_OS" != "Unix" {
	di as err "Only Mac OSX and Linux are supported."
	error 198
}

// verify data are tsset to Q or M
capt tsset
if _rc != 0 {
	di as err "Data must be tsset"
	error 198
}
if r(unit1) != "q" & r(unit1) != "m" {
	di as err "Only available for Q or M frequencies"
	error 198
}
if r(unit1) == "q" {
	loc nper 4
	loc tfmt %tq
	loc fn qofd(dofq(
}
else if r(unit1) == "m" {
	loc nper 12
	loc tfmt %tm
	loc fn mofd(dofm(
}

tempvar touse
// disable for now  
// tempname fspc

marksample touse
qui count if `touse'
loc en  = r(N)
if r(N) == 0 {
	di as err "No observations"
	error 198
}
loc maxobs 1020
if r(N) > `maxobs' {
	di as err "Current maximum observations = `maxobs'"
	error 198
}

// get start period; could also use this to fill in span from touse
qui tsset
qui su `r(timevar)' if `touse', f
loc sper = string(r(min),"`tfmt'")
loc sper = subinstr("`sper'","q",".",.)
loc sper = subinstr("`sper'","m",".",.)

loc vn: word 1 of `varlist'
loc fspc "`vn'.spc" 
loc fd11 "`vn'.d11"
confirm new var `vn'_as
qui g `double' `vn'_as = .
loc newlist `vn'_as

// generate the spc file
mata: _x11as_w("`vn'","`touse'","`fspc'","`nper'","`sper'")

// reference executable in PLUS/x/
loc xec `"`c(sysdir_plus)'x/x13as"'
loc xec = subinstr("`xec'","Application","Application\",1)
// di "`xec'"
!chmod a+x `xec'
!`xec' `vn'


// read the d11 file into a Stata variable
mata: _x11as_r("`newlist'","`touse'","`fd11'",`en')

end

version 13
mata:
void function _x11as_w(string scalar varlist,
					string scalar touse,
					string scalar fspc,
					string scalar nper,
					string scalar sper)
{
	st_view(X=.,.,varlist,touse)

// should use fileexists() to require replace
	unlink(fspc)
	fh = fopen(fspc,"w")
	line = "series { title = " + char(34) + varlist + char(34)
	fput(fh, line)
	fput(fh, "start = " + sper)
	fput(fh, "period = " + nper)
	fput(fh, "data = (")
	for(i=1;i<=rows(X);i++) {
		fput(fh,strofreal(X[i]))
	}
	fput(fh, ") }")
	fput(fh, "x11{save=d11}")
	fclose(fh)
}

void function _x11as_r(string scalar newlist,
					   string scalar touse,
					   string scalar fd11,
					   real scalar en)
{
	st_view(Z=.,.,newlist,touse)
	fh = fopen(fd11, "r")
// snarf two header lines
	line = fget(fh)
	line = fget(fh)
	i=0
	while ((line=fget(fh))!=J(0,0,"")) {
//		printf("%s\n", line)
		i++
		Z[i,1] = strtoreal(substr(line, 8))
    }
    fclose(fh)
}
	
end

