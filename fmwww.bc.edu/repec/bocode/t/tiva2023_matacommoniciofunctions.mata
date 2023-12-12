
capture mata: mata drop tiva2023_commonICIO()
mata:
	class tiva2023_commonICIO extends tiva2023 {
		
		real matrix hN_to_N()
		real matrix Y(), GVA(), GOP()
		real matrix A(), B(), L(), Z()
		real colvector vx_ratio(), _nY()
		real matrix _get_ForeignRows()
		real matrix _EXGR(), _IMGR(), IMGR_INT(), IMGR_FNL(), IMGR(), EXGR_INT(), EXGR_FNL(), EXGR()
		real matrix DOWNSTREAMNESS(), UPSTREAMNESS()		
		real matrix filter_dimension()
		}

	real matrix tiva2023_commonICIO::Z(real scalar t, | string scalar ccc, string scalar ppp) {
		real matrix result
		result = filter_dimension(select(Z, time_index :== t), ccc, ppp)
		return(result)
		}
		

	real matrix tiva2023_commonICIO::hN_to_N(real matrix result) {

		if (rows(result) == hN*K) result = hci_ci' * result
		if (rows(result) == hN) result = hc_c' * result		
		if (cols(result) == hN*K) result = result * hci_ci
		if (cols(result) == hN) result = result * hc_c
		
		return(result)
		
		}

	real matrix tiva2023_commonICIO::GVA(real scalar t, | string scalar ccc, string scalar ppp) {
		real matrix result
		result = select(v, time_index :== t) 
		/* result = (J(1, hN*K, 1) * (I(hN * K) - Z(2005)))' */
		result = filter_dimension(result, ccc, ppp)
		return(result)

		}

	real matrix tiva2023_commonICIO::GOP(real scalar t, | string scalar ccc, string scalar ppp) {
		real matrix result
		result = select(x, time_index :== t)
		result = filter_dimension(result, ccc, ppp)		
		return(result)
		}

	real matrix tiva2023_commonICIO::A(real scalar t, | string scalar ccc, string scalar ppp) {
		
		real matrix result
		result = select(Z, time_index :== t) :/ select(x,time_index :== t)'
		_editmissing(result, 0)
		result = filter_dimension(result, ccc, ppp)
		return(result)
		}

	real colvector tiva2023_commonICIO::vx_ratio(real scalar t, | string scalar ccc, string scalar ppp) {
		real colvector toSelect
		real colvector result
		toSelect = time_index :== t
		result = (J(1, hN*K, 1) * (I(hN*K) - A(t)))'
		_editmissing(result, 0)
		result = filter_dimension(result, ccc, ppp)
		return(result)
		}
	

	real matrix tiva2023_commonICIO::Y(real scalar t, | string scalar ccc, string scalar ppp) {
		real colvector toSelect
		real matrix result
		toSelect = time_index :== t
		result = (select(Y, toSelect) * hcf_c), J(hN*K,4,0)
		result = filter_dimension(result, ccc, ppp)
		return(result)
		}
	
	real colvector tiva2023_commonICIO::_nY(real scalar t, real scalar n) {
		real colvector toSelect, result
		real matrix Y
		Y = Y(t)
		if (!(hcou[n]:== "MEX" | hcou[n] :== "MX1" | hcou[n] == "MX2" | hcou[n]:== "CHN" | hcou[n] :== "CN1" | hcou[n] == "CN2")) result = Y[, n]
		else if (hcou[n]:== "MEX" | hcou[n] :== "MX1" | hcou[n] == "MX2") result = rowsum(Y[,(selectindex(hcou:=="MEX"), selectindex(hcou:=="MX1"), selectindex(hcou:=="MX2"))])
		else if (hcou[n]:== "CHN" | hcou[n] :== "CN1" | hcou[n] == "CN2") result = rowsum(Y[,(selectindex(hcou:=="CHN"), selectindex(hcou:=="CN1"), selectindex(hcou:=="CN2"))])

		return(result)
		}

	real matrix tiva2023_commonICIO::_get_ForeignRows(real matrix inputMatrix, real scalar n) {
		real scalar n1, nK
		real scalar MEXcondition, CHNcondition 
		real colvector selection 
		
		n1 = (n-1) * K + 1
		nK = (n-1) * K + K
		
		result = inputMatrix

		MEXcondition = hcou[n] :== "MEX" | hcou[n] :== "MX1" | hcou[n] :== "MX2"
		CHNcondition = hcou[n] :== "CHN" | hcou[n] :== "CN1" | hcou[n] :== "CN2"

		if (!(MEXcondition == 1 | CHNcondition == 1)) {
			selection = n1::nK
			}
		else if (MEXcondition) {
			selection = ( ///
			  ((selectindex(hcou:=="MEX") - 1) * K + 1)::((selectindex(hcou:=="MEX") - 1) * K + K) \ ///
			  ((selectindex(hcou:=="MX1") - 1) * K + 1)::((selectindex(hcou:=="MX1") - 1) * K + K) \ ///
			  ((selectindex(hcou:=="MX2") - 1) * K + 1)::((selectindex(hcou:=="MX2") - 1) * K + K))
			}
		else if (CHNcondition) {
			selection = ( ///
			  ((selectindex(hcou:=="CHN") - 1) * K + 1)::((selectindex(hcou:=="CHN") - 1) * K + K) \ ///
			  ((selectindex(hcou:=="CN1") - 1) * K + 1)::((selectindex(hcou:=="CN1") - 1) * K + K) \ ///
			  ((selectindex(hcou:=="CN2") - 1) * K + 1)::((selectindex(hcou:=="CN2") - 1) * K + K))
			}

		result[selection, ] = J(rows(selection), cols(inputMatrix), 0)

		return(result) 
		}

	real matrix tiva2023_commonICIO::B(real scalar t, | string scalar ccc, string scalar ppp) {
		real matrix result
		result = luinv(I(cols(A(t))) - A(t))
		result = filter_dimension(result, ccc, ppp)
		return(result)
		}
	
	real matrix tiva2023_commonICIO::L(real scalar t, | string scalar ccc, string scalar ppp) {
		real matrix _Ad, result
		_Ad = hFci_hFci :* A(t)
		result = luinv(I(cols(_Ad)) - _Ad)
		result = filter_dimension(result, ccc, ppp)
		return(result)
		}

	real matrix tiva2023_commonICIO::_EXGR(t, string scalar segment) {
		real colvector toSelect
		real matrix result
		real matrix tY, tZ		

		toSelect = time_index :== t
		tY = select(Y, toSelect) * hcf_c
		tZ = select(Z, toSelect)
		
		if (segment == "INT") {
			result = (tZ:*hFci_hFci) * I(hN)#J(K,1,1)
			}
		else if (segment == "FNL") {
			result = (Y(t) :* hFci_hFc)
			}
		else if (segment == "TOTAL") {
			result = ((tZ :* hFci_hFci) * I(hN) # J(K, 1, 1)) :+ ((Y(t) :* hFci_hFc))
			}
		return(result)
		}

	
	
	real matrix tiva2023_commonICIO::_IMGR(t, string scalar segment) {
		real matrix EXGR
		real matrix results
		real scalar n, n1, nK, p, p1, pK
		
		EXGR = _EXGR(t, segment)
		results = J(rows(EXGR), cols(EXGR), .)
		for(n = 0 ; n <= cols(EXGR) - 1; n++) {
			n1 = n * K + 1
			nK = n * K + K
			for (p = 0; p <= cols(EXGR) - 1; p++) {
				p1 = p * K + 1
				pK = p * K + K
				results[p1..pK,n+1] = EXGR[n1..nK,p+1]			
				}
			}

		return(results)
		}

	// Based on former private functions, I create EXGR and IMGR functions with only one argument

	// Exports
	real matrix tiva2023_commonICIO::EXGR(t, | string scalar ccc, string scalar ppp) {
		real matrix result
		result = _EXGR(t, "TOTAL")
		result = filter_dimension(result, ccc, ppp)
		return(result)
		}
	real matrix tiva2023_commonICIO::EXGR_INT(t, | string scalar ccc, string scalar ppp) {
		real matrix result
		result = _EXGR(t, "INT")
		result = filter_dimension(result, ccc, ppp)
		return(result)
		}
	real matrix tiva2023_commonICIO::EXGR_FNL(t, | string scalar ccc, string scalar ppp) {
		real matrix result
		result = _EXGR(t, "FNL")
		result = filter_dimension(result, ccc, ppp)
		return(result)
		}

	// Imports
	real matrix tiva2023_commonICIO::IMGR(t, | string scalar ccc, string scalar ppp) {
		real matrix result
		result = _IMGR(t, "TOTAL")
		result = filter_dimension(result, ccc, ppp)
		return(result)
		}
	
	real matrix tiva2023_commonICIO::IMGR_INT(t, | string scalar ccc, string scalar ppp) {
		real matrix result
		result = _IMGR(t, "INT")
		result = filter_dimension(result, ccc, ppp)
		return(result)
		}
	real matrix tiva2023_commonICIO::IMGR_FNL(t, | string scalar ccc, string scalar ppp) {
		real matrix result
		result = _IMGR(t, "FNL")
		result = filter_dimension(result, ccc, ppp)
		return(result)
		}

	real matrix tiva2023_commonICIO::DOWNSTREAMNESS(t, | string scalar ccc, string scalar ppp) {
		real matrix _Z, _A, _L
		real colvector _x
		real scalar toSelect
		
		toSelect = time_index :== t
		_Z = hci_ci' * select(Z, toSelect) * hci_ci
		_x = hci_ci' * select(x, toSelect)

		_A = _Z :/ _x'
		_editmissing(_A, 0)

		_L = luinv(I(N*K) - _A)
		ci_c = I(N) # J(K, 1, 1)
		
		result = (ci_c' * _L )'
		
		result = filter_dimension(result, ccc, ppp)
		return(result)
		
		}

	real matrix tiva2023_commonICIO::UPSTREAMNESS(t, | string scalar ccc, string scalar ppp) {
		
		real matrix _Z, _B, _G
		real colvector _x
		real scalar toSelect
		
		toSelect = time_index :== t
		_Z = hci_ci' * select(Z, toSelect) * hci_ci
		_x = hci_ci' * select(x, toSelect)

		_B = _Z :/ _x
		_editmissing(_B, 0)

		_G = luinv(I(N*K) - _B)
		ci_c = I(N) # J(K, 1, 1)
		result = _G * ci_c
		result = filter_dimension(result, ccc, ppp)
		return(result)
		
		}

	real matrix tiva2023_commonICIO::filter_dimension(real matrix input, | string scalar ccc, string scalar ppp) {

		real colvector c, p
		real matrix result
		
		c = selectindex(hcou :== ccc)
		p = selectindex(hcou :== ppp)

		condition_c = c == J(0, 1, .)
		condition_p = p == J(0, 1, .)

		if (condition_c == 1 & condition_p == 1) result = input
		
		else if (condition_c != 1 & condition_p == 1) {

			c1 = (c-1)*K + 1
			cK = (c-1)*K + K
			c1K = c1..cK

			result = input[c1K, ]
			
			}
		else if (condition_c != 1 & condition_p != 1) {

			c1 = (c-1)*K + 1
			cK = (c-1)*K + K
			c1K = c1..cK

			if (cols(input) == hN | cols(input) == N) result = input[c1K, p]
			else if (cols(input) == hN*K) {
				p1 = (p-1)*K + 1
				pK = (p-1)*K + K
				p1K = p1..pK
				result = input[c1K, p1K]
				}
			}
		
		return(result)
		
		}

end
