*! 9aug2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program chlist
version 11
mata:DoIt()
end

version 11
mata:
void DoIt() { //>>define function<<
	class tabel scalar t
	class dataset scalar ds
	
	syntaxl(st_local("0"),&(vlist="anything"),(&(clist="c:hars="),&(dta="d:ta"),&(swap="s:wap"),&(out="out=")))
	vlist="_dta"*(vlist==""|dta),varlist(vlist,"all nfrep")
	if (!length(vlist)) {
		printf("{txt:No variables found}\n")
		return
		}
	ds.with("chars")
	ds.readmem()
	clist=varlistk(uniqrows(ds.chars[,2]),clist,"all nfrep")
	if (!length(clist)) {
		printf("{txt:No chars found}\n")
		return
		}
	in=vmap(ds.chars[,1],vlist):&vmap(ds.chars[,2],clist)
	chtab=select(ds.chars,in)
	if (!length(chtab)) {
		printf("{txt:No matching vars/chars found}\n")
		return
		}
	
	stub=vlist'
	//stub=dedup(chtab[,1],1)
	head=dedup(chtab[,2],1)
	del=charsubs(chtab,1)
	rmap=vmap(concat(pairs(stub,head),del),concat(chtab[,1..2],del,"r"))
	data=J(rows(rmap),1,"")
	data[toindices(rmap)]=chtab[select(rmap,rmap),3]
	data=rowshape(data,rows(stub))
	
	t.body="",head'\stub,data
	t.head=1
	t.stub=1
	if (swap) t.body=t.body'
	t.present(out)
	}
end
	