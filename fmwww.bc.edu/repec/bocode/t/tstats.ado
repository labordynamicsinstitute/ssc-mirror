*! 22dec2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program tstats, sortpreserve
version 11

mata: DoIt()
end

version 11
mata:

void DoIt() { //>>def func
	class statgrid scalar sg
	class tspoof scalar t
	
	syntaxl(st_local("0"),(&(explist="anything"),&(ifin="ifin")),(&(by="by="),&(swap="swap"), &(nest="nest"),&(nlab="nl:abels="),&(vlab="vl:abels="),&(out="out=")))
	syntaxl(by,&(by2="anything"), (&(fm="f:irstvar"),&(lm="l:astvar"),&(ov="o:verall"),&(byc="c:olumns")))
	
	sg.defaults="Nobs() N() Mean() SD() Min() Med(,d(Med)) Max()"
	sg.by(by2)
	bytypes=""
	if (length(sg.by_vars)) {
		if (length(sg.by_vars)>1) {
			if (fm) {
				sg.bys=sg.bys\&sg.by_vars[1]
				bytypes=bytypes,"fm"
				}
			if (lm) {
				sg.bys=sg.bys\&cut(sg.by_vars,-1)
				bytypes=bytypes,"lm"
				}
			}
		if (ov) {
			sg.bys=sg.bys\&""
			bytypes=bytypes,"om"
			}
		}
	sg.setup(explist,ifin)
	sg.set_flabels()
	sg.dseval()
	b_n=sg.b_n
	k_n=sg.k_n
	cross=sg.cross*!nest
	
	if (any(bytypes:=="fm")) {
		mn=J(1,4,0)
		for (m=1;m<=length(sg.bys);m++) mn[m]=*sg.bys[m]
		mf=&(J(mn[1],1,0)\J(mn[2],1,1)\J(mn[3]+mn[4],1,0))
		ml=&(J(mn[1]+mn[2],1,0)\J(mn[3],1,1)\J(mn[4],1,2))
		cosort_((ml,sg.ds.data[1],mf,sg.ds.data[2..sg.ds.nvars]),1::sg.ds.nvars+2)
		}
	
	t.labset("n",2,nlab,"u,u")
	t.labset("v",2,vlab,"l,l",(1,0))
	dnames=t.dsspoof(sg.ds)
	
	if (!cross) {
		xstub=J(1,0,"")
		xhead=t.getn(sg.k_vars)'\cut(sg.ds.nlabels,b_n+1)
		}
	else {
		xstub=t.getn(dedup(sg.k_vars'))
		xhead=sg.ds.nlabels[b_n+1..b_n+k_n/cross]
		}
	
	data=t.getv(cut(dnames,b_n+1),sg.ds.strdat(.,b_n+1..b_n+k_n),1)
	allby=b_n?t.getv(cut(dnames,1,b_n),sg.ds.strdat(.,1..b_n),2):J(0,rows(data),"")
	byhead=byheadh=bystub=J(0,0,"")
	if (b_n>byc) bystub=dedup(cut(allby,1,(b_n-byc)*t.vl_n[2],.,"cols"))
	if (byc) {
		byhead=dedup(cut(allby,b_n,b_n*byc,.,"cols"))'
		byheadh=t.getn(dnames[b_n],2)'
		if (b_n>1) {
			del=charsubs(allby)
			x=pairs(bystub,byhead')
			rmap=vmap(concat(x,del),concat(allby,del),"both")
			ndata=J(rows(x),cols(data),"")
			ndata[rmap[,1],]=data[rmap[,2],]
			data=ndata
			}
		}
	if (swap&cross) data=riffle(data,k_n/cross)
	if (byc) data=colshape(data,cols(data)*cols(byhead))
	if (swap&cross) data=kaleid(data,cross,k_n/cross)
	else if (swap) data=kaleid(data,1,k_n)
	else if (cross) data=kaleid(data,k_n/cross,cross)
	if (swap) {
		sw=xstub
		xstub=xhead'
		xhead=sw'
		}
	head=pad(byheadh,pairs(byhead',xhead')',"\")
	stub=pairs(bystub,xstub)
	
	sthead=J(0,cols(stub),"")
	if (b_n>byc) sthead=expand(colshape(t.getn(dnames[b_n-byc..1],2),1),cols(stub),1)
	if (b_n-byc>1) {
		guide=t.defChar("{c |}","&#x2502;","&#x2193;")
		sthead[,rangel(2*t.vl_n[2],(b_n-byc)*t.vl_n[2],t.vl_n[2])]=J(rows(sthead),b_n-byc-1,guide)
		}
	
	t.body=pad(sthead,head,",","bottom")\stub,data
	t.head=rows(t.body)-rows(data)
	t.stub=cols(stub)
	t.altrows=1
	xhn=cols(xhead)
	
	span=t.stub-cols(xstub)
	for (r=1;r<=rows(sthead);r++) {
		t.set(t._span,t.head-rows(sthead)+r,1,span)
		span=span-t.vl_n[2]*!mod(r,t.nl_n[2])
		t.set(t._align,t.head-rows(sthead)+r,1,t.right)
		}
	if (byc) {
		hr1=1+pmax(b_n-byc-rows(head),0)
		t.set(t._span,hr1..hr1+t.nl_n[2]-1,t.stub+1,cols(data))
		t.set(t._span,hr1+t.nl_n[2]..hr1+t.nl_n[2]+t.vl_n[2]-1,rangel(t.stub+1,cols(t.body),xhn),xhn)
		t.set(t._vline,.,rangel(t.stub+xhn,cols(t.body),xhn),t.Lminor)
		}
	stspcol=t.stub-cols(xstub)-!cols(xstub)*t.vl_n[2]-(t.vl_n[2]==2)
	for (c=stspcol;c>0;c=c-t.vl_n[2]) {
		t.set(t._hline,toindices(differ(stub[,c])):+t.head,(c..cols(t.body)),c==stspcol?t.Lsp1:t.Lminor)
		}
	if (!cross&!swap) {
		vbrk=J(1,pmax(1,cols(byhead)),differ(sg.k_vars,"bef","true"))
		vix=toindices(vbrk):+t.stub
		vsp=(cut(vix,2),length(vbrk)+1+t.stub):-vix
		for (v=1;v<=length(vix);v++) t.set(t._span,t.head-t.nl_n[1]..t.head-1,vix[v],vsp[v])
		if (length(vix=select(vix,vix:>t.stub+1):-1)) t.set(t._vline,.,vix,t.Lminor)
		}
	t.set(t._vline,.,cols(t.body),t.Lmajor)
	
	if (length(sg.bys)>1) { //margins
		if (byc&(bytypes[2]=="fm"|b_n==1)) t.set(t._vline,.,cols(t.body)-xhn,t.Lmajor)
		if (b_n>byc) {
			if (length(sg.bys)>2|bytypes[2]!="fm") t.set(t._hline,cut(toindices(differ(t.body[,1])),-1),1..cols(t.body),t.Lmajor) //because earlier hlines are set by cell
			if (cut(bytypes,-1)=="om") t.set(t._hline,rows(t.body),1..cols(t.body),t.Lmajor) //sometimes rendundant
			}
		}
	t.present(out)
	}

end
