*! 25oct2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program intercorr
version 11.1

mata: DoIt() 
end


mata:
version 11.1
void DoIt() { 
	class tspoof scalar t
	
	syntaxl(st_local("0"),(&(stat="!anything"),&(ifin="ifin")),(&(va="!a="),&(vb="!b="),&(adj="adjust"), &(N="n"),&(nostat="nost:at"),&(nop="nop"),&(stars="st:ars+"),&(nlab="nl:abels="),&(vlab="vl:abels="),&(out="out="), &(save="save=")))
	
	optionel(stat,(&(p="p:earson"),&(s="s:pearman"),&(k="k:endall"),&(r="r"),&(rho="rho"),&(tau="t:au")))
	if (p+s+k+r+rho+tau>1) errel("Only one correlation statistic can be specified for intercorr")
	else if (p+s+k+r+rho+tau==0) errel("A correlation statistic must be specified")
	cmd=("corr","r(rho)"\"spearman","r(rho)"\"ktau","r(tau_b)")[1+(s+rho)+2*(k+tau),]
	if (nostat) stars=0
	if (stars) {
		if (truish(*stars)) stars=strtoreal(tokel(*stars))
		else stars=(.05,.01,.001)
		}
	
	va=varlist(va)
	vb=varlist(vb)
	if (strlen(save)) {
		rmexternal(save)
		sstats=crexternal(save)
		*sstats=asarray_create()
		asarray(*sstats,"rowvars",va')
		asarray(*sstats,"colvars",vb)
		alln=allstat=allp=J(length(va),length(vb),.)
		}
	
	pick=toindices((N,!nostat,truish(stars),!nop))
	perc=cols(pick)
	
	t.body=J(length(va),perc*length(vb),"")
	adj=adj?length(va)*length(vb):1
	for (a=1;a<=length(va);a++) {
		for (b=1;b<=length(vb);b++) {
			cix=(b-1)*perc
			stata(sprintf("qui %s %s %s %s",cmd[1],va[a],vb[b],ifin))
			rstat=st_numscalar(cmd[2])
			N=st_numscalar("r(N)")
			if (cmd[1]=="corr") p=min((2*ttail(N-2,abs(rstat)*sqrt(N-2)/sqrt(1-rstat^2)),1))*adj
			else p=st_numscalar("r(p)")*adj
			if (truish(save)) {
				alln[a,b]=N
				allstat[a,b]=rstat
				allp[a,b]=p
				}
			t.body[a,cix+1..cix+perc]=
			(strofreal(N),strofreal(rstat,"%3.2f"),"*"*sum(p:<=stars),strofreal(p,"%4.3f"))[pick]
			}
		}
	if (truish(save)) {
		asarray(*sstats,"n",alln)
		asarray(*sstats,"stat",allstat)
		asarray(*sstats,"p",allp)
		}		
	
	t.labset("n",1,nlab) //should be 2
	//t.labset("v",1,vlab) //none?
	stub=t.getn(va')
	head=J(1+t.nl_n,perc*length(vb),"")
	head[1..t.nl_n,rangel(1,cols(head),perc)]=t.getn(vb')'
	head[t.nl_n+1,]=J(1,length(vb),("n",stat,"","p")[pick])
	t.body=pad(head,(stub,t.body),"\","rev")
	
	t.head=1+t.nl_n
	t.stub=t.nl_n
	t.set(t._span,1..t.nl_n,rangel(t.nl_n+1,cols(t.body),perc),perc)
	t.set(t._align,.,1..t.nl_n,t.left)
	//t.set(t._class,.,rangel(2,cols(t.body),2),"weaker")
	t.set(t._vline,.,rangel(t.nl_n+perc,cols(t.body),perc),t.Lminor)
	if (truish(stars)) {
		t.set(t._vline,.,rangel(t.nl_n+1+(pick[1]==1),cols(t.body),perc),t.Lnone)
		t.set(t._align,.,rangel(t.nl_n+2+(pick[1]==1),cols(t.body),perc),t.left)
		}
	t.set(t._wrap,1..t.nl_n,.,0)
	t.set(t._wrap,.,1..t.nl_n,0)
	t.set(t._hline,rows(t.body),.,t.Lmajor)
	t.o_parse(out)
	t.render()
	if (truish(stars)) {
		t.body="*":*(1::length(stars)),"p<=":+strofreal(stars')
		t.head=length(stars)
		t.set(t._align,.,2,t.left)
		t.set(t._vline,.,1,t.Lsp1)
		t.padbefore=0
		t.render()
		}
	t.present(out)
	}

end


