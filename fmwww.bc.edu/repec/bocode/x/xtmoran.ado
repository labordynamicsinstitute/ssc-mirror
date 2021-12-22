*！V1.0 Zihou,Chen etc.
*! data: 29 Apr 2021
*! Party School of the Guangdong Provincial Committee of CPC,China

** The command is based upon commands( spatgsa and spatlsa ) originally written by  Maurizio Pisati,thanks!


program define xtmoran, rclass
version 11.0

syntax varname(min = 1 max=1), Wname(string)       /*
           */   [Morani(numlist)]                  /*
           */   [GRaph]                            /*	   
           */   [SYmbol(varname)]           

local vvcheck = max(11,c(stata_version))
if `vvcheck' < 11{
	di as err "it cannot run version `vvcheck' programs"
	exit
}
_xt, trequired
local id: char _dta[_TSpanel]
local time: char _dta[_TStvar]
cy using "`wname'",name(wcname) 
capture qui matrix list wcname
if _rc==111 {
	di as err "Matrix file `weights' does not exist"
	exit
}
local weights wcname
local ROWNAME : rownames(`weights')
local COLNAME : colnames(`weights')
local WTYPE : word 1 of `ROWNAME'
local WBINA : word 2 of `ROWNAME'
local WSTAN : word 3 of `ROWNAME'
qui {
preserve
keep `id' `time' `varlist'
reshape wide `varlist' ,i(`id') j(`time')
local N=_N
restore
local DIM=rowsof(`weights')
}
if `DIM'!=`N' {
	di as err "Matrix `weights' is `DIM'x`DIM', the dataset using on the cross section has `N' obs."
	di as err "To run -xtmoran- weights matrix dimension must equal N. of obs"
	exit
}
local W="`weights'"
local tc=_N/`N'
local NVAR  `tc'
tempname cname MORAN
matrix `cname'=J(`tc',1,0)
local k2=1
local yearz=`time'
while `k2'<=`tc' {
local yearc =`yearz'+`k2'-1
matrix `cname'[`k2',1]=`yearc'
local k2=`k2'+1
}
local MULT=2
local PVL "*`MULT'-tail test"
preserve
keep `id' `time' `varlist'
qui reshape wide `varlist' ,i(`id') j(`time')
local kk=1
local aa `varlist'
while `kk'<=`NVAR' {
local tvarc=`cname'[`kk',1]
tempname m2 m4 b2 M 
matrix `m2'=J(`NVAR',1,0)
matrix `m4'=J(`NVAR',1,0)
matrix `b2'=J(`NVAR',1,0)
matrix `M'=J(`NVAR',4,0)
local k=1 //Prepare for the next update
tempname zc
mkmat `aa'`tvarc', matrix(`zc')
svmat `zc',name(zc`kk')
local VAR zc`kk'1
local j=1
while `j'<=4 {
tempvar TEMP
qui generate `TEMP'=`VAR'^`j'
qui summ `TEMP', mean
matrix `M'[`k',`j']=r(sum)
local j=`j'+1
}
qui summ `VAR', mean
local MEAN=r(mean)
qui replace `VAR'=`VAR'-`MEAN'
tempvar Vm2 Vm4
qui generate `Vm2'=`VAR'^2
qui summ `Vm2', mean
matrix `m2'[`k',1]=r(mean)	
local m2k=r(mean)
qui generate `Vm4'=`VAR'^4
qui summ `Vm4', mean
matrix `m4'[`k',1]=r(mean)	
local m4k=r(mean)
matrix `b2'[`k',1]=`m4k'/(`m2k'^2)	
tempname Z
mkmat zc`kk'1, matrix(`Z')
local S0=0
local S1=0
local S2=0
local i=1
while `i'<=`N' {
local wi=0
local wj=0
local j=1
while `j'<=`N' {
local S0=`S0'+`W'[`i',`j']
local S1=`S1'+(`W'[`i',`j']+`W'[`j',`i'])^2
local wi=`wi'+`W'[`i',`j']
local wj=`wj'+`W'[`j',`i']
local j=`j'+1
}
local S2=`S2'+(`wi'+`wj')^2
local i=`i'+1
}
local S1=`S1'/2
tempname MORAN
matrix `MORAN'=J(`NVAR',5,0)
matrix colnames `MORAN'=stat mean sd z p-value
local m2k=`m2'[`k',1]
local b2k=`b2'[`k',1]
tempname Zk
matrix `Zk'=`Z'[1...,`k']
matrix `Zk'=`Zk''*`W'*`Zk'
local stat=`Zk'[1,1]/(`S0'*`m2k')
matrix `MORAN'[`k',1]=`stat'
local E=-1/(`N'-1)
matrix `MORAN'[`k',2]=`E'
local NUM1=`N'*( (`N'^2-3*`N'+3)*`S1' - (`N'*`S2') + (3*`S0'^2) )
local NUM2=`b2k'*( (`N'^2-`N')*`S1' - (2*`N'*`S2') + (6*`S0'^2) )
local DEN=(`N'-1)*(`N'-2)*(`N'-3)*(`S0'^2)
local sd=(`NUM1'-`NUM2')/`DEN' - (1/(`N'-1))^2
local sd=sqrt(`sd')
matrix `MORAN'[`k',3]=`sd'
local z=(`stat'-`E')/`sd'
matrix `MORAN'[`k',4]=`z'
local pval=(1-normprob(abs(`z')))*`MULT'
matrix `MORAN'[`k',5]=`pval'
mat mczh`kk'=`MORAN'
local kk=`kk'+1
}
tempname CC
mat `CC'=J(`tc',5,0)
local kck=1
while `kck'<=`NVAR' {
local kckk=1	
while `kckk'<= 5 {
mat `CC'[`kck',`kckk']=mczh`kck'[1,`kckk']
local kckk=`kckk'+1	
}
local kck=`kck'+1
}
restore
local kckp=1
while `kckp'<=`NVAR' {
mat drop mczh`kckp'
local kckp =`kckp'+1
}
di _newline
di as txt "{bf:{err:Welcome to use this command to calculate the Moran's I}}"
local ncz=_N
dis ""
di as res "{title:The results :}"
_dispcc "`CC'" "Moran's I" "I" "`cname'" "`id'"  "`time'"  "`ncz'"   /*
*/  "`N'"  "`NVAR'" "`varlist'"
return matrix Moran `MORAN'
di as txt "`PVL'"
di _newline
if "`morani'"!="" {
if "`symbol'"=="" {
local ID=1
}
if "`symbol'"!="" {
local TEMP : type `symbol'
local TEMP=substr("`TEMP'",1,3)
if "`TEMP'"=="str" {
local ID=2
}
else {
local TEMP : value label `symbol'
if "`TEMP'"!="" {
local ID=3
}
else {
local ID=4
}
}
}
preserve
keep `id' `time' `varlist'
qui reshape wide `varlist' ,i(`id') j(`time')
local N=_N
restore
preserve
keep `id' `time' `varlist' `symbol'
qui reshape wide `varlist' ,i(`id') j(`time')
local aca `varlist'
foreach varlistc of numlist `morani' {
tempname zcx
mkmat `aca'`varlistc', matrix(`zcx')
svmat `zcx',name(zcx`varlistc')
local varlistcx  zcx`varlistc'1
tempname M 
matrix `M'=J(1,4,0)
local j=1
while `j'<=4 {
tempvar TEMP
qui generate `TEMP'=zcx`varlistc'1^`j'
qui summ `TEMP', mean
matrix `M'[1,`j']=r(sum)
local j=`j'+1
}
qui summ zcx`varlistc'1, mean
local MEAN=r(mean)
qui replace zcx`varlistc'1=zcx`varlistc'1-`MEAN'
tempvar Vm2 Vm4
qui generate `Vm2'=zcx`varlistc'1^2
qui summ `Vm2', mean
local m2=r(mean)
qui generate `Vm4'=zcx`varlistc'1^4
qui summ `Vm4', mean
local m4=r(mean)
local b2=`m4'/(`m2'^2)	
tempname Z
mkmat zcx`varlistc'1, matrix(`Z')
tempname Wi Wi2
local N=_N
local W="`weights'"
matrix `Wi'=J(`N',1,0)
matrix `Wi2'=J(`N',1,0)
local i=1
while `i'<=`N' {
	local wi=0
	local wi2=0
	local j=1
	while `j'<=`N' {
		local w=`W'[`i',`j']
		local wi=`wi'+`w'
		local wi2=`wi2'+`w'^2
		local j=`j'+1
	}
	matrix `Wi'[`i',1]=`wi'
	matrix `Wi2'[`i',1]=`wi2'
	local i=`i'+1
}
tempname MORAN cz cq
matrix `MORAN'=J(`N',6,0)
matrix `cz'=J(`N',1,0)
matrix colnames `MORAN'=stat mean sd z p-value quadrant
tempvar Yc 
qui egen `Yc'=std(zcx`varlistc'1)
tempname yc Wyc
mkmat `Yc', matrix(`yc')
matrix `Wyc'=`W'*`yc'
svmat `Wyc', n(_Wyc)
qui gen zcx`varlistc'1quadrant=_N
local leix  zcx`varlistc'1quadrant
qui replace `leix'=1 if `Yc'>0 & _Wyc1>0
qui replace `leix'=3 if `Yc'<0 & _Wyc1<0
qui replace `leix'=4 if `Yc'>0 & _Wyc1<0
qui replace `leix'=2 if `Yc'<0 & _Wyc1>0
mkmat zcx`varlistc'1quadrant, matrix(`cq')
qui cap drop zcx`varlistc'1quadrant  _Wy*
local i=1

while `i'<=`N' {
	local zi=`Z'[`i',1]
	local wi=`Wi'[`i',1]
	local wi2=`Wi2'[`i',1]
	local SUM=0
	local j=1
	while `j'<=`N' {
		local wj=`W'[`i',`j']
		local zj=`Z'[`j',1]
		local SUM=`SUM'+`wj'*`zj'
		local j=`j'+1
	}
	local stat=(`zi'/`m2')*`SUM'
	matrix `MORAN'[`i',1]=`stat'
	local E=(-`wi')/(`N'-1)
	matrix `MORAN'[`i',2]=`E'
	local T1=(`wi2'*(`N'-`b2')) / (`N'-1)
	local T2=((`wi'^2-`wi2')*(2*`b2'-`N')) / ((`N'-1)*(`N'-2))
	local T3=((-`wi')/(`N'-1))^2
	local sd=`T1'+`T2'-`T3'
	local sd=sqrt(`sd')
	matrix `MORAN'[`i',3]=`sd'
	local z=(`stat'-`E')/`sd'
	matrix `MORAN'[`i',4]=`z'
   local pval=(1-normprob(abs(`z')))*2
	matrix `MORAN'[`i',5]=`pval'
    matrix `cz'[`i',1]=`pval'
	matrix `MORAN'[`i',6]=`cq'[`i',1]
	local i=`i'+1
}
_dispcz "`varlist'`varlistc'" "`MORAN'" "Moran's Ii" "Ii" "`N'" "`ID'"  /*
   */ "`symbol'" 
