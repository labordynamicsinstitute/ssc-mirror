*! 	rcform.ado	Version 1.0 	RL Kaufman		10/4/2016

***		1.0 Formats row and col label string in NMLIST as string for significance region table for Results Window and to Save in Excel
***			Called by SIGREG.ADO. Returns r(nmstr) with centered within fields of length. 

program rcform, rclass
version 14.2
syntax , nmlist(string) nmsz(integer) len(integer)
loc nmstr ""
forvalues i=1/`nmsz' {
	loc nmi: word `i' of `nmlist'
	ctrstr , instr(`nmi') length(`len')
	loc nmstr "`nmstr' `r(padded)'"
}
return loc nmstr="`nmstr'"
end
