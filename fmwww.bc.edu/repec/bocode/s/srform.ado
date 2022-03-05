*! 	srform.ado	Version 2.1 	RL Kaufman  7/23/2018
***		1.0 Formats cells for significance region table for Results Window and to Save in Excel
***			Called by SIGREG.ADO. Returns val and format for printf r(val) r(fmt) and for putexcel r(xval) r(xfmt)
***			MATB & MATP are matrices of moderated coefficient values and hier p-levels, PSIG is sig level
***			R&C index cell in MATB & MATP, NDIG = # of display digits.
***		2.0	Corrected highlighting of factor change effects "posiitve" >=1, "negative" < 1
***		2.1 Cha ged fill pattern in EXcel table to be consistent with book
program srform, rclass
version 14.2
syntax , matb(name) matp(name) psig(real) r(integer) c(integer) ndig(integer) coeftype(string)
loc xval = el(`matb',`r',`c')
loc sig = el(`matp',`r',`c')
loc val=strofreal(`xval',"%9.`ndig'f")
loc nf "#."
forvalues i=1/`ndig' {
	loc nf "`nf'0"
}
loc nf = "`nf'" + `"`last'"'
if "`coeftype'" != "factor" {
	if `xval' >= 0 & `sig' < `psig' { 
		loc  xfmt  `"nform(`nf'"*") bold fpat(solid,"140 140 140")"'
		loc fmt = "{bf}%10s{sf}{c 42}"
		}
	if `xval' >= 0 & `sig' >= `psig' {
		loc  xfmt  "nform(`nf'_*)"  
		loc fmt = "{sf}%10s{c 32}"
		}
	if `xval' < 0 & `sig' < `psig' {
		loc  xfmt `"nform(`nf'"*") bold italic fpat(solid,"210 210 210")"'
		loc fmt = "{it}%10s{sf}{c 42}"
		}
	if `xval' < 0 & `sig' >= `psig' {
		loc  xfmt  "nform(`nf'_*) italic"
		loc fmt = "{it}%10s{sf}{c 32}"
		}
}
***** factor change effects
if "`coeftype'" == "factor" {
	if `xval' >= 1 & `sig' < `psig' { 
		loc  xfmt  `"nform(`nf'"*") bold fpat(solid,"140 140 140")"'
		loc fmt = "{bf}%10s{sf}{c 42}"
		}
	if `xval' >= 1 & `sig' >= `psig' {
		loc  xfmt  "nform(`nf'_*)"  
		loc fmt = "{sf}%10s{c 32}"
		}
	if `xval' < 1 & `sig' < `psig' {
		loc  xfmt "nform(`nf'"*") bold italic fpat(solid,"210 210 210")"
		loc fmt = "{it}%10s{sf}{c 42}"
		}
	if `xval' < 1 & `sig' >= `psig' {
		loc  xfmt  "nform(`nf'_*) italic"
		loc fmt = "{it}%10s{sf}{c 32}"
		}
}
******
return sca xval = `xval'
return loc xfmt = `"`xfmt'"'
return loc val =  "`val'"
return loc fmt =  "`fmt'"
end
