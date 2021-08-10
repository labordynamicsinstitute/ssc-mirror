*! 16aug2012 
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program tfreq
version 11.1 

mata: DoIt()
end

version 11.1
mata:
void DoIt() { //>>def func<<
	class tspoof scalar t
	
	syntaxl(st_local("0"),(&(varlist="!anything"),&(ifin="ifin"),&(fw="weight")), (&(rowpc="r:ow"),&(colpc="c:ol"),&(cellpc="cell"),&(nofreq="nof:req"),&(vert="v:ertical"), &(sort="s:ort+"),&(oneway="nov:alcols"),&(twoway="val:cols"),&(nomiss="nom:issing"),&(allrows="all:rows"), &(nlab="nl:abels="),&(vlab="vl:abels="),&(out="out=")))
	if (nofreq&!(rowpc+colpc+cellpc)) errel("Some sort of output must be specified: freq or row/col/cell percent")
	if (oneway&twoway) errel("{hi:valcols} and {hi:novalcols} cannot both be specified")
	if (oneway&(rowpc|colpc|cellpc)) errel("{hi:novalcols} precludes specifying percents")
	if (sort) {
		optionel(*sort,(&(fsort="f:req"),&(lsort="l:abel"),&(vsort="v:alue"),&(rsort="r:everse")))
		if (fsort+lsort+vsort>1) errel("Only one index at a time can be chosen for the sort (plus 'reverse')")
		if (fsort+lsort+vsort==0) fsort=1
		rsort=(-1)^rsort
		}
	else {
		lsort=fsort=0
		rsort=1
		}
	
	varlist=varlist(varlist,"",monly=".")
	monly=tru2(monly)
	if (nomiss) ifin=ifin+adorn((truish(ifin)?"&":"if ")+"!mi(",concat(varlist,","),")")
	settouse(touse,ifin)
	strmon=toindices(strvars(varlist):&monly)
	varlist=t.strdummy(varlist)
	if (length(mos=toindices(monly))) {
		vmos=t.dummyof(varlist[mos])
		for (m=1;m<=length(mos);m++) {
			stata(sprintf("qui replace %s=cond(mi(%s),%s,1)",vmos[m],varlist[mos[m]],varlist[mos[m]]))
			}
		varlist[mos]=vmos
		t.spoofv(varlist[mos],("1","-","Not Missing"))
		t.spoofv(varlist[strmon],(".","","<empty>"))
		}
	oneway=cols(varlist)==1|oneway|(cols(varlist)>2&!(twoway|rowpc|colpc|cellpc))
	cst=cols(varlist)-!oneway
	
	freqs=freq(varlist,touse,!oneway+2*allrows,varlist(fw,"single"))
	if (rows(freqs)==0) {
		t.body="No observations"
		t.present(out)
		exit()
		}
	if (lsort) {
		labmat=J(rows(freqs),cols(varlist),"")
		for (v=1;v<=cols(labmat);v++) labmat[,v]=t.getv(varlist[v],freqs[,v],.,"l"):+t.getv(varlist[v],freqs[,v],.,"u") //potentially still problems with labels?
		freqs=freqs[order(labmat,rsort:*(1..cols(labmat))),]
		}
	else if (rsort<0&!fsort) freqs=freqs[rows(freqs)..1,]
	
	if (oneway) {
		if (fsort) _sort(freqs,(rsort*(cst+1),1..cst))
		data=freqs[,cst+1]
		data=data\sum(data)
		data=data,100*data:/data[rows(data)],100*runningsum(data):/data[rows(data)]
		varcols=freqs[,1..cst]
		}
	else {
		dcvals=dedup(freqs[,cst+1],1)'
		data=colshape(freqs[,cst+2],cols(dcvals))
		dcvals=select(dcvals,colsum(data))
		data=select(data,colsum(data))
		varcols=select(freqs[,1..cst],freqs[,cst+1]:==freqs[1,cst+1])
		rs=rowsum(data)
		cs=colsum(data)
		if (fsort) {
			ord=order(rs,rsort*1)
			data=data[ord,]
			rs=rs[ord]
			varcols=varcols[ord,]
			ord=order(cs',rsort*1)
			data=data[,ord]
			dcvals=dcvals[ord]
			cs=cs[ord]
			}
		data=data,rs\cs,rowsum(cs)
		}
	
	bits=oneway?1:toindices((!nofreq,rowpc,colpc,cellpc))
	cd=cols(data)
	if (length(bits)<3) {
		sdata=tosd(data,bits[1])
		if (length(bits)==2) {
			if (vert) sdata=colshape((sdata,tosd(data,bits[2])),cd)
			else sdata=riffle((sdata,tosd(data,bits[2])),cd)
			}
		}
	else sdata=riffle((colshape((tosd(data,!nofreq),tosd(data,3*colpc)),cd), colshape((tosd(data,2*rowpc),tosd(data,4*cellpc)),cd)),cd)
	if (oneway) sdata[rows(sdata),cols(sdata)]=""
	
	t.labset("n",2,nlab,",u l")
	t.labset("v",2,vlab,"l u, u l")
	dc2=1+(cols(sdata)>cols(data))
	dr2=1+(rows(sdata)>rows(data))
	
	stub=t.getv(varlist[1..cst],varcols[,1..cst])
	vl2=1+(t.vl_n[1]==2/*&dr2==1*/)
	if (dr2>1) stub=colshape((stub,stub:*0),cst*vl2)
	stub=pad(stub,"Total"\J(dr2>1,1,""),"\")
	sthead=colshape(t.getn(varlist[cst..1]'),1),J(cst*t.nl_n[1],cst*vl2-1,t.defChar("{c |}","&#x2502;","&#x2193;"))
	if (vl2==2&cst>1) sthead[,rangel(3,cols(sthead),2)]=J(rows(sthead),cst-1,"")
	
	if (oneway) dhead="Freq","Percent","Cum %"
	else {
		dhead=J(t.nl_n[2]+t.vl_n[2],cols(data),"")
		dhead[1..t.nl_n[2],1]=t.getn(varlist[cst+1],2)'
		dhead[t.nl_n[2]+1..t.nl_n[2]+t.vl_n[2],1..cols(data)-1]=t.getv(varlist[cst+1],dcvals',2)'
		dhead[rows(dhead),cols(data)]="Total"
		if (dc2>1) dhead=riffle((dhead,J(rows(dhead),cols(dhead),"")),cols(dhead))
		}
	
	rsd=rows(sdata)
	csd=cols(sdata)
	t.stub=cols(stub)
	d1=t.stub+1
	d2=d1+csd-1
	t.body=pad(sthead,dhead,",","bottom")
	t.head=rows(t.body)
	nhrows=t.head-t.vl_n[2]-t.nl_n[2]+1..t.head-t.vl_n[2]
	t.body=t.body\stub,sdata
	rb=rows(t.body)
	if (!oneway) t.set(t._vline,.,d2-dc2,t.Lmajor) //total line
	if (dc2>1) {
		t.set(t._vline,.,rangel(d1+1,d2-4,2),t.Lsp2min)
		t.set(t._vline,.,rangel(d1,d2-1,2),t.Lsp1)
		t.set(t._span,t.head-t.vl_n[2]+1..t.head,rangel(d1,d2-1,2),2)
		t.set(t._class,rangel(t.head+1,/*hr+rsd-plusr*/rb,dr2),rangel(d1,d2-1,dc2),"weaker") //for html
		}
	t.set(t._hline,rb-dr2,.,t.Lmajor) //footer line
	if (dr2>1) {
		t.set(t._class,rangel(t.head+1,t.head+rsd-1,2),rangel(d1,d2-dc2+1,dc2),"weaker") //for html
		t.altrows=2
		}
	else t.altrows=1
	if (dc2>1 & dr2>1) t.set(t._class,rangel(t.head+2,t.head+rsd,2),rangel(d1+1,d2,dc2),"other")
	//t.set(t._span,hr+rsd-plusr,1,cst+plusvc)
	span=t.stub
	for (r=1;r<=rows(sthead);r++) {
		t.set(t._span,t.head-rows(sthead)+r,1,span)
		span=span-vl2*!mod(r,t.nl_n[1])
		t.set(t._align,t.head-rows(sthead)+r,1,t.right)
		}
	t.set(t._align,(1::max((cst,t.head))\t.head+rsd-dr2+1),J(max((cst,t.head))+1,1,1),t.right)
	if (!oneway) t.set(t._span,nhrows,d1,csd-dc2)
	t.present(out)
	}

string matrix tosd(real matrix data, real scalar type) {
	if (type==0) return(J(rows(data),cols(data),""))
	if (type==1) return(strofreal(data,"%11.0fc"))
	if (type==2) return(strofreal(100:*data:/data[,cols(data)],"%4.1f"))
	if (type==3) return(strofreal(100:*data:/data[rows(data),],"%4.1f"))
	if (type==4) return(strofreal(100:*data:/data[rows(data),cols(data)],"%4.1f"))
	}

end
