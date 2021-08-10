*! as of 3nov2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program tlist
version 11.1

mata: DoIt()
end


version 11.1
mata:
void DoIt() { //>>def func<<
	class tspoof scalar t
	class statgrid scalar sg
	
	syntaxl(st_local("0"),(&(spec="anything"),&(ifin="ifin")), (&(head="h:ead="),&(stn="stub="),&(foot="f:oot="),&(skip="skip:names"),&(distinct="d:istinct+"),&(random="r:andom+"), &(vline="vli:ne=*"),&(hline="hli:ne=*"),&(align="ali:gn=*"),&(wrap="wr:ap=*"),&(clas="cl:ass=*"), &(alt="alt:back="), &(nlab="nl:abels="),&(vlab="vl:abels="),&(out="out=")))
	
	t.labset("n",2,nlab,"l,l") //body, stub!
	t.labset("v",2,vlab,"l,l") //body, stub!
	
	stn=editmissing(strtoreal(stn),0)
	spec=tokel(spec,"|")
	if (length(spec)>1|skip) {
		if (skip&!truish(spec)) spec=varlist(spec,"all")
		tlh=valofexternal("tlisthead_el")
		if (length(spec)!=cols(tlh)) errel("columns do not match super-heads")
		supers=1
		vars=varlist(spec[1])
		for (i=2;i<=cols(spec);i++) {
			supers=supers,length(vars)+1
			vars=vars,varlist(spec[i])
			}
		head=J(rows(tlh),cols(vars),"")
		head[,supers]=tlh //there are no blanks in tlh, so none in col 1
		if (any(!strlen(head[,stn+1]):&rowmax(strlen(cut(head,2))))) errel("superheads cannot span the stub boundary")
		}
	else {
		vars=varlist(spec,"all")
		head=J(0,cols(vars),"")
		}

	if (distinct) {
		if (*distinct=="1") distinct=concat(vars," ")
		else distinct=concat(varlistk(vars,*distinct,"all")," ")
		stata(sprintf("qui egen byte %s=tag(%s) %s, missing",touse=st_tempname(),distinct,ifin))
		}
	else settouse(touse,ifin)
	if (truish(random)) {
		if (!truish(touse)) settouse(touse,"if 1")
		el_view(users=.,.,touse,touse)
		random=pmin(rows(users),firstof(strtoreal(*random)\c("pagesize")-3))
		users[.]=jumble(J(random,1,1)\J(rows(users)-random,1,0))
		}
	if (truish(touse)) none=!sum(el_data(.,touse))
	else none=!st_nobs()
	if (none) {
		t.present(out)
		return
		}
	
	sthead=cut(head,1,stn,.,"cols")
	bhead=head[,stn+1..cols(head)]
	
	stvars=cut(vars,1,stn)
	bvars=cut(vars,stn+1)
	if (!skip) {
		sthead=sthead\t.getn(stvars',2)'
		bhead=bhead\t.getn(bvars',1)'
		}
	
	b2=t.vl_n[1]
	s2=t.vl_n[2]
	if (b2==2) bhead=riffle((bhead,J(rows(bhead),cols(bhead),"")),cols(bhead))
	if (s2==2) sthead=riffle((sthead,J(rows(sthead),cols(sthead),"")),cols(sthead))
	
	t.head=pmax(rows(sthead),rows(bhead))
	t.stub=stn*s2
	
	if (truish(foot)) {
		sg.setup(concat(bvars," ")+":"+foot,ifin)
		sg.set_flabels()
		sg.dseval()
		nstats=sg.ds.nvars/sg.cross
		sg.ds.formats=J(1,sg.ds.nvars,"%12.0g") //commas mess with getv
		footer=kaleid(sg.ds.strdat(.,.),1,nstats)
		}
	else footer=J(0,0,"")
	t.body=t.getv(bvars,pad(el_sdata(.,bvars,touse),footer,"\"),1)
	if (t.stub) {
		stub=t.getv(stvars,el_sdata(.,stvars,touse),2)
		if (truish(foot)) stub=pad(stub,sg.ds.nlabels[1..nstats]',"\")
		t.body=stub,t.body
		}
	t.body=pad(sthead,bhead,",")\t.body
	
	t.altrows=firstof((strtoreal(alt)\1))
	rb=rows(t.body)
	cb=cols(t.body)
	if (rows(tlh)-1>skip) t.set(t._hline,1..rows(tlh)-skip-1,.,t.Lsp1)
	t.set(t._align,.,toindices(rowshape(J(1,s2,strvars(stvars')),1)),t.left)
	t.set(t._align,.,t.stub:+toindices(rowshape(J(1,b2,strvars(bvars')),1)),t.left)
	for (h=1;h<=t.head;h++) {
		//for (h=1;h<=rows(tlh);h++) {
		on=toindices(tru2(t.body[h,])),cb+1
		for (c=1;c<length(on);c++) t.set(t._span,h,on[c],on[c+1]-on[c])
		}
	if (rf=rows(footer)) {
		t.set(t._hline,rb-rf,.,t.Lmajor)
		t.set(t._align,rb-rf+1..rb,1,t.right)
		if (t.stub) t.set(t._span,rb-rf+1..rb,1,t.stub)
		}
	t.set(t._vline,.,.,t.Lsp2min)
	hdivide=cut(tru2(select(head,rowsum(tru2(head)):>1)),2)
	if (rows(hdivide)>1) t.set(t._vline,.,toindices(hdivide[rows(hdivide),]),t.Lminor)
	if (rows(hdivide)) t.set(t._vline,.,toindices(hdivide[1,]),t.Lmajor)
	if (s2==2) {
		t.set(t._vline,.,rangel(1,t.stub,2),t.Lsp1)
		t.set(t._vline,.,rangel(2,t.stub-1,2),t.Lminor)
		}
	if (b2==2) {
		t.set(t._vline,.,rangel(t.stub+1,cb,2),t.Lsp1)
		t.set(t._vline,.,rangel(t.stub+2,cb,2),t.Lminor)
		}
	
	for (i=1;i<=5;i++) {
		styles=*(&vline,&hline,&align,&wrap,&clas)[i]
		for (s=1;s<=length(styles);s++) {
			astyle=tokel(styles[s],":")
			if (truish(astyle[,1])!=rows(astyle)|cols(astyle)!=2) errel("Each style option must include one {it:style name} & colon ({hi::})")
			if (astyle[1]=="altback") t.altrows=0
			syntaxl(astyle[2],(&(styvars="anything"),&(ifin="ifin")),&(rixs="r:ows="))
			styvars=varlist(styvars,"all")
			if (!length(styvars)) stycols=.
			else stycols=multix(vmap(styvars,stvars),s2),multix(vmap(styvars,bvars),b2,t.stub)
			if (!strlen(ifin+rixs)) styrows=.
			else {
				styrows=J(1,0,.)
				if (strlen(ifin)) {
					settouse(touse2,ifin)
					styrows=styrows,toindices(st_data(.,touse2,touse)'):+t.head
					}
				if (strlen(rixs)) styrows=styrows,numl(rixs,sprintf("asc int range(>=1 <=%f)",rb))
				}
			substyles=astyle[1] //this used to possibly be the v- variable
			sets=uniqrows(substyles)
			if (styrows==.&rows(sets)>1) styrows=(1::rows(substyles)):+t.head
			for (ss=1;ss<=rows(sets);ss++) {
				vstyle=sets[ss]
				vrows=styrows==.?.:select(styrows,vstyle:==substyles)
				if (i<=2) t.set(i==1?t._vline:t._hline,vrows,stycols, (t.Lmajor,t.Lminor,t.Lsp2,t.Lnone)[toindices(vstyle:==("major","minor","space","none"))])
				else if (i==3) t.set(t._align,vrows,stycols,(t.left,t.center,t.right)[toindices(vstyle:==("left","center","right"))])
				else if (i==4) t.set(t._wrap,vrows,stycols,strtoreal(vstyle)) //could be numeric already
				else t.set(t._class,vrows,stycols,vstyle,"post")
				}
			}
		}
	
	t.present(out)
	}

end
