*! 29aug2007; 12jun2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program genif 
version 11

mata:DoIt()
end


version 11
mata:
void DoIt() { //>>def func<<
	first=tokel(st_local("0"),"=")
	steps=tokenstrip(tokel(first[2]))
	if (truish(steps[,(1,3,4)])) errel("All gen info must be inside parens")
	if (any(!tru2(steps[,2]))) errel("Empty condition...")
	steps=columnize(steps[,2],"if ")
	if (cols(steps)!=2) errel("Each expression except the final one must include 1 'if' condition")
	if (any(!tru2(cut(steps[,2],1,-2)))) errel("Each expression except the final one must include 1 'if' condition")
	steps[,2]=recode(steps[,2],("","1"))
	(void) st_addvar("byte",notdone=st_tempname())
	stata(sprintf("gen %s=%s if %s",first[1],steps[1,1],steps[1,2]))
	for (s=2;s<=rows(steps);s++) {
		stata(sprintf("replace %s=0 if %s",notdone,steps[s-1,2]))
		stata(sprintf("replace %s=%s if (%s) & %s",first[1],steps[s,1],steps[s,2],notdone)) //parens are required in case exp includes |
		}
	}
end
