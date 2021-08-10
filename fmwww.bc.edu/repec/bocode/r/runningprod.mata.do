// Running Product 
// Author: Federico Belotti & Silvio Daidone
// Tor Vergata University - Faculty of Economics
// version 1.1 04/05/2010

version 10
capture mata:  mata drop runningprod()
mata

numeric vector runningprod(numeric vector vec, | real scalar missing)
{
	numeric vector rp 
	real scalar i
	
	if (missing == .) tmp = vec
	else              tmp = editmissing(vec, missing)
	rp = tmp
	
	for (i=2; i <= length(vec); i++)  {
		rp[i] = rp[i-1] * tmp[i] 
	}
	return(rp)
}

mata mosave runningprod(), dir(PERSONAL) replace

end



