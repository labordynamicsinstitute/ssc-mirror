*! 28oct2010
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program cdl 
version 11.1

mata: DoIt()
end

version 11
mata:

void DoIt() { //>>def func
	maybe=expand(tokel(blob=st_local("0"),"","","",1),2)
	scmd=ocanon("cdl sub",maybe[1],("<","d:ata"),"nfok")
	syntaxl(truish(scmd)?maybe[2]:blob,&(path="anything"),&(proj="p:roject"))
	cdl(scmd,path,proj)
	}
end
