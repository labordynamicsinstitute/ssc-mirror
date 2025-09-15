/*------------------------------------*/
/*_parse_date_to_string*/
/*written by Eric Jamieson */
/*version 1.0.0 2025-02-14 */
/*------------------------------------*/

cap program drop _parse_date_to_string
program define _parse_date_to_string
    version 16
    syntax, varname(name) date_format(string) newvar(name)

    // Create an empty string variable to store formatted date
    qui gen str20 `newvar' = ""

    // Handle different date formats
    if "`date_format'" == "yyyy" {
        qui replace `newvar' = string(year(`varname'))
    }
    else if "`date_format'" == "ddmonyyyy" {
        qui gen mon = ""
        qui replace mon = "jan" if month(`varname') == 1
        qui replace mon = "feb" if month(`varname') == 2
        qui replace mon = "mar" if month(`varname') == 3
        qui replace mon = "apr" if month(`varname') == 4
        qui replace mon = "may" if month(`varname') == 5
        qui replace mon = "jun" if month(`varname') == 6
        qui replace mon = "jul" if month(`varname') == 7
        qui replace mon = "aug" if month(`varname') == 8
        qui replace mon = "sep" if month(`varname') == 9
        qui replace mon = "oct" if month(`varname') == 10
        qui replace mon = "nov" if month(`varname') == 11
        qui replace mon = "dec" if month(`varname') == 12

        qui replace `newvar' = string(day(`varname'), "%02.0f") + mon + string(year(`varname'))
        qui drop mon
    }
    else if "`date_format'" == "yyyym00" {
        qui replace `newvar' = string(year(`varname')) + "m" + string(month(`varname'), "%02.0f")
    }
    else if "`date_format'" == "yyyyddmm" {
        qui replace `newvar' = string(year(`varname')) + string(day(`varname'), "%02.0f") + string(month(`varname'), "%02.0f")
    }
    else if "`date_format'" == "yyyy/dd/mm" {
        qui replace `newvar' = string(year(`varname')) + "/" + string(day(`varname'), "%02.0f") + "/" + string(month(`varname'), "%02.0f")
    }
    else if "`date_format'" == "yyyy-dd-mm" {
        qui replace `newvar' = string(year(`varname')) + "-" + string(day(`varname'), "%02.0f") + "-" + string(month(`varname'), "%02.0f")
    }
    else if "`date_format'" == "yyyy-mm-dd" {
        qui replace `newvar' = string(year(`varname')) + "-" + string(month(`varname'), "%02.0f") + "-" + string(day(`varname'), "%02.0f") 
    }
    else if "`date_format'" == "yyyy/mm/dd" {
        qui replace `newvar' = string(year(`varname')) + "/" + string(month(`varname'), "%02.0f") + "/" + string(day(`varname'), "%02.0f") 
    }
    else if "`date_format'" == "yyyymmdd" {
        qui replace `newvar' = string(year(`varname')) + string(month(`varname'), "%02.0f") + string(day(`varname'), "%02.0f") 
    }
    else if "`date_format'" == "dd/mm/yyyy" {
        qui replace `newvar' = string(day(`varname'), "%02.0f") + "/" + string(month(`varname'), "%02.0f") + "/" + string(year(`varname'))
    }
    else if "`date_format'" == "dd-mm-yyyy" {
        qui replace `newvar' = string(day(`varname'), "%02.0f") + "-" + string(month(`varname'), "%02.0f") + "-" + string(year(`varname'))
    }
    else if "`date_format'" == "ddmmyyyy" {
        qui replace `newvar' = string(day(`varname'), "%02.0f") + string(month(`varname'), "%02.0f") + string(year(`varname'))
    }
    else if "`date_format'" == "mm/dd/yyyy" {
        qui replace `newvar' = string(month(`varname'), "%02.0f") + "/" + string(day(`varname'), "%02.0f") +  "/" + string(year(`varname'))
    }
    else if "`date_format'" == "mm-dd-yyyy" {
        qui replace `newvar' = string(month(`varname'), "%02.0f") + "-" + string(day(`varname'), "%02.0f") +  "-" + string(year(`varname'))
    }
    else if "`date_format'" == "mmddyyyy" {
        qui replace `newvar' = string(month(`varname'), "%02.0f") + string(day(`varname'), "%02.0f") + string(year(`varname'))
    }
    else {
        di as error "Unsupported date format: `date_format'"
        exit 198
    }

end

/*--------------------------------------*/
/* Change Log */
/*--------------------------------------*/
*1.0.0 - created function