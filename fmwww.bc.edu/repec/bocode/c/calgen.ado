


program calgen, rclass

    version 11

    syntax, did(string) dst(string) slotd(integer)

    *------------------------------------------------------------*
    * Check compatibility between episode durations and slotd()
    *------------------------------------------------------------*
    capture drop __mod
    gen __mod = mod(time, `slotd') if !missing(time)

    qui count if __mod != 0 & !missing(__mod)
    if r(N) > 0 {

        preserve
            qui keep if !missing(time) & time > 0
            sort time

            * Start with first positive duration
            quietly summarize time in 1, meanonly
            local gcd = r(mean)

            * Compute gcd across all positive durations
            quietly {
                forvalues i = 2/`=_N' {
                    summarize time in `i', meanonly
                    local b = r(mean)
                    local a = `gcd'

                    while `b' != 0 {
                        local temp = mod(`a', `b')
                        local a = `b'
                        local b = `temp'
                    }

                    local gcd = `a'
                }
            }
        restore

        di as err "Error: slot duration (`slotd') is incompatible with episode durations."
        di as err "Some durations are not multiples of slotd()."
        di as txt "Recommended slot duration: `gcd'"
        *di as err "Example problematic values:"
        *list time if __mod != 0 & !missing(__mod) in 1/5

        drop __mod
        exit 0
    }

    drop __mod

    quietly {

        qui sum time
        replace time = time/`slotd'
        expand time
        sort `did' epnum
        drop epnum
        capture drop tslot
        bysort `did': gen tslot = _n
        capture drop time

        label define clock`dst' 0 "`mymacro':00", replace

        forvalues i = 1/1440 {
            local minutes = (`dst'*60-0) + `i'
            local hour = mod(floor(`minutes' / 60), 24)
            local min = mod(`minutes', 60)
            local time = string(`hour', "%02.0f") + ":" + string(`min', "%02.0f")
            label define clock`dst' `i' "`time'", modify
        }

        label define clock`dst' 0 "`: label clock`dst' 1440'", modify

        capture drop start
        gen start = (tslot*`slotd')-`slotd'
        label value start clock`dst'

        capture drop end
        gen end = tslot*`slotd'
        label value end clock`dst'

        capture drop clockst

        order `did' tslot start end
        sort `did' tslot

        lab var tslot "time slot"
        lab var start "start time of episode (minute of day)"
        lab var end "end time of episode (minute of day)"
    }

	* Success Message *
	bysort `did': gen __nslots = _N
	quietly summarize __nslots, meanonly
	local nslots = r(mean)
	qui drop __nslots
	di as txt "File successfully transformed into a calendar file."
	di as txt "Slots per diary: `nslots'. Slot duration: `slotd' minutes"

end







