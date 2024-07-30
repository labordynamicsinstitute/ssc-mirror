
cap pr drop matdrop 

program define matdrop

   version 10.0

    // extract the matrix name from the syntax
    gettoken matname 0 : 0, parse(" ,")
	
    syntax , [r(string) c(string)] 
	
	
	if "`r'" == "" & "`c'" == "" {
                di in bl "Nothing to do here since both options are empty"
                exit 0
        }

    // temporary name for the matrix
    tempname matrixname
    mat `matrixname' = `matname'

    // get the row and column names of the matrix
    local rows : rowfullnames `matrixname'
    local columns: colfullnames `matrixname'
        
    scalar full_rows = `:word count `rows''
    scalar full_columns = `:word count `columns''
	

    //default to empty lists if none specified
    local rnamelist ""
    local cnamelist ""
	
    //default to all rows if none specified
    if "`r'" != "" {
        local rnamelist: di "`r'"
    } 

    if "`c'" != "" {
        local cnamelist: di "`c'"
    } 
	
	
 //handle Row removal
    if "`rnamelist'" != "" & {
        local row= "`rnamelist'" 
		
        scalar row_count = `:word count `row''

        if  row_count > full_rows{
            di in r "row number out of range"
            exit 498
        }
		
		if full_rows ==1 {
		    di in r "Only row from the matrix can not be removed"
		}
		
         // Create index for each word in the local rows
		scalar j = 1
        foreach word_row of local rows {
            local row_index_`word_row' = j
            scalar j = j + 1	
		}
		
		// now search for each word in the row and delete it by its index 
		scalar shift_row = 0 
        foreach check_word_row of local row { 
            if "`check_word_row'" != "" {
			    
                local index_row = `row_index_`check_word_row'' - shift_row	
				
				scalar shift_row = shift_row + 1 
				
				*delete the specific row 
				
				if "`index_row'" != "0" {
				
				    matdelrc `matrixname', r(`index_row')
				}
                
            }
        }
		

		if row_count == full_rows{
		    
			mat `matrixname' = `matrixname'
		}
	}

 
    //handle column removal
    if "`cnamelist'" != "" & {
        local col= "`cnamelist'" 
		
        scalar col_count = `:word count `col''
       
        if  col_count > full_columns {
            di in r "Column number out of range"
            exit 498
        }
		
		if full_columns ==1 {
		    di in r "Only column from the matrix can not be removed"
		}
		
        //create index for each word in the local columns
		scalar i = 1
        foreach word of local columns {
            local column_index_`word' = i
            scalar i = i + 1	
		}
		
		//now search for each word in the col and delete it by its index 
		scalar shift = 0 
        foreach check_word of local col { 
            if "`check_word'" != "" {
                local index_col = `column_index_`check_word'' - shift 
				
				scalar shift = shift + 1
				
				*delete the specific column
				if "`index_col'" != "0" {
				
				    matdelrc `matrixname', c(`index_col')
				}
            }
        }
		
	   if col_count == full_columns{
		    
			mat `matrixname' = `matrixname'
   }
}
 		
mat `matname' = `matrixname'

end



