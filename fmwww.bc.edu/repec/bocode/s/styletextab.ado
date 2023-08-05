*! version 1.1  07jul2023  Gorkem Aksaray <aksarayg@tcd.ie>
*! Restyle LaTeX tables exported by the collect suite of commands
*! 
*! Changelog
*! ---------
*!   [1.1]
*!     - Allow for multiple paragraphs of text before and after table.
*!     - Added lipsum() and geometry() options.
*!   [1.0]
*!     - Initial public release.

capture program drop styletextab
program styletextab, rclass
    version 18
    syntax [using/] [, SAVing(string asis)                      ///
                       FRAGment TABLEonly LScape noBOOKtabs     ///
                       LABel(string)                            ///
                       BEFOREtext0(string) AFTERtext0(string)   ///
                       BEFOREtext1(string) AFTERtext1(string)   ///
                       BEFOREtext2(string) AFTERtext2(string)   ///
                       BEFOREtext3(string) AFTERtext3(string)   ///
                       BEFOREtext4(string) AFTERtext4(string)   ///
                       BEFOREtext5(string) AFTERtext5(string)   ///
                       BEFOREtext6(string) AFTERtext6(string)   ///
                       BEFOREtext7(string) AFTERtext7(string)   ///
                       BEFOREtext8(string) AFTERtext8(string)   ///
                       BEFOREtext9(string) AFTERtext9(string)   ///
                       geometry GEOMETRY2(string)               ///
                       lipsum LIPSUM2(string)                   ///
                    ]
    
    if `"`using'"' == "" {
        if `"`s(filename)'"' == "" {
            di as err "last TeX table from {bf: collect export} not found"
            exit 197
        }
        else {
            local using `"`s(filename)'"'
        }
    }
    
    if `"`saving'"' == "" {
        local saving `"`using'"'
        local replace "replace"
    }
    else if `"`saving'"' != "" {
        local _using `"`using'"' // protect main `using'
        local 0 `"using `saving'"'
        syntax using/ [, replace]
        local saving `"`using'"'
        local replace "`replace'"
        local using `"`_using'"'
    }
    
    mata: suffix = subinstr(pathsuffix(`"`using'"'), ".", "")
    mata: st_local("suffix", suffix)
    
    if `"`suffix'"' == "" {
        local suffix "tex"
        local using `"`using'.`suffix'"'
    }
    else if `"`suffix'"' != "tex" {
        di as err "{p 0 0 2}"
        di as err "incorrect file type specified"
        di as err "in {bf:using};"
        di as err "only .tex files allowed"
        di as err "{p_end}"
        exit 198
    }
    
    mata: suffix = subinstr(pathsuffix(`"`saving'"'), ".", "")
    mata: st_local("suffix", suffix)
    
    if `"`suffix'"' == "" {
        local suffix "tex"
        local saving `"`saving'.`suffix'"'
    }
    else if `"`suffix'"' != "tex" {
        di as err "{p 0 0 2}"
        di as err "incorrect file type specified"
        di as err "in {bf:saving()};"
        di as err "only .tex files allowed"
        di as err "{p_end}"
        exit 198
    }
    
    confirm file `"`using'"'
    
    tempname fh
    tempname tf
    tempfile tmp
    file open `fh' using `"`using'"', read
    file open `tf' using `"`tmp'"', write
    
    if "`fragment'" == "" {
    if "`tableonly'" == "" {
    
    * preamble
    file write `tf' "\documentclass{article}" _n
    if "`geometry'`geometry2'" != "" {
        file write `tf' "\usepackage[`geometry2']{geometry}" _n
    }
    if "`lscape'" != "" {
        file write `tf' "\usepackage{pdflscape}" _n
    }
    if "`booktabs'" != "nobooktabs" {
        file write `tf' "\usepackage{booktabs}" _n
    }
    file write `tf' "\usepackage{multirow}" _n
    file write `tf' "\usepackage[para,flushleft]{threeparttable}" _n
    file write `tf' "\usepackage{amsmath}" _n
    file write `tf' "\usepackage{ulem}" _n
    file write `tf' "\usepackage[table]{xcolor}" _n
    if "`lipsum'`lipsum2'" != "" {
        file write `tf' "\usepackage[`lipsum2']{lipsum}" _n
    }
    
    file write `tf' "\begin{document}" _n
    
    * beforetext
    if "`beforetext0'" != "" {
        forvalues i = 0/9 {
            if "`beforetext`i''" != "" {
                file write `tf' _n "`beforetext`i''" _n
            }
        }
        file write `tf' _n
    }
    
    } // tableonly
    if "`lscape'" != "" {
        file write `tf' "\begin{landscape}" _n
    }
    file write `tf' "\begin{table}[!h]" _n
    
    * caption
    file seek `fh' tof
    file read `fh' line
    while r(eof) == 0 {
        if strpos(`"`macval(line)'"', "\caption") != 0 {
            file write `tf' `"`macval(line)'"' _n
            if "`label'" != "" {
                file write `tf' "\label{`label'}" _n
            }
        }
        else if `"`macval(line)'"' == "\centering" {
            file write `tf' `"`macval(line)'"' _n
            file seek `fh' eof
        }
        file read `fh' line
    }
    
    file write `tf' "\begin{threeparttable}" _n
    
    } // fragment
    
    * tabular
    file seek `fh' tof
    file read `fh' line
    local keepline = 0
    while r(eof) == 0 {
        if strpos(`"`macval(line)'"', "\begin{tabular}") != 0 {
            local keepline = 1
        }
        if `keepline' == 1 {
            if "`booktabs'" == "nobooktabs" & strpos(`"`macval(line)'"', "\cmidrule") != 0 {
                local newline = subinstr(`"`macval(line)'"', "\cmidrule", "\cline", .)
                file write `tf' `"`newline'"' _n
            }
            else if "`booktabs'" != "nobooktabs" & strpos(`"`macval(line)'"', "\cline") != 0 {
                local newline = subinstr(`"`macval(line)'"', "\cline", "\cmidrule", .)
                file write `tf' `"`newline'"' _n
            }
            else {
                file write `tf' `"`macval(line)'"' _n
            }
        }
        if strpos(`"`macval(line)'"', "\end{tabular}") != 0 {
            local keepline = 0
        }
        file read `fh' line
    }
    
    if "`fragment'" == "" {
    
    file write `tf' "\begin{tablenotes}" _n
    
    * footnotes
    file seek `fh' tof
    file read `fh' line
    local keepline = 0
    while r(eof) == 0 {
        if `"`macval(line)'"' == "\footnotesize{" {
            local keepline = 1
        }
        if `keepline' == 1 {
            file write `tf' `"`macval(line)'"' _n
        }
        if `"`macval(line)'"' == "}" {
            local keepline = 0
        }
        file read `fh' line
    }
    
    file write `tf' "\end{tablenotes}" _n
    file write `tf' "\end{threeparttable}" _n
    file write `tf' "\end{table}" _n
    if "`lscape'" != "" {
        file write `tf' "\end{landscape}" _n
    }
    
    if "`tableonly'" == "" {
    
    * aftertex
    if "`aftertext0'" != "" {
        forvalues i = 0/9 {
            if "`aftertext`i''" != "" {
                file write `tf' _n "`aftertext`i''" _n
            }
        }
        file write `tf' _n
    }
    
    file write `tf' "\end{document}" _n
    
    } // tableonly
    } // fragment
    
    file close `fh'
    file close `tf'
    
    copy `"`tmp'"' `"`saving'"', `replace'
    mata: st_local("basename", pathbasename(`"`saving'"'))
    di as txt `"(LaTeX table saved to file {browse `"`saving'"':`basename'})"'
end
