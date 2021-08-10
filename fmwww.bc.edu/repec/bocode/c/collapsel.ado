*! 5mar2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program collapsel
version 11
mata: DoIt()
end

version 11
mata:
void DoIt() { //>>def func<<
	class statgrid scalar sg
	
	syntaxl(st_local("0"),(&(explist="anything"),&(ifin="ifin")),(&(by="by=*"),&(noby="noby")))
	if (noby) by=by,""
	
	sg.defaults="Nobs() Nobs(,%) Mean()"
	sg.by(by)
	sg.setup(explist,ifin)
	sg.dseval()
	for (k=1;k<=sg.k_n;k++) {
		if (sg.ds.nlabels[sg.b_n+k]=="@") {
			if (truish(sg.k_vars[k])) sg.ds.nlabels[sg.b_n+k]=charget(sg.k_vars[k],"@nlab")
			else sg.ds.nlabels[sg.b_n+k]=sg.e_exp[k]
			}
		}
	sg.ds.chars=J(0,3,"") //kluge! not sure where chars are getting filled
	sg.ds.writemem()
	}

end
