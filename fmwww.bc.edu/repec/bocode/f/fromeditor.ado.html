*!20may2015
program fromEditor
version 13

mata: DoIt()
do "`fedo'"
end

version 11
mata:

void DoIt() { //>>def func
	class ferunner scalar fer //theoretically, people could compose their own ferunner
	class elfs_misc scalar elf
	
	fe=cat(st_macroexpand(elf.get("fromEditor path")))
	if (substr(fe[1],1,9)!="*++start:") {
		printf("{txt:fromEditor found a non-fromEditor file.}\n")
		return
		}
	
	meta=substr(fe[1..5],strpos(fe[1..5],":"):+1)
	start=strtoreal(meta[1])
	fin=strtoreal(meta[2])
	rmode=meta[3] //switch with smode; rmode _could_ be done in stata
	path=meta[4]
	//if (regexm(path,"Untitled-[0-9]+$")) path="memory" //editor specific setting
	smode=meta[5]
	code=cut(fe,6)
	//fedo="run"
	
	lix=runningsum(strlen(code)):+(0::rows(code)-1)
	sl=toindices(start:<=lix)[1]
	fl=toindices(fin:<=lix)[1]
	if (smode=="selection"&fin!=start & fl==sl) {
		show(code[sl])
		show(start)
		fer.docode=substr(code[sl],start-(sl==1?-1:lix[sl-1]),fin-start)+eol()
	}
	else {
		if (smode=="selection") {
			if (sl>1) while (strpos(code[sl-1]," ///")>0) if (--sl==1) break
			if (fl<rows(code)) while (strpos(code[fl]," ///")>0) if (++fl==rows(code)) break
			}
		else { //part/all
			dobreak=elf.get("dobreak")
			parts=0\toindices(substr(strtrim(code),1,4):==/*"*---"*/dobreak)\rows(code)+1
			sl=pmax(1,parts[cut(toindices(sl:>=parts),-1)])
			fl=pmin(rows(code),parts[toindices(fl:<=parts)[1]])
			}
		fer.run(code,sl,fl,path)
	//	fedo=ferunner(code,sl,fl,path) 
		}
	
	if (smode=="selection"&rmode=="mata") fer.docode="mata:"+eol()+fer.docode+"end"+eol()
	fowrite(fedo=pathto(sprintf("_fe_%s.do",fer.doname),"i"),fer.docode)
	st_local("fedo",fedo)
	}

end

