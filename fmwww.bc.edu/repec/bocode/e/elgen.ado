*! 22dec2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program elgen, sortpreserve
version 11

mata: DoIt()
end

version 11
mata:

void DoIt() { //>>def func
	class statgrid scalar sg
	
	syntaxl(st_local("0"),(&(explist="!anything"),&(ifin="ifin")),&(by="by="))
	
	last=st_varname(st_nvar())
	sg.by(by)
	sg.setup(explist,ifin,"newvars")
	sg.eval(sg.by_vars)
	
	order=""
	for (k=1;k<=sg.k_n;k++) {
		d=k+sg.b_n
		order=order+" "+sg.ds.vnames[d]
		if (truish(_st_varindex(sg.e_tmp[k]))) st_varrename(sg.e_tmp[k],sg.ds.vnames[d])
		else {
			if (sg.ee_str[k]) stata(sprintf(`"qui gen str1 %s="""',sg.ds.vnames[d]))
			else stata(sprintf("qui gen byte %s=.",sg.ds.vnames[d]))
			for (g=1;g<=rows(sg.gixs);g++) el_store(sg.gixs[g,],sg.ds.vnames[d],J(sg.gixs[g,2]-sg.gixs[g,1]+1,1, (*sg.ee_scalars[k])[g]))
			}
		if (charget(sg.ds.vnames[d],"@nlab")=="@") charset(sg.ds.vnames[d],"@nlab",sg.e_exp[k]+adorn(" by(",concat(sg.by_vars," "),")"))
		charset(sg.ds.vnames[d],"@form",sg.ds.formats[d])
		charset(sg.ds.vnames[d],"@vlab",sg.ds.vlabrefs[d])
		}
	stata(sprintf("order %s, after(%s)",order,last))
	}

end

