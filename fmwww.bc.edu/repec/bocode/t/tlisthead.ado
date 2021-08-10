*! 1may2013

* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program tlisthead
version 11
mata: DoIt()
end

version 11
mata:

void DoIt() { //>>def func<<
	syntaxl(st_local("0"),&(stuff="!anything"),(&(across="a:cross="),&(up="u:p="),&(begin="b:egin"),&(disp="di:splay")))
	across=firstof(across\"\")
	up=firstof(up\"|")
	hr=tokel(stuff,(across\up),"",del)
	if (anyof(del,up)&begin) errel("Can't specify 'begin' & use super-delimiters")
	hr=hr:+(hr:==""):*" " //no blanks, they indicate a spanned cell
	
	if (!begin) {
		x=findexternal("tlisthead_el")
		if (anyof(del,up)) begin=0
		else if (x==NULL) begin=1
		else if (cols(*x)==1) begin=0
		else begin=1
		}
	if (begin) {
		rmexternal("tlisthead_el")
		x=crexternal("tlisthead_el")
		*x=hr
		printf("{txt:New tlisthead started}\n")
		}
	else {
		if (x==NULL) errel("no top row found for tlisthead")
		align=toindices(colmax(strmatch(del,(""\up)))) //or sub sd for ""
		if (length(align)!=cols(*x)) errel("row does not match previous row")
		newx=J(rows(*x),cols(hr),"")
		newx[,align]=*x
		newx=newx\hr
		*x=newx
		}
	if (disp) show(*x)
	}
end
