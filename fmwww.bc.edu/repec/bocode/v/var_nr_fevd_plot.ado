program define var_nr_fevd_plot, rclass
version 16.0

	syntax , FEVD(string) VARname(string) OPTname(string) [FEVDBands(string) SRname(string)]
	
	if "`srname'"=="" {
		if "`fevdbands'"=="" {
			di as error "Missing FEVD bands input"
			exit 198
		}
		else {
			mata: fevd_plot(`fevd',`fevdbands',`varname',`optname')
		}
	}
	else {
		mata: fevd_plot(asarray(`fevd',"median"),asarray(`fevd',"bands"),`varname',`optname')
	}
	
end