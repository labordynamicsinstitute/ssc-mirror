*! 5jun2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program sqli
version 11

mata: DoIt()
end


version 11
mata:
void DoIt() { //>>def func<<
	ocmd=st_local("0")
	cmd=""
	
	if (!truish(ocmd)|ocmd=="<") {
		class recentle_data scalar rld
		class sql_conn scalar sc
		rld.ncmd="sql"
		rld.nmode="i"
		rld.get(ocmd)
		sc.userset(rld.ndir)
		sql_dnload(("i","re-query"),rld.ndetails,sc)
		return
		}
	while (regexm(ocmd," (from|join|table) +([^ ]+)")) {
		phrase=regexs(0)
		kw=regexs(1)
		tname=regexs(2)
		ppos=strpos(ocmd,phrase)
		cmd=cmd+substr(ocmd,1,ppos)+kw+" "+sql_rparts(tname,123)
		ocmd=substr(ocmd,ppos+strlen(phrase))
		}
	cmd=cmd+ocmd
	lcmd=strtrim(cut(tokel(cmd,";"),-1))
	dnld=substr(strlower(lcmd),1,strpos(lcmd," ")-1)=="select"
	if (dnld) sql_dnload(("i","query"),cmd)
	else sql_submit(cmd)
	}
end

