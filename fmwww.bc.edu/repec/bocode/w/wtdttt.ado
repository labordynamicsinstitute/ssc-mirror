*! 0.1 HS, Nov 11, 2015
*! 0.2 HS, Mar 16, 2016
*! 0.3 HS, Aug 30, 2016

pr define wtdttt, rclass
version 14.0

syntax varname [if] [in], ///
    DISTtype(string) ///
    [IADPercentile(real 0.8) ///
     start(string) end(string) ///
     LOGITPcovar(varlist fv) ///
     MUcovar(varlist fv) LNSIGMAcovar(varlist fv) ///
     LNALPHAcovar(varlist fv) LNBETAcovar(varlist fv) ///
                         ALLcovar(varlist fv) ///
                         eform(passthru) delta(real 1) reverse ///
                                                       *]
qui {
preserve
tokenize `varlist'
local obstime `1'

tempname resmat covarmat prevpr seprev timeperc setimeperc ///
         logtimeperc beta mu sigma alpha

local fmtperc = strofreal(`iadpercentile' * 100, "%2.0f")

if ("`start'" != "" & "`end'" == "") | ("`start'" == "" & "`end'" != "") {
    di in red "If you specify -start()- or -end() you must specify both"
    error 119
}
if ("`start'" != "" & "`end'" != "") {
    local delta = (td(`end') - td(`start')) + 1
    if "`reverse'" != "" {
        replace `obstime' = td(`end') + .5 - `obstime'
    }
    else {
        replace `obstime' = `obstime' - (d(`start') - .5)
    }
    local tstart = td(`start') - .5
    local tend = td(`end') + .5
}
else {
    local tstart = 0
    local tend = `delta'
    if "`reverse'" != "" {
        replace `obstime' = `tend' - `obstime'
    }
}    
global wtddelta = `delta'

* Exponential FRD
if "`disttype'" == "exp" {
    noi ml model lf mlwtd_exp ///
        (logitp: `obstime' = `logitpcovar' `allcovar') ///
        (lnbeta: `lnbetacovar' `allcovar') `if' `in', ///
            max `options'
    if "`eform'" != "" {
        seteform, kexpo(2)
    }
    noi ml display, `eform'

    if "`nlcomoff'" == "" {
        noi nlcom (prevfrac: invlogit([logitp]_b[_cons])) ///
            (iadperc`fmtperc': - log(1 - `iadpercentile') ///
                    / exp([lnbeta]_b[_cons])) ///
            (logiadperc`fmtperc': log(- log(1 - `iadpercentile')) ///
                       - [lnbeta]_b[_cons])
     }
}

* Log-Normal FRD
if "`disttype'" == "lnorm" {
    noi ml model lf mlwtd_lnorm ///
        (logitp: `obstime' = `logitpcovar' `allcovar') ///
        (mu: `mucovar' `allcovar') ///
        (lnsigma: `lnsigmacovar' `allcovar') `if' `in', ///
    `options' max
    if "`eform'" != "" {
        seteform, kexpo(3)
    }
    noi ml display, `eform'

    if "`nlcomoff'" == "" {
        noi nlcom (prevfrac: invlogit([logitp]_b[_cons])) ///
        (iadperc`fmtperc': exp(invnormal(`iadpercentile') ///
                      * exp([lnsigma]_b[_cons]) + [mu]_b[_cons])) ///
        (logiadperc`fmtperc': invnormal(`iadpercentile') ///
                      * exp([lnsigma]_b[_cons]) + [mu]_b[_cons])
    }
}

* Weibull FRD
if "`disttype'" == "wei" {
    noi ml model lf mlwtd_wei ///
        (logitp: `obstime' = `logitpcovar' `allcovar') ///
        (lnbeta: `lnbetacovar' `allcovar') ///
        (lnalpha: `lnalphacovar' `allcovar') `if' `in', ///
                max
    if "`eform'" != "" {
        seteform, kexpo(3)
    }
    noi ml display, `eform'

    mat `resmat' = e(b)
    mat `covarmat' = e(V)

    if "`nlcomoff'" == "" {
        noi nlcom (prevfrac: invlogit([logitp]_b[_cons])) ///
        (iadperc`fmtperc': ///
                (- log(1 - `iadpercentile'))^(1 / exp([lnalpha]_b[_cons])) ///
                                             / exp([lnbeta]_b[_cons])) ///
        (logiadperc`fmtperc': ///
                log(- log(1 - `iadpercentile')) ///
                    * (1 / exp([lnalpha]_b[_cons])) ///
                    - [lnbeta]_b[_cons])
    }
}

mat `resmat' = r(b)
mat `covarmat' = r(V)

scalar `prevpr' = `resmat'[1, 1]
scalar `seprev' = sqrt(`covarmat'[1, 1])

scalar `timeperc' = `resmat'[1, 2]
scalar `setimeperc' = sqrt(`covarmat'[2, 2])
scalar `logtimeperc' = log(`timeperc')
return scalar logtimeperc = `logtimeperc'
return scalar timepercentile = `timeperc'
return scalar setimepercentile = `setimeperc'
return scalar prevprop = `prevpr'
return scalar seprev = `seprev'
return local disttype `disttype'
return local reverse "`reverse'"
return scalar delta = `delta'
return scalar start = `tstart'
return scalar end = `tend'

}
end

program seteform, eclass
syntax, kexpo(integer)
ereturn scalar k_eform = `kexpo'
end
