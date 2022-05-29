*! version 1.1.2  27apr2022  Gorkem Aksaray <gaksaray@ku.edu.tr>
*!
*! Syntax
*! ------
*!   frapply [framename1] [if] [in] [, into(framename2, [replace CHange]) QUIetly]
*!           [: commandlist]
*!
*!   where the syntax of commandlist is
*!
*!     command [ |> command [ |> command [...]]]
*!
*!   and comand is any Stata command.
*!
*! Changelog
*! ---------
*!   [1.1.2]
*!     - Revised parsing of command list again to allow for "empty pipes".
*!       The command list can now start with |>, end with |>, and have
*!       consecutive |>'s with nothing in between. frapply is now robust to
*!       those "errors".
*!   [1.1.1]
*!     - Rewrote parsing of command list to allow for protected locals
*!       while also allowing for | and > characters within the individual
*!       commands.
*!   [1.1.0]
*!     - Changed the 'pipe' operator from "||" to "|>" as in R language.
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
    
    // run command(s)
    frame `cframe' {
        preserve
        quietly capture keep `in' `if'
        
        while `"`command'"' != "" {
            gettoken part command : command, parse("|")
            if `"`part'"' == "|" & substr(`"`command'"', 1, 1) == ">" {
                gettoken part command : command, parse(">")
                local part ""
            }
            if substr(`"`command'"', 1, 2) == "|>" | `"`command'"' == "" {
                gettoken sep command : command, parse("|")
                gettoken sep command : command, parse(">")
                `quietly' `cmd' `part'
                local cmd ""
            }
            else {
                local cmd `"`cmd' `part'"'
            }
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
