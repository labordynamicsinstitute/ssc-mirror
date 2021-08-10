*! 6apr2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program emiss, rclass 
version 11.1
mata:DoIt()
end

version 11.1
mata:
void DoIt() { //>>def func<<
	class dataset scalar ds
	class tabel scalar t
	
	ds.readmem()
	syntaxl(st_local("0"),&(vars="anything"),(&(mvlist="mv:list="),&(omit="o:mit"),&(out="out=")))
	vars=ds.varlist(vars,"all")
	vars=select(vars,ds.sirtypes[vars]:!="s")
	body=J(length(vars),27,0)
	st_view(V=.,.,vars)
	misses=select((.,.a,.b,.c,.d,.e,.f,.g,.h,.i,.j,.k,.l,.m,.n,.o,.p,.q,.r,.s,.t,.u,.v,.w,.x,.y,.z), asvmatch((".",columnize(char(97..122),"")),firstof(mvlist\"*")))
	for (v=1;v<=length(vars);v++) {
		for (m=1;m<=length(misses);m++) {
			if (anyof(V[,v],misses[m])) body[v,m]=1
			}
		}
	if (!any(body)) printf("No missing values")
	else {
		found=toindices(colmax(body))
		head=subinstr(strofreal(misses[found]),".","")
		if (head[1]=="") head[1]="."
		tbod=ds.vnames[vars]',body[,found]:*head
		if (omit) tbod=select(tbod,rowmax(body))
		t.body=("",head\tbod)
		t.head=1
		t.stub=1
		t.altrows=1
		t.set(t._hline,rangel(5,length(vars),5),.,t.Lmajor)
		t.set(t._vline,.,.,t.Lsp1)
		t.present(out)
		}
	}
end

