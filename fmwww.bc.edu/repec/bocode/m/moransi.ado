/*******************************************************************************
** (C) KEISUKE KONDO
** 
** Release Date: March 31, 2018
** Latest Update: March 23, 2025
** 
** Version: 1.31
** 
** [Contact]
** Email: kondo-keisuke@rieti.go.jp
** URL: https://keisukekondokk.github.io/
*******************************************************************************/
** Version: 1.31
** Added largesize option
** Coding improvement for small sample size
** Bug fix
** Version: 1.30
** Added WVAR() option
** Added replace option
** Added graph option
** Added local Moran's I statistics
** Coding improvement
** Removed generate option
** Bug fix for error messages
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
	version 11.0
	syntax varlist [if] [in], /*
			*/ lat(varname) /*
			*/ lon(varname) /*
			*/ swm(string) /*
			*/ dist(real) /*
			*/ dunit(string) /*
			*/ [ /*
			*/ WVAR(varname) /*
			*/ DMS /*
			*/ LARGEsize /*
			*/ APProx /*
			*/ DETail /*
			*/ NOMATsave /*
			*/ REPlace /*
			*/ GRAPH ]
	
	local vY `varlist'
	local swmtype = substr("`swm'", 1, 3)
	local swmtype_short = substr("`swm'", 1, 1)
	local unit = "`dunit'"
	marksample touse
	markout `touse' `vY' `lon' `lat' `wvar'

	/*Check Variable*/
	if( strpos("`vY'"," ") > 0 ){
		display as error "Multiple variables are not allowed."
		exit 198
	}
	
	/*Check Missing Values of Variable*/
	qui: egen ______missing_count_y = rowmiss(`vY')
	qui: count if ______missing_count_y > 0
	local nummissing = r(N)
	local errormissing = 0
	if(`nummissing' > 0){
		local errormissing = 1
	}
	if( `errormissing' == 1){
		if(`nummissing' == 1){
			display as text "Warning: `nummissing' observation with missing value in `vY' is dropped."
		}
		if(`nummissing' > 1){
			display as text "Warning: `nummissing' observations with missing value in `vY' are dropped."
		}
	}
	qui: drop ______missing_count_y
	
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
	
	/*Check Missing Values of Latitude*/
	qui: egen ______missing_count_lat = rowmiss(`lat')
	qui: count if ______missing_count_lat > 0
	local nummissing = r(N)
	local errormissing = 0
	if(`nummissing' > 0){
		local errormissing = 1
	}
	if( `errormissing' == 1){
		if(`nummissing' == 1){
			display as text "Warning: `nummissing' observation with missing value in `lat' is dropped."
		}
		if(`nummissing' > 1){
			display as text "Warning: `nummissing' observations with missing value in `lat' are dropped."
		}
	}
	qui: drop ______missing_count_lat
	
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
	
	/*Check Missing Values of Longitude*/
	qui: egen ______missing_count_lon = rowmiss(`lon')
	qui: count if ______missing_count_lon > 0
	local nummissing = r(N)
	local errormissing = 0
	if(`nummissing' > 0){
		local errormissing = 1
	}
	if( `errormissing' == 1){
		if(`nummissing' == 1){
			display as text "Warning: `nummissing' observation with missing value in `lon' is dropped."
		}
		if(`nummissing' > 1){
			display as text "Warning: `nummissing' observations with missing value in `lon' are dropped."
		}
	}
	qui: drop ______missing_count_lon
	
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
		if( `dd' == . ){
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
		if( `dd' == . ){
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
		if( `dd' == . ){
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
	
	/*Weight Variable*/
	local sweight = 0
	if( "`wvar'" != "" ){
		/*Weight Variable On*/
		local sweight = 1
		/*Check Missing for Weight Variable*/
		qui: egen ______missing_count_wvar = rowmiss(`wvar')
		qui: count if ______missing_count_wvar > 0
		local nummissing = r(N)
		local errormissing = 0
		if(`nummissing' > 0){
			local errormissing = 1
		}
		if( `errormissing' == 1){
			if(`nummissing' == 1){
				display as text "Warning: `nummissing' observation with missing value in the weight variable is dropped."
			}
			if(`nummissing' > 1){
				display as text "Warning: `nummissing' observations with missing value in the weight variable are dropped."
			}
		}
		qui: drop ______missing_count_wvar
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
	
	/*Large Size Option*/
	local large = 0
	if( "`largesize'" != "" ){
		local large = 1
	}
	
	/*Replace Option*/
	if( "`replace'" == "" ){
		/*Check before Making Output Variable*/
		local error_exit = 0
		foreach VAR in "splag" "lmoran_i" "lmoran_e" "lmoran_v" "lmoran_z" "lmoran_p" "lmoran_cat" {
			local genvar = 0
			capture confirm new variable `VAR'_`vY'_`swmtype_short', exact
			if( _rc == 0 ) {
				local genvar = 1
			}			
			else if( _rc != 0 ) {
				display as error "Outcome variable, `VAR'_`vY'_`swmtype_short', already exists in the dataset."
				local error_exit = 1
			}
		}
		if( `error_exit' == 1 ){
			exit _rc
		}
	}
	else if( "`replace'" != "" ){
		/*Check before Making Output Variable*/
		foreach VAR in "splag" "lmoran_i" "lmoran_e" "lmoran_v" "lmoran_z" "lmoran_p" "lmoran_cat" {
			local genvar = 0
			capture confirm new variable `VAR'_`vY'_`swmtype_short', exact
			if( _rc == 0 ) {
				local genvar = 1
			}			
			else if( _rc != 0 ) {
				qui: drop `VAR'_`vY'_`swmtype_short'
				local genvar = 1
			}
		}
	}

	/*Make Graph*/
	local makefigure = 0
	if( "`graph'" != "" ){
		local makefigure = 1
	}
	
	/*+++++CALL Mata Program+++++*/
	if( `large' == 0 ){
		mata: calcmoransi_loop_scalar("`vY'", "`lon'", "`lat'", `fmdms', "`swmtype'", `dist', "`unit'", `dd', "`wvar'", `sweight', `appdist', `dispdetail', `matsave', `genvar', "`touse'")
	}
	else if( `large' == 1 ){
		mata: calcmoransi_loop_vector("`vY'", "`lon'", "`lat'", `fmdms', "`swmtype'", `dist', "`unit'", `dd', "`wvar'", `sweight', `appdist', `dispdetail', `matsave', `genvar', "`touse'")
	}
	/*+++++END Mata Program+++++*/
	
	/*Store Results in return*/
	return add
	
	/*Generate Variables*/
	if( `genvar' == 1 ){
		/*Add Variable Label*/
		if( `sweight' == 1 ){
			label var splag_`vY'_`swmtype_short' "sptial lag, swm(`swm'), td=`dist', row-standadized"
			label var lmoran_i_`vY'_`swmtype_short' "local Morans I, statistic, swm(`swm'), td=`dist', weight=`wvar', row-standadized"
			label var lmoran_e_`vY'_`swmtype_short' "local Morans I, expected value, swm(`swm'), td=`dist', weight=`wvar', row-standadized"
			label var lmoran_v_`vY'_`swmtype_short' "local Morans I, variance, swm(`swm'), td=`dist', weight=`wvar', row-standadized"
			label var lmoran_z_`vY'_`swmtype_short' "local Morans I, z-value, swm(`swm'), td=`dist', weight=`wvar', row-standadized"
			label var lmoran_p_`vY'_`swmtype_short' "local Morans I, p-value, swm(`swm'), td=`dist', weight=`wvar', row-standadized"
		}
		else if( `sweight' == 0 ){
			label var splag_`vY'_`swmtype_short' "sptial lag, swm(`swm'), td=`dist', row-standadized"
			label var lmoran_i_`vY'_`swmtype_short' "local Morans I, statistic, swm(`swm'), td=`dist', row-standadized"
			label var lmoran_e_`vY'_`swmtype_short' "local Morans I, expected value, swm(`swm'), td=`dist', row-standadized"
			label var lmoran_v_`vY'_`swmtype_short' "local Morans I, variance, swm(`swm'), td=`dist', row-standadized"
			label var lmoran_z_`vY'_`swmtype_short' "local Morans I, z-value, swm(`swm'), td=`dist', row-standadized"
			label var lmoran_p_`vY'_`swmtype_short' "local Morans I, p-value, swm(`swm'), td=`dist', row-standadized"
		}

		/*Display Results*/
		display as txt "{bf:splag_`vY'_`swmtype_short'} was generated in the dataset."
		display as txt "{bf:lmoran_i_`vY'_`swmtype_short'} was generated in the dataset."
		display as txt "{bf:lmoran_e_`vY'_`swmtype_short'} was generated in the dataset."
		display as txt "{bf:lmoran_v_`vY'_`swmtype_short'} was generated in the dataset."
		display as txt "{bf:lmoran_z_`vY'_`swmtype_short'} was generated in the dataset."
		display as txt "{bf:lmoran_p_`vY'_`swmtype_short'} was generated in the dataset."
		display as txt "{bf:lmoran_cat_`vY'_`swmtype_short'} was generated in the dataset."
	
		/*Mean*/
		qui: sum splag_`vY'_`swmtype_short'
		local mean_wy = r(mean)
		qui: sum `vY'
		local mean_y = r(mean)
		
		/*Category of Local Monran's I*/
		qui: gen lmoran_cat_`vY'_`swmtype_short' = .
		qui: replace lmoran_cat_`vY'_`swmtype_short' = 1 if splag_`vY'_`swmtype_short' >= `mean_wy' & `vY' >= `mean_y' & splag_`vY'_`swmtype_short' != .
		qui: replace lmoran_cat_`vY'_`swmtype_short' = 2 if splag_`vY'_`swmtype_short' < `mean_wy' & `vY' >= `mean_y' & splag_`vY'_`swmtype_short' != .
		qui: replace lmoran_cat_`vY'_`swmtype_short' = 3 if splag_`vY'_`swmtype_short' >= `mean_wy' & `vY' < `mean_y' & splag_`vY'_`swmtype_short' != .
		qui: replace lmoran_cat_`vY'_`swmtype_short' = 4 if splag_`vY'_`swmtype_short' < `mean_wy' & `vY' < `mean_y' & splag_`vY'_`swmtype_short' != .

		/*Label*/
		label var lmoran_cat_`vY'_`swmtype_short' "local Morans I, category"
		label def category_lmoransi 1 "High-High" 2 "High-Low" 3 "Low-High" 4 "Low-Low", replace
		label value lmoran_cat_`vY'_`swmtype_short' category_lmoransi
		
		/*Graph*/
		if( "`graph'" != "" | "`gsaving'" != "" ){
			twoway (scatter splag_`vY'_`swmtype_short' `vY' if splag_`vY'_`swmtype_short' != ., ms(oh) mc(navy) yaxis(1 2) xaxis(1 2)) ///
				(lfit splag_`vY'_`swmtype_short' `vY' if splag_`vY'_`swmtype_short' != ., lw(medthick)) ///
				, ///
				ytitle("Spatial Lag of `vY'", height(5) axis(1)) ///
				xtitle("`vY'", height(5) axis(1)) ///
				ytitle("", axis(2)) ///
				xtitle("", axis(2)) ///
				ylabel(, nogrid axis(1)) ///
				xlabel(, nogrid axis(1)) ///
				ylabel(, nogrid axis(2)) ///
				xlabel(, nogrid axis(2)) ///
				yline(`mean_wy', lwidth(thin) lcolor(gray) lpattern(dash)) ///
				xline(`mean_y', lwidth(thin) lcolor(gray) lpattern(dash)) ///
				legend(off) ///
				graphregion(color(white) fcolor(white))
			if( "`gsaving'" != "" ){
				graph export "`gsaving'", replace
			}
		}
	}
		
end

/*## MATA ## Calculate Moran's I*/
version 11.0
mata:
void calcmoransi_loop_scalar(vY, lon, lat, fmdms, swmtype, dist, unit, dd, wvar, sweight, appdist, dispdetail, matsave, genvar, touse)
{
	/*Linebreak*/
	printf("{txt}\n")

	/*Make Variable*/
	if( fmdms == "1" ){
		printf("{txt}Convert DMS format to Decimal format.")
		convlonlat2decimal(lon, lat, touse, &vlon, &vlat)		
	} 
	else {
		st_view(vlon, ., lon, touse)
		st_view(vlat, ., lat, touse)
	}
	latr = ( pi() / 180 ) * vlat; 
	lonr = ( pi() / 180 ) * vlon; 

	/*Make Variable*/
	st_view(vy, ., vY, touse)
	cN = rows(vlon)

	/*Import Weight Variable*/
	if( sweight == 1 ){
		st_view(vZ, ., wvar, touse)
	}
	
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
	numErrorSwmMultiNeighbor = 0
	numErrorSwmNoNeighbor = 0
	
	/*Spatial Lag*/
	vDist = J(1, cN, 0)
	mW = J(cN, cN, 0)
	
	/*Iteration Process*/
	itr = 0
	cItr = cN*(cN-1)/2
	itr10percent = trunc(cItr/10)
	itr20percent = 2 * trunc(cItr/10)
	itr30percent = 3 * trunc(cItr/10)
	itr40percent = 4 * trunc(cItr/10)
	itr50percent = trunc(cItr/2)
	itr60percent = trunc(cItr/2) + trunc(cItr/10)
	itr70percent = trunc(cItr/2) + 2 * trunc(cItr/10)
	itr80percent = trunc(cItr/2) + 3 * trunc(cItr/10)
	itr90percent = trunc(cItr/2) + 4 * trunc(cItr/10)
	
	/*Vincenty Formula*/
	if( appdist == 0 ){
	
		/*Variables*/
		a = 6378.137
		b = 6356.752314245
		f = (a-b)/a
		eps = 1e-12
		maxIt = 1e+5
		
		/*LOOP for Bilateral Distance*/
		for( i = 1; i <= cN; ++i ){
			for( j = i + 1; j <= cN; ++j ){

				++itr
				if( itr == 1 ){
					printf("{txt}Calculating bilateral distance...\n")
					printf("{txt}{c TT}{hline 15}{c TT}\n")
				}

				/*Variables*/
				U1 = atan( (1-f)*tan(latr[i]) )
				U2 = atan( (1-f)*tan(latr[j]) )
				L = lonr[i] - lonr[j]
				lam = L
				l1_lam = lam
				cnt = 0
				
				/*Iteration for Vincenty Formula*/
				do{
					numer1 = ( cos(U2)*sin(lam) )^2;
					numer2 = ( cos(U1)*sin(U2) - sin(U1)*cos(U2)*cos(lam) )^2;
					numer = sqrt( numer1 + numer2 );
					denom = sin(U1)*sin(U2) + cos(U1)*cos(U2)*cos(lam);
					sig = atan2( denom, numer );
					sinalp = (cos(U1)*cos(U2)*sin(lam)) / sin(sig);
					cos2alp = 1 - sinalp^2;
					cos2sigm = cos(sig) - ( 2*sin(U1)*sin(U2) ) / cos2alp;
					C = f/16 * cos2alp * ( 4+f*(4-3*cos2alp) );
					lam = L + (1-C)*f*sinalp*( sig+C*sin(sig)*( cos2sigm+C*cos(sig)*(-1+2*cos2sigm^2) ) );
					cri = abs( lam - l1_lam );
					l1_lam = lam;
					if( cnt++ > maxIt ){
						printf("{err}Convergence not achieved in Vincenty formula \n")
						printf("{err}region %f, \t region %f \n", i, j )
						printf("{err}Add approx option to avoid convergence error \n")
						exit(error(430))
					}
				}while( cri > eps )
				
				/*After Iteration*/
				u2 = cos2alp * ( (a^2-b^2)/b^2 )
				A = 1 + (u2/16384) * ( 4096 + u2*(-768+u2*(320-175*u2)) )
				B = u2/1024 * (256 + u2*(-128+u2*(74-47*u2)) )
				dsig = B*sin(sig)*( cos2sigm + 0.25*B*( cos(sig)*(-1+2*cos2sigm^2)-1/6*B*cos2sigm*(-3+4*sin(sig)^2)*(-3+4*cos2sigm) ) )
				mD[i, j] = b * A * (sig-dsig)
				
				/*Display Iteration Progress*/
				if( itr == itr10percent ){
					printf("{txt}{c |}Completed:  10%%{c |}\n")
				}
				else if( itr == itr20percent ){
					printf("{txt}{c |}Completed:  20%%{c |}\n")
				}
				else if( itr == itr30percent ){
					printf("{txt}{c |}Completed:  30%%{c |}\n")
				}
				else if( itr == itr40percent ){
					printf("{txt}{c |}Completed:  40%%{c |}\n")
				}
				else if( itr == itr50percent ){
					printf("{txt}{c |}Completed:  50%%{c |}\n")
				}
				else if( itr == itr60percent ){
					printf("{txt}{c |}Completed:  60%%{c |}\n")
				}
				else if( itr == itr70percent ){
					printf("{txt}{c |}Completed:  70%%{c |}\n")
				}
				else if( itr == itr80percent ){
					printf("{txt}{c |}Completed:  80%%{c |}\n")
				}
				else if( itr == itr90percent ){
					printf("{txt}{c |}Completed:  90%%{c |}\n")
				}
				else if( itr == cItr ){
					printf("{txt}{c |}Completed: 100%%{c |}\n")
					printf("{txt}{c BT}{hline 15}{c BT}\n")
				}
			}
		}
	}
	/*Simplified Version of Vincenty Formula*/
	else if( appdist == 1 ){
	
		/*LOOP for Bilateral Distance*/
		for( i = 1; i <= cN; ++i ){
			for( j = i + 1; j <= cN; ++j ){

				++itr
				if( itr == 1 ){
					printf("{txt}Calculating bilateral distance...\n")
					printf("{txt}{c TT}{hline 15}{c TT}\n")
				}
				
				difflonr = abs( lonr[i] - lonr[j] )
				numer1 = ( cos(latr[j])*sin(difflonr) )^2
				numer2 = ( cos(latr[i])*sin(latr[j]) - sin(latr[i])*cos(latr[j])*cos(difflonr) )^2
				numer = sqrt( numer1 + numer2 )
				denom = sin(latr[i])*sin(latr[j]) + cos(latr[i])*cos(latr[j])*cos(difflonr)
				mD[i, j] = 6378.137 * atan2( denom, numer )
				
				/*Display Iteration Progress*/
				if( itr == itr10percent ){
					printf("{txt}{c |}Completed:  10%%{c |}\n")
				}
				else if( itr == itr20percent ){
					printf("{txt}{c |}Completed:  20%%{c |}\n")
				}
				else if( itr == itr30percent ){
					printf("{txt}{c |}Completed:  30%%{c |}\n")
				}
				else if( itr == itr40percent ){
					printf("{txt}{c |}Completed:  40%%{c |}\n")
				}
				else if( itr == itr50percent ){
					printf("{txt}{c |}Completed:  50%%{c |}\n")
				}
				else if( itr == itr60percent ){
					printf("{txt}{c |}Completed:  60%%{c |}\n")
				}
				else if( itr == itr70percent ){
					printf("{txt}{c |}Completed:  70%%{c |}\n")
				}
				else if( itr == itr80percent ){
					printf("{txt}{c |}Completed:  80%%{c |}\n")
				}
				else if( itr == itr90percent ){
					printf("{txt}{c |}Completed:  90%%{c |}\n")
				}
				else if( itr == cItr ){
					printf("{txt}{c |}Completed: 100%%{c |}\n")
					printf("{txt}{c BT}{hline 15}{c BT}\n")
				}
			}
		}
	}
			
	/*Distance Matrix: Overwrite mD to save meory space*/
	mD = mD + mD'
	
	/*Distance = . between i and i*/
	_diag(mD, .)
	
	/*Convert Unit of Distance*/
	if( unit == "mi" ){
		mD = 0.621371 :* mD
	}
	
	/*Message*/
	printf("{txt}Calculating Moran's I Statistics...\n")

	/*Binary SWM*/
	if( swmtype == "bin" ){
		if( sweight == 0 ){
			mW = ( mD :< dist )
		}
		else if( sweight == 1 ){
			mW = ( mD :< dist ) :* (vZ')
		}
		/*ERROR CHECK*/
		numErrorSwmNoNeighbor = colsum( rowsum((mD :<= dist) :> 0) :== 0 )
		/*Diagonal Element 0*/
		_diag(mW, 0)
		mW = mW :/ rowsum(mW)
		/*ERROR CHECK*/
		if( numErrorSwmNoNeighbor > 0 ){
			if( numErrorSwmNoNeighbor == 1 ){
				errprintf("Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			if( numErrorSwmNoNeighbor > 1 ){
				errprintf("Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			/*EXIT*/
			exit(3351)
		}
	}
	/*K-Nearest Neighbor SWM*/
	else if( swmtype == "knn" ){
		/*Obtain Threshold Distance for KNN*/
		vDknn = J(cN, 1, 0)
		for (i = 1; i <= cN; ++i) {
			vDSorted = sort(mD[i, .]', 1)
			vDknn[i] = vDSorted[dd]
		}
		if( sweight == 0 ){
			mW = ( mD :<= vDknn )
		}
		else if( sweight == 1 ){
			mW = ( mD :<= vDknn ) :* (vZ')
		}
		/*ERROR CHECK*/
		numErrorSwmMultiNeighbor = colsum( rowsum((mD :<= vDknn) :!= 0) :> dd )
		/*Diagonal Element 0*/
		_diag(mW, 0)
		mW = mW :/ rowsum(mW)
		/*ERROR CHECK*/
		if(numErrorSwmMultiNeighbor > 0){
			if( numErrorSwmMultiNeighbor == 1 ){
				printf("{txt}Warning: %1.0f observation has multiple k-nearest neighbors.\n", numErrorSwmMultiNeighbor)
			}
			if( numErrorSwmMultiNeighbor > 1 ){
				printf("{txt}Warning: %1.0f observations have multiple k-nearest neighbors.\n", numErrorSwmMultiNeighbor)
			}
		}
	}
	/*Exponential SWM*/
	else if( swmtype == "exp" ){
		if( sweight == 0 ){
			mW = ( mD :< dist ) :* exp( - dd :* mD ) 
		}
		else if( sweight == 1 ){
			mW = ( mD :< dist ) :* exp( - dd :* mD ) :* (vZ') 
		}
		/*ERROR numErrorSwmNoNeighbor*/
		numErrorSwmNoNeighbor = colsum( rowsum((mD :<= dist) :> 0) :== 0 )
		/*Diagonal Element 0*/
		_diag(mW, 0)
		mW = mW :/ rowsum(mW)
		/*ERROR CHECK*/
		if( numErrorSwmNoNeighbor > 0 ){
			if( numErrorSwmNoNeighbor == 1 ){
				errprintf("Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			if( numErrorSwmNoNeighbor > 1 ){
				errprintf("Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			/*EXIT*/
			exit(3351)
		}
	}
	/*Power SWM*/
	else if( swmtype == "pow" ){
		if( sweight == 0 ){
			mW = ( mD :< dist ) :* mD :^(-dd)
		}
		else if( sweight == 1 ){
			mW = ( mD :< dist ) :* mD :^(-dd) :* (vZ')
		}
		/*ERROR CHECK*/
		numErrorSwmNoNeighbor = colsum( rowsum((mD :<= dist) :> 0) :== 0 )
		/*Diagonal Element 0*/
		_diag(mW, 0)
		mW = mW :/ rowsum(mW)
		/*ERROR CHECK*/
		if( numErrorSwmNoNeighbor > 0 ){
			if( numErrorSwmNoNeighbor == 1 ){
				errprintf("Warning: %1.0f observation has no neighbor. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			if( numErrorSwmNoNeighbor > 1 ){
				errprintf("Warning: %1.0f observations have no neighbor. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			/*EXIT*/
			exit(3351)
		}
	}
		
	/*Moran's I from Definition*/
	vsy = ( vy :- mean(vy) ) :/ sqrt( variance(vy) )
	vwy = mW * vy
	vwsy = mW * vsy
	dI = (vsy'vwsy) / (vsy'vsy)

	/*Calculate Expectation and Variance of Global Moran's I*/
	dS0 = cN
	dS1 = 0.5 * colsum( rowsum( (mW :+ mW'):^2 ) )
	dS2 = 1.0 * colsum( rowsum( mW :+ mW' ):^2 )
	vS1 = .
	vS2 = .
	dD = cN * colsum( vsy:^4 ) / (colsum(vsy:^2))^2
	dC = (cN-1)*(cN-2)*(cN-3) * dS0^2
	dB = dD * ( (cN^2-cN)*dS1 - 2*cN*dS2 + 6*dS0^2 )
	dA = cN * ( (cN^2-3*cN+3)*dS1 - cN*dS2 + 3*dS0^2 )

	/*Calculate Z-value of Global Moran's I*/
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
	
	vRowSumW = rowsum(mW)
	vLocalMoranTemp1 = rowsum(mW:^2)
	vLocalMoranTemp2 = J(cN, 1, 1)
	/*Calculate Expectation and Variance of Local Moran's I*/
	if(dI == .){
		vZIi = J(cN, 1, .)
		vPIi = J(cN, 1, .)
	}
	else {
		vIi = (cN - 1) :* vsy :* vwsy :/ (vsy'vsy) 
		vEIi = - vRowSumW :/ (cN - 1)
		vW1 = vLocalMoranTemp1
		/*Anselin, L. (1995)*/
		vW2 = vLocalMoranTemp2
		/*Sokal et al. (1998) Local Spatial Autocorrelation in a Biological Model, Geographical Analysis, 30(4)*/
		/*vW2 = vLocalMoranTemp2 :- vLocalMoranTemp1*/
		vVarIi1 = vW1 :* (cN - dD) :/ (cN - 1)
		vVarIi2 = vW2 :* (2*dD - cN)  :/ ( (cN - 1)*(cN - 2) )
		vVarIi3 = (vEIi):^2
		vVarIi = vVarIi1 + vVarIi2 - vVarIi3
		vZIi = (vIi :- vEIi) :/ sqrt(vVarIi)
		vPIi = 2 :* ( 1 :- normal(abs(vZIi)) )
	}
	
	/*Summary Statistics of Local Moran's I*/
	if(dI == .){
		mStatLM = J(4, 4, .)
	}
	else {
		mStatLM = J(4, 4, 0)
		mean_y = mean(vy)
		mean_wy = mean(vwy)
		vHH = (vwy :>= mean_wy) :* (vy :>= mean_y)
		vHL = (vwy :< mean_wy) :* (vy :>= mean_y)
		vLH = (vwy :>= mean_wy) :* (vy :< mean_y)
		vLL = (vwy :< mean_wy) :* (vy :< mean_y)
		vP010 = vPIi :< 0.10
		vP005 = vPIi :< 0.05
		vP001 = vPIi :< 0.01
		mStatLM[1,] = colsum(vHH), colsum(vHH :* vP010), colsum(vHH :* vP005), colsum(vHH :* vP001)
		mStatLM[2,] = colsum(vHL), colsum(vHL :* vP010), colsum(vHL :* vP005), colsum(vHL :* vP001)
		mStatLM[3,] = colsum(vLH), colsum(vLH :* vP010), colsum(vLH :* vP005), colsum(vLH :* vP001)
		mStatLM[4,] = colsum(vLL), colsum(vLL :* vP010), colsum(vLL :* vP005), colsum(vLL :* vP001)
	}
	
	/*Summary Statistics of Distance Matrix*/
	if( matsave == 1 ){
		mD_L = lowertriangle(mD)
		mD = .
		vD = select(vech(mD_L), vech(mD_L):>0)
		cN_vD = rows(vD)
		dist_mean = mean(vD)
		dist_sd = sqrt(variance(vD))
		dist_min = min(vD)
		dist_max = max(vD)
		vD = .
	}
	else {
		mW = .
		mD = .
		mD_L = .
		dist_mean = .
		dist_sd = .
		dist_min = .
		dist_max = .
	}
	
	
	/*Display Summary Statistics of Distances*/
	printf("\n")
	if( appdist == 1 ){
		if( unit == "km" ){
			printf("{txt}Distance by simplified version of Vincenty formula (unit: km)\n")
		}
		if( unit == "mi" ){
			printf("{txt}Distance by simplified version of Vincenty formula (unit: mi)\n")
		}
	}
	if( appdist == 0 ){
		if( unit == "km" ){
			printf("{txt}Distance by Vincenty formula (unit: km)\n")
		}
		if( unit == "mi" ){
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
			printf("{txt}Distance threshold (unit: km):{res} %5.0f\n", dist)
		}
		if( unit == "mi" ){
			printf("{txt}Distance threshold (unit: mi):{res} %5.0f\n", dist)
		}
		printf("{txt}{hline 85}\n")
		printf("\n")
	}

	/*For Long Variable Name*/
	sY = abbrev(vY, 20)

	/*Results of Global Moran's I*/
	printf("\n")
	printf("{txt}Summary of Global Moran's I Statistic {space 20} Number of Obs. = {res}%9.0f\n", cN)
	printf("{txt}{hline 21}{c TT}{hline 63}\n")
	printf("{txt}{space 12}Variable {c |}  Moran's I{space 9}E(I){space 8}SE(I){space 9}Z(I){space 6}p-value\n")
	printf("{hline 21}{c +}{hline 63}\n")
	printf("{txt}%20s {c |} {res}%10.5f   %10.5f   %10.5f   %10.5f   %10.5f\n", sY, dI, dEI, dSEI, dZI, dPI )
	printf("{txt}{hline 21}{c BT}{hline 63}\n")
	printf("{txt}Null Hypothesis: Spatial Randomization\n")
	printf("\n")

	/*Results of Local Moran's I*/
	if( genvar == 1 ){
		printf("\n")
		printf("{txt}Summary of Local Moran's I Statistics {space 20} Number of Obs. = {res}%9.0f\n", cN)
		printf("{txt}{hline 21}{c TT}{hline 63}\n")
		printf("{txt}%20s {c |}{space 11}Obs.{space 8}p < 0.10{space 8}p < 0.05{space 8}p < 0.01\n", sY)
		printf("{hline 21}{c +}{hline 63}\n")
		printf("{txt}{space 7} 1: High-High {c |} {res}%14.0f   %13.0f   %13.0f   %13.0f\n", mStatLM[1,1], mStatLM[1,2], mStatLM[1,3], mStatLM[1,4])
		printf("{txt}{space 7} 2: High-Low  {c |} {res}%14.0f   %13.0f   %13.0f   %13.0f\n", mStatLM[2,1], mStatLM[2,2], mStatLM[2,3], mStatLM[2,4])
		printf("{txt}{space 7} 3: Low-High  {c |} {res}%14.0f   %13.0f   %13.0f   %13.0f\n", mStatLM[3,1], mStatLM[3,2], mStatLM[3,3], mStatLM[3,4])
		printf("{txt}{space 7} 4: Low-Low   {c |} {res}%14.0f   %13.0f   %13.0f   %13.0f\n", mStatLM[4,1], mStatLM[4,2], mStatLM[4,3], mStatLM[4,4])
		printf("{txt}{hline 21}{c BT}{hline 63}\n")
		printf("{txt}Null Hypothesis: Spatial Randomization\n")
		printf("\n")
	}
	
	/*Return Results in Mata to Stata*/
	if( genvar == 1 ){
		st_store(., st_addvar("float", "splag_"+vY+"_"+substr(swmtype, 1, 1)), st_local("touse"), vwy)
		st_store(., st_addvar("float", "lmoran_i_"+vY+"_"+substr(swmtype, 1, 1)), st_local("touse"), vIi)
		st_store(., st_addvar("float", "lmoran_e_"+vY+"_"+substr(swmtype, 1, 1)), st_local("touse"), vEIi)
		st_store(., st_addvar("float", "lmoran_v_"+vY+"_"+substr(swmtype, 1, 1)), st_local("touse"), vVarIi)
		st_store(., st_addvar("float", "lmoran_z_"+vY+"_"+substr(swmtype, 1, 1)), st_local("touse"), vZIi)
		st_store(., st_addvar("float", "lmoran_p_"+vY+"_"+substr(swmtype, 1, 1)), st_local("touse"), vPIi)
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
	if( sweight == 1 ){
		st_global("r(weight)", wvar)
	}
	else if( sweight == 0 ){
		st_global("r(weight)", ".")
	}
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

/*## MATA ## Calculate Moran's I*/
version 11.0
mata:
void calcmoransi_loop_vector(vY, lon, lat, fmdms, swmtype, dist, unit, dd, wvar, sweight, appdist, dispdetail, matsave, genvar, touse)
{
	/*Linebreak*/
	printf("{txt}\n")

	/*Make Variable*/
	if( fmdms == "1" ){
		printf("{txt}Convert DMS format to Decimal format.")
		convlonlat2decimal(lon, lat, touse, &vlon, &vlat)		
	} 
	else {
		st_view(vlon, ., lon, touse)
		st_view(vlat, ., lat, touse)
	}
	latr = ( pi() / 180 ) * vlat; 
	lonr = ( pi() / 180 ) * vlon; 

	/*Make Variable*/
	st_view(vy, ., vY, touse)
	cN = rows(vlon)

	/*Import Weight Variable*/
	if( sweight == 1 ){
		st_view(vZ, ., wvar, touse)
	}
	
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
	numErrorSwmMultiNeighbor = 0
	numErrorSwmNoNeighbor = 0
	
	/*Spatial Lag*/
	vDist = J(1, cN, 0)
	vW = J(1, cN, 0)
	mW = J(cN, cN, 0)
	vsy = ( vy :- mean(vy) ) :/ sqrt( variance(vy) )
	vwy = J(cN, 1, 0)
	vwsy = J(cN, 1, 0)

	/*Variables for Local Moran's I*/
	vRowSumW = J(cN, 1, 1)
	vLocalMoranTemp1 = J(cN, 1, 0)
	vLocalMoranTemp2 = J(cN, 1, 1)
	
	/*Iteration Progress*/
	itr10percent = trunc(cN/10)
	itr20percent = 2 * trunc(cN/10)
	itr30percent = 3 * trunc(cN/10)
	itr40percent = 4 * trunc(cN/10)
	itr50percent = trunc(cN/2)
	itr60percent = trunc(cN/2) + trunc(cN/10)
	itr70percent = trunc(cN/2) + 2 * trunc(cN/10)
	itr80percent = trunc(cN/2) + 3 * trunc(cN/10)
	itr90percent = trunc(cN/2) + 4 * trunc(cN/10)
	
	/*LOOP For Each Location*/
	for( i = 1; i <= cN; ++i ){
	
		/*Display Iteration Process */
		if( i == 1 ){
			printf("{txt}Calculating bilateral distance...\n")
			printf("{txt}{c TT}{hline 15}{c TT}\n")
		}
		
		/*Vincenty Formula*/
		if( appdist == 0 ){

			/*Variables*/
			a = 6378.137
			b = 6356.752314245
			f = (a-b)/a
			eps = 1e-12
			maxIt = 1e+5
			
			/*Variables*/
			Alon = J(1, cN, 1) :* lonr[i]
			Blon = J(1, cN, 1) :* lonr'
			Clat = J(1, cN, 1) :* latr[i]
			Dlat = J(1, cN, 1) :* latr'
			U1 = atan( (1-f) :* tan(Clat) )
			U2 = atan( (1-f) :* tan(Dlat) )
			L = abs( Alon :- Blon )
			lam = L
			l1_lam = lam
			
			/*Loop*/
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
		}
		/*Simplified Version of Vincenty Formula*/
		else if( appdist == 1 ){
			/*Variables*/
			a = 6378.137

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
			vDist = a * atan2( denom, numer )	
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
		
		/*Binary SWM*/
		if( swmtype == "bin" ){
			if( sweight == 0 ){
				vW = ( vDist :< dist )
			}
			else if( sweight == 1 ){
				vW = ( ( vDist :< dist ) :* (vZ') )
			}
			/*ERROR CHECK*/
			numErrorSwmNoNeighbor = numErrorSwmNoNeighbor + ( rowsum((vDist :< dist) :> 0) == 0 )
			/*Diagonal Element*/
			vW[i] = 0 
		}
		/*K-Nearest Neighbor SWM*/
		if( swmtype == "knn" ){
			/*Obtain Threshold Distance for KNN*/
			vDistSorted = sort(vDist', 1)'
			dDistKnn = vDistSorted[dd]
			if( sweight == 0 ){
				vW = ( vDist :<= dDistKnn )
			}
			else if( sweight == 1 ){
				vW = ( ( vDist :<= dDistKnn ) :* (vZ') )
			}
			/*ERROR CHECK*/
			numErrorSwmMultiNeighbor = numErrorSwmMultiNeighbor + ( rowsum((vDist :< dist) :!= 0) > dd )
			/*Diagonal Element*/
			vW[i] = 0 
		}
		/*Exponential SWM*/
		if( swmtype == "exp" ){
			if( sweight == 0 ){
				vW = ( vDist :< dist ) :* exp( - dd :* vDist )
			}
			else if( sweight == 1 ){
				vW = ( vDist :< dist ) :* exp( - dd :* vDist ) :* (vZ') 
			}
			/*ERROR CHECK*/
			numErrorSwmNoNeighbor = numErrorSwmNoNeighbor + ( rowsum((vDist :< dist) :> 0) == 0 )
			/*Diagonal Element*/
			vW[i] = 0 
		}
		/*Power SWM*/
		if( swmtype == "pow" ){
			if( sweight == 0 ){
				vW = ( vDist :< dist ) :* vDist :^(-dd)
			}
			else if( sweight == 1 ){
				vW = ( vDist :< dist ) :* vDist :^(-dd) :* (vZ')
			}
			/*ERROR CHECK*/
			numErrorSwmNoNeighbor = numErrorSwmNoNeighbor + ( rowsum((vDist :< dist) :> 0) == 0 )
			/*Diagonal Element*/
			vW[i] = 0 
		}

		/*Row-Standardized SWM*/
		vW = vW :/ rowsum(vW)
		
		/*Save Distance Matrix*/
		if( matsave == 1 ){
			mD[i,] = vDist
		}
		vDist = .
		
		/*Spatial Lagged Variable*/
		mW[i,] = vW
		vwy[i,] = vW * vy
		vwsy[i,] = vW * vsy

		/*Variables for Local Moran's I*/
		if( genvar == 1 ){
			/*Value is 1 for Row-Standardized SWM*/
			/*vRowSumW[i] = rowsum(vW)*/
			
			/*Term of Variance*/
			vLocalMoranTemp1[i] = rowsum(vW:^2)
			
			/*Value is 1 for Row-Standardized SWM*/
			/*vLocalMoranTemp2[i] = colsum(rowsum(vW' * vW))*/
		}
		
		/*Display Iteration Progress*/
		if( i == itr10percent ){
			printf("{txt}{c |}Completed:  10%%{c |}\n")
		}
		else if( i == itr20percent ){
			printf("{txt}{c |}Completed:  20%%{c |}\n")
		}
		else if( i == itr30percent ){
			printf("{txt}{c |}Completed:  30%%{c |}\n")
		}
		else if( i == itr40percent ){
			printf("{txt}{c |}Completed:  40%%{c |}\n")
		}
		else if( i == itr50percent ){
			printf("{txt}{c |}Completed:  50%%{c |}\n")
		}
		else if( i == itr60percent ){
			printf("{txt}{c |}Completed:  60%%{c |}\n")
		}
		else if( i == itr70percent ){
			printf("{txt}{c |}Completed:  70%%{c |}\n")
		}
		else if( i == itr80percent ){
			printf("{txt}{c |}Completed:  80%%{c |}\n")
		}
		else if( i == itr90percent ){
			printf("{txt}{c |}Completed:  90%%{c |}\n")
		}
		else if( i == cN ){
			printf("{txt}{c |}Completed: 100%%{c |}\n")
			printf("{txt}{c BT}{hline 15}{c BT}\n")
		}
	}

	/*REPORT ERROR CHECK*/
	if( swmtype == "bin" ){
		if( numErrorSwmNoNeighbor > 0 ){
			if( numErrorSwmNoNeighbor == 1 ){
				errprintf("Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			if( numErrorSwmNoNeighbor > 1 ){
				errprintf("Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			/*EXIT*/
			exit(3351)
		}
	}
	else if( swmtype == "knn" ){
		if( numErrorSwmMultiNeighbor > 0 ){
			if( numErrorSwmMultiNeighbor == 1 ){
				printf("{txt}Warning: %1.0f observation has multiple k-nearest neighbors.\n", numErrorSwmMultiNeighbor)
			}
			if( numErrorSwmMultiNeighbor > 1 ){
				printf("{txt}Warning: %1.0f observations have multiple k-nearest neighbors.\n", numErrorSwmMultiNeighbor)
			}
		}
	}
	else if( swmtype == "exp" ){
		if( numErrorSwmNoNeighbor > 0 ){
			if( numErrorSwmNoNeighbor == 1 ){
				errprintf("Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			if( numErrorSwmNoNeighbor > 1 ){
				errprintf("Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			/*EXIT*/
			exit(3351)
		}
	}
	else if( swmtype == "pow" ){
		if( numErrorSwmNoNeighbor > 0 ){
			if( numErrorSwmNoNeighbor == 1 ){
				errprintf("Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			if( numErrorSwmNoNeighbor > 1 ){
				errprintf("Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			/*EXIT*/
			exit(3351)
		}
	}

	/*Message*/
	printf("{txt}Calculating Moran's I Statistics...\n")
	
	/*Moran's I from Definition*/
	dI = (vsy'vwsy) / (vsy'vsy)

	/*Calculate Expectation and Variance of Global Moran's I*/
	dS0 = cN
	vS1 = J(cN, 1, 0)
	vS2 = J(cN, 1, 0)
	for( i = 1; i <= cN; ++i ){
		vS1[i] = rowsum( (mW[i,] :+ mW[,i]'):^2 )
		vS2[i] = rowsum( mW[i,] :+ mW[,i]' ):^2 
	}
	dS1 = 0.5 * colsum( vS1 )
	dS2 = 1.0 * colsum( vS2 )
	vS1 = .
	vS2 = .
	dD = cN * colsum( vsy:^4 ) / (colsum(vsy:^2))^2
	dC = (cN-1)*(cN-2)*(cN-3) * dS0^2
	dB = dD * ( (cN^2-cN)*dS1 - 2*cN*dS2 + 6*dS0^2 )
	dA = cN * ( (cN^2-3*cN+3)*dS1 - cN*dS2 + 3*dS0^2 )

	/*Calculate Z-value of Global Moran's I*/
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
	
	/*Calculate Expectation and Variance of Local Moran's I*/
	if(dI == .){
		vZIi = J(cN, 1, .)
		vPIi = J(cN, 1, .)
	}
	else {
		vIi = (cN - 1) :* vsy :* vwsy :/ (vsy'vsy) 
		vEIi = - vRowSumW :/ (cN - 1)
		vW1 = vLocalMoranTemp1
		/*Anselin, L. (1995)*/
		vW2 = vLocalMoranTemp2
		/*Sokal et al. (1998) Local Spatial Autocorrelation in a Biological Model, Geographical Analysis, 30(4)*/
		/*vW2 = vLocalMoranTemp2 :- vLocalMoranTemp1*/
		vVarIi1 = vW1 :* (cN - dD) :/ (cN - 1)
		vVarIi2 = vW2 :* (2*dD - cN)  :/ ( (cN - 1)*(cN - 2) )
		vVarIi3 = (vEIi):^2
		vVarIi = vVarIi1 + vVarIi2 - vVarIi3
		vZIi = (vIi :- vEIi) :/ sqrt(vVarIi)
		vPIi = 2 :* ( 1 :- normal(abs(vZIi)) )
	}
	
	/*Summary Statistics of Local Moran's I*/
	if(dI == .){
		mStatLM = J(4, 4, .)
	}
	else {
		mStatLM = J(4, 4, 0)
		mean_y = mean(vy)
		mean_wy = mean(vwy)
		vHH = (vwy :>= mean_wy) :* (vy :>= mean_y)
		vHL = (vwy :< mean_wy) :* (vy :>= mean_y)
		vLH = (vwy :>= mean_wy) :* (vy :< mean_y)
		vLL = (vwy :< mean_wy) :* (vy :< mean_y)
		vP010 = vPIi :< 0.10
		vP005 = vPIi :< 0.05
		vP001 = vPIi :< 0.01
		mStatLM[1,] = colsum(vHH), colsum(vHH :* vP010), colsum(vHH :* vP005), colsum(vHH :* vP001)
		mStatLM[2,] = colsum(vHL), colsum(vHL :* vP010), colsum(vHL :* vP005), colsum(vHL :* vP001)
		mStatLM[3,] = colsum(vLH), colsum(vLH :* vP010), colsum(vLH :* vP005), colsum(vLH :* vP001)
		mStatLM[4,] = colsum(vLL), colsum(vLL :* vP010), colsum(vLL :* vP005), colsum(vLL :* vP001)
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
		mD = .
		mD_L = .
		dist_mean = .
		dist_sd = .
		dist_min = .
		dist_max = .
	}
	
	/*Display Summary Statistics of Distances*/
	printf("\n")
	if( appdist == 1 ){
		if( unit == "km" ){
			printf("{txt}Distance by simplified version of Vincenty formula (unit: km)\n")
		}
		if( unit == "mi" ){
			printf("{txt}Distance by simplified version of Vincenty formula (unit: mi)\n")
		}
	}
	if( appdist == 0 ){
		if( unit == "km" ){
			printf("{txt}Distance by Vincenty formula (unit: km)\n")
		}
		if( unit == "mi" ){
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
			printf("{txt}Distance threshold (unit: km):{res} %5.0f\n", dist)
		}
		if( unit == "mi" ){
			printf("{txt}Distance threshold (unit: mi):{res} %5.0f\n", dist)
		}
		printf("{txt}{hline 85}\n")
		printf("\n")
	}

	/*For Long Variable Name*/
	sY = abbrev(vY, 20)

	/*Results of Global Moran's I*/
	printf("\n")
	printf("{txt}Summary of Global Moran's I Statistic {space 20} Number of Obs. = {res}%9.0f\n", cN)
	printf("{txt}{hline 21}{c TT}{hline 63}\n")
	printf("{txt}{space 12}Variable {c |}  Moran's I{space 9}E(I){space 8}SE(I){space 9}Z(I){space 6}p-value\n")
	printf("{hline 21}{c +}{hline 63}\n")
	printf("{txt}%20s {c |} {res}%10.5f   %10.5f   %10.5f   %10.5f   %10.5f\n", sY, dI, dEI, dSEI, dZI, dPI )
	printf("{txt}{hline 21}{c BT}{hline 63}\n")
	printf("{txt}Null Hypothesis: Spatial Randomization\n")
	printf("\n")

	/*Results of Local Moran's I*/
	if( genvar == 1 ){
		printf("\n")
		printf("{txt}Summary of Local Moran's I Statistics {space 20} Number of Obs. = {res}%9.0f\n", cN)
		printf("{txt}{hline 21}{c TT}{hline 63}\n")
		printf("{txt}%20s {c |}{space 11}Obs.{space 8}p < 0.10{space 8}p < 0.05{space 8}p < 0.01\n", sY)
		printf("{hline 21}{c +}{hline 63}\n")
		printf("{txt}{space 7} 1: High-High {c |} {res}%14.0f   %13.0f   %13.0f   %13.0f\n", mStatLM[1,1], mStatLM[1,2], mStatLM[1,3], mStatLM[1,4])
		printf("{txt}{space 7} 2: High-Low  {c |} {res}%14.0f   %13.0f   %13.0f   %13.0f\n", mStatLM[2,1], mStatLM[2,2], mStatLM[2,3], mStatLM[2,4])
		printf("{txt}{space 7} 3: Low-High  {c |} {res}%14.0f   %13.0f   %13.0f   %13.0f\n", mStatLM[3,1], mStatLM[3,2], mStatLM[3,3], mStatLM[3,4])
		printf("{txt}{space 7} 4: Low-Low   {c |} {res}%14.0f   %13.0f   %13.0f   %13.0f\n", mStatLM[4,1], mStatLM[4,2], mStatLM[4,3], mStatLM[4,4])
		printf("{txt}{hline 21}{c BT}{hline 63}\n")
		printf("{txt}Null Hypothesis: Spatial Randomization\n")
		printf("\n")
	}
	
	/*Return Results in Mata to Stata*/
	if( genvar == 1 ){
		st_store(., st_addvar("float", "splag_"+vY+"_"+substr(swmtype, 1, 1)), st_local("touse"), vwy)
		st_store(., st_addvar("float", "lmoran_i_"+vY+"_"+substr(swmtype, 1, 1)), st_local("touse"), vIi)
		st_store(., st_addvar("float", "lmoran_e_"+vY+"_"+substr(swmtype, 1, 1)), st_local("touse"), vEIi)
		st_store(., st_addvar("float", "lmoran_v_"+vY+"_"+substr(swmtype, 1, 1)), st_local("touse"), vVarIi)
		st_store(., st_addvar("float", "lmoran_z_"+vY+"_"+substr(swmtype, 1, 1)), st_local("touse"), vZIi)
		st_store(., st_addvar("float", "lmoran_p_"+vY+"_"+substr(swmtype, 1, 1)), st_local("touse"), vPIi)
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
	if( sweight == 1 ){
		st_global("r(weight)", wvar)
	}
	else if( sweight == 0 ){
		st_global("r(weight)", ".")
	}
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
version 11.0
mata:
void convlonlat2decimal(lat, lon, touse, vlat, vlon)
{
	st_view(vlat_, ., lat, touse)
	st_view(vlon_, ., lon, touse)
	(*vlat) = floor(vlat_) :+ (floor((vlat_:-floor(vlat_)):*100):/60) :+ (floor((vlat_:*100:-floor(vlat_:*100)):*100):/3600)
	(*vlon) = floor(vlon_) :+ (floor((vlon_:-floor(vlon_)):*100):/60) :+ (floor((vlon_:*100:-floor(vlon_:*100)):*100):/3600)
}
end
