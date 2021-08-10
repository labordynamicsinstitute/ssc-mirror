*! 5apr2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program qlabel 
version 11.1
mata:DoIt()
end

version 11.1
mata:
void DoIt() { //>>def func<<
	syntaxl(st_local("0"),&(meat="!anything"),(&(name="n:ame="),&(filter="f:ilter"),&(mod="m:odify")))
	meat=tokel(meat)
	lpos=toindices(strpos(meat,`"""'))
	if (length(lpos)>1 & cut(lpos,2):-cut(lpos,1,-2)!=J(1,length(lpos)-1,2)) errel("Values & Labels should alternate...")
	qlabel(subinstr(subinstr(concat(meat[1..lpos[1]-2]," "),"(",""),")","") ,strtoreal(meat[lpos:-1]),subinstr(meat[lpos],char(34),""),name,filter,mod)
	}
end
