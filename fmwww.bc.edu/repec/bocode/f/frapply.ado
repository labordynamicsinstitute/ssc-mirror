*! version 1.01  31jan2022  Gorkem Aksaray <gaksaray@ku.edu.tr>
*!
*! Syntax
*! ------
*!   frapply [framename1] [if] [in] [, into(framename2, [replace CHange]) QUIetly]
*!           [: commandlist]
*!
*!   where the syntax of commandlist is
*!
*!     command [ || command [ || command [...]]]
*!
*!   and comand is any Stata command.
*!
*! Changelog
*! ---------
*!   [1.01]
*!     - Using an if expression on a non-current frame was causing an error.
*!       This is now fixed.
*!   [1.0]
*!     - Initial SSC release.

capture program drop frapply
program define frapply
    version 16.0
    
    // parse prefix and command(s)
    gettoken prefix command : 0, parse(":")
    if "`prefix'" == ":" {
        local prefix ""
    }
    else {
        gettoken colon command : command , parse(":")
    }
    parse_prefix `prefix'
    local retlist "from if in intoname intoreplace intochange quietly"
    foreach ret of local retlist {
        capture local `ret' "`r(`ret')'"
    }
    
    // from frame check
    if "`from'" != "" {
        confirm frame `from'
        local cframe "`from'"
    }
    else {
        local cframe = c(frame)
    }
    
    // into frame check
    if "`intoname'" == "" {
        tempname tempframe
        local intoname "`tempframe'"
    }
    if "`intoname'" == "`cframe'" {
        display as error "into() option may not specify the applied frame"
        exit 198
    }
    if "`intoreplace'" == "" {
        confirm new frame `intoname'
    }
    
    // multiple command check
    local cmdchk `"`command'"'
    while `"`cmdchk'"' != "" {
        gettoken cmd cmdchk : cmdchk, parse("|")
        if `"`cmd'"' == "|" {
            if substr(`"`cmdchk'"', 1, 1) == "|" {
                gettoken cmd cmdchk : cmdchky, parse("|")
                continue
            }
            else {
                noisily display as error "| invalid command"
                exit 198
            }
        }
    }
    
    // run command(s)
    frame `cframe' {
        preserve
        quietly capture keep `in' `if'
        while `"`command'"' != "" {
            gettoken cmd command : command, parse("|")
            if `"`cmd'"' == "|" continue
            `quietly' `cmd'
        }
        frput, into(`intoname') `intoreplace'
        restore
    }
    capture frame `intochange' `intoname'
end

capture program drop parse_prefix
program define parse_prefix, rclass
    version 16.0
    gettoken from 0 : 0
    capture confirm frame `from'
    if !_rc frame `from' {
        syntax [if] [in] [, into(string asis) QUIetly]
    }
    else {
        local 0 "`from' `0'"
        syntax [name(name=from)] [if] [in] [, into(string asis) QUIetly]
    }
    
    return local from "`from'"
    return local if "`if'"
    return local in "`in'"
    
    capture parse_into `into'
    if _rc {
        display as error `"Illegal into option: `into'"'
        exit 198
    }
    return local intoname "`r(name)'"
    return local intoreplace "`r(replace)'"
    return local intochange "`r(change)'"
    
    return local quietly "`quietly'"
end

capture program drop parse_into
program define parse_into, rclass
    version 16.0
    syntax [name(name=name)] [, replace CHange]
    
    return local name "`name'"
    return local change "`change'"
    return local replace "`replace'"
end

capture program drop frput
program frput
    version 16.0
    syntax [varlist] [if] [in], into(name local) [replace]

    tempname tmpframe
    frame put `varlist' `if' `in', into(`tmpframe')
    frame copy `tmpframe' `into', `replace'

end
