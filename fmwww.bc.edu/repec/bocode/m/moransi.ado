/*******************************************************************************
** (C) KEISUKE KONDO
** 
** Release Date: March 31, 2018
** Latest Update: June 9, 2021
** 
** Version: 1.21
** 
** [Contact]
** Email: kondo-keisuke@rieti.go.jp
** URL: https://keisukekondokk.github.io/
*******************************************************************************/
** Version: 1.21
** Added generate option
** Coding improvement for saving memory space
** Version: 1.20
** Bug fix for p-value
** Added swm(knn #) option
** Added "r(W)" in r()
** Alert message for missing observations
** Coding improvement
** Version: 1.10
** Abbreviation of "detail" option changed
** 
** 
capture program drop moransi
program moransi, sortpreserve rclass
	version 11
	syntax varlist [if] [in], /*
			*/ lat(varname) /*
			*/ lon(varname) /*
			*/ swm(string) /*
			*/ dist(real) /*
			*/ dunit(string) /*
			*/ [ /*
			*/ DMS /*
			*/ APProx /*
			*/ DETail /*
			*/ NOMATsave /*
			*/ GENerate ]
	
	local vY `varlist'
	local swmtype = substr("`swm'", 1, 3)
	local swmtype_short = substr("`swm'", 1, 1)
	local unit = "`dunit'"
	marksample touse
	markout `touse' `vY' `lon' `lat'
	
	/*Check Variable*/
	if( strpos("`vY'"," ") > 0 ){
		display as error "Multiple variables are not allowed."
		exit 198
	}
	
	/*Check Missing Values of Variable*/
	qui: egen ______missing_count_spgen = rowmiss(`vY')
	qui: count if ______missing_count_spgen > 0
	local nummissing = r(N)
	local errormissing = 0
	if(`nummissing' > 0){
		local errormissing = 1
	}
	if( `errormissing' == 1){
		if(`nummissing' == 1){
			display as text "Warning: `nummissing' observation with missing value is dropped."
		}
		if(`nummissing' > 1){
			display as text "Warning: `nummissing' observations with missing value are dropped."
		}
	}
	qui: drop ______missing_count_spgen
	
	/*Check Latitude Range*/
	qui: sum `lat'
	local max_lat = r(max)
	local min_lat = r(min)
	if( `max_lat' < -90 | `min_lat' < -90 ){
		display as error "lat() must be within -90 to 90."
		exit 198
	}
	if( `max_lat' > 90 | `min_lat' > 90 ){
		display as error "lat() must be within -90 to 90."
		exit 198
	}
	
	/*Check Longitude Range*/
	qui: sum `lon'
	local max_lon = r(max)
	local min_lon = r(min)
	if( `max_lon' < -180 | `min_lon' < -180 ){
		display as error "lon() must be within -180 to 180."
		exit 198
	}
	if( `max_lon' > 180 | `min_lon' > 180 ){
		display as error "lon() must be within -180 to 180."
		exit 198
	}
	
	/*Check Spatial Weight Matrix*/
	if( "`swmtype'" != "bin" & "`swmtype'" != "knn" & "`swmtype'" != "exp" & "`swmtype'" != "pow"){
		display as error "swm() must be one of bin, knn, exp, and pow."
		exit 198
	}

	/*Check Distance Decay Parameter of Spatial Weight Matrix*/
	if( "`swmtype'" == "bin" ){
		local dd = . /*not used*/
	}
	else if( "`swmtype'" == "knn" ){
		local dd = real(substr("`swm'", strpos("`swm'", "knn") + length("knn") + 1, .))
		capture confirm integer number `dd'
		if( _rc != 0 ){
			display as error "Parameter {it:k} of swm(knn) must be integer."
			exit 198
		}
		if( `dd' <= 0 ){
			display as error "Parameter {it:k} of swm(knn) must be more than 0."
			exit 198
		}
		if( `dd' > _N ){
			qui: count
			local totalobs = r(N)
			display as error "Parameter {it:k} of swm(knn) must be less than `totalobs' (# of obs)."
			exit 198
		}
		else if( `dd' == . ){
			display as error "Numerical type is expected for distance-decay parameter."
			exit 198
		}
	}
	else if( "`swmtype'" == "exp" ){
		local dd = real(substr("`swm'", strpos("`swm'", "exp") + length("exp") + 1, .))
		if( `dd' <= 0 ){
			display as error "Distance-decay parameter must be more than 0."
			exit 198
		}
		else if( `dd' == . ){
			display as error "Numerical type is expected for distance-decay parameter."
			exit 198
		}
	}
	else if( "`swmtype'" == "pow" ){
		local dd = real(substr("`swm'", strpos("`swm'", "pow") + length("pow") + 1, .))
		if( `dd' <= 0 ){
			display as error "Distance-decay parameter must be more than 0."
			exit 198
		}
		else if( `dd' == . ){
			display as error "Numerical type is expected for distance-decay parameter."
			exit 198
		}
	}
	
	/*Check Parameter Range*/
	if( `dist' <= 0 ){
		display as error "dist(#) must be more than 0."
		exit 198
	}
	if( "`swmtype'" == "knn" & `dist' > 0 & `dist' != . ){
		local dist = .
		display as text "Warning: dist() is ignored for swm(knn) option."
	}
	
	/*Check Unit of Distance*/
	if( "`unit'" != "km" & "`unit'" != "mi" ){
		display as error "dunit(unit) must be either km or mi."
		exit 198
	}

	/*DMS or Decimal*/
	local fmdms = 0
	if( "`dms'" != "" ){
		local fmdms = 1
	}
	
	/*Approximation of Distance*/
	local appdist = 0
	if( "`approx'" != "" ){
		local appdist = 1
	}
	
	/*Display Details*/
	local dispdetail= 0
	if( "`detail'" != "" ){
		local dispdetail = 1
	}
	
	/*Distance Matrix Save Option*/
	local matsave = 1
	if( "`nomatsave'" != "" ){
		local matsave = 0
	}
	
	/*Check before Making Output Variable*/
	local gensplag = 0
	if( "`generate'" != "" ){
		capture confirm new variable splag_`vY'_`swmtype_short', exact
		if( _rc == 0 ) {
			local gensplag = 1
		}
		else if( _rc != 0 ) {
			display as error "Outcome variable for `vY' already exists."
			exit _rc
		}
	}
	
	/*+++++CALL Mata Program+++++*/
	mata: calcmoransi("`vY'", "`lon'", "`lat'", `fmdms', "`swmtype'", `dist', "`unit'", `dd', `appdist', `dispdetail', `matsave', `gensplag', "`touse'")
	/*+++++END Mata Program+++++*/
	
	/*Store Results in return*/
	return add
	
	/*Generate Spatial Lag*/
	if( "`generate'" != "" ){
		/*Add Variable Label*/
		label var splag_`vY'_`swmtype_short' "sptial lag, swm(`swm'), td=`dist', od=`order', row-standadized"

		/*Display Results*/
		display as txt "{bf:splag_`vY'_`swmtype_short'} was generated in the dataset."
	}
