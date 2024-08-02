/*******************************************************************************
*                                                                              *
*             Handles persisting the state of Stata when using xv              *
*                                                                              *
*******************************************************************************/

*! state
*! v 0.0.2
*! 29FEB2024

// Drop program from memory if already loaded
cap prog drop state

// Define program
prog def state, rclass 

	// Version statement 
	version 15

	// Set a characteristic with the current rng
	char _dta[rng] `"`c(rng)'"'
	
	// Return this in the argument named local
	ret loc rng = `"`c(rng)'"'
	
	// Set the dataset characteristic for the current RNG in effect
	char _dta[rngcurrent] `"`c(rng_current)'"'
	
	// Set the return macro
	ret loc rngcurrent = `"`c(rng_current)'"'
	
	// Set the dataset characteristic for the current state of the RNG
	char _dta[rngstate] `"`c(rngstate)'"'

	// Set the return macro
	ret loc rngstate = `"`c(rngstate)'"'
	
	// Set the dataset characteristic for the last set seed for the RNG
	char _dta[rngseed] `"`c(rngseed_mt64s)'"'
	
	// Set the return macro
	ret loc rngseed = `"`c(rngseed_mt64s)'"'
	
	// Set the dataset characteristic for the current stream of the streaming RNG
	char _dta[rngstream] `"`c(rngstream)'"'
	
	// Set the return macro
	ret loc rngstream = `"`c(rngstream)'"'
	
	// Set the dataset characteristic for the name of the file in memory
	char _dta[filename] `"`c(filename)'"'
	
	// Set the return macro
	ret loc filename = `"`c(filename)'"'
	
	// Set the dataset characteristic for the last saved file date
	char _dta[filedate] `"`c(filedate)'"'
	
	// Set the return macro
	ret loc filedate = `"`c(filedate)'"'
		
	// Set the dataset characteristic for the Stata version
	char _dta[version] `"`c(version)'"'
	
	// Set the return macro for it
	ret loc version = `"`c(version)'"'
	
	// Set the dataset characteristic for the current date 
	char _dta[currentdate] `"`c(current_date)'"'
	
	// Set the return macro for it
	ret loc currentdate = `"`c(current_date)'"'
	
	// Set the dataset characteristic for the current time
	char _dta[currenttime] `"`c(current_time)'"'
	
	// Set the return macro for it
	ret loc currenttime = `"`c(current_time)'"'
	
	// Set the dataset characteristic for the stata edition/flavor
	char _dta[stflavor] `"`c(edition_real)'"'
	
	// Set the return macro for it
	ret loc stflavor = `"`c(edition_real)'"'
	
	// Set the dataset characteristic for the number of processors for use
	char _dta[processors] `"`c(processors)'"'
	
	// Set the return macro for it
	ret loc processors = `"`c(processors)'"'
	
	// Set the dataset characteristic for the hostname
	char _dta[hostname] `"`c(hostname)'"'
	
	// Set the return macro for it
	ret loc hostname = `"`c(hostname)'"'
	
	// Set the dataset characteristic for the machine type
	char _dta[machinetype] `"`c(machine_type)'"'
	
	// Set the return macro for it
	ret loc machinetype = `"`c(machine_type)'"'
	
// End of program definition
end

