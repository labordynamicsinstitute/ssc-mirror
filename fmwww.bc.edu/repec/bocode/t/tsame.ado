*! 23mar2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program tsame, sortpreserve
version 11

mata: DoIt()
end


version 11
mata:
void DoIt() { //>>def func<<
	class tabel scalar t
	class statgrid scalar sg
	
	syntaxl(st_local("0"),(&(dups="anything"),&(ifin="ifin")),(&(difs="m:ultiple="),&(heads="h:eadings="), &(out="out=")))
	cmdvars("","tsame")
		
	settouse(touse,ifin)
	iftouse=adorn("if ",touse)
	
	dups=concat(varlist(dups,"all")," ")
	stata(sprintf("qui egen %s=group(%s) %s, m",uid=st_tempname(),dups,iftouse))
	stata("sort "+uid)
	
	dup_="_same"
	stata(sprintf("qui by %s: gen %s=_N %s",uid,dup_,iftouse))
	difs=varlist(difs)
	ldf=length(difs)
	dif_=ldf?riffle(("_":+difs:+"_2","_":+difs:+"_m"),ldf):J(1,0,"")
	for (d=1;d<=ldf;d=d++) {
		settouse(touse2,sprintf("if !mi(%s)",difs[d]),touse)
		d_=(d-1)*2+1
		
		stata(sprintf("qui bysort %s %s (%s): gen byte %s=%s[1]!=%s[_N] if %s",touse2,uid,difs[d],dif_[d_],difs[d],difs[d],touse2))
		stata(sprintf("qui bysort %s (%s): replace %s=%s[1] if mi(%s) %s",uid,dif_[d_],dif_[d_],dif_[d_],dif_[d_],adorn("& ",touse)))
		stata(sprintf("qui bysort %s (%s): replace %s=0 if mi(%s) %s",uid,dif_[d_],dif_[d_],dif_[d_],adorn("& ",touse)))
		
		mord=strvars(difs[d])?("_N","1"):("1","_N")
		stata(sprintf("qui bysort %s (%s): gen byte %s=!mi(%s[%s])&mi(%s[%s]) %s",uid,difs[d],dif_[d_+1],difs[d],mord[1],difs[d],mord[2],iftouse))
		}
	cmdvars((dup_,dif_),"tsame")
	sg.by(dup_)
	sg.setup(adorn("Uniq(",uid,") ")+concat("Mean(Sum(":+dif_:+")/":+dup_:+")"," "),iftouse)
	sg.dseval()
	bod=expand(sg.ds.getdat(.,.),sg.ds.nvars+1,sg.ds.nobs+1)
	bod[,cols(bod)]=bod[,1]:*bod[,2]
	bod[rows(bod),]=colsum(bod)
	for (d=1;d<=ldf*2;d++) {
		if (!truish(bod[,d+2])|bod[,d+2]==bod[,2]) st_dropvar(dif_[d])
		}
	if (rows(uniqrows(el_data(.,dup_,touse)))==1) st_dropvar(dup_)
	
	t.o_parse(out)
	t.body="Sets with the same values of:",dups
	t.set(t._class,1,1,"heading")
	t.padafter=0
	t.render()
	
	t.head=1+3*(ldf>0)
	t.altrows=1
	t.body=expand(strofreal(bod,"%12.0fc"),.,-rows(bod)-1-3*truish(ldf))
	t.body[rows(t.body),1]=""
	heads=expand(tokel(heads,","),3)
	t.body[1,]=firstof(heads[1]\"Records"+eol()+"per Set"), firstof(heads[2]\"Distinct"+eol()+"Sets"),J(1,2*ldf,""),firstof(heads[3]\"Total"+eol()+"Records")
	t.set(t._span,1,2,1+2*ldf)
	t.set(t._align,1,1..3+2*ldf,t.center)
	if (ldf) {
		t.set(t._hline,1,.,t.Lsp1)
		t.body[2,]="","","Multiple",J(1,2*ldf-1,""),""
		t.set(t._span,2,3,2*ldf)
		t.set(t._hline,2,3..2+2*ldf,t.Lminor)
		t.body[3,]="","",riffle((difs,J(1,ldf,"")),ldf),""
		t.set(t._span,3,rangel(3,2+2*ldf,2),2)
		t.set(t._vline,3..rows(t.body),2,t.Lminor)
		htext="2 or more present (ie, non-missing) values"\"present (ie, non-missing) and missing values"
		htext=adorn(`"matacmd MoreInfo(" "',htext,`" ")"'),htext
		htext=rowshape(t.setLinks(("stata","title"),htext,"p2+"\"p+m"),1)
		t.body[4,]="","",J(1,ldf,htext),""
		t.set(t._vline,.,rangel(3,2+2*ldf,2),t.Lsp1)
		t.set(t._class,.,rangel(4,3+2*ldf,2),"weaker")
		}
	t.set(t._hline,rows(t.body)-1,.,t.Lmajor)
	t.set(t._vline,.,1,t.Lmajor)
	t.set(t._vline,.,cols(t.body)-1,t.Lmajor)
	t.present(out)
	}
end
