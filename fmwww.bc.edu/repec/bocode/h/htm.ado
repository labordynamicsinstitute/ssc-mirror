*! 28jan2011
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program htm
version 13

mata: DoIt()
end
//the version numbers are crucial for capture stata()!
version 13
mata:

void DoIt() { //>>def func<<
	external pointer (class htmlplus scalar) scalar el_htmlpgs //bug:external class creates pointer, for which the declaration is wrong
	if (el_htmlpgs==NULL) el_htmlpgs=&(htmlplus()) //a null pointer, above, needs an instance...
	
	scmd=subcmdl(main=st_local("0"), ("page","bits","write","div","redir:ect","query","clear","html"))
	
	if (scmd=="page") {
		syntaxl(main,&(pgid="anything"), (&(title="t:itle="),&(des="d:escription="),&(rev="r:evision="),&(styles="st:yles=")))
		el_htmlpgs->page(pgid)
		el_htmlpgs->header(title,rev,des)
		el_htmlpgs->addcss(styles)
		}
	else if (scmd=="bits") {
		syntaxl(main,NULL,&(bits=("toc=*","p:aragraph=*","text=*","file=*","break=*", "buttons=*","drop:down=*","cbox=*","image=*","log=*")))
		
		for (b=1;b<=cols(bits);b++) {
			if (bits[2,b]=="toc") el_htmlpgs->addtoci(bits[b,1])
			else if (bits[2,b]=="paragraph") el_htmlpgs->place("<p class='bitsp'>"+bits[1,b]+"</p>")
			else if(bits[2,b]=="text") el_htmlpgs->place(bits[1,b])
			else if (bits[2,b]=="file") el_htmlpgs->place(ftostr(bits[1,b]))
			else if (bits[2,b]=="image") {
				syntaxl(bits[1,b],&(imname="!anything"),(&(tip="t:ip="),&(width="w:idth=")))
				stata("qui graph dir")
				if (truish(imname:==tokel(st_global("r(list)")))) {
					width=firstof(width\"800")
					stata(sprintf("qui graph export %s, as(png) name(%s) width(%s) replace",tf=st_tempfilename(),imname,width))
					el_htmlpgs->addimage("png",ftostr(tf),tip)
					}
				else el_htmlpgs->addimage(substr(pathparts(imname,3),2),ftostr(imname),tip)
				}
			else if (bits[2,b]=="log") {
				logpath=pathto("_topage.txt","inst")
				stata(sprintf(`"qui log using "%s", replace text"',logpath))
				allcmds=columnize(bits[1,b],";")
				for (c=1;c<=length(allcmds);c++) stata(allcmds[c])
				stata("qui log close")
				el_htmlpgs->addlog(bits[1,b],logpath)
				}
			else if (bits[2,b]=="break") el_htmlpgs->addpgbreak()
			else if (bits[2,b]=="cbox"){
				syntaxl(bits[1,b],&(cbname="!anything"), (&(disp="!d:isp="),&(tip="t:ip="),&(iyes="i:check")))
				el_htmlpgs->addcbox(cbname,disp,tip,iyes)
				}
			else if (bits[2,b]=="dropdown") {
				syntaxl(bits[1,b],&(drname="!anything"),&(choices=("ich:oice=","ch:oice=*")))
				el_htmlpgs->adddd(drname,choices)
				}
			else if (bits[2,b]=="buttons") {
				syntaxl(bits[1,b],&(bname="!anything"),(&(bs=("ibtn=","btn=*")),&(colors="colors=")))
				ibut=toindices(substr(bs[2,],1,1):=="i","z")
				bs=bs'
				for (bsn=1;bsn<=rows(bs);bsn++) {
					optionel(bs[bsn,1],(&(disp="!d:isplay="),&(tip="t:ip=")))
					bs[bsn,]=disp,tip
					}
				colors=tokel(colors)
				if (length(colors)!=0&length(colors)!=3) errel("You must specify 3 colors or none")
				el_htmlpgs->addbuttons(bname,bs,ibut,colors)
				}
			}
		}
	else if (scmd=="write") {
		syntaxl(main,&(path="anything"),(&(id="page="),&(grail="el_grail=")))
		el_htmlpgs->write(id,path,grail)
		launchfile(path)
		}
	else if (scmd=="div") {
		syntaxl(main,&(id="anything"),(&(parent="p:arent="),&(showif="sh:owif=")))
		el_htmlpgs->div(strtrim(id),parent,adorn("showif='",showif,char(39)))
		}
	else if (scmd=="redirect") printf("{txt}redirect isn't functioning at the moment\n")
	else if (scmd=="query") {
		if (truish(main)) show(el_htmlpgs->query("all"))
		else {
			class tabel scalar t
			t.body="Selector","Attributes"\el_htmlpgs->query()
			t.head=1
			t.set(t._align,.,.,t.left)
			t.set(t._wrap,.,2,-3)
			t.set(t._class,.,1,"heading")
			t.present("")
			}
		}
	else if (scmd=="clear") el_htmlpgs=NULL
	else if (scmd=="html") {
		htmpath=findfile("htm.ado")
		lprog="program html"+eol()+`"local version : di "version " string(_caller()) ":" "'+eol()+char(96)+"version' htm "+char(96)+"0'"+eol()+"end"+eol()
		fowrite(x=subinstr(htmpath,".ado","l.ado"),lprog)
		fowrite(x=subinstr(htmpath,".ado","l.sthlp"),".h htm"+eol())
		}
	}

end

