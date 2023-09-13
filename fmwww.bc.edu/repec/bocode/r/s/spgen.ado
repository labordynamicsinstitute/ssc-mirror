/***********************************************************
** (C) KEISUKE KONDO
** 
** Release Date: October 24, 2015
** Last Updated: June 17, 2021
** Version: 1.40
** 
** 
** [Contact]
** Email: kondo-keisuke@rieti.go.jp
** URL: https://sites.google.com/site/keisukekondokk/
***********************************************************/
** Version: 1.40
** Added "knn" for "swm()" option
** Added "rowif()" option
** Added "suffix()" option
** Added "r(W)" in r()
** Added "odweight" and "dweight" options
** Added "replace" option
** Alert message for missing observations
** Alert message for spatial weight matrix 
** Allowed multiple variables
** Coding improvement for saming memory space
** Version: 1.33
** Small improvement of coding
** Version: 1.32
** Bug fix for error check of latitude and longitude ranges
** Version: 1.31
** Small bug fix for error indication in Vincenty formula
** Changed maximum number of iteration in Vincenty formula (1e+5 <- 100)
** Version: 1.30
** Improved the program for large-sized spatial weight matrix
** Added "largesize" option
** Version: 1.22
** Bug Fix for diagonal elements of swm(bin) 
** Version: 1.21
** Improved the program for large-sized spatial weight matrix
** Added "nomatsave" option
** Version: 1.20
** Added "wvar()" option for weight variable
** Added "dunit()" option for distance unit
** Version: 1.10
** Added "nostd" option for row standardization
** 
** 

