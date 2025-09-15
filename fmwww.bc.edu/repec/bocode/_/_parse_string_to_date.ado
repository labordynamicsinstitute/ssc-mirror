/*------------------------------------*/
/*_parse_string_to_date*/
/*written by Eric Jamieson */
/*version 1.0.0 2025-02-11 */
/*------------------------------------*/
cap program drop _parse_string_to_date
program define _parse_string_to_date
    version 16
    syntax, varname(name) date_format(string) newvar(name)

    // Copy input to avoid modifying the original data
    qui gen str20 fixed_date = `varname'
    
    // Handle different date formats
    if "`date_format'" == "yyyy" {
        qui replace fixed_date = fixed_date + "/01/01"
    }
    else if "`date_format'" == "ddmonyyyy" {
        qui replace fixed_date = substr(fixed_date, 6, 4) + "/" + substr(fixed_date, 3, 3) + "/" + substr(fixed_date, 1, 2)
        qui replace fixed_date = subinstr(fixed_date, "jan", "01", .)
        qui replace fixed_date = subinstr(fixed_date, "feb", "02", .)
        qui replace fixed_date = subinstr(fixed_date, "mar", "03", .)
        qui replace fixed_date = subinstr(fixed_date, "apr", "04", .)
        qui replace fixed_date = subinstr(fixed_date, "may", "05", .)
        qui replace fixed_date = subinstr(fixed_date, "jun", "06", .)
        qui replace fixed_date = subinstr(fixed_date, "jul", "07", .)
        qui replace fixed_date = subinstr(fixed_date, "aug", "08", .)
        qui replace fixed_date = subinstr(fixed_date, "sep", "09", .)
        qui replace fixed_date = subinstr(fixed_date, "oct", "10", .)
        qui replace fixed_date = subinstr(fixed_date, "nov", "11", .)
        qui replace fixed_date = subinstr(fixed_date, "dec", "12", .)
    }
    else if "`date_format'" == "yyyym00" {
        qui replace fixed_date = substr(fixed_date,1,4) + "/" + substr(fixed_date, 6, .) + "/01"
    }
    else if "`date_format'" == "yyyyddmm" {
        qui replace fixed_date = substr(fixed_date,1,4) + "/" + substr(fixed_date,7,2) + "/" + substr(fixed_date,5,2)
    }
    else if "`date_format'" == "yyyy/dd/mm" {
        qui replace fixed_date = substr(fixed_date,1,4) + "/" + substr(fixed_date,9,2) + "/" + substr(fixed_date,6,2)
    }
    else if "`date_format'" == "yyyy-dd-mm" {
        qui replace fixed_date = substr(fixed_date,1,4) + "/" + substr(fixed_date,9,2) + "/" + substr(fixed_date,6,2)
    }
    else if "`date_format'" == "yyyy-mm-dd" {
        qui replace fixed_date = substr(fixed_date,1,4) + "/" + substr(fixed_date,6,2) + "/" + substr(fixed_date,9,2)
    }
    else if "`date_format'" == "yyyymmdd" {
        qui replace fixed_date = substr(fixed_date,1,4) + "/" + substr(fixed_date,5,2) + "/" + substr(fixed_date,7,2)
    }
    else if "`date_format'" == "dd/mm/yyyy" | "`date_format'" == "dd-mm-yyyy" {
        qui replace fixed_date = substr(fixed_date,7,4) + "/" + substr(fixed_date,4,2) + "/" + substr(fixed_date,1,2)
    }
    else if "`date_format'" == "ddmmyyyy" {
        qui replace fixed_date = substr(fixed_date,5,4) + "/" + substr(fixed_date,3,2) + "/" + substr(fixed_date,1,2)
    }
    else if "`date_format'" == "mm/dd/yyyy" | "`date_format'" == "mm-dd-yyyy" {
        qui replace fixed_date = substr(fixed_date, 7, 4) + "/" + substr(fixed_date,1,2) + "/" + substr(fixed_date,4,2)
    }
    else if "`date_format'" == "mmddyyyy" {
        qui replace fixed_date = substr(fixed_date, 5, 4) + "/" + substr(fixed_date,1,2) + "/" + substr(fixed_date,3,2)
    }


    // Convert to a Stata date using date()
    qui gen `newvar' = date(fixed_date, "YMD")

    // Apply readable Stata date format
    qui format `newvar' %td

    // Clean up temporary variable
    qui drop fixed_date

end



/*--------------------------------------*/
/* Change Log */
/*--------------------------------------*/
*1.0.0 - created function