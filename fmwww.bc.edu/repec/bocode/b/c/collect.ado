*! 15dec2010 
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program collect
version 11
mata: DoIt()

end 

version 11
mata:
void DoIt() { //>>def func<<
	syntaxl(st_local("0"),(&(paths="!anything"),&(ifin="ifin")), (&(app="ap:pend"),&(keep="k:eep="),&(pass="pass="),&(test="t:est")))
	colllect(paths,ifin,app,keep,pass,test)
	}

end
