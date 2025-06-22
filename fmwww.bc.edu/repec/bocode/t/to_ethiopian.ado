

********************************************************************************
*** Convert Gregorian to Ethiopian dates
********************************************************************************

program define to_ethiopian
    version 10.0
    syntax varlist(min=1 max=1) [if] [in] [, eth_year(string) eth_month(string) eth_day(string)]
    
	// Date variables are numberic
    confirm numeric variable `varlist'
    
    marksample touse
    
    local fmt : format `varlist'
    local fmt = lower("`fmt'")
    
    // Obtain number of days since January 01, 1960
    tempvar temp_numeric_var_touse
    if "`fmt'" == "%td" {
        gen double `temp_numeric_var_touse' = `varlist' if `touse'
    }
    else if "`fmt'" == "%tc" {
        gen double `temp_numeric_var_touse' = dofc(`varlist') if `touse'
    }
    else {
        display as error "Date variable must be valid STATA date variable formatted as %td, %tc or %tC."
        exit 198
    }
	
	// Default variable names if not provided
	if "`eth_year'" == "" {
        local eth_year "eth_year"
    }
	if "`eth_month'" == "" {
        local eth_month "eth_month"
    }
	if "`eth_day'" == "" {
        local eth_day "eth_day"
    }

	// Validate new variable names
	capture confirm new variable `eth_year'
	if _rc {
		display as error "Option eth_year(): `eth_year' is not a valid new variable name or already exists."
		exit 198
	}
	capture confirm new variable `eth_month'
	if _rc {
		display as error "Option eth_month(): `eth_month' is not a valid new variable name or already exists."
		exit 198
	}
	capture confirm new variable `eth_day'
	if _rc {
		display as error "Option eth_day(): `eth_day' is not a valid new variable name or already exists."
		exit 198
	}
	
    // New variables placeholders
    quietly {
		gen double `eth_year'  = .
		gen double `eth_month' = .
		gen double `eth_day'   = .
		}
    
    // Call mata to perform conversion
    mata: ethdate_compute("`temp_numeric_var_touse'", "`touse'", "`eth_year'", "`eth_month'", "`eth_day'")
    
end


********************************************************************************
*** MATA function to convert Gregorian to Ethiopian dates
********************************************************************************

mata:
void ethdate_compute(string scalar datevar, string scalar touse, 
                     string scalar ethyear, string scalar ethmonth, 
					 string scalar ethday)
{
    real colvector days, years, months
    real scalar i, n
    
    // Read input data
    days = st_data(., datevar, touse)
    n = rows(days)
    
    // Initialize output vectors : Starting year (Tahsas 22, 1952) = January 01, 1960
    years  = J(n, 1, 1952)
    months = J(n, 1, 4)
    days   = days :+ 22 
    
    // Main computation loop
    for (i = 1; i <= n; i++) {
        if (days[i] != .) {  // Skip missing values
            while (days[i] > 30 | days[i] <= 0) {
                // Determine if current year is a leap year
                real scalar is_leap, year_days, pagume_days
                is_leap = mod(years[i], 4) == 3
                year_days = is_leap ? 366 : 365
                
                if (days[i] > year_days) {
                    days[i] = days[i] - year_days
                    years[i] = years[i] + 1
                }
                else if (days[i] <= 0) {
                    years[i] = years[i] - 1
                    is_leap = mod(years[i], 4) == 3
                    year_days = is_leap ? 366 : 365
                    days[i] = days[i] + year_days
                }
                else {
                    days[i] = days[i] - 30
                    months[i] = months[i] + 1
                    
                    if (months[i] == 13) {
                        is_leap = mod(years[i], 4) == 3
                        pagume_days = is_leap ? 6 : 5
                        if (days[i] > pagume_days) {
                            days[i] = days[i] - pagume_days
                            months[i] = 1
                            years[i] = years[i] + 1
                        }
                    }
                }
            }
        }
    }
    
    // Write results back to Stata
    st_store(., ethyear, touse, years)
    st_store(., ethmonth, touse, months)
    st_store(., ethday, touse, days)
}
end
