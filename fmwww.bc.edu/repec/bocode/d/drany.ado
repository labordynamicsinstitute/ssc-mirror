*! 5dec2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program drany
version 11

mata: DoIt()
end

version 11
mata:

void DoIt() { //>>def func<<
	syntaxl(st_local("0"),(&(todrop="anything"),&(ifin="ifin")),&(clr="cl:ear+"))
	if (truish(todrop)&truish(ifin)) errel("Either variables or other conditions can be specified, not both.")
	
	if (truish(todrop)) {
		todrop=varlist(todrop,"nfrep")
		st_dropvar(todrop)
		}
	if (truish(ifin)) {
		settouse(touse,ifin)
		stata(sprintf("drop if %s",touse))
		}
	truish(clr)
	if (truish(clr)) cmdvars("",tokel(*clr))
	}
end
