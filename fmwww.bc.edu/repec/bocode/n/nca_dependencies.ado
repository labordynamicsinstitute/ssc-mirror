pro def nca_dependencies
syntax 
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
cap which rowsort
if _rc {
	di "{bf: rowsort} package not found. Installing dependency..."
	ssc install rowsort
}
cap findfile moremata.hlp
if _rc {
	//di as error "{bf: moremata} package not found please execute {bf: ssc install moremata} to install it or search it using {bf: net search}"
	di "{bf: moremata} package not found. Installing dependency..."
	ssc install moremata
}
end
