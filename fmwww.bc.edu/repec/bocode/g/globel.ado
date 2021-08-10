*!13feb2016
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program globel
version 11

mata: DoIt()
end

version 11
mata:

void DoIt() { //>>def func
	mbits=expand(tokel(st_local("0"),"","","",1),2)
	if (!truish(mbits[1])) return
	st_global(mbits[1],mbits[2])
	if (truish(mbits[2])) stata("macro list "+mbits[1])
	else printf("{txt:%s:}\n",mbits[1])
	}
end
