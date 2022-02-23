*uirt_dif.ado 
*ver 1.1
*2022.01.24
*everythingthatcounts@gmail.com

cap m: mata drop  _display_matrix_as_table()

capture prog drop uirt_dif
program define uirt_dif, rclass
version 10
syntax [varlist] [, CLeargraphs Format(str) Colors(str) tw(str asis)] 
	
	
	if("`e(cmd)'" != "uirt"){
		error 301
	}
	else{
		
		unab allvars: *
		if("`allvars'"=="`varlist'"){
			local varlist="*"
		}
		
		cap mat l  e(dif_results)
		local if_dif_results= _rc==0
		
		if(`if_dif_results' & "`varlist'"=="*"){
			mat temp_results=e(dif_results)
			mat temp_par_GR=e(dif_item_par_GR)
			mat temp_par_GF=e(dif_item_par_GF)
			
		}
		else{
		
			m: st_local("if_not_2_groups",strofreal(cols(st_matrix("e(group_par)"))!=2))
			if(`if_not_2_groups'){
				di as err "DIF analysis can be performed only after fitting a two-group model"
				exit 198
			}
			else{
				if(strlen("`format'")){
					local dif_format=" dif_format(`format')"
				}
				else{
					local dif_format=""
				}
				if(strlen("`colors'")){
					local dif_colors=" dif_colors(`colors')"
				}
				else{
					local dif_colors=""
				}
				if(strlen(`"`tw'"')){
					local dif_tw=" dif_tw("+`"`tw'"'+")"
				}
				else{
					local dif_tw=""
				}
			
			
				local cmdstrip="`e(cmdstrip)'"
				local cmdstrip_a=substr("`cmdstrip'", 1, strpos("`cmdstrip'","gr(")-1)
				local cmdstrip_b=substr("`cmdstrip'", strpos("`cmdstrip'","gr("),strlen("`cmdstrip'"))
				local insertpos=strpos("`cmdstrip_b'",")")
				local tocomaornottocoma= ","*(strpos(substr("`cmdstrip_b'",1,`insertpos'-1),",")==0)
				
				
				local cmdstrip_b=substr("`cmdstrip_b'",1,`insertpos'-1)+"`tocomaornottocoma' dif(`varlist') `dif_format'`dif_colors'"+`"`dif_tw'"'+substr("`cmdstrip_b'",`insertpos',strlen("`cmdstrip_b'"))
				local cmdstrip="`cmdstrip_a' "+`"`cmdstrip_b'"'
			}
			

			m: backup_e=st_tempname()
			m: stata("qui estimates store "+backup_e)
			
			m: st_local("errcode",strofreal(_stata(`"`cmdstrip'"' +" fix(prev used) err(stored) nit(0) tr(0) not noh")))
			if(`errcode'){
				exit `errcode'
			}
			
			
			
			mat temp_results=e(dif_results)
			mat temp_par_GR=e(dif_item_par_GR)
			mat temp_par_GF=e(dif_item_par_GF)
			
			m: stata("qui estimates restore "+backup_e)
			m: stata("qui estimates drop "+backup_e)
		
		}
	
		local ncol_temp=colsof(temp_results)
		if(`ncol_temp'>1){
			m: decimals=(3,4,3,3,3,3,3,3)
			m: _display_matrix_as_table("temp_results",decimals)
			
			return matrix dif_results temp_results
			return matrix dif_item_par_GR temp_par_GR
			return matrix dif_item_par_GF temp_par_GF
		}		
		
	}
	
end


mata
	void _display_matrix_as_table(string scalar matname, real matrix decimals){
		
		matrix_rown=st_matrixrowstripe(matname)[.,2]
		matrix_coln=st_matrixcolstripe(matname)[.,2]
		matrix_vals=st_matrix(matname)
		
		col_len=13
		n_col=cols(matrix_vals)
		
		printf("{txt}{hline "+strofreal(col_len)+"}{c TT}{hline "+strofreal(n_col*col_len)+"}\n")
		
		temp_line="{txt}{space 13}{c |}"
		for(c=1;c<=n_col;c++){
			temp_line=temp_line+" "*(13-strlen(matrix_coln[c]))+matrix_coln[c]
		}
		temp_line=temp_line+"\n"
		printf(temp_line)
		
		printf("{txt}{hline "+strofreal(col_len)+"}{c +}{hline "+strofreal(n_col*col_len)+"}\n")
	
		for(r=1;r<=rows(matrix_vals);r++){
			temp_line="{txt}"+matrix_rown[r]+" "*(13-strlen(matrix_rown[r]))+"{c |}"
			for(c=1;c<=cols(matrix_vals);c++){
				temp_val=strofreal(matrix_vals[r,c],"%9."+strofreal(decimals[c])+"f")
				temp_line=temp_line+"{res}"+" "*(13-strlen(temp_val))+temp_val
			}
			temp_line=temp_line+"\n"
			printf(temp_line)
		}
		
		printf("{txt}{hline "+strofreal(col_len)+"}{c BT}{hline "+strofreal(n_col*col_len)+"}\n")
		
	}
end
