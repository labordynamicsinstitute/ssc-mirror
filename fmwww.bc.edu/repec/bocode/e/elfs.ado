*! 19dec2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program elfs
version 11

mata: DoIt()
end


version 11
mata:
void DoIt()  { //>>def func<<
	scmd=subcmdl(main=st_local("0"),("misc","outs:tata","outh:tml","oute:mail","col:ors", "f:acts","callst","inst:ance","st:artup","sql"),"none")
	if (!truish(scmd)) {
		stata("help elfs")
		return
		}
	syntaxl(main,NULL,NULL,opts="ya")
	
	if (scmd=="misc") Misc(opts)
	else if (scmd=="outs") Outs(opts)
	else if (scmd=="outh") Outh(opts)
	else if (scmd=="oute") Oute(opts)
	else if (scmd=="col") Col(opts)
	else if (scmd=="f") Facts(opts)
	else if (scmd=="callst") Callst(opts)
	else if (scmd=="inst") Inst(opts)
	else if (scmd=="st") Startup(opts)
	else if (scmd=="sql") Sql(opts)
	}

void Misc(string rowvector opts) { //>>def func
	class elfs_misc scalar elf
	elf.button(opts)
	}
void Outs(string rowvector opts) { //>>def func
	class elfs_out scalar elf
	elf.init(elf.mstata)
	elf.button(opts)
	}
void Outh(string rowvector opts) { //>>def func
	class elfs_out scalar elf
	elf.init(elf.mhtml)
	elf.button(opts)
	}
void Oute(string rowvector opts) { //>>def func
	class elfs_out scalar elf
	elf.init(elf.memail)
	elf.button(opts)
	}
void Col(string rowvector opts) { //>>def func
	class elfs_colors scalar elf
	elf.init()
	elf.button(opts)
	}
void Facts(string rowvector opts) { //>>def func
	class elfs_facts scalar elf
	elf.button(opts)
	}
void Callst(string rowvector opts) { //>>def func
	class elfs_callst scalar elf
	elf.button(opts)
	}
void Inst(string rowvector opts) { //>>def func
	class elfs_instance scalar elf
	elf.button(opts)
	}
void Sql(string rowvector opts) { //>>def func
	class elfs_sql scalar elf
	elf.button(opts)
	}
void Startup(string rowvector opts) { //>>def func
	class elfs_startup scalar elf_s
	class elfs_misc scalar elf_m
	
	optionel(opts,&(run="run"),opts)
	if (run) {
		if (elf_s.get("instance")=="on") stata("elfs instance, set")
		else if (truish(stid=elf_m.get("Stata appID"))) stata(sprintf(`"window manage maintitle "%s""',stid))
		if (elf_s.get("cdl")=="on") stata("noi cdl, p")
		if (elf_s.get("fromEditor")=="on") {
			stata("window menu clear")
			stata(`"window menu append item "stUser" "&From Editor" "fromEditor""')
			stata(sprintf(`"window menu append item "stUser" "&U Run Again" "do %s_fe_run.do""',seattel()))
			stata("window menu refresh")
			}
		return
		}
	
	elf_s.button(opts)
	}

	
end

