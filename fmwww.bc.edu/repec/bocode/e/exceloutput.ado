*! Date    : 16 August 2021
*! Version : 1.0
*! Author  : Max Sacher
*! Email   : maxsacher@email.wm.edu


*! Program to create standard excel output 

program exceloutput, rclass
	version 15.0
	syntax name(id="cell" name=input), [BEtas(integer 1) TItle(string) B_decimal(integer 4) SE_decimal(integer 4) Detail MEan_decimal(integer 4) R2_decimal(integer 4)    ] 
			local cell=regexm("`input'", "([a-zA-Z]+)([0-9]+)")		
			local cell_column=regexs(1)
			local cell_row = scalar(regexs(2))
			local cell_row = `cell_row'-1
			local Cell = "`cell_column'" + string(`cell_row')


			*get results from estimate
			matrix results=r(table)
			
			*write title of regression to cell
			if  ("`title'"!="") {
				local cell_row=`cell_row'+1
				local Cell = "`cell_column'" + string(`cell_row')
				putexcel `Cell'="`title'" , hcenter  bottom bold overwrite
				}
			

			*place results with significance stars 
			forvalues i=1(1)`betas' {

				local cell_row=`cell_row'+1
				local Cell = "`cell_column'" + string(`cell_row')


				scalar treat_post_b=results[1,`i']
				scalar treat_post_p=results[4,`i']
				local base_result=string(treat_post_b, "%9.`b_decimal'f")

				if  treat_post_p<.01{
				putexcel `Cell'="`base_result'***" , hcenter bottom  overwrite
				}
				if  treat_post_p>=.01&treat_post_p<.05 {
				putexcel `Cell'="`base_result'**" , hcenter  bottom  overwrite
				}
				if  treat_post_p>=.05&treat_post_p<.1 {
				putexcel `Cell'="`base_result'*" , hcenter bottom  overwrite 
				}
				if  treat_post_p>=.1 {
				putexcel `Cell'="`base_result'" , hcenter  bottom  overwrite
				}


				local cell_row=`cell_row'+1
				local Cell = "`cell_column'" + string(`cell_row')


				* place S.E.
				scalar treat_post_s=results[2,`i']
				local base_error=string(treat_post_s, "%9.`se_decimal'f")
				putexcel `Cell'="(`base_error')", hcenter  bottom overwrite

			}
			
			dis "`detail'"
			if  ("`detail'"=="detail") {
				local N=string(e(N), "%12.0fc")
				local r2=string(e(r2), "%9.`r2_decimal'f")



				local cell_row=`cell_row'+1
				local Cell = "`cell_column'" + string(`cell_row')
				local yvar=e(depvar)
				sum `yvar', meanonly
				local mean=string(r(mean), "%9.`mean_decimal'f")
				putexcel `Cell'="`mean'", hcenter  bottom  overwrite


				local cell_row=`cell_row'+1
				local Cell = "`cell_column'" + string(`cell_row')
				putexcel `Cell'="`r2'", hcenter  bottom overwrite


				*** format this guy****
				local cell_row=`cell_row'+1
				local Cell = "`cell_column'" + string(`cell_row')
				putexcel `Cell'="`N'", hcenter  bottom  overwrite
			}
		return matrix table=results
		
end




