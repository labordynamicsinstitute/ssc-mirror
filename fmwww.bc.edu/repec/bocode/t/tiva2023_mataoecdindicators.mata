capture mata: mata drop tiva2023_oecdindicators()
mata:
	class tiva2023_oecdindicators extends tiva2023_commonICIO {

	
		/* ** TiVA Functions */
		
		real matrix _cons_org()
		real matrix OECD_EXGR_DVA(), OECD_EXGR_FVA()
		real matrix OECD_DFD_DVA(), OECD_DFD_FVA(), OECD_FFD_DVA() /* , FD_DVA(), FD_FVA() */
		real matrix OECD_BACKWARD(), OECD_FORWARD()
		

		}
	
	real matrix tiva2023_oecdindicators::_cons_org(t, cons, org)  {
		real vector toSelect
		real vector tY
		real vector _vx
		real matrix _B
		real matrix _vB
		real matrix _cons_matrix
		real matrix _ew_mult
		real matrix result

		_vx = vx_ratio(t)
		_B = B(t)
		_vB = diag(_vx) * _B

		// origin of value added
		if (strlower(org) == "dva") {
			_ew_mult = hDci_hDci
			}
		
		else if (strlower(org) == "fva") {
			_ew_mult = hFci_hFci
			}
		else {
			_error("the argument 'org' must be 'DVA' (domestic value-added) or 'FVA' (foreign value-added).")
			}
		
		// Destination of value-added: consumption
		if (strlower(cons) == "exgr") {
			_cons_matrix = EXGR(t)
			}
		else if (strlower(cons) == "dfd") {
			_cons_matrix = hDci_Dc :* (Y(t) * hc_c)
			}
		else if (strlower(cons) == "ffd") {
			_cons_matrix = hFci_Fc :* (Y(t) * hc_c)
			}		
		else if (strlower(cons) == "fd") {
			_cons_matrix = Y(t) * hc_c
			}
		
		result = colsum(_ew_mult :* _vB)' :* _cons_matrix
		return(result)
		}

	real matrix tiva2023_oecdindicators::OECD_EXGR_DVA(t, | string scalar ccc, string scalar ppp) {
		real matrix result
		result = _cons_org(t, "EXGR", "DVA")
		result = filter_dimension(result, ccc, ppp)
		return(result)
		}

	real matrix tiva2023_oecdindicators::OECD_EXGR_FVA(t, | string scalar ccc, string scalar ppp) {
		real matrix result
		result = _cons_org(t, "EXGR", "FVA")
		result = filter_dimension(result, ccc, ppp)		
		return(result)
		}

	real matrix tiva2023_oecdindicators::OECD_DFD_DVA(t, | string scalar ccc, string scalar ppp) {
		real colvector result
		real scalar n, n1, nK
		B = B(t)
		vx = vx_ratio(t)
		vB = diag(vx) * B
	
		result = J(hN*K, 1, .)
		for (n = 0; n <= hN-1; n++) {
			n1 = n * K + 1
			nK = n * K + K
			dY = _nY(t, n+1)
			result[n1..nK, ] = vB[n1..nK, ] * dY
			}

		result = filter_dimension(result, ccc, ppp)		
		return(result)
		}

	real matrix tiva2023_oecdindicators::OECD_DFD_FVA(t, | string scalar ccc, string scalar ppp) {
		real colvector result
		real _f_vB 
		real scalar n, n1, nK
		B = B(t)
		vx = vx_ratio(t)
		vB = diag(vx) * B
	
		result = J(hN*K, 1, 0)
		for (n = 0; n <= N-1; n++) {
			n1 = n * K + 1
			nK = n * K + K
			dY = _nY(t, n+1)
			_f_vB = _get_ForeignRows(vB, n+1)
			result[n1..nK, ] = hci_i' * _f_vB * dY
			}
		result = filter_dimension(result, ccc, ppp)		
		return(result)
		}
	
	real matrix tiva2023_oecdindicators::OECD_FFD_DVA(t, | string scalar ccc, string scalar ppp) {
		real matrix fY, result
		real scalar n, n1, nK
		B = B(t)
		vx = vx_ratio(t)
		vB = diag(vx) * B
	
		result = J(hN*K, hN, .)
		for (n = 0; n <= hN-1; n++) {
			n1 = n * K + 1
			nK = n * K + K
			fY = Y(t)
			fY[,n+1] = J(hN*K, 1, 0)
			if (n+1==66|n+1==67) fY[, selectindex(hcou:=="MEX")] = J(hN*K, 1, 0)
			if (n+1==68|n+1==69) fY[, selectindex(hcou:=="CHN")] = J(hN*K, 1, 0)			
			result[n1..nK, ] = vB[n1..nK, ] * fY
			}
		result = filter_dimension(result, ccc, ppp)		
		return(result)
		}
	

	real matrix tiva2023_oecdindicators::OECD_BACKWARD(t, | string scalar ccc, string scalar ppp) {
		real colvector _vx, _e
		real matrix _B, _vB
		_vx = vx_ratio(t)
		_B = B(t)
		_vB = diag(_vx) * _B
		_e = rowsum(EXGR(t))
		result = colsum(hFci_hFci :* _vB)' :* _e
		result = filter_dimension(result, ccc, ppp)		
		return (result)
		}

	real matrix tiva2023_oecdindicators::OECD_FORWARD(t, | string scalar ccc, string scalar ppp) {
		real colvector _vx, _e
		real matrix _B, _vB, _vBe
		_vx = vx_ratio(t)
		_B = B(t)
		_vB = diag(_vx) * _B
		_e = rowsum(EXGR(t))
		_vBe = hci_ci' * (hFci_hFci :* _vB * diag(_e)) * hci_ci

		_ci_c = I(N) # J(K, 1, 1) 
		result = J(N, 0, .)
		for (k = 1; k<= K; k++) {
			_kci = J(1, K, 0)
			_kci[k] = 1
			_kci = J(N*K, N, 1) # _kci

			result = result, _ci_c' * rowsum(_vBe :* _kci)
			
			}

		result_long = J(N*K, 1, 1)
		for (n=1; n<= N; n++) {
			n1 = (n-1)*K+1
			nK = (n-1)*K+K
			n1K = n1..nK

			result_long[n1K] = result[n,]'
			}
		result = filter_dimension(result, ccc, ppp)		
		return(result_long)
		}
end
