*! 19mar2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program nmiss 
version 11.1

mata:DoIt()
end


version 11.1
mata:
void DoIt() {
	class tspoof scalar t
	
	syntaxl(st_local("0"),(&(vars="anything"),&(ifin="ifin")), (&(nlab="nl:abels="),&(out="out=")))
	settouse(touse,ifin)
	t.labset("n",1,nlab)
	
	vars=varlist(vars,"all")
	if (truish(touse)) {
		st_view(V,.,touse)
		nobs=sum(V)
		}
	else nobs=st_nobs()
	themiss=J(nobs,length(vars),0)
	for (c=1;c<=cols(themiss);c++) {
		if (st_vartype(vars[c])=="strL") printf("{res:%s} {txt:is strL; it will be skipped}\n",vars[c]) //it needs to be DROPPED!
		else {
			el_view(V,.,vars[c],touse)
			themiss[,c]=!tru2(V,"z")
			}
		}
	if (sum(themiss)==0) {
		printf("{txt}None missing")
		return
		}
	mcix=toindices(colsum(themiss))
	mcl=length(mcix)-1
	
	tmiss=colsum(themiss)'
	tmiss=tmiss,J(rows(tmiss),2,.)
	tmiss[,2]=round(100*tmiss[,1]/nobs)
	for (r=1;r<=length(mcix);r++) {
		rc=rowsum(themiss[,mcix[r]])
		mrix=toindices(rc)
		tmiss[mcix[r],3]=round(100*(sum(themiss[mrix,mcix])-sum(rc))/(length(mrix)*mcl),1)
		}
	t.body=J(1,t.nl_n,"Variables"),"Observations","","Other Data"\J(1,t.nl_n,""),"# Miss","% Miss","% Miss"\t.getn(vars'),strofreal(tmiss,"%12.0fc")
	t.o_parse(out)
	t.head=2
	t.stub=t.nl_n
	t.altrows=1
	t.set(t._span,1,t.nl_n==2?(1,3):2,2)
	t.set(t._vline,.,t.nl_n+2,t.Lmajor)
	t.render()
	
	rowmiss = sort(rowsum(themiss),1)
	//should use (write) a generic version based in freq.mata
	tmiss=uniqrows(rowmiss)
	tmiss=tmiss,J(rows(tmiss),5,0)
	tmiss[,5]=round(100*tmiss[,1]/cols(themiss),1)
	i=1;tmiss[1,2]=1
	for (r=2;r<=rows(rowmiss);r++) {
		i=i+(rowmiss[r]!=rowmiss[r-1])
		tmiss[i,2]=tmiss[i,2]+1
		}
	tmiss[,3]=round(100*tmiss[,2]:/sum(tmiss[,2]))
	tmiss[,4]=runningsum(tmiss[,3])
	tmiss[,6]=tmiss[,1]:*tmiss[,2]
	tmiss[,6]=runningsum(tmiss[,6])
	tmiss[,6]=round(100*tmiss[,6]:/(runningsum(tmiss[,2]):*cols(themiss)),1)
	tmiss="Variables","Observations","","","Data",""\"# Miss","Count","%","Cum %","% Miss","Cum %"\strofreal(tmiss,"%12.0fc")
	tmiss=tmiss\strofreal(cols(themiss))+" vars",strofreal(nobs,"%12.0fc"),"","","",tmiss[rows(tmiss),6]
	t.body=tmiss
	t.head=2
	t.stub=1
	t.altrows=1
	t.set(t._span,1,2,3)
	t.set(t._span,1,5,2)
	t.set(t._vline,.,4,t.Lmajor)
	t.set(t._hline,rows(tmiss)-1,.,t.Lmajor)
	t.render()
	
	t.present(.)
	}
end 
