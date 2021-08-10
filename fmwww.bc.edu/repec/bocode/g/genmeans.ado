capture program drop genmeans
program define genmeans
	version 9.0
	syntax varname, CONtextvars(varlist) RESpid(varname) 
	
	capture drop `varlist'_ctx_mean
	capture drop `varlist'_resp_mean
	
	bysort `contextvars': egen `varlist'_ctx_mean = mean(`varlist')
	bysort `contextvars' `respid': egen `varlist'_resp_mean = mean(`varlist')
	
	
end
