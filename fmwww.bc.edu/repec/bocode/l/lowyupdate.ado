*!19jun2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program lowyupdate
version 11
syntax [anything],[Compile]

qui mata mata mlib index
mata: DoIt()

if (!mi("`compile'")&!mi("`dopath'")) {
	if (mi("`anything'")) {
		do `"`dopath'"'
		}
	else {
		do `"`dopath'"' $el_base/v`anything'
		}
	}
end

version 11
mata:
void DoIt() {
	if (!direxists(c("sysdir_plus")+"l")) mkdir(c("sysdir_plus")+"l") //mf
	lsd=findfile("lowyseattle.do")
	if (strlen(lsd)) {
		st_local("dopath",lsd)
		dvers=substr(cat(lsd,1,1),3)
		}
	else dvers="None"
	printf("{space 1}{txt:Source version (ie, newest update):} {res:%s}\n",dvers)
	
	lsm=findfile("lowyseattle.mlib")
	if (strlen(lsm)) {
		stata(`"capture mata: st_local("sv",lowyseattlev())"')
		mvers=st_local("sv")
		b1=strpos(mvers,"[")+1
		b2=strpos(mvers,"]")
		sv=strtoreal(substr(mvers,b1,b2-b1))
		mvers=substr(mvers,b2+2)
		}
	else mvers="None"
	printf("{txt:Library version (ie, current):}{space 6} {res:%s}\n",mvers)
	
	if (length(sv)) {
		printf("{txt:Library compiled under Stata:}{space 7} {res:%f}\n",sv)
		if (mvers!="None"&sv>c("stata_version")) printf("{err:The existing library was compiled in a later version of Stata than this one; it can't be used.}\n")
		}
	if (strlen(lsd)) printf(`"\n{txt:Click {stata "lowyupdate, compile":compile} to create a working library from the source code (for versions 11+)}\n"')
	}
end

