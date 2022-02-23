*uirt_esf.ado 
*ver 1.0
*2022.02.09
*everythingthatcounts@gmail.com

capture prog drop uirt_esf
program define uirt_esf
version 10
syntax [varlist] [, bins(numlist integer max=1 >=1) Format(str) CLeargraphs NOObs Color(str) tw(str asis) PREFix(str) SUFfix(str) all tesf] 
	
	if("`e(cmd)'" != "uirt"){
		error 301
	}
	else{
	
		if("`0'"==""){
			local postest="esf(*)"	
		}
		else{
			local postest="esf("+`"`0'"'+")"
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

