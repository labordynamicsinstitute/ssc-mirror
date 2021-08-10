*! 20dec2012 redo
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program toview 
version 11

mata: DoIt()
end

version 11
mata:
void DoIt() { //>>def func<<
	
	bits=columnize(" "+st_local("0"),":") 
	syntaxl(bits[1],&(name="anything"),&(app="a:ppend"))
	
	name=adorn("_",name)
	file=pathto("_toview"+name+".smcl","inst")
	stata(sprintf(`"qui log using "%s", %s smcl"',file,("replace","append")[1+app]))
	cmds=columnize(bits[2],";")
	for (c=1;c<=length(cmds);c++) stata(cmds[c])
	stata("qui log close")
	stata(sprintf("view %s##|%s",file,name))
	}
end 




