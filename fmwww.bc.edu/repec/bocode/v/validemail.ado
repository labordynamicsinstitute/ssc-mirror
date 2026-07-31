*! validemail.ado  Email Validation via Regex, DNS/MX Check, and Disposable Domain Detection
*! version 2.1.1  2024-06-13
*! Eric A. Booth <eric.a.booth@gmail.com>

cap program drop validemail
program define validemail
    version 14.0
    syntax varlist(max=1) [,  GENerate(name) DNS(name) mx IP(name) DISPOSable(name) Mergereport regex(string) LOWercase]

    * Default variable names
    if `"`generate'"' == "" loc generate validated_status
    if `"`dns'"' == ""      loc dns validated_domain
    if `"`ip'"' == ""       loc ip validated_ip
    if `"`disposable'"' == "" loc disposable validated_disposable

    * Confirm variables don't exist
    foreach v in `generate' `dns' `ip' `disposable' {
        cap confirm variable `v', exact
        if !_rc {
            noi di in r as smcl `"Variable {stata desc `v':`v'} already exists. Specify new variables in options."'
            error 198
        }
    }

    * Default Regex
    if `"`regex'"' == "" {
        loc regex "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    }

    qui {
        * Clean input
        tempvar clean_email
        g `clean_email' = trim(`varlist')
        replace `clean_email' = subinstr(`clean_email', " ", "", .)
        if "`lowercase'" != "" {
            replace `clean_email' = lower(`clean_email')
        }

        * Initial status: 0 (Invalid Format)
        g `generate' = 0
        
        * Regex Check (Status 1: Valid Format)
        replace `generate' = 1 if ustrregexm(`clean_email', "`regex'")
        
        * Extract domain
        g `dns' = ""
        replace `dns' = ustrregexs(1) if ustrregexm(`clean_email', "@(.*)$")
        replace `dns' = "" if `generate' == 0
        
        * Initialize IP and Disposable
        g `ip' = ""
        g `disposable' = 0
    }

    * Disposable Check
    noi di as text "Checking for disposable domains..."
    qui {
        loc d_list "mailinator.com 10minutemail.com guerrillamail.com temp-mail.org yopmail.com throwawaymail.com sharklasers.com getairmail.com maildrop.cc dispostable.com"
        foreach d in `d_list' {
            replace `disposable' = 1 if `dns' == "`d'"
        }
    }

    * DNS / MX Check
    tempfile email_results
    tempfile dns_list
    
    qui {
        preserve
        keep if `generate' == 1
        keep `dns'
        duplicates drop `dns', force
        
        loc n_domains = _N
        
        if `n_domains' > 0 {
            * 1. Store domain names in locals to survive 'clear'
            forval i = 1/`n_domains' {
                loc d`i' = `dns'[`i']
            }

            noi di as text "Checking DNS/MX for `n_domains' unique domains..."
            
            * 2. Run nslookup for each domain
            forval i = 1/`n_domains' {
                loc d_name = `"`d`i''"'
                loc type = cond("`mx'" != "", "-type=MX", "")
                
                * Use shell command with redirection
                qui !nslookup `type' `d_name' > "`email_results'_`i'.txt"
                
                * Progress
                if mod(`i', 5) == 0 | `i' == `n_domains' {
                    noi di as text "." _continue
                }
            }
            noi di ""
            
            * 3. Process results into a temp file using postfile
            tempname memhold
            tempfile master_dns
            * Use str240 to be safe for domain and IP
            postfile `memhold' str240 `dns' str240 `ip' dns_valid using `master_dns', replace

            forval i = 1/`n_domains' {
                loc d_name = `"`d`i''"'
                cap qui import delimited "`email_results'_`i'.txt", clear delimiters("\n") varnames(nonames)
                
                loc valid = 0
                loc ip_current = ""
                
                if !_rc & _N > 0 {
                    forval j = 1/`=_N' {
                        loc line = v1[`j']
                        if strpos("`line'", "Address:") {
                            loc ip_current = trim(subinstr("`line'", "Address:", "", 1))
                            * Some nslookup outputs include #port
                            if strpos("`ip_current'", "#") loc ip_current = trim(word("`ip_current'", 1))
                            loc valid = 1
                        }
                        if strpos("`line'", "mail exchanger") {
                            loc valid = 1
                        }
                    }
                    
                    * Fallback if no specific tags found but lookup wasn't an error
                    if `valid' == 0 {
                        count if strpos(v1, "NXDOMAIN")
                        if r(N) == 0 {
                            count if _n > 2
                            if r(N) > 0 loc valid = 1
                        }
                    }
                }
                
                * Post the result for this domain
                post `memhold' (`"`d_name'"') (`"`ip_current'"') (`valid')
            }
            postclose `memhold'
            
            * Load the results and save to dns_list
            use `master_dns', clear
            duplicates drop `dns', force
            save "`dns_list'", replace
        }
        restore
        
        * Merge results back to main dataset
        if `n_domains' > 0 {
            merge m:1 `dns' using "`dns_list'", nogenerate keep(master match)
            
            * Update Status
            replace `generate' = 2 if `generate' == 1 & dns_valid == 1
            replace `generate' = 3 if `generate' == 2 & `disposable' == 1
            drop dns_valid
        }
    }

    * Report results
    di as smcl `"{hline}"'
    di as text "Email Validation Report for {bf:`varlist'}"
    di as text "Status codes in {bf:`generate'}:"
    
    qui count if `generate' == 0
    di as text "  0: Invalid format: " _col(35) as result r(N)
    
    qui count if `generate' == 1
    di as text "  1: Valid format, DNS/MX fail: " _col(35) as result r(N)
    
    qui count if `generate' == 2
    di as text "  2: Valid format, DNS/MX pass: " _col(35) as result r(N)
    
    qui count if `generate' == 3
    di as text "  3: Valid format, Disposable: " _col(35) as result r(N)
    di as smcl `"{hline}"'

    if "`mergereport'" != "" {
        capture label drop evstatus
        label define evstatus 0 "Invalid Format" 1 "DNS Fail" 2 "Valid" 3 "Disposable"
        label values `generate' evstatus
        tab `generate'
    }

    * Cleanup temporary files
    cap shell rm "`email_results'_*.txt"
end
