*! nca v1.1 04/22/2025
program define nca, eclass
syntax [anything] [if] [in] [, *]
version 15
//checking dependencies
cap which grc1leg
if _rc {
	//di as error "{bf: grc1leg} package not found please execute {bf: net install grc1leg,from( http://www.stata.com/users/vwiggins/)} to install it or search it using {bf: net search}"
	di "{bf: grc1leg} package not found. Installing dependency..."
	net install grc1leg,from( http://www.stata.com/users/vwiggins/)
}
cap which submatrix
if _rc {
	di "{bf: submatrix} package not found. Installing dependency..."
	ssc install submatrix
}
cap findfile moremata.hlp
if _rc {
	//di as error "{bf: moremata} package not found please execute {bf: ssc install moremata} to install it or search it using {bf: net search}"
	di "{bf: moremata} package not found. Installing dependency..."
	ssc install moremata
}
if !replay() {
	nca_estimate `0' 
	if (e(testrep)>0)  nca_perm,reps(`e(testrep)')
}
else { // replay
	if "`e(cmd)'"!="nca" error 301
}
ereturn hidden local est_cmd=	"nca_estimate `0' "
nca_display, `options' 
end

