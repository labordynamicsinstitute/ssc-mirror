*! 10oct2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program importlabels
version 11.2

mata: DoIt()
end

version 11.2
mata:
void DoIt() { //>>def func<<
	class dataset_dta scalar ds
	syntaxl(st_local("0"),(&(vars="!anything"),&(file="!using")))
	
	ds.with("data")
	ds.readfile(file)
	
	vars=varlist(vars,"",vlabs="")
	labs=uniqrows(vlabs')
	for (l=1;l<=rows(labs);l++) {
		names=columnize(labs[l],"->")
		if (length(names)==1) names=names,names
		rows=toindices(*ds.data[1]:==names[1])
		st_vldrop(names[2])
		vals=ds.sirtypes[2]=="s"?strtoreal((*ds.data[2])[rows]):(*ds.data[2])[rows]
		st_vlmodify(names[2],vals,(*ds.data[3])[rows])
		lvars=select(vars,vlabs:==labs[l])
		for (lv=1;lv<=length(lvars);lv++) st_varvaluelabel(lvars[lv],names[2])
		}
	}
end

