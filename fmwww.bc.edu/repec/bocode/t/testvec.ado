*! testvec CFBaum  12may2017
/*

testvec places the coefficients of the cointegrating vector(s) and their 
VCE into the ereturns, so that standard test, testparm, lincom commands
may be used. If there is more than one cointegrating vector, the coefficient
names should be prefixed with [_ce1], [_ce2], etc.

e.g.  
webuse urates
vec missouri indiana kentucky illinois arkansas,  rank(2)
test [_ce2]illinois = [_ce2]kentucky 
lincom [_ce1]kentucky + [_ce1]illinois + [_ce1]arkansas
*/

prog testvec, eclass
version 12
syntax [,PRINT]
tempname beta veebeta
if "`e(cmd)'" != "vec" {
	di as err "testvec can only be used after vec."
    error 198
    exit
}
loc cenames `e(cenames)'
mat `beta' = e(beta)
mat `veebeta' = e(V_beta)
eret post `beta' `veebeta'
eret local eqnames `cenames'
di _n "You can now use test, testparm, lincom on the cointegrating vectors (`cenames')."
if "`print'" == "print" {
	matlist e(b)
	matlist e(V)
}
end
