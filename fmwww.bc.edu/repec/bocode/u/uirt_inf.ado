*uirt_inf.ado 
*ver 1.0
*2022.02.11
*everythingthatcounts@gmail.com

capture prog drop uirt_inf
program define uirt_inf
version 10
syntax [varlist] [, Test se GRoups tw(str asis)] 
	
	if("`e(cmd)'" != "uirt"){
		error 301
	}
	else{
	
		if("`0'"==""){
			local postest="inf(*)"	
		}
		else{
			local postest="inf("+`"`0'"'+")"
		}
	
		m: backup_e=st_tempname()
		m: stata("qui estimates store "+backup_e)
		
		m: st_local("errcode",strofreal(_stata("`e(cmdstrip)' " + `"`postest'"' + " fix(prev used) err(stored) nit(0) tr(0) not noh")))
		if(`errcode'){
			exit `errcode'
		}
		
		m: stata("qui estimates restore "+backup_e)
		m: stata("qui estimates drop "+backup_e)
	
	}
		
end