end

version 11
mata:
void calcmoransi(vY, lon, lat, fmdms, swmtype, dist, unit, dd, appdist, dispdetail, matsave, gensplag, touse)
{
	/*Make Variable*/
	if( fmdms == "1" ){
		printf("Convert DMS format to Decimal format.")
		convlonlat2decimal(lon, lat, touse, &vlon, &vlat)		
	} else {
		st_view(vlon, ., lon, touse)
		st_view(vlat, ., lat, touse)
	}
	latr = ( pi() / 180 ) * vlat; 
	lonr = ( pi() / 180 ) * vlon; 

	/*Make Variable*/
	st_view(vy, ., vY, touse)
	cN = rows(vlon)
	
	/*Size of SWM*/
	printf("{txt}Size of spatial weight matrix:{res} %1.0f * %1.0f\n", cN, cN)

	/*Variables*/
	if( matsave == 1 ){
		mD = J(cN, cN, 0)
	}
	mD_L = .
	cN_vD = .
	dist_mean = .
	dist_sd = .
	dist_min = .
	dist_max = 0
	numErrorSwm = 0
	numErrorSwmNoNeighbor = 0
	
	/*Spatial Lag*/
	vDist = J(1, cN, 0)
	vW = J(1, cN, 0)
	mW = J(cN, cN, 0)
	vsy = ( vy :- mean(vy) ) :/ sqrt( variance(vy) )
	vwy = J(cN, 1, 0)
	vwsy = J(cN, 1, 0)
	
	/*Make Distance Matrix using Vincenty (1975) */
	if( appdist == 1 ){
		/*Simplified Version of Vincenty Formula*/
		for( i = 1; i <= cN; ++i ){
		
			/* Display Iteration Process */
			if( i == 1 ){
				printf("{txt}{c TT}{hline 15}{c TT}\n")
			}

			/*Distance between i and j*/
			A = J(1, cN, 1) :* lonr[i]
			B = J(1, cN, 1) :* lonr'
			C = J(1, cN, 1) :* latr[i]
			D = J(1, cN, 1) :* latr'
			difflonr = abs( A - B )
			numer1 = ( cos(D):*sin(difflonr) ):^2
			numer2 = ( cos(C):*sin(D) :- sin(C):*cos(D):*cos(difflonr) ):^2
			numer = sqrt( numer1 :+ numer2 )
			denom = sin(C):*sin(D) :+ cos(C):*cos(D):*cos(difflonr)
			vDist = 6378.137 * atan2( denom, numer )
			/*Missing between i and i*/
			vDist[i] = .
			
			/*Convert Unit of Distance*/
			if( unit == "mi" ){
				vDist = 0.621371 :* vDist
			}
			
			/*Store Min and Max Distance*/
			if( min(vDist) < dist_min ){
				dist_min = min(vDist)
			}
			if( max(vDist) > dist_max ){
				dist_max = max(vDist)
			}
			
			/*Save Distance Matrix*/
			if( matsave == 1 ){
				mD[i,] = vDist
			}
			
			/*Binary SWM*/
			if( swmtype == "bin" ){
				vW = ( vDist :< dist )
				vDist = .
				/*ERROR CHECK*/
				numErrorSwm = numErrorSwm + (rowsum(vW) == 0)
				/*Diagonal Element*/
				vW[i] = 0
				vW = vW :/ rowsum(vW)
			}
			/*K-Nearest Neighbor SWM*/
			if( swmtype == "knn" ){
				/*Obtain Threshold Distance for KNN*/
				vDistSorted = sort(vDist', 1)'
				dDistKnn = vDistSorted[dd]
				vW = ( vDist :<= dDistKnn )
				vDist = .
				/*ERROR CHECK*/
				numErrorSwm = numErrorSwm + (rowsum(vW :!= 0) > dd)
				/*Diagonal Element*/
				vW[i] = 0
				vW = vW :/ rowsum(vW)
			}
			/*Exponential SWM*/
			if( swmtype == "exp" ){
				vW = ( vDist :< dist ) :* exp( - dd :* vDist )
				vDist = .
				vW[i] = 0 
				vW = vW :/ rowsum(vW)
			}
			/*Power SWM*/
			if( swmtype == "pow" ){
				vW = ( vDist :< dist ) :* vDist :^(-dd)
				vDist = .
				/*ERROR CHECK*/
				numErrorSwmNoNeighbor = numErrorSwmNoNeighbor + (rowsum(vW) == 0)
				/*ERROR CHECK*/
				numErrorSwm = numErrorSwm + (rowsum(vW :== .) > 1 | rowsum(vW) == 0)
				/*Diagonal Element*/
				vW[i] = 0
				vW = vW :/ rowsum(vW)
			}
			
			/*Spatial Lagged Variable*/
			mW[i,] = vW
			vwy[i,] = vW * vy
			vwsy[i,] = vW * vsy
			
			/* Display Iteration Process */
			if( i == trunc(cN/10) ){
				printf("{txt}{c |}Completed:  10%%{c |}\n")
			}
			else if( i == 2*trunc(cN/10) ){
				printf("{txt}{c |}Completed:  20%%{c |}\n")
			}
			else if( i == 3*trunc(cN/10) ){
				printf("{txt}{c |}Completed:  30%%{c |}\n")
			}
			else if( i == 4*trunc(cN/10) ){
				printf("{txt}{c |}Completed:  40%%{c |}\n")
			}
			else if( i == trunc(cN/2) ){
				printf("{txt}{c |}Completed:  50%%{c |}\n")
			}
			else if( i == trunc(cN/2) + trunc(cN/10) ){
				printf("{txt}{c |}Completed:  60%%{c |}\n")
			}
			else if( i == trunc(cN/2) + 2*trunc(cN/10) ){
				printf("{txt}{c |}Completed:  70%%{c |}\n")
			}
			else if( i == trunc(cN/2) + 3*trunc(cN/10) ){
				printf("{txt}{c |}Completed:  80%%{c |}\n")
			}
			else if( i == trunc(cN/2) + 4*trunc(cN/10) ){
				printf("{txt}{c |}Completed:  90%%{c |}\n")
			}
			else if( i == cN ){
				printf("{txt}{c |}Completed: 100%%{c |}\n")
				printf("{txt}{c BT}{hline 15}{c BT}\n")
			}
		}

		/*REPORT ERROR CHECK*/
		if( swmtype == "bin" ){
			if(numErrorSwm > 0){
				if(numErrorSwm == 1){
					printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwm)
				}
				if(numErrorSwm > 1){
					printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwm)
				}
			}
		}
		if( swmtype == "knn" ){
			if(numErrorSwm > 0){
				if(numErrorSwm == 1){
					printf("{txt}Warning: %1.0f observation has multiple k-nearest neighbors.\n", numErrorSwm)
				}
				if(numErrorSwm > 1){
					printf("{txt}Warning: %1.0f observations have multiple k-nearest neighbors.\n", numErrorSwm)
				}
			}
		}
		if( swmtype == "pow" ){
			if(numErrorSwmNoNeighbor > 0){
				if(numErrorSwmNoNeighbor == 1){
					printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
				}
				if(numErrorSwmNoNeighbor > 1){
					printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
				}
			}
			if(numErrorSwm > 0){
				if(numErrorSwm == 1){
					printf("{txt}Warning: %1.0f observation has missing value.\n", numErrorSwm)
				}
				if(numErrorSwm > 1){
					printf("{txt}Warning: %1.0f observations have missing values.\n", numErrorSwm)
				}
			}
		}
	}
	else if( appdist == 0 ){
		/*Vincenty Formula*/

		/*Variables*/
		a = 6378.137
		b = 6356.752314245
		f = (a-b)/a
		eps = 1e-12
		maxIt = 1e+5

		/*LOOP for Vincenty Formula*/
		for( i = 1; i <= cN; ++i ){
		
			/* Display Iteration Process */
			if( i == 1 ){
				printf("{txt}{c TT}{hline 15}{c TT}\n")
			}
			
			Alon = J(1, cN, 1) :* lonr[i]
			Blon = J(1, cN, 1) :* lonr'
			Clat = J(1, cN, 1) :* latr[i]
			Dlat = J(1, cN, 1) :* latr'
			U1 = atan( (1-f) :* tan(Clat) )
			U2 = atan( (1-f) :* tan(Dlat) )
			L = abs( Alon :- Blon )
			lam = L
			l1_lam = lam
			cnt = 0
			do{
				numer1 = ( cos(U2) :* sin(lam) ):^2
				numer2 = ( cos(U1) :* sin(U2) :- sin(U1) :* cos(U2) :* cos(lam) ):^2
				numer = sqrt( numer1 :+ numer2 )
				denom = sin(U1) :* sin(U2) :+ cos(U1) :* cos(U2) :* cos(lam)
				sig = atan2( denom, numer )
				sinalp = (cos(U1) :* cos(U2) :* sin(lam)) :/ sin(sig)
				cos2alp = 1 :- sinalp:^2
				cos2sigm = cos(sig) :- ( 2 :* sin(U1) :* sin(U2) ) :/ cos2alp
				C = f:/16 :* cos2alp :* ( 4 :+ f :* (4 :- 3 :* cos2alp) )
				lam = L :+ (1:-C) :* f :* sinalp :* ( sig :+ C :* sin(sig) :* ( cos2sigm :+ C :* cos(sig) :*(-1 :+ 2 :* cos2sigm:^2) ) )
				cri = abs( max(lam :- l1_lam) )
				l1_lam = lam;
				if( cnt++ > maxIt ){
					printf("{err}Convergence not achieved in Vincenty formula \n")
					printf("{err}Add approx option to avoid convergence error \n")
					exit(error(430))
				}
			}while( cri > eps )

			/*After Iteration*/
			u2 = cos2alp :* ( (a^2 - b^2) / b^2 )
			A = 1 :+ (u2 :/ 16384) :* ( 4096 :+ u2 :* (-768 :+ u2 :* (320 :- 175 :* u2)) )
			B = u2 :/ 1024 :* (256 :+ u2 :* (-128 :+ u2 :* (74 :- 47 :*u2)) )
			dsig = B:*sin(sig) :* ( cos2sigm :+ 0.25:*B:*( cos(sig):*(-1:+2:*cos2sigm:^2) :- 1:/6:*B:*cos2sigm:*(-3:+4:*sin(sig):^2):*(-3:+4:*cos2sigm) ) )
			vDist = b :* A :* (sig :- dsig)
			
			/*Distance = 0*/
			if(missing(vDist) > 1){
				_editmissing(vDist, 0)
			}
			
			/*Missing between i and i*/
			vDist[i] = .
			
			/*Convert Unit of Distance*/
			if( unit == "mi" ){
				vDist = 0.621371 :* vDist
			}
			
			/*Store Min and Max Distance*/
			if( min(vDist) < dist_min ){
				dist_min = min(vDist)
			}
			if( max(vDist) > dist_max ){
				dist_max = max(vDist)
			}
			
			/*Save Distance Matrix*/
			if( matsave == 1 ){
				mD[i,] = vDist
			}
			
			/*Binary SWM*/
			if( swmtype == "bin" ){
				vW = ( vDist :< dist )
				vDist = .
				/*ERROR CHECK*/
				numErrorSwm = numErrorSwm + (rowsum(vW) == 0)
				/*Diagonal Element*/
				vW[i] = 0 
				vW = vW :/ rowsum(vW)
			}
			/*K-Nearest Neighbor SWM*/
			if( swmtype == "knn" ){
				/*Obtain Threshold Distance for KNN*/
				vDistSorted = sort(vDist', 1)'
				dDistKnn = vDistSorted[dd]
				vW = ( vDist :<= dDistKnn )
				vDist = .
				/*ERROR CHECK*/
				numErrorSwm = numErrorSwm + (rowsum(vW :!= 0) > dd)
				/*Diagonal Element*/
				vW[i] = 0 
				vW = vW :/ rowsum(vW)
			}
			/*Exponential SWM*/
			if( swmtype == "exp" ){
				vW = ( vDist :< dist ) :* exp( - dd :* vDist )
				vDist = .
				vW[i] = 0 
				vW = vW :/ rowsum(vW)
			}
			/*Power SWM*/
			if( swmtype == "pow" ){
				vW = ( vDist :< dist ) :* vDist :^(-dd)
				vDist = .
				/*ERROR CHECK*/
				numErrorSwmNoNeighbor = numErrorSwmNoNeighbor + (rowsum(vW) == 0)
				/*ERROR CHECK*/
				numErrorSwm = numErrorSwm + (rowsum(vW :== .) > 1 | rowsum(vW) == 0)
				/*Diagonal Element*/
				vW[i] = 0 
				vW = vW :/ rowsum(vW)
			}
			
			/*Spatial Lagged Variable*/
			mW[i,] = vW
			vwy[i,] = vW * vy
			vwsy[i,] = vW * vsy
			
			/* Display Iteration Process */
			if( i == trunc(cN/10) ){
				printf("{txt}{c |}Completed:  10%%{c |}\n")
			}
			else if( i == 2*trunc(cN/10) ){
				printf("{txt}{c |}Completed:  20%%{c |}\n")
			}
			else if( i == 3*trunc(cN/10) ){
				printf("{txt}{c |}Completed:  30%%{c |}\n")
			}
			else if( i == 4*trunc(cN/10) ){
				printf("{txt}{c |}Completed:  40%%{c |}\n")
			}
			else if( i == trunc(cN/2) ){
				printf("{txt}{c |}Completed:  50%%{c |}\n")
			}
			else if( i == trunc(cN/2) + trunc(cN/10) ){
				printf("{txt}{c |}Completed:  60%%{c |}\n")
			}
			else if( i == trunc(cN/2) + 2*trunc(cN/10) ){
				printf("{txt}{c |}Completed:  70%%{c |}\n")
			}
			else if( i == trunc(cN/2) + 3*trunc(cN/10) ){
				printf("{txt}{c |}Completed:  80%%{c |}\n")
			}
			else if( i == trunc(cN/2) + 4*trunc(cN/10) ){
				printf("{txt}{c |}Completed:  90%%{c |}\n")
			}
			else if( i == cN ){
				printf("{txt}{c |}Completed: 100%%{c |}\n")
				printf("{txt}{c BT}{hline 15}{c BT}\n")
			}
		}

		/*REPORT ERROR CHECK*/
		if( swmtype == "bin" ){
			if(numErrorSwm > 0){
				if(numErrorSwm == 1){
					printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwm)
				}
				if(numErrorSwm > 1){
					printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwm)
				}
			}
		}
		if( swmtype == "knn" ){
			if(numErrorSwm > 0){
				if(numErrorSwm == 1){
					printf("{txt}Warning: %1.0f observation has multiple k-nearest neighbors.\n", numErrorSwm)
				}
				if(numErrorSwm > 1){
					printf("{txt}Warning: %1.0f observations have multiple k-nearest neighbors.\n", numErrorSwm)
				}
			}
		}
		if( swmtype == "pow" ){
			if(numErrorSwmNoNeighbor > 0){
				if(numErrorSwmNoNeighbor == 1){
					printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
				}
				if(numErrorSwmNoNeighbor > 1){
					printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
				}
			}
			if(numErrorSwm > 0){
				if(numErrorSwm == 1){
					printf("{txt}Warning: %1.0f observation has missing value.\n", numErrorSwm)
				}
				if(numErrorSwm > 1){
					printf("{txt}Warning: %1.0f observations have missing values.\n", numErrorSwm)
				}
			}
		}
	}

	/*Moran's I from Definition*/
	dS0 = cN
	dI = (vsy'vwsy) / (vsy'vsy)

	/*Calculate Expectation and Variance of Moran's I*/
	vS1 = J(cN, 1, 0)
	vS2 = J(cN, 1, 0)
	for( i = 1; i <= cN; ++i ){
		vS1[i] = rowsum( (mW[i,] :+ mW[,i]'):^2 )
		vS2[i] = ( rowsum(mW[i,] :+ mW[,i]'):^2 )
	}
	dS1 = 0.5 * colsum( vS1 )
	dS2 = 1.0 * colsum( vS2 )
	vS1 = .
	vS2 = .
	dD = cN * colsum( vsy:^4 ) / (colsum(vsy:^2))^2
	dC = (cN-1)*(cN-2)*(cN-3)*dS0^2
	dB = dD * ( (cN^2-cN)*dS1 - 2*cN*dS2 + 6*dS0^2 )
	dA = cN * ( (cN^2-3*cN+3)*dS1 - cN*dS2 + 3*dS0^2 )

	/*Calculate Z-value of Moran's I*/
	if(dI == .){
		dEI = .
		dEI2 = .
		dVI = .
		dSEI = .
		dZI = .
		dPI = .
	}
	else {
		dEI = - 1 / ( cN - 1 )
		dEI2 = (dA - dB) / dC
		dVI = dEI2 - (dEI)^2
		dSEI = sqrt(dVI)
		dZI = (dI - dEI) / dSEI
		dPI = 2 * ( 1 - normal(abs(dZI)) )
	}

	/*Summary Statistics of Distance Matrix*/
	if( matsave == 1 ){
		mD_L = lowertriangle(mD)
		mD = .
		vD = select(vech(mD_L), vech(mD_L):>0)
		cN_vD = rows(vD)
		dist_mean = mean(vD)
		dist_sd = sqrt(variance(vD))
		vD = .
	}
	else {
		mW = .
		mD_L = .
		cN_vD = .
		dist_mean = .
		dist_sd = .
	}
	
	/*Display Summary Statistics of Distances*/
	printf("\n")
	if( appdist == 1 ){
		if( unit == "km" ){
			printf("{txt}Distance by simplified version of Vincenty formula (unit: km)\n")
		}
		else if( unit == "mi" ){
			printf("{txt}Distance by simplified version of Vincenty formula (unit: mi)\n")
		}
	}
	else if( appdist == 0 ){
		if( unit == "km" ){
			printf("{txt}Distance by Vincenty formula (unit: km)\n")
		}
		else if( unit == "mi" ){
			printf("{txt}Distance by Vincenty formula (unit: mi)\n")
		}
	}
	if( dispdetail == 1 ){
		printf("{txt}{hline 21}{c TT}{hline 63} \n")
		printf("{txt}{space 20} {c |}{space 8}Obs.{space 8}Mean{space 9}S.D.{space 9}Min.{space 9}Max.\n")
		printf("{txt}{hline 21}{c +}{hline 63} \n")
		printf("{txt}{space 12}Distance {c |}{res}  %10.0f  %10.3f   %10.3f   %10.3f   %10.3f\n", 
					cN_vD, dist_mean, dist_sd, dist_min, dist_max )	
		printf("{txt}{hline 21}{c BT}{hline 63} \n")
		if( unit == "km" ){
			printf("{txt}Distance threshold (unit: km):{res} %10.0f\n", dist)
		}
		else if( unit == "mi" ){
			printf("{txt}Distance threshold (unit: mi):{res} %10.0f\n", dist)
		}
		printf("{txt}{hline 85}\n")
	}

	/*For Long Variable Name*/
	sY = abbrev(vY, 20)

	/*Results of Moran's I*/
	printf("\n")
	printf("{txt}Moran's I Statistic {space 40} Number of Obs = {res}%8.0f\n",cN)
	printf("{txt}{hline 21}{c TT}{hline 63}\n")
	printf("{txt}{space 12}Variable {c |}  Moran's I{space 9}E(I){space 8}SE(I){space 9}Z(I){space 6}p-value\n")
	printf("{hline 21}{c +}{hline 63}\n")
	printf("{txt}%20s {c |} {res}%10.5f   %10.5f   %10.5f   %10.5f   %10.5f\n", sY, dI, dEI, dSEI, dZI, dPI )
	printf("{txt}{hline 21}{c BT}{hline 63}\n")
	printf("{txt}Null Hypothesis: Spatial Randomization\n")

	/*Return Results in Mata to Stata*/
	if( gensplag == 1 ){
		st_store(., st_addvar("float", "splag"+"_"+vY+"_"+substr(swmtype, 1, 1)), st_local("touse"), vwy)
	}
	
	/*rreturn command in Stata*/
	st_rclear()
	st_numscalar("r(dist_max)", dist_max)
	st_numscalar("r(dist_min)", dist_min)
	st_numscalar("r(dist_sd)", dist_sd)
	st_numscalar("r(dist_mean)", dist_mean)
	st_numscalar("r(dd)", dd)
	st_numscalar("r(td)", dist)
	st_numscalar("r(N)", cN)
	st_numscalar("r(pI)", dPI)
	st_numscalar("r(zI)", dZI)
	st_numscalar("r(seI)", dSEI)
	st_numscalar("r(EI)", dEI)
	st_numscalar("r(I)", dI)
	st_matrix("r(W)", mW)
	st_matrix("r(D)", mD_L)
	if( swmtype == "bin" ){
		st_global("r(swm)", "binary")
	} 
	else if( swmtype == "exp" ){
		st_global("r(swm)", "exponential")
	}
	else if( swmtype == "pow" ){
		st_global("r(swm)", "power")
	}
	if( unit == "km" ){ 
		st_global("r(dunit)", "km")
	}
	else if( unit == "mi" ){
		st_global("r(dunit)", "mi")
	}
	if( appdist == 1 ){
		st_global("r(dist_type)", "approximation")
	}
	else if( appdist == 0 ){
		st_global("r(dist_type)", "exact")
	}
	st_global("r(varname)", vY)
	st_global("r(cmd)", "moransi")
}
end

/*## MATA ## Convert DMS format to Decimal Format*/
version 11
mata:
void convlonlat2decimal(lat, lon, touse, vlat, vlon)
{
	st_view(vlat_, ., lat, touse)
	st_view(vlon_, ., lon, touse)
	(*vlat) = floor(vlat_) :+ (floor((vlat_:-floor(vlat_)):*100):/60) :+ (floor((vlat_:*100:-floor(vlat_:*100)):*100):/3600)
	(*vlon) = floor(vlon_) :+ (floor((vlon_:-floor(vlon_)):*100):/60) :+ (floor((vlon_:*100:-floor(vlon_:*100)):*100):/3600)
}
end
