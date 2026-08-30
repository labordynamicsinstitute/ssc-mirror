*! texpdf_run 0.1.0 26aug2026
*! Run named examples embedded in texpdf.sthlp.
program define texpdf_run
    version 18

    syntax anything(name=example_name id="example name") using/ [, PRESERVE]

    capture confirm file `"`using'"'
    if _rc {
        findfile `"`using'"'
        local helpfile `"`r(fn)'"'
    }
    else local helpfile `"`using'"'

    if "`preserve'" != "" preserve

    quietly infix str s 1-244 using `"`helpfile'"', clear
    quietly generate long obs = _n

    quietly count if strpos(s, "{* example_start - `example_name'}{...}")
    local starts = r(N)
    if `starts' != 1 {
        if "`preserve'" != "" restore
        if `starts' == 0 display as error "example `example_name' not found"
        else display as error "example `example_name' has duplicate start markers"
        exit 111
    }

    quietly summarize obs if strpos(s, ///
        "{* example_start - `example_name'}{...}"), meanonly
    local pos1 = r(min) + 1
    quietly count if strpos(s, "{* example_end}{...}") & obs >= `pos1'
    local ends = r(N)
    if `ends' == 0 {
        if "`preserve'" != "" restore
        display as error "example `example_name' has no end marker"
        exit 111
    }
    quietly summarize obs if strpos(s, "{* example_end}{...}") & ///
        obs >= `pos1', meanonly
    local pos2 = r(min) - 1

    quietly keep in `pos1'/`pos2'
    quietly replace s = subinstr(s, "{c -(}", "{", .)
    quietly replace s = subinstr(s, "{c )-}", "}", .)
    quietly replace s = regexr(trim(s), "}{...}", "") if ///
        substr(s, 1, 3) == "{* "
    quietly replace s = substr(s, 4, .) if substr(s, 1, 3) == "{* "

    tempfile example_do
    quietly outfile s using `"`example_do'"', noquote

    capture noisily do `"`example_do'"'
    local example_rc = _rc
    if "`preserve'" != "" restore
    if `example_rc' exit `example_rc'
end