di as txt "`PVL'"
di _newline
if "`graph'"!="" {
tempvar Y
qui egen `Y'=std(zcx`varlistc'1)
tempname y Wy
mkmat `Y', matrix(`y')
local cyc  gr tw 
matrix `Wy'=`W'*`y'
svmat `Wy', n(_Wy)
qui summ _Wy1, mean
local YL=r(mean)
local VARLBL : variable label zcx`varlistc'1
if "`VARLBL'"!="" {
   local VARLBL=usubstr("`VARLBL'",1,78)
}
else {
   local VARLBL="`zcx`varlistc'1'"
}
   qui regress _Wy1 `Y',noconstant
   local I=string(_b[`Y'],"%5.4f")
   local t = _b[`Y']/_se[`Y'] 
   local pcp=2*ttail(e(df_r),abs(`t'))
   local II=string(`pcp',"%5.4f")
   qui summ _Wy1, mean
   local ymin=int(r(min))-1
   local ymax=int(r(max))+1
   qui summ `Y', mean
   local xmin=int(r(min))-1
   local xmax=int(r(max))+1
   if "`symbol'"=="" {
   	local czhc1 msymbol(Oh)
   }
   if "`symbol'"!="" {
    local czhc1 msymbol(i)   
	local varnamec `symbol' 
   	local czhc2 mlabel (`varnamec') 
	local czhc3 mlabsize(*1)
   }  
   	`cyc'  (sc  _Wy1 `Y' ,`czhc1' `czhc2'  `czhc3')                                          /*
*/	(lfit  _Wy1 `Y',estopts(nocons)), yline(0) xline(0) xlabel(`xmin'(1)`xmax')              /*
*/	xtitle(z)  ylabel(`ymin'(1)`ymax') ytitle(Wz)                                            /*
*/	legend(off) scheme(s1mono )                                                              /*
*/  title("Moran scatterplot (Moran's I = `I' and P-value = `II')",  /*
*/  justification(left)  size(medium))                               /*
*/  subtitle("`varlist'`varlistc'", pos(11))                         /*
*/  name(picture`varlistc',replace) 
}
}
restore
}
mat drop wcname
end

program define _dispcc
version 11.0
args MAT TITLE L cname  idc timec Nc nc tcc namecz
local LIST : rownames(`MAT')
local NVAR : word count `LIST'
di as txt _n "`TITLE' (" as res "varname : `namecz'" as txt ")" _col(40) /*
	*/  "Number of obs " _col(38) "="  as res %7.0g `Nc'	
di in gr "Group variable: " in ye abbrev("`idc'",12)   /*
        */   in gr _col(37) "Number of groups " _col(4) "=" in ye %7.0g `nc'	 
 di in gr "Time variable: " in ye abbrev("`timec'",12)       /*             
    */ in gr _col(41) in gr "Panel length " _col(50) "=" in ye %7.0g `tcc' 
di as txt "{hline 20}{c TT}{hline 41}"
di as txt _col(11) "     year {c |}" _col(26) "`L'" _col(33) "E(`L')"   /*
     */   _col(40) "Sd(`L')" _col(50) "Z" _col(55) "P-value"
di as txt "{hline 20}{c +}{hline 41}"
local k=1
while `k'<=`NVAR' {
	local VAR = `cname'[`k',1]
	local VAR=abbrev("`VAR'",19)
	di as txt _col(1)  %19s "`VAR'" " {c |}"   /*
	*/ as res _col(22) %7.4f `MAT'[`k',1]      /*
	*/ as res _col(30) %7.4f `MAT'[`k',2]      /*
	*/ as res _col(38) %7.4f `MAT'[`k',3]      /*
	*/ as res _col(46) %7.4f `MAT'[`k',4]      /*
	*/ as res _col(56) %5.4f `MAT'[`k',5]
	local k=`k'+1
}
di as txt "{hline 20}{c BT}{hline 41}"
end

program define _dispcz
version 11.0
args VAR MAT TITLE L N ID  id VARLBLC
preserve
tempname STAT
matrix `STAT'=`MAT'
if "`id'"!="" {
	local header=abbrev("`id'",42)
}
else {
	local header="Location"
}
di as txt "`TITLE' (" as res "`VAR'" as txt ")"
di as txt "{hline 20}{c TT}{hline 50}"
di as txt _col(1) %19s "`header'" " {c |}" _col(26) "`L'"       /*
     */   _col(32) "E(`L')" _col(39) "Sd(`L')" _col(50) "Z"     /*
     */   _col(55) "P-value"   _col(64) "Quadrant"
di as txt "{hline 20}{c +}{hline 50}"
local i=1
while `i'<=`N' {
	if `ID'==1 {
		local ROW=`TEMP'[`i']
	}
	if `ID'==2 {
		local ROW=substr(`id'[`i'],1,24)
	}
	if `ID'==3 {
      local INDEX=`id'[`i']
      local ROW : label(`id') `INDEX' 24
	}
	if `ID'==4 {
      local ROW=`id'[`i']
	}
	di as txt _col(1) %19s "`ROW'" " {c |}"   /*
	*/ as res %7.4f `STAT'[`i',1]             /*
	*/ as res %8.4f `STAT'[`i',2]             /*
	*/ as res %8.4f `STAT'[`i',3]             /*
	*/ as res %8.4f `STAT'[`i',4]             /*
	*/ as res %8.4f `STAT'[`i',5]             /*
	*/ as res %8.0f `STAT'[`i',6]
	local i=`i'+1
}
di as txt "{hline 20}{c BT}{hline 50}"
restore
end

program define cy
version 7.0
syntax [using/], Name(string)                           /* 
          */     [Standardize]                          /*
          */     [Eigenval(string)]
confirm name `name'
local OUTPUT "The following matrix has been created:"
if "`using'"!="" {
	preserve
   qui use `"`using'"', clear
	unab VLIST : _all
	local NVAR : word count `VLIST'
	local SUM=0
	local i=1
	while `i'<=`NVAR' {
		local VAR : word `i' of `VLIST'
		qui capture assert `VAR'==0 | `VAR'==1
  	   if _rc!=0 {
		   local SUM=`SUM'+1
	   }
		local i=`i'+1
	}
	if `SUM'==0 {
		local binary "binary"
	}
	else {
		local binary ""
	}
	qui egen ROWSUM=rsum(_all)
	qui count if ROWSUM==0
	local NN=r(N)
	qui drop ROWSUM
   qui mkmat _all, matrix(_W)
   restore
   local NROW=rowsof(_W)
   local NCOL=colsof(_W)
   if `NROW'!=`NCOL' {
   	di as err "Matrix is not square"
   	exit
   }
   local N=`NROW'
   if "`binary'"!="" {
   	local WT "Imported binary weights matrix"
   }
   else {
   	local WT "Imported non-binary weights matrix"
   }
   matrix `name'=_W
}
if `"`using'"'=="" {
	local LOWER : word 1 of `band'
	local UPPER : word 2 of `band'
	local N=_N
	matrix _W=J(`N',`N',0)
	matrix _D=J(`N',`N',0)
	preserve
	local MAXOBS=(`N'/2)*(`N'-1)
	qui set obs `MAXOBS'
	tempvar DISTAN
	qui generate `DISTAN'=.
	local d=1
	local i=1
	while `i'<=`N' {
		local j=`i'+1
		while `j'<=`N' {
			local A=(`xcoord'[`i']-`xcoord'[`j'])^2
			local B=(`ycoord'[`i']-`ycoord'[`j'])^2
			local DIST=sqrt(`A'+`B')
			qui replace `DISTAN'=`DIST' in `d'
			matrix _D[`i',`j']=`DIST'
			matrix _D[`j',`i']=`DIST'
			if `DIST'>`LOWER' & `DIST'<=`UPPER' {
				if "`binary'"!="" {
					matrix _W[`i',`j']=1
					matrix _W[`j',`i']=1
				}
				else {
					matrix _W[`i',`j']=1/(`DIST'^`friction')
					matrix _W[`j',`i']=1/(`DIST'^`friction')
				}
			}
		   local d=`d'+1
		   local j=`j'+1
		}
	   local i=`i'+1
	}
	qui summarize `DISTAN', detail
	local DMIN=r(min)
	local DP25=r(p25)
	local DP50=r(p50)
	local DP75=r(p75)
	local DMAX=r(max)
   qui svmat _D
   qui for varlist _D* : replace X=. if X==0
   qui egen ROWMIN=rmin(_D*)
   qui summ ROWMIN, mean
   local MAXMIN=r(max)
   qui egen ROWMAX=rmax(_D*)
   qui summ ROWMAX, mean
   local MINMAX=r(min)
   matrix drop _D
	restore
	preserve
	qui drop _all
   qui svmat _W
   qui egen ROWSUM=rsum(_W*)
	qui count if ROWSUM==0
	local NN=r(N)
   restore
   if "`binary'"!="" {
   	local WT "Distance-based binary weights matrix"
   }
   else {
   	local WT "Inverse distance weights matrix"
   }
   matrix `name'=_W
}
preserve
qui drop _all
qui svmat _W
qui egen ROWSUM=rsum(_W*)
qui for varlist _W* : replace X=X/ROWSUM if ROWSUM!=0
qui mkmat _W*, matrix(_WS)
restore
matrix `name'=_WS
if "`using'"!="" & "`binary'"!="" {local ROW="SWMImpo Yes "}
if "`using'"!="" & "`binary'"=="" {local ROW="SWMImpo No "}
if "`using'"=="" & "`binary'"!="" {local ROW="SWMDist Yes "}
if "`using'"=="" & "`binary'"=="" {local ROW="SWMDist No "}
local ROW="`ROW'Yes"
matrix rownames `name'=`ROW'
if "`using'"=="" {
   local INT=int(`LOWER')
   local DEC=`LOWER'-`INT'
   local DEC=string(`DEC')
   local COL "`INT' `DEC'"
   local INT=int(`UPPER')
   local DEC=`UPPER'-`INT'
   local DEC=string(`DEC')
   local COL "`COL' `INT' `DEC'"
   matrix colnames `name'=`COL'
}
capture matrix drop _W
capture matrix drop _WS
end




