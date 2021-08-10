*! 19oct2011
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program randid , sortpreserve
version 11.1

mata: DoIt()
end

version 11.1
mata:
void DoIt() {
	class dataset_dta scalar ds
	syntaxl(st_local("0"),&(vars="!anything"),(&(range="r:ange="),&(xw="xw:alk=")))
	vars=columnize(vars,"=")
	if (length(vars)!=2) errel("You must specify {hi:newvar}={hi:oldvarlist}")
	nvar=vars[1]
	if (!missing(_st_varindex(nvar))) errel(sprintf("'%s' already exists in the dataset",nvar))
	ovars=varlist(vars[2])
	if (!length(ovars)) errel(printf("No original ID variables found (%s)",vars[2]))
	if ((str=length(somevars(ovars,"str")))!=length(ovars)&str) errel("Original ID vars must be all numeric or all string")
	
	if (str) st_sview(vo=.,.,ovars)
	else st_view(vo=.,.,ovars)
	size=rows(okey=uniqrows(vo))
	
	range=tokens(range)
	if (!length(range)) range=(1,size)
	else if (length(range)==1) range=strtoreal(range),10^(strlen(strtrim(range)))-1
	else range=strtoreal(range[1..2])
	if (range[2]-range[1]+1<size) errel("There are more existing IDs than possible numbers in the specified range")
	
	stata("sort "+concat(ovars," "))
	rids=jumble(range[1]::range[2])[|1\size|]
	(void) st_addvar("long",nvar)
	st_view(vn=.,.,nvar)
	rix=1
	vn[1]=rids[1]
	for (dix=2;dix<=rows(vn);dix++) {
		if (vo[dix,]!=vo[dix-1,]) ++rix
		vn[dix]=rids[rix]
		}
	
	if (strlen(xw)) {
		xw=pcanon(xw)
		ds.with("d")
		ds.readmem()
		ds.shrink("keep",ds.varlist((ovars,nvar)))
		ds.data=J(1,ds.nvars,NULL)
		for (v=1;v<ds.nvars;v++) ds.data[v]=&(okey[,v])
		ds.data[v]=&rids
		ds.nobs=size
		ds.writefile(xw)
		}
	printf("{txt:%f random values created in %s}\n",size,nvar) 
	}
end


