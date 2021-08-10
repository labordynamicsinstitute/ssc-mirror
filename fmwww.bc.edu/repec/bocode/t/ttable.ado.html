* Authors:
* Xuan Zhang, Ph.D., Zhongnan Univ. of Econ. & Law (zhangx@znufe.edu.cn)
* Chuntao Li, Ph.D. , Zhongnan Univ. of Econ. & Law (chtl@znufe.edu.cn)
* January 22, 2013


capture program drop ttable 
program define ttable , rclass
version 12.0
syntax varlist(min=1) [if] [in], by(varname)
 
		  
  tokenize `varlist'
  local k : word count `varlist'
	forval i=1(1) `k' {
	  confirm numeric variable ``i''
	  }
	  
  qui tab `by' `if' `in'
    if r(r) ~=2 {
	     di in red "cannot find two groups"
         exit 198

	   }
	   
  tempname mat ttable 
  qui tabstat `varlist' `if' `in', s(N mean) by(`by') save
  mat `ttable'=  r(Stat1)' , r(Stat2)',J(`k',2,0)
  local Group1_name = r(name1)
  local Group2_name = r(name2)
  forval i = 1(1) `k' {
    qui ttest ``i'' `if' `in', by(`by')
	mat `ttable'[`i',5]=r(mu_1)-r(mu_2)
	
	  if r(p)<=.1 {
	     mat `ttable'[`i',6]= 1
	     }
	   if r(p)<=.05 {
	     mat `ttable'[`i',6]= 2
	     }
		 
		 if r(p)<=.01 {
	     mat `ttable'[`i',6]= 3
	     }
		 
		 }
	
	
		 local star0=""
		 local star1= "*"
		 local star2= "**"
		 local star3= "***"

	  disp "Var, Group1(`by'=`Group1_name'), Mean1, Group2(`by'=`Group2_name'), Mean2, MeanDiff" 
forval i = 1(1) `k' {
      disp "``i''," _c 
	  disp _skip(1), scalar(`ttable'[`i', 1]) _c
	  disp ","  %10.4f scalar(`ttable'[`i', 2]) _c
	  disp ","   _skip(1) scalar(`ttable'[`i', 3]) _c
	  disp "," %10.4f scalar(`ttable'[`i', 4]) _c
	  disp "," %10.4f scalar(`ttable'[`i', 5]) _c
	  local star = scalar(`ttable'[`i', 6])
	  disp "`star`star''" 
	 }

 
    
end
