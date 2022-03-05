*!  plotcomb.ado 	Version 1.1		RL Kaufman 	10/11/2017

***  	1.0 Combine plots.  Called by EFFDISP.
***		1.1 Draw plots in multiptlles of 2 or 3
program plotcomb, rclass
version 14.2
syntax  , grphcomb(string) title(string asis) grname(string) legend(string asis) plttype(string)

loc ng: list sizeof grphcomb
loc ndone = 0
loc paneltxt ""
loc gnmtxt ""
loc ndrw = 2	
	loc ysz = 5.2
	loc xsz = 8
if `ng' <3 loc ndrw = `ng'
if mod(`ng',3) == 0 {
	loc ndrw = 3
	loc ysz = 5.2
	loc xsz = 12
}
while `ng' > 0 {
	if ${pannum$sfx} > 0 { 
		loc paneltxt "(Panel ${pannum$sfx})"
		loc gnmtxt "Pan_${pannum$sfx}"	
	}
	if `ng' ==1 {
		loc  ndrw=1
		loc ysz = 5.2
		loc xsz = 4
	}
	loc ng = `ng' - `ndrw'
	loc grphdrw ""
	forvalues j=1/`ndrw' {
		loc gg: word `=`j' + `ndone'' of `grphcomb'
		loc grphdrw "`grphdrw' `gg'"
	}
	if "`plttype'" != "contour" {
		graph combine `grphdrw' , ysize(`ysz') xsize(`xsz') rows(1) iscale(*1.4) graphreg(fc(white)) name(`grname'`gnmtxt', replace) ///
			title("`title'. `paneltxt'", size(*.8) m(b+2)) ///
			graphreg(fc(white) style(none)) ///
			cap(`legend' , pos(6) linegap(*1) j(left) alignment(bottom)  ///
			margin(t+1 b+1) fc(white) bmargin(t+2) box size(*.8)) imargin(0 0 0 0)
	}
	if "`plttype'" == "contour" {
		graph combine `grphdrw' , ysize(`=5.2*`ndrw'') xsize(6) cols(1) iscale(*1.4) graphreg(fc(white)) name(`grname'`gnmtxt', replace) ///
			title("`title'. `paneltxt'", size(*.7) m(b+2)) ///
			graphreg(fc(white) style(none))
	}
	loc ndone = `ndone' + `ndrw'
	if `ng' > 0 glo pannum$sfx = ${pannum$sfx} + 1
}
end
