
 pro def nca_display_bottleneck_table
 syntax 
tempname _table _disp
matrix `_table'=e(bottlenecks)
local ceilings `e(ceilings)'
local X `e(indepvars)'
local y `e(depvar)'
tokenize `X' 
quie count if e(sample)
local Nobs=r(N)
preserve
clear
quie foreach c of local ceilings {
submatrix `_table', colnames(`1':`y' `c') 
matrix `_disp'=r(mat)
//matlist `_disp'
   matrix colnames `_disp'=`y' `X'
   matrix coleq `_disp'=""
   clear
   svmat `_disp', names(col)
   tempvar xx
   gen `xx'=.
   foreach x of local X {

   replace `xx'=sum(`x')
   if ("`e(xbottlenecks)'"=="percentile") 	gen byte `x'_number=round(`x'*`Nobs'/100)
   
 
   tostring `x'*, force replace usedisplayformat
      replace `x'="NN" if `x'=="." & `xx'==0

  replace `x'="NA" if `x'=="."
    
      if ("`e(xbottlenecks)'"=="percentile") 	{
	  	replace `x'=`x'+" "+cond(`x'=="NN","(0)", cond(`x'=="NA", "(`Nobs')", "("+`x'_number+")"))
		replace `x'=subinstr(`x',"NN","0",.)
		}
	  }
	local c2: subinstr local c  "_" "-"
   noi display "{bf: Bottlenecks: `x' - `y' (`c2') }  (`e(bnecks_subtitle)', cutoff=`e(cutoff)')"
noi list `y' `X',noobs sep(0) divider nocompress  abbreviate(50)  

}
noi display "NN: not necessary, NA: not available"
 if ("`e(xbottlenecks)'"=="percentile") noi display "Number of cases that are unable the reach the required x level for the desired y level in parentheses"
 restore
  end
