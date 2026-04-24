



capture program drop clocklabel
program define clocklabel
    version 14
    

    // Parse
    capture syntax anything(name=offset), [ NAME(string) GEN(string) REPLACE ]

    // Support gen() as alias for name()
    if "`gen'" != "" & "`name'" != "" {
        di as err "clocklabel: use either name() or gen(), not both."
        exit 198
    }
    if "`name'" == "" & "`gen'" != "" local name "`gen'"

    if _rc {
        di as err "Usage: clocklabel # , name(lblname) [replace]"
        exit 198
    }

    if "`name'" == "" {
        di as err "clocklabel: you must specify a label name via name() or gen()."
        exit 198
    }

    // Validate offset
    if regexm("`offset'", "^[0-9]+$")==0 {
        di as err "clocklabel: offset must be an integer 0–23."
        exit 198
    }
    local dst = real("`offset'")
    if missing(`dst') | `dst'<0 | `dst'>=24 {
        di as err "clocklabel: offset must be an integer 0–23."
        exit 198
    }

    // Handle existing label
    if "`replace'" != "" {
        capture label drop `name'
    }
    capture label list `name'
    if !_rc {
        di as err "clocklabel: value label `name' already exists. Use , replace or choose another name."
        exit 110
    }

    // Build 0..1440; set 0 later to equal 1440
    label define `name' 0 "00:00", replace

    forvalues i = 1/1440 {
        local minutes = `dst'*60 + `i'
        local hour = mod(floor(`minutes'/60), 24)
        local min  = mod(`minutes', 60)
        local time = string(`hour', "%02.0f") + ":" + string(`min', "%02.0f")
        label define `name' `i' "`time'", modify
    }

    // Make code 0 display the same as code 1440 (offset:00)
    label define `name' 0 "`: label `name' 1440'", modify

    // Confirmation (creation only; no application)
    di as txt "Created value label " as res "`name'" ///
        as txt " (0 = " as res "`: label `name' 0'" as txt ")."
end



