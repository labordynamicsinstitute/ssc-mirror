
********************************************************************************
*** Convert Ethiopian to Gregorian dates
********************************************************************************


program define to_gregorian
    version 10.0
    syntax varlist(min=3 max=3) [if] [in] [, gre_date(string)]
    
    // All variables must be numeric
    confirm numeric variable `varlist'
    
    // Parse varlist into year, month, day
    tokenize `varlist'
    local year `1'
    local month `2'
    local day `3'
    
    marksample touse
    
    // Set default result variable name if not specified
    if "`gre_date'" == "" {
        local gre_date "gre_date"
    }
    
    // Confirm result variable is new
    capture confirm new variable `gre_date'
    if _rc {
        display as error "Option gre_date(): `gre_date' is not a valid new variable name or already exists."
        exit 198
    }
    
    // Generate result variable
    quietly gen double `gre_date' = .
    
    // Call Mata function to perform validation and computation
    mata: eth_date_validate("`year'", "`month'", "`day'", "`touse'", "`gre_date'")
	
	// Format as date
	format `gre_date' %td
end


********************************************************************************
*** MATA function to convert Ethiopian to Gregorian dates
********************************************************************************


mata:
void eth_date_validate(string scalar yearvar, string scalar monthvar, 
                              string scalar dayvar, string scalar touse, 
                              string scalar resultvar)
{
    real colvector year, month, day, result
    real scalar i, n, base_offset, days, cur_year, year_days, invalid
    
    // Read input data
    year = st_data(., yearvar, touse)
    month = st_data(., monthvar, touse)
    day = st_data(., dayvar, touse)
    
    n = rows(year)
    base_offset = 112  // Days from Meskerem 1, 1952 to Tahsas 22, 1952 (Jan 01, 1960 GC)
    result = J(n, 1, .)  // Initialize result with missing values
    invalid = 0
    
    for (i = 1; i <= n; i++) {
        // Check for missing values
        if (missing(year[i]) | missing(month[i]) | missing(day[i])) {
            result[i] = .
            invalid = invalid + 1
            continue
        }
        
        // Validate year (basic range check)
        if (year[i] < 0 | year[i] > 9999) {
            result[i] = .
            invalid = invalid + 1
            continue
        }
        
        // Validate month
        if (month[i] < 1 | month[i] > 13) {
            result[i] = .
            invalid = invalid + 1
            continue
        }
        
        // Validate day
        if (day[i] < 1 | day[i] > 30) {
            result[i] = .
            invalid = invalid + 1
            continue
        }
        
        // Validate Pagumae (month 13) days
        if (month[i] == 13) {
            if (day[i] > 6) {
                result[i] = .
                invalid = invalid + 1
                continue
            }
            if (day[i] > 5 & mod(year[i], 4) != 3) {  // Non-leap year
                result[i] = .
                invalid = invalid + 1
                continue
            }
        }
        
        // Calculate days since base date (Tahsas 22, 1952)
        days = 0
        cur_year = year[i]
        
        // Add days for months and days in current year
        if (month[i] > 1) {
            days = days + (month[i] - 1) * 30
            days = days + day[i]
        } else {
            days = days + day[i]
        }
        
        // Adjust for years after 1952
        while (cur_year > 1952) {
            year_days = (mod(cur_year - 1, 4) == 3) ? 366 : 365
            days = days + year_days
            cur_year = cur_year - 1
        }
        
        // Adjust for years before 1952
        while (cur_year < 1952) {
            year_days = (mod(cur_year, 4) == 3) ? 366 : 365
            days = days - year_days
            cur_year = cur_year + 1
        }
        
        result[i] = days - base_offset
    }
    
    // Display warning for invalid dates
    if (invalid > 0) {
        printf("Detected %g invalid date%s and coerced to missing.\n", 
               invalid, (invalid == 1 ? "" : "s"))
    }
    
    // Store result back to Stata
    st_store(., resultvar, touse, result)
}
end

