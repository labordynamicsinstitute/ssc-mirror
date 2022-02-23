*uirt_theta.ado 
*ver 1.1
*2022.01.24
*everythingthatcounts@gmail.com

capture prog drop uirt_theta
program define uirt_theta
version 10
syntax [namelist] [, eap nip(numlist integer max=1 >=2 <=195) pv(numlist integer max=1 >=0) pvreg(str) SUFfix(namelist max=1) SCale(numlist max=2 min=2) SKIPNote]  
	
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
			
		m: st_local("errcode",strofreal(_stata("`e(cmdstrip)' `postest' fix(prev used) err(stored) nit(0) tr(0) not noh")))
		if(`errcode'){
			exit `errcode'
		}
		
		m: stata("qui estimates restore "+backup_e)
		m: stata("qui estimates drop "+backup_e)
	
	}
	
end

