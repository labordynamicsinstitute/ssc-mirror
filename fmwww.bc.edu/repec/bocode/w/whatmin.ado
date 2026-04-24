
capture program drop whatmin
program define whatmin, rclass
    version 14.0
    syntax anything(name=tstr) [, dst(string)]

 
    * Require diary start time
	if `"`dst'"' == "" {
		di as err "Option dst() is required. Specify the diary start time, e.g. dst(04:00)"
		exit 198
	}

    * Parse target time
    local t = clock("`tstr'", "hm")
    if missing(`t') {
        di as err "Invalid time: `tstr'. Use HH:MM, e.g. 18:00"
        exit 198
    }

    * Parse diary start time
    local s = clock("`dst'", "hm")
    if missing(`s') {
        di as err "Invalid start time: `dst'. Use HH:MM, e.g. 04:00"
        exit 198
    }

    * Convert to minutes since midnight
    local tmin = hh(`t')*60 + mm(`t')
    local smin = hh(`s')*60 + mm(`s')

    * Relative minute in diary
    local rel = `tmin' - `smin'

    * If target time is after midnight but still part of same diary day
    if `rel' < 0 local rel = `rel' + 24*60
    di as txt "Minute index: `rel'"

    return scalar minute = `rel'
    return local time "`tstr'"

	return local start "`dst'"
	
end

