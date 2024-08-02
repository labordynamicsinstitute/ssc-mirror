/*******************************************************************************
*                                                                              *
*                     Client-/User-Side Compilation of Libxv                   *
*                                                                              *
*******************************************************************************/

*! libxv
*! v 0.0.1
*! 02mar2024

// Drop program from memory if already loaded
cap prog drop libxv

// Defines the program
prog def libxv

	// Provides a version statement
	version 15
	
	// Defines the syntax
	syntax [, DISplay ]
	
	// Try to find the library file
	cap: findfile crossvalidate.mata
	
	// If the file is found
	if _rc == 0 {
		
		// Gets the distribution date for the uncompiled mata library
		mata: st_local("fdate", distdate(`"`r(fn)'"'))
		
		// If the distribution date is greater than or equal to the date here
		if td(`"`fdate'"') >= td("02mar2024") {
			
			// clear mata memory
			mata: mata clear
			
			// Run the mata file
			run `"`r(fn)'"'
			
			// Compile the library
			qui: lmbuild libxv, replace
			
			// Rebuild the index
			qui: mata: mata mlib index
			
		} // End IF Block for recompilation
		
	} // End IF Block for successful location of the file
	
	// Call the help file
	if !mi(`"`display'"') help libxv
	
// End of the program definition
end

