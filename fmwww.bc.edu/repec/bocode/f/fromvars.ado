*!9jan2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program fromvars
version 11

mata: DoIt()
end


version 11
mata:
void DoIt() { //>>def func<<
	class statgrid scalar sg
	
	syntaxl(st_local("0"),(&(from="anything"),&(ifin="ifin")),&(those="!th:oseforwhich="))
	
	exp=concat(varlist(from,"nfrep")," ")+":"+those
	sg.setup(exp,ifin)
	sg.dseval()
	vars=concat(select(sg.ds.vnames,sg.ds.getdat(.,.))," ")
	st_rclear()
	st_global("r(varlist)",vars)
	printf(vars)
	}
end
	