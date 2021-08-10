*! version 1.0.1  05may2010 Robert Picard, picard@netbox.com
program define geodist, rclass

	version 9

	syntax anything [in] [if], ///
		[ ///
		Generate(name) ///
		MIles ///
		Radius(string) ///
		Sphere ///
		Ellipsoid(string) ///
		Maxiter(integer 25) ///
		]
	
	
	if ("`sphere'" != "" | "`radius'" != "") & "`ellipsoid'" != "" {
		dis as err "You must choose either a sphere or ellipsoid model"
		exit 198
	}
	
	// each lat1 lon1 lat2 lon2 is either variable, scalar, or a number (as string)
	// coordinates are expected in signed decimal degrees, east and north positive
	tokenize `anything'
	if "`5'" != "" {
		dis as err "unexpected extra text: `5'"
		exit 198
	}
	if "`4'" == "" {
		dis as err "You must provide lat1 lon1 lat2 lon2"
		exit 198
	}
	local hasvar 0
	local j 0
	forvalues i = 1/2 {
		foreach l in lat lon {
			local ++j
			local `l'`i' ``j''
			cap confirm number ``l'`i''
			local isnum = _rc == 0
			cap confirm scalar ``l'`i''
			if !_rc | `isnum' {
				if "`l'" == "lat" & abs(``j'') > 90 {
					dis as err "latitude `i' must be between -90 and 90"
					exit 198
				}
				if "`l'" == "lon" & abs(``j'') > 180 {
					dis as err "longitude `i' must be between -180 and 180"
					exit 198
				}
			}
			else {
				cap confirm numeric var ``j''
				if !_rc {
					local hasvar 1
					sum ``j'' `if' `in', meanonly
					if "`l'" == "lat" & (r(max) > 90 | r(min) < -90) {
						dis as err "latitude `i' must be between -90 and 90"
						exit 198
					}
					if "`l'" == "lon" & (r(max) > 180 | r(min) < -180) {
						dis as err "longitude `i' must be between -180 and 180"
						exit 198
					}
				}
				else {
					dis as err "Was expecting a variable, scalar, or number " ///
						"instead of ``j''"
					exit 198
				}
			}
		}
	}
	
	if !`hasvar' {
		if "`if'`in'" != "" {
			dis as err "lat/lon are not variables, if or in option not allowed"
			exit 198
		}
		if "`generate'" != "" {
			dis as err "lat/lon are not variables, nothing to generate"
			exit 198
		}
	}
	else {
		if "`generate'" == "" {
			dis as err "you must specify gen(newvar) option"
			exit 198
		}
		capture confirm new var `generate'
		if _rc {
			dis as err "cannot create variable specified in gen() option"
			exit _rc
		}
	}

	if "`miles'" != "" {
		local km_to_miles / 1.609344
		local units miles
	}
	else local units km

	tempname d2r
	scalar `d2r' = c(pi) / 180
	
	if "`sphere'" != "" | "`radius'" != "" {
	
		// default to mean earth radius
		// see http://en.wikipedia.org/wiki/Earth_radius#Mean_radii
		if "`radius'" == "" local radius 6371
		
		// double precision sin becomes flat for angles within 1.0536e-08 of pi/2
		// double precision cos becomes flat for angles <= 1.0536e-08 radians
		// this represents an earth distance of 67mm (1.0536e-08 * 6371000000)
		
		if `hasvar' {
		
			tempvar touse
			qui gen `touse' = 1 `if' `in'
			qui replace `touse' = 0 if mi(`lat1',`lon1',`lat2',`lon2')
			qui replace `touse' = 0 if `touse' == .		

			// by default, use haversine formula
			// http://www.movable-type.co.uk/scripts/gis-faq-5.1.html
			// becomes flat within 2 * 67mm of antipod, i.e. max error = 134mm
			qui gen double `generate' =  2 * asin(min(1,sqrt( ///
				sin((`lat2' - `lat1') * `d2r' / 2)^2 + ///
				cos(`lat1' * `d2r') * cos(`lat2' * `d2r') * ///
				sin((`lon2' - `lon1') * `d2r' / 2)^2))) ///
				* `radius' `km_to_miles' if `touse'
				
			// switch to law of cosines formula for near-antipodal points
			// becomes flat for points within 67mm of each other on the equator,
			// i.e. max error = 67mm
			qui replace `generate' = acos(min(1, ///
				sin(`lat1' * `d2r') * sin(`lat2' * `d2r') + ///
				cos(`lat1' * `d2r') * cos(`lat2' * `d2r') * ///
				cos(`lon2' * `d2r' - `lon1' * `d2r'))) ///
				* `radius' `km_to_miles' if `touse' & ///
				`generate' > `radius' * c(pi) - 10
				
		}
		else {
			local formula "haversine"
			tempname generate
			scalar `generate' = 2 * asin(min(1,sqrt( ///
				sin((`lat2' - `lat1') * `d2r' / 2)^2 + ///
				cos(`lat1' * `d2r') * cos(`lat2' * `d2r') * ///
				sin((`lon2' - `lon1') * `d2r' / 2)^2))) ///
				* `radius' `km_to_miles'
			if `generate' > `radius' * c(pi) - 10 {
				scalar `generate' = acos(min(1, ///
				sin(`lat1' * `d2r') * sin(`lat2' * `d2r') + ///
				cos(`lat1' * `d2r') * cos(`lat2' * `d2r') * ///
				cos(`lon2' * `d2r' - `lon1' * `d2r'))) ///
				* `radius' `km_to_miles'
				local formula "law of cosines"
			}
			dis as txt "Great-circle distance " ///
				"(`formula' formula, radius of `radius'km) = " ///
				as res `generate' " `units'"
			return scalar distance = `generate'
		}
		
	}
	else {
	
		// allow for any reference ellipsoid by allowing user-specified parameters
		tempname a b f
		if "`ellipsoid'" != "" {
			tokenize "`ellipsoid'", parse(" ,")
			capture confirm number `1'
			local rc = _rc
			if "`2'" == "," local 2 `3'
			capture confirm number `2'
			if _rc | `rc' {
				dis as err "the reference ellipsoid parameters (a,f^-1) are not numbers"
				dis as err "a = semi-major axis, in meters"
				dis as err "f^-1 = reciprocal of flattening ratio"
				dis as err "e.g. ellipsoid(6378249.145, 293.465) for Clarke 1880"
				exit 198
			}
			scalar `a' = `1'
			scalar `f' = 1 / `2'
		}
		else { 
			// Use WGS 1984 ellipsoid
			// source: http://earth-info.nga.mil/GandG/publications/tr8350.2/wgs84fin.pdf
			// Section 3.2
			scalar `a' = 6378137 // semi-major axis
			scalar `f' = 1 / 298.257223563 // Flattening
			local ename "WGS 1984"
		}
		scalar `b' = `a' - `a' * `f'
		
	
		if `hasvar' {
		
			// at least one lat/lon is a variable; others can be scalar or number
			tempvar touse
			qui gen `touse' = 1 `if' `in'
			qui replace `touse' = 0 if mi(`lat1',`lon1',`lat2',`lon2')
			qui replace `touse' = 0 if `touse' == .			

			// implement Vincenty's (1975) inverse solution
			// Source: http://www.ngs.noaa.gov/PUBS_LIB/inverse.pdf
			
			// first approximation, equation 13
			tempvar L lambda
			qui gen double `L' =  `d2r' * (`lon2' - `lon1') if `touse'
			qui gen double `lambda' = `L' if `touse'
			
			// for speed, precompute all sin and cos of U
			tempvar U1 U2 sin_U1 sin_U2 cos_U1 cos_U2
			qui gen double `U1' = atan((1-`f') * tan(`d2r' *`lat1')) if `touse'
			qui gen double `U2' = atan((1-`f') * tan(`d2r' *`lat2')) if `touse'
			qui gen double `sin_U1' = sin(`U1') if `touse'
			qui gen double `sin_U2' = sin(`U2') if `touse'
			qui gen double `cos_U1' = cos(`U1') if `touse'
			qui gen double `cos_U2' = cos(`U2') if `touse'
			drop `U1' `U2'
			
			// Find lambda by iteration; mark out observation when converged
			tempvar cont
			gen `cont' = `touse'
			foreach v in sin_sigma cos_sigma sigma sin_alpha ///
				cos_sq_alpha cos_2sigma_m C lambda_old {
				tempvar `v'
				qui gen double ``v'' = .
			}
			local iter 0
			local more 1
			while `++iter' < `maxiter' & `more' {
				// equation 14
				qui replace `sin_sigma' = sqrt((`cos_U2' * sin(`lambda'))^2 + ///
					(`cos_U1' * `sin_U2' - `sin_U1' * `cos_U2' * cos(`lambda'))^2) ///
					if `cont'
				// mark out co-incident points
				qui replace `cont' = 0 if `sin_sigma' == 0
				// equation 15
				qui replace `cos_sigma' = `sin_U1' * `sin_U2' + `cos_U1' * ///
					`cos_U2' * cos(`lambda') if `cont'
				// equation 16
				qui replace `sigma' = atan2(`sin_sigma',`cos_sigma') if `cont'
				// equation 17
				qui replace `sin_alpha' = `cos_U1' * `cos_U2' * sin(`lambda') / ///
					`sin_sigma' if `cont'
				// use trig identity to obtain cos^2 alpha
				qui replace `cos_sq_alpha' = 1 - `sin_alpha'^2 if `cont'
				// equation 18
				qui replace `cos_2sigma_m' = `cos_sigma' - 2 * `sin_U1' * ///
					`sin_U2' / `cos_sq_alpha' if `cont'
				// adjust if both points are on the equator
				qui replace `cos_2sigma_m' = 0 if `cos_sq_alpha' == 0 & `cont'
				// compute new lambda and compare to previous one
				qui replace `lambda_old' = `lambda' if `cont'
				// equation 10
				qui replace `C' = `f' / 16 * `cos_sq_alpha' * ///
					(4 + `f' * (4 - 3 * `cos_sq_alpha')) if `cont'
				// equation 11
				qui replace `lambda' = `L' + (1 - `C') * `f' * `sin_alpha' * ///
				  (	`sigma' + `C' * `sin_sigma' * (`cos_2sigma_m' + ///
				  `C'*`cos_sigma' * (-1 + 2* `cos_2sigma_m'^2))) if `cont'
				// mark out observations that have converged
				qui replace `cont' = 0 if abs(`lambda'-`lambda_old') <= 1e-12
				// we are done if all observations have converged
				sum `cont', meanonly
				local more = r(max)
			}
			drop `L' `sin_U1' `sin_U2' `cos_U1' `cos_U2' `lambda' `sin_alpha' `C' `lambda_old'
						
			tempvar u_sq A B delta_sigma
			qui gen double `u_sq' = `cos_sq_alpha' * (`a'^2 - `b'^2) / (`b'^2) if `touse'
			// equation 3
			qui gen double `A' = 1 + `u_sq' / 16384 * (4096 + ///
				`u_sq' * (-768 + `u_sq' * (320 - 175 * `u_sq'))) if `touse'
			// equation 4
			qui gen double `B' = `u_sq' / 1024 * (256 + ///
				`u_sq' * (-128 + `u_sq' * (74 - 47 * `u_sq'))) if `touse'
			// equation 6
			qui gen double `delta_sigma' = `B' * `sin_sigma' * (`cos_2sigma_m' + ///
				`B' / 4 * (`cos_sigma' * ///
				(-1 + 2 * `cos_2sigma_m'^2) - ///
				`B' / 6 * `cos_2sigma_m' * (-3 + 4 * `sin_sigma'^2) * ///
				(-3 + 4 * `cos_2sigma_m'^2))) if `touse'
			// equation 19; convert to km and then to miles if requested
			qui gen double `generate' = `b' * `A' * (`sigma' - `delta_sigma') ///
				 / 1000 `km_to_miles' if `touse'
			// co-incident points were marked out of the iteration loop
			qui replace `generate' = 0 if `sin_sigma' == 0 & `touse'
			
			// use an extended missing value to flag observations that failed to converge
			qui replace `generate' = .a if `cont'
			qui count if `generate' == .a
			if r(N) {
				dis as err "Warning: failed to converge due to near-antipodal points"
				dis as err "Replaced distance(s) with missing value .a"
				dis as err "Number of distance(s) affected = " r(N)
			}
			
		}
		else {
		
			// since there are no variables, do as above but with scalars
			tempname L lambda
			scalar `L' =  `d2r' * (`lon2' - `lon1')
			scalar `lambda' = `L'
			
			tempname U1 U2 sin_U1 sin_U2 cos_U1 cos_U2
			scalar `U1' = atan((1-`f') * tan(`d2r' *`lat1'))
			scalar `U2' = atan((1-`f') * tan(`d2r' *`lat2'))
			scalar `sin_U1' = sin(`U1')
			scalar `sin_U2' = sin(`U2')
			scalar `cos_U1' = cos(`U1')
			scalar `cos_U2' = cos(`U2')
			
			foreach v in sin_sigma cos_sigma sigma sin_alpha ///
				cos_sq_alpha cos_2sigma_m C lambda_old {
				tempname `v'
			}
			local iter 0
			local more 1
			while `++iter' < `maxiter' & `more' {
				scalar `sin_sigma' = sqrt((`cos_U2' * sin(`lambda'))^2 + ///
					(`cos_U1' * `sin_U2' - `sin_U1' * `cos_U2' * cos(`lambda'))^2)
				// break out of loop if points are co-incident
				if `sin_sigma' == 0 continue, break
				scalar `cos_sigma' = `sin_U1' * `sin_U2' + `cos_U1' * ///
					`cos_U2' * cos(`lambda')
				scalar `sigma' = atan2(`sin_sigma',`cos_sigma')
				scalar `sin_alpha' = `cos_U1' * `cos_U2' * sin(`lambda') / `sin_sigma'
				scalar `cos_sq_alpha' = 1 - `sin_alpha'^2
				scalar `cos_2sigma_m' = `cos_sigma' - 2 * `sin_U1' * ///
					`sin_U2' / `cos_sq_alpha'
				// adjust if both points are on the equator
				if `cos_sq_alpha' == 0 scalar `cos_2sigma_m' = 0
				scalar `lambda_old' = `lambda'
				scalar `C' = `f' / 16 * `cos_sq_alpha' * ///
					(4 + `f' * (4 - 3 * `cos_sq_alpha'))
				scalar `lambda' = `L' + (1 - `C') * `f' * `sin_alpha' * ///
				  (	`sigma' + `C' * `sin_sigma' * (`cos_2sigma_m' + ///
				  `C'*`cos_sigma' * (-1 + 2* `cos_2sigma_m'^2)))
				local more = abs(`lambda'-`lambda_old') > 1e-12
			}
			
			tempname d
			if `sin_sigma' == 0 scalar `d' = 0
			else {
				tempname u_sq A B delta_sigma d
				scalar `u_sq' = `cos_sq_alpha' * (`a'^2 - `b'^2) / (`b'^2)
				scalar `A' = 1 + `u_sq' / 16384 * (4096 + ///
					`u_sq' * (-768 + `u_sq' * (320 - 175 * `u_sq')))
				scalar `B' = `u_sq' / 1024 * (256 + ///
					`u_sq' * (-128 + `u_sq' * (74 - 47 * `u_sq')))
				scalar `delta_sigma' = `B' * `sin_sigma' * (`cos_2sigma_m' + ///
				`B' / 4 * (`cos_sigma' * ///
				(-1 + 2 * `cos_2sigma_m'^2) - ///
				`B' / 6 * `cos_2sigma_m' * (-3 + 4 * `sin_sigma'^2) * ///
				(-3 + 4 * `cos_2sigma_m'^2)))
				scalar `d' = `b' * `A' * (`sigma' - `delta_sigma') / 1000 `km_to_miles'
			}
	
			if `iter' == `maxiter' {
				scalar `d' = .a
				dis as err "Warning: failed to converge due to near-antipodal points"
			}
			else {
				dis as txt "`ename' ellipsoid(`=`a'',`=1/`f'') distance = " ///
					as res `d' " `units'"
			}
			return scalar distance = `d'
			return scalar iterations = `iter'
			
		}
	}

end
