*! _mixi12_pretty 1.0.0  21may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*  Internal helper - print a clean SMCL table.  The table is bordered with
*  horizontal hlines; columns are tab-separated within {col} markers.
*  No references / notes printed below; only the body and a single trailing
*  hline.

program define _mixi12_pretty
    version 14
    syntax , Title(string) [             ///
        Width(integer 78)                ///
        HEADer(string asis)              ///
        ROWS(string asis)                ///
        FOOTer(string asis)              ///
        ]

    local w = `width'
    di
    di as text "{hline `w'}"
    di as text _col(2) "{bf:`title'}"
    di as text "{hline `w'}"
    if `"`header'"' != "" {
        di as text `"`header'"'
        di as text "{hline `w'}"
    }
    local nrows : word count `rows'
    if `"`rows'"' != "" {
        foreach r of local rows {
            di as result `"`r'"'
        }
        di as text "{hline `w'}"
    }
    if `"`footer'"' != "" {
        di as text `"`footer'"'
        di as text "{hline `w'}"
    }
end
