*! 4oct2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program savesaslabs
version 11.2

mata: DoIt()
end

version 11.2
mata:
void DoIt() { //>>def func<<
	class dataset_dta scalar ds
	
	syntaxl(st_local("0"),&(source="!anything"),&(dest="!s:aving="))
	sas=columnize(ftostr(source),";")'
	sas=subinstr(subinstr(subinstr(sas,char(9)," "),char(10)," "),char(13)," ")
	while (any(regexm(sas,"  +"))) sas=regexr(sas,"  +"," ")
	isval=substr(sas,2,5):=="value"
	strval=substr(sas,8,1):=="$"
	vln=select(sas,isval:&!strval)
	vls=select(sas,isval:&strval)
	
	labeldata=J(0,3,"")
	for (i=1;i<=rows(vln);i++) {
		one=substr(vln[i],8)
		name=substr(one,1,strpos(one," ")-1)
		one=substr(one,strlen(name)+2)
		alab=J(strcount(one,"="),2,"")
		for (e=1;e<=rows(alab);e++) {
			eq=strpos(one,"=")
			alab[e,1]=substr(one,1,eq-1)
			qch=substr(one,eq+1,1)
			if (any(chars((34,39)):==qch)) {
				one=substr(one,eq+2)
				alab[e,2]=substr(one,1,qp=strpos(one,qch)-1)
				one=substr(one,qp+3)
				}
			else {
				one=substr(one,eq+1)
				qp=strpos(one," ")-1
				if (qp<0) qp=strlen(one)
				alab[e,2]=substr(one,1,qp)
				one=substr(one,qp+2)
				}
			}
		alab=select(alab,strlen(alab[,1]):&alab[,1]:!=".")
		if (any(strpos(alab[,1],","))) {
			next=J(sum(strcount(alab[,1],","))+rows(alab),2,"")
			j=1
			for (r=1;r<=rows(alab);r++) {
				x=columnize(alab[r,1],",")'
				next[j..j+rows(x)-1,1]=x
				next[j..j+rows(x)-1,2]=J(rows(x),1,alab[r,2])
				j=j+rows(x)
				}
			}
		else next=alab
		labeldata=labeldata\J(rows(next),1,name),next
		}
	
	for (i=1;i<=rows(vls);i++) {
		one=substr(vls[i],8)
		one=regexr(one,"\\$ +","") //extra
		name=substr(one,1,strpos(one," ")-1)
		one=substr(one,strlen(name)+2)
		alab=J(strcount(one,"="),2,"")
		for (e=1;e<=rows(alab);e++) {
			eq=strpos(one,"=")
			alab[e,1]=substr(one,1,eq-1)
			qch=substr(one,eq+1,1)
			if (any(chars((34,39)):==qch)) {
				one=substr(one,eq+2)
				alab[e,2]=substr(one,1,qp=strpos(one,qch)-1)
				one=substr(one,qp+3)
				}
			else {
				one=substr(one,eq+1)
				qp=strpos(one," ")-1
				if (qp<0) qp=strlen(one)
				alab[e,2]=substr(one,1,qp)
				one=substr(one,qp+2)
				}
			}
		alab=select(alab,strlen(alab[,1]):&alab[,1]:!=".")
		if (any(strpos(alab[,1],","))) {
			next=J(sum(strcount(alab[,1],","))+rows(alab),2,"")
			j=1
			for (r=1;r<=rows(alab);r++) {
				x=columnize(alab[r,1],",")'
				next[j..j+rows(x)-1,1]=x
				next[j..j+rows(x)-1,2]=J(rows(x),1,alab[r,2])
				j=j+rows(x)
				}
			}
		else next=alab
		labeldata=labeldata\J(rows(next),1,name),next
		}
	
	vars=select(sas,substr(sas,2,6):=="format")
	vars=cut(tokens(vars),2)
	if (mod(cols(vars),2)) errel("gotta fix for uneven parameters")
	vars=colshape(vars,2)
	
	ds.gen("","name","str20")
	ds.gen("","value","str20")
	ds.gen("","label","str244")
	ds.nobs=rows(labeldata)
	for (v=1;v<=3;v++) *ds.data[v]=labeldata[,v]
	ds.chars=("_dta","assign",concat(concat(vars," "),eol()))
	ds.writefile(dest)
	}

end
