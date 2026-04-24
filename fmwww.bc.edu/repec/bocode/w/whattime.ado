capture program drop whattime
program define whattime, rclass
    version 14.0
    syntax anything(name=min) [, dst(string)]

    * Default diary start
    *if `"`dst'"' == "" local dst "04:00"

    * Require diary start time
    if `"`dst'"' == "" {
        di as err "Option dst() is required. Specify the diary start time, e.g. dst(04:00)"
        exit 198
    }
	
    * Check minute input
    capture confirm number `min'
    if _rc {
        di as err "Invalid minute: `min'. Provide an integer (e.g. 500)"
        exit 198
    }

    * Parse diary start time
    local s = clock("`dst'", "hm")
    if missing(`s') {
        di as err "Invalid start time: `dst'. Use HH:MM, e.g. 04:00"
        exit 198
    }

    * Convert start to minutes since midnight
    local smin = hh(`s')*60 + mm(`s')

    * Add relative minute and wrap around 24h
    local tmin = mod(`smin' + `min', 24*60)

    * Convert back to HH:MM
    local hh = floor(`tmin'/60)
    local mm = mod(`tmin', 60)

    * Format with leading zeros
    local hh_str : display %02.0f `hh'
    local mm_str : display %02.0f `mm'

    local timestr "`hh_str':`mm_str'"

    di as txt "Clock time: `timestr'"

    return local time "`timestr'"
    return scalar minute = `min'
    return local start "`dst'"
end
