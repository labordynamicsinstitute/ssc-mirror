*uirt_theta.ado 
*ver 1.0
*2021.03.09
*everythingthatcounts@gmail.com

capture prog drop uirt_theta
program define uirt_theta
version 10
syntax [anything] 
	
	if("`e(cmd)'" != "uirt"){
		error 301
	}
	else{
	
		if("`0'"==""){
			local postest="theta(eap)"	
		}
		else{
			local postest="theta(`0')"	
		}
	
		m: backup_e=st_tempname()
		m: stata("qui estimates store "+backup_e)
		
		m: stata("`e(cmdstrip)' `postest' fix(prev used) err(stored) nit(0) tr(0) not noh")
		
		m: stata("qui estimates restore "+backup_e)
		m: stata("qui estimates drop "+backup_e)
	
	}
	
end

