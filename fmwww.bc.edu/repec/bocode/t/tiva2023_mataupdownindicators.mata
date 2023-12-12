capture mata: mata drop tiva2023_UpDownIndicators()
mata: 
	class tiva2023_UpDownIndicators extends tiva2023_commonICIO {
		real colvector UV_DOWNSTREAMNESS(), UV_UPSTREAMNESS(), UV_DOM_DOWNSTREAMNESS(), UV_FOR_DOWNSTREAMNESS(), UV_DOM_UPSTREAMNESS(), UV_FOR_UPSTREAMNESS(), UV_PII()
		// UV_ stands for Unit Value
		
		}
	
	real colvector tiva2023_UpDownIndicators::UV_DOWNSTREAMNESS(t, | string scalar ccc, string scalar ppp) {
		real matrix _Z, _A, _L
		real colvector _x
		real scalar toSelect
		
		toSelect = time_index :== t
		_Z = hci_ci' * select(Z, toSelect) * hci_ci
		_x = hci_ci' * select(x, toSelect)

		_A = _Z :/ _x'
		_editmissing(_A, 0)

		_L = luinv(I(N*K) - _A)
		
		result = (J(1, N*K, 1) * _L )'
		result = filter_dimension(result, ccc, ppp)		
		
		return(result)
		
		}

	real colvector tiva2023_UpDownIndicators::UV_UPSTREAMNESS(t, | string scalar ccc, string scalar ppp) {
		
		real matrix _Z, _B, _G
		real colvector _x
		real scalar toSelect
		
		toSelect = time_index :== t
		_Z = hci_ci' * select(Z, toSelect) * hci_ci
		_x = hci_ci' * select(x, toSelect)

		_B = _Z :/ _x
		_editmissing(_B, 0)

		_G = luinv(I(N*K) - _B)
		
		result = _G * J(N*K, 1, 1)
		result = filter_dimension(result, ccc, ppp)		
		
		return(result)
		
		}

	real colvector tiva2023_UpDownIndicators::UV_DOM_DOWNSTREAMNESS(t, | string scalar ccc, string scalar ppp) {
		real matrix _Z, _A, _L
		real colvector _x
		real scalar toSelect
		
		toSelect = time_index :== t
		_Z = hci_ci' * select(Z, toSelect) * hci_ci
		_x = hci_ci' * select(x, toSelect)

		_A = _Z :/ _x'
		_editmissing(_A, 0)

		_L = luinv(I(N*K) - _A)
		
		result = (J(1, N*K, 1) * (Dci_Dci :* _L) )'
		result = filter_dimension(result, ccc, ppp)		
		
		return(result)
		
		}

	real colvector tiva2023_UpDownIndicators::UV_FOR_DOWNSTREAMNESS(t, | string scalar ccc, string scalar ppp) {
		real matrix _Z, _A, _L
		real colvector _x
		real scalar toSelect
		
		toSelect = time_index :== t
		_Z = hci_ci' * select(Z, toSelect) * hci_ci
		_x = hci_ci' * select(x, toSelect)

		_A = _Z :/ _x'
		_editmissing(_A, 0)

		_L = luinv(I(N*K) - _A)
		
		result = (J(1, N*K, 1) * (Fci_Fci :* _L) )'
		
		return(result)
		result = filter_dimension(result, ccc, ppp)		
		
		}		

	real colvector tiva2023_UpDownIndicators::UV_DOM_UPSTREAMNESS(t, | string scalar ccc, string scalar ppp) {
		
		real matrix _Z, _B, _G
		real colvector _x
		real scalar toSelect
		
		toSelect = time_index :== t
		_Z = hci_ci' * select(Z, toSelect) * hci_ci
		_x = hci_ci' * select(x, toSelect)

		_B = _Z :/ _x
		_editmissing(_B, 0)

		_G = luinv(I(N*K) - _B)
		
		result = (Dci_Dci :* _G) * J(N*K, 1, 1)
		result = filter_dimension(result, ccc, ppp)		
		
		return(result)
		
		}

	real colvector tiva2023_UpDownIndicators::UV_FOR_UPSTREAMNESS(t, | string scalar ccc, string scalar ppp) {
		
		real matrix _Z, _B, _G
		real colvector _x
		real scalar toSelect
		
		toSelect = time_index :== t
		_Z = hci_ci' * select(Z, toSelect) * hci_ci
		_x = hci_ci' * select(x, toSelect)

		_B = _Z :/ _x
		_editmissing(_B, 0)

		_G = luinv(I(N*K) - _B)
		
		result = (Fci_Fci :* _G) * J(N*K, 1, 1)
		result = filter_dimension(result, ccc, ppp)		
		
		return(result)
		
		}

	real colvector tiva2023_UpDownIndicators::UV_PII(t, | string scalar ccc, string scalar ppp) {

		real colvector u, results
		u = J(hN*K, 1, 1)
		result = (u' * (colsum(hFci_hFci :* A(t))' :* (L(t)*diag(u))))'
		result = filter_dimension(result, ccc, ppp)		
		return(result)
		
		}	

end
