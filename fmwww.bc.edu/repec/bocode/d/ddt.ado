*> add time option, use mods to set var types
*!27apr2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program ddt
version 13

mata: DoIt()
end

version 11
mata:

void DoIt() { //>>def func<<
	class tspoof scalar t
	class dataset scalar ds
	
	syntaxl(st_local("0"),&(dvars="anything"), (&(dt="dt+"),&(dtf="dtf:ormat="),&(df="df:ormat="),&(sord="str:ingorder="),&(go="go")))
	dtf=firstof(dtf\"%tcCCYY-NN-DD_HH:MM:SS")
	df=firstof(df\"%tdCCYY-NN-DD")
	sord=firstof(sord\"YMD")
	if (truish(dvars)) dvars=varlist(dvars)
	else dvars=select(varlist("*"),asvmatch(varlist("*"),("*datetime *date")))
	if (truish(dt)) {
		if (*dt=="") *dt="*datetime"
		todt=asvmatch(dvars,*dt,"multi")
		}
	else todt=J(1,length(dvars),0)
	if (!truish(dvars)) {
		printf("{txt:No date/datetime variables found}")
		return
		}
	oforms=charget(dvars,"@form")
	(void) st_addvar("double",nvars=st_tempname(length(dvars)))
	
	samp=cut(jumble(1::st_nobs()),1,10)
	sn=pmin(st_nobs(),3)
	t.labset("v",1,"","l")
	t.labset("n",1,"","u")
	t.body=pad(("Variable","Orig","Now"),vec(expand(t.getn(dvars)[,1]',.,sn)),"\")
	if (!go) t.body[1,3]=t.setSpan("hi2","Preview")
	for (d=1;d<=length(dvars);d++) {
		el_view(Vd=.,.,dvars[d])
		el_view(Vn=.,.,nvars[d])
		if (eltype(Vd)=="string") {
			if (frdt=max(strlen(strtrim(Vd)))>15) Vn[.]=clock(Vd,sord+"hms")
			else Vn[.]=date(Vd,sord)
			}
		else {
			Vn[.]=Vd
			charset(dvars[d],"@form",(frdt=max(abs(Vd))>1000000)?dtf:df)
			}
		if (frdt&!todt[d]) Vn[.]=dofc(Vn)
		else if (!frdt&todt[d]) Vn[.]=cofd(Vn)
		charset(nvars[d],"@form",todt[d]?dtf:df)
		
		if (truish(off=toindices(tru2(Vd,"zok"):!=tru2(Vn,"zok")))) errel("Some dates resulted in missing values",dvars[d]\t.getv(dvars[d],Vd[off]))
		
		t.body[(d-1)*sn+2..(d-1)*sn+1+sn,2]=t.getv(dvars[d],cut(Vd[samp],1,sn))
		t.body[(d-1)*sn+2..(d-1)*sn+1+sn,3]=t.getv(nvars[d],cut(Vn[samp],1,sn))
		if (eltype(Vd)=="string") t.set(t._class,(d-1)*sn+2..(d-1)*sn+1+sn,2,"hi1")
		stata(sprintf("order %s, after(%s)",nvars[d],dvars[d]))
		}
	
	t.head=1
	t.stub=1
	t.present("-")
	if (go) {
		st_dropvar(dvars)
		stata("qui compress")
		for (d=1;d<=length(dvars);d++) st_varrename(nvars[d],dvars[d])
		}
	else charset(dvars,"@form",oforms)
	}
end
