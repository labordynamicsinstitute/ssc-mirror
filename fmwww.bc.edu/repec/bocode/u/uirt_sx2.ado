*uirt_sx2.ado 
*ver 1.0
*2021.03.07
*everythingthatcounts@gmail.com

cap m: mata drop  _display_matrix_as_table()

capture prog drop uirt_sx2
program define uirt_sx2, rclass
version 10
syntax [varlist] [, MINFreq(numlist max=1 >0)] 
	
	if("`e(cmd)'" != "uirt"){
		error 301
	}
	else{
	
		m: decimals=(3,4,0,0)
		local postest="sx2(`0')"
		
		unab allvars: *
		if("`allvars'"=="`varlist'"){
			local varlist=""
		}
	
		cap mat l  e(item_fit_SX2)
		local if_sx2= _rc==0
		
		if("`varlist'"=="" & "`minfreq'"=="" & `if_sx2'){
			mat temp=e(item_fit_SX2)
		}
		else{
			if("`postest'"=="sx2()"){
				local postest="sx2(*)"
			}

			m: backup_e=st_tempname()
			m: stata("qui estimates store "+backup_e)
			
			m: stata("`e(cmdstrip)' `postest' fix(prev used) err(stored) nit(0) tr(0) not noh")
			mat temp=e(item_fit_SX2)
			
			m: stata("qui estimates restore "+backup_e)
			m: stata("qui estimates drop "+backup_e)
		
		}
	
		local ncol_temp=colsof(temp)
		if(`ncol_temp'>1){
			m: _display_matrix_as_table("temp",decimals)
			return matrix item_fit_SX2 temp 
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
