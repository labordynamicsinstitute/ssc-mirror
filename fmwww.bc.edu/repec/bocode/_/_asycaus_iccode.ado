*! _asycaus_iccode v1.0.0  24may2026
*! Translates a textual IC name to the Mata engine's numeric code.
*! Internal helper for the asycaus suite.
*! Returns:  r(ic) -- 1=AIC 2=AICC 3=SBC/BIC 4=HQC/HQIC 5=HJC (default) 6=user
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define _asycaus_iccode, rclass
    args icname
    local lname = lower("`icname'")
    if "`lname'" == "aic"        local ic 1
    else if "`lname'" == "aicc"   local ic 2
    else if "`lname'" == "sbc"    local ic 3
    else if "`lname'" == "bic"    local ic 3
    else if "`lname'" == "hqc"    local ic 4
    else if "`lname'" == "hqic"   local ic 4
    else if "`lname'" == "hjc"    local ic 5
    else if "`lname'" == "hatemi" local ic 5
    else if "`lname'" == "user"   local ic 6
    else                          local ic 5
    return scalar ic = `ic'
end
