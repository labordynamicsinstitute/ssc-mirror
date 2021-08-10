*! 8oct2010
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program dd
version 11.1 

mata: DoIt()
end


version 11.1
mata:
void DoIt() { //>>def func<<
	class dataset_dta scalar ds
	class tabel scalar t
	
	syntaxl(st_local("0"),(&(vars="anything"),&(use="using")), (&(hilight="hi:light="),&(plain="p:lain"),&(alpha="a:lpha"),&(out="out=")))
	if (strlen(hilight) & plain) errel("Only one of -hilight- and -plain- can be specified.")
	ds.with("lab")
	if (truish(use)) ds.readfile(use)
	else ds.readmem()
	vars=ds.varlist(vars,"all")
	if (alpha) vars=vars[order(ds.vnames[vars]',1)']
	st_rclear()
	st_global("r(varlist)",concat(ds.vnames[vars]," "))
	if (!length(vars)) {
		printf("{res:No variables}")
		exit()
		}
	
	cats=his=J(1,length(vars),0)
	if (!plain) {
		if (strlen(hilight)) his=vmap(vars,ds.varlist(hilight))
		else {
			his=ds.sirtypes[vars]:=="s"
			cats=vars:*0
			for (v=1;v<=length(vars);v++) {
				if (length(labels=ds.labelsof(vars[v]))) {
					if (nonmissing(strtoreal(labels[,1]))) cats[v]=1
					}
				}
			}
		}
	
	psize=c("pagesize")-3
	pvars=colshape((ds.vnames[vars],J(1,psize-mod(length(vars),psize),"")),psize)'
	sizes=colmax(strlen(pvars):+1)
	pages=(1,1)
	while ((c=pages[rows(pages),2]+1)<=cols(pvars)) {
		if (sum(sizes[pages[rows(pages),1]..c])<c("linesize")) pages[rows(pages),2]=c
		else pages=pages\J(1,2,c)
		}
	
	t.o_parse(out)
	rp=rows(pages)
	if (rp>1) {
		hl=t.defChar("{c -}","&#x2500;")
		t.body=hl*trunc(2*c("linesize")/3)
		t.padbefore=t.padafter=0
		t.set(t._class,.,.,"heading")
		t.set(t._align,.,.,t.center)
		t.render()
		div=t.rendered
		t.rendered=""
		}
	if (key=!plain&hilight=="") { //what should hilight criteria be?
		t.body=t.setSpan("body","Key: numeric")+t.setSpan("hi1"," num/labeled")*!missing(ds.bytes)+t.setSpan("hi2"," string")
		t.set(t._align,.,.,t.left)
		t.set(t._hline,.,.,t.Lminor)
		t.padafter=0
		t.render()
		}
	for (p=1;p<=rp;p++) {
		t.body=pvars[,pages[p,1]..pages[p,2]]
		if (pages[p,2]==1) t.body=select(t.body,tru2(t.body))
		t.padbefore=(p+key==1)
		t.padafter=0
		t.set(t._vline,.,.,t.Lsp1)
		t.set(t._align,.,.,t.left)
		pspan=(pages[p,1]-1)*psize+1..min((length(vars),pages[p,2]*psize))
		pcells=pcells(pspan,cats,psize)
		if (length(pcells)) {
			for (r=1;r<=rows(pcells);r++) t.set(t._class,pcells[r,1],pcells[r,2],"hi1")
			}
		pcells=pcells(pspan,his,psize)
		if (length(pcells)) {
			for (r=1;r<=rows(pcells);r++) t.set(t._class,pcells[r,1],pcells[r,2],"hi2")
			}
		t.render()
		if (rp>1) t.rendered=t.rendered+div
		}
	t.present(.)
	}

real matrix pcells(real vector span, real vector selector, real scalar rows) { //>>def func<<
	pvect=toindices(selector[span])'
	if (length(pvect)) return((mod1(pvect,rows),trunc((pvect:-1)/rows):+1))
	else return(J(0,2,.))
	}

end
