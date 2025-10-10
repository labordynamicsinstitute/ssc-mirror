*! 1.2.1 KN 24sep2025
* 1.2.0 KN 8sep2025
* 1.1.0 KN 18apr2023
* 1.0.0 NJC 8jul2014 
* splitvallabels.ado v1.1.2 Nicholas Winter/Ben Jann 14aug2008

program splitvarlabels, sclass
    version 8.2
    syntax varlist, [LENgth(int 15) Break LOCal(string) Delimiter(string)]
    
    * Default action is to keep even long words intact. However, the user can break words by using the break option

    local nobreak = cond("`break'" != "", "", "nobreak")
    
    local j = 1

    di 
    
    foreach var of varlist `varlist' {    
        local label : var label `var'
        if `"`label'"' == "" local label "`var'" 
        
        local eff_length = `length'	
 
        * Making chunks
        local newlabel = ""
        local i = 1

        * Override if delimiter is specified and found
        if "`delimiter'" != "" {
            local pos = strpos(`"`label'"', "`delimiter'")
            if `pos' > 0 {
                local eff_length = `pos' - 1  // Split just before the delimiter
            }
        }
    
        local part : piece `i' `eff_length' of `"`label'"', `nobreak'
    
        while `"`part'"' != "" {
            local newlabel `"`newlabel' `"`part'"' "'
            local i = `i' + 1
            local part : piece `i' `eff_length' of `"`label'"', `nobreak'
        }    
    
        di `"`j' `"`newlabel'"'"'         
        local all_labels    `"`all_labels' `j' `"`newlabel'"' "'
    
        local j = `j' + 1
    }

    sreturn local relabel `"`all_labels'"'
    
    if "`local'" != "" {
        c_local `local' `"`all_labels'"'
    }
end
