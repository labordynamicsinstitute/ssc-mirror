*! v1.2 09may2024 by deng.28@outlook.com with input from C. Baum
*! v1.1 08may2024 by deng.28@outlook.com

program define trim_vars, nclass
    version 17.0
    syntax varlist

    // Identify string variables to be trimmed
    quietly ds `varlist', has(type string)
    local vars_to_trim = "`r(varlist)'"

    // Will not proceed if no string variables identified
    capture assert !missing("`vars_to_trim'")
    if _rc {
        display as error "No string variables specified."
        exit 109
    }

    // Trim string variables
    foreach v of varlist `vars_to_trim' {
        display as text "Trimming variable " as input "`v'" as text "..."
        replace `v' = ustrtrim(stritrim(`v'))
    }

end