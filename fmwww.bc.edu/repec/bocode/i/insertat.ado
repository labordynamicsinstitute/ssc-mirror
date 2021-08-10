*! 223oct2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program insertat

mata:DoIt()
end

version 11
mata:


void DoIt() { //>>def func<<
	bits=strtoreal(tokel(st_local("0"),"*"))
	(void) st_addvar("int",rn=st_tempname())
	stata(sprintf("qui replace %s=_n",rn))
	st_view(V=.,.,rn)
	if (missing(V)) errel("The dataset is too large for insertat")
	st_addobs(length(bits)==2?bits[2]:1)
	stata(sprintf("qui recode %s (.=%f)",rn,bits[1]-.5))
	stata(sprintf("sort %s",rn))
	}

end


