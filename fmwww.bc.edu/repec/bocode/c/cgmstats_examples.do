capture log close

log using cgmstatsexamples.log, text replace

*Example 1	

	cd "/users/ndaya1/desktop/cgmstats/"  //Note to referee: In our examples
		// the location of the input CGM files is the working directory. To test
		// you must save the folder containing all submission files (including
		// folders "Example1" and "Example2" to your working directory OR 
		// change the filepath in option "dtadir" below
	
	pwd
	
	dir 
	
	cgmstats, id(id) glucose(GlucoseValue) time(GlucoseDisplayTime) ///
	dtadir(`c(pwd)'/example1) freq(5) unit(mmol/L) ///
	timebefore("2022/02/06 12:00") ///
	hist(mean_sensor cv_sensor percent_time_3_9_10 percent_time_over_10, freq) ///
	savecombdta(cgmcombined_ex1) savesumdta(cgm_summary_file_ex1) ///
	saveplotdir(`c(pwd)'/example1) 
	
	list id first_glucose_reading ndayswear mean_sensor in 1/10, abbrev(20)
	*list id-mean_sensor in 1/10, abbrev(20)
	

	
*Example 2

	cgmstats, id(subjectid) glucose(sensorglucose) time(timestamp) ///
	dtadir(`c(pwd)'/example2) by(id day) firsthours(1) ///
	hyper_exc_lngth(45) hypo_exc_lngth(15) ///
	savecombdta(cgmcombined_ex2) savesumdta(cgm_summary_file_ex2) 
	
	list subjectid day total_sensor_readings mean_sensor in 1/20, abbrev(20)         

	
log close

graph close _all
