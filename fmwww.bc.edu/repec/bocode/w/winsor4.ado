*! winsor4: trims or winsorizes a variable based on outliers defined by either percentiles or interquartile range.
*! Version: August, 2024
*! Authors: Adrien Matray, Pablo E. Rodriguez

capture program drop winsor4
program define winsor4
    syntax varlist(numeric min=1 max=1), METhod(string) OUTlier(string) Level(string) [NEWvar(string)] [POSitive] [GRoup(string)]
    version 13.0

    quietly {
        * Parse the level option
        tokenize `level'
        local threshold `1'

        * Validate the method option
        if inlist("`method'", "trim", "winsor") == 0 {
            display as error "Invalid method specified. Please use 'trim' or 'winsor'."
            exit 198
        }

        * Validate the outlier option
        if inlist("`outlier'", "tail", "iqr") == 0 {
            display as error "Invalid outlier definition specified. Please use 'tail' or 'iqr'."
            exit 198
        }

        * Create temporary variable for the group option
        tempvar groupvar

        * Handle the group option
        if "`group'" == "" {
            gen `groupvar' = 1
        }
        else {
            gen `groupvar' = `group'
        }

        * Handle the positive option
        local condition "1"
        if "`positive'" != "" {
            local condition "`varlist' > 0"
        }
		
		 * If newvar option is specified, create the new variable outside the loop
        if "`newvar'" != "" {
            gen `newvar' = `varlist'
        }

        * Process based on method and outlier options
        levelsof `groupvar', local(groups)
        foreach g of local groups {
            if "`outlier'" == "tail" {
                local uptail = 100 - `threshold'
                local lowtail = `threshold'
                quietly summ `varlist' if `groupvar' == `g' & `condition', detail
                local lowcut = r(p`lowtail')
                local upcut = r(p`uptail')
            }
            else if "`outlier'" == "iqr" {
                quietly summ `varlist' if `groupvar' == `g' & `condition', detail
                local iqr = r(p75) - r(p25)
                local lowcut = r(p50) - `threshold' * `iqr'
                local upcut = r(p50) + `threshold' * `iqr'
            }

            if "`method'" == "trim" {
                if "`newvar'" == "" {
                    quietly replace `varlist' = . if (`varlist' < `lowcut' | `varlist' > `upcut') & `groupvar' == `g' & `condition' & `varlist'<.
                }
                else {
                    quietly replace `newvar' = . if (`newvar' < `lowcut' | `newvar' > `upcut') & `groupvar' == `g' & `condition' & `varlist'<.
                }
            }
            else if "`method'" == "winsor" {
                if "`newvar'" == "" {
                    quietly replace `varlist' = max(`lowcut', min(`varlist', `upcut')) if `groupvar' == `g' & `condition' & `varlist'<.
                }
                else {
                    quietly replace `newvar' = max(`lowcut', min(`newvar', `upcut')) if `groupvar' == `g' & `condition' & `varlist'<.
                }
            }
        }
    }
end













