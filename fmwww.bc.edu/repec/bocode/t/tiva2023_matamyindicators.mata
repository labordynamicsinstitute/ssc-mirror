/* clear all */
/* local package_files = "tiva2023_matainitclass.mata tiva2023_mataimportfunctions.mata tiva2023_matacommoniciofunctions.mata tiva2023_mataoecdindicators.mata tiva2023_matastore.mata" */
/* foreach f of local package_files { */
/* 	findfile `f', path("g:/develop/tiva/tiva2023-stata-package/") */
/* 	run `r(fn)' */
/* 	} */

capture mata: mata drop tiva2023_MYindicators()
mata:
	class tiva2023_MYindicators extends tiva2023_commonICIO {

		// Block 1: Exports
		real colvector wp_e()	// world perspective, export of country i
		real colvector cp_e()	// country perspective, export of country i
		real colvector bp_e()	// bilateral perspective, export of country i
		real matrix e()			// real matrix of bilateral exports (hN*K, hN)
		
		// Block 2: AI & Astar matrices 
		real matrix wp_AI()	// world perspective, AI
		real matrix cp_AI()	// country perspective, AI
		real matrix bp_AI()	// bilateral perspective, AI
		real matrix Astar() // Astar = A - AI

		// Block 3: Decomposition of exports
		real matrix wp_MY() // world perspective, MY indicators
		real matrix cp_MY(), getCP_MY() // country perspective, MY indicators
		real matrix bp_MY(), getBP_MY() // country perspective, MY indicators 				

		real matrix getB()

		}

	/* ~~~~~~~~~~~~~~~~ */
	/* Block 1: exports */
	/* ~~~~~~~~~~~~~~~~ */

	real colvector tiva2023_MYindicators::wp_e(real scalar t) return(rowsum(e(t)))

	real colvector tiva2023_MYindicators::cp_e(real scalar t, real scalar i) {
		
		// country perspective, export of country i
		
		real colvector result
		i1 = (i-1)*K + 1
		iK = (i-1)*K + K

		result = J(hN*K, 1, 0)
		
		result[i1..iK] = rowsum(e(t))[i1..iK]
		return(result)

		}

	real colvector tiva2023_MYindicators::bp_e(real scalar t, real scalar i, real scalar j) {
		
		// country perspective, export of country i
		
		real colvector result
		i1 = (i-1)*K + 1
		iK = (i-1)*K + K

		result = J(hN*K, 1, 0)
		
		result[i1..iK] = e(t)[i1..iK, j]
		return(result)

		}

	real matrix tiva2023_MYindicators::e(real scalar t) return(((Z(t) :* hFci_hFci) * I(hN) # J(K, 1, 1)) :+ ((Y(t) :* hFci_hFc)))

	/* Block 1: END */

	/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
	/* Block 2: AI International production */
	/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

	real matrix tiva2023_MYindicators::Astar(real scalar t, real matrix AI) return(A(t) - AI)	
	
	real matrix tiva2023_MYindicators::wp_AI(real scalar t) return(hFci_hFci :* A(t))
	
	real matrix tiva2023_MYindicators::cp_AI(real scalar t, real scalar i) {

		// returns AI (country perspective)
		
		real matrix _A, result
		string colvector _hcou

		// I create a temporary hcou colvector where country names are recorded.
		// the difference with hcou is: when hcou == MX1 | MX2, then new temporary
		// hcou is equal to MEX.
		// this will allow me to spot if country i and country j are same country.
		_hcou = hcou 
		_MEXpos = _hcou :== "MEX" :|_hcou :== "MX1" :| _hcou :=="MX2"
		_CHNpos = _hcou :== "CHN" :|_hcou :== "CN1" :| _hcou :=="CN2"
		_hcou[selectindex(_MEXpos)] = J(colsum(_MEXpos), 1, "MEX")
		_hcou[selectindex(_CHNpos)] = J(colsum(_CHNpos), 1, "CHN")

		result = J(hN*K, hN*K, 0)
		_A = A(2005)

		i1 = (i-1)*K + 1
		iK = (i-1)*K + K
		
		for (j = 1; j<= hN; j++) {
			j1 = (j-1)*K + 1
			jK = (j-1)*K + K 
			if (_hcou[i] != _hcou[j]) result[i1..iK, j1..jK] = _A[j1..jK, i1..iK]
			}
	
		return(result)
		
		}

	real matrix tiva2023_MYindicators::bp_AI(real scalar t, real scalar i, real scalar j) {

		// returns AI (bilateral perspective)
		
		real matrix _A, result
		string colvector _hcou

		// I create a temporary hcou colvector where country names are recorded.
		// the difference with hcou is: when hcou == MX1 | MX2, then new temporary
		// hcou is equal to MEX.
		// this will allow me to spot if country i and country j are same country.
		_hcou = hcou 
		_MEXpos = _hcou :== "MEX" :|_hcou :== "MX1" :| _hcou :=="MX2"
		_CHNpos = _hcou :== "CHN" :|_hcou :== "CN1" :| _hcou :=="CN2"
		_hcou[selectindex(_MEXpos)] = J(colsum(_MEXpos), 1, "MEX")
		_hcou[selectindex(_CHNpos)] = J(colsum(_CHNpos), 1, "CHN")

		result = J(hN*K, hN*K, 0)
		_A = A(2005)

		i1 = (i-1)*K + 1
		iK = (i-1)*K + K
		j1 = (j-1)*K + 1
		jK = (j-1)*K + K
		
		if (_hcou[i] != _hcou[j]) result[i1..iK, j1..jK] = _A[i1..iK, j1..jK]

		return(result)
		
		}

	/* Block 2: END */

	/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
	/* Block 3: Decomposition of exports */
	/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

	real matrix tiva2023_MYindicators::wp_MY(real scalar t, | string scalar ccc, string scalar ppp) {

		real colvector DVA, DDC, FVA, FDC

		real colvector vx // Value-Added / gross output
		real colvector wp_e 
		real matrix Bstar
		real matrix BstarAIB

		vx = (J(1, hN*K, 1) * (I(hN*K) :- A(t)))'

		wp_e = wp_e(t)

		printf("Calculating Bstar with world perspective \n")
		Bstar = getB(Astar(t, wp_AI(t)))

		printf("Calculating Bstar * AI * B with world perspective \n")		
		BstarAIB = Bstar * wp_AI(t) * getB(A(t))

		DVA = DDC = FVA = FDC = J(hN*K, 1, 0)
		for (i=1; i<=hN; i++) {

			i1 = (i-1)* K + 1
			iK = (i-1)* K + K
			i1K = i1..iK
			
			DVA[i1K] = (vx[i1K]' * Bstar[i1K, i1K] * diag(wp_e[i1K]))'
			DDC[i1K] = (vx[i1K]' * BstarAIB[i1K, i1K] * diag(wp_e[i1K]))'

			for (j=1; j<=hN;j++) {
				if (j != i) {
					j1 = (j-1)*K + 1
					jK = (j-1)*K + K
					j1K = j1..jK

					FVA[i1K] = FVA[i1K] + (vx[j1K]' * Bstar[j1K, i1K] * diag(wp_e[i1K]))'
					FDC[i1K] = FDC[i1K] + (vx[j1K]' * BstarAIB[j1K, i1K] * diag(wp_e[i1K]))'
					}
				}
			}

		result = DVA, DDC, FVA, FDC
		result = filter_dimension(result, ccc, ppp)
		return(result)
		}

	real matrix tiva2023_MYindicators::cp_MY(real scalar t, | string scalar ccc, string scalar ppp) {

		/* TODO: print caution message that says "no partner dimension for this indicator if not missing ppp */
		
		real matrix result 

		if (ccc == "") {
			result = J(hN*K, 4, 0)			
			for (k = 1; k<= hN; k++) {
				k1 = (k-1) * K + 1
				kK = (k-1) * K + K
				k1K = k1..kK
				result[k1K, ] = getCP_MY(t, k)
				}
			}
		else {
			real scalar _i
			_i = selectindex(hcou :== ccc) 
			result = getCP_MY(t, _i)
			}

		
		return(result)
		
		}

	real matrix tiva2023_MYindicators::getCP_MY(t, i) {

		real colvector DVA, DDC, FVA, FDC

		real colvector vx // Value-Added / gross output
		real colvector cp_e 
		real matrix Bstar
		real matrix BstarAIB

		vx = (J(1, hN*K, 1) * (I(hN*K) :- A(t)))'
		
		cp_e = cp_e(t, i)
		
		printf("Calculating Bstar with country perspective for country %s \n", hcou[i])
		Bstar = getB(Astar(t, cp_AI(t,i)))
		
		printf("Calculating Bstar * AI * B with country perspective for country %s \n", hcou[i])
		BstarAIB = Bstar * cp_AI(t, i) * getB(A(t))			

		i1 = (i-1)* K + 1
		iK = (i-1)* K + K
		i1K = i1..iK

		DVA = (vx[i1K]' * Bstar[i1K, i1K] * diag(cp_e[i1K]))'
		DDC = (vx[i1K]' * BstarAIB[i1K, i1K] * diag(cp_e[i1K]))'

		FVA = FDC = J(K, 1, 0) 
		for (j=1; j<=hN;j++) {
			if (j != i) {
				j1 = (j-1)*K + 1
				jK = (j-1)*K + K
				j1K = j1..jK
				FVA = FVA + (vx[j1K]' * Bstar[j1K, i1K] * diag(cp_e[i1K]))'
				FDC = FDC + (vx[j1K]' * BstarAIB[j1K, i1K] * diag(cp_e[i1K]))'
				}
			}
		
		return((DVA, DDC, FVA, FDC))
		
		}

	real matrix tiva2023_MYindicators::bp_MY(real scalar t, | string scalar  ccc, string scalar ppp) {

		real matrix result

		real colvector i, j
		i = selectindex(hcou :== ccc)
		j = selectindex(hcou :== ppp)

		condition_i = i == J(0, 1, .)
		condition_j = j == J(0, 1, .)		

		if (condition_i != 1) {
			
			if (condition_j != 1) result = getBP_MY(t, i, j)

			else {
				result = J(hN*K, 4, .)
				for (k = 1; k<= hN; k++) {
					k1 = (k-1)*K + 1
					kK = (k-1)*K + K
					k1K = k1..kK
					result[k1K,] = getBP_MY(t, i, k)
					}
				}
			
			}
		else {
			if (condition_j != 1) {
				result = J(hN*K, 4, .)
				for (k = 1; k<=hN; k++) {
					k1 = (k-1)*K + 1
					kK = (k-1)*K + K
					k1K = k1..kK					
					result[k1K, ] = getBP_MY(t, k, j)
					}
				}
			else {
				result = J(hN*K*hN, 4, .)
				counter = 1
				for (k = 1; k<=hN; k++) {
					for (l=1; l<=hN; l++) {
						k1 = (k-1)*K + 1
						kK = (k-1)*K + K
						k1K = k1..kK						
						result[k1K, ] = getBP_MY(t, k, l)
						counter = counter + 1
						}
					}
				}
			}
		
		return(result)
		}

	real matrix tiva2023_MYindicators::getBP_MY(real scalar t, real scalar i, real scalar j) {

		real matrix result 
		real colvector DVA, DDC, FVA, FDC
		
		real colvector vx // Value-Added / gross output
		real colvector bp_e 
		real matrix Bstar
		real matrix BstarAIB

		vx = (J(1, hN*K, 1) * (I(hN*K) :- A(t)))'
		
		bp_e = bp_e(t, i, j)

		printf("Calculating Bstar & Bstar * AI * B with bilateral perspective for country %s and partner %s \n", hcou[i], hcou[j])
		Bstar = getB(Astar(t, bp_AI(t, i, j)))
		BstarAIB = Bstar * bp_AI(t, i, j) * getB(A(t))			

		i1 = (i-1)* K + 1
		iK = (i-1)* K + K
		i1K = i1..iK
		
		DVA = (vx[i1K]' * Bstar[i1K, i1K] * diag(bp_e[i1K]))'
		DDC = (vx[i1K]' * BstarAIB[i1K, i1K] * diag(bp_e[i1K]))'

		FVA = FDC = J(K, 1, 0) 
		for (k=1; k<=hN;k++) {
			if (k != i) {
				k1 = (k-1)*K + 1
				kK = (k-1)*K + K
				k1K = k1..kK
				FVA = FVA + (vx[k1K]' * Bstar[k1K, i1K] * diag(bp_e[i1K]))'
				FDC = FDC + (vx[k1K]' * BstarAIB[k1K, i1K] * diag(bp_e[i1K]))'
				}
			
}
		result = DVA, DDC, FVA, FDC
		return(result)
		
		}
	
	real matrix tiva2023_MYindicators::getB(real matrix input) return(luinv(I(hN*K) - input))
	
	/* Block 3: END */

	
end

