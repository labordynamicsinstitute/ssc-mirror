*! 26oct2011
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program pair, 
version 11

mata: DoIt()
end


version 11
mata:
void DoIt() { //>>def func<<
	
	syntaxl(st_local("0"),(&(two="!anything"),&(ifin="ifin")),(&(keep="k:eep")))
	two=varlist(two,"min(2) max(2)")
	if (sum(strvars(two))!=1) errel("Exactly one of the variables must be string")
	settouse(touse,ifin)
	
	nix=toindices(!strvars(two))
	both=uniqrows(el_sdata(.,two,touse))
	if (rows(uniqrows(both[,nix]))<rows(both)) errel("A number cannot map to more than one label")
	
	st_vlmodify(two[nix]+"_pair",strtoreal(both[,nix]),both[,3-nix])
	st_varvaluelabel(two[nix],two[nix]+"_pair")
	if (!keep&!truish(ifin)) st_dropvar(two[3-nix])
	}
end
