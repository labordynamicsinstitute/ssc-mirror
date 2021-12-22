program define var_nr_hd_plot, rclass
version 16.0

	syntax , HD(string) VARname(string) OPTname(string) [SRname(string)]
	
	if "`srname'"=="" {
		mata: hd_plot(`hd',`varname',`optname')
	}
	else {
		mata: hd_plot(asarray(`hd',"median"),`varname',`optname')
	}
	
end
