/*******************************************************************************

							  Stata Weaver Package
					   Developed by E. F. Haghish (2014)
			  Center for Medical Biometry and Medical Informatics
						University of Freiburg, Germany
						
						  haghish@imbi.uni-freiburg.de

		
                  The Weaver Package comes with no warranty    	
				  
				  
	Weaver version 1.0  August, 2014
	Weaver version 1.1  August, 2014
	Weaver version 1.2  August, 2014
	Weaver version 1.3  September, 2014 
	Weaver version 1.4  October, 2014 
	Weaver version 1.5  April, 2015
	Weaver version 2.0  August, 2015 
*******************************************************************************/

	/* ----     linebreak     ---- */
		
	* moves to the next line */
	program define linebreak
        version 11
        
        if "$weaver" != "" cap confirm file `"$weaver"'

        tempname canvas
        cap file open `canvas' using `"$weaver"', write text append         
		cap file write `canvas' "<br />" _n
		
		/* give a notice if Weaver not in use, but not an error */
		if "$weaver" == "" {
				di _newline
				di  _dup(17) "-"
                di as text " Nothing to {help weave}!"
				di _newline(2)
				}      
	end
