*! boundeduroot v1.0.0  Merwan Roudane  07jul2026
*! Bounded unit-root & structural-break tests -- a library
*! Companion to the boundedur (Cavaliere-Xu 2014) package, implementing the
*! Carrion-i-Silvestre & Gadea family of bounded tests:
*!   boundeduroot mtests <var> , ...  GLS M-tests for bounded series      (2013)
*!   boundeduroot breaks <var> , ...  bounds + structural breaks          (2016)
*!   boundeduroot hlt    <var> , ...  HLT multiple level-shift detection  (2024)
*! github.com/merwanroudane  --  merwanroudane920@gmail.com

program define boundeduroot, rclass
    version 14.0

    gettoken sub rest : 0, parse(" ,")
    local sub = lower("`sub'")

    if "`sub'" == "mtests" {
        local 0 `"`rest'"'
        boundeduroot_mtests `0'
    }
    else if "`sub'" == "breaks" {
        local 0 `"`rest'"'
        boundeduroot_breaks `0'
    }
    else if "`sub'" == "hlt" {
        local 0 `"`rest'"'
        boundeduroot_hlt `0'
    }
    else {
        di as error "unknown or missing subcommand: `sub'"
        di as text  "Use one of: {bf:mtests}, {bf:breaks}, {bf:hlt}."
        di as text  "See {help boundeduroot}."
        exit 198
    }
    return add
end