capture program drop spgen
program spgen, sortpreserve rclass
	version 11
	syntax varlist [if] [in], /*
			*/ lat(varname) /*
			*/ lon(varname) /*
			*/ swm(string) /*
			*/ dist(real) /*
			*/ dunit(string) /*
			*/ [ /*
			*/ Order(real 1) /*
			*/ WVAR(varname) /*
			*/ ROWIF(varname) /*
			*/ SUFfix(string) /*
			*/ NOMATsave /*
			*/ NOSTD /*
			*/ DMS /*
			*/ APProx /*
			*/ DETail /*
			*/ LARGEsize /*
			*/ REPlace ]

	/*Variables*/
	local mY `varlist'
	local swmtype = substr("`swm'", 1, 3)
	local swmtype_short = substr("`swm'", 1, 1)
	local unit = "`dunit'"
	marksample touse
	markout `touse' `mY' `lat' `lon' `wvar' `rowif' 

	/*Check Duplication of Multiple Variables*/
	local cnt_vari = 0
	foreach vari in `mY' {
		local cnt_vari = `cnt_vari' + 1 
		local cnt_varj = 0
		foreach varj in `mY' {
			local cnt_varj = `cnt_varj' + 1
			if( `cnt_vari' < `cnt_varj' ){
				if("`vari'" == "`varj'"){
					display as error "`vari' is duplicated in varlist."
					exit 198
				}
			}
		}
	}
	
	/*Check Missing Values of Variables*/
	qui: egen ______missing_count_spgen = rowmiss(`mY')
	qui: count if ______missing_count_spgen > 0
	local nummissing = r(N)
	local errormissing = 0
	if(`nummissing' > 0){
		local errormissing = 1
	}
	if( `errormissing' == 1 & strpos("`mY'", " ") == 0){
		if(`nummissing' == 1){
			display as text "Warning: `nummissing' observation with missing value is dropped."
		}
		if(`nummissing' > 1){
			display as text "Warning: `nummissing' observations with missing value are dropped."
		}
	}
	if( `errormissing' == 1 & strpos("`mY'", " ") > 0){
		if(`nummissing' == 1){
			display as text "Warning: `nummissing' observation with missing value is dropped w.r.t. multiple variables."
		}
		if(`nummissing' > 1){
			display as text "Warning: `nummissing' observations with missing value are dropped w.r.t. multiple variables."
		}
	}
	qui: drop ______missing_count_spgen
	
	/*Store Number and Name of Variables*/
	local _num_var = 0
	foreach var in `mY' {
		local _num_var = `_num_var' + 1
		local _name_var`_num_var' = "`var'"
	}
	
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
	
	/*Error Check*/
	qui: duplicates report `lon' `lat' if `touse' == 1
	if (`r(unique_value)' != `r(N)'){
		display as text "Warning: There are duplicated locations. swm(pow #) returns missing values for them."
	}	
	
	/*Check Spatial Weight Matrix*/
	if( "`swmtype'" != "bin" & "`swmtype'" != "knn" & "`swmtype'" != "exp" & "`swmtype'" != "pow" ){
		display as error "swm() must be one of bin, knn, exp, and pow."
		exit 198
	}

	/*Check Distance Decay Parameter of Spatial Weight Matrix*/
	if( "`swmtype'" == "bin" ){
		if( substr("`swm'", strpos("`swm'", "bin") + length("bin"), 1) != "" ){
			display as error "Error in swm(bin)."
			exit 198
		}
		local dd = . /*not used*/
	}
	else if( "`swmtype'" == "knn" ){
		if( substr("`swm'", strpos("`swm'", "knn") + length("knn"), 1) != " " ){
			display as error "Error in swm(knn #)."
			exit 198
		}
		local dd = real( substr("`swm'", strpos("`swm'", "knn") + length("knn") + 1, .) )
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
		if( substr("`swm'", strpos("`swm'", "exp") + length("exp"), 1) != " " ){
			display as error "Error in swm(exp #)."
			exit 198
		}
		local dd = real( substr("`swm'", strpos("`swm'", "exp") + length("exp") + 1, .) )
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
		if( substr("`swm'", strpos("`swm'", "pow") + length("pow"), 1) != " " ){
			display as error "Error in swm(pow #)."
			exit 198
		}
		local dd = real( substr("`swm'", strpos("`swm'", "pow") + length("pow") + 1, .) )
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
		display as error "dist() must be more than 0."
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

	/*Check Order*/
	if( `order' <= 0 ){
		display as error "order() must be more than 0."
		exit 198
	}
	capture confirm integer number `order'
	if( _rc != 0 ){
		display as error "order() must be integer."
		exit 7
	}
	
	/*Weight Variable*/
	local sweight = 0
	if( "`wvar'" != "" ){
		/*Weight Variable On*/
		local sweight = 1
	}
	
	/*Check variable of ROWIF option*/
	local flag_rowif = 0
	if( "`rowif'" != "" ){
		local flag_rowif = 1
		qui: tab `rowif'
		if( r(r) != 2 ){
			display as error "Specify indicator variable with 1/0 for rowif() option"
			exit 198
		}
		if( r(r) == 2 ){
			qui: sum `rowif'
			local val_rowif = r(max)
			display as text "ROWIF option returns spatial lags for observations with `rowif' = `r(max)'"
		}
	}

	/*Distance Matrix Save Option*/
	local matsave = 1
	if( "`nomatsave'" != "" ){
		local matsave = 0
	}
	
	/*Row Standardization of Spatial Weight Matrix*/
	local rowstd = 1
	if( "`nostd'" != "" ){
		local rowstd = 0
		if( `order' != 1 ){
			display as error "order() must be 1."
			exit 198
		}
	}
	
	/*Convert DMS Format to Decimal Format*/
	local fmdms = 0
	if( "`dms'" != "" ){
		local fmdms = 1
	}
	
	/*Approximation of Distance*/
	local appdist = 0
	if( "`approx'" != "" ){
		local appdist = 1
	}
	
	/*Detail*/
	local dispdetail= 0
	if( "`detail'" != "" ){
		local dispdetail = 1
	}
	
	/*Suffix for Outcome Variable*/
	if( "`suffix'" == "" ){
		local varsuffix = ""
	}
	else if( "`suffix'" != "" ){
		local varsuffix = "`suffix'"
	}

	/*Check Length of Variable Name*/
	local strlen_varname = 0
	if( `sweight' == 1 ){
		foreach var in `mY' {
			local strlen_varname = ustrlen("splag`order'_`var'_`swmtype_short'_`wvar'`varsuffix'")
			if( `strlen_varname' > 32 ) {
				display as error "Outcome variable to be generated has longer than 32 characters. Use short variable names for `var' and `wvar'."
				exit 198
			}
		}
	}
	else if( `sweight' == 0 ){
		foreach var in `mY' {
			local strlen_varname = ustrlen("splag`order'_`var'_`swmtype_short'`varsuffix'")
			if( `strlen_varname' > 32 ) {
				display as error "Outcome variable to be generated has longer than 32 characters. Use short variable name for `var'."
				exit 198
			}
		}
	}
	
	/*Replace Option*/
	if( "`replace'" == "" ){
		/*Check before Making Output Variable*/
		local error_exit = 0
		if( `sweight' == 1 ){
			foreach var in `mY' {
				capture confirm new variable splag`order'_`var'_`swmtype_short'_`wvar'`varsuffix', exact
				if( _rc != 0 ) {
					display as error "Outcome variable for `var' already exists."
					local error_exit = 1
				}
				local _var_rep_`var' = 0
			}
			if( `error_exit' == 1 ){
				exit _rc
			}
		}
		else if( `sweight' == 0 ){
			foreach var in `mY' {
				capture confirm new variable splag`order'_`var'_`swmtype_short'`varsuffix', exact
				if( _rc != 0 ) {
					display as error "Outcome variable for `var' already exists."
					local error_exit = 1
				}
				local _var_rep_`var' = 0
			}
			if( `error_exit' == 1 ){
				exit _rc
			}
		}
	}
	if( "`replace'" != "" ){
		/*Check before Making Output Variable*/
		if( `sweight' == 1 ){
			foreach var in `mY' {
				capture confirm new variable splag`order'_`var'_`swmtype_short'_`wvar'`varsuffix', exact
				if( _rc != 0 ) {
					drop splag`order'_`var'_`swmtype_short'_`wvar'`varsuffix'
					local _var_rep_`var' = 1
				}
				else if( _rc == 0 ){
					local _var_rep_`var' = 0
				}
			}
		}
		else if( `sweight' == 0 ){
			foreach var in `mY' {
				capture confirm new variable splag`order'_`var'_`swmtype_short'`varsuffix', exact
				if( _rc != 0 ) {
					drop splag`order'_`var'_`swmtype_short'`varsuffix'
					local _var_rep_`var' = 1
				}
				else if( _rc == 0 ){
					local _var_rep_`var' = 0
				}
			}
		}
	}
	
	/*Setting for Large Size Option*/
	local large = 0
	if( "`largesize'" != "" ){
		
		/*Error Check*/
		if( `order' != 1 ){
			display as error "order() must be 1 when largesize option is used."
			exit 198
		}

		/*Option*/
		local large = 1
		local matsave = 0
		local appdist = 1
		local order = 1		
	}

	/*Setting for ROFIF Option*/
	if( "`rowif'" != "" ){
		
		/*Error Check*/
		if( `order' != 1 ){
			display as error "order() must be 1 when largesize option is used."
			exit 198
		}
		
		/*Option*/
		local order = 1
	}
	
	/*Generate ID variable
	capture confirm new variable __rowid__, exact
	if( _rc != 0 ){
		display as error "Change variable name __rowid__, which is used during calculation process."
		exit 110
	}
	qui: gen __rowid__ = _n
	*/
	
	/*Call Mata Program*/
	if( `large' == 0 & `flag_rowif' == 0 ){
		mata: calcsplag_matrix("`mY'", "`lat'", "`lon'", `fmdms', "`swmtype'", `dist', "`unit'", `dd', `order', "`wvar'", `sweight', "`varsuffix'", `matsave', `rowstd', `appdist', `dispdetail', "`touse'")
	}
	else if( `large' == 1 & `flag_rowif' == 0 ){
		mata: calcsplag_large("`mY'", "`lat'", "`lon'", `fmdms', "`swmtype'", `dist', "`unit'", `dd', `order', "`wvar'", `sweight', "`varsuffix'", `matsave', `rowstd', `appdist', `dispdetail', "`touse'")
	}
	else if( `large' == 0 & `flag_rowif' == 1 ){
		mata: calcsplag_rowif("`mY'", "`lat'", "`lon'", `fmdms', "`swmtype'", `dist', "`unit'", `dd', `order', "`wvar'", `sweight', "`varsuffix'", "`rowif'", `val_rowif', `matsave', `rowstd', `appdist', `dispdetail', `large', "`touse'")
	}
	else if( `large' == 1 & `flag_rowif' == 1 ){
		mata: calcsplag_rowif("`mY'", "`lat'", "`lon'", `fmdms', "`swmtype'", `dist', "`unit'", `dd', `order', "`wvar'", `sweight', "`varsuffix'", "`rowif'", `val_rowif', `matsave', `rowstd', `appdist', `dispdetail', `large', "`touse'")
	}
	
	/*Store Results in return*/
	return add

	/*Drop ID variable
	qui: drop __rowid__
	*/

	/*Add Variable Label*/
	if( `rowstd' == 1 ){
		if( `sweight' == 1 ){
			foreach var in `mY' {
				label var splag`order'_`var'_`swmtype_short'_`wvar'`varsuffix' "sptial lag, swm(`swm'), td=`dist', od=`order', row-standadized, weighted"
			}
		}
		else if( `sweight' == 0 ){
			foreach var in `mY' {
				label var splag`order'_`var'_`swmtype_short'`varsuffix' "sptial lag, swm(`swm'), td=`dist', od=`order', row-standadized"
			}
		}
	}
	else if( `rowstd' == 0 ){
		if( `sweight' == 1 ){
			foreach var in `mY' {
				label var splag`order'_`var'_`swmtype_short'_`wvar'`varsuffix' "sptial lag, swm(`swm'), td=`dist', od=`order', no row-standadized, weighted"
			}
		}
		else if( `sweight' == 0 ){
			foreach var in `mY' {
				label var splag`order'_`var'_`swmtype_short'`varsuffix' "sptial lag, swm(`swm'), td=`dist', od=`order', no row-standadized"
			}
		}
	}

	/*Display Results*/
	if( `sweight' == 1 ){
		foreach var in `mY' {
			if( `_var_rep_`var'' == 0 ){
				display as txt "{bf:splag`order'_`var'_`swmtype_short'_`wvar'`varsuffix'} was generated in the dataset."
			}
			if( `_var_rep_`var'' == 1 ){
				display as txt "{bf:splag`order'_`var'_`swmtype_short'_`wvar'`varsuffix'} was replaced in the dataset."
			}
		}
	}
	else if( `sweight' == 0 ){
		foreach var in `mY' {
			if( `_var_rep_`var'' == 0 ){
				display as txt "{bf:splag`order'_`var'_`swmtype_short'`varsuffix'} was generated in the dataset."
			}
			if( `_var_rep_`var'' == 1 ){
				display as txt "{bf:splag`order'_`var'_`swmtype_short'`varsuffix'} was replaced in the dataset."
			}
		}
	}
