*! 11jul2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program projix
version 11

mata: DoIt()
end


version 11
mata:
void DoIt() { //>>def func<<
	class tabel scalar t
	class recentle_proj scalar prj
	class dataset_dta scalar ds
	
	prj.get()
	if (!truish(prj.prjdir)) errel("projix cannot run outside of a defined project")
	scmd=subcmdl(main=st_local("0"),("define","compile"),"oknone")
	if (scmd=="define") {
		clearl()
		vars="heading","cell","tip","link"
		(void) st_addvar(("str10","str10","str10","byte"),vars)
		charset(vars,"projix",vars)
		savel(prj.prjdir+"projix")
		return
		}
	
	syntaxl(main,(&(usedta="using")))
	if (truish(usedta)) usedta=pcanon(usedta,"fex")
	else usedta=prj.prjdir+"projix.dta"
	ds.with("d")
	ds.readfile(usedta) //4vars: title,text,link,tip
	
	files=expand(subfiles(prj.prjdir,("*.htm","*.html")),2)
	
	for (fi=1;fi<=rows(files);fi++) {
		bit=ftostr(files[fi,1])
		if (regexm(bit,"<meta *name *= *'outputix' *content *= *'([^']*)'")) files[fi,2]=regexs(1)
		}
	files=select(files,tru2(files[,2]))
	
	t.body=J(rows(files),1,ds.getdat(.,"cell")')
	ttips=J(rows(files),1,ds.getdat(.,"tip")')
	
	funcs=tokenfunc(vec(t.body\ttips),"path")
	funcs=uniqrows(select(funcs[1,],tru2(funcs[2,]))')
	for (fu=1;fu<=rows(funcs);fu++) {
		subs=Psub(funcs[fu],files[,1])
		t.body=subinstr(t.body,adorn("path(",funcs[fu],")"),subs)
		ttips=subinstr(ttips,adorn("path(",funcs[fu],")"),subs)
		}
	
	funcs=tokenfunc(vec(t.body\ttips),"meta")
	funcs=uniqrows(select(funcs[1,],tru2(funcs[2,]))')
	for (fu=1;fu<=rows(funcs);fu++) {
		subs=Msub(funcs[fu],files[,2])
		t.body=subinstr(t.body,adorn("meta(",funcs[fu],")"),subs)
		ttips=subinstr(ttips,adorn("meta(",funcs[fu],")"),subs)
		}
	
	tips=tru2(ds.getdat(.,"tip")')
	links=tru2(ds.getdat(.,"link")')
	for (d=1;d<=ds.nobs;d++) {
		header=J(1,0,"")
		linfo=J(rows(files),0,"")
		if (links[d]) {
			header=("href","target")
			linfo=adorn("file:///",subinstr(files[,1],"\","/")),J(rows(t.body),1,"_blank")
			}
		if (tips[d]) { //tips tips...
			header=header,"title"
			linfo=linfo,ttips[,d]
			}
		if (length(header)) t.body[,d]= t.setLinks(header,linfo,t.body[,d])
		}
	
	t.body=ds.getdat(.,"heading")'\t.body
	t.head=1
	t.altrows=1 /**/
	//a way to add hlines...
	t.set(t._align,.,.,t.left)
	t.present("htm, saving(projix.html)") //use prjdir!
	}

string colvector Psub(string scalar spec, string colvector paths) { //>>def func<<
	bits=strtoreal(tokel(spec,","))
	if (length(bits)==1) bits=bits,bits
	subs=paths:*0
	for (p=1;p<=rows(paths);p++) subs[p]=untokenpath(cut(tokenpath(paths[p]),bits[1],bits[2]))
	return(subs)
	}
string colvector Msub(string scalar spec, string colvector metas) { //>>def func<<
	subs=metas:*0
	spec=ocanon("meta field",spec,("t:itle","r:evision","d:escription"))
	for (m=1;m<=rows(metas);m++) {
		tokd=tokenfunc(metas[m],spec)
		subs[m]=cut(select(tokd[1,],tru2(tokd[2,])),.,1,1)
		}
	return(subs)
	}

end

