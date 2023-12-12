capture mata: mata drop tiva2023()
mata:
	class tiva2023 {


		/* ** variables */

		string scalar path 

		/* ***  Dimensions */
		real scalar T, hN, N, K, F

		/* *** Descriptions  */
		real colvector year
		string colvector hcou, cou, ind
		string matrix year_cou_ind, year_hcou_ind, hcou_ind, cou_ind

		/* *** ICIO  */
		real colvector v, x
		real matrix Z, Y

		/* ***  index */
		real colvector time_index, time_indexN

		/* *** Transitions */
		real matrix hci_ci, hci_c, hcf_c, hcf_c_gfcf, hci_i, hc_c

		/* *** ew_multiplications */
		real matrix hDci_hDci, hFci_hFci, hDci_Dc, hFci_Fc, ///
		  Dci_Dci, Fci_Fci, Dci_Dc, Fci_Fc, hDci_hDc, hFci_hFc

		real matrix indicator
		
		/* ** Functions */
		void importMatrices()
		pointer(matrix) vector _import_asPointer()
		void _import_asExternal(), load()
		void _checkClear(), _initStorage(), _storeResult()
		string rowvector _storeIndicator()

		/* ** Results */
		real matrix result
		
		}

	void tiva2023::importMatrices(string scalar path)
	{
		/* When the class initializes, it must check either matrices are found,
		If not found, an error message must be displayed saying that the matrices
		are not found and that they should be downloaded */
		
		/* Problem: all the TiVA elements must be in new! */
		
		string colvector descrNames, icioNames, indexNames, transitionNames, ewmultNames
		pointer(real scalar) colvector dimPointer
		pointer(matrix) colvector descrPointer, icioPointer, indexPointer, transitionPointer, ewmultPointer

		printf("~ Importing matrices  from %s\n", path)
		
		/* _dimensions */
		dimPointer = _import_asPointer(path+"_dimensions.mmat")
		dimNames = *dimPointer[1]
		T = *dimPointer[2]
		hN = *dimPointer[3]
		N = *dimPointer[4]
		K = *dimPointer[5]
		F = *dimPointer[6]

		/* _descriptions */
		descrPointer = _import_asPointer(path+"_descriptions.mmat")
		descrNames = *descrPointer[1]
		year = *descrPointer[2]
		hcou = *descrPointer[3]
		cou = *descrPointer[4]
		ind = *descrPointer[5]
		year_cou_ind = *descrPointer[6]
		year_hcou_ind = *descrPointer[7]
		hcou_ind = *descrPointer[8]
		cou_ind = *descrPointer[9]

		/* _ICIO */
		icioPointer = _import_asPointer(path+"_ICIO.mmat")
		icioNames = *icioPointer[1]
		v = *icioPointer[2]
		x = *icioPointer[3]
		Z = *icioPointer[4]
		Y = *icioPointer[5]

		/* _index */
		indexPointer = _import_asPointer(path+"_index.mmat")
		indexNames = *indexPointer[1]
		time_index = *indexPointer[2]
		time_indexN = *indexPointer[3]		

		/* _transitions */
		transitionPointer = _import_asPointer(path+"_transitions.mmat")
		transitionNames = *transitionPointer[1]
		hci_ci = *transitionPointer[2]
		hci_c = *transitionPointer[3]
		hcf_c = *transitionPointer[4]
		hcf_c_gfcf = *transitionPointer[5]
		hci_i = *transitionPointer[6]
		hc_c = *transitionPointer[7]		
		
		/* _ew_multiplications */
		ewmultPointer = _import_asPointer(path+"_ew_multiplications.mmat")
		ewmultNames = *ewmultPointer[1]
		hDci_hDci = *ewmultPointer[2]
		hFci_hFci = *ewmultPointer[3]
		hDci_Dc = *ewmultPointer[4]
		hFci_Fc = *ewmultPointer[5]
		Dci_Dci = *ewmultPointer[6]
		Fci_Fci = *ewmultPointer[7]
		Dci_Dc = *ewmultPointer[8]
		Fci_Fc = *ewmultPointer[9]
		hDci_hDc = *ewmultPointer[10]
		hFci_hFc = *ewmultPointer[11]
		
		}
	
	// function that uses the function _import_asExternal to load
	// all matrices
	void tiva2023::load(string scalar path) {
		_import_asExternal(_import_asPointer(path+"_dimensions.mmat"))
		_import_asExternal(_import_asPointer(path+"_descriptions.mmat"))
		_import_asExternal(_import_asPointer(path+"_ICIO.mmat"))
		_import_asExternal(_import_asPointer(path+"_index.mmat"))
		_import_asExternal(_import_asPointer(path+"_transitions.mmat"))
		_import_asExternal(_import_asPointer(path+"_ew_multiplications.mmat"))
		}

		// Import matrices as pointers
	pointer(matrix) vector tiva2023::_import_asPointer(string scalar myMMAT) {
		fh = fopen(myMMAT, "r")
		names = fgetmatrix(fh)
		p = J(length(names)+1, 1, NULL)
		p[1] = &names
		for(i=2; i<=length(names)+1; i++){
			p[i] = &fgetmatrix(fh)
			}
		
		fclose(fh)
		return(p)
		}
	
	// Import matrices as global variables usable in mata
	void tiva2023::_import_asExternal(pointer vector p) {
		transmorphic matrix isnew
		for (i = 2; i<= length(p); i++) {
			rmexternal((*p[1])[i-1])
			isnew = crexternal((*p[1])[i-1])
			swap(*isnew, *p[i])
			printf("%s: %s %s of size [%g, %g] \n",	///
			  (*p[1])[i-1],									///
			  eltype(*isnew),									///
			  orgtype(*isnew),								///
			  rows(*isnew),									///
			  cols(*isnew))
			}
		}

	// Store
	
	/* void tiva2023::_initStorage() { */
	/* 	stata("clear") */
	/* 	st_addobs(T*N*K) */
	/* 	st_addvar("str10", ("year", "cou", "ind")) */
	/* 	st_sstore(., ("year", "cou", "ind"), year_cou_ind) */
	/* 	st_addvar("double", "toKeep") */
	/* 	} */

	/* void tiva2023::_storeIndicator(string scalar indicator, real matrix result) { */
	/* 	if (cols(result) == N) { */
	/* 		st_addvar("double", indicator :+ "_" :+ cou') */
	/* 		} */
	/* 	else if (cols(result) == 1) { */
	/* 		st_addvar("double", indicator) */
	/* 		} */
	/* 	} */

	/* void tiva2023::_storeResult(string scalar indicator, real matrix result, real scalar t) { */
	/* 	st_store(selectindex(time_indexN:== t), "toKeep", J(N*K, 1, 1)) */
	/* 	if (cols(result) == N) { */
	/* 		st_store(selectindex(time_indexN:== t), indicator :+ "_" :+ cou', result) */
	/* 		} */
	/* 	else if (cols(result) == 1) { */
	/* 		st_store(selectindex(time_indexN:== t), indicator, result) */
	/* 		} */
	/* 	} */
end
