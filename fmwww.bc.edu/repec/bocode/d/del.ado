*! 13may2011
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program del 
version 11.1 

mata: DoIt()
end 

version 11.1
mata:
void DoIt() { //>>def func
	class dataset_dta scalar ds
	class tabel scalar t
	
	syntaxl(st_local("0"),(&(vars="anything"),&(use="using")), (&(def="def:ine"),&(inc="i:nclude="),&(wrap="wr:ap"),&(novar="nov:ars"),&(sect="sec:tion=*"),&(out="out=")))
	if (def&truish(use)) errel("{txt:Define cannot be specified with an external (ie, {it:using}) files.}\n")
	
	fields="irs:type","std:type","f:ormat","nl:abel","vl:abel"
	syntaxl(inc,&(incf="anything"),&(inco="o:nly"))
	incf=ocanon("Include Columns",tokel(incf),fields,incc="nfok max")
	inc=firstof(incf\incc)
	
	//if (truish(sect)) {
	//	sect=expand(strtrim(columnize(sect',":")),2)
	//	grid=asvmatch(cut(varlist,2),sect[,2],"det")
	//	sheads=firstof((1::rows(grid)):*grid,"row",0)
	//	}
	//else sheads=J(1,length(varlist),0)
	
	if (def) {
		charset("_dta","el_del_c",scofmat(inc))
		charset("_dta","el_del_w",wrap)
		}
	
	ds.with("lab chars")
	if (truish(use)) ds.readfile(use=pcanon(use,"",".dta"))
	else ds.readmem()
	if (!length(ds.vnames)) {
		printf("{res:No variables in dataset}\n")
		exit()
		}
	
	t.o_parse(out)
	
	t.body=J(2,4,"")
	t.body[1,]="Vars:",strofreal(ds.nvars,"%12.0fc"),"Record size:",MemSize(sum(ds.bytes))
	t.body[2,]="Obs:",strofreal(ds.nobs,"%12.0fc"),"Data size:",MemSize(ds.nobs*sum(ds.bytes))
	t.set(t._class,.,(1,3),"heading")
	t.set(t._vline,.,(1,3),t.Lsp1)
	t.padafter=0
	t.render()
	
	cspec=sctomat(ds.charget("_dta","el_del_c"))
	if (!truish(cspec)) cspec="irstype","nlabel","vlabel"
	wrapd=ds.charget("_dta","el_del_w")
	if (truish(wrapd)) wrap=strofreal(wrapd)
	
	dtach=ds.charget("_dta",incc')
	if (!novar) {
		if (truish(inc)) {
			cspec=inco?inc:(inc,cspec)
			cspec=dedup(vec(cspec))'
			}
		if (truish(icol=toindices(cspec:=="irstype"))) cspec=cut(cspec,1,icol),"irs2",cut(cspec,icol+1)
		drops=J(1,cols(cspec)+1,0)
		
		chosen=ds.varlist(vars,"all")
		vnames=ds.vnames[chosen]
		//secs=
		
		vlabs=J(0,3,"")
		head=J(1,1+length(cspec),"")
		t.body=J(length(chosen),1+length(cspec),"")
		head[1]="Variables"
		t.body[,1]=ds.vnames[chosen]'
		for (c=1;c<=length(cspec);c++) {
			if (cspec[c]=="irstype") {
				t.body[,c+1]=ds.sirtypes[chosen]'
				head[c+1..c+2]=J(1,2,vbar=t.defChar("{c |}","&#x2502;","&#x2193;"))
				t.body[,++c+1]=editvalue(strofreal(ds.bytes[chosen]'),".","L")
				}
			else if (cspec[c]=="stdtype") {
				head[c+1]="Type"
				t.body[,c+1]=othtypes(ds.sirtypes[chosen],ds.bytes[chosen])'
				}
			else if (cspec[c]=="format") {
				head[c+1]="Format"
				t.body[,c+1]=ds.formats[chosen]'
				}
			else if (cspec[c]=="nlabel") {
				head[c+1]="nLabel"
				t.body[,c+1]=ds.nlabels[chosen]'
				}
			else if (cspec[c]=="vlabel") {
				head[c+1]="vLabels"
				t.body[,c+1]=ds.vlabrefs[chosen]' // or vl
				labfile=pathto("_del.smcl","inst")
				sput(f="","{smcl}")
				sput(f,sprintf("{title:%s}",cut(use,1,1)))
				vlix=t.body[,c+1]:*0
				for (v=1;v<=length(ds.vlabnames);v++) {
					if (truish(ds.vlabnames[v])) {
						if (truish(ix=toindices(t.body[,c+1]:==ds.vlabnames[v]))) {
							vlix[ix]=J(length(ix),1,strofreal(v))
							onelab=*ds.vlabtabs[v]
							cpos=6:-strlen(onelab[,1])
							sput(f,sprintf("{marker %f}{hi:%s}\n",v,ds.vlabnames[v]))
							for (l=1;l<=rows(onelab);l++) {
								sput(f,sprintf("{col %f}%s{col 8}%s",cpos[l],onelab[l,1],onelab[l,2]))
								}
							sput(f,"{hline}")
							}
						}
					}
				t.body[,c+1]=t.setLinks("stata","view "+char((96,34,34))+labfile+char(34)+"##":+vlix:+char((34,39)),t.body[,c+1])
				fowrite(labfile,f)
				}
			else /*char*/ {
				head[c+1]=strproper(cspec[c])
				t.body[,c+1]=ds.charget(vnames,cspec[c])'
				if (!truish(t.body[,c+1])&truish(dtach[toindices(incc:==cspec[c])])) drops[c+1]=1
				}
			}
		if (truish(tcol=toindices(cspec:=="irstype"))) {
			hcol=tcol+1
			tcol=tcol+1-sum(drops[1..tcol])
			head=expand(head,.,-3)
			head[1,hcol]=t.setSpan("body","integer")+"/"+t.setSpan("body","real")+"/"+t.setSpan("hi1","string")
			head[2,hcol]=vbar
			head[2,hcol+1]="Size (bytes)"
			t.set(t._span,1,tcol,cols(t.body)-tcol)
			t.set(t._span,2,tcol+1,cols(t.body)-tcol-1)
			t.set(t._align,1,tcol,t.left)
			t.set(t._align,2,tcol+1,t.left)
			t.set(t._vline,.,tcol,t.Lsp1)
			t.set(t._class,toindices(t.body[,hcol]:=="s"):+3,tcol..tcol+1,"hi1")
			t.set(t._align,.,tcol+1,t.right)
			}
		
		t.body=head\t.body
		t.body=select(t.body,!drops)
		t.head=rows(head)
		t.stub=1
		t.set(t._align,.,.,t.left)
		if (wrap) t.set(t._wrap,.,.,-2)
		t.render()
		}
	
	use=pathparts(use,(23,3))
	ext=truish(use[1])+(cut(use,2)==".dta")
	phform=ext==2?sprintf("Stata %s (%s)",ds.vers[1],ds.vers[2]):""
	t.body="Filename",use[1]\"Format",phform\"Label",ds.dtalabel\incc',dtach
	t.body=select(t.body,tru2(t.body[,2]))
	t.stub=1
	t.set(t._wrap,.,.,-2)
	t.set(t._align,.,.,t.left)
	if (ext) t.set(t._hline,ext,.,t.Lsp1)
	t.render()
	
	if (!novar&t.o_mode=="html") {
		for (v=1;v<=length(ds.vlabnames);v++) {
			if (truish(ds.vlabnames[v])) {
				t.body=ds.vlabnames[v],""\*ds.vlabtabs[v]
				t.head=1
				t.set(t._span,1,1,2)
				t.set(t._align,.,.,t.left)
				t.render()
				}
			}
		}
	
	t.present(.)
	}

string scalar MemSize(real scalar bytes) { //>>def func
	scale=(bytes>=1000)+(bytes>=1000000) 
	return(strofreal(round(bytes/1000^scale,1),"%12.0fc")+substr(" kM",scale+1,1))
	}

end
