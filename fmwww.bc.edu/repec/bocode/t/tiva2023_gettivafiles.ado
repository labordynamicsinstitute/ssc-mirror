capture program drop tiva2023_getTivaFiles
program define tiva2023_getTivaFiles, nclass
	syntax, path(string) years(string)

	tiva2023_getPath, path(`"`path'"')
	local path = `"`r(path)'"'
	
	// I_ Dimensions
	local nYears : list sizeof local(years)
	mata {
		T = strtoreal(st_local("nYears"))
		hN = 81
		N = 77
		K = 45
		F = 6
		
		}

	// year and time_index
	mata: year = J(0, 1, .)
	foreach yyyy of local years {
		mata: year = year \ `yyyy'
		}

	// time_index
	mata {
		time_index = J(T*hN*K, 1, .)
		for(t=0; t<=rows(year)-1; t++) {
			t1 = t*hN*K + 1
			tNK = t*hN*K + hN*K
			time_index[t1..tNK] = J(hN*K,1, year[t+1])
			}

		time_indexN = J(T*N*K, 1, .)
		for(t=0; t<=rows(year)-1; t++) {
			t1 = t*N*K + 1
			tNK = t*N*K + N*K
			time_indexN[t1..tNK] = J(N*K,1, year[t+1])
			}		
		}

	// _icio matrices
	mata {
		Z = J(0, hN*K, .)
		Y = J(0, N*F, .)
		x = v = J(0, 1, .)
		}
	
	foreach yyyy of local years {

		display `"`yyyy'"'
		
		// ICIO in Stata memory
		local currentPath = c(pwd)
		/* cd `"`path'"' */
		/* unzipfile "`path'icio2023_`yyyy'.zip", replace */
		insheet using `path'`yyyy'.csv, names clear
		/* cd `"`currentPath'"' */
		/* erase "`c(pwd)'//icio2023_`yyyy'.csv" */

		// Retrieve ICIO vectors
		mata {

			Z = Z \ st_data(1::hN*K, 2..hN*K+1)
			Y = Y \ st_data(1::hN*K, hN*K+2.. hN*K+N*F+1)
			v = v \ colsum(st_data(hN * K + 2:: hN * K + 3, 2..hN*K+1))'
			x = x \ st_data(hN*K+3, 2..hN*K+1)'
			}

		}

	// II_ Descriptions
	mata {
		/* countries */
		hcou = substr(st_sdata(range(K,hN*K,K),1),1,3)
		cou = substr(st_sdata(range(K,hN*K,K),1),1,3)[1..N]
		
		/* industries */
		ind = J(K, 1, "D") :+ substr(st_sdata(range(1,K,1),1),5,.)

		/* Countries & industries */
		cou_ind = J(N*K,2,"")
		cou_ind[,1] = substr(st_sdata(1::N*K,1),1,3)
		/* cou_ind[,2] = J(N*K, 1, "D") :+ substr(st_sdata(1::N*K,1),5,.)		 */
		cou_ind[,2] = substr(st_sdata(1::N*K,1),5,.)
		hcou_ind = J(hN*K,2,"")
		hcou_ind[,1] = substr(st_sdata(1::hN*K,1),1,3)
		hcou_ind[,2] = J(hN*K, 1, "D") :+ substr(st_sdata(1::hN*K,1),5,.)
		
		/* Year & countries & industries */
		year_cou_ind = J(T*N*K, 3, "")
		year_hcou_ind = J(T*hN*K, 3, "")
		
		for(t = 0; t<=T-1; t++) {
			
			t1 = t*N*K + 1
			tNK = t*N*K + N*K
			
			/* year_cou_ind */
			year_cou_ind[t1..tNK,1] = strofreal(J(N*K,1,1)#year[t+1])
			year_cou_ind[t1..tNK, 2] = cou_ind[,1]
			year_cou_ind[t1..tNK, 3] = cou_ind[,2]
			
			/* year_hcou_ind */
			t1 = t*hN*K + 1
			thNK = t*hN*K + hN*K
			
			year_hcou_ind[t1..thNK,1] = strofreal(J(hN*K,1,1)#year[t+1])
			year_hcou_ind[t1..thNK, 2] = hcou_ind[,1]
			year_hcou_ind[t1..thNK, 3] = hcou_ind[,2]
			}
		}

	// III_ Transition matrices
	mata {
		
		split = 2 /* CHN & MEX are split into two */
		
		/* Position of MEX & CHN */
		_pos_MEX = hcou  :== "MEX"
		_pos_CHN = hcou  :== "CHN"
	
		/* HCI_C: heterogeneous country/industry to */
		/* country / industry */
		_add_MEX = _pos_MEX[1..N]'#(J(split,1,1)#I(K))
		_add_CHN = _pos_CHN[1..N]'#(J(split,1,1)#I(K))
		_ALL = I(N*K)
		hci_ci = _ALL \ (_add_MEX) \ (_add_CHN)
		
		/* HCI_C: heterogeneous country/industry to */
		/* country */
		_add_MEX = _pos_MEX[1..N]'#(J(split,1,1)#J(K,1,1))
		_add_CHN = _pos_CHN[1..N]'#(J(split,1,1)#J(K,1,1))
		_ALL = I(N) # J(K,1,1)
		hci_c = _ALL \ (_add_MEX) \ (_add_CHN)

		/* HCF_C: Heterogeneous Country/ FD components to */
		/* Country  */
		_ALL = I(N)#J(F,1,1)
		/* _add_MEX = _pos_MEX[1..N]'#(J(split,1,1)#J(F,1,1)) */
		/* _add_CHN = _pos_CHN[1..N]'#(J(split,1,1)#J(F,1,1)) */
		hcf_c = _ALL /* \ (_add_MEX) \ (_add_CHN) */

		_gfcf = J(F,1,0)
		_gfcf[4] = 1
		_ALL = I(N)#_gfcf
		/* _add_MEX = _pos_MEX[1..N]'#(J(split,1,1)#_gfcf) */
		/* _add_CHN = _pos_CHN[1..N]'#(J(split,1,1)#_gfcf) */
		hcf_c_gfcf = _ALL /* \ (_add_MEX) \ (_add_CHN) */

		hci_i = J(hN, 1, 1) # I(K)

		hc_c = I(N) \ _pos_MEX[1..N]' # J(split, 1, 1)  \ _pos_CHN[1..N]' # J(split, 1, 1) 

		}

	// IV_ Domestic and Foreign matrices

	mata {

		_pos_allMEX = (hcou  :== "MEX" :| hcou  :== "MX1" :| hcou  :== "MX2")
		_pos_allCHN = (hcou  :== "CHN" :| hcou  :== "CN1" :| hcou  :== "CN2")
	
		/* Dci_Dci & Fci_Fci */
		_ALL = I(N) # J(K,K,1)
		_add_allMEX = _pos_allMEX'#(J(split,1,1)#J(K,K,1))
		_add_allCHN = _pos_allCHN'#(J(split,1,1)#J(K,K,1))
		hDci_hDci = (_ALL \ _add_allMEX[.,1..N*K] \ _add_allCHN[.,1..N*K]), _add_allMEX', _add_allCHN'
		hFci_hFci = J(hN * K, hN * K, 1) - hDci_hDci

		Dci_Dci = I(N)#J(K,K,1)
		Fci_Fci = J(N*K,N*K,1) - Dci_Dci
	
		/* Dci_Dc & Fci_Fc */
		_ALL = I(N) # J(K,1,1)
		_add_allMEX = _pos_allMEX'#(J(split,1,1)#J(K,1,1))
		_add_allCHN = _pos_allCHN'#(J(split,1,1)#J(K,1,1))
		hDci_Dc = (_ALL \ _add_allMEX[.,1..N] \ _add_allCHN[.,1..N])
		hFci_Fc = J(hN * K, N, 1) - hDci_Dc

		_ALL = I(N) # J(K,1,1)
		_add_allMEX = _pos_allMEX' # (J(split, 1, 1) # J(K, 1, 1))
		_add_allCHN = _pos_allCHN' # (J(split, 1, 1) # J(K, 1, 1))
		hDci_Dc = (_ALL \ _add_allMEX[.,1..N] \ _add_allCHN[.,1..N])
		hFci_Fc = J(hN * K, N, 1) - hDci_Dc

		hDci_hDc = (_ALL \ _add_allMEX[.,1..N] \ _add_allCHN[.,1..N]), _pos_allMEX # J(K, 1, 1),_pos_allMEX # J(K, 1, 1), _pos_allCHN # J(K, 1, 1), _pos_allCHN # J(K, 1, 1)
		hFci_hFc = J(hN*K, hN, 1) - hDci_hDc

		Dci_Dc = I(N) # J(K,1,1)
		Fci_Fc = J(N*K,N,1) - Dci_Dc
	
		}

	/*~~~~~~~~~~~~~~~~~~~~~~~~~*/
	/* Save in own format */
	/*~~~~~~~~~~~~~~~~~~~~~~~~~*/

	/* local matrices = "_dimensions _descriptions  _ICIO _index _transitions _ew_multiplications" */
	/* foreach matrix of local matrices { */
	/* 	capture erase "`path'\\`matrix'.mmat" */
	/* 	} */
	
	mata {
		
		dimNames ="T",	"hN", "N", "K", "F"
		fh = fopen("`path'_dimensions.mmat", "w")
		fputmatrix(fh,dimNames)
		fputmatrix(fh, T)
		fputmatrix(fh, hN)
		fputmatrix(fh, N)
		fputmatrix(fh, K)
		fputmatrix(fh, F)
		fclose(fh)

		/* _descriptions */
		descrNames = "year", "hcou", "cou", "ind", "year_cou_ind", "year_hcou_ind", "hcou_ind", "cou_ind"
		fh = fopen("`path'_descriptions.mmat", "w")
		fputmatrix(fh, descrNames)
		fputmatrix(fh, year)
		fputmatrix(fh, hcou)
		fputmatrix(fh, cou)
		fputmatrix(fh, ind)
		fputmatrix(fh, year_cou_ind)
		fputmatrix(fh, year_hcou_ind)
		fputmatrix(fh, hcou_ind)
		fputmatrix(fh, cou_ind)
		fclose(fh)

		/* _ICIO */
		icioNames = "v", "x", "Z", "Y"
		fh = fopen("`path'_ICIO.mmat", "w")
		fputmatrix(fh, icioNames)
		fputmatrix(fh, v)
		fputmatrix(fh, x)
		fputmatrix(fh, Z)
		fputmatrix(fh, Y)
		fclose(fh)

		/* _index */
		indexNames = "time_index", "time_indexN"
		fh = fopen("`path'_index.mmat", "w")
		fputmatrix(fh, indexNames)
		fputmatrix(fh, time_index)
		fputmatrix(fh, time_indexN)		
		fclose(fh)

		/* _transitions */
		transitionNames = "hci_ci", "hci_c", "hcf_c", "hcf_c_gfcf", "hci_i", "hc_c"
		fh = fopen("`path'/_transitions.mmat", "w")
		fputmatrix(fh, transitionNames)
		fputmatrix(fh, hci_ci)
		fputmatrix(fh, hci_c)
		fputmatrix(fh, hcf_c)
		fputmatrix(fh, hcf_c_gfcf)
		fputmatrix(fh, hci_i)
		fputmatrix(fh, hc_c)
		fclose(fh)

		/* _ew_multiplications */
		ewmultNames = "hDci_hDci", "hFci_hFci", "hDci_Dc", "hFci_Fc", "Dci_Dci", "Fci_Fci", "Dci_Dc", "Fci_Fc", "hDci_hDc", "hFci_hFc"
		fh = fopen("`path'_ew_multiplications.mmat", "w")
		fputmatrix(fh, ewmultNames)
		fputmatrix(fh, hDci_hDci)
		fputmatrix(fh, hFci_hFci)
		fputmatrix(fh, hDci_Dc)
		fputmatrix(fh, hFci_Fc)
		fputmatrix(fh, Dci_Dci)
		fputmatrix(fh, Fci_Fci)
		fputmatrix(fh, Dci_Dc)
		fputmatrix(fh, Fci_Fc)
		fputmatrix(fh, hDci_hDc)
		fputmatrix(fh, hFci_hFc)
		fclose(fh)
		}
	
end
