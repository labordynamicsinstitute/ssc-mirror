*!1feb2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program rrc
version 11.1

mata: DoIt()
end

version 11.1 
mata:
void DoIt() { //>>def func<<
	class dataset scalar ds
	
	syntaxl(st_local("0"),&(fname="!using"),(&(ptid="pt:id="),&(ixdate="ix:date="),&(drugid="drug:id="), &(prdate="prdate="),&(prdays="prdays="),&(span="!time:span=")))
	if (strlen(ptid)) {
		vars=varlist((ptid,ixdate,drugid,prdate,prdays))
		stata(sprintf("order %s",concat(vars," ")))
		}
	else vars=st_varname(1..5)
	ptid=vars[1];ixdate=vars[2];drugid=vars[3];prdate=vars[4];prdays=vars[5]
	span=strtoreal(columnize(span,"/"))
	if (length(span)!=3|hasmissing(span)) errel("The timespan option must have 3 numbers like: timespan(starting offset/period length/ending offset)}")
	np=trunc((span[3]-span[1]+1)/span[2])
	pdays=span[2]
	if (st_isstrvar(drugid)) errel("Drug ID must be a numeric variable (value labels are a good idea).")
	fname=pcanon(fname,"file","dta")
	printf("{txt:Begin:} {res:%s}\n",c("current_time"))
	st_keepvar(1..5)
	stata(sprintf("drop if %s<%s+%f | %s>%s+%f",prdate,ixdate,span[1],prdate,ixdate,span[3]))
	stata(sprintf("drop if %s<=0",prdate))
	stata(sprintf("sort %s %s %s %s",ptid,ixdate,drugid,prdate))

	st_view(V=.,.,drugid)
	drugs=uniqrows(V)
	unlink(fname)
	fid=fopen(fname,"w")
	C=bufio()
	ds.readmem()
	writeHeader(C,fid,ds.bytes[1],ds.sirtypes[1],strofreal(drugs), firstof((st_vlmap(firstof((st_varvaluelabel(drugid),"theres_none")),drugs)'\strofreal(drugs)'))')
	
	ptbfmt="%"+strofreal(ds.bytes[1])+subinstr(subinstr(ds.sirtypes[1],"i","b"),"r","z")
	ndr=length(drugs)
	rwidth=(ds.bytes[1]+2+2+4*ndr)
	buffer=(np*rwidth)*char(0)
	npt=0
	
	i=1
	while (i<=st_nobs()) {
		ptid=el_data_(i,1)
		dtid=_st_data(i,2)
		adh=J(np,ndr,0)
		for (dr=1;dr<=ndr;dr++) {
			if (_st_data(i,3)!=drugs[dr]) continue
			
			mark=dtid+span[1]
			on=0
			off=0
			thisp=1
			while (el_data_(i,1)==ptid & _st_data(i,2)==dtid & _st_data(i,3)==drugs[dr]) {
				fillday=_st_data(i,4)
				supdays=_st_data(i,5)
				if (fillday>mark) {
					off=off+fillday-mark
					if (off+on>=pdays) {
						adh[thisp,dr]=on/pdays
						thisp=thisp+trunc((off+on)/pdays)
						if (thisp>np) break
						off=mod(off+on,pdays)
						on=0
						}
					mark=fillday
					}
				on=on+supdays
				if (off+on>=pdays) {
					adh[thisp,dr]=(pdays-off)/pdays
					if (extra=min((np-thisp,trunc((off+on)/pdays)-1))) adh[thisp+1..thisp+extra,dr]=J(extra,1,1)
					thisp=thisp+1+extra
					if (thisp>np) break
					on=mod(off+on,pdays)
					off=0
					}
				mark=mark+supdays
				++i
				}
			if (on & thisp<=np) adh[thisp,dr]=on/pdays
			while (el_data_(i,1)==ptid & _st_data(i,2)==dtid & _st_data(i,3)==drugs[dr]) ++i //gotta use _st for i>N
			if (el_data_(i,1)!=ptid | _st_data(i,2)!=thisid) break
			}
		ixstart=trunc(span[1]/pdays)
		for (r=0;r<np;r++) {
			bufput(C,buffer,rwidth*r,ptbfmt,ptid)
			bufput(C,buffer,rwidth*r+ds.bytes[1],"%2b",(dtid,ixstart+r))
			bufput(C,buffer,rwidth*r+ds.bytes[1]+4,"%4z",adh[r+1,])
			}
		++npt //pt-date counter
		fwrite(fid,buffer)
		}
	fseek(fid,6,-1)
	fbufput(C,fid,"%4bu",npt*np) //# of obs
	fclose(fid)
	
	printf("{txt:End:} {res:%s}",c("current_time"))
	usel(fname)
	}


void writeHeader(real colvector C, real scalar fid, real scalar ptbytes, string scalar ptsir, string vector drugids, string vector druglabs) { //>>def func<<
	stend=char(0)
	ndr=length(drugids)
	ptdtype=ptbytes*(ptsir=="s")+(ptsir=="i")*(250+ptbytes-(ptbytes==4))+(ptsir=="r")*(253+ptbytes/4)
	
	fbufput(C,fid,"%1bu",(114,byteorder(),1,1)) //format v10, byteorder,filetype,unused
	fbufput(C,fid,"%2bu",3+ndr) //nvars
	fbufput(C,fid,"%4bu",0) //nobs, rewritten later
	fbufput(C,fid,"%81s","rrc output"+stend) //dataset label
	fbufput(C,fid,"%18s",c("current_date")+stend) //date/time
	fbufput(C,fid,"%1bu",(ptdtype,252,252,J(1,ndr,254))) //ptid ,ixdate-int,period-int,adherence-float
	fbufput(C,fid,"%33s",("ptid","ixdate","period"):+stend) //varnames
	fbufput(C,fid,"%33s","d":+drugids:+stend) //drugvar names
	fbufput(C,fid,"%2bu",(1,2,3,J(1,ndr+1,0))) //sorted pt,ixdate,period,end,post-sort
	fbufput(C,fid,"%49s",("%12.0g","%td","%4.0f",J(1,ndr,"%3.2f")):+stend) //ptid,ixdate,period,r format
	fbufput(C,fid,"%33s",J(1,3+ndr,stend)) // vallabels
	fbufput(C,fid,"%81s",("patient ID","index date",""):+stend) //varlab
	fbufput(C,fid,"%81s",druglabs:+stend) //drug labels
	fbufput(C,fid,"%5s",5*stend) //5 0s for chars
	}

end
