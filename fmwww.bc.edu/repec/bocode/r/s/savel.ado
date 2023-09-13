*! 26jan2011 
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program savel 
version 11.1 

mata: DoIt()
end


version 11.1
mata:
void DoIt() {
	syntaxl(st_local("0"),(&(path="anything"),&(ifin="ifin")), (&(keep="k:eep="),&(cd="cd"),&(pass="pass="),&(vers="vers:ion="),&(draft="drop:after"),&(make="m:akedirs"), &(label="l:abel="),&(grail="el_grail=")))
	
	if (sub=truish(ifin+keep)) { //this can be done on export now...
		if (path=="") errel("To save a subset of the current data, you must include a filename.")
		stata("preserve") //switch this to ds
		if (ifin!="") stata("keep "+ifin)
		if (strlen(keep)) keep=concat(varlist(keep)," ")
		if (truish(keep)) stata("keep "+keep)
		}
	if (truish(grail)) charset("_dta","el_grail",scofmat(el_grail(grail)))
	if (make) path=pathto(pcanon(path,"file dcn",".dta"))
	savel(path,pass+adorn(" vers(",vers,")"),sub)
	if (sub) stata("restore")
	if (draft&ifin!="") stata("drop "+ifin)
	
	if (cd) cdl("",path)
	}

end


