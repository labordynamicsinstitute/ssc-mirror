*! 6dec2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program tone
version 11

mata: DoIt()
end


version 11
mata:
void DoIt() { //>>def func<<
	class tspoof scalar t
	class collector scalar co
	
	syntaxl(st_local("0"),(&(varlist="!anything"),&(ifin="ifin")), (&(hi="hi="),&(stdiff="std:iff"),&(decimal="d:ecimal"),&(p2="p2"),&(catcut="cat:cut="),&(univar="uni:var"), &(sect="sec:tion=*"),&(nlab="nl:abels="),&(vlab="vl:abels="),&(pub="pub:lication"),&(out="out="),&(trysts="test")))
	//can't specify stdiff & p2!
	
	varlist=varlist(varlist,"",mods=("(first)","cat:egorical","di:chotomous","con:tinuous"))
	catcut=editmissing(strtoreal(catcut),0)
	for (c=1;c<=cols(varlist);c++) {
		if (st_isstrvar(varlist[c])) mods[c]="cat"
		else if (substr(mods[c],1,2)=="di") { //these two lines have to change to _tokens_
			charset(varlist[c],"tone_di",substr(mods[c],3)) //a bit odd to always store this...
			mods[c]="di"
			}
		else if (mods[c]=="") {
			st_view(V=.,.,varlist[c],0) //0 selectvar excludes missing
			if (catcut) {
				if (sum(V:==0)+sum(V:==1)==rows(V)/*+missing(V)==st_nobs()*/) mods[c]="di"
				else mods[c]=rows(uniqrows(V))<=catcut?"cat":"con"
				}
			else {
				mods[c]=charget(varlist[c],"tone")
				if (mods[c]=="") {
					if (sum(V:==0)+sum(V:==1)==rows(V)/*+missing(V)==st_nobs()*/) mods[c]="di"
					else if (catdata(varlist[c])) mods[c]="cat"
					else mods[c]="con"
					}
				}
			}
		charset(varlist[c],"tone",mods[c])
		}
	
	if (truish(sect)) {
		sect=expand(strtrim(columnize(sect',":")),2)
		grid=asvmatch(cut(varlist,2),sect[,2],"det")
		sheads=firstof((1::rows(grid)):*grid,"row",0)
		}
	else sheads=J(1,length(varlist),0)
	
	t.labset("n",2,nlab,",l")
	t.labset("v",2,vlab,",l",1)
	pmchar=t.defChar(/*char(177)*/"{c 177}","&plusmn;")
	dot=t.setSpan("nottext",t.defChar("{c 183}","&#9679;"))
	mu=t.defChar("{c 181}","&mu;")
	sig=t.defChar("{c 243}","&sigma;")
	
	varlist=t.strdummy(varlist,("tone","tone_di"))
	univar=univar|cols(varlist)==1
	if (univar) {
		settouse(byvar,"if 1")
		t.spoofn(byvar,"Univariate","","")
		t.spoofv(byvar,("1"," "," "))
		}
	else {
		byvar=varlist[1]
		varlist=cut(varlist,2)
		mods=cut(mods,2)
		}
	
	stata(sprintf("qui count %s mi(%s)",firstof((adorn("",ifin,"&"),"if")),byvar))
	if (st_numscalar("r(N)")) printf("%f observations excluded for missing %s\n",st_numscalar("r(N)"),t.getn(byvar,.,"u"))
	settouse(touse,sprintf("%s !mi(%s)",firstof((adorn("",ifin,"&"),"if")),byvar))
	
	decimal=decimal?"1":"0"
	byfreq=freq(byvar,touse)
	byvals=.,byfreq[,1]'
	t.spoofv(byvar,(".","Overall",""))
	bycols=cols(byvals)
	co.init(4)
	co.add(t.getn(byvar,2)',3)
	co.add(riffle(expand(t.getv(byvar,byvals',2)',3*bycols),bycols),3)
	co.add(("p","stdiff","p<")[1+stdiff+2*p2],4)
	co.add(J(1,bycols,("N","%"+dot+mu,"n"+dot+sig)),3)
	tot=sum(byfreq[,2])
	byfreq=tot\byfreq[,2]
	byfreq=expand((strofreal(byfreq),strofreal(100*byfreq/tot,"%3."+decimal+"f"):+" %"),3)
	co.add(rowshape(byfreq,1),3)
	co.next()
	
	for (i=1;i<=cols(varlist);i++) {
		var=varlist[i]
		type=mods[i]
		if (!anyof(("con","di","cat"),type)) continue
		
		if (sheads[i]) {
			co.add("heading",1)
			co.add(sect[sheads[i],1],2)
			}
		co.add(t.getn(var),2)
		
		if (type=="con") {
			mv=J(2,bycols,.)
			toadd=J(bycols,3,"")
			for(c=1;c<=bycols;c++) { 
				settouse(touse2,(c>1)*sprintf("if %s==%f",byvar,byvals[c]),touse) //to skip overall
				st_view(V=.,.,var,touse2)
				mv[,c]=meanvariance(V)
				toadd[c,]=strofreal(colnonmissing(V)),strofreal(mv[1,c],"%9.3g"),pmchar+strofreal(sqrt(mv[2,c]),"%9.3g")
				}
			co.add("con",1)
			co.add(rowshape(toadd,1),3)
			
			if (stdiff) {
				mv=cut(mv,2)
				co.add(strofreal((max(mv[1,])-min(mv[1,]))/sqrt(sum(mv[2,])/cols(mv)),"%9.3g"),4)
				}
			else if (trysts) {
				stata("qui stcox "+var+" if "+touse)
				co.add(strofreal( select(st_matrix("r(table)"),st_matrixrowstripe("r(table)"):=="pvalue"),"%4.3f"),4)
				}
			else {
				stata("qui oneway "+var+" "+byvar+" if "+touse)
				if (!length(st_numscalar("r(N)"))) co.add(".",4)
				else {
					p=Ftail(st_numscalar("r(df_m)"),st_numscalar("r(df_r)"),st_numscalar("r(F)"))
					co.add(p2?pless(p):strofreal(p,"%4.3f"),4)
					}
				}
			}
		else {
			settouse(touse2,sprintf("if !mi(%s)",var),touse)
			if (type=="di"&strlen(calc=st_global(var+"[tone_di]"))) {
				settouse(extrav,subinstr(calc,"#V",var))
				var=extrav
				}
			zfreqs=freq((var,byvar),touse2,1/*fillin col 0s*/)
			zfreqs=select(zfreqs,!rowmissing(zfreqs[,1..2]))
			stub=uniqrows(zfreqs[,1])
			colmap=vmap(uniqrows(zfreqs[,2]),cut(byvals,2))
			zfreqs=colshape(zfreqs[,3],rows(uniqrows(zfreqs[,2])))
			freqs=J(rows(zfreqs),cols(byvals)-1,0)
			freqs[,colmap]=zfreqs
			denom=colsum(freqs)
			
			denom=sum(freqs),denom
			freqs=rowsum(freqs),freqs
			
			
			if (stdiff) {
				cprcnt=(type=="cat"?freqs:freqs[2,]):/colsum(freqs)
				test=strofreal((rowmax(cprcnt):-rowmin(cprcnt)):/sqrt(rowsum(cprcnt:*(1:-cprcnt))/2), "%9.3g")
				}
			else if (trysts) {
				stata("qui sts test "+var+" if "+touse)
				test=strofreal(chi2tail(st_numscalar("r(df)"),st_numscalar("r(chi2)")),"%4.3f")
				}
			else {
				stata(sprintf("qui ta %s %s if %s, chi2",var, byvar,touse2))
				p=expand(st_numscalar("r(p)"),1,1)
				test=p2?pless(p):strofreal(p,"%4.3f")
				}
			
			if (type=="di") {
				if (rows(freqs)==2) df=freqs[2,]
				else df=J(1,cols(freqs),0)
				co.add("di",1)
				co.add(rowshape((strofreal(denom)',strofreal(100:*df:/denom,"%3."+decimal+"f")':+" %",strofreal(df')),1),3)
				co.add(test,4)
				}
			else {
				co.add("multiple",1)
				co.add(rowshape(expand(strofreal(denom)',3),1),3)
				if (!stdiff) co.add(test,4)
				co.add(J(rows(freqs),1,"val"),1)
				co.add(t.getv(var,stub),2)
				co.add(rowshape((J(length(freqs),1,""),colshape(strofreal(100:*freqs:/denom,"%3."+decimal+"f"):+" %",1),colshape(strofreal(freqs),1)),rows(freqs)),3)
				if (stdiff) co.add(test,4)
				}
			}
		}
	
	control=co.compose()[,1] //wasteful
	t.body=cut(co.compose(),2)
	cb=cols(t.body)
	t.head=t.nl_n[2]+t.vl_n[2]+1
	t.stub=t.nl_n[1]
	t.set(t._hline,t.nl_n[2]+t.vl_n[2],.,t.Lsp1)
	t.set(t._vline,.,rangel(t.stub+3,cb,3),t.Lminor) 
	t.set(t._vline,.,rangel(t.stub+1,cb,3),t.Lsp2)
	t.set(t._vline,.,rangel(t.stub+2,cb,3),t.Lsp1)
	t.set(t._vline,.,cb,t.Lmajor)
	t.set(t._span,1..t.nl_n[2],t.nl_n[1]+1+pub,cb-t.nl_n[1]-1)
	t.set(t._span,t.nl_n[2]+1..t.nl_n[2]+t.vl_n[2],rangel(t.nl_n[1]+1,cb-1,3),3)
	t.set(t._align,1..rows(t.body),1..t.nl_n[1],t.right) //to align spanned cells...
	vals=toindices(control:=="val")
	t.set(t._span,vals,1,t.nl_n[1])
	t.set(t._class,vals,1,"it")
	t.set(t._hline,toindices(control:=="multiple"):-1,.,t.Lsp1)
	t.set(t._hline,toindices(control:=="val":&differ(control)),.,t.Lsp1)
	t.set(t._hline,t.head+1,.,t.Lminor) //cheat, set this after multiple Lsp1
	hdrows=toindices(control:=="heading") //all of these should be done more efficiently
	t.set(t._hline,hdrows:-1,.,t.Lminor)
	t.set(t._hline,hdrows,.,t.Lnone)
	t.set(t._align,hdrows,1..t.nl_n[1],t.left)
	t.set(t._class,hdrows,1,"hi2")
	if (!pub) {
		t.set(t._class,.,rangel(t.nl_n[1]+1,cb-1,3),"weaker")
		t.set(t._class,.,rangel(t.nl_n[1]+3,cb-1,3),"weaker")
		}
	t.set(t._hline,rows(t.body),.,t.Lmajor)
	hix=(-1)^stdiff*strtoreal(t.body[,t.nl_n[1]+1]):+(-1)^!stdiff*strtoreal(hi)
	if (strlen(hi)) t.set(t._class,toindices(hix:<=0),cb,"hi1")
	if (pub) pubkluge(t,pmchar,control)
	t.present(out)
	}

void pubkluge(class tspoof scalar t, string scalar pmchar, string vector control) { //>>def func
	t.body=subinstr(t.body,pmchar,"")
	rrange=t.head..rows(t.body)
	crange=rangel(t.stub+1,cols(t.body)-3,3)
	t.body[rrange,crange]=J(length(rrange),length(crange),"")
	t.body[t.head,.]=J(1,cols(t.body),"")
	t.body[rrange,crange:+2]=adorn("(",t.body[rrange,crange:+2],")")
	t.stub=t.stub+1
	t.set(t._vline,.,t.stub,t.Lmajor)
	legix=toindices(control:=="con")
	if (truish(legix)) t.body[legix,t.stub]=J(length(legix),1,"mean (sd)")
	legix=toindices(control:=="di":|control:=="val")
	if (truish(legix)) t.body[legix,t.stub]=J(length(legix),1,"% (n)")
	t.body[1..t.nl_n[2]+t.vl_n[2],t.stub..t.stub+1]=t.body[1..t.nl_n[2]+t.vl_n[2],t.stub+1..t.stub]
	t.set(t._span,t.nl_n[2]+1..t.nl_n[2]+t.vl_n[2],t.stub,1)
	t.set(t._span,t.nl_n[2]+1..t.nl_n[2]+t.vl_n[2],t.stub+1,2)
	}

end
