program define var_nr_irf_plot, rclass
version 16.0

	syntax , IRF(string) VARname(string) OPTname(string) [IRFBands(string) SRname(string)]
	
	if "`srname'"=="" {
		if "`irfbands'"=="" {
			di as error "Missing IRF bands or SR name input"
			exit 198
		}
		else {
			mata: irf_plot(`irf',`irfbands',`varname',`optname')
		}
	}
	else {
		mata: irf_plot(asarray(`irf',"median"),asarray(`irf',"bands"),`varname',`optname')
	}
	
end