*!  pathdiag.ado	Version 4.0		RL Kaufman		10/4/2017

***		1.0  Draws path daigram with only focal var effects. Called by GFI.ADO using info in global macros from definefm.ado 
***		2.0  Renamed Version 1.0 as pathdiagfull.ado which shows ALL paths& variables
***			 This version of PATHDIAG isolates focal variable's paths in simpler to read diagram
***			NOTE:Print from graph window in order to set to landscape orientation
***		2.1  Added options TITLE BOXWIDTH YGAP XGAP.  Fixed spacing issues.
***		3.0 Added  functionality for mlogit. 
***		4.0 Changed bform() to ndigits() option

program pathdiag, rclass
version 14.2
syntax  ,  eqnow(string) [ TItle(string asis) name(string) NDIGits(integer 3) EQName(string asis) ///
	BOXWidth(real 1.25) ygap(real .625) xgap(real 1.25) ]


tempname bmat
tempvar ybox xbox boxwd ytail xtail yhead xhead boxtext

disp as res "Path Diagram with Only Paths & Coefficients for Focal Variable"

quiet {
mat bmat=e(b)
loc nmtxt "`eqnow'"
if ${eqnum$sfx2} ==1 loc nmtxt "1"
loc pname "Path`nmtxt'"
if "`name'" != "" loc pname `=strtoname("`name'`nmtxt'",0)'


***  mvarn$sfx}= #of moderators	 mcnum#$sfx}= # of nominal dummies, 1 if interval    
***		madj# = adjust y-coord for 2way textbox with > 6 lines
*** 	yinc & xinc are increments between textboxes on x&y axes
***		bx# is width of textbox(% of axis)   Maineffect box (x=0 to bx1)   2way box (x=bx1+xinc to  ... + bx2)  3way box (x=bx1+xinc+bx2 to  ... + bx3) 
***		bxw=rescaling factor for bxwidths

loc yinc=`ygap'
loc xinc=`xgap'
loc bx1=1.25
loc bx2=1.75
loc bx3=1.25
loc bxw=`boxwidth'
loc madj1=0

forvalues mi=1/${mvarn$sfx} {
	loc ii=`mi'-1
	if `mi' > 1 loc madj`mi'= max(0,(${fcnum$sfx}*${mcnum`ii'$sfx}-6)/6*`yinc') +`madj`ii''
	if "${fm1m2list$sfx}"!=""  & `mi'==3 loc madj3=  max(0,`madj`ii'', /// 
	    (${mcnum1$sfx}*${mcnum2$sfx}-6)/6*`yinc' +`madj`ii'', (${fcnum$sfx}*${mcnum1$sfx}*${mcnum2$sfx}-6)/6*`yinc')
}
loc ii=${mvarn$sfx}+1
loc madj`ii'=`madj${mvarn$sfx}'
***		ymax=max/starting y coord (axes rescaled before graph made)		pdtxt[] = y,x and boxwidth for textbox
***		txt[] = MATA string matrix with textbox title	pdarr[] = coord for arrow y&x tail y&x head
loc ymax=  (${mvarn$sfx}+2) * `yinc' + `madj${mvarn$sfx}'
mat pdtxt=J(50,3,.)
mata: txt=J(50,1," ")
mat pdarr=J(100,4,.)


*** 	Define Main Effect Box and Arrows to  2-way Boxes: Focal Var	lasty=y coord of box, use to define arrows
***		ii = textbox counter		jj = arrow counter
loc lasty=`ymax' 
loc ii=1
loc jj=0
mat pdtxt[`ii',1]= `lasty' 
mat pdtxt[`ii',2]= 0
mat pdtxt[`ii',3]= 24*`bxw'

*** Concatenate title for textbox   if interval/1 dummy   title =  VarName*(coeff) +
***		if nominal 2+ dummies title =  VarCategoryName*(coeff) + with each dummy on separate line
***		nm = accumulate named across categories
if ${fcnum$sfx}==1 {							//	title if interval/1 dummy
	getb , mat(bmat) vn("${fvarc1$sfx}") eqn(`eqname')  bform(%8.`ndigits'f)  
	loc nm= " ${fvldisp$sfx}  Effect = " + r(bstr) + " +"
	mata: txt[`ii',1]="`nm'"
	}
if ${fcnum$sfx}>1 {					//	title if 2+dummies embed " to create multi-line title as   line1" "line2" "line3" ... "lastline  
	loc nm= ""
	
	forvalues fci=1/${fcnum$sfx} {
		getb , mat(bmat) vn("${fvarc`fci'$sfx}") eqn(`eqname')  bform(%8.`ndigits'f)  
		if `fci'==1     loc nm= `"`nm'"'  + " ${fvnamec`fci'$sfx} Effect = " + r(bstr) + " +" +`"""'
		if `fci'==${fcnum$sfx} loc nm= `"`nm'"' + " " + `"""' + " ${fvnamec`fci'$sfx} Effect = " + r(bstr) + " +" 
		if `fci'>1 & `fci' < ${fcnum$sfx} 	loc nm= `"`nm'"' + " " + `"""' + " ${fvnamec`fci'$sfx} Effect = " + r(bstr) + " +" +`"""'
		}
	mata: txt[`ii',1]=`"`nm'"'
}
*
***		Arrows from main effect box to each 2way of focal*m1 , focal*m2 ....  start  just below top of box
***		Adjust y coord for arrow head for oversize 2way boxes  and for extra 2way term (m1*m2) if 3way specified

	forvalues mi=1/${mvarn$sfx} {
		loc ++jj
		mat pdarr[`jj',1]= `lasty'-.1/2
		mat pdarr[`jj',2]= `bx1'
		mat pdarr[`jj',3]= `ymax' - (`mi'-1 )*`yinc' -.1/2 -`madj`mi''
		if "${fm1m2list$sfx}"!="" & `mi' >2 mat pdarr[`jj',3]= `ymax' - `mi'*`yinc' -.1/2 -`madj`mi''
		mat pdarr[`jj',4]= `bx1'+`xinc'
	}

***		Define Main Effects Box(s) and Arrows to  2-way Boxes:  Moderators 
***		Adjust y coord for textbox and arrow head for oversize 2way boxes and for extra 2way term (m1*m2) if 3way specified
***		bk1 = left bracket type  bk2 = right bracket    types =   [m1] {m2} use {} for m3 on

forvalues mi=1/${mvarn$sfx} {
	loc ++ii
	loc mst=`mi'+1
	loc lasty= `ymax'- `mi'*`yinc' -`madj`mst''
	mat pdtxt[`ii',1]= `lasty'
	mat pdtxt[`ii',2]= 0
	mat pdtxt[`ii',3]= 24*`bxw'
	if ${mcnum`mi'$sfx}==1 {
		loc nm= "${mvldisp`mi'$sfx}" 
		mata: txt[`ii',1]="`nm'"
		}
	if ${mcnum`mi'$sfx}>1 {
		loc nm= ""
		
		forvalues mci=1/${mcnum`mi'$sfx} {
			if `mci'==1     loc nm= `"`nm'"'  + " ${mvname`mi'c`mci'$sfx}"+  +`"""'
			if `mci'==${mcnum`mi'$sfx} loc nm= `"`nm'"' + " " + `"""' + " ${mvname`mi'c`mci'$sfx}" 
			if `mci'>1 & `mci' < ${mcnum`mi'$sfx} 	loc nm= `"`nm'"' + " " + `"""' + " ${mvname`mi'c`mci'$sfx}"  +`"""'
			}
		mata: txt[`ii',1]=`"`nm'"'
	}
***   Draw arrows to  2-way with focal
***
		loc ++jj 
		mat pdarr[`jj',1]= `lasty'-.1/2
		mat pdarr[`jj',2]= `bx1'
		mat pdarr[`jj',3]= `ymax' -(( `mi'-1)*`yinc'+`madj`mi''+.1/2)  + .2*`xinc'*tan((atan(((`mi'-1)*`yinc'+`madj`mi'')/`xinc')))
		if "${fm1m2list$sfx}"!="" & `mi' > 2 mat pdarr[`jj',3]= `ymax' - (`mi'*`yinc'+`madj`mi''+.1/2)   + .2*`xinc'*tan((atan((`mi'*`yinc'+`madj`mi'')/`xinc')))
		mat pdarr[`jj',4]= (`bx1'+.8*`xinc')
***   If 3way exists, draw arrows to 2way with only moderators for moderators 1 & 2
***
	if "${fm1m2list$sfx}"!=""  & `mi' < 3 {
			loc ++jj
			loc ypos=`ymax' -2*`yinc' - (`madj2' +`madj3')/2
			mat pdarr[`jj',1]= `lasty'-.1/2
			mat pdarr[`jj',2]= `bx1'
			mat pdarr[`jj',3]= `ypos' -.1/2
			mat pdarr[`jj',4]= `bx1'+`xinc' 	
		}
	}

***		Define Box & Arrow for Other Predictors Box
loc ++ii
loc ++jj
loc lasty = `ymax'-`yinc'* (${mvarn$sfx}+1)-`madj${mvarn$sfx}' 
mat pdtxt[`ii',1]= `lasty'
mat pdtxt[`ii',2]= 0
mat pdtxt[`ii',3]= 24*`bxw'
mata: txt[`ii',1]=`" Other" " Predictors"'
mat pdarr[`jj',1]= `lasty'-.1/2
mat pdarr[`jj',2]= `bx1'
mat pdarr[`jj',3]= `lasty'-.1/2
mat pdarr[`jj',4]= `bx1'+`xinc'+`bx2'+`xinc'
if "${fm1m2list$sfx}"!=""   mat pdarr[`jj',4]= (`bx1'+`xinc'+`bx2'+`xinc'+`bx3'+`xinc')/1.007

***		Define 2way Box(s) with Focal (leave spot for M1*M2 if there is a 3way int ) and Arrows to Outcome or to 3-way Boxes
***		nmend = end-symbols for textbox line     ")" if no 3way      ") +"  if 3way
loc nmend= " "

	forvalues mi=1/${mvarn$sfx} {
		if "${fm1m2list$sfx}"!="" & `mi'<3 loc nmend= " +"
		loc ++ii
		loc lasty= `ymax'- (`mi'-1)*`yinc' -`madj`mi''
		if "${fm1m2list$sfx}"!="" & `mi'>2 	loc lasty= `ymax'- `mi'*`yinc' -`madj`mi''
		mat pdtxt[`ii',1]= `lasty' 
		mat pdtxt[`ii',2]= `bx1'+`xinc'
		mat pdtxt[`ii',3]= 26*`bxw'
		loc nm1= ""
		loc nm3= ""
		loc nm4= ""
***		nm1 = tag 1st line(s) of moderator with <fvnameci> if both focal & moderator are categorical
***		nm2 = accummulated text lines across categories of moderator for given focal var category, reset with fci to keep embedded " " correct
***		nm3 = accumulated nm2 across categories of focal, reset with fci to keep embedded " " correct
***		nm4 = accumulated nm3 across categories of focal

	forvalues fci=1/${fcnum$sfx} {
		if ${mcnum`mi'$sfx}==1 {
			getb , mat(bmat) vn("${f`fci'm`mi'c1$sfx}") eqn(`eqname') bform(%8.`ndigits'f)  
			loc nm2= " " + r(bstr) + " *${mvname`mi'c1$sfx}" +  "`nmend'" + `"" ""'
			loc nm3=`"`nm2'"'
			}
		if ${mcnum`mi'$sfx}>1 {
			if ${fcnum$sfx} > 1 loc nm1= "       [" + abbrev("${fvnamec`fci'$sfx}",8)
			loc nm3=""
			loc nm2 = ""
			forvalues mci=1/${mcnum`mi'$sfx} {
			getb , mat(bmat) vn("${f`fci'm`mi'c`mci'$sfx}") eqn(`eqname') bform(%8.`ndigits'f)
				if `mci'==1     loc nm2= `"`nm2'"' + " "  + r(bstr) + " *${mvname`mi'c`mci'$sfx}" +  "`nmend'" + "`nm1'"
				if `mci' == ${mcnum`mi'$sfx}  loc nm2= `"`nm2'"' + `"" ""' + " " + r(bstr) + " *${mvname`mi'c`mci'$sfx}" +  "`nmend'" + `"" ""' 
				if `mci'> 1	& `mci' < ${mcnum`mi'$sfx}  loc nm2= `"`nm2'"' + `"" ""' + " " +  r(bstr) + " *${mvname`mi'c`mci'$sfx}" +  "`nmend'" 
				}
			loc nm3= `"`nm3'"' + `"`nm2'"'
			}
		loc nm4= `"`nm4'"'  + `"`nm3'"'
		}
		mata: txt[`ii',1]=`"`nm4'"'
***		Define arrow from 2way to Outcome box if no 3way
***	
	if "${fm1m2list$sfx}"=="" | `mi'> 2 {
		loc ++jj
		mat pdarr[`jj',1]= `lasty'-.1/2
		mat pdarr[`jj',2]= (`bx1'+`xinc'+`bx2')/1.1
		mat pdarr[`jj',3]= `lasty'-.1/2
		mat pdarr[`jj',4]= `bx1'+`xinc'+`bx2'+`xinc'
		if "${fm1m2list$sfx}"!="" mat pdarr[`jj',4]= `bx1'+`xinc'+`bx2'+`xinc'+`bx3'+`xinc'
		}
***		Define arrow from 2way to 3way box if present
***	
	if "${fm1m2list$sfx}"!="" & `mi' < 3 {
		loc ++jj
		mat pdarr[`jj',1]= `lasty'-.1/2
		mat pdarr[`jj',2]= `bx1'+`xinc'+`bx2'
		mat pdarr[`jj',3]= `ymax' -.1/2
		mat pdarr[`jj',4]= `bx1'+`xinc'+`bx2'+`xinc'
		}
	}
***		If 3way exists Define 2way Box Moderators 1&2  and Arrows to Outcome Box
***		place box after f*m2 and before f*m3.   Adjustment is 1/2 between m2 and m3 adjustment
***		same use of nm,nm2,nm3, nm4 as above
if "${fm1m2list$sfx}"!=""  {
	loc ++ii
	loc ypos= `ymax' -2*`yinc' -(`madj2' + `madj3')/2
	mat pdtxt[`ii',1]= `ypos' 
	mat pdtxt[`ii',2]= `bx1'+`xinc'
	mat pdtxt[`ii',3]= 26*`bxw'
	loc nm4= " ${mvldisp1$sfx} * ${mvldisp2$sfx}"
	mata: txt[`ii',1]=`"`nm4'"'
	loc ++jj
	mat pdarr[`jj',1]= `ypos'-.1/2
	mat pdarr[`jj',2]= (`bx1'+`xinc'+`bx2')/1.1
	mat pdarr[`jj',3]= `ymax' -.1/2
	mat pdarr[`jj',4]= `bx1'+`xinc'+`bx2'+`xinc'
		}
*** 	If 3way exists Draw 3way Box and Arrows to Outcome
***		same use of nm,nm2,nm3, nm4 as above
if "${fm1m2list$sfx}"!="" { 
	loc ++ii
	mat pdtxt[`ii',1]= `ymax' 
	mat pdtxt[`ii',2]= `bx1'+`xinc'+`bx2'+`xinc'
	mat pdtxt[`ii',3]= 24*`bxw'
	loc nm1= ""
	loc nm3= ""
	loc nm4= ""
	
	forvalues fci=1/${fcnum$sfx} {
		if ${fcnum$sfx} > 1 & (${mcnum1$sfx}>1 | ${mcnum2$sfx}>1) loc nm1= "           [" + abbrev("${fvnamec`fci'$sfx}",8)
		forvalues mci1=1/${mcnum1$sfx} {
			if ${mcnum2$sfx}==1 {
				getb , mat(bmat) vn("${f`fci'm1c`mci1'm2c1$sfx}") eqn(`eqname') bform(%8.`ndigits'f)  
				loc nm2= " " +  r(bstr) + " *${mvname1c`mci1'$sfx}"  +`"" ""' + "   *${mvname2c1$sfx}" +"`nm1'" + `"" ""'
				loc nm1 = ""
				loc nm3=`"`nm2'"' 
				}
			if ${mcnum2$sfx} > 1 {
				loc nm3=""
				forvalues mci2=1/${mcnum2$sfx} {
					getb , mat(bmat) vn("${f`fci'm1c`mci1'm2c`mci2'$sfx}") eqn(`eqname')  bform(%8.`ndigits'f)  
					if `mci2'==1     loc nm2= " " + r(bstr) + " *${mvname1c`mci1'$sfx} "  +`"" ""' + "   *${mvname2c`mci2'$sfx}" + "`nm1'" 
					loc nm1 = ""
					if `mci2'==${mcnum2$sfx} loc nm2= `"`nm2'"' + `"" ""' + " " + r(bstr) + " *${mvname1c`mci1'$sfx} "  +`"" ""' + "   *${mvname2c`mci2'$sfx}"  +`"" ""'					
					if `mci2'>1 & `mci2' < ${mcnum2$sfx} 	loc nm2= `"`nm2'"' + `"" ""' + " " + r(bstr) + " *${mvname1c`mci1'$sfx}"  +`"" ""' + "   *${mvname2c`mci2'$sfx}"  
				}
				loc nm3= `"`nm3'"' + `"`nm2'"'
			}
				loc nm4= `"`nm4'"'  + `"`nm3'"'
		}
	}
	mata: txt[`ii',1]=`"`nm4'"'
	loc ++jj
	mat pdarr[`jj',1]= `ymax'-.1/2
	mat pdarr[`jj',2]= `bx1'+`xinc'+`bx2'+`xinc'+`bx3'
	mat pdarr[`jj',3]= `ymax'-.1/2
	mat pdarr[`jj',4]= (`bx1'+`xinc'+`bx2'+`xinc'+`bx3'+`xinc')/1.007
}	
***		Define Outcome box.  boxwidth=90 will apply to rotated box and is its height
loc ++ii
loc ++jj
mat pdtxt[`ii',1]= `ymax'/2
mat pdtxt[`ii',2]= `bx1'+`xinc'+`bx2'+`xinc'*1.05
mat pdtxt[`ii',3]= 90
if "${fm1m2list$sfx}"!="" mat pdtxt[`ii',2]= `bx1'+`xinc'+`bx2'+`xinc'+`bx3'+`xinc'*1.05
mata: txt[`ii',1]= "g(${dvname$sfx})"


***		Make variables from matrices defining textbox (pdtxt and mata:txt) and arrows (pdarr)
***		
mat colnames pdtxt = "`ybox'" "`xbox'" "`boxwd'"
mat colnames pdarr= "`ytail'" "`xtail'" "`yhead'" "`xhead'"
svmat pdtxt, names(col)
svmat pdarr, names(col)
mata: st_addvar("strL","`boxtext'")
mata: st_sstore((1,50),"`boxtext'",txt)

replace `xhead'=`xhead'*1
replace `xtail'=`xtail'/1

***		Concatenate text boxes
***		graph has fixed y/xsize=12 and y/x axes 0 to 12
***		 rescale x& y so each runs from (0+ a tad) to (11.5+ a tad)
loc yxy="y x"

foreach yx of loc yxy {
	loc `yx'min=100
	loc `yx'max=0
	foreach yv of var ``yx'box' ``yx'head' ``yx'tail' {
		summ `yv'
		if r(min) < ``yx'min' loc `yx'min=r(min)
		if r(max) > ``yx'max' loc `yx'max=r(max)
		}
		loc scale=6.3
		if "`yx'"=="x" loc scale=8.8
		
	foreach yv of var ``yx'box' ``yx'head' ``yx'tail' {
		replace `yv'=(`yv'-``yx'min'+.1)*`scale'/(``yx'max'-``yx'min')
	}
}
***		reset y coord for Outcome boox to 1/2 way  between rescaled ybox min and max
***
qui summ `ybox'
loc iin=r(N)
qui replace `ybox'= r(min)+.47*(r(max)-r(min)) if _n==`iin'
***		tb = accumulated textbox definitions   tt1=text title	bxwd=boxwidth 	
***		gg=accumulate pieces of iith textbox	Outcome ox (last box) rotated to vertical
loc tb = " "
forvalues ii=1/`iin' {
	loc tt1=   `boxtext'[`ii']
	loc bxwd =   `boxwd'[`ii'] 
	loc gg= "text( " + strofreal(`ybox'[`ii'], "%14.6g") + " " + strofreal(`xbox'[`ii'], "%14.6g") + " " + `"""' + `"`tt1'"'  ///
	  + `"""' + " , size(2) box m(vsmall) place(se) width(`bxwd') bexp j(left) linegap(*1.3)  ) "
	if `ii'==`iin' loc gg="text( " + strofreal(`ybox'[`ii'], "%14.6g") + " " + strofreal(`xbox'[`ii'], "%14.6g") + " " + `"""' + `"`tt1'"'  ///
	  + `"""' + " , size(2.5) box m(vsmall) place(0) width(`bxwd') bexp  orient(rvertical)) "
	loc tb = `"`tb'"' + `"`gg'"'
} 
} 
 // end quietly  
tw  pcarrow `ytail' `xtail' `yhead' `xhead', msize(tiny) barbsize(.5) lw(*.5) lc(black) mc(black) ///
  xsize(9) ysize(6.5) ti( , size(*.7)  m(b+2)) tit(`title' ) scheme(s1mono) ytit("") xtit("") ysc(r(0 6.5)) /// 
  ysc(noline) xsc(r(0 9)) xsc(noline) xlab(none) ylab(none) leg(off)  name(`pname',replace) plotreg(lc(none)) `tb'
end  