end


/*Calculation of Spatially Lagged Variable*/
** Calculation based on matrix
version 11
mata:
void calcsplag_matrix(mY, lat, lon, fmdms, swmtype, dist, unit, dd, order, wvar, sweight, varsuffix, matsave, rowstd, appdist, dispdetail, touse)
{
	/*Check Format of latitude and longitude*/
	if( fmdms == 1 ){
		printf("{txt}Converting DMS format to decimal format...\n")
		convlonlat2decimal(lat, lon, touse, &vlat, &vlon)
	} 
	else if( fmdms == 0 ){
		st_view(vlat, ., lat, touse)
		st_view(vlon, ., lon, touse)
	}
	latr = ( pi() / 180 ) * vlat; 
	lonr = ( pi() / 180 ) * vlon; 
	
	/*Make Variables*/
	st_view(my, ., mY, touse)
	cN = rows(vlon)
	cK = cols(my)
	mD = J(cN, cN, 0)
	printf("{txt}Size of spatial weight matrix:{res} %1.0f * %1.0f\n", cN, cN)
	
	/*Store Variable Names*/
	sVarName = J(cK, 1, "")
	for( i = 1; i <= cK; ++i ){
		sVarName[i] = st_local("_name_var" + sprintf("%f", i))
	}

	/*Import Weight Variable*/
	if( sweight == 1 ){
		st_view(vZ, ., wvar, touse)
	}
	
	/*Calculate Distance Matrix using Vincenty (1975) */
	if( appdist == 0 ){
		/*Vincenty Formula*/
		/*With Iteration Progress*/
		calcdist(cN, latr, lonr, unit, &mW)
	} 
	else if( appdist == 1 ){
		/*Simplified Version of Vincenty Formula*/
		/*Without Iteration Progress*/
		calcdist_appdist(cN, latr, lonr, unit, &mW)
	}

	/*Convert Diagonal Elements of SWM to Missing Values*/
	_diag(mW, .)
	
	/*Summary Statistics of Distance Matrix*/
	mD_L = lowertriangle(mW)
	vD = select(vech(mD_L), vech(mD_L):>0)
	cN_vD = rows(vD)
	dist_mean = mean(vD)
	dist_sd = sqrt(variance(vD))
	dist_min = min(vD)
	dist_max = max(vD)
	vD = .
	if( matsave == 0 ){
		mD_L = .
	}
	numErrorSwm = 0
	numErrorSwmNoNeighbor = 0
	numErrorSwmMissing = 0

	/*Spatial Weight Matrix*/
	/*Binary SWM*/
	if( swmtype == "bin" ){
		if( sweight == 0 ){
			mW = ( mW :< dist )
		}
		else if( sweight == 1 ){
			mW = ( mW :< dist ) :* (vZ')
		}
		/*ERROR CHECK*/
		numErrorSwm = colsum( rowsum(mW :== 0) :== cN - 1 )
		/*Diagonal Element 0*/
		_diag(mW, 0)
		if( rowstd == 1 ){
			mW = mW :/ rowsum(mW)
		} 
		/*ERROR CHECK*/
		if( numErrorSwm > 0 ){
			if( numErrorSwm == 1 ){
				printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
			if( numErrorSwm > 1 ){
				printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
		}
	} 
	/*K-Nearest Neighbor SWM*/
	else if( swmtype == "knn" ){
		/*Obtain Threshold Distance for KNN*/
		mWSorted = J(cN, cN, 0)
		for ( i = 1; i <= cN; ++i ) {
			mWSorted[., i] = sort(mW[i, .]', 1)
		}
		vDSorted = mWSorted[dd, .]'
		mWSorted = .
		if( sweight == 0 ){
			mW = ( mW :<= vDSorted )
		}
		else if( sweight == 1 ){
			mW = ( mW :<= vDSorted ) :* (vZ')
		}
		/*ERROR CHECK*/
		numErrorSwm = colsum( rowsum(mW :!= 0) :> dd )
		/*Diagonal Element 0*/
		_diag(mW, 0)
		if( rowstd == 1 ){
			mW = mW :/ rowsum(mW)
		}
		/*ERROR CHECK*/
		if( numErrorSwm > 0 ){
			if( numErrorSwm == 1 ){
				printf("{txt}Warning: %1.0f observation has multiple k-nearest neighbors.\n", numErrorSwm)
			}
			if( numErrorSwm > 1 ){
				printf("{txt}Warning: %1.0f observations have multiple k-nearest neighbors.\n", numErrorSwm)
			}
		}		
	} 
	/*Exponential SWM*/
	else if( swmtype == "exp" ){
		if( sweight == 0 ){
			mW = ( mW :< dist ) :* exp( - dd :* mW ) 
		}
		else if( sweight == 1 ){
			mW = ( mW :< dist ) :* exp( - dd :* mW ) :* (vZ') 
		}
		/*ERROR CHECK*/
		numErrorSwm = colsum( rowsum(mW :== 0) :== cN - 1 )
		/*Diagonal Element 0*/
		_diag(mW, 0)
		if( rowstd == 1 ){
			mW = mW :/ rowsum(mW)
		} 
		/*ERROR CHECK*/
		if( numErrorSwm > 0 ){
			if( numErrorSwm == 1 ){
				printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
			if( numErrorSwm > 1 ){
				printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
		}
	} 
	/*Power SWM*/
	else if( swmtype == "pow" ){
		if( sweight == 0 ){
			mW = ( mW :< dist ) :* mW :^(-dd)
		}
		else if( sweight == 1 ){
			mW = ( mW :< dist ) :* mW :^(-dd) :* (vZ')
		}
		/*ERROR CHECK*/
		numErrorSwmNoNeighbor = colsum( rowsum(mW :== 0) :== cN - 1)
		numErrorSwmMissing = colsum( rowsum(mW :== .) :> 1 :| rowsum(mW :== 0) :== cN - 1 )
		/*Diagonal Element 0*/
		_diag(mW, 0)
		if( rowstd == 1 ){
			mW = mW :/ rowsum(mW)
		}
		/*ERROR CHECK*/
		if( numErrorSwmNoNeighbor > 0 ){
			if( numErrorSwmNoNeighbor == 1 ){
				printf("{txt}Warning: %1.0f observation has no neighbor. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			if( numErrorSwmNoNeighbor > 1 ){
				printf("{txt}Warning: %1.0f observations have no neighbor. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
		}
		/*ERROR CHECK*/
		if( numErrorSwmMissing > 0 ){
			if( numErrorSwmMissing == 1 ){
				printf("{txt}Warning: %1.0f observation has missing value.\n", numErrorSwmMissing)
			}
			if( numErrorSwmMissing > 1 ){
				printf("{txt}Warning: %1.0f observations have missing values.\n", numErrorSwmMissing)
			}
		}
	}
	
	/*Order of Spatial Lag*/
	mW_O = I(cN)
	for(i = 1; i <= order; ++i){
		mW_O = mW * mW_O
	}
	mW = .
	
	/*Spatial Lag*/
	mWY = mW_O * my
	if( matsave == 0 ){
		mW_O = .
	}
	
	/*Display Additional Summary Statistics of Distances*/
	if( dispdetail == 1 ){
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
		printf("{txt}{hline 13}{c TT}{hline 62} \n")
		printf("{txt}{space 12} {c |}        Obs.        Mean        S.D.        Min.         Max\n")
		printf("{txt}{hline 13}{c +}{hline 62} \n")
		printf("{txt}{space 4}Distance {c |}{res}  %10.0f  %10.3f  %10.3f  %10.3f  %10.3f\n", 
					cN_vD, dist_mean, dist_sd, dist_min, dist_max )	
		printf("{txt}{hline 13}{c BT}{hline 62} \n")
		if( unit == "km" ){
			printf("{txt}Distance threshold (unit: km):{res} %1.0f\n", dist)
		}
		else if( unit == "mi" ){
			printf("{txt}Distance threshold (unit: mi):{res} %1.0f\n", dist)
		}
		printf("{txt}{hline 76}\n")
	}
	
	/*Return Results in Mata to Stata*/
	if( sweight == 1 ){
		for(i = 1; i <= cK; ++i){
			st_store(., st_addvar("float", "splag"+strofreal(order)+"_"+sVarName[i]+"_"+substr(swmtype,1,1)+"_"+wvar+varsuffix), st_local("touse"), mWY[,i])
		}
	}
	else if( sweight == 0 ){
		for(i = 1; i <= cK; ++i){
			st_store(., st_addvar("float", "splag"+strofreal(order)+"_"+sVarName[i]+"_"+substr(swmtype,1,1)+varsuffix), st_local("touse"), mWY[,i])
		}
	}

	/*rreturn command in Stata*/
	st_rclear()
	st_numscalar("r(dist_max)", dist_max)
	st_numscalar("r(dist_min)", dist_min)
	st_numscalar("r(dist_sd)", dist_sd)
	st_numscalar("r(dist_mean)", dist_mean)
	st_numscalar("r(od)", order)
	st_numscalar("r(dd)", dd)
	st_numscalar("r(td)", dist)
	st_numscalar("r(K)", cK)
	st_numscalar("r(N)", cN)
	st_matrix("r(W)", mW_O)
	st_matrix("r(D)", mD_L)
	st_global("r(rowif)", ".")
	if( sweight == 1 ){
		st_global("r(weight)", wvar)
	} 
	else if( sweight == 0 ){
		st_global("r(weight)", ".")
	}
	if( appdist == 1 ){
		st_global("r(dist_type)", "approximation")
	}
	else if( appdist == 0 ){
		st_global("r(dist_type)", "exact")
	}
	if( unit == "km" ){ 
		st_global("r(dunit)", "km")
	}
	else if( unit == "mi" ){
		st_global("r(dunit)", "mi")
	}
	if( rowstd == 1 ){
		st_global("r(swm_std)", "row-standardized")
	}
	else if( rowstd == 0 ){
		st_global("r(swm_std)", "not row-standardized")
	}
	if( swmtype == "bin" ){
		st_global("r(swm)", "binary")
	} 
	else if( swmtype == "knn" ){
		st_global("r(swm)", "k-nearest neighbor")
	}
	else if( swmtype == "exp" ){
		st_global("r(swm)", "exponential")
	}
	else if( swmtype == "pow" ){
		st_global("r(swm)", "power")
	}
	st_global("r(varlist)", mY)
	st_global("r(cmd)", "spgen")
}
end

/*Calculation of Spatially Lagged Variable*/
/*For Large-Sized Data*/
version 11
mata:
void calcsplag_large(mY, lat, lon, fmdms, swmtype, dist, unit, dd, order, wvar, sweight, varsuffix, matsave, rowstd, appdist, dispdetail, touse)
{
	/*Check format of latitude and longitude*/
	if( fmdms == 1 ){
		printf("{txt}Converting DMS format to decimal format...\n")
		convlonlat2decimal(lat, lon, touse, &vlat, &vlon)
	} 
	else if( fmdms == 0 ){
		st_view(vlat, ., lat, touse)
		st_view(vlon, ., lon, touse)
	}
	latr = ( pi() / 180 ) * vlat; 
	lonr = ( pi() / 180 ) * vlon; 
	
	/*Make Variable*/
	st_view(my, ., mY, touse)
	cN = rows(vlon)
	cK = cols(my)
	printf("{txt}Size of spatial weight matrix:{res} %1.0f * %1.0f\n", cN, cN)
	
	/*Store Variable Names*/
	sVarName = J(cK, 1, "")
	for( i = 1; i <= cK; ++i ){
		sVarName[i] = st_local("_name_var" + sprintf("%f", i))
	}

	/*Import Weight Variable*/
	if( sweight == 1 ){
		st_view(vZ, ., wvar, touse)
	}
	
	/*Spatial Lagged Variables*/
	printf("{txt}Calculating spatial lagged variable...\n")
	cN_vD = .
	dist_mean = .
	dist_sd = .
	dist_min = .
	dist_max = 0
	mD_L = .
	vDist = J(1, cN, 0)
	vW = J(1, cN, 0)
	mWY = J(cN, cK, 0)
	numErrorSwm = 0
	numErrorSwmNoNeighbor = 0
	numErrorSwmMissing = 0
	
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
	
	/*Distance Matrix*/
	for( i = 1; i <= cN; ++i ){
	
		/*Display Iteration Progress*/
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
		
		/*Binary SWM*/
		if( swmtype == "bin" ){
			if( sweight == 0 ){
				vW = ( vDist :< dist )
			}
			else if( sweight == 1 ){
				vW = ( ( vDist :< dist ) :* (vZ') )
			}
			/*ERROR CHECK*/
			numErrorSwm = numErrorSwm + ( rowsum(vW :== 0) == cN - 1 )
			/*Diagonal Element*/
			vW[i] = 0 
			if(rowstd == 1){
				vW = vW :/ rowsum(vW)
			}
		}
		/*K-Nearest Neighbor SWM*/
		else if( swmtype == "knn" ){
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
			numErrorSwm = numErrorSwm + ( rowsum(vW :!= 0) > dd )
			/*Diagonal Element*/
			vW[i] = 0 
			if(rowstd == 1){
				vW = vW :/ rowsum(vW)
			}
		}
		/*Exponential SWM*/
		else if( swmtype == "exp" ){
			if( sweight == 0 ){
				vW = ( vDist :< dist ) :* exp( - dd :* vDist )
			}
			else if( sweight == 1 ){
				vW = ( vDist :< dist ) :* exp( - dd :* vDist ) :* (vZ') 
			}
			/*ERROR CHECK*/
			numErrorSwm = numErrorSwm + ( rowsum(vW :== 0) == cN - 1 )
			/*Diagonal Element*/
			vW[i] = 0 
			if(rowstd == 1){
				vW = vW :/ rowsum(vW)
			}
		}
		/*Power SWM*/
		else if( swmtype == "pow" ){
			if( sweight == 0 ){
				vW = ( vDist :< dist ) :* vDist :^(-dd)
			}
			else if( sweight == 1 ){
				vW = ( vDist :< dist ) :* vDist :^(-dd) :* (vZ')
			}
			/*ERROR CHECK*/
			numErrorSwmNoNeighbor = numErrorSwmNoNeighbor + ( rowsum(vW :== 0) == cN - 1 )
			/*ERROR CHECK*/
			numErrorSwmMissing = numErrorSwmMissing + ( rowsum(vW :== .) > 1 | rowsum(vW :== 0) == cN - 1 )
			/*Diagonal Element*/
			vW[i] = 0 
			if(rowstd == 1){
				vW = vW :/ rowsum(vW)
			}
		}
		
		/*Spatial Lagged Variable*/
		mWY[i,] = vW * my
		
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
		if( numErrorSwm > 0 ){
			if( numErrorSwm == 1 ){
				printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
			if( numErrorSwm > 1 ){
				printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
		}
	}
	else if( swmtype == "knn" ){
		if( numErrorSwm > 0 ){
			if( numErrorSwm == 1 ){
				printf("{txt}Warning: %1.0f observation has multiple k-nearest neighbors.\n", numErrorSwm)
			}
			if( numErrorSwm > 1 ){
				printf("{txt}Warning: %1.0f observations have multiple k-nearest neighbors.\n", numErrorSwm)
			}
		}
	}
	else if( swmtype == "exp" ){
		if( numErrorSwm > 0 ){
			if( numErrorSwm == 1 ){
				printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
			if( numErrorSwm > 1 ){
				printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
		}
	}
	else if( swmtype == "pow" ){
		if( numErrorSwmNoNeighbor > 0 ){
			if( numErrorSwmNoNeighbor == 1 ){
				printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			if( numErrorSwmNoNeighbor > 1 ){
				printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
		}
		if( numErrorSwmMissing > 0 ){
			if( numErrorSwmMissing == 1 ){
				printf("{txt}Warning: %1.0f observation has missing value.\n", numErrorSwmMissing)
			}
			if( numErrorSwmMissing > 1 ){
				printf("{txt}Warning: %1.0f observations have missing values.\n", numErrorSwmMissing)
			}
		}
	}
	
	/*Display Additional Summary Statistics of Distances*/
	if( dispdetail == 1 ){
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
		printf("{txt}{hline 13}{c TT}{hline 62} \n")
		printf("{txt}{space 12} {c |}        Obs.        Mean        S.D.        Min.         Max\n")
		printf("{txt}{hline 13}{c +}{hline 62} \n")
		printf("{txt}{space 4}Distance {c |}{res}  %10.0f  %10.3f  %10.3f  %10.3f  %10.3f\n", 
					cN_vD, dist_mean, dist_sd, dist_min, dist_max )	
		printf("{txt}{hline 13}{c BT}{hline 62} \n")
		if( unit == "km" ){
			printf("{txt}Distance threshold (unit: km):{res} %1.0f\n", dist)
		}
		else if( unit == "mi" ){
			printf("{txt}Distance threshold (unit: mi):{res} %1.0f\n", dist)
		}
		printf("{txt}{hline 76}\n")
		printf("{txt}NOTE: largesize option displays only minimum and maximum distances.\n")
	}
	
	/*Return Results in Mata to Stata*/
	if( sweight == 1 ){
		for( i = 1; i <= cK; ++i ){
			st_store(., st_addvar("float", "splag"+strofreal(order)+"_"+sVarName[i]+"_"+substr(swmtype,1,1)+"_"+wvar+varsuffix), st_local("touse"), mWY[,i])
		}
	}
	else if( sweight == 0 ){
		for( i = 1; i <= cK; ++i ){
			st_store(., st_addvar("float", "splag"+strofreal(order)+"_"+sVarName[i]+"_"+substr(swmtype,1,1)+varsuffix), st_local("touse"), mWY[,i])
		}
	}

	/*rreturn command in Stata*/
	st_rclear()
	st_numscalar("r(dist_max)", dist_max)
	st_numscalar("r(dist_min)", dist_min)
	st_numscalar("r(dist_sd)", dist_sd)
	st_numscalar("r(dist_mean)", dist_mean)
	st_numscalar("r(od)", order)
	st_numscalar("r(dd)", dd)
	st_numscalar("r(td)", dist)
	st_numscalar("r(K)", cK)
	st_numscalar("r(N)", cN)
	st_matrix("r(W)", .)
	st_matrix("r(D)", mD_L)
	st_global("r(rowif)", ".")
	if( sweight == 1 ){
		st_global("r(weight)", wvar)
	} 
	else if( sweight == 0 ){
		st_global("r(weight)", ".")
	}
	if( appdist == 1 ){
		st_global("r(dist_type)", "approximation")
	}
	else if( appdist == 0 ){
		st_global("r(dist_type)", "exact")
	}
	if( unit == "km" ){ 
		st_global("r(dunit)", "km")
	}
	else if( unit == "mi" ){
		st_global("r(dunit)", "mi")
	}
	if( rowstd == 1 ){
		st_global("r(swm_std)", "row-standardized")
	}
	else if( rowstd == 0 ){
		st_global("r(swm_std)", "no row-standardized")
	}
	if( swmtype == "bin" ){
		st_global("r(swm)", "binary")
	} 
	else if( swmtype == "knn" ){
		st_global("r(swm)", "k-nearest neighbor")
	}
	else if( swmtype == "exp" ){
		st_global("r(swm)", "exponential")
	}
	else if( swmtype == "pow" ){
		st_global("r(swm)", "power")
	}
	st_global("r(varlist)", mY)
	st_global("r(cmd)", "spgen")
}
end

/*Calculation of Spatially Lagged Variable*/
/*For ROWIF option*/
version 11
mata:
void calcsplag_rowif(mY, lat, lon, fmdms, swmtype, dist, unit, dd, order, wvar, sweight, varsuffix, rowif, val_rowif, matsave, rowstd, appdist, dispdetail, large, touse)
{
	/*Check format of latitude and longitude*/
	if( fmdms == 1 ){
		printf("{txt}Converting DMS format to decimal format...\n")
		convlonlat2decimal(lat, lon, touse, &vlat, &vlon)
	} 
	else if( fmdms == 0 ){
		st_view(vlat, ., lat, touse)
		st_view(vlon, ., lon, touse)
	}
	latr = ( pi() / 180 ) * vlat; 
	lonr = ( pi() / 180 ) * vlon; 
	
	/*Make Variables*/
	st_view(my, ., mY, touse)
	st_view(vRowif, ., rowif, touse)
	vRowif = (vRowif :== val_rowif)
	cN = rows(vlon)
	cN_rowif = colsum(vRowif)
	cK = cols(my)
	printf("{txt}Size of spatial weight matrix:{res} %1.0f * %1.0f\n", cN_rowif, cN)

	/*Store Variable Names*/
	sVarName = J(cK, 1, "")
	for( i = 1; i <= cK; ++i ){
		sVarName[i] = st_local("_name_var" + sprintf("%f", i))
	}

	/*Import Weight Variable*/
	if( sweight == 1 ){
		st_view(vZ, ., wvar, touse)
	}
	
	/*Spatial Lagged Variables*/
	printf("{txt}Calculating spatial lagged variable...\n")
	cN_vD = .
	dist_mean = .
	dist_sd = .
	dist_min = .
	dist_max = 0
	mD_L = .
	vDist = J(1, cN, 0)
	vW = J(1, cN, 0)
	mWY = J(cN, cK, 0)
	if( matsave == 1 ){
		mDist = J(cN_rowif, cN, 0)
		mW = J(cN_rowif, cN, 0)
	}
	
	/*Variables for Vincenty's Formula*/
	a = 6378.137
	b = 6356.752314245
	f = (a-b)/a
	eps = 1e-12
	maxIt = 1e+5
	numErrorSwm = 0
	numErrorSwmNoNeighbor = 0
	numErrorSwmMissing = 0
	itr = 0

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

	/*Make Distance Matrix using Vincenty (1975) */
	for( i = 1; i <= cN; ++i ){
	
		/*Display Iteration Progress*/
		if( i == 1 ){
			printf("{txt}{c TT}{hline 15}{c TT}\n")
		}

		if( vRowif[i] == 1 ){
			++itr
			/*Simplified Version of Vincenty Formula*/
			if( appdist == 1 ){
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
			}
			/*Vincenty Formula*/
			else if( appdist == 0 ){
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
			}
			
			/*Convert distance between i and i to missing value*/
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
				numErrorSwm = numErrorSwm + ( rowsum(vW :== 0) == cN - 1 )
				/*Diagonal Element*/
				vW[i] = 0 
				if(rowstd == 1){
					vW = vW :/ rowsum(vW)
				}
			}
			/*K-Nearest Neighbor SWM*/
			else if( swmtype == "knn" ){
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
				numErrorSwm = numErrorSwm + ( rowsum(vW :!= 0) > dd )
				/*Diagonal Element*/
				vW[i] = 0 
				if(rowstd == 1){
					vW = vW :/ rowsum(vW)
				}
			}
			/*Exponential SWM*/
			else if( swmtype == "exp" ){
				if( sweight == 0 ){
					vW = ( vDist :< dist ) :* exp( - dd :* vDist )
				}
				else if( sweight == 1 ){
					vW = ( vDist :< dist ) :* exp( - dd :* vDist ) :* (vZ') 
				}
				/*ERROR CHECK*/
				numErrorSwm = numErrorSwm + ( rowsum(vW :== 0) == cN - 1 )
				/*Diagonal Element*/
				vW[i] = 0 
				if(rowstd == 1){
					vW = vW :/ rowsum(vW)
				}
			}
			/*Power SWM*/
			else if( swmtype == "pow" ){
				if( sweight == 0 ){
					vW = ( vDist :< dist ) :* vDist :^(-dd)
				}
				else if( sweight == 1 ){
					vW = ( vDist :< dist ) :* vDist :^(-dd) :* (vZ')
				}
				/*ERROR CHECK*/
				numErrorSwmNoNeighbor = numErrorSwmNoNeighbor + ( rowsum(vW :== 0) == cN - 1 )
				/*ERROR CHECK*/
				numErrorSwmMissing = numErrorSwmMissing + ( rowsum(vW :== .) > 1 | rowsum(vW :== 0) == cN - 1 )
				/*Diagonal Element*/
				vW[i] = 0 
				if(rowstd == 1){
					vW = vW :/ rowsum(vW)
				}
			}
			
			/*Spatial Lagged Variable*/
			mWY[i,] = vW * my
			
			/*Store Distance Matrix*/
			if( matsave == 1 ){
				mDist[itr,] = vDist
				mW[itr,] = vW
			}
		}
		else if( vRowif[i] == 0 ){
			/*Spatial Lagged Variable*/
			mWY[i,] = J(1, cK, .)
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
		if( numErrorSwm > 0 ){
			if( numErrorSwm == 1 ){
				printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
			if( numErrorSwm > 1 ){
				printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
		}
	}
	else if( swmtype == "knn" ){
		if( numErrorSwm > 0 ){
			if( numErrorSwm == 1 ){
				printf("{txt}Warning: %1.0f observation has multiple k-nearest neighbors.\n", numErrorSwm)
			}
			if( numErrorSwm > 1 ){
				printf("{txt}Warning: %1.0f observations have multiple k-nearest neighbors.\n", numErrorSwm)
			}
		}
	}
	else if( swmtype == "exp" ){
		if( numErrorSwm > 0 ){
			if( numErrorSwm == 1 ){
				printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
			if( numErrorSwm > 1 ){
				printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
		}
	}
	else if( swmtype == "pow" ){
		if( numErrorSwmNoNeighbor > 0 ){
			if( numErrorSwmNoNeighbor == 1 ){
				printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			if( numErrorSwmNoNeighbor > 1 ){
				printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
		}
		if( numErrorSwmMissing > 0 ){
			if( numErrorSwmMissing == 1 ){
				printf("{txt}Warning: %1.0f observation has missing value.\n", numErrorSwmMissing)
			}
			if( numErrorSwmMissing > 1 ){
				printf("{txt}Warning: %1.0f observations have missing values.\n", numErrorSwmMissing)
			}
		}
	}
		
	/*Store in r()*/
	if( matsave == 1 ){
		mD = mDist
		vD = select(vec(mD), vec(mD):>0)
		cN_vD = rows(vD)
		dist_mean = mean(vD)
		dist_sd = sqrt(variance(vD))
		vD = .
	}
	else if( matsave == 0 ){
		mD = .
		mW = .
	}
	
	/*Display Additional Summary Statistics of Distances*/
	if( dispdetail == 1 ){
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
		printf("{txt}{hline 13}{c TT}{hline 62} \n")
		printf("{txt}{space 12} {c |}        Obs.        Mean        S.D.        Min.         Max\n")
		printf("{txt}{hline 13}{c +}{hline 62} \n")
		printf("{txt}{space 4}Distance {c |}{res}  %10.0f  %10.3f  %10.3f  %10.3f  %10.3f\n", 
					cN_vD, dist_mean, dist_sd, dist_min, dist_max )	
		printf("{txt}{hline 13}{c BT}{hline 62} \n")
		if( unit == "km" ){
			printf("{txt}Distance threshold (unit: km):{res} %1.0f\n", dist)
		}
		else if( unit == "mi" ){
			printf("{txt}Distance threshold (unit: mi):{res} %1.0f\n", dist)
		}
		printf("{txt}{hline 76}\n")
		printf("{txt}NOTE: rowif() option returns the matrix %1.0f * %1.0f.\n", cN_rowif, cN)
		if( large == 1 ){
			printf("{txt}NOTE: largesize option displays only minimum and maximum distances.\n")
		}
	}
	
	/*Return Resutls in Mata to Stata*/
	if( sweight == 1 ){
		for(i = 1; i <= cK; ++i){
			st_store(., st_addvar("float", "splag"+strofreal(order)+"_"+sVarName[i]+"_"+substr(swmtype,1,1)+"_"+wvar+varsuffix), st_local("touse"), mWY[,i])
		}
	}
	else if( sweight == 0 ){
		for(i = 1; i <= cK; ++i){
			st_store(., st_addvar("float", "splag"+strofreal(order)+"_"+sVarName[i]+"_"+substr(swmtype,1,1)+varsuffix), st_local("touse"), mWY[,i])
		}
	}

	/*rreturn command in Stata*/
	st_rclear()
	st_numscalar("r(dist_max)", dist_max)
	st_numscalar("r(dist_min)", dist_min)
	st_numscalar("r(dist_sd)", dist_sd)
	st_numscalar("r(dist_mean)", dist_mean)
	st_numscalar("r(od)", order)
	st_numscalar("r(dd)", dd)
	st_numscalar("r(td)", dist)
	st_numscalar("r(K)", cK)
	st_numscalar("r(N)", cN)
	st_matrix("r(W)", mW)
	st_matrix("r(D)", mD)
	st_global("r(rowif)", rowif)
	if( sweight == 1 ){
		st_global("r(weight)", wvar)
	} 
	else if( sweight == 0 ){
		st_global("r(weight)", "")
	}
	if( appdist == 1 ){
		st_global("r(dist_type)", "approximation")
	}
	else if( appdist == 0 ){
		st_global("r(dist_type)", "exact")
	}
	if( rowstd == 1 ){
		st_global("r(swm_std)", "row-standardized")
	}
	else if( rowstd == 0 ){
		st_global("r(swm_std)", "no row-standardized")
	}
	if( unit == "km" ){ 
		st_global("r(dunit)", "km")
	}
	else if( unit == "mi" ){
		st_global("r(dunit)", "mi")
	}
	if( swmtype == "bin" ){
		st_global("r(swm)", "binary")
	} 
	else if( swmtype == "knn" ){
		st_global("r(swm)", "k-nearest neighbor")
	}
	else if( swmtype == "exp" ){
		st_global("r(swm)", "exponential")
	}
	else if( swmtype == "pow" ){
		st_global("r(swm)", "power")
	}
	st_global("r(varlist)", mY)
	st_global("r(cmd)", "spgen")
}
end

/*Convert DMS format to Decimal Format*/
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

/*Distance Matrix from Vincenty's Formula*/
version 11
mata:
void calcdist(cN, latr, lonr, unit, mW)
{
	/*Variables*/
	mDist = J(cN, cN, 0)
	a = 6378.137
	b = 6356.752314245
	f = (a-b)/a
	eps = 1e-12
	maxIt = 1e+5
	
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
	
	/*Make Distance Matrix using Vincenty (1975) */
	for( i = 1; i <= cN; ++i ){
	
		/*Display Iteration Progress*/
		if( i == 1 ){
			printf("{txt}Calculating bilateral distance...\n")
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
		/*Convert distance between i and i to missing value*/
		vDist[i] = .
		/*Store Distance*/
		mDist[i,] = vDist
		
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

	/*Convert Unit of Distance*/
	if( unit == "mi" ){
		mDist = 0.621371 :* mDist
	}

	/*Return Distance Matrix*/
	(*mW) = mDist
}
end

/*Distance Matrix from Vincenty's Formula*/
/*Simplified Version for Large-Sized Matrix*/
version 11
mata:
void calcdist_appdist(cN, latr, lonr, unit, mW)
{
	/*Variables*/
	vDist = J(1, cN, 0)
	mDist = J(cN, cN, 0)

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
	
	/*Make Distance Matrix using Vincenty (1975) */
	for( i = 1; i <= cN; ++i ){
	
		/*Display Iteration Progress*/
		if( i == 1 ){
			printf("{txt}Calculating bilateral distance...\n")
			printf("{txt}{c TT}{hline 15}{c TT}\n")
		}
				
		/*Bilateral Distance*/
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
		vDist[i] = .
		mDist[i,] = vDist
		
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

	/*Convert Unit of Distance*/
	if( unit == "mi" ){
		mDist = 0.621371 :* mDist
	}

	/*Return Distance Matrix*/
	(*mW) = mDist
}
end
