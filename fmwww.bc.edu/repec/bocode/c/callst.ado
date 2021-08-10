*! 27oct2010 
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program callst 
version 11.1

mata: DoIt()
end

version 11
mata:

void DoIt() { //>>def func
	syntaxl(st_local("0"),&(source="anything"),(&(dest="dest="),&(config="config=")))
	callst(source,dest,config)
	}
end
