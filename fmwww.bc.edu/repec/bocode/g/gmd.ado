cap program drop gmd
program define gmd
    version 15.0
    syntax [anything] [, COUntry(string) Version(string) Raw Iso Vars]
	
	* Checking for the dependency
	cap which missings
	if _rc {
		di as txt "Installing required package 'missings'..."
		qui ssc install missings, replace
	}
    
    * Store country list
    local countrylist Afghanistan-AFG Albania-ALB Algeria-DZA "American Samoa-ASM" Andorra-AND Angola-AGO Anguilla-AIA Antarctica-ATA "Antigua and Barbuda-ATG" Argentina-ARG Armenia-ARM Aruba-ABW Australia-AUS Austria-AUT Azerbaijan-AZE Bahamas-BHS Bahrain-BHR Bangladesh-BGD Barbados-BRB Belarus-BLR Belgium-BEL Belize-BLZ Benin-BEN Bermuda-BMU Bhutan-BTN Bolivia-BOL "Bonaire, Sint Eustatius and Saba-BES" "Bosnia and Herzegovina-BIH" Botswana-BWA "Bouvet Island-BVT" Brazil-BRA "British Indian Ocean Territory-IOT" "British Virgin Islands-VGB" Brunei-BRN Bulgaria-BGR "Burkina Faso-BFA" Burundi-BDI Cambodia-KHM Cameroon-CMR Canada-CAN "Cape Verde-CPV" "Cayman Islands-CYM" "Central African Republic-CAF" Chad-TCD Chile-CHL China-CHN "Christmas Island-CXR" "Cocos (Keeling) Islands-CCK" Colombia-COL Comoros-COM "Cook Islands-COK" "Costa Rica-CRI" Croatia-HRV Cuba-CUB Curaçao-CUW Cyprus-CYP "Czech Republic-CZE" Czechoslovakia-CSK "Democratic Republic of Yemen-YMD" "Democratic Republic of the Congo-COD" Denmark-DNK Djibouti-DJI Dominica-DMA "Dominican Republic-DOM" Ecuador-ECU Egypt-EGY "El Salvador-SLV" "Equatorial Guinea-GNQ" Eritrea-ERI Estonia-EST Eswatini-SWZ Ethiopia-ETF "Falkland Islands-FLK" "Faroe Islands-FRO" Fiji-FJI Finland-FIN France-FRA "French Guiana-GUF" "French Polynesia-PYF" "French Southern Territories-ATF" Gabon-GAB Gambia-GMB Georgia-GEO "German Democratic Republic-DDR" Germany-DEU Ghana-GHA Gibraltar-GIB Greece-GRC Greenland-GRL Grenada-GRD Guadeloupe-GLP Guam-GUM Guatemala-GTM Guernsey-GGY Guinea-GIN "Guinea-Bissau-GNB" Guyana-GUY Haiti-HTI "Heard Island and McDonald Islands-HMD" "Holy See-VAT" Honduras-HND "Hong Kong-HKG" Hungary-HUN Iceland-ISL India-IND Indonesia-IDN Iran-IRN Iraq-IRQ Ireland-IRL "Isle of Man-IMN" Israel-ISR Italy-ITA "Ivory Coast-CIV" Jamaica-JAM Japan-JPN Jersey-JEY Jordan-JOR Kazakhstan-KAZ Kenya-KEN Kiribati-KIR Kosovo-XKX Kuwait-KWT Kyrgyzstan-KGZ Laos-LAO Latvia-LVA Lebanon-LBN Lesotho-LSO Liberia-LBR Libya-LBY Liechtenstein-LIE Lithuania-LTU Luxembourg-LUX Macau-MAC Macedonia-MKD Madagascar-MDG Malawi-MWI Malaysia-MYS Maldives-MDV Mali-MLI Malta-MLT "Marshall Islands-MHL" Martinique-MTQ Mauritania-MRT Mauritius-MUS Mayotte-MYT Mexico-MEX "Micronesia (Federated States of)-FSM" Moldova-MDA Monaco-MCO Mongolia-MNG Montenegro-MNE Montserrat-MSR Morocco-MAR Mozambique-MOZ Myanmar-MMR Namibia-NAM Nauru-NRU Nepal-NPL Netherlands-NLD "Netherlands Antilles-ANT" "New Caledonia-NCL" "New Zealand-NZL" Nicaragua-NIC Niger-NER Nigeria-NGA Niue-NIU "Norfolk Island-NFK" "North Korea-PRK" "Northern Mariana Islands-MNP" Norway-NOR Oman-OMN Pakistan-PAK Palau-PLW Palestine-PSE Panama-PAN "Papua New Guinea-PNG" Paraguay-PRY Peru-PER Philippines-PHL Pitcairn-PCN Poland-POL Portugal-PRT "Puerto Rico-PRI" Qatar-QAT "Republic of the Congo-COG" Romania-ROU "Russian Federation-RUS" Rwanda-RWA Réunion-REU "Saint Barthélemy-BLM" "Saint Helena, Ascension and Tristan da Cunha-SHN" "Saint Kitts and Nevis-KNA" "Saint Lucia-LCA" "Saint Martin-MAF" "Saint Pierre and Miquelon-SPM" "Saint Vincent and the Grenadines-VCT" Samoa-WSM "San Marino-SMR" "Sao Tome and Principe-STP" "Saudi Arabia-SAU" Senegal-SEN Serbia-SRB "Serbia and Montenegro-SCG" Seychelles-SYC "Sierra Leone-SLE" Singapore-SGP "Sint Maarten-SXM" Slovakia-SVK Slovenia-SVN "Solomon Islands-SLB" Somalia-SOM "South Africa-ZAF" "South Georgia and the South Sandwich Islands-SGS" "South Korea-KOR" "South Sudan-SSD" "Soviet Union-SUN" Spain-ESP "Sri Lanka-LKA" Sudan-SDN Suriname-SUR "Svalbard and Jan Mayen-SJM" Sweden-SWE Switzerland-CHE Syria-SYR Taiwan-TWN Tajikistan-TJK Tanzania-TZA Thailand-THA "Timor-Leste-TLS" Togo-TGO Tokelau-TKL Tonga-TON "Trinidad and Tobago-TTO" Tunisia-TUN Turkey-TUR Turkmenistan-TKM "Turks and Caicos Islands-TCA" Tuvalu-TUV "US Virgin Islands-VIR" Uganda-UGA Ukraine-UKR "United Arab Emirates-ARE" "United Kingdom-GBR" "United States-USA" "United States Minor Outlying Islands-UMI" Uruguay-URY Uzbekistan-UZB Vanuatu-VUT Venezuela-VEN Vietnam-VNM "Wallis and Futuna-WLF" "Western Sahara-ESH" Yemen-YEM Yugoslavia-YUG Zambia-ZMB Zimbabwe-ZWE "Åland Islands-ALA"
    
    * Base URLs for the data
    local base_url "http://www.globalmacrodata.com"
    
    * Display package information
    di as text "Global Macro Database by Müller et. al (2025)"
    di as text "Website: https://www.globalmacrodata.com"
    di as text ""
	
	* Determine current version
	local current_date = date(c(current_date), "DMY")
	local current_year = year(date(c(current_date), "DMY"))
	local current_month = month(date(c(current_date), "DMY"))

	
	* Determine quarter based on current month 
	if `current_year' == 2025 {
		if `current_month' < 3 {
		local quarter "01"
		}
		else if `current_month' <= 6 {
			local quarter "03"
		}
		else if `current_month' <= 9 {
			local quarter "06"
		}
		else {
			local quarter "09"
		}
	}
	else {
		
		if `current_month' <= 3 {
		local quarter "12"
		}
		else if `current_month' <= 6 {
			local quarter "03"
		}
		else if `current_month' <= 9 {
			local quarter "06"
		}
		else {
			local quarter "09"
		}
	}

	local current_version "`current_year'_`quarter'"
	
	* Check if the variable exist
	if "`anything'" != "" {
    local varlist "nGDP rGDP rGDP_USD rGDP_pc deflator cons cons_GDP rcons inv inv_GDP finv finv_GDP exports exports_GDP imports imports_GDP CA CA_GDP USDfx REER govexp govexp_GDP govrev govrev_GDP govtax govtax_GDP govdef govdef_GDP govdebt govdebt_GDP HPI CPI infl pop unemp strate ltrate cbrate M0 M1 M2 M3 M4 CurrencyCrisis BankingCrisis SovDebtCrisis"
	
	* Count the number of variables
	local word_count = wordcount("`anything'")
    
    * Parse each word in `anything` as a separate variable
    foreach var of local anything {
        local var_exists = 0
        
        * Check if current variable exists in varlist
        foreach valid_var of local varlist {
            if "`var'" == "`valid_var'" {
                local var_exists = 1
                continue, break
            }
        }
        
        * If variable doesn't exist, display error and exit
        if `var_exists' == 0 {
            di as error "Invalid variable code: `var'"
            di as text _newline "To see the list of valid variable codes, use: gmd, vars" _newline
            exit 498
        }
    }
	}
	
    
	if "`vars'" != "" {
		di as text _newline "Available variables:" _newline
		di as text "{hline 90}"
		di as text "Variable" _col(17) "Description"
		di as text "{hline 90}"
		
		di as text "nGDP" _col(17) "Nominal Gross Domestic Product"
		di as text "rGDP" _col(17) "Real Gross Domestic Product, in 2010 prices"
		di as text "rGDP_pc" _col(17) "Real Gross Domestic Product per Capita"
		di as text "rGDP_USD" _col(17) "Real Gross Domestic Product in USD"
		di as text "deflator" _col(17) "GDP deflator"
		di as text "cons" _col(17) "Total Consumption"
		di as text "rcons" _col(17) "Real Total Consumption"
		di as text "cons_GDP" _col(17) "Total Consumption as % of GDP"
		di as text "inv" _col(17) "Total Investment"
		di as text "inv_GDP" _col(17) "Total Investment as % of GDP"
		di as text "finv" _col(17) "Fixed Investment"
		di as text "finv_GDP" _col(17) "Fixed Investment as % of GDP"
		di as text "exports" _col(17) "Total Exports"
		di as text "exports_GDP" _col(17) "Total Exports as % of GDP"
		di as text "imports" _col(17) "Total Imports"
		di as text "imports_GDP" _col(17) "Total Imports as % of GDP"
		di as text "CA" _col(17) "Current Account Balance"
		di as text "CA_GDP" _col(17) "Current Account Balance as % of GDP"
		di as text "USDfx" _col(17) "Exchange Rate against USD"
		di as text "REER" _col(17) "Real Effective Exchange Rate, 2010 = 100"
		di as text "govexp" _col(17) "Government Expenditure"
		di as text "govexp_GDP" _col(17) "Government Expenditure as % of GDP"
		di as text "govrev" _col(17) "Government Revenue"
		di as text "govrev_GDP" _col(17) "Government Revenue as % of GDP"
		di as text "govtax" _col(17) "Government Tax Revenue"
		di as text "govtax_GDP" _col(17) "Government Tax Revenue as % of GDP"
		di as text "govdef" _col(17) "Government Deficit"
		di as text "govdef_GDP" _col(17) "Government Deficit as % of GDP"
		di as text "govdebt" _col(17) "Government Debt"
		di as text "govdebt_GDP" _col(17) "Government Debt as % of GDP"
		di as text "HPI" _col(17) "House Price Index"
		di as text "CPI" _col(17) "Consumer Price Index, 2010 = 100"
		di as text "infl" _col(17) "Inflation Rate"
		di as text "pop" _col(17) "Population"
		di as text "unemp" _col(17) "Unemployment Rate"
		di as text "strate" _col(17) "Short-term Interest Rate"
		di as text "ltrate" _col(17) "Long-term Interest Rate"
		di as text "cbrate" _col(17) "Central Bank Policy Rate"
		di as text "M0" _col(17) "M0 Money Supply"
		di as text "M1" _col(17) "M1 Money Supply"
		di as text "M2" _col(17) "M2 Money Supply"
		di as text "M3" _col(17) "M3 Money Supply"
		di as text "M4" _col(17) "M4 Money Supply"
		di as text "SovDebtCrisis" _col(17) "Sovereign Debt Crisis"
		di as text "CurrencyCrisis" _col(17) "Currency Crisis"
		di as text "BankingCrisis" _col(17) "Banking Crisis"
		
		di as text "{hline 90}"
		exit _rc
	}
	
	* Process version option
    if "`version'" != "" {
		
    * Handle current version explicitly
    if lower("`version'") == "current" {
        local data_url "`base_url'/GMD_`current_version'.dta"
    }
    else {
        * Parse the year and quarter
        local year = substr("`version'", 1, 4)
        local quarter = substr("`version'", 6, 2)
        
        * Validate year and quarter
        if !inrange(`year', 2020, 2050) | !inlist("`quarter'", "01", "03", "06", "09", "12") {
            di as error "Error: Version must be either 'current' or in YYYY_QQ format (e.g., 2024_04)"
            di as text _newline "Quarter must be 03, 06, 09, or 12 (Except for the first release which is 2025_01)"
            exit 498
			}
        
        * If we get here, format is valid
        local data_url "`base_url'/GMD_`version'.dta"
		}
		
		local current_version "`version'"
	}
	
    else {
        * Default to current base URL
        local data_url "`base_url'/GMD_`current_version'.dta"
    }
	
	
    
    * If country specified, validate it against the list
    if "`country'" != "" {
        local country = upper("`country'")
        local valid = 0
        
        foreach pair of local countrylist {
            local ccode = substr("`pair'", -3, .)
            if "`country'" == "`ccode'" {
                local valid = 1
                continue, break
            }
        }
        
        if `valid' == 0 {
            di as error "Error: Invalid country code '`country''"
            di as text _newline "To see the list of valid country codes, use: gmd, iso" _newline
			exit 498
        }
		
    }
	
	* Print the list of countries 
	if "`iso'" != "" {
		di as text "{hline 60}"
		di as text "Country and territories" _col(50) "Code"
		di as text "{hline 60}"
		
		foreach pair of local countrylist {
			local cname = substr("`pair'", 1, strlen("`pair'") - 4)
			local ccode = substr("`pair'", -3, 3)
			di as text "`cname'" _col(50) "`ccode'"
		}
		
		di as text "{hline 60}"
		exit _rc
	}
	
    
    * Always clear existing data
    clear
    
    * Load data based on whether variables are specified
    cap noisily {
    if "`raw'" != "" {
		
		* Make sure that only one variable is selected
		if `word_count' > 1 {
			di as error "Warning: raw requires specifying exactly one variable (not more, not less)."
			exit _rc
		}
		
        * Raw option is specified
        if "`anything'" == "" {
            * No variable specified, import first sheet with warning
            di as error "Warning: No variable specified."
            di as text "Note: Raw data is only accessed variable-wise using: gmd [variable], raw"
			di as text `"To download the full data documentation: {browse "https://www.globalmacrodata.com/GMD.xlsx":https://www.globalmacrodata.com/GMD.xlsx}"'
			exit _rc
        }
        else {
            * Variable specified, import that specific sheet
            di "Importing raw data for variable: `anything'"
            qui import delimited using "`base_url'/`anything'_`current_version'.csv", clear case(preserve)
			
			* Set up the panel
			qui encode ISO3, gen(id)
			qui xtset id year 
			
			* Order the variable and sort the data 
			order ISO3 countryname id year 
			sort countryname year
			
        }
    }
    else {
        * Original functionality for non-raw option
        if "`anything'" == "" {
            qui use "`data_url'"
        }
        else {
			* If we are selecting one variable, import the csv because it's faster
			if `word_count' == 1 {
				di "Importing data for variable: `anything'"
				qui import delimited using "`base_url'/`anything'_`current_version'.csv", clear case(preserve)
				
				* Set up the panel
				qui encode ISO3, gen(id)
				qui xtset id year 
				
				* Keep the variable demanded 
				qui keep ISO3 year id countryname `anything'
			}
			
			* Otherwise use the excel
			else {
				qui use ISO3 year id countryname `anything' using "`data_url'"
			}
			
			* Order the variable and sort the data 
			order ISO3 countryname id year 
			sort countryname year
        }
    }
}
	
    * Check for the version error
    if _rc {
        if "`version'" != "" {
            di as error "Error: Version `version' not found"
        }
        else {
            di as error "Error: Unable to download current version"
        }
        di as text _newline "Please visit {browse www.globalmacrodata.com/data.html} to see available version dates"
        exit _rc
    }
    
    * If country specified, filter for that country
    if "`country'" != "" {
        qui keep if ISO3 == "`country'"
        di as text "Filtered data for country: `country'"
    }
    
    * Display final dataset dimensions
	cap missings dropvars, force
	qui describe
	if r(k) < 5 {
		di "The database has no data on `anything' for `country'"
		clear
		exit 498
	}
	else {
		qui: describe
		if r(N) > 0 {
		if "`raw'" != "" {
			local n_sources = `r(k)' - 8
			di as text "Final dataset: `r(N)' observations of `n_sources' sources"
			
			* Display version information
			if "`version'" != "" {
				di as text "Version: `version'"
			}
			else {
				di as text "Version: `current_version'"
			}
			
			* Order the variable and sort the data 
			order ISO3 countryname id year 
			sort countryname year
		}

		else {
		di as text "Final dataset: `r(N)' observations of `r(k)' variables"

		* Display version information
		if "`version'" != "" {
			di as text "Version: `version'"
		}
		else {
			di as text "Version: `current_version'"
		}

		* Order the variable and sort the data 
		order ISO3 countryname id year 
		sort countryname year
		}	
	}
}

end
