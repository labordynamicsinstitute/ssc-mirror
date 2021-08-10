*!25mar2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program rxdose
version 11

mata: DoIt()
end


version 11.1 
mata:
void DoIt() { //>>def func<<
	class dataset scalar ds
	
	syntaxl(st_local("0"),&(ratio="anything"),(&(from="from="),&(to="to="),&(ptid="pt:id="),&(drugid="drug:id="), &(prdate="prdate="),&(prdays="prdays="),&(ddose="ddose=")))
	ratio=trunc(strtoreal(tokel(ratio,"/")))
	if (length(ratio)!=2) errel("The main parameter must be specified as {hi:{it:supply}/{it:window}}")
	if (hasmissing(ratio)) errel("A number must be supplied for both {hi:supply} and {hi:window}")
	sup=ratio[1]
	wind=ratio[2]
	
	if (strlen(ptid)) {
		vars=varlist((ptid,drugid,prdate,prdays,ddose))
		stata(sprintf("order %s",concat(vars," ")))
		}
	else vars=st_varname(1..5)
	ptid=vars[1];drugid=vars[2];prdate=vars[3];prdays=vars[4];ddose=vars[5]
	from=date(from,"MD20Y")
	to=date(to,"MD20Y")

	printf("{txt:Begin:} {res:%s}\n",c("current_time"))
	st_keepvar(1..5)
	stata(sprintf("drop if mi(%s,%s,%s,%s,%s)",ptid,drugid,prdate,prdays,ddose))
	stata(sprintf("drop if %s<=0|%s<=0",prdate,ddose)) //??
	if (truish(to)) stata(sprintf("drop if %s>%f",prdate,to))
	stata(sprintf("sort %s %s %s",ptid,drugid,prdate))
	if (truish(from)) stata(sprintf("by %s %s: drop if %s[_N]<%f",ptid,drugid,prdate,from))
	
	el_view(vp,.,ptid)
	el_view(vd,.,drugid)
	cases=toindices(differ(vp,"prev","ftrue"):|differ(vd,"prev","ftrue"))\st_nobs()+1
	ds.gen(ptid)
	ds.gen(drugid)
	ds.gen("","asof","int","earliest date of therapy","%d")
	ds.add(length(cases)-1)
	
	cn=rows(cases)
	for (c=1;c<cn;c++) {
		if (!mod(c,10000)) printf("{txt}Case {res:%f} of {res:%f}; {res:%s}\n",c,cn,c("current_time"))
		(*ds.data[1])[c]=el_data_(cases[c],1)
		(*ds.data[2])[c]=el_data_(cases[c],2)
		bdate=st_data((cases[c],cases[c+1]-1),prdate)
		st_view(days,(cases[c],cases[c+1]-1),prdays)
		st_view(dose,(cases[c],cases[c+1]-1),ddose)
		
		fdate=bdate:+days\.
		bdate=bdate\fdate[rows(fdate)-1]
		if (truish(from)) beg=fin=toindices(bdate:>=from)[1]
		else beg=fin=1
		done=0
		cmax=rows(bdate)
		while (!done&beg<cmax) {
			while (fdate[fin]-bdate[beg]<wind) ++fin
			if (fdate[fin]==.) done=--fin
			if (sum(dose[beg..fin]:*days[beg..fin])- dose[fin]*(fdate[fin]-pmin(fdate[fin],pmax(bdate[fin],bdate[beg]+wind)))>=sup) {
				(*ds.data[3])[c]=bdate[beg]
				break
				}
			while (fdate[fin]-bdate[beg]>=wind) ++beg
			}
		}
	ds.writemem()
	printf("{txt:End:} {res:%s}\n",c("current_time"))
	}
end


