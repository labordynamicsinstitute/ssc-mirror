*! 3.0 VERSION OF DISTANCEMATRIX
*! 1.0 build version of traveltime3
program traveltime3
	version 12.0 
	syntax, start(string) end(string) [mode(string) units(string) avoid(string)]


	quietly {
	
		*check for insheetjson and libsjson
			cap which insheetjson
			if _rc == 111 noisily dis as text "Insheetjson.ado not found"
			cap which libjson.mlib
			if _rc == 111 noisily dis as text "Libjson.mlib not found"
			if _rc == 111 assert 1==2
		
		*set local according to options
			if "`mode'" == "" | "`mode'" == "driving" local lmode = "`mode'"
			if "`mode'" == "bicycling" local lmode = "`mode'"
			if "`mode'" == "walking" local lmode = "`mode'"
			if "`mode'" != "" & "`mode'" != "driving" & "`mode'" != "bicycling" & "`mode'" != "walking" {
			noi di as text "Error: invalid mode option specified"
			assert 1==2
			}

			if "`units'" == "" | "`units'" == "metric" local lunits = "`units'"
			if "`units'" == "imperial" local lunits = "`units'"
			if "`units'" != "" & "`units'" != "metric" & "`units'" != "imperial"  {
			noi di as text "Error: invalid units option specified"
			assert 1==2
			}
			
			if "`avoid'" == "" local lavoid = ""
			if "`avoid'" == "tolls" local lavoid = "&avoid=tolls"
			if "`avoid'" == "highways" local lavoid = "&avoid=highways"
			if "`avoid'" != "" & "`avoid'" != "tolls" & "`avoid'" != "highways"  {
			noi di as text "Error: invalid avoid option specified"
			assert 1==2
			}	
			
			
		*generate needed stuff
			tempfile txtfile
			cap drop geoid
			cap gen str24 t_distance = ""
			cap gen str24 t_time = ""
			cap gen str24 t_status = ""
			cap gen str200 t_origin = ""
			cap gen str200 t_destination = ""
			cap gen geoid = _n
			
		*variables need to be string
			cap format t_distance t_time %12.9g
			cap tostring t_distance t_time , replace force
			
			cap replace geoid = 0 if t_distance != "" & t_time != "" & t_status == "OK"
			
			sort geoid
			
		local cnt = _N
		
		*start the main routine
		forval i = 1/`cnt' {
			local starting = `start'[`i']
			local ending = `end'[`i']
			local offset = `i'-1
			
			*sometimes, if user "breaks" this is useful
				if t_distance[`i'] == "" & t_time[`i'] == "" & t_status[`i'] == "OK" {
				noi di as text "Google Distancematrix `i' of `cnt' corrupted, resetting observation."
				}
				
			*if any other error code the obs is reset
				if t_distance[`i'] == "" & t_time[`i'] == "" & t_status[`i'] != "" & t_status[`i'] != "OVER_QUERY_LIMIT" {
				noisily di as text "Google Distancematrix `i' of `cnt' corrupted, resetting observation"
				replace g_status = "" in `i'
				}
			
			*we are done with these
				if t_status[`i']  == "OK" & t_distance[`i'] != "" & t_time[`i'] != "" {
				noisily di as text "Skipping Google Distancematrix `i' of `cnt': already done" 
				}
			
			*it was over query limit in a previous try and is now reset
				if t_status[`i']  == "OVER_QUERY_LIMIT" {
				noisily di as text "`i' of `cnt' over query limit, resetting t_status"
				replace t_status = "" in `i'
				}
			
				*starting the standard procedure
					if t_status[`i'] == "" {
					
					noisily di as text "Google Distancematrix `i' of `cnt'" 
					
				*get the info and save it temporarily	
				cap copy "http://maps.googleapis.com/maps/api/distancematrix/json?origins=`starting'&destinations=`ending'&mode=`lmode'&sensor=false&units=`lunits`lavoid'" `txtfile'.json , replace
					
				*prevent google denying acces due to overflood
					sleep 500	
					
				*use insheetjson to extract data from temp file
					capture: insheetjson t_distance t_time using `txtfile'.json , table("rows") col("elements:1:distance:value" "elements:1:duration:value") limit(1) offset(`offset') replace topscalars		
					cap replace t_status = r(status) in `i'
					cap replace t_origin = r(origin_addresses) in `i'
					cap replace t_destination = r(destination_addresses) in `i'
					
				*just an insta-debug notifier
					cap assert t_status == "OK" in `i'
					if _rc == 9 noisily di as text "Return code was not OK"		

				*reading the file returned over query limit
					if t_status[`i']  == "OVER_QUERY_LIMIT" | t_status[`i']  == "REQUEST_DENIED" { 
			
				*it tells the user to continue tomorrow or change the IP-address
					noisily di as text "Google Distancematrix `i' of `cnt' failed due to daily query limit"			
					noisily di as text "aborting traveltime3, continue tomorrow or change IP"
					assert g_status[`i']  != "OVER_QUERY_LIMIT"
					assert g_status[`i']  != "REQUEST_DENIED"
			
			
					*close if t_status == "OVER_QUERY_LIMIT"
					}
					
				*close if t_status == ""
					}
						
				*close forval
				}
	
		*in the end we report if all observations went OK
			cap assert t_status == "OK"
			
			if _rc == 0 {
			noisily di as text "All observations processed successfully"
			foreach var in t_distance t_time t_origin t_destination t_status {
			cap compress `var'
			}
			}
			if _rc == 9 {
			noisily di as text "Not all observations processed successfully"
			cap noisily assert t_status == "OK"
			}	
	
			sort geoid
			cap drop geoid
			cap destring t_distance t_time, replace
			
			if "`units'" == "imperial" {
			replace t_distance = t_distance * 3.2808399 / 5280
			}
			
			if "`units'" == "metric" | "`units'" == "" {
			replace t_distance = t_distance / 1000
			}
			
			replace t_time = t_time / 60
			
			compress t_distance t_time
	}
	
end

