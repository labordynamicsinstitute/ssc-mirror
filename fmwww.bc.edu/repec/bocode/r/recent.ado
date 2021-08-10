*! 23aug2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program recent
version 11.1

mata: DoIt()
end

version 11.1
mata:
void DoIt() { //>>def func<<
	class recentle_data scalar rld
	class sql_conn scalar sc
	class recentle_proj scalar prj
	
	scmd=subcmdl(main=st_local("0"),("d:ata","oth:er data","cdl","sql: path","pr:oject"),"oknone")
	
	if (scmd==""|scmd=="d") {
		syntaxl(main,NULL,&(wform="w:indow="))
		if (truish(wform)) {
			rld.get()
			rld.window(wform)
			}
		rld.list()
		}
	else if (scmd=="oth") rld.list("other")
	else if (scmd=="cdl") cdl("list","")
	else if (scmd=="sql") sc.list()
	else if (scmd=="pr") prj.list()
	}

end
