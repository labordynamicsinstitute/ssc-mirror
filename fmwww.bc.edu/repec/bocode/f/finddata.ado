*! 5dec2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program finddata
version 11

mata: DoIt()
end

version 11
mata:

void DoIt() { //>>def func<<
	syntaxl(st_local("0"),(&(kvlist="!anything"),&(bbpath="!using"),&(ifin="ifin")), (&(copy="c:opy="),&(pass="pass=")),flags="therest")
	finddta(kvlist,bbpath,ifin,copy,flags,pass)
	}

end

