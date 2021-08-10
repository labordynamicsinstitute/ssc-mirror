*! 31mar2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program sql
version 11
mata: DoIt()
end

version 11
mata:

void DoIt() { //>>def func<<
	class tabel scalar t
	class sqldo scalar sd
	class sql_meta scalar sm
	class sql_conn scalar sc
	class dataset_dta scalar ds
	
	scmd=subcmdl(main=st_local("0"), ("p:ath","get","put","fin:ish","move","merge","write","do","cols","tables","dbd:escription","clear"))
	if (scmd=="p") {
		sc.userset(main)
		sc.add()
		}
	else if (scmd=="get") sqlget(main)
	else if (scmd=="put") {
		syntaxl(main,(&(dest="anything"),&(ifin="ifin")),&(keep="keep="))
		if (sub=truish(ifin+keep)) {
			ds.with("d l c")
			ds.readmem()
			if (ifin!="") stata("keep "+ifin)
			if (strlen(keep)) keep=concat(varlist(keep)," ")
			if (truish(keep)) stata("keep "+keep)
			}
		
		sql_upload(dest)
		sm.fromdta()
		if (truish(sm.sql)) { //really, any field...
			sm.dest(dest)
			printf("{txt:Putting meta-data} {res:%s}\n",sm.t_name[1]) //will t always be identical? think it's multi-query/table
			sm.tosql()
			}
		
		if (sub) ds.writemem()
		}
	else if (scmd=="fin") {
		ds.with("l c")
		ds.readmem()
		ds.writefile(blob=pathto("_dtameta.dta"))
		ds.with("d l c")
		ds.readmem("clear")
		st_dropvar(.)
		st_addobs(1)
		stata(sprintf(`"gen strL dta=fileread("%s") in 1"',blob))
		sc.get()
		schema=sc.field("schema")
		sc.merge(sc.hparse("."+sm.home_s))
		sql_upload(sprintf("dta_%s_%s",schema,main),sc) //name format needs to be elsewhere
		ds.writemem()
		}
	else if (scmd=="move") {
		syntaxl(main,&(from="!anything"),&(to="!to="))
		sql_move(from,to)
		}
	else if (scmd=="merge") {
		syntaxl(main,&(existing="anything"),(&(into="!into="),&(keep="k:eep")))
		into=strtrim(tokel(into,":"))
		if (cols(into)!=2) errel("into() must be specified as {it:table}{hi::}{query-name}")
		sm.fromsql(existing)
		sqlmerge(into,sm,keep)
		}
	else if (scmd=="write") sql_write(main)
	else if (scmd=="do") sd.sqldo(main)
	else if (scmd=="cols") {
		syntaxl(main,&(cpat="anything"),(&(alias="a:lias="),&(path="p:ath=")))
		if (truish(alias)) alias=subinstr(alias,".","")+"."
		cpat=expand(tokel(cpat,(" "\"."),"","",1),2)
		if (!truish(cpat[1])) errel("A table must be specified.")
		sc.userset(path)
		columns=strlower(colshape(sql_submit(sprintf("select column_name, ordinal_position from information_schema.columns where table_schema='%s' and table_name='%s'",sc.field("schema"),cpat[1]),sc)[,2],2))
		cosort_((&columns,&strtoreal(columns[,2])),2)
		columns=select(columns[,1],asvmatch(columns[,1],firstof(cpat[2]\"*")))
		t.body=concat(columns," ")
		t.set(t._wrap,.,.,0)
		t.set(t._align,.,.,t.left)
		t.present("")
		display("{p 0 0 0 1000}"+concat(alias:+columns,", "))
		}
	else if (scmd=="tables") {
		syntaxl(main,&(tpat="anything"),&(path="p:ath="))
		sc.userset(path)
		t.body=sql_tables(tpat,sc)
		t.body="Tables"\sc.humstr()\t.body
		t.head=2
		t.set(t._align,.,.,t.left)
		t.set(t._hline,1,.,t.Lmajor)
		t.present("-")
		}
	else if (scmd=="dbd") sqldb(main)
	else if (scmd=="clear") {
		syntaxl(main,&(tables="anything"),(&(wsch="s:chema"),&(path="p:ath=")))
		sc.userset(path)
		stables=sql_tables("",sc)
		dtabs=asvmatch(stables,tables,"mult")
		t.body="Tables to clear",""\sc.humstr(),""\dtabs:*t.defChar("{c 164}","*"),stables
		t.head=2
		t.set(t._span,(1,2),1,2)
		t.set(t._align,(1,2),1,t.left)
		t.set(t._hline,1,.,t.Lmajor)
		t.set(t._align,.,.,t.left)
		t.set(t._class,.,1,"hi1")
		t.present("-")
		sql=concat(adorn("drop table "+sc.field("schema")+".",select(stables,dtabs),";"),"")
		if (sum(dtabs)==rows(stables)&wsch) {
			sql=sql+"drop schema "+sc.field("schema")
			display(`"{txt:Drop all tables, and schema?} {matacmd sql_submit("el_holdcode"):Yes}"')
			}
		else display(`"{txt:Drop starred tables?} {matacmd sql_submit("el_holdcode"):Yes}"')
		st_global("el_holdcode",sql)
		//el_holdcode literal
		}
	else errel("Unknown sql command",cmd1)
	}

string vector sql_tables(string scalar tspec, class sql_conn scalar sc) { //>>def func
	tspec=firstof(tspec\"*")
	tables=sql_submit(sprintf("select table_name from information_schema.tables where table_schema='%s'",sc.field("schema")),sc) //submit to preserve any downloaded data
	tables=sort(strlower(tables[,2]),1)
	tables=selectv(tables,asvmatch(tables,tspec,"mult"),"c")
	return(tables)
	}

end
