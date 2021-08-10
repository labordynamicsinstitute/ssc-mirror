*! 26jan2011
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program usel
version 11.1

mata: DoIt()
end

version 11.1
mata:
void DoIt() {
	
	syntaxl(st_local("0"),(&(path="anything"),&(ifin="ifin")),(&(keep="k:eep="),&(cd="cd"), &(sys="sys"),&(pass="pass=")))
	if (sys) {
		syspath=findfile(pathparts(path,2)+firstof(pathparts(path,3)\".dta"))
		if (syspath=="") errel(path+" not found in adopath")
		else path=syspath
		}
	usel(path,ifin,keep,pass)
	if (strlen(keep)) printf("{p2col 0 15 15 3:{txt:Kept %f vars:} {txt:%s}}{p_end}",st_nvar(),concat(varlist("","all")," "))
	
	if (cd) cdl("d","")
	}
end
