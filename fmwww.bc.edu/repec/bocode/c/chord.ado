*! chord 1.0.0  09jul2026
*! draw chord diagrams
*! Authors: Jiajun Zhou (Technical University of Munich, zhoujiajun_06@163.com)
*!          De Zhou (Nanjing Agricultural University, zhou-de@hotmail.com)

capture program drop _chordcomma_check
program define _chordcomma_check
    args optname optval
    if strpos(`"`optval'"', ",") > 0 {
        di as result "Note: `optname'() uses space-separated items, not commas; a comma was detected and may not produce the intended result."
        di as result "提示：`optname'() 使用空格分隔各项，不是逗号；检测到逗号，可能不是预期效果。"
    }
end

capture program drop _chordsize_check
program define _chordsize_check, rclass
    args val
    local kwlist "tiny vsmall small medsmall medium medlarge large vlarge huge"
    local isnum = 0
    capture confirm number `val'
    if _rc == 0 local isnum = 1
    local iskw = 0
    foreach k of local kwlist {
        if "`val'" == "`k'" local iskw = 1
    }
    return scalar ok = (`isnum' == 1 | `iskw' == 1)
end

capture program drop _chordcolor_parse
program define _chordcolor_parse, rclass
    args usercol hexchars
    if `"`usercol'"' == "" {
        exit 0
    }

    local pctpos = strpos(`"`usercol'"', "%")
    if `pctpos' > 0 {
        local alphapart = substr(`"`usercol'"', `pctpos'+1, .)
        local usercol    = substr(`"`usercol'"', 1, `pctpos'-1)
        return local parsedalpha "`alphapart'"
    }
    else {
        return local parsedalpha ""
    }

    if `"`usercol'"' == "" {
        exit 0
    }
    else if substr(`"`usercol'"',1,1) == "#" {
        local hexbody = upper(substr(`"`usercol'"',2,.))
        local hexlen = strlen(`"`hexbody'"')
        if `hexlen' == 6 {
            local r1 = strpos("`hexchars'", substr(`"`hexbody'"',1,1)) - 1
            local r2 = strpos("`hexchars'", substr(`"`hexbody'"',2,1)) - 1
            local g1 = strpos("`hexchars'", substr(`"`hexbody'"',3,1)) - 1
            local g2 = strpos("`hexchars'", substr(`"`hexbody'"',4,1)) - 1
            local b1 = strpos("`hexchars'", substr(`"`hexbody'"',5,1)) - 1
            local b2 = strpos("`hexchars'", substr(`"`hexbody'"',6,1)) - 1
            local rdec = `r1'*16 + `r2'
            local gdec = `g1'*16 + `g2'
            local bdec = `b1'*16 + `b2'
            return local parsedcolor "`rdec' `gdec' `bdec'"
        }
        else if `hexlen' == 3 {
            local r1 = strpos("`hexchars'", substr(`"`hexbody'"',1,1)) - 1
            local g1 = strpos("`hexchars'", substr(`"`hexbody'"',2,1)) - 1
            local b1 = strpos("`hexchars'", substr(`"`hexbody'"',3,1)) - 1
            local rdec = `r1'*16 + `r1'
            local gdec = `g1'*16 + `g1'
            local bdec = `b1'*16 + `b1'
            return local parsedcolor "`rdec' `gdec' `bdec'"
        }
        else {
            di as error "Color `usercol' is not a valid hex code (expected #RRGGBB or #RGB). (颜色 `usercol' 不是合法的hex格式，应为#RRGGBB或#RGB。)"
            exit 198
        }
    }
    else if strpos(`"`usercol'"',",") > 0 {
        local tmp : subinstr local usercol "," " ", all
        return local parsedcolor `"`tmp'"'
    }
    else {
        return local parsedcolor `"`usercol'"'
    }
end

capture program drop _chordtitle_splitcomma
program define _chordtitle_splitcomma, rclass
    * Find the first comma at brace depth 0 and outside double-quoted text;
    * it separates the text part from the textbox sub-options, so commas
    * inside quoted literals or {braces} are never mistaken for the separator.
    * NOTE: characters are compared via inline substr() expressions instead of
    * storing a single character in a local and re-quoting it -- if the scanned
    * character happens to be a double quote, the "store then re-quote" pattern
    * creates three adjacent quotes and Stata raises "too few quotes".
    * 中文说明：逐字符扫描时直接用substr()表达式比较，不先存入宏再包引号比较；
    * 否则当扫描到的字符本身是双引号时会产生三引号歧义，导致"too few quotes"报错。
    local rawtext `"`0'"'
    local depth = 0
    local inquote = 0
    local n = strlen(`"`rawtext'"')
    local splitpos = 0
    forvalues p = 1/`n' {
        if substr(`"`rawtext'"', `p', 1) == char(34) local inquote = 1 - `inquote'
        if substr(`"`rawtext'"', `p', 1) == "{" & `inquote' == 0 local depth = `depth' + 1
        if substr(`"`rawtext'"', `p', 1) == "}" & `inquote' == 0 local depth = `depth' - 1
        if substr(`"`rawtext'"', `p', 1) == "," & `depth' == 0 & `inquote' == 0 & `splitpos' == 0 {
            local splitpos = `p'
        }
    }
    return scalar pos = `splitpos'
end

capture program drop _chordpairopt_split
program define _chordpairopt_split, rclass
    * Split "A-B: opts" into sectorA / sectorB / opts, using the first ":"
    * as the boundary between the sector pair and the sub-options.
    local rawtext `0'
    local cpos = strpos(`"`rawtext'"', ":")
    if `cpos' == 0 {
        return scalar ok = 0
        exit 0
    }
    local pairpart = substr(`"`rawtext'"', 1, `cpos'-1)
    local optspart = substr(`"`rawtext'"', `cpos'+1, .)
    local optspart = strtrim(`"`optspart'"')

    local sep = strpos(`"`pairpart'"', "-")
    if `sep' == 0 {
        return scalar ok = 0
        exit 0
    }
    local sA = strtrim(substr(`"`pairpart'"', 1, `sep'-1))
    local sB = strtrim(substr(`"`pairpart'"', `sep'+1, .))

    return local sectorA `"`sA'"'
    return local sectorB `"`sB'"'
    return local opts    `"`optspart'"'
    return scalar ok = 1
end

capture program drop _chordsplit_toplevel
program define _chordsplit_toplevel, rclass
    * Split the text into segments at commas that sit at parenthesis depth 0,
    * so commas inside sub-option parentheses are never treated as separators.
    local rawtext `0'
    local depth = 0
    local n = strlen(`"`rawtext'"')
    local startpos = 1
    local nseg = 0
    forvalues p = 1/`n' {
        local ch = substr(`"`rawtext'"', `p', 1)
        if `"`ch'"' == "(" local depth = `depth' + 1
        if `"`ch'"' == ")" local depth = `depth' - 1
        if `"`ch'"' == "," & `depth' == 0 {
            local seg = substr(`"`rawtext'"', `startpos', `p'-`startpos')
            local nseg = `nseg' + 1
            return local seg`nseg' `"`seg'"'
            local startpos = `p' + 1
        }
    }
    local seg = substr(`"`rawtext'"', `startpos', .)
    local nseg = `nseg' + 1
    return local seg`nseg' `"`seg'"'
    return scalar nseg = `nseg'
end

capture program drop _chordfont_split
program define _chordfont_split, rclass
    * Split the label into a per-character list of (character, font):
    * text outside {fontface "X":...} tags uses deffont; text inside a tag
    * uses the tagged font X, character by character.  A label may thus mix
    * several font tags, and each character keeps its own font when placed
    * one by one in curved mode.
    * 中文说明：把标签拆成"字符+对应字体"列表；无标签部分用默认字体，
    * {fontface "X":...} 包裹部分逐字符用字体X，curved模式逐字摆放时字体不丢。
    args rawtext deffont
    local remaining `"`rawtext'"'
    local nch = 0
    while `"`remaining'"' != "" {
        local tagstr `"{fontface ""'
        local openpos = strpos(`"`remaining'"', `"`tagstr'"')
        if `openpos' == 0 {
            local plainlen = ustrlen(`"`remaining'"')
            forvalues p = 1/`plainlen' {
                local nch = `nch' + 1
                local onechar = usubstr(`"`remaining'"', `p', 1)
                return local char`nch' `"`onechar'"'
                return local font`nch' `"`deffont'"'
            }
            local remaining ""
        }
        else {
            if `openpos' > 1 {
                local plaintext = substr(`"`remaining'"', 1, `openpos'-1)
                local plainlen = ustrlen(`"`plaintext'"')
                forvalues p = 1/`plainlen' {
                    local nch = `nch' + 1
                    local onechar = usubstr(`"`plaintext'"', `p', 1)
                    return local char`nch' `"`onechar'"'
                    return local font`nch' `"`deffont'"'
                }
            }
            local afteropen = substr(`"`remaining'"', `openpos' + strlen(`"`tagstr'"'), .)
            local closequote = strpos(`"`afteropen'"', `"""')
            if `closequote' == 0 {
                local plaintext `"`afteropen'"'
                local plainlen = ustrlen(`"`plaintext'"')
                forvalues p = 1/`plainlen' {
                    local nch = `nch' + 1
                    local onechar = usubstr(`"`plaintext'"', `p', 1)
                    return local char`nch' `"`onechar'"'
                    return local font`nch' `"`deffont'"'
                }
                local remaining ""
            }
            else {
                local fontname = substr(`"`afteropen'"', 1, `closequote'-1)
                local aftercolon = substr(`"`afteropen'"', `closequote'+1, .)
                if substr(`"`aftercolon'"',1,1) == ":" local aftercolon = substr(`"`aftercolon'"', 2, .)
                local closebrace = strpos(`"`aftercolon'"', "}")
                if `closebrace' == 0 {
                    local content `"`aftercolon'"'
                    local remaining ""
                }
                else {
                    local content = substr(`"`aftercolon'"', 1, `closebrace'-1)
                    local remaining = substr(`"`aftercolon'"', `closebrace'+1, .)
                }
                local contentlen = ustrlen(`"`content'"')
                forvalues p = 1/`contentlen' {
                    local nch = `nch' + 1
                    local onechar = usubstr(`"`content'"', `p', 1)
                    return local char`nch' `"`onechar'"'
                    return local font`nch' `"`fontname'"'
                }
            }
        }
    }
    return scalar nch = `nch'
end

capture program drop _chordfont_splitseg
program define _chordfont_splitseg, rclass
    * Like _chordfont_split (handles {fontface "X":...} tags), but splits the
    * label into SEGMENTS instead of single characters: consecutive narrow
    * characters (Latin letters, digits, half-width symbols; UTF-8 length <= 2)
    * are merged into one segment and rendered natively, so Western text keeps
    * its natural letter spacing; each wide character (CJK/full-width; UTF-8
    * length >= 3) still forms its own segment, so per-character curved
    * placement is unchanged for CJK.  Narrow segments do not merge across
    * {fontface} tag boundaries (at most one extra tiny segment appears there).
    * 中文说明："中文逐字、西文连排"——窄字符连排成段整体渲染，宽字符仍逐字成段；
    * 窄字符段不跨fontface标签边界合并。
    args rawtext deffont
    local remaining `"`rawtext'"'
    local nseg = 0
    local buf ""
    local buffont ""

    while `"`remaining'"' != "" {
        local tagstr `"{fontface ""'
        local openpos = strpos(`"`remaining'"', `"`tagstr'"')
        if `openpos' == 0 {
            local plainlen = ustrlen(`"`remaining'"')
            forvalues p = 1/`plainlen' {
                local onechar = usubstr(`"`remaining'"', `p', 1)
                if strlen(`"`onechar'"') <= 2 {
                    local buf `"`buf'`onechar'"'
                    local buffont `"`deffont'"'
                }
                else {
                    if `"`buf'"' != "" {
                        local nseg = `nseg' + 1
                        return local segtext`nseg' `"`buf'"'
                        return local segfont`nseg' `"`buffont'"'
                        return local segwide`nseg' 0
                        local buf ""
                    }
                    local nseg = `nseg' + 1
                    return local segtext`nseg' `"`onechar'"'
                    return local segfont`nseg' `"`deffont'"'
                    return local segwide`nseg' 1
                }
            }
            if `"`buf'"' != "" {
                local nseg = `nseg' + 1
                return local segtext`nseg' `"`buf'"'
                return local segfont`nseg' `"`buffont'"'
                return local segwide`nseg' 0
                local buf ""
            }
            local remaining ""
        }
        else {
            if `openpos' > 1 {
                local plaintext = substr(`"`remaining'"', 1, `openpos'-1)
                local plainlen = ustrlen(`"`plaintext'"')
                forvalues p = 1/`plainlen' {
                    local onechar = usubstr(`"`plaintext'"', `p', 1)
                    if strlen(`"`onechar'"') <= 2 {
                        local buf `"`buf'`onechar'"'
                        local buffont `"`deffont'"'
                    }
                    else {
                        if `"`buf'"' != "" {
                            local nseg = `nseg' + 1
                            return local segtext`nseg' `"`buf'"'
                            return local segfont`nseg' `"`buffont'"'
                            return local segwide`nseg' 0
                            local buf ""
                        }
                        local nseg = `nseg' + 1
                        return local segtext`nseg' `"`onechar'"'
                        return local segfont`nseg' `"`deffont'"'
                        return local segwide`nseg' 1
                    }
                }
                if `"`buf'"' != "" {
                    local nseg = `nseg' + 1
                    return local segtext`nseg' `"`buf'"'
                    return local segfont`nseg' `"`buffont'"'
                    return local segwide`nseg' 0
                    local buf ""
                }
            }
            local afteropen = substr(`"`remaining'"', `openpos' + strlen(`"`tagstr'"'), .)
            local closequote = strpos(`"`afteropen'"', `"""')
            if `closequote' == 0 {
                local plaintext `"`afteropen'"'
                local plainlen = ustrlen(`"`plaintext'"')
                forvalues p = 1/`plainlen' {
                    local onechar = usubstr(`"`plaintext'"', `p', 1)
                    if strlen(`"`onechar'"') <= 2 {
                        local buf `"`buf'`onechar'"'
                        local buffont `"`deffont'"'
                    }
                    else {
                        if `"`buf'"' != "" {
                            local nseg = `nseg' + 1
                            return local segtext`nseg' `"`buf'"'
                            return local segfont`nseg' `"`buffont'"'
                            return local segwide`nseg' 0
                            local buf ""
                        }
                        local nseg = `nseg' + 1
                        return local segtext`nseg' `"`onechar'"'
                        return local segfont`nseg' `"`deffont'"'
                        return local segwide`nseg' 1
                    }
                }
                if `"`buf'"' != "" {
                    local nseg = `nseg' + 1
                    return local segtext`nseg' `"`buf'"'
                    return local segfont`nseg' `"`buffont'"'
                    return local segwide`nseg' 0
                    local buf ""
                }
                local remaining ""
            }
            else {
                local fontname = substr(`"`afteropen'"', 1, `closequote'-1)
                local aftercolon = substr(`"`afteropen'"', `closequote'+1, .)
                if substr(`"`aftercolon'"',1,1) == ":" local aftercolon = substr(`"`aftercolon'"', 2, .)
                local closebrace = strpos(`"`aftercolon'"', "}")
                if `closebrace' == 0 {
                    local content `"`aftercolon'"'
                    local remaining ""
                }
                else {
                    local content = substr(`"`aftercolon'"', 1, `closebrace'-1)
                    local remaining = substr(`"`aftercolon'"', `closebrace'+1, .)
                }
                local contentlen = ustrlen(`"`content'"')
                forvalues p = 1/`contentlen' {
                    local onechar = usubstr(`"`content'"', `p', 1)
                    if strlen(`"`onechar'"') <= 2 {
                        local buf `"`buf'`onechar'"'
                        local buffont `"`fontname'"'
                    }
                    else {
                        if `"`buf'"' != "" {
                            local nseg = `nseg' + 1
                            return local segtext`nseg' `"`buf'"'
                            return local segfont`nseg' `"`buffont'"'
                            return local segwide`nseg' 0
                            local buf ""
                        }
                        local nseg = `nseg' + 1
                        return local segtext`nseg' `"`onechar'"'
                        return local segfont`nseg' `"`fontname'"'
                        return local segwide`nseg' 1
                    }
                }
                if `"`buf'"' != "" {
                    local nseg = `nseg' + 1
                    return local segtext`nseg' `"`buf'"'
                    return local segfont`nseg' `"`buffont'"'
                    return local segwide`nseg' 0
                    local buf ""
                }
            }
        }
    }
    return scalar nseg = `nseg'
end

capture program drop chord
program define chord, rclass
    version 15.0

    syntax varlist(min=2) [if] [in] [, ///
          ADJMATRIX                           ///
          COLSECTORS(string)                  ///
          SECTORORDER(string)                 ///
          SECTORGROUP(string)                 ///
          GROUPGAP(real -1)                   ///
          SCALE                               ///
          SECTORSCALEOVERRIDE(string)         ///
          WITHINGAPOVERRIDE(string)           ///
          LINKSORT(string)                    ///
          PRIORITYPAIRS(string)               ///
          NITER(integer 6)                    ///
          COUNTERCLOCKWISE                    ///
          STARTANGLE(real 0)                  ///
          SPLITHORIZONTAL                     ///
          TICKS                               ///
          TICKDIR(string)                     ///
          TICKLABDIR(string)                  ///
          TICKLEN(real 0.02)                  ///
          TICKLABSIZE(string)                 ///
          TICKCOLOR(string)                   ///
          TICKLABCOLOR(string)                ///
          MINORTICKS(integer 5)               ///
          TICKSTEP(real -1)                   ///
          TICKSTEPOVERRIDE(string)            ///
          MINORTICKSOVERRIDE(string)          ///
          AXISARCRES(integer 40)              ///
          TICKTOPFLIP                         ///
          TICKBOTTOMFLIP                      ///
          TICKSIDE(string)                    ///
          TICKGAP(real 0.01)                  ///
          MINORLEN(real -1)                   ///
          AXISLWIDTH(string)                  ///
          TICKLWIDTH(string)                  ///
          MINORLWIDTH(string)                 ///
          TICKLABGAP(real 0.025)               ///
          TICKLABFONT(string)                 ///
          TICKLPATTERN(string)                ///
          PCTTICKS                            ///
          PCTTICKSTEP(real 20)                ///
          PCTMINORTICKS(integer -1)           ///
          PCTAXISGAP(real 0.05)               ///
          PCTTICKLEN(real -1)                 ///
          PCTMINORLEN(real -1)                ///
          PCTTICKLABGAP(real -1)               ///
          PCTTICKCOLOR(string)                ///
          PCTTICKLABCOLOR(string)             ///
          PCTTICKLABSIZE(string)              ///
          PCTTICKCOLORLIST(string)            ///
          PCTTICKLABCOLORLIST(string)         ///
          PCTTICKCOLOROVERRIDE(string)        ///
          PCTTICKLABCOLOROVERRIDE(string)     ///
          PCTTICKLABSIZEOVERRIDE(string)      ///
          PCTAXISLWIDTH(string)               ///
          PCTTICKLWIDTH(string)               ///
          PCTMINORLWIDTH(string)              ///
          PCTTICKLPATTERN(string)             ///
          PCTTICKLABFONT(string)              ///
          LABELCOLORLIST(string)               ///
          TICKCOLORLIST(string)                ///
          TICKLABCOLORLIST(string)             ///
          LABELCOLOROVERRIDE(string)            ///
          TICKCOLOROVERRIDE(string)             ///
          TICKLABCOLOROVERRIDE(string)          ///
          LABELSIZEOVERRIDE(string)             ///
          TICKLABSIZEOVERRIDE(string)           ///
          SECTORLABELOVERRIDE(string asis)      ///
          LABELTRANSPARENCY(real 0)             ///
          TICKTRANSPARENCY(real 0)              ///
          TICKLABTRANSPARENCY(real 0)           ///
          ARROW                               ///
          ARROWGAP(real 0.05)                 ///
          INTERSEG                            ///
          INTERSEGWIDTH(real 0.01)            ///
          RIBBONGAP(real -1)                  ///
          INTERSEGOUTGAP(real 0.03)           ///
          INTERSEGINGAP(real 0.01)            ///
          INTERSEGRES(integer 15)             ///
          HIGHLIGHTTOP(string)                ///
          HIGHLIGHTALPHA(real -1)             ///
          DIMALPHA(real 20)                   ///
          RIBBONCOLOROVERRIDE(string)         ///
          RIBBONBULGEOVERRIDE(string)         ///
          LINKCHORDS(string)                  ///
          LINKCOLOR(string)                   ///
          LINKLWIDTH(string)                  ///
          LINKRADIUS(real -1)                 ///
          LINKARROW(string)                   ///
          LINKLPATTERN(string)                ///
          LINKMSIZE(string)                   ///
          LINKMANGLE(string)                  ///
          LINKBARBSIZE(string)                ///
          LINKBULGE(real -1)                  ///
          LINKARROWGAP(real 0.02)             ///
          LINKRES(integer 60)                 ///
          RIBBONBORDER                        ///
          RIBBONBORDEROPTS(string asis)       ///
          RIBBONBORDEROVERRIDE(string)        ///
          RIBBONPOSITION(string)              ///
          RIBBONZORDER(string)                ///
          TOENDOUTER(real 0)                  ///
          BLOCKORDER(string)                  ///
          COLORLIST(string)                   ///
          RIBBONTRANSPARENCY(real 30)          ///
          RINGCOLORLIST(string)               ///
          RINGTRANSPARENCY(real 0)            ///
          GAP(real 3)                         ///
          BULGE(real 0.85)                    ///
          RINGWIDTH(real 0.06)                 ///
          PLOTMARGIN(real 0)                 ///
          LABELSIZE(string)                   ///
          LABELDIR(string)                    ///
          LABELRADIUS(real 1.12)              ///
          LABELINSIDE                          ///
          CURVECHARGAP(real 3)                ///
          NARROWCHARWIDTH(real 0.55)          ///
          CURVEDLABELADJUST(real -0.01)           /// radial compensation for upper/lower curved-label asymmetry (上下半圆弯曲标签位置补偿)
          LABELTOPFLIP                        ///
          LABELBOTTOMFLIP                     ///
          LABELCOLOR(string)                  ///
          LABELFONT(string)                   ///
          NRIM(integer 15)                    ///
          NCONN(integer 20)                   ///
          NRING(integer 60)                   ///
          TITLE(string asis)                  ///
          SUBTITLE(string asis)               ///
          NOTE(string asis)                   ///
          CAPTION(string asis)                ///
          NAME(string)                        ///
          SCHEME(string)                      ///
          GRAPHREGION(string asis)            ///
          PLOTREGION(string asis)             ]


    * In adjmatrix mode the varlist may exceed 3 variables (1 row var + many
    * numeric columns); only a preliminary count check is done here.  The real
    * parsing into from/to/value happens after marksample (touse must filter
    * the original wide rows first).
    _chordcomma_check "colorlist" `"`colorlist'"'
    _chordcomma_check "ringcolorlist" `"`ringcolorlist'"'
    _chordcomma_check "labelcolorlist" `"`labelcolorlist'"'
    _chordcomma_check "tickcolorlist" `"`tickcolorlist'"'
    _chordcomma_check "ticklabcolorlist" `"`ticklabcolorlist'"'
    _chordcomma_check "pcttickcolorlist" `"`pcttickcolorlist'"'
    _chordcomma_check "pctticklabcolorlist" `"`pctticklabcolorlist'"'

    local nv_check : word count `varlist'
    if "`adjmatrix'" == "" & `nv_check' > 3 {
        di as error "The from-to-value format allows at most 3 variables (from to [value]); add the adjmatrix option for adjacency-matrix input."
        di as error "普通from-to-value格式最多允许3个变量(from to [value])。如果你要用邻接矩阵格式，请加上 adjmatrix 选项。"
        exit 198
    }
    if "`adjmatrix'" != "" & `nv_check' < 3 {
        di as error "Too few variables for adjmatrix mode: need 1 row variable + at least 2 numeric columns. (adjmatrix 模式下变量数量太少：需要1个行分类变量 + 至少2个数值列。)"
        exit 198
    }
    if `bulge' < 0 | `bulge' > 1 {
        di as error "bulge() must be between 0 and 1. (bulge() 必须在 0~1 之间。)"
        exit 198
    }
    if `ringwidth' <= 0 | `ringwidth' >= 1 {
        di as error "ringwidth() must be between 0 and 1. (ringwidth() 必须在 0~1 之间。)"
        exit 198
    }
    if "`labelinside'" != "" & `ringwidth' < 0.1 {
        *di as text "Note: labelinside is on but ringwidth(`ringwidth') is small; labels may overflow the ring. Consider a larger ringwidth() or a smaller labelsize()."
        *di as text "提示：你选择了将标签放在扇区环内(labelinside)，但ringwidth(`ringwidth')较小，文字可能超出色环，建议增大ringwidth()或调小labelsize()。"
    }
    if `plotmargin' < 0 {
        di as error "plotmargin() must be >= 0. (plotmargin() 必须 >= 0。)"
        exit 198
    }
    if `narrowcharwidth' <= 0 {
        di as error "narrowcharwidth() must be greater than 0. (narrowcharwidth() 必须大于0。)"
        exit 198
    }
    if `arrowgap' <= 0 | `arrowgap' >= 1 {
        di as error "arrowgap() must be between 0 and 1. (arrowgap() 必须在 0~1 之间。)"
        exit 198
    }
    if `ribbongap' != -1 & `ribbongap' <= 0 {
        di as error "ribbongap() must be greater than 0. (ribbongap() 必须大于0。)"
        exit 198
    }
    if `groupgap' < 0 local groupgap = `gap' * 4
    if `"`linksort'"' == "" local linksort "circular"
    if !inlist(`"`linksort'"', "circular", "asis", "value", "minimize") {
        di as error "linksort() must be one of circular, asis, value, minimize. (linksort() 只能是 circular、asis、value、minimize 之一。)"
        exit 198
    }
    if `niter' < 1 {
        di as error "niter() must be >= 1. (niter() 必须 >= 1。)"
        exit 198
    }
    local dirmult = -1
    if "`counterclockwise'" != "" local dirmult = 1

    if `"`blockorder'"' == "" local blockorder "fromfirst"
    if !inlist(`"`blockorder'"', "fromfirst", "tofirst") {
        di as error "blockorder() must be fromfirst or tofirst. (blockorder() 只能是 fromfirst 或 tofirst。)"
        exit 198
    }
    local wantfromfirst = (`"`blockorder'"' == "fromfirst")
    local fromatlower = cond(`dirmult'==-1, `wantfromfirst', !`wantfromfirst')

    local rrim = 1 - `ringwidth'
    if "`arrow'" != "" local rrim = 1 - `ringwidth' - `arrowgap'

    if `"`linkcolor'"' == "" local linkcolor "black"
    if `"`linklwidth'"' == "" local linklwidth "thin"
    if `"`linklpattern'"' == "" local linklpattern "solid"
    if `"`linkmsize'"' == "" local linkmsize "1pt"
    * Empty linkmangle/linkbarbsize are not passed to pcarrow, so the scheme
    * defaults apply automatically.
    if `"`linkarrow'"' == "" local linkarrow "single"
    if !inlist(`"`linkarrow'"', "single", "double", "none") {
        di as error "linkarrow() must be one of single, double, none. (linkarrow() 只能是 single、double、none 之一。)"
        exit 198
    }
    if `linkbulge' < 0 local linkbulge = `bulge'
    if `linkbulge' > 1 {
        di as error "linkbulge() must be between 0 and 1. (linkbulge() 必须在 0~1 之间。)"
        exit 198
    }
    if `linkarrowgap' < 0 {
        di as error "linkarrowgap() must be >= 0. (linkarrowgap() 必须 >= 0。)"
        exit 198
    }
    if `linkres' < 2 {
        di as error "linkres() must be >= 2 (at least 2 points are needed for a line). (linkres() 必须 >= 2，至少2个点才能构成一条线。)"
        exit 198
    }

    if `"`labelsize'"' == "" local labelsize "2.2"
    if `"`ticklabsize'"' == "" local ticklabsize "1.4"
    _chordsize_check `"`labelsize'"'
    if r(ok) == 0 {
        di as error "labelsize() must be a number or one of tiny, vsmall, small, medsmall, medium, medlarge, large, vlarge, huge. (labelsize() 必须是数字或上述关键字之一。)"
        exit 198
    }
    _chordsize_check `"`ticklabsize'"'
    if r(ok) == 0 {
        di as error "ticklabsize() must be a number or one of tiny, vsmall, small, medsmall, medium, medlarge, large, vlarge, huge. (ticklabsize() 必须是数字或上述关键字之一。)"
        exit 198
    }

    if `"`ribbonborderopts'"' == "" local ribbonborderopts "lwidth(thin) lpattern(solid) lcolor(black)"

    if `"`tickdir'"' == "" local tickdir "clockwise"
    if !inlist(`"`tickdir'"', "clockwise", "counterclockwise") {
        di as error "tickdir() must be clockwise or counterclockwise. (tickdir() 只能是 clockwise 或 counterclockwise。)"
        exit 198
    }
    local tickmatch = 0
    if `"`tickdir'"' == "clockwise" & `dirmult' == -1 local tickmatch = 1
    if `"`tickdir'"' == "counterclockwise" & `dirmult' == 1 local tickmatch = 1
    if `"`tickcolor'"' == "" local tickcolor "gs8"
    if `"`ticklabcolor'"' == "" local ticklabcolor "gs6"
    if `"`axislwidth'"' == "" local axislwidth "thin"
    if `"`ticklwidth'"' == "" local ticklwidth "thin"
    if `"`minorlwidth'"' == "" local minorlwidth "vthin"
    if `"`ticklpattern'"' == "" local ticklpattern "solid"
    if `"`ticklabdir'"' == "" local ticklabdir "curved"
    if !inlist(`"`ticklabdir'"', "curved", "radial", "horizontal") {
        di as error "ticklabdir() must be one of curved, radial, horizontal. (ticklabdir() 只能是 curved、radial、horizontal 之一。)"
        exit 198
    }
    if `minorticks' < 1 {
        di as error "minorticks() must be >= 1. (minorticks() 必须 >= 1。)"
        exit 198
    }
    if `tickstep' != -1 & `tickstep' <= 0 {
        di as error "tickstep() must be greater than 0. (tickstep() 必须大于0。)"
        exit 198
    }

    * ================================================================
    * Percentage axis (pctticks): validation + defaults for unspecified
    * items.  pcttickcolor/pctticklabcolor/pctticklabsize are GLOBAL
    * defaults: a sector not covered by pcttickcolorlist/
    * pcttickcoloroverride etc. falls back to them -- same mechanism as
    * the value axis (tickcolor/ticklabcolor).  Line widths/patterns and
    * major tick length are global (no per-sector override).
    * 中文说明：比例轴各项默认值兜底机制与数值轴完全一致；线宽/线型/主刻度长度全图统一。
    * ================================================================
    if `pcttickstep' <= 0 {
        di as error "pcttickstep() must be greater than 0. (pcttickstep() 必须大于0。)"
        exit 198
    }
    if `pctaxisgap' < 0 {
        di as error "pctaxisgap() must be >= 0. (pctaxisgap() 必须 >= 0。)"
        exit 198
    }
    if `pctminorticks' != -1 & `pctminorticks' < 1 {
        di as error "pctminorticks() must be >= 1. (pctminorticks() 必须 >= 1。)"
        exit 198
    }
    * Default minor-tick rule: value axis + pct axis both on -> pct axis
    * draws no minor ticks (equivalent to 1); pct axis alone -> inherit
    * the global minorticks() value.
    if `pctminorticks' == -1 {
        if "`ticks'" != "" local pctminorticks_eff = 1
        else                local pctminorticks_eff = `minorticks'
    }
    else {
        local pctminorticks_eff = `pctminorticks'
    }
    if `pctticklen' < 0 local pctticklen = `ticklen'
    if `pctticklabgap' < 0 local pctticklabgap = `ticklabgap'
    if `pctminorlen' < 0 local pctminorlen = `pctticklen' * 0.5
    if `"`pctaxislwidth'"' == "" local pctaxislwidth "`axislwidth'"
    if `"`pctticklwidth'"' == "" local pctticklwidth "`ticklwidth'"
    if `"`pctminorlwidth'"' == "" local pctminorlwidth "`minorlwidth'"
    if `"`pctticklpattern'"' == "" local pctticklpattern "solid"
    if `"`pctticklabfont'"' == "" local pctticklabfont "`ticklabfont'"
    if `"`pctticklabsize'"' == "" local pctticklabsize "`ticklabsize'"
    _chordsize_check `"`pctticklabsize'"'
    if r(ok) == 0 {
        di as error "pctticklabsize() must be a number or one of tiny, vsmall, small, medsmall, medium, medlarge, large, vlarge, huge. (pctticklabsize() 必须是数字或上述关键字之一。)"
        exit 198
    }
    if `"`pcttickcolor'"' == "" local pcttickcolor "`tickcolor'"
    if `"`pctticklabcolor'"' == "" local pctticklabcolor "`ticklabcolor'"

    if `"`tickside'"' == "" local tickside "outside"
    if !inlist(`"`tickside'"', "outside", "inside") {
        di as error "tickside() must be outside or inside. (tickside() 只能是 outside 或 inside。)"
        exit 198
    }
    if `"`labeldir'"' == "" local labeldir "curved"
    if !inlist(`"`labeldir'"', "curved", "curvedwestern", "radial", "horizontal") {
        di as error "labeldir() must be one of curved, curvedwestern, radial, horizontal. (labeldir() 只能是 curved、curvedwestern、radial、horizontal 之一。)"
        exit 198
    }
    local curvedwestern_eff = 0
    if `"`labeldir'"' == "curvedwestern" {
        local curvedwestern_eff = 1
        local labeldir "curved"
    }
    else if `"`labeldir'"' == "curved" & "`labelinside'" != "" {
        local curvedwestern_eff = 1
        *di as text "Note: with labelinside, Western (non-CJK) segments in sector labels are placed character by character along the arc (as in labeldir(curvedwestern)) to fit the narrow ring band; remove labelinside to see the segment-based layout outside the ring."
        *di as text "提示：labelinside 模式下，扇区标签中的西文片段已自动切换为逐字符弯曲摆放(等效于 labeldir(curvedwestern))，以贴合狭窄的环内弧带；如需查看环外分段摆放效果，请去掉 labelinside。"
    }

    local so_raw `"`sectororder'"'
    local so_raw : subinstr local so_raw "`" "", all
    local so_raw : subinstr local so_raw `"""' "", all
    local so_raw : subinstr local so_raw "'" "", all
    local sectororder `so_raw'
    _chordcomma_check "sectororder" `"`sectororder'"'

    local pp_raw `"`prioritypairs'"'
    local pp_raw : subinstr local pp_raw "`" "", all
    local pp_raw : subinstr local pp_raw `"""' "", all
    local pp_raw : subinstr local pp_raw "'" "", all
    local prioritypairs `pp_raw'
    _chordcomma_check "prioritypairs" `"`prioritypairs'"'

    local sg_raw `"`sectorgroup'"'
    local sg_raw : subinstr local sg_raw "`" "", all
    local sg_raw : subinstr local sg_raw `"""' "", all
    local sg_raw : subinstr local sg_raw "'" "", all
    local sectorgroup `sg_raw'
    _chordcomma_check "sectorgroup" `"`sectorgroup'"'

    local sso_raw `"`sectorscaleoverride'"'
    local sso_raw : subinstr local sso_raw "`" "", all
    local sso_raw : subinstr local sso_raw `"""' "", all
    local sso_raw : subinstr local sso_raw "'" "", all
    local sectorscaleoverride `sso_raw'
    _chordcomma_check "sectorscaleoverride" `"`sectorscaleoverride'"'

    local wgo_raw `"`withingapoverride'"'
    local wgo_raw : subinstr local wgo_raw "`" "", all
    local wgo_raw : subinstr local wgo_raw `"""' "", all
    local wgo_raw : subinstr local wgo_raw "'" "", all
    local withingapoverride `wgo_raw'

    local tso_raw `"`tickstepoverride'"'
    local tso_raw : subinstr local tso_raw "`" "", all
    local tso_raw : subinstr local tso_raw `"""' "", all
    local tso_raw : subinstr local tso_raw "'" "", all
    local tickstepoverride `tso_raw'
    _chordcomma_check "tickstepoverride" `"`tickstepoverride'"'

    local mto_raw `"`minorticksoverride'"'
    local mto_raw : subinstr local mto_raw "`" "", all
    local mto_raw : subinstr local mto_raw `"""' "", all
    local mto_raw : subinstr local mto_raw "'" "", all
    local minorticksoverride `mto_raw'
    _chordcomma_check "minorticksoverride" `"`minorticksoverride'"'

    local lco_raw `"`labelcoloroverride'"'
    local lco_raw : subinstr local lco_raw "`" "", all
    local lco_raw : subinstr local lco_raw `"""' "", all
    local lco_raw : subinstr local lco_raw "'" "", all
    local labelcoloroverride `lco_raw'
    _chordcomma_check "labelcoloroverride" `"`labelcoloroverride'"'

    local tco_raw `"`tickcoloroverride'"'
    local tco_raw : subinstr local tco_raw "`" "", all
    local tco_raw : subinstr local tco_raw `"""' "", all
    local tco_raw : subinstr local tco_raw "'" "", all
    local tickcoloroverride `tco_raw'
    _chordcomma_check "tickcoloroverride" `"`tickcoloroverride'"'

    local tlco_raw `"`ticklabcoloroverride'"'
    local tlco_raw : subinstr local tlco_raw "`" "", all
    local tlco_raw : subinstr local tlco_raw `"""' "", all
    local tlco_raw : subinstr local tlco_raw "'" "", all
    local ticklabcoloroverride `tlco_raw'
    _chordcomma_check "ticklabcoloroverride" `"`ticklabcoloroverride'"'

    local lso_raw `"`labelsizeoverride'"'
    local lso_raw : subinstr local lso_raw "`" "", all
    local lso_raw : subinstr local lso_raw `"""' "", all
    local lso_raw : subinstr local lso_raw "'" "", all
    local labelsizeoverride `lso_raw'
    _chordcomma_check "labelsizeoverride" `"`labelsizeoverride'"'

    local tlso_raw `"`ticklabsizeoverride'"'
    local tlso_raw : subinstr local tlso_raw "`" "", all
    local tlso_raw : subinstr local tlso_raw `"""' "", all
    local tlso_raw : subinstr local tlso_raw "'" "", all
    local ticklabsizeoverride `tlso_raw'
    _chordcomma_check "ticklabsizeoverride" `"`ticklabsizeoverride'"'

    * sectorlabeloverride: strip stray backticks as well (defensive cleanup).
    local slo_raw `"`sectorlabeloverride'"'
    local slo_raw : subinstr local slo_raw "`" "", all
    local sectorlabeloverride `"`slo_raw'"'

    * Percentage-axis override options need the same defensive cleanup.
    local ptco_raw `"`pcttickcoloroverride'"'
    local ptco_raw : subinstr local ptco_raw "`" "", all
    local ptco_raw : subinstr local ptco_raw `"""' "", all
    local ptco_raw : subinstr local ptco_raw "'" "", all
    local pcttickcoloroverride `ptco_raw'
    _chordcomma_check "pcttickcoloroverride" `"`pcttickcoloroverride'"'

    local ptlco_raw `"`pctticklabcoloroverride'"'
    local ptlco_raw : subinstr local ptlco_raw "`" "", all
    local ptlco_raw : subinstr local ptlco_raw `"""' "", all
    local ptlco_raw : subinstr local ptlco_raw "'" "", all
    local pctticklabcoloroverride `ptlco_raw'
    _chordcomma_check "pctticklabcoloroverride" `"`pctticklabcoloroverride'"'

    local ptlso_raw `"`pctticklabsizeoverride'"'
    local ptlso_raw : subinstr local ptlso_raw "`" "", all
    local ptlso_raw : subinstr local ptlso_raw `"""' "", all
    local ptlso_raw : subinstr local ptlso_raw "'" "", all
    local pctticklabsizeoverride `ptlso_raw'
    _chordcomma_check "pctticklabsizeoverride" `"`pctticklabsizeoverride'"'

    local ht_raw `"`highlighttop'"'
    local ht_raw : subinstr local ht_raw "`" "", all
    local ht_raw : subinstr local ht_raw `"""' "", all
    local ht_raw : subinstr local ht_raw "'" "", all
    local highlighttop `ht_raw'
    _chordcomma_check "highlighttop" `"`highlighttop'"'

    local eco_raw `"`ribboncoloroverride'"'
    local eco_raw : subinstr local eco_raw "`" "", all
    local eco_raw : subinstr local eco_raw `"""' "", all
    local eco_raw : subinstr local eco_raw "'" "", all
    local ribboncoloroverride `eco_raw'
    _chordcomma_check "ribboncoloroverride" `"`ribboncoloroverride'"'

    local bo_raw `"`ribbonbulgeoverride'"'
    local bo_raw : subinstr local bo_raw "`" "", all
    local bo_raw : subinstr local bo_raw `"""' "", all
    local bo_raw : subinstr local bo_raw "'" "", all
    local ribbonbulgeoverride `bo_raw'
    _chordcomma_check "ribbonbulgeoverride" `"`ribbonbulgeoverride'"'

    local zo_raw `"`ribbonzorder'"'
    local zo_raw : subinstr local zo_raw "`" "", all
    local zo_raw : subinstr local zo_raw `"""' "", all
    local zo_raw : subinstr local zo_raw "'" "", all
    local ribbonzorder `zo_raw'
    _chordcomma_check "ribbonzorder" `"`ribbonzorder'"'
    local nzo : word count `ribbonzorder'
    local zo_seen ""
    forvalues z = 1/`nzo' {
        local pr : word `z' of `ribbonzorder'
        local isdup : list pr in zo_seen
        if `isdup' == 1 {
            di as error "ribbonzorder(): `pr' is specified more than once. (ribbonzorder() 中 `pr' 被重复指定。)"
            exit 198
        }
        local zo_seen `zo_seen' `pr'
    }

    marksample touse, novarlist
    qui count if `touse'
    if r(N) == 0 {
        di as error "No observations satisfy the if/in conditions. (没有符合条件的观测值。)"
        exit 2000
    }

    preserve

    * ================================================================
    * Adjacency-matrix (adjmatrix) mode: expand the wide table
    * (rows = origin category, columns = destination category,
    * cells = flow) into the from_s/to_s/weight long table used
    * internally, so the collapse/angle code downstream is unchanged.
    * Missing (blank) cells mean "no flow" and are skipped.
    * 中文说明：把宽表邻接矩阵展开为内部统一的长表；缺失单元格视为无流量。
    * ================================================================
    if "`adjmatrix'" == "" {
        local from  : word 1 of `varlist'
        local to    : word 2 of `varlist'
        local value : word 3 of `varlist'
    }
    else {
        local rowvar : word 1 of `varlist'
        local nvtot  : word count `varlist'
        local ncols  = `nvtot' - 1

        * colsectors() is optional: since Stata 14+ variable names can be
        * Unicode (e.g. Chinese), each numeric column's own name can serve
        * directly as its sector label.  colsectors() remains as a fallback/
        * override for cases where variable-name rules (no spaces, 32-char
        * limit, no leading digits, ...) force abbreviated names.
        * 中文说明：数值列变量名可直接作分类名；colsectors()仅作兜底/覆盖。
        if `"`colsectors'"' != "" {
            local ncs : word count `colsectors'
            if `ncs' != `ncols' {
                di as error "colsectors() lists `ncs' names but there are `ncols' numeric columns. (colsectors() 列出的分类数(`ncs')与数值列数量(`ncols')不一致。)"
                exit 198
            }
            forvalues c = 1/`ncols' {
                local colvar_`c' : word `=`c'+1' of `varlist'
                local colsec_`c' : word `c' of `colsectors'
            }
        }
        else {
            forvalues c = 1/`ncols' {
                local colvar_`c' : word `=`c'+1' of `varlist'
                local colsec_`c' "`colvar_`c''"
            }
        }

        cap confirm string variable `rowvar'
        if _rc != 0 {
            di as error "In adjmatrix mode the first variable (`rowvar') must be a string variable holding the row category names. (adjmatrix 模式下第一个变量必须是字符串变量，存放每行对应的分类名称。)"
            exit 198
        }
        forvalues c = 1/`ncols' {
            cap confirm numeric variable `colvar_`c''
            if _rc != 0 {
                di as error "In adjmatrix mode all variables after the first must be numeric (matrix cells); `colvar_`c'' is not numeric. (adjmatrix 模式下除第一个变量外都必须是数值变量，`colvar_`c'' 不是数值变量。)"
                exit 198
            }
        }

        quietly keep if `touse' & !missing(`rowvar') & `rowvar' != ""
        local nrows = _N
        if `nrows' == 0 {
            di as error "No eligible rows in adjmatrix mode. (adjmatrix 模式下没有符合条件的行。)"
            exit 2000
        }

        * Pass 1: before clear, read row labels and cell values into
        * locals/a matrix.
        tempname AdjVal
        matrix `AdjVal' = J(`nrows', `ncols', .)
        forvalues i = 1/`nrows' {
            local rowlab_`i' = `rowvar'[`i']
            forvalues c = 1/`ncols' {
                matrix `AdjVal'[`i',`c'] = `colvar_`c''[`i']
            }
        }

        * Count non-missing cells once, so obs can be set in one go.
        local totaledges = 0
        forvalues i = 1/`nrows' {
            forvalues c = 1/`ncols' {
                if !missing(el(`AdjVal',`i',`c')) local totaledges = `totaledges' + 1
            }
        }
        if `totaledges' == 0 {
            di as error "All adjmatrix cells are missing; no usable data. (adjmatrix 中所有单元格都是缺失值，没有可用数据。)"
            exit 2000
        }

        clear
        quietly set obs `totaledges'
        quietly gen str244 _adjfrom_s = ""
        quietly gen str244 _adjto_s   = ""
        quietly gen double _adjweight = .
        local r = 0
        forvalues i = 1/`nrows' {
            forvalues c = 1/`ncols' {
                local cellval = el(`AdjVal',`i',`c')
                if !missing(`cellval') {
                    local r = `r' + 1
                    quietly replace _adjfrom_s = `"`rowlab_`i''"' in `r'
                    quietly replace _adjto_s   = `"`colsec_`c''"' in `r'
                    quietly replace _adjweight = `cellval'        in `r'
                }
            }
        }

        * Regenerate touse (the data are now the long table; keep all rows).
        quietly gen byte `touse' = 1

        local from  "_adjfrom_s"
        local to    "_adjto_s"
        local value "_adjweight"
        di as text "Adjacency matrix expanded: `nrows' rows x `ncols' columns, `totaledges' non-missing cells -> `totaledges' edges."
        di as text "已将邻接矩阵展开为 `nrows' 行 x `ncols' 列，其中 `totaledges' 个非缺失单元格 -> `totaledges' 条边。"
    }

    if `ribbontransparency' < 0 | `ribbontransparency' > 100 {
        di as error "ribbontransparency() must be between 0 and 100. (ribbontransparency() 必须在 0-100 之间。)"
        exit 198
    }
    if `ringtransparency' < 0 | `ringtransparency' > 100 {
        di as error "ringtransparency() must be between 0 and 100. (ringtransparency() 必须在 0-100 之间。)"
        exit 198
    }
    if `labeltransparency' < 0 | `labeltransparency' > 100 {
        di as error "labeltransparency() must be between 0 and 100. (labeltransparency() 必须在 0-100 之间。)"
        exit 198
    }
    if `ticktransparency' < 0 | `ticktransparency' > 100 {
        di as error "ticktransparency() must be between 0 and 100. (ticktransparency() 必须在 0-100 之间。)"
        exit 198
    }
    if `ticklabtransparency' < 0 | `ticklabtransparency' > 100 {
        di as error "ticklabtransparency() must be between 0 and 100. (ticklabtransparency() 必须在 0-100 之间。)"
        exit 198
    }
    local alpha = 100 - `ribbontransparency'
    local ringalpha = 100 - `ringtransparency'
    local labelalpha = 100 - `labeltransparency'
    local tickalpha = 100 - `ticktransparency'
    local ticklabalpha = 100 - `ticklabtransparency'

    tempvar from_lab to_lab weight
    cap confirm string variable `from'
    if _rc == 0  gen `from_lab' = `from'
    else         gen `from_lab' = string(`from')

    cap confirm string variable `to'
    if _rc == 0  gen `to_lab' = `to'
    else         gen `to_lab' = string(`to')

    if `"`value'"' == "" {
        di as text "Note: no third (value) variable specified; each observation counts as 1 (frequency weights)."
        di as text "注意：未指定第三个变量(value)，使用每行记1次的频数作为权重。"
        gen `weight' = 1
    }
    else {
        cap confirm numeric variable `value'
        if _rc != 0 {
            di as error "value (`value') must be a numeric variable. (value(`value') 必须是数值变量。)"
            exit 198
        }
        gen `weight' = `value'
    }

    quietly keep if `touse' & !missing(`weight') & `from_lab' != "" & `to_lab' != ""
    quietly count
    if r(N) == 0 {
        di as error "No valid data remain. (有效数据为空。)"
        exit 2000
    }

    rename `from_lab' from_s
    rename `to_lab'   to_s

    local fa_sectors ""
    local Nraw = _N
    forvalues i = 1/`Nraw' {
        local v = from_s[`i']
        local already : list v in fa_sectors
        if `already' == 0 local fa_sectors `fa_sectors' `v'
    }
    forvalues i = 1/`Nraw' {
        local v = to_s[`i']
        local already : list v in fa_sectors
        if `already' == 0 local fa_sectors `fa_sectors' `v'
    }

    tempvar val_s
    collapse (sum) `val_s'=`weight', by(from_s to_s)
    quietly drop if `val_s' <= 0

    quietly count
    local nedges = r(N)
    if `nedges' == 0 {
        di as error "No valid edges after aggregation. (聚合后无有效边。)"
        exit 2000
    }

    gen long _origorder = _n

    quietly levelsof from_s, local(lev_from) clean
    quietly levelsof to_s,   local(lev_to)   clean
    local actual_sectors : list lev_from | lev_to
    local nsec : word count `actual_sectors'
    if `nsec' < 2 {
        di as error "At least two distinct categories are required to draw a chord diagram. (至少需要两个不同的分类才能绘制和弦图。)"
        exit 2000
    }

    if `"`sectororder'"' != "" {
        local sectors `sectororder'
        local n_given : word count `sectors'
        if `n_given' != `nsec' {
            di as error "sectororder() lists `n_given' categories but the data contain `nsec'. (sectororder() 列出的分类数与实际分类数不一致。)"
            di as error "Categories found in the data (数据中实际的分类): `actual_sectors'"
            exit 198
        }
        local diff1 : list actual_sectors - sectors
        local diff2 : list sectors - actual_sectors
        if `"`diff1'"' != "" | `"`diff2'"' != "" {
            di as error "sectororder() does not match the categories in the data. (sectororder() 与数据中实际分类不完全一致。)"
            di as error "Categories found in the data (数据中实际的分类): `actual_sectors'"
            di as error "Order you specified (你指定的顺序): `sectors'"
            exit 198
        }
    }
    else {
        local sectors `fa_sectors'
    }

    * Grouping: reorder sectors so that sectors of the same group are
    * contiguous on the circle.
    local has_group = (`"`sectorgroup'"' != "")
    if `has_group' == 1 {
        local n_orig : word count `sectors'
        forvalues j = 1/`n_orig' {
            local sname : word `j' of `sectors'
            local grp_`j' "`sname'"
            foreach pr of local sectorgroup {
                local sep = strpos(`"`pr'"', "-")
                if `sep' > 0 {
                    local pname = substr(`"`pr'"', 1, `sep'-1)
                    local pgrp  = substr(`"`pr'"', `sep'+1, .)
                    if "`sname'" == "`pname'" {
                        local grp_`j' "`pgrp'"
                    }
                }
            }
        }

        local grouplist ""
        foreach pr of local sectorgroup {
            local sep = strpos(`"`pr'"', "-")
            if `sep' > 0 {
                local pgrp = substr(`"`pr'"', `sep'+1, .)
                local found = 0
                local ng : word count `grouplist'
                forvalues k = 1/`ng' {
                    local existing : word `k' of `grouplist'
                    if "`existing'" == "`pgrp'" local found = 1
                }
                if `found' == 0 local grouplist `grouplist' `pgrp'
            }
        }
        forvalues j = 1/`n_orig' {
            local g "`grp_`j''"
            local found = 0
            local ng : word count `grouplist'
            forvalues k = 1/`ng' {
                local existing : word `k' of `grouplist'
                if "`existing'" == "`g'" local found = 1
            }
            if `found' == 0 local grouplist `grouplist' `g'
        }

        local sectors_new ""
        local ngrp : word count `grouplist'
        forvalues k = 1/`ngrp' {
            local g : word `k' of `grouplist'
            forvalues j = 1/`n_orig' {
                if "`grp_`j''" == "`g'" {
                    local sname : word `j' of `sectors'
                    local sectors_new `sectors_new' `sname'
                }
            }
            if `k' == 1 local n_group1 : word count `sectors_new'
        }
        local sectors `sectors_new'
    }

    local auto2group = 0
    if `has_group' == 1 {
        if `ngrp' == 2 local auto2group = 1
    }
    if "`splithorizontal'" != "" & `auto2group' == 0 {
        di as text "Note: splithorizontal only takes effect when sectorgroup() yields exactly two groups; it is ignored this time."
        di as text "提示：splithorizontal 仅在 sectorgroup() 正好分为两组时才生效，本次因分组数不是2组而未生效。"
    }

    tempname ME
    matrix `ME' = J(`nedges', 3, 0)
    quietly gen long _fidx = .
    quietly gen long _tidx = .
    quietly gen byte  _ispriority = 0
    forvalues i = 1/`nedges' {
        local fs = from_s[`i']
        local ts = to_s[`i']
        local fi : list posof `"`fs'"' in sectors
        local ti : list posof `"`ts'"' in sectors
        matrix `ME'[`i',1] = `fi'
        matrix `ME'[`i',2] = `ti'
        matrix `ME'[`i',3] = `val_s'[`i']
        quietly replace _fidx = `fi' in `i'
        quietly replace _tidx = `ti' in `i'

        foreach pr of local prioritypairs {
            local sep = strpos(`"`pr'"', "-")
            if `sep' > 0 {
                local pA = substr(`"`pr'"', 1, `sep'-1)
                local pB = substr(`"`pr'"', `sep'+1, .)
                if ("`fs'"=="`pA'" & "`ts'"=="`pB'") | ("`fs'"=="`pB'" & "`ts'"=="`pA'") {
                    quietly replace _ispriority = 1 in `i'
                }
            }
        }
    }
    quietly gen byte _ishi  = 0
    quietly gen byte _isdim = 0
    if `"`highlighttop'"' != "" quietly replace _isdim = 1
    foreach pr of local highlighttop {
        local sep1 = strpos(`"`pr'"', "-")
        local rest = substr(`"`pr'"', `sep1'+1, .)
        local sep2 = strpos(`"`rest'"', "-")
        local hregion = substr(`"`pr'"', 1, `sep1'-1)
        local hdir    = substr(`"`rest'"', 1, `sep2'-1)
        local htopn   = substr(`"`rest'"', `sep2'+1, .)

        if "`hdir'" == "from"      local hcond `"from_s == `"`hregion'"'"'
        else if "`hdir'" == "to"   local hcond `"to_s == `"`hregion'"'"'
        else {
            di as error "highlighttop(): the direction part of `pr' must be from or to. (highlighttop() 里 `pr' 的方向部分只能是 from 或 to。)"
            exit 198
        }

        cap drop _hlrank
        quietly egen double _hlrank = rank(-`val_s') if `hcond'
        quietly replace _ishi  = 1 if `hcond' & _hlrank <= `htopn'
        quietly replace _isdim = 1 if `hcond' & _hlrank >  `htopn' & _hlrank < .
    }

    tempname EdgeFlag
    matrix `EdgeFlag' = J(`nedges', 1, 0)
    forvalues i = 1/`nedges' {
        if _ishi[`i'] == 1       matrix `EdgeFlag'[`i',1] = 1
        else if _isdim[`i'] == 1 matrix `EdgeFlag'[`i',1] = 2
    }

    local hexchars2 "0123456789ABCDEF"

    local rbo_nseg = 0
    if `"`ribbonborderoverride'"' != "" {
        _chordsplit_toplevel `"`ribbonborderoverride'"'
        local rbo_nseg = r(nseg)
        forvalues s = 1/`rbo_nseg' {
            local rbo_seg`s' `"`r(seg`s')'"'
        }
    }

    local lc_nseg = 0
    if `"`linkchords'"' != "" {
        _chordsplit_toplevel `"`linkchords'"'
        local lc_nseg = r(nseg)
        forvalues s = 1/`lc_nseg' {
            local lc_seg`s' `"`r(seg`s')'"'
        }
    }

    local rp_nseg = 0
    if `"`ribbonposition'"' != "" {
        _chordsplit_toplevel `"`ribbonposition'"'
        local rp_nseg = r(nseg)
        forvalues s = 1/`rp_nseg' {
            local rp_seg`s' `"`r(seg`s')'"'
        }
    }

    local slo_nseg = 0
    if `"`sectorlabeloverride'"' != "" {
        local slo_text `"`sectorlabeloverride'"'
        local slo_depth = 0
        local slo_n = strlen(`"`slo_text'"')
        local slo_start = 1
        forvalues p = 1/`slo_n' {
            local slo_ch = substr(`"`slo_text'"', `p', 1)
            if `"`slo_ch'"' == "(" local slo_depth = `slo_depth' + 1
            if `"`slo_ch'"' == ")" local slo_depth = `slo_depth' - 1
            if `"`slo_ch'"' == "," & `slo_depth' == 0 {
                local slo_nseg = `slo_nseg' + 1
                local slo_seg`slo_nseg' = substr(`"`slo_text'"', `slo_start', `p'-`slo_start')
                local slo_start = `p' + 1
            }
        }
        local slo_nseg = `slo_nseg' + 1
        local slo_seg`slo_nseg' = substr(`"`slo_text'"', `slo_start', .)
    }

    forvalues i = 1/`nedges' {
        local fs = from_s[`i']
        local ts = to_s[`i']
        foreach pr of local ribboncoloroverride {
            local sep1 = strpos(`"`pr'"', "-")
            local rest = substr(`"`pr'"', `sep1'+1, .)
            local sep2 = strpos(`"`rest'"', "-")
            local eA  = substr(`"`pr'"', 1, `sep1'-1)
            local eB  = substr(`"`rest'"', 1, `sep2'-1)
            local ecol = substr(`"`rest'"', `sep2'+1, .)
            if "`fs'" == "`eA'" & "`ts'" == "`eB'" {
                _chordcolor_parse `"`ecol'"' "`hexchars2'"
                local edgecol_`i' `"`r(parsedcolor)'"'
                if `"`r(parsedalpha)'"' == "" local edgealpha_`i' = `alpha'
                else                          local edgealpha_`i' = `r(parsedalpha)'
            }
        }

        local bulge_`i' = `bulge'
        foreach pr of local ribbonbulgeoverride {
            local sep1 = strpos(`"`pr'"', "-")
            local rest = substr(`"`pr'"', `sep1'+1, .)
            local sep2 = strpos(`"`rest'"', "-")
            local bA  = substr(`"`pr'"', 1, `sep1'-1)
            local bB  = substr(`"`rest'"', 1, `sep2'-1)
            local bval = substr(`"`rest'"', `sep2'+1, .)
            if "`fs'" == "`bA'" & "`ts'" == "`bB'" {
                if `bval' < 0 | `bval' > 1 {
                    di as error "ribbonbulgeoverride(): the curvature for `fs'-`ts' must be between 0 and 1. (ribbonbulgeoverride() 中 `fs'-`ts' 的弯曲度必须在 0~1 之间。)"
                    exit 198
                }
                local bulge_`i' = `bval'
            }
        }

        local borderopts_`i' `"`ribbonborderopts'"'
        local borderoverridden_`i' = 0
        forvalues s = 1/`rbo_nseg' {
            _chordpairopt_split `"`rbo_seg`s''"'
            if r(ok) == 1 {
                local rA `"`r(sectorA)'"'
                local rB `"`r(sectorB)'"'
                local ropts `"`r(opts)'"'
                if "`fs'" == "`rA'" & "`ts'" == "`rB'" {
                    local borderopts_`i' `"`ropts'"'
                    local borderoverridden_`i' = 1
                }
            }
        }

        local linkflag_`i' = 0
        local linkcolcur_`i' `"`linkcolor'"'
        local linklwcur_`i' `"`linklwidth'"'
        local linklpcur_`i' `"`linklpattern'"'
        local linkmszcur_`i' `"`linkmsize'"'
        local linkmanglecur_`i' `"`linkmangle'"'
        local linkbarbszcur_`i' `"`linkbarbsize'"'
        local linkarrowtype_`i' `"`linkarrow'"'
        local linkbulgecur_`i' = `linkbulge'
        local linkradiusfromcur_`i' = `linkradius'
        local linkradiustocur_`i' = `linkradius'
        local linkrescur_`i' = `linkres'
        local linkextra_`i' ""
        forvalues s = 1/`lc_nseg' {
            local lcseg = strtrim(`"`lc_seg`s''"')
            local lccolon = strpos(`"`lcseg'"', ":")
            if `lccolon' > 0 {
                local lcpair = strtrim(substr(`"`lcseg'"', 1, `lccolon'-1))
                local lcopt  = strtrim(substr(`"`lcseg'"', `lccolon'+1, .))
            }
            else {
                local lcpair `"`lcseg'"'
                local lcopt ""
            }
            local lcsep = strpos(`"`lcpair'"', "-")
            if `lcsep' > 0 {
                local lA = strtrim(substr(`"`lcpair'"', 1, `lcsep'-1))
                local lB = strtrim(substr(`"`lcpair'"', `lcsep'+1, .))
                if "`fs'" == "`lA'" & "`ts'" == "`lB'" {
                    local linkflag_`i' = 1
                    if `"`lcopt'"' != "" {
                        if strpos(`"`lcopt'"', "arrow(double)") > 0 {
                            local linkarrowtype_`i' "double"
                            local lcopt : subinstr local lcopt "arrow(double)" "", all
                        }
                        else if strpos(`"`lcopt'"', "arrow(single)") > 0 {
                            local linkarrowtype_`i' "single"
                            local lcopt : subinstr local lcopt "arrow(single)" "", all
                        }
                        else if strpos(`"`lcopt'"', "arrow(none)") > 0 {
                            local linkarrowtype_`i' "none"
                            local lcopt : subinstr local lcopt "arrow(none)" "", all
                        }

                        local lcolpos = strpos(`"`lcopt'"', "lcolor(")
                        if `lcolpos' > 0 {
                            local lcolafter = substr(`"`lcopt'"', `lcolpos'+7, .)
                            local lcolend = strpos(`"`lcolafter'"', ")")
                            local linkcolcur_`i' = substr(`"`lcolafter'"', 1, `lcolend'-1)
                            local lcoltag = "lcolor(" + substr(`"`lcolafter'"', 1, `lcolend')
                            local lcopt : subinstr local lcopt `"`lcoltag'"' "", all
                        }

                        local lwidpos = strpos(`"`lcopt'"', "lwidth(")
                        if `lwidpos' > 0 {
                            local lwidafter = substr(`"`lcopt'"', `lwidpos'+7, .)
                            local lwidend = strpos(`"`lwidafter'"', ")")
                            local linklwcur_`i' = substr(`"`lwidafter'"', 1, `lwidend'-1)
                            local lwidtag = "lwidth(" + substr(`"`lwidafter'"', 1, `lwidend')
                            local lcopt : subinstr local lcopt `"`lwidtag'"' "", all
                        }

                        local lpatpos = strpos(`"`lcopt'"', "lpattern(")
                        if `lpatpos' > 0 {
                            local lpatafter = substr(`"`lcopt'"', `lpatpos'+9, .)
                            local lpatend = strpos(`"`lpatafter'"', ")")
                            local linklpcur_`i' = substr(`"`lpatafter'"', 1, `lpatend'-1)
                            local lpattag = "lpattern(" + substr(`"`lpatafter'"', 1, `lpatend')
                            local lcopt : subinstr local lcopt `"`lpattag'"' "", all
                        }

                        local lmszpos = strpos(`"`lcopt'"', "msize(")
                        if `lmszpos' > 0 {
                            local lmszafter = substr(`"`lcopt'"', `lmszpos'+6, .)
                            local lmszend = strpos(`"`lmszafter'"', ")")
                            local linkmszcur_`i' = substr(`"`lmszafter'"', 1, `lmszend'-1)
                            local lmsztag = "msize(" + substr(`"`lmszafter'"', 1, `lmszend')
                            local lcopt : subinstr local lcopt `"`lmsztag'"' "", all
                        }

                        local lmangpos = strpos(`"`lcopt'"', "mangle(")
                        if `lmangpos' > 0 {
                            local lmangafter = substr(`"`lcopt'"', `lmangpos'+7, .)
                            local lmangend = strpos(`"`lmangafter'"', ")")
                            local linkmanglecur_`i' = substr(`"`lmangafter'"', 1, `lmangend'-1)
                            local lmangtag = "mangle(" + substr(`"`lmangafter'"', 1, `lmangend')
                            local lcopt : subinstr local lcopt `"`lmangtag'"' "", all
                        }

                        local lbarbpos = strpos(`"`lcopt'"', "barbsize(")
                        if `lbarbpos' > 0 {
                            local lbarbafter = substr(`"`lcopt'"', `lbarbpos'+9, .)
                            local lbarbend = strpos(`"`lbarbafter'"', ")")
                            local linkbarbszcur_`i' = substr(`"`lbarbafter'"', 1, `lbarbend'-1)
                            local lbarbtag = "barbsize(" + substr(`"`lbarbafter'"', 1, `lbarbend')
                            local lcopt : subinstr local lcopt `"`lbarbtag'"' "", all
                        }

                        local lbulgepos = strpos(`"`lcopt'"', "bulge(")
                        if `lbulgepos' > 0 {
                            local lbulgeafter = substr(`"`lcopt'"', `lbulgepos'+6, .)
                            local lbulgeend = strpos(`"`lbulgeafter'"', ")")
                            local lbulgeval = substr(`"`lbulgeafter'"', 1, `lbulgeend'-1)
                            if `lbulgeval' < 0 | `lbulgeval' > 1 {
                                di as error "linkchords(): bulge() for `fs'-`ts' must be between 0 and 1. (linkchords() 中 `fs'-`ts' 的 bulge() 必须在 0~1 之间。)"
                                exit 198
                            }
                            local linkbulgecur_`i' = `lbulgeval'
                            local lbulgetag = "bulge(" + substr(`"`lbulgeafter'"', 1, `lbulgeend')
                            local lcopt : subinstr local lcopt `"`lbulgetag'"' "", all
                        }

                        local lradfpos = strpos(`"`lcopt'"', "radiusfrom(")
                        if `lradfpos' > 0 {
                            local lradfafter = substr(`"`lcopt'"', `lradfpos'+11, .)
                            local lradfend = strpos(`"`lradfafter'"', ")")
                            local lradfval = substr(`"`lradfafter'"', 1, `lradfend'-1)
                            if `lradfval' <= 0 {
                                di as error "linkchords(): radiusfrom() for `fs'-`ts' must be greater than 0. (linkchords() 中 `fs'-`ts' 的 radiusfrom() 必须大于0。)"
                                exit 198
                            }
                            local linkradiusfromcur_`i' = `lradfval'
                            local lradftag = "radiusfrom(" + substr(`"`lradfafter'"', 1, `lradfend')
                            local lcopt : subinstr local lcopt `"`lradftag'"' "", all
                        }

                        local lradtpos = strpos(`"`lcopt'"', "radiusto(")
                        if `lradtpos' > 0 {
                            local lradtafter = substr(`"`lcopt'"', `lradtpos'+9, .)
                            local lradtend = strpos(`"`lradtafter'"', ")")
                            local lradtval = substr(`"`lradtafter'"', 1, `lradtend'-1)
                            if `lradtval' <= 0 {
                                di as error "linkchords(): radiusto() for `fs'-`ts' must be greater than 0. (linkchords() 中 `fs'-`ts' 的 radiusto() 必须大于0。)"
                                exit 198
                            }
                            local linkradiustocur_`i' = `lradtval'
                            local lradttag = "radiusto(" + substr(`"`lradtafter'"', 1, `lradtend')
                            local lcopt : subinstr local lcopt `"`lradttag'"' "", all
                        }

                        local lrespos = strpos(`"`lcopt'"', "res(")
                        if `lrespos' > 0 {
                            local lresafter = substr(`"`lcopt'"', `lrespos'+4, .)
                            local lresend = strpos(`"`lresafter'"', ")")
                            local lresval = substr(`"`lresafter'"', 1, `lresend'-1)
                            if `lresval' < 2 {
                                di as error "linkchords(): res() for `fs'-`ts' must be >= 2. (linkchords() 中 `fs'-`ts' 的 res() 必须 >= 2。)"
                                exit 198
                            }
                            local linkrescur_`i' = `lresval'
                            local lrestag = "res(" + substr(`"`lresafter'"', 1, `lresend')
                            local lcopt : subinstr local lcopt `"`lrestag'"' "", all
                        }

                        local lcopt = strtrim(`"`lcopt'"')
                        local linkextra_`i' `"`lcopt'"'
                    }
                }
            }
        }
        local linklineopts_`i' `"lcolor(`linkcolcur_`i'') lwidth(`linklwcur_`i'') lpattern(`linklpcur_`i'') `linkextra_`i''"'
        local arrowextra_`i' ""
        if `"`linkmanglecur_`i''"' != "" local arrowextra_`i' `"`arrowextra_`i'' mangle(`linkmanglecur_`i'')"'
        if `"`linkbarbszcur_`i''"' != "" local arrowextra_`i' `"`arrowextra_`i'' barbsize(`linkbarbszcur_`i'')"'
        local linkarrowopts_`i' `"lcolor(`linkcolcur_`i'') lwidth(`linklwcur_`i'') mcolor(`linkcolcur_`i'') msize(`linkmszcur_`i'')`arrowextra_`i''"'

        local pinfrom_`i' "."
        local pinto_`i'   "."
        forvalues s = 1/`rp_nseg' {
            _chordpairopt_split `"`rp_seg`s''"'
            if r(ok) == 1 {
                local rA `"`r(sectorA)'"'
                local rB `"`r(sectorB)'"'
                local ropts `"`r(opts)'"'
                if "`fs'" == "`rA'" & "`ts'" == "`rB'" {
                    local frompos = strpos(`"`ropts'"', "from(")
                    if `frompos' > 0 {
                        local fromafter = substr(`"`ropts'"', `frompos'+5, .)
                        local fromend = strpos(`"`fromafter'"', ")")
                        local pinfrom_`i' = substr(`"`fromafter'"', 1, `fromend'-1)
                    }
                    local topos = strpos(`"`ropts'"', "to(")
                    if `topos' > 0 {
                        local toafter = substr(`"`ropts'"', `topos'+3, .)
                        local toend = strpos(`"`toafter'"', ")")
                        local pinto_`i' = substr(`"`toafter'"', 1, `toend'-1)
                    }
                }
            }
        }

        local zorank_`i' = 0
        forvalues z = 1/`nzo' {
            local pr : word `z' of `ribbonzorder'
            local zsep = strpos(`"`pr'"', "-")
            if `zsep' > 0 {
                local zA = substr(`"`pr'"', 1, `zsep'-1)
                local zB = substr(`"`pr'"', `zsep'+1, .)
                if "`fs'" == "`zA'" & "`ts'" == "`zB'" {
                    local zorank_`i' = `z'
                }
            }
        }
    }

    * Verify that every ribbonzorder() item matches an existing edge.
    forvalues z = 1/`nzo' {
        local zmatched = 0
        forvalues e = 1/`nedges' {
            if `zorank_`e'' == `z' local zmatched = 1
        }
        if `zmatched' == 0 {
            local pr : word `z' of `ribbonzorder'
            di as error "ribbonzorder(): `pr' does not match any existing edge in the data (note: from/to direction must match). (ribbonzorder() 中 `pr' 未匹配到数据里实际存在的边，注意方向需与数据一致。)"
            exit 198
        }
    }

    * Build the final drawing order: unlisted edges first (bottom), then the
    * listed pairs in REVERSE list order (first listed pair is drawn last =
    * appears on top).
    local ndrawn = 0
    forvalues e = 1/`nedges' {
        if `zorank_`e'' == 0 {
            local ndrawn = `ndrawn' + 1
            local draworder`ndrawn' = `e'
        }
    }
    if `nzo' > 0 {
        forvalues z = `nzo'(-1)1 {
            forvalues e = 1/`nedges' {
                if `zorank_`e'' == `z' {
                    local ndrawn = `ndrawn' + 1
                    local draworder`ndrawn' = `e'
                }
            }
        }
    }

    tempname Mout Min
    matrix `Mout' = J(1, `nsec', 0)
    matrix `Min'  = J(1, `nsec', 0)
    forvalues i = 1/`nsec' {
        local sname : word `i' of `sectors'
        quietly sum `val_s' if from_s == `"`sname'"', meanonly
        matrix `Mout'[1,`i'] = r(sum)
        quietly sum `val_s' if to_s == `"`sname'"', meanonly
        matrix `Min'[1,`i']  = r(sum)
    }
    quietly sum `val_s', meanonly
    local total_flow = r(sum)
    tempname TickStep
    matrix `TickStep' = J(1, `nsec', 1)
    if "`ticks'" != "" {
        forvalues i = 1/`nsec' {
            local Ti = el(`Mout',1,`i') + el(`Min',1,`i')
            if `Ti' > 0 {
                if `tickstep' > 0 {
                    local step = `tickstep'
                }
                else {
                    local raw = `Ti' / 5
                    local mag = 10^floor(log10(`raw'))
                    local normv = `raw' / `mag'
                    if `normv' < 1.5       local step = 1*`mag'
                    else if `normv' < 3    local step = 2*`mag'
                    else if `normv' < 7    local step = 5*`mag'
                    else                   local step = 10*`mag'
                }
                matrix `TickStep'[1,`i'] = `step'
            }
        }
        forvalues i = 1/`nsec' {
            local sname : word `i' of `sectors'
            foreach pr of local tickstepoverride {
                local sep = strpos(`"`pr'"', "-")
                if `sep' > 0 {
                    local pname = substr(`"`pr'"', 1, `sep'-1)
                    local pval  = substr(`"`pr'"', `sep'+1, .)
                    if "`sname'" == "`pname'" {
                        if `pval' <= 0 {
                            di as error "tickstepoverride(): the step for `sname' must be greater than 0. (tickstepoverride() 中 `sname' 的步长必须大于0。)"
                            exit 198
                        }
                        matrix `TickStep'[1,`i'] = `pval'
                    }
                }
            }
        }
    }

    tempname MinorTicks
    matrix `MinorTicks' = J(1, `nsec', `minorticks')
    if "`ticks'" != "" {
        forvalues i = 1/`nsec' {
            local sname : word `i' of `sectors'
            foreach pr of local minorticksoverride {
                local sep = strpos(`"`pr'"', "-")
                if `sep' > 0 {
                    local pname = substr(`"`pr'"', 1, `sep'-1)
                    local pval  = substr(`"`pr'"', `sep'+1, .)
                    if "`sname'" == "`pname'" {
                        if `pval' < 1 {
                            di as error "minorticksoverride(): the minor-tick count for `sname' must be >= 1. (minorticksoverride() 中 `sname' 的小刻度数量必须 >= 1。)"
                            exit 198
                        }
                        matrix `MinorTicks'[1,`i'] = `pval'
                    }
                }
            }
        }
    }

    * Gap after each sector: groupgap between groups, gap within groups or
    * when no groups are defined.
    tempname GapArr
    matrix `GapArr' = J(1, `nsec', `gap')
    forvalues i = 1/`nsec' {
        local gsize_`i' = 1
    }
    if `has_group' == 1 {
        forvalues i = 1/`nsec' {
            local sname : word `i' of `sectors'
            local fgrp_`i' "`sname'"
            foreach pr of local sectorgroup {
                local sep = strpos(`"`pr'"', "-")
                if `sep' > 0 {
                    local pname = substr(`"`pr'"', 1, `sep'-1)
                    local pgrp  = substr(`"`pr'"', `sep'+1, .)
                    if "`sname'" == "`pname'" {
                        local fgrp_`i' "`pgrp'"
                    }
                }
            }
        }
        forvalues i = 1/`nsec' {
            local inext = mod(`i', `nsec') + 1
            if "`fgrp_`i''" != "`fgrp_`inext''" {
                matrix `GapArr'[1,`i'] = `groupgap'
            }
            else {
                local gname "`fgrp_`i''"
                foreach pr of local withingapoverride {
                    local sep = strpos(`"`pr'"', "-")
                    if `sep' > 0 {
                        local pname = substr(`"`pr'"', 1, `sep'-1)
                        local pval  = substr(`"`pr'"', `sep'+1, .)
                        if "`gname'" == "`pname'" {
                            matrix `GapArr'[1,`i'] = `pval'
                        }
                    }
                }
            }
        }
        forvalues i = 1/`nsec' {
            local gsize_`i' = 0
            forvalues j = 1/`nsec' {
                if "`fgrp_`j''" == "`fgrp_`i''" local gsize_`i' = `gsize_`i'' + 1
            }
        }
    }

    local totalgap = 0
    forvalues i = 1/`nsec' {
        local totalgap = `totalgap' + el(`GapArr',1,`i')
    }
    local eff_angle = 360 - `totalgap'
    if `eff_angle' <= 0 {
        di as error "Too many categories: the gap()/groupgap() settings leave no angle for the sectors. (分类数量过多，gap()/groupgap()设置导致角度不足。)"
        exit 2000
    }

    * Sector angular weights (scale switch + sectorscaleoverride).
    tempname SecWeight
    matrix `SecWeight' = J(1, `nsec', 0)
    forvalues i = 1/`nsec' {
        local flow_i = el(`Mout',1,`i') + el(`Min',1,`i')
        if "`scale'" != "" local w = 1
        else               local w = `flow_i'
        matrix `SecWeight'[1,`i'] = `w'
    }
    forvalues i = 1/`nsec' {
        local sname : word `i' of `sectors'
        foreach pr of local sectorscaleoverride {
            local sep = strpos(`"`pr'"', "-")
            if `sep' > 0 {
                local pname = substr(`"`pr'"', 1, `sep'-1)
                local pfac  = substr(`"`pr'"', `sep'+1, .)
                if "`sname'" == "`pname'" {
                    if `pfac' <= 0 {
                        di as error "sectorscaleoverride(): the scale factor for `sname' must be greater than 0. (sectorscaleoverride() 中 `sname' 的缩放倍数必须大于0。)"
                        exit 198
                    }
                    matrix `SecWeight'[1,`i'] = el(`SecWeight',1,`i') * `pfac'
                }
            }
        }
    }
    local sumweight = 0
    forvalues i = 1/`nsec' {
        local sumweight = `sumweight' + el(`SecWeight',1,`i')
    }
    if `sumweight' <= 0 {
        di as error "The sum of all sector weights must be greater than 0; check scale/sectorscaleoverride. (所有扇区权重之和必须大于0，请检查scale/sectorscaleoverride设置。)"
        exit 2000
    }

    local sumflow2 = 0
    forvalues i = 1/`nsec' {
        local sumflow2 = `sumflow2' + el(`Mout',1,`i') + el(`Min',1,`i')
    }

    tempname Msang Meang
    matrix `Msang' = J(1, `nsec', 0)
    matrix `Meang' = J(1, `nsec', 0)
    local cur = cond(`dirmult' == 1, 90 - `startangle', `startangle' - 90)
    if `auto2group' == 1 {
        local group1_span = 0
        forvalues i = 1/`n_group1' {
            local group1_span = `group1_span' + `eff_angle' * el(`SecWeight',1,`i') / `sumweight'
        }
        if `n_group1' > 1 {
            forvalues i = 1/`=`n_group1'-1' {
                local group1_span = `group1_span' + el(`GapArr',1,`i')
            }
        }
        local vtarget1 = cond("`splithorizontal'" != "", 90, 180)
        local cur = `dirmult' * `vtarget1' - `group1_span'/2 - `dirmult' * `startangle'
        di as text "Note: sectorgroup() yields exactly two groups; the diagram has been auto-rotated so that the two group centers align exactly " cond("`splithorizontal'" != "", "top and bottom (one group above, one below)", "left and right (one group on each side)") ", unaffected by sectorscaleoverride() and other scaling settings. Use startangle() for fine adjustment."
        di as text "提示：检测到sectorgroup()正好分为两组，已自动旋转图形，让两组中心严格对齐到" cond("`splithorizontal'" != "", "正上方与正下方", "正左方与正右方") "，不受sectorscaleoverride()等缩放设置影响；可用 startangle() 微调。"
    }
    forvalues i = 1/`nsec' {
        local ang = `eff_angle' * el(`SecWeight',1,`i') / `sumweight'
        matrix `Msang'[1,`i'] = `cur'
        matrix `Meang'[1,`i'] = `cur' + `ang'
        local cur = `cur' + `ang' + el(`GapArr',1,`i')
    }

    tempname FromSpan ToSpan
    matrix `FromSpan' = J(1, `nsec', 0)
    matrix `ToSpan'   = J(1, `nsec', 0)
    forvalues i = 1/`nsec' {
        local Mo = el(`Mout',1,`i')
        local Mi = el(`Min',1,`i')
        local Ti = `Mo' + `Mi'
        local span = el(`Meang',1,`i') - el(`Msang',1,`i')
        if `Ti' > 0  local fsp = `span' * `Mo' / `Ti'
        else         local fsp = `span' / 2
        matrix `FromSpan'[1,`i'] = `fsp'
        matrix `ToSpan'[1,`i']   = `span' - `fsp'
    }

    egen double _totF = total(`val_s'), by(from_s)
    egen double _totT = total(`val_s'), by(to_s)

    quietly gen double _sangF = .
    quietly gen double _eangF = .
    quietly gen double _sangT = .
    quietly gen double _eangT = .
    quietly gen double _fspanF = .
    quietly gen double _fspanT = .
    quietly gen double _tspanF = .
    quietly gen double _tspanT = .
    forvalues i = 1/`nsec' {
        local sname : word `i' of `sectors'
        local fsp = el(`FromSpan',1,`i')
        local tsp = el(`ToSpan',1,`i')
        quietly replace _sangF  = el(`Msang',1,`i') if from_s == `"`sname'"'
        quietly replace _eangF  = el(`Meang',1,`i') if from_s == `"`sname'"'
        quietly replace _fspanF = `fsp'              if from_s == `"`sname'"'
        quietly replace _tspanF = `tsp'              if from_s == `"`sname'"'
        quietly replace _sangT  = el(`Msang',1,`i') if to_s   == `"`sname'"'
        quietly replace _eangT  = el(`Meang',1,`i') if to_s   == `"`sname'"'
        quietly replace _fspanT = `fsp'              if to_s   == `"`sname'"'
        quietly replace _tspanT = `tsp'              if to_s   == `"`sname'"'
    }

    cap drop _bdist
    cap drop _negbdist
    cap drop _negval
    quietly gen long   _bdist    = mod(_fidx - _tidx, `nsec')
    quietly replace _bdist = 0 if _ispriority == 1
    quietly gen long   _negbdist = -_bdist
    quietly gen double _negval   = -`val_s'
    quietly gen double _keyF = .
    quietly gen double _keyT = .
    local n_loop = 1
    if `"`linksort'"' == "asis" {
        quietly replace _keyF = _origorder
        quietly replace _keyT = _origorder
        quietly replace _keyF = -1e9 if _ispriority == 1
        quietly replace _keyT = -1e9 if _ispriority == 1
    }
    else if `"`linksort'"' == "value" {
        quietly replace _keyF = _negval
        quietly replace _keyT = _negval
        quietly replace _keyF = -1e9 if _ispriority == 1
        quietly replace _keyT = -1e9 if _ispriority == 1
    }
    else {
        quietly replace _keyF = _bdist
        quietly replace _keyT = _negbdist
        quietly replace _keyF = -1e9 if _ispriority == 1
        quietly replace _keyT =  1e9 if _ispriority == 1
        if `"`linksort'"' == "minimize" local n_loop = `niter'
    }
    tempname SeedAngFs SeedAngFe SeedAngTs SeedAngTe
    local seed_cross = .
    local final_cross = .

    forvalues iter = 1/`n_loop' {
        cap drop _cumF
        cap drop _cumT
        quietly sort from_s _keyF
        by from_s: gen double _cumF = sum(`val_s')
        quietly sort to_s _keyT
        by to_s: gen double _cumT = sum(`val_s')

        cap drop _startfracF
        cap drop _endfracF
        cap drop _startfracT
        cap drop _endfracT
        quietly gen double _startfracF = (_cumF - `val_s') / _totF
        quietly gen double _endfracF   = _cumF / _totF
        quietly gen double _startfracT = (_cumT - `val_s') / _totT
        quietly gen double _endfracT   = _cumT / _totT

        cap drop _angFs
        cap drop _angFe
        cap drop _angTs
        cap drop _angTe
        if `fromatlower' == 1 {
            quietly gen double _angFs = _sangF + _startfracF * _fspanF
            quietly gen double _angFe = _sangF + _endfracF   * _fspanF
            quietly gen double _angTs = (_sangT + _fspanT) + _startfracT * _tspanT
            quietly gen double _angTe = (_sangT + _fspanT) + _endfracT   * _tspanT
        }
        else {
            quietly gen double _angFs = (_sangF + _tspanF) + _startfracF * _fspanF
            quietly gen double _angFe = (_sangF + _tspanF) + _endfracF   * _fspanF
            quietly gen double _angTs = _sangT + _startfracT * _tspanT
            quietly gen double _angTe = _sangT + _endfracT   * _tspanT
        }

        if `iter' == 1 {
            sort _origorder
            matrix `SeedAngFs' = J(`nedges',1,.)
            matrix `SeedAngFe' = J(`nedges',1,.)
            matrix `SeedAngTs' = J(`nedges',1,.)
            matrix `SeedAngTe' = J(`nedges',1,.)
            forvalues e = 1/`nedges' {
                matrix `SeedAngFs'[`e',1] = _angFs[`e']
                matrix `SeedAngFe'[`e',1] = _angFe[`e']
                matrix `SeedAngTs'[`e',1] = _angTs[`e']
                matrix `SeedAngTe'[`e',1] = _angTe[`e']
            }
            local seed_cross = 0
            forvalues e1 = 1/`=`nedges'-1' {
                local mF1 = (el(`SeedAngFs',`e1',1)+el(`SeedAngFe',`e1',1))/2
                local mT1 = (el(`SeedAngTs',`e1',1)+el(`SeedAngTe',`e1',1))/2
                forvalues e2 = `=`e1'+1'/`nedges' {
                    local mF2 = (el(`SeedAngFs',`e2',1)+el(`SeedAngFe',`e2',1))/2
                    local mT2 = (el(`SeedAngTs',`e2',1)+el(`SeedAngTe',`e2',1))/2
                    local b1 = mod(`mF2'-`mF1',360) < mod(`mT1'-`mF1',360)
                    local b2 = mod(`mT2'-`mF1',360) < mod(`mT1'-`mF1',360)
                    if `b1' != `b2' local seed_cross = `seed_cross' + 1
                }
            }
        }

        if `"`linksort'"' == "minimize" & `iter' < `n_loop' {
            cap drop _midF
            cap drop _midT
            quietly gen double _midF = (_angFs + _angFe) / 2
            quietly gen double _midT = (_angTs + _angTe) / 2
            cap drop _relF
            cap drop _relT
            quietly gen double _relF = mod(_midT - _sangF, 360)
            quietly gen double _relT = mod(_midF - _sangT, 360)
            quietly replace _keyF = _relF
            quietly replace _keyT = _relT
            quietly replace _keyF = -1e9 if _ispriority == 1
            quietly replace _keyT =  1e9 if _ispriority == 1
        }
    }

    if `"`linksort'"' == "minimize" {
        sort _origorder
        tempname FinalAngFs FinalAngFe FinalAngTs FinalAngTe
        matrix `FinalAngFs' = J(`nedges',1,.)
        matrix `FinalAngFe' = J(`nedges',1,.)
        matrix `FinalAngTs' = J(`nedges',1,.)
        matrix `FinalAngTe' = J(`nedges',1,.)
        forvalues e = 1/`nedges' {
            matrix `FinalAngFs'[`e',1] = _angFs[`e']
            matrix `FinalAngFe'[`e',1] = _angFe[`e']
            matrix `FinalAngTs'[`e',1] = _angTs[`e']
            matrix `FinalAngTe'[`e',1] = _angTe[`e']
        }
        local final_cross = 0
        forvalues e1 = 1/`=`nedges'-1' {
            local mF1 = (el(`FinalAngFs',`e1',1)+el(`FinalAngFe',`e1',1))/2
            local mT1 = (el(`FinalAngTs',`e1',1)+el(`FinalAngTe',`e1',1))/2
            forvalues e2 = `=`e1'+1'/`nedges' {
                local mF2 = (el(`FinalAngFs',`e2',1)+el(`FinalAngFe',`e2',1))/2
                local mT2 = (el(`FinalAngTs',`e2',1)+el(`FinalAngTe',`e2',1))/2
                local b1 = mod(`mF2'-`mF1',360) < mod(`mT1'-`mF1',360)
                local b2 = mod(`mT2'-`mF1',360) < mod(`mT1'-`mF1',360)
                if `b1' != `b2' local final_cross = `final_cross' + 1
            }
        }

        if `final_cross' <= `seed_cross' {
            tempname AngFs AngFe AngTs AngTe
            matrix `AngFs' = `FinalAngFs'
            matrix `AngFe' = `FinalAngFe'
            matrix `AngTs' = `FinalAngTs'
            matrix `AngTe' = `FinalAngTe'
            local used_which "refined layout (迭代细化后)"
        }
        else {
            tempname AngFs AngFe AngTs AngTe
            matrix `AngFs' = `SeedAngFs'
            matrix `AngFe' = `SeedAngFe'
            matrix `AngTs' = `SeedAngTs'
            matrix `AngTe' = `SeedAngTe'
            local used_which "seed layout, refinement did not improve so it was reverted (种子方案，迭代细化没有改善，已自动回退)"
        }
        di as text "Crossing pairs (交叉对数): seed (种子方案) = `seed_cross', refined (迭代细化后) = `final_cross'; using (最终采用): `used_which'"
    }
    else {
        quietly count if missing(_angFs) | missing(_angFe) | missing(_angTs) | missing(_angTe)
        if r(N) > 0 {
            di as error "Missing values occurred in angle computation. (角度计算出现缺失值。)"
            list from_s to_s `val_s' _angFs _angFe _angTs _angTe if missing(_angFs) | missing(_angFe) | missing(_angTs) | missing(_angTe)
            exit 498
        }
        sort _origorder
        tempname AngFs AngFe AngTs AngTe
        matrix `AngFs' = J(`nedges', 1, .)
        matrix `AngFe' = J(`nedges', 1, .)
        matrix `AngTs' = J(`nedges', 1, .)
        matrix `AngTe' = J(`nedges', 1, .)
        forvalues e = 1/`nedges' {
            matrix `AngFs'[`e',1] = _angFs[`e']
            matrix `AngFe'[`e',1] = _angFe[`e']
            matrix `AngTs'[`e',1] = _angTs[`e']
            matrix `AngTe'[`e',1] = _angTe[`e']
        }
    }

    * ============ ribbonposition(): pin the F-end/T-end of listed ribbons to
    * any physical slot within the sector's WHOLE arc (global numbering), not
    * just within their own from/to block.
    * Semantics: from(#) is the slot of this edge within its from-sector fs;
    *            to(#) is the slot within its to-sector ts; from- and to-pins
    * share ONE slot numbering per sector (1..total edges touching it), so
    * pins within the same sector must not collide.
    * 中文说明：from()/to()钉子共享同一套"扇区整体位点编号"，不区分角色，
    * 同一扇区内不能冲突；未钉住的端点按自然顺序回填剩余槽位。
    * ============
    if `rp_nseg' > 0 {
        tempname NewAngFs NewAngFe NewAngTs NewAngTe
        matrix `NewAngFs' = `AngFs'
        matrix `NewAngFe' = `AngFe'
        matrix `NewAngTs' = `AngTs'
        matrix `NewAngTe' = `AngTe'

        forvalues i = 1/`nsec' {
            local sname : word `i' of `sectors'

            * Edges where this sector is the from-end.
            local flist ""
            forvalues e = 1/`nedges' {
                if el(`ME',`e',1) == `i' local flist `flist' `e'
            }
            local nF : word count `flist'

            * Edges where this sector is the to-end.
            local tlist ""
            forvalues e = 1/`nedges' {
                if el(`ME',`e',2) == `i' local tlist `tlist' `e'
            }
            local nT : word count `tlist'

            local ntot_i = `nF' + `nT'
            if `ntot_i' > 0 {

                * Natural F order: sorted by the pre-override AngFs.
                local fnatural ""
                if `nF' > 0 {
                    tempname FKey
                    matrix `FKey' = J(`nF', 2, .)
                    local k = 0
                    foreach e of local flist {
                        local k = `k' + 1
                        matrix `FKey'[`k',1] = `e'
                        matrix `FKey'[`k',2] = el(`AngFs',`e',1)
                    }
                    forvalues a = 1/`=`nF'-1' {
                        forvalues b = 1/`=`nF'-`a'' {
                            if el(`FKey',`b',2) > el(`FKey',`b'+1,2) {
                                local te = el(`FKey',`b',1)
                                local tv = el(`FKey',`b',2)
                                matrix `FKey'[`b',1]   = el(`FKey',`b'+1,1)
                                matrix `FKey'[`b',2]   = el(`FKey',`b'+1,2)
                                matrix `FKey'[`b'+1,1] = `te'
                                matrix `FKey'[`b'+1,2] = `tv'
                            }
                        }
                    }
                    forvalues k = 1/`nF' {
                        local fnatural `fnatural' `=el(`FKey',`k',1)'
                    }
                }

                * Natural T order: sorted by the pre-override AngTs.
                local tnatural ""
                if `nT' > 0 {
                    tempname TKey
                    matrix `TKey' = J(`nT', 2, .)
                    local k = 0
                    foreach e of local tlist {
                        local k = `k' + 1
                        matrix `TKey'[`k',1] = `e'
                        matrix `TKey'[`k',2] = el(`AngTs',`e',1)
                    }
                    forvalues a = 1/`=`nT'-1' {
                        forvalues b = 1/`=`nT'-`a'' {
                            if el(`TKey',`b',2) > el(`TKey',`b'+1,2) {
                                local te = el(`TKey',`b',1)
                                local tv = el(`TKey',`b',2)
                                matrix `TKey'[`b',1]   = el(`TKey',`b'+1,1)
                                matrix `TKey'[`b',2]   = el(`TKey',`b'+1,2)
                                matrix `TKey'[`b'+1,1] = `te'
                                matrix `TKey'[`b'+1,2] = `tv'
                            }
                        }
                    }
                    forvalues k = 1/`nT' {
                        local tnatural `tnatural' `=el(`TKey',`k',1)'
                    }
                }

                * Merge into the sector's default combined order, following
                * blockorder(): F before T when fromatlower==1, else T before
                * F -- so without any pins the angles reproduce the old
                * (block-based) layout position by position.
                local combined_e ""
                local combined_role ""
                if `fromatlower' == 1 {
                    foreach e of local fnatural {
                        local combined_e `combined_e' `e'
                        local combined_role `combined_role' F
                    }
                    foreach e of local tnatural {
                        local combined_e `combined_e' `e'
                        local combined_role `combined_role' T
                    }
                }
                else {
                    foreach e of local tnatural {
                        local combined_e `combined_e' `e'
                        local combined_role `combined_role' T
                    }
                    foreach e of local fnatural {
                        local combined_e `combined_e' `e'
                        local combined_role `combined_role' F
                    }
                }

                * Validate all from()/to() pins for this sector: range
                * 1..ntot_i, and from/to share one numbering (no collisions).
                local usedranks ""
                forvalues k = 1/`nF' {
                    local e : word `k' of `fnatural'
                    local pf `"`pinfrom_`e''"'
                    if `"`pf'"' != "." {
                        if `pf' < 1 | `pf' > `ntot_i' {
                            di as error "ribbonposition(): from() slot `pf' for sector `sname' is out of range (this sector has `ntot_i' physical slots: `nF' from-edges + `nT' to-edges). (ribbonposition() 中扇区`sname'的from()排位`pf'超出范围。)"
                            exit 198
                        }
                        local dup : list pf in usedranks
                        if `dup' == 1 {
                            di as error "ribbonposition(): slot `pf' of sector `sname' is claimed more than once; from() and to() share one slot numbering within a sector. (ribbonposition() 中扇区`sname'的位点`pf'被重复指定；同一扇区内from()与to()共享同一套整体编号。)"
                            exit 198
                        }
                        local usedranks `usedranks' `pf'
                    }
                }
                forvalues k = 1/`nT' {
                    local e : word `k' of `tnatural'
                    local pt `"`pinto_`e''"'
                    if `"`pt'"' != "." {
                        if `pt' < 1 | `pt' > `ntot_i' {
                            di as error "ribbonposition(): to() slot `pt' for sector `sname' is out of range (this sector has `ntot_i' physical slots: `nF' from-edges + `nT' to-edges). (ribbonposition() 中扇区`sname'的to()排位`pt'超出范围。)"
                            exit 198
                        }
                        local dup : list pt in usedranks
                        if `dup' == 1 {
                            di as error "ribbonposition(): slot `pt' of sector `sname' is claimed more than once; from() and to() share one slot numbering within a sector. (ribbonposition() 中扇区`sname'的位点`pt'被重复指定；同一扇区内from()与to()共享同一套整体编号。)"
                            exit 198
                        }
                        local usedranks `usedranks' `pt'
                    }
                }

                * Assemble the final slot arrays: place pins first, then fill
                * the remaining slots with unpinned endpoints in combined_e
                * relative order.
                tempname FullSlotE FullSlotR
                matrix `FullSlotE' = J(`ntot_i', 1, 0)
                matrix `FullSlotR' = J(`ntot_i', 1, 0)

                forvalues k = 1/`nF' {
                    local e : word `k' of `fnatural'
                    local pf `"`pinfrom_`e''"'
                    if `"`pf'"' != "." {
                        matrix `FullSlotE'[`pf',1] = `e'
                        matrix `FullSlotR'[`pf',1] = 1
                    }
                }
                forvalues k = 1/`nT' {
                    local e : word `k' of `tnatural'
                    local pt `"`pinto_`e''"'
                    if `"`pt'"' != "." {
                        matrix `FullSlotE'[`pt',1] = `e'
                        matrix `FullSlotR'[`pt',1] = 2
                    }
                }

                local remain_e ""
                local remain_r ""
                local ncomb : word count `combined_e'
                forvalues k = 1/`ncomb' {
                    local e  : word `k' of `combined_e'
                    local rl : word `k' of `combined_role'
                    local ispinned = 0
                    if "`rl'" == "F" & `"`pinfrom_`e''"' != "." local ispinned = 1
                    if "`rl'" == "T" & `"`pinto_`e''"'   != "." local ispinned = 1
                    if `ispinned' == 0 {
                        local remain_e `remain_e' `e'
                        local remain_r `remain_r' `rl'
                    }
                }
                local rp = 0
                forvalues slot = 1/`ntot_i' {
                    if el(`FullSlotE',`slot',1) == 0 {
                        local rp = `rp' + 1
                        local fillE : word `rp' of `remain_e'
                        local fillR : word `rp' of `remain_r'
                        matrix `FullSlotE'[`slot',1] = `fillE'
                        matrix `FullSlotR'[`slot',1] = cond("`fillR'"=="F", 1, 2)
                    }
                }

                * Accumulate widths in final slot order (the formula is
                * role-agnostic) and write back to the angle matrices.
                local sang_i = el(`Msang',1,`i')
                local span_i = el(`Meang',1,`i') - el(`Msang',1,`i')
                local Ti = el(`Mout',1,`i') + el(`Min',1,`i')
                local cum = 0
                forvalues slot = 1/`ntot_i' {
                    local e  = el(`FullSlotE',`slot',1)
                    local rl = el(`FullSlotR',`slot',1)
                    local v  = el(`ME',`e',3)
                    local sf = `cum' / `Ti'
                    local cum = `cum' + `v'
                    local ef = `cum' / `Ti'
                    if `rl' == 1 {
                        matrix `NewAngFs'[`e',1] = `sang_i' + `sf' * `span_i'
                        matrix `NewAngFe'[`e',1] = `sang_i' + `ef' * `span_i'
                    }
                    else {
                        matrix `NewAngTs'[`e',1] = `sang_i' + `sf' * `span_i'
                        matrix `NewAngTe'[`e',1] = `sang_i' + `ef' * `span_i'
                    }
                }
            }
        }

        matrix `AngFs' = `NewAngFs'
        matrix `AngFe' = `NewAngFe'
        matrix `AngTs' = `NewAngTs'
        matrix `AngTe' = `NewAngTe'
    }

if `"`scheme'"' != "" {
    local origscheme = c(scheme)
    quietly set scheme `scheme'
    cap quietly gr_setscheme
    forvalues k = 1/15 {
        cap local schemep`k' `.__SCHEME.color.p`k''
    }
    quietly set scheme `origscheme'
}

local hexchars "0123456789ABCDEF"
    forvalues i = 1/`nsec' {
        local sname : word `i' of `sectors'

        * Displayed sector text: defaults to the original name (sname), which
        * is what the data and all matching options (sectorgroup, overrides)
        * keep referring to; only displabel_`i' -- the text actually drawn --
        * is replaced when sectorlabeloverride() names this sector.
        * 中文说明：displabel仅影响画到图上的文字，其余匹配一律用原名。
        local displabel_`i' "`sname'"
        forvalues s = 1/`slo_nseg' {
            local pr `"`slo_seg`s''"'
            local sep = strpos(`"`pr'"', "-")
            if `sep' > 0 {
                local pname = strtrim(substr(`"`pr'"', 1, `sep'-1))
                local pdisp = strtrim(substr(`"`pr'"', `sep'+1, .))
                if "`sname'" == "`pname'" {
                    local displabel_`i' `"`pdisp'"'
                }
            }
        }

        local usercol : word `i' of `colorlist'
        if `"`usercol'"' == "" {
            if `"`scheme'"' != "" {
                local pidx = mod(`i'-1, 15) + 1
                local color_`i' `"`schemep`pidx''"'
            }
            else {
                local hue = 360 * (`i'-1) / `nsec'
                local color_`i' `"hsv `hue' 0.7 0.8"'
            }
            local ribalpha_`i' = `alpha'
        }
        else {
            _chordcolor_parse `"`usercol'"' "`hexchars'"
            local color_`i' `"`r(parsedcolor)'"'
            if `"`r(parsedalpha)'"' == "" local ribalpha_`i' = `alpha'
            else                          local ribalpha_`i' = `r(parsedalpha)'
        }

        local ringusercol : word `i' of `ringcolorlist'
        if `"`ringusercol'"' == "" {
            local ringcolor_`i' `"`color_`i''"'
            local ringalpha_`i' = `ringalpha'
        }
        else {
            _chordcolor_parse `"`ringusercol'"' "`hexchars'"
            local ringcolor_`i' `"`r(parsedcolor)'"'
            if `"`r(parsedalpha)'"' == "" local ringalpha_`i' = `ringalpha'
            else                          local ringalpha_`i' = `r(parsedalpha)'
        }

        if `"`labelcolor'"' == "" {
            local labelcol "black"
            local labelcolalpha = `labelalpha'
        }
        else {
            _chordcolor_parse `"`labelcolor'"' "`hexchars'"
            local labelcol `"`r(parsedcolor)'"'
            if `"`r(parsedalpha)'"' == "" local labelcolalpha = `labelalpha'
            else                          local labelcolalpha = `r(parsedalpha)'
        }

        local labusercol : word `i' of `labelcolorlist'
        if `"`labusercol'"' == "" {
            local labelcol_`i' `"`labelcol'"'
            local labelalpha_`i' = `labelcolalpha'
        }
        else {
            _chordcolor_parse `"`labusercol'"' "`hexchars'"
            local labelcol_`i' `"`r(parsedcolor)'"'
            if `"`r(parsedalpha)'"' == "" local labelalpha_`i' = `labelalpha'
            else                          local labelalpha_`i' = `r(parsedalpha)'
        }

        local labsize_`i' `"`labelsize'"'
        local ticklabsize_`i' `"`ticklabsize'"'
        local tcusercol : word `i' of `tickcolorlist'
        if `"`tcusercol'"' == "" {
            _chordcolor_parse `"`tickcolor'"' "`hexchars'"
            local tickcolor_`i' `"`r(parsedcolor)'"'
            if `"`r(parsedalpha)'"' == "" local tickalpha_`i' = `tickalpha'
            else                          local tickalpha_`i' = `r(parsedalpha)'
        }
        else {
            _chordcolor_parse `"`tcusercol'"' "`hexchars'"
            local tickcolor_`i' `"`r(parsedcolor)'"'
            if `"`r(parsedalpha)'"' == "" local tickalpha_`i' = `tickalpha'
            else                          local tickalpha_`i' = `r(parsedalpha)'
        }

        local tlcusercol : word `i' of `ticklabcolorlist'
        if `"`tlcusercol'"' == "" {
            _chordcolor_parse `"`ticklabcolor'"' "`hexchars'"
            local ticklabcolor_`i' `"`r(parsedcolor)'"'
            if `"`r(parsedalpha)'"' == "" local ticklabalpha_`i' = `ticklabalpha'
            else                          local ticklabalpha_`i' = `r(parsedalpha)'
        }
        else {
            _chordcolor_parse `"`tlcusercol'"' "`hexchars'"
            local ticklabcolor_`i' `"`r(parsedcolor)'"'
            if `"`r(parsedalpha)'"' == "" local ticklabalpha_`i' = `ticklabalpha'
            else                          local ticklabalpha_`i' = `r(parsedalpha)'
        }

        foreach pr of local labelcoloroverride {
            local sep = strpos(`"`pr'"', "-")
            if `sep' > 0 {
                local pname = substr(`"`pr'"', 1, `sep'-1)
                local pcol  = substr(`"`pr'"', `sep'+1, .)
                if "`sname'" == "`pname'" {
                    _chordcolor_parse `"`pcol'"' "`hexchars'"
                    local labelcol_`i' `"`r(parsedcolor)'"'
                    if `"`r(parsedalpha)'"' == "" local labelalpha_`i' = `labelalpha_`i''
                    else                          local labelalpha_`i' = `r(parsedalpha)'
                }
            }
        }
        foreach pr of local labelsizeoverride {
            local sep = strpos(`"`pr'"', "-")
            if `sep' > 0 {
                local pname = substr(`"`pr'"', 1, `sep'-1)
                local psize = substr(`"`pr'"', `sep'+1, .)
                if "`sname'" == "`pname'" {
                    local labsize_`i' `"`psize'"'
                }
            }
        }
        foreach pr of local tickcoloroverride {
            local sep = strpos(`"`pr'"', "-")
            if `sep' > 0 {
                local pname = substr(`"`pr'"', 1, `sep'-1)
                local pcol  = substr(`"`pr'"', `sep'+1, .)
                if "`sname'" == "`pname'" {
                    _chordcolor_parse `"`pcol'"' "`hexchars'"
                    local tickcolor_`i' `"`r(parsedcolor)'"'
                    if `"`r(parsedalpha)'"' == "" local tickalpha_`i' = `tickalpha_`i''
                    else                          local tickalpha_`i' = `r(parsedalpha)'
                }
            }
        }
        foreach pr of local ticklabcoloroverride {
            local sep = strpos(`"`pr'"', "-")
            if `sep' > 0 {
                local pname = substr(`"`pr'"', 1, `sep'-1)
                local pcol  = substr(`"`pr'"', `sep'+1, .)
                if "`sname'" == "`pname'" {
                    _chordcolor_parse `"`pcol'"' "`hexchars'"
                    local ticklabcolor_`i' `"`r(parsedcolor)'"'
                    if `"`r(parsedalpha)'"' == "" local ticklabalpha_`i' = `ticklabalpha_`i''
                    else                          local ticklabalpha_`i' = `r(parsedalpha)'
                }
            }
        }
        foreach pr of local ticklabsizeoverride {
            local sep = strpos(`"`pr'"', "-")
            if `sep' > 0 {
                local pname = substr(`"`pr'"', 1, `sep'-1)
                local psize = substr(`"`pr'"', `sep'+1, .)
                if "`sname'" == "`pname'" {
                    local ticklabsize_`i' `"`psize'"'
                }
            }
        }

        * Percentage axis: per-sector colors/sizes, same mechanism as the
        * value axis (tickcolor/ticklabcolor).
        if "`pctticks'" != "" {
            local pcttcusercol : word `i' of `pcttickcolorlist'
            if `"`pcttcusercol'"' == "" {
                _chordcolor_parse `"`pcttickcolor'"' "`hexchars'"
                local pcttickcolor_`i' `"`r(parsedcolor)'"'
                if `"`r(parsedalpha)'"' == "" local pcttickalpha_`i' = `tickalpha'
                else                          local pcttickalpha_`i' = `r(parsedalpha)'
            }
            else {
                _chordcolor_parse `"`pcttcusercol'"' "`hexchars'"
                local pcttickcolor_`i' `"`r(parsedcolor)'"'
                if `"`r(parsedalpha)'"' == "" local pcttickalpha_`i' = `tickalpha'
                else                          local pcttickalpha_`i' = `r(parsedalpha)'
            }

            local pcttlcusercol : word `i' of `pctticklabcolorlist'
            if `"`pcttlcusercol'"' == "" {
                _chordcolor_parse `"`pctticklabcolor'"' "`hexchars'"
                local pctticklabcolor_`i' `"`r(parsedcolor)'"'
                if `"`r(parsedalpha)'"' == "" local pctticklabalpha_`i' = `ticklabalpha'
                else                          local pctticklabalpha_`i' = `r(parsedalpha)'
            }
            else {
                _chordcolor_parse `"`pcttlcusercol'"' "`hexchars'"
                local pctticklabcolor_`i' `"`r(parsedcolor)'"'
                if `"`r(parsedalpha)'"' == "" local pctticklabalpha_`i' = `ticklabalpha'
                else                          local pctticklabalpha_`i' = `r(parsedalpha)'
            }

            local pctticklabsize_`i' `"`pctticklabsize'"'

            foreach pr of local pcttickcoloroverride {
                local sep = strpos(`"`pr'"', "-")
                if `sep' > 0 {
                    local pname = substr(`"`pr'"', 1, `sep'-1)
                    local pcol  = substr(`"`pr'"', `sep'+1, .)
                    if "`sname'" == "`pname'" {
                        _chordcolor_parse `"`pcol'"' "`hexchars'"
                        local pcttickcolor_`i' `"`r(parsedcolor)'"'
                        if `"`r(parsedalpha)'"' == "" local pcttickalpha_`i' = `pcttickalpha_`i''
                        else                          local pcttickalpha_`i' = `r(parsedalpha)'
                    }
                }
            }
            foreach pr of local pctticklabcoloroverride {
                local sep = strpos(`"`pr'"', "-")
                if `sep' > 0 {
                    local pname = substr(`"`pr'"', 1, `sep'-1)
                    local pcol  = substr(`"`pr'"', `sep'+1, .)
                    if "`sname'" == "`pname'" {
                        _chordcolor_parse `"`pcol'"' "`hexchars'"
                        local pctticklabcolor_`i' `"`r(parsedcolor)'"'
                        if `"`r(parsedalpha)'"' == "" local pctticklabalpha_`i' = `pctticklabalpha_`i''
                        else                          local pctticklabalpha_`i' = `r(parsedalpha)'
                    }
                }
            }
            foreach pr of local pctticklabsizeoverride {
                local sep = strpos(`"`pr'"', "-")
                if `sep' > 0 {
                    local pname = substr(`"`pr'"', 1, `sep'-1)
                    local psize = substr(`"`pr'"', `sep'+1, .)
                    if "`sname'" == "`pname'" {
                        local pctticklabsize_`i' `"`psize'"'
                    }
                }
            }
        }
    }

    clear
    quietly set obs 1

    clear
    quietly set obs 1
    quietly gen double _x = .
    quietly gen double _y = .
    quietly gen long   _id = .
    quietly gen double _aX1 = .
    quietly gen double _aY1 = .
    quietly gen double _aX2 = .
    quietly gen double _aY2 = .
    quietly gen long   _aid = .
    local pi = _pi

    local rin_anchor = 1 - `ringwidth'
    local toendext    = cond(`toendouter' > 0, `toendouter', 0)
    local rout = 1 + `toendext'
    local rin  = `rout' - `ringwidth'

    forvalues i = 1/`nsec' {
        local s0 = el(`Msang',1,`i')
        local s1 = el(`Meang',1,`i')

        local base0 = _N
        local ntot  = `nring' + `nring' + 2
        quietly set obs `=`base0' + `ntot''
        local r = `base0'

        forvalues k = 0/`=`nring'-1' {
            local r = `r' + 1
            local frac = `k' / (`nring'-1)
            local ang  = `s0' + `frac' * (`s1' - `s0')
            local rad  = `ang' * `pi' / 180
            quietly replace _x  = `rout' * cos(`rad')           in `r'
            quietly replace _y  = `rout' * sin(`dirmult'*`rad') in `r'
            quietly replace _id = `i'                            in `r'
        }
        local r = `r' + 1
        local rad1 = `s1' * `pi' / 180
        quietly replace _x  = `rin' * cos(`rad1')           in `r'
        quietly replace _y  = `rin' * sin(`dirmult'*`rad1') in `r'
        quietly replace _id = `i'                            in `r'

        forvalues k = 1/`=`nring'-1' {
            local r = `r' + 1
            local frac = `k' / (`nring'-1)
            local ang  = `s1' - `frac' * (`s1' - `s0')
            local rad  = `ang' * `pi' / 180
            quietly replace _x  = `rin' * cos(`rad')           in `r'
            quietly replace _y  = `rin' * sin(`dirmult'*`rad') in `r'
            quietly replace _id = `i'                            in `r'
        }
        local r = `r' + 1
        local rad0 = `s0' * `pi' / 180
        quietly replace _x  = `rout' * cos(`rad0')           in `r'
        quietly replace _y  = `rout' * sin(`dirmult'*`rad0') in `r'
        quietly replace _id = `i'                              in `r'
    }

local ribbongap_user = `ribbongap'
    if `ribbongap' == -1 local ribbongap = 0.04

    if "`interseg'" != "" {
        local intersegout   = `rin_anchor' - `intersegoutgap'
        local interseginner = `intersegout' - `intersegwidth'
        if `ribbongap_user' == -1 {
            local ribbonrim = `interseginner' - `intersegingap'
        }
        else {
            local ribbonrim = `interseginner' - `intersegingap' - `ribbongap'
        }
        local ribbonrim_to = `ribbonrim' + `toendouter'
    }
    else {
        local ribbonrim    = `rin_anchor' - `ribbongap'
        local ribbonrim_to = `ribbonrim' + `toendouter'
    }
    local rapex    = `ribbonrim_to' + `arrowgap'/2
    local rfromrib = `ribbonrim'

    forvalues e = 1/`nedges' {
        local curid = `nsec' + `e'

        local aFs = el(`AngFs',`e',1)
        local aFe = el(`AngFe',`e',1)
        local aTs = el(`AngTs',`e',1)
        local aTe = el(`AngTe',`e',1)
        local aTmid = (`aTs' + `aTe') / 2

        local nTseg = cond("`arrow'" != "", 3, `nrim')
        local ntot  = `nrim' + `nconn' + `nTseg' + `nconn'

        local base0 = _N
        quietly set obs `=`base0' + `ntot''
        local r = `base0'

        * Segment 1: F-end arc (always smooth), at the shrunken rfromrib radius.
        forvalues k = 0/`=`nrim'-1' {
            local r = `r' + 1
            local frac = `k' / (`nrim'-1)
            local ang  = `aFs' + `frac' * (`aFe' - `aFs')
            local rad  = `ang' * `pi' / 180
            quietly replace _x  = `rfromrib' * cos(`rad')           in `r'
            quietly replace _y  = `rfromrib' * sin(`dirmult'*`rad') in `r'
            quietly replace _id = `curid'                         in `r'
        }

        * Segment 2: Bezier connection, F-end -> start of T-end.
        local p0x = `rfromrib' * cos(`aFe' * `pi' / 180)
        local p0y = `rfromrib' * sin(`dirmult' * `aFe' * `pi' / 180)
        local p3x = `ribbonrim_to' * cos(`aTs' * `pi' / 180)
        local p3y = `ribbonrim_to' * sin(`dirmult' * `aTs' * `pi' / 180)
        local c1x = `p0x' * (1 - `bulge_`e'')
        local c1y = `p0y' * (1 - `bulge_`e'')
        local c2x = `p3x' * (1 - `bulge_`e'')
        local c2y = `p3y' * (1 - `bulge_`e'')
        forvalues k = 1/`nconn' {
            local r = `r' + 1
            local t  = `k' / `nconn'
            local u  = 1 - `t'
            local bx = `u'^3*`p0x' + 3*`u'^2*`t'*`c1x' + 3*`u'*`t'^2*`c2x' + `t'^3*`p3x'
            local by = `u'^3*`p0y' + 3*`u'^2*`t'*`c1y' + 3*`u'*`t'^2*`c2y' + `t'^3*`p3y'
            quietly replace _x  = `bx'    in `r'
            quietly replace _y  = `by'    in `r'
            quietly replace _id = `curid' in `r'
        }

        * Segment 3: T-end -- smooth arc without arrow; with arrow, a
        * start->apex->end triangle merged into the SAME polygon (no separate
        * triangle layer).
        if "`arrow'" != "" {
            local r = `r' + 1
            local rad = `aTs' * `pi' / 180
            quietly replace _x  = `ribbonrim_to' * cos(`rad')           in `r'
            quietly replace _y  = `ribbonrim_to' * sin(`dirmult'*`rad') in `r'

            local r = `r' + 1
            local rad = `aTmid' * `pi' / 180
            quietly replace _x  = `rapex' * cos(`rad')           in `r'
            quietly replace _y  = `rapex' * sin(`dirmult'*`rad') in `r'
            quietly replace _id = `curid'                          in `r'

            local r = `r' + 1
            local rad = `aTe' * `pi' / 180
            quietly replace _x  = `ribbonrim_to' * cos(`rad')           in `r'
            quietly replace _y  = `ribbonrim_to' * sin(`dirmult'*`rad') in `r'
            quietly replace _id = `curid'                         in `r'
        }
        else {
            forvalues k = 0/`=`nrim'-1' {
                local r = `r' + 1
                local frac = `k' / (`nrim'-1)
                local ang  = `aTs' + `frac' * (`aTe' - `aTs')
                local rad  = `ang' * `pi' / 180
                quietly replace _x  = `ribbonrim_to' * cos(`rad')           in `r'
                quietly replace _y  = `ribbonrim_to' * sin(`dirmult'*`rad') in `r'
                quietly replace _id = `curid'                              in `r'
            }
        }

        * Segment 4: Bezier connection, T-end -> start of F-end, closing
        * the polygon.
        local p0x = `ribbonrim_to' * cos(`aTe' * `pi' / 180)
        local p0y = `ribbonrim_to' * sin(`dirmult' * `aTe' * `pi' / 180)
        local p3x = `rfromrib' * cos(`aFs' * `pi' / 180)
        local p3y = `rfromrib' * sin(`dirmult' * `aFs' * `pi' / 180)
        local c1x = `p0x' * (1 - `bulge_`e'')
        local c1y = `p0y' * (1 - `bulge_`e'')
        local c2x = `p3x' * (1 - `bulge_`e'')
        local c2y = `p3y' * (1 - `bulge_`e'')
        forvalues k = 1/`nconn' {
            local r = `r' + 1
            local t  = `k' / `nconn'
            local u  = 1 - `t'
            local bx = `u'^3*`p0x' + 3*`u'^2*`t'*`c1x' + 3*`u'*`t'^2*`c2x' + `t'^3*`p3x'
            local by = `u'^3*`p0y' + 3*`u'^2*`t'*`c1y' + 3*`u'*`t'^2*`c2y' + `t'^3*`p3y'
            quietly replace _x  = `bx'    in `r'
            quietly replace _y  = `by'    in `r'
            quietly replace _id = `curid' in `r'
        }

        if `linkflag_`e'' == 1 {
            local lkr_from = cond(`linkradiusfromcur_`e'' < 0, `rfromrib', `linkradiusfromcur_`e'')
            local lkr_to   = cond(`linkradiustocur_`e'' < 0, `ribbonrim_to', `linkradiustocur_`e'')
            if "`linkarrowtype_`e''" == "single" {
                local lkr_to = `lkr_to' - `linkarrowgap'
            }
            else if "`linkarrowtype_`e''" == "double" {
                local lkr_from = `lkr_from' - `linkarrowgap'
                local lkr_to   = `lkr_to'   - `linkarrowgap'
            }
            local midFang = (`aFs' + `aFe') / 2
            local midTang = (`aTs' + `aTe') / 2
            local lp0x = `lkr_from' * cos(`midFang' * `pi' / 180)
            local lp0y = `lkr_from' * sin(`dirmult' * `midFang' * `pi' / 180)
            local lp3x = `lkr_to'   * cos(`midTang' * `pi' / 180)
            local lp3y = `lkr_to'   * sin(`dirmult' * `midTang' * `pi' / 180)
            local lc1x = `lp0x' * (1 - `linkbulgecur_`e'')
            local lc1y = `lp0y' * (1 - `linkbulgecur_`e'')
            local lc2x = `lp3x' * (1 - `linkbulgecur_`e'')
            local lc2y = `lp3y' * (1 - `linkbulgecur_`e'')

            local lkid = `nsec' + `nedges' + 8000000 + `e'
            local lkpenx = `lp0x'
            local lkpeny = `lp0y'
            local lkfirstx = `lp3x'
            local lkfirsty = `lp3y'

            local lkbase = _N
            quietly set obs `=`lkbase' + `linkrescur_`e'' + 1'
            local r3 = `lkbase' + 1
            quietly replace _x  = `lp0x' in `r3'
            quietly replace _y  = `lp0y' in `r3'
            quietly replace _id = `lkid' in `r3'

            forvalues k = 1/`linkrescur_`e'' {
                local r3 = `r3' + 1
                local t  = `k' / `linkrescur_`e''
                local u  = 1 - `t'
                local bx = `u'^3*`lp0x' + 3*`u'^2*`t'*`lc1x' + 3*`u'*`t'^2*`lc2x' + `t'^3*`lp3x'
                local by = `u'^3*`lp0y' + 3*`u'^2*`t'*`lc1y' + 3*`u'*`t'^2*`lc2y' + `t'^3*`lp3y'
                quietly replace _x  = `bx'   in `r3'
                quietly replace _y  = `by'   in `r3'
                quietly replace _id = `lkid' in `r3'
                if `k' == `=`linkrescur_`e''-1' {
                    local lkpenx = `bx'
                    local lkpeny = `by'
                }
                if `k' == 1 {
                    local lkfirstx = `bx'
                    local lkfirsty = `by'
                }
            }

            if "`linkarrowtype_`e''" == "single" | "`linkarrowtype_`e''" == "double" {
                local arow = _N + 1
                quietly set obs `=_N + 1'
                quietly replace _aX1 = `lkpenx' in `arow'
                quietly replace _aY1 = `lkpeny' in `arow'
                quietly replace _aX2 = `lp3x'   in `arow'
                quietly replace _aY2 = `lp3y'   in `arow'
                quietly replace _aid = `lkid'   in `arow'
            }
            if "`linkarrowtype_`e''" == "double" {
                local arow2 = _N + 1
                quietly set obs `=_N + 1'
                quietly replace _aX1 = `lkfirstx' in `arow2'
                quietly replace _aY1 = `lkfirsty' in `arow2'
                quietly replace _aX2 = `lp0x'     in `arow2'
                quietly replace _aY2 = `lp0y'     in `arow2'
                quietly replace _aid = `=`lkid'+5000000' in `arow2'
            }
        }

        if "`interseg'" != "" {
            local ti = el(`ME',`e',2)
            local segcol `"`ringcolor_`ti''"'
            local segalpha = `ringalpha_`ti''
            local segid = `nsec' + `nedges' + 9000000 + `e'

            local base1 = _N
            local ntot1 = `intersegres'*2 + 2
            quietly set obs `=`base1' + `ntot1''
            local r2 = `base1'

            forvalues k = 0/`=`intersegres'-1' {
                local r2 = `r2' + 1
                local frac1 = `k' / (`intersegres'-1)
                local ang1  = `aFs' + `frac1' * (`aFe' - `aFs')
                local rad1  = `ang1' * `pi' / 180
                quietly replace _x  = `intersegout' * cos(`rad1')           in `r2'
                quietly replace _y  = `intersegout' * sin(`dirmult'*`rad1') in `r2'
                quietly replace _id = `segid'                                 in `r2'
            }

            forvalues k = 0/`=`intersegres'-1' {
                local r2 = `r2' + 1
                local frac1 = `k' / (`intersegres'-1)
                local ang1  = `aFe' - `frac1' * (`aFe' - `aFs')
                local rad1  = `ang1' * `pi' / 180
                quietly replace _x  = `interseginner' * cos(`rad1')           in `r2'
                quietly replace _y  = `interseginner' * sin(`dirmult'*`rad1') in `r2'
                quietly replace _id = `segid'                                   in `r2'
            }

            local r2 = `r2' + 1
            local radclose2 = `aFs' * `pi' / 180
            quietly replace _x  = `intersegout' * cos(`radclose2')           in `r2'
            quietly replace _y  = `intersegout' * sin(`dirmult'*`radclose2') in `r2'
            quietly replace _id = `segid'                                      in `r2'

            local segcolor_`segid' `"`segcol'"'
            local segalpha_`segid' = `segalpha'
        }
    }

    local lblbase = `nsec' + `nedges'

    if "`labelinside'" != "" local efflabelradius = (`rin' + `rout') / 2
    else                      local efflabelradius = `labelradius'

    local totalchars = 0

    forvalues i = 1/`nsec' {
        local sname : word `i' of `sectors'
        if `"`labeldir'"' == "curved" {
            if `curvedwestern_eff' == 1 {
                _chordfont_split `"`displabel_`i''"' `"`labelfont'"'
                local fontnch_`i' = r(nch)
                forvalues j = 1/`=r(nch)' {
                    local fontchar_`i'_`j' `"`r(char`j')'"'
                    local fontfont_`i'_`j' `"`r(font`j')'"'
                    if strlen(`"`fontchar_`i'_`j''"') >= 3 {
                        local fontwide_`i'_`j' = 1
                    }
                    else {
                        local fontwide_`i'_`j' = 0
                    }
                }
            }
            else {
                _chordfont_splitseg `"`displabel_`i''"' `"`labelfont'"'
                local fontnch_`i' = r(nseg)
                forvalues j = 1/`=r(nseg)' {
                    local fontchar_`i'_`j' `"`r(segtext`j')'"'
                    local fontfont_`i'_`j' `"`r(segfont`j')'"'
                    local fontwide_`i'_`j' = r(segwide`j')
                }
            }
            local nch = `fontnch_`i''
        }
        else local nch = 1
        local totalchars = `totalchars' + `nch'
    }

    local oldN = _N
    quietly set obs `=`oldN'+`totalchars''
    quietly gen str60 _lbl = ""

    local labrow = 0
    forvalues i = 1/`nsec' {
        local s0  = el(`Msang',1,`i')
        local s1  = el(`Meang',1,`i')
        local mid = (`s0'+`s1')/2
        local sname : word `i' of `sectors'

        local effmid = `dirmult' * `mid'
        local effmid = mod(`effmid', 360)
        if `effmid' < 0 local effmid = `effmid' + 360

        local on_left = (cos(`effmid' * `pi' / 180) < 0)
        local force_special = (`auto2group' == 1 & "`splithorizontal'" == "" & `gsize_`i'' == 1 & `on_left' == 1)

        if `"`labeldir'"' == "curved" {
            if `force_special' == 1 {
                local do_flip = 0
            }
            else {
                local do_flip = (sin(`effmid' * `pi' / 180) > 0)
            }
        }
        else if `"`labeldir'"' == "radial" {
            local do_flip = (cos(`effmid' * `pi' / 180) < 0)
        }
        else {
            local do_flip = 0
        }

        if `"`labeldir'"' == "curved" local nch = `fontnch_`i''
        else                          local nch = 1

        * ================================================================
        * Curved-mode "segment placement": wide characters (CJK/full-width;
        * one segment = one character) follow the original per-character rule
        * (each occupies a fixed curvechargap degrees); a narrow-character
        * segment (a run of Latin/digits) is placed as ONE unit whose angular
        * weight is (segment length x narrowcharwidth), so Western runs get a
        * realistic width while Stata renders their letter spacing natively --
        * "CJK char by char, Western as a run".
        * Whether the whole placement order is reversed is decided ONCE per
        * label; this is mathematically equivalent to the old per-character
        * koff logic (which was itself a single global reversal, never a
        * per-character one).  The force_special branch equals "no reversal"
        * and is folded into the unified logic.
        * 中文说明：整条标签只判断一次是否反转，与旧逐字符版本数学等价；
        * force_special分支等价于"不反转"，已并入统一公式。
        * ================================================================
        if `"`labeldir'"' == "curved" & `force_special' == 0 {
            local inupperhalf = (sin(`effmid' * `pi' / 180) > 0)
            local segreversed = 0
            if `inupperhalf' == 1 & "`labeltopflip'"    == "" local segreversed = 1
            if `inupperhalf' == 0 & "`labelbottomflip'" != "" local segreversed = 1
        }
        else {
            local segreversed = 0
        }

        if `"`labeldir'"' == "curved" {
            local dispseq_`i' ""
            if `segreversed' == 1 {
                forvalues k = `nch'(-1)1 {
                    local dispseq_`i' `dispseq_`i'' `k'
                }
            }
            else {
                forvalues k = 1/`nch' {
                    local dispseq_`i' `dispseq_`i'' `k'
                }
            }
            local totalweight_`i' = 0
            forvalues k = 1/`nch' {
                if `fontwide_`i'_`k'' == 1 {
                    local segw_`i'_`k' = 1
                }
                else {
                    local segw_`i'_`k' = ustrlen(`"`fontchar_`i'_`k''"') * `narrowcharwidth'
                }
                local totalweight_`i' = `totalweight_`i'' + `segw_`i'_`k''
            }
            local cumrun_`i' = 0
            foreach kk of local dispseq_`i' {
                local segcenter_`i'_`kk' = `cumrun_`i'' + `segw_`i'_`kk''/2 - `totalweight_`i''/2
                local cumrun_`i' = `cumrun_`i'' + `segw_`i'_`kk''
            }
        }

        forvalues k = 1/`nch' {
            local labrow = `labrow' + 1
            local row = `oldN' + `labrow'
            local lid = `lblbase' + `labrow'

            if `"`labeldir'"' == "curved" {
                local charang = `mid' + `dirmult' * `segcenter_`i'_`k'' * `curvechargap'
                if `"`fontfont_`i'_`k''"' != "" {
                    local chartext `"{fontface "`fontfont_`i'_`k''":`fontchar_`i'_`k''}"'
                }
                else {
                    local chartext `"`fontchar_`i'_`k''"'
                }
            }
            else {
                local charang = `mid'
                if `"`labelfont'"' != "" {
                    local chartext `"{fontface "`labelfont'":`displabel_`i''}"'
                }
                else {
                    local chartext `"`displabel_`i''"'
                }
            }

            local rad2 = `charang' * `pi' / 180
            local effang = `dirmult' * `charang'
            local effang = mod(`effang', 360)
            if `effang' < 0 local effang = `effang' + 360

            if `"`labeldir'"' == "horizontal" {
                local labang = 0
            }
            else if `"`labeldir'"' == "curved" {
                local labang = mod(`effang' + 90, 360)
                if `do_flip' == 1 local labang = `labang' - 180
            }
            else {
                local labang = `effang'
                if `do_flip' == 1 local labang = `labang' - 180
            }

            if `"`labeldir'"' == "curved" {
                if `do_flip' == 1 local labrad_adj = -`curvedlabeladjust'
                else               local labrad_adj = `curvedlabeladjust'
            }
            else local labrad_adj = 0
            local thislabelradius = `efflabelradius' + `labrad_adj'

            quietly replace _id  = `lid'                                in `row'
            quietly replace _x   = `thislabelradius' * cos(`rad2')           in `row'
            quietly replace _y   = `thislabelradius' * sin(`dirmult'*`rad2') in `row'
            quietly replace _lbl = `"`chartext'"'                       in `row'

            local labang_`lid' = `labang'
            local labelcol_`lid' `"`labelcol_`i''"'
            local labelalpha_`lid' = `labelalpha_`i''
            local labsize_`lid' `"`labsize_`i''"'
        }
    }

    local tickbase = `lblbase' + `totalchars'
    local ntickrows = 0
    local nminorrows = 0
    if "`ticks'" != "" {
        local minorlen = cond(`minorlen' < 0, `ticklen' * 0.5, `minorlen')
        local rtickbase = `rout' + `tickgap'
        local minorsign = cond(`"`tickside'"' == "outside", 1, -1)

        * Count major and minor tick points first so obs can be reserved
        * in one go.
        local totalticks = 0
        local totalminor = 0
        forvalues i = 1/`nsec' {
            local Ti = el(`Mout',1,`i') + el(`Min',1,`i')
            local step = el(`TickStep',1,`i')
            local mticks_i = el(`MinorTicks',1,`i')
            if `Ti' > 0 {
                local nt = floor(`Ti'/`step') + 1
                local totalticks = `totalticks' + `nt'
                local totalminor = `totalminor' + `nt' * (`mticks_i'-1)
            }
        }

        local oldN2 = _N
        local ntot2 = `totalticks'*4 + `totalminor'*3 + `nsec'*`axisarcres'
        quietly set obs `=`oldN2' + `ntot2''
        quietly gen str30 _ticklbl = ""

        local tcount  = 0
        local mcount  = 0
        local rowptr  = `oldN2'

        forvalues i = 1/`nsec' {
            local s0 = el(`Msang',1,`i')
            local s1 = el(`Meang',1,`i')
            local Ti = el(`Mout',1,`i') + el(`Min',1,`i')
            local step = el(`TickStep',1,`i')
            local mticks_i = el(`MinorTicks',1,`i')

            * Decide the flip direction ONCE for the whole axis, so the axis
            * is never mirrored piecewise and stays consistent with the
            * sector-label orientation.
            local tmid = (`s0' + `s1') / 2
            local efftmid = `dirmult' * `tmid'
            local efftmid = mod(`efftmid', 360)
            if `efftmid' < 0 local efftmid = `efftmid' + 360
            local secondleft = (cos(`efftmid' * `pi' / 180) < 0)
            local secforce_special = (`auto2group' == 1 & "`splithorizontal'" == "" & `gsize_`i'' == 1 & `secondleft' == 1)
            if `secforce_special' == 1 {
                local secdoflip = 0
            }
            else {
                local secdoflip = (sin(`efftmid' * `pi' / 180) > 0)
                local tinupperhalf = (mod(`tmid', 360) < 180)
                if `tinupperhalf' == 1 & "`ticktopflip'"    != "" local secdoflip = !`secdoflip'
                if `tinupperhalf' == 0 & "`tickbottomflip'" != "" local secdoflip = !`secdoflip'
            }

            * 3.1 Continuous arc axis line (spans the whole sector, sitting
            * just outside the ring).
            local axisid = `tickbase' + 1000000 + `i'
            local axiscol_`axisid' `"`tickcolor_`i''"'
            local axisalpha_`axisid' = `tickalpha_`i''
            local majlineid_`i' = `tickbase' + 4000000 + `i'
            local minlineid_`i' = `tickbase' + 5000000 + `i'
            local sectorhasticks_`i' = 0
            local sectorhasminor_`i' = 0
            * The axis arc extends slightly beyond both ends, tucked under
            * the tick marks, to hide rendering seams at the joints.
            local axiseps = min(0.15, `gap'*0.15)
            local axis_s0 = `s0' - `axiseps'
            local axis_s1 = `s1' + `axiseps'
            forvalues k = 0/`=`axisarcres'-1' {
                local rowptr = `rowptr' + 1
                local frac0 = `k' / (`axisarcres'-1)
                local ang0  = `axis_s0' + `frac0' * (`axis_s1' - `axis_s0')
                local rad0b = `ang0' * `pi' / 180
                quietly replace _x  = `rtickbase' * cos(`rad0b')           in `rowptr'
                quietly replace _y  = `rtickbase' * sin(`dirmult'*`rad0b') in `rowptr'
                quietly replace _id = `axisid'                              in `rowptr'
            }

            if `Ti' <= 0 continue

            local sectorhasticks_`i' = 1
            local tickval = 0
            while `tickval' <= `Ti' + 1e-9 {
                local frac = `tickval' / `Ti'
                if `tickmatch' == 1  local tang = `s0' + `frac' * (`s1' - `s0')
                else                 local tang = `s1' - `frac' * (`s1' - `s0')
                local trad = `tang' * `pi' / 180

                local tcount = `tcount' + 1
                local tid = `tickbase' + `tcount'

                local rowptr = `rowptr' + 1
                local rowa = `rowptr'
                local rowptr = `rowptr' + 1
                local rowb = `rowptr'
                local rowptr = `rowptr' + 1
                local rowsep = `rowptr'
                local rowptr = `rowptr' + 1
                local rowc = `rowptr'

                quietly replace _x  = `rtickbase' * cos(`trad')                       in `rowa'
                quietly replace _y  = `rtickbase' * sin(`dirmult'*`trad')             in `rowa'
                quietly replace _id = `majlineid_`i''                                 in `rowa'

                quietly replace _x  = (`rtickbase'+`ticklen') * cos(`trad')           in `rowb'
                quietly replace _y  = (`rtickbase'+`ticklen') * sin(`dirmult'*`trad') in `rowb'
                quietly replace _id = `majlineid_`i''                                 in `rowb'

                quietly replace _id = `majlineid_`i''                                 in `rowsep'

                local labid = `tid' + 200000
                local effang2 = `dirmult' * `tang'
                local effang2 = mod(`effang2', 360)
                if `effang2' < 0 local effang2 = `effang2' + 360

                if `"`ticklabdir'"' == "horizontal" {
                    local ticklabang = 0
                }
                else if `"`ticklabdir'"' == "curved" {
                    local ticklabang = mod(`effang2' + 90, 360)
                    if `secdoflip' == 1 local ticklabang = `ticklabang' - 180
                }
                else {
                    local ticklabang = `effang2'
                    if `secdoflip' == 1 local ticklabang = `ticklabang' - 180
                }

                quietly replace _x       = (`rtickbase'+`ticklen'+`ticklabgap') * cos(`trad')           in `rowc'
                quietly replace _y       = (`rtickbase'+`ticklen'+`ticklabgap') * sin(`dirmult'*`trad') in `rowc'
                quietly replace _id      = `labid'                                                          in `rowc'
                if `"`ticklabfont'"' == "" {
                    quietly replace _ticklbl = "`=string(`tickval')'"                                       in `rowc'
                }
                else {
                    quietly replace _ticklbl = `"{fontface "`ticklabfont'":`=string(`tickval')'}"'          in `rowc'
                }

                local tickang_`labid' = `ticklabang'
                local tickcol_`tid' `"`tickcolor_`i''"'
                local ticklabcol_`labid' `"`ticklabcolor_`i''"'
                local tickalpha_`tid' = `tickalpha_`i''
                local ticklabalpha_`labid' = `ticklabalpha_`i''
                local ticklabsize_`labid' `"`ticklabsize_`i''"'

                * 3.2 Evenly spaced unnumbered minor ticks inside this major
                * interval.
                if `tickval' + 1e-9 < `Ti' & `mticks_i' > 1 {
                    forvalues sub = 1/`=`mticks_i'-1' {
                        local minorval = `tickval' + `sub' * (`step'/`mticks_i')
                        if `minorval' <= `Ti' + 1e-9 {
                            local mfrac = `minorval' / `Ti'
                            if `tickmatch' == 1  local mang = `s0' + `mfrac' * (`s1' - `s0')
                            else                 local mang = `s1' - `mfrac' * (`s1' - `s0')
                            local mrad = `mang' * `pi' / 180

                            local mcount = `mcount' + 1
                            local sectorhasminor_`i' = 1

                            local rowptr = `rowptr' + 1
                            local rowm1 = `rowptr'
                            local rowptr = `rowptr' + 1
                            local rowm2 = `rowptr'
                            local rowptr = `rowptr' + 1
                            local rowmsep = `rowptr'

                            quietly replace _x  = `rtickbase' * cos(`mrad')                        in `rowm1'
                            quietly replace _y  = `rtickbase' * sin(`dirmult'*`mrad')              in `rowm1'
                            quietly replace _id = `minlineid_`i''                                  in `rowm1'

                            quietly replace _x  = (`rtickbase'+`minorsign'*`minorlen') * cos(`mrad')           in `rowm2'
                            quietly replace _y  = (`rtickbase'+`minorsign'*`minorlen') * sin(`dirmult'*`mrad') in `rowm2'
                            quietly replace _id = `minlineid_`i''                                              in `rowm2'

                            quietly replace _id = `minlineid_`i''                                  in `rowmsep'
                        }
                    }
                }

                local tickval = `tickval' + `step'
            }
        }
        local ntickrows  = `tcount'
        local nminorrows = `mcount'
    }

    * ================================================================
    * Percentage axis (pctticks): drawn exactly in parallel with the value
    * axis -- one continuous arc per sector + short tick lines merged into
    * one line layer via cmissing(n) + separate label points, so the layer
    * count grows with the number of sectors, not the number of ticks.
    * Differences from the value axis:
    *   1) radius: stacked outside the value-axis labels (+pctaxisgap) when
    *      both axes are on; takes the value axis position when alone.
    *   2) values: fixed 0-100(%), no "nice step" search needed.
    *   3) ids offset by +50000000, disjoint from all other id ranges.
    *   4) colors/sizes come from the per-sector pcttickcolor_`i' etc.;
    *      the flip logic (secdoflip2 etc.) mirrors the value axis.
    * 中文说明：比例轴画法与数值轴完全平行；id区间+50000000避免重叠。
    * ================================================================
    local ntickrows2 = 0
    local nminorrows2 = 0
    if "`pctticks'" != "" {
        local tickbase2 = `tickbase' + 50000000

        if "`ticks'" != "" {
            local rtickbase2 = `rtickbase' + `ticklen' + `ticklabgap' + `pctaxisgap'
        }
        else {
            local rtickbase2 = `rout' + `tickgap'
        }
        local minorsign2 = cond(`"`tickside'"' == "outside", 1, -1)

        * Each sector gets a fixed number of major ticks (data-independent),
        * so the total row count can be reserved in advance.
        local nt2 = floor(100/`pcttickstep') + 1
        local totalticks2 = 0
        local totalminor2 = 0
        forvalues i = 1/`nsec' {
            local Ti = el(`Mout',1,`i') + el(`Min',1,`i')
            if `Ti' > 0 {
                local totalticks2 = `totalticks2' + `nt2'
                local totalminor
				local totalminor2 = `totalminor2' + `nt2' * (`pctminorticks_eff'-1)
            }
        }

        local oldN3 = _N
        local ntot3 = `totalticks2'*4 + `totalminor2'*3 + `nsec'*`axisarcres'
        quietly set obs `=`oldN3' + `ntot3''
        quietly gen str30 _pctlbl = ""

        local tcount2 = 0
        local mcount2 = 0
        local rowptr2 = `oldN3'

        forvalues i = 1/`nsec' {
            local s0 = el(`Msang',1,`i')
            local s1 = el(`Meang',1,`i')
            local Ti = el(`Mout',1,`i') + el(`Min',1,`i')

            * Flip logic copied from the value axis so both axes keep the
            * same label orientation.
            local tmid2 = (`s0' + `s1') / 2
            local efftmid2 = `dirmult' * `tmid2'
            local efftmid2 = mod(`efftmid2', 360)
            if `efftmid2' < 0 local efftmid2 = `efftmid2' + 360
            local secondleft2 = (cos(`efftmid2' * `pi' / 180) < 0)
            local secforce2 = (`auto2group' == 1 & "`splithorizontal'" == "" & `gsize_`i'' == 1 & `secondleft2' == 1)
            if `secforce2' == 1 {
                local secdoflip2 = 0
            }
            else {
                local secdoflip2 = (sin(`efftmid2' * `pi' / 180) > 0)
                local tinupperhalf2 = (mod(`tmid2', 360) < 180)
                if `tinupperhalf2' == 1 & "`ticktopflip'"    != "" local secdoflip2 = !`secdoflip2'
                if `tinupperhalf2' == 0 & "`tickbottomflip'" != "" local secdoflip2 = !`secdoflip2'
            }

            * Continuous arc axis line: drawn whether or not this sector has
            * flow, same as the value axis.
            local axisid2 = `tickbase2' + 1000000 + `i'
            local axiscol2_`axisid2' `"`pcttickcolor_`i''"'
            local axisalpha2_`axisid2' = `pcttickalpha_`i''
            local sectorhasticks2_`i' = 0
            local sectorhasminor2_`i' = 0
            local axiseps2 = min(0.15, `gap'*0.15)
            local axis2_s0 = `s0' - `axiseps2'
            local axis2_s1 = `s1' + `axiseps2'
            forvalues k = 0/`=`axisarcres'-1' {
                local rowptr2 = `rowptr2' + 1
                local frac0 = `k' / (`axisarcres'-1)
                local ang0  = `axis2_s0' + `frac0' * (`axis2_s1' - `axis2_s0')
                local rad0b = `ang0' * `pi' / 180
                quietly replace _x  = `rtickbase2' * cos(`rad0b')           in `rowptr2'
                quietly replace _y  = `rtickbase2' * sin(`dirmult'*`rad0b') in `rowptr2'
                quietly replace _id = `axisid2'                              in `rowptr2'
            }

            if `Ti' <= 0 continue

            local sectorhasticks2_`i' = 1
            local majlineid2_`i' = `tickbase2' + 4000000 + `i'
            local minlineid2_`i' = `tickbase2' + 5000000 + `i'

            local pctval = 0
            while `pctval' <= 100 + 1e-9 {
                local frac = `pctval' / 100
                if `tickmatch' == 1  local tang2 = `s0' + `frac' * (`s1' - `s0')
                else                 local tang2 = `s1' - `frac' * (`s1' - `s0')
                local trad2 = `tang2' * `pi' / 180

                local tcount2 = `tcount2' + 1
                local tid2 = `tickbase2' + `tcount2'

                local rowptr2 = `rowptr2' + 1
                local row2a = `rowptr2'
                local rowptr2 = `rowptr2' + 1
                local row2b = `rowptr2'
                local rowptr2 = `rowptr2' + 1
                local row2sep = `rowptr2'
                local rowptr2 = `rowptr2' + 1
                local row2c = `rowptr2'

                quietly replace _x  = `rtickbase2' * cos(`trad2')                       in `row2a'
                quietly replace _y  = `rtickbase2' * sin(`dirmult'*`trad2')             in `row2a'
                quietly replace _id = `majlineid2_`i''                                  in `row2a'

                quietly replace _x  = (`rtickbase2'+`pctticklen') * cos(`trad2')           in `row2b'
                quietly replace _y  = (`rtickbase2'+`pctticklen') * sin(`dirmult'*`trad2') in `row2b'
                quietly replace _id = `majlineid2_`i''                                  in `row2b'

                quietly replace _id = `majlineid2_`i''                                  in `row2sep'

                local labid2 = `tid2' + 200000
                local effang3 = `dirmult' * `tang2'
                local effang3 = mod(`effang3', 360)
                if `effang3' < 0 local effang3 = `effang3' + 360

                if `"`ticklabdir'"' == "horizontal" {
                    local pctlabang = 0
                }
                else if `"`ticklabdir'"' == "curved" {
                    local pctlabang = mod(`effang3' + 90, 360)
                    if `secdoflip2' == 1 local pctlabang = `pctlabang' - 180
                }
                else {
                    local pctlabang = `effang3'
                    if `secdoflip2' == 1 local pctlabang = `pctlabang' - 180
                }

                quietly replace _x       = (`rtickbase2'+`pctticklen'+`pctticklabgap') * cos(`trad2')           in `row2c'
                quietly replace _y       = (`rtickbase2'+`pctticklen'+`pctticklabgap') * sin(`dirmult'*`trad2') in `row2c'
                quietly replace _id      = `labid2'                                                                in `row2c'
                if `"`pctticklabfont'"' == "" {
                    quietly replace _pctlbl = "`=string(`pctval')'%"                                              in `row2c'
                }
                else {
                    quietly replace _pctlbl = `"{fontface "`pctticklabfont'":`=string(`pctval')'%}"'              in `row2c'
                }

                local tickang2_`labid2' = `pctlabang'
                local pctticklabcolor_`labid2' `"`pctticklabcolor_`i''"'
                local pctticklabalpha_`labid2' = `pctticklabalpha_`i''
                local pctticklabsize_`labid2' `"`pctticklabsize_`i''"'

                * Unnumbered minor ticks within this major interval.
                if `pctval' + 1e-9 < 100 & `pctminorticks_eff' > 1 {
                    forvalues sub = 1/`=`pctminorticks_eff'-1' {
                        local minorval2 = `pctval' + `sub' * (`pcttickstep'/`pctminorticks_eff')
                        if `minorval2' <= 100 + 1e-9 {
                            local mfrac2 = `minorval2' / 100
                            if `tickmatch' == 1  local mang2 = `s0' + `mfrac2' * (`s1' - `s0')
                            else                 local mang2 = `s1' - `mfrac2' * (`s1' - `s0')
                            local mrad2 = `mang2' * `pi' / 180

                            local mcount2 = `mcount2' + 1
                            local sectorhasminor2_`i' = 1

                            local rowptr2 = `rowptr2' + 1
                            local rowm2a = `rowptr2'
                            local rowptr2 = `rowptr2' + 1
                            local rowm2b = `rowptr2'
                            local rowptr2 = `rowptr2' + 1
                            local rowm2sep = `rowptr2'

                            quietly replace _x  = `rtickbase2' * cos(`mrad2')                        in `rowm2a'
                            quietly replace _y  = `rtickbase2' * sin(`dirmult'*`mrad2')              in `rowm2a'
                            quietly replace _id = `minlineid2_`i''                                   in `rowm2a'

                            quietly replace _x  = (`rtickbase2'+`minorsign2'*`pctminorlen') * cos(`mrad2')           in `rowm2b'
                            quietly replace _y  = (`rtickbase2'+`minorsign2'*`pctminorlen') * sin(`dirmult'*`mrad2') in `rowm2b'
                            quietly replace _id = `minlineid2_`i''                                                   in `rowm2b'

                            quietly replace _id = `minlineid2_`i''                                   in `rowm2sep'
                        }
                    }
                }

                local pctval = `pctval' + `pcttickstep'
            }
        }
        local ntickrows2  = `tcount2'
        local nminorrows2 = `mcount2'
    }

    tempname cmdbuf
    local `cmdbuf' ""

    forvalues pos = 1/`nedges' {
        local e = `draworder`pos''
        local fi  = el(`ME',`e',1)
        local cid = `nsec' + `e'

        if `"`edgecol_`e''"' != "" {
            local col `"`edgecol_`e''"'
            local thisalpha = `edgealpha_`e''
        }
        else {
            local col `"`color_`fi''"'
            local flag = el(`EdgeFlag',`e',1)
            if `flag' == 1 {
                if `highlightalpha' < 0  local thisalpha = `ribalpha_`fi''
                else                     local thisalpha = `highlightalpha'
            }
            else if `flag' == 2 {
                local thisalpha = `dimalpha'
            }
            else {
                local thisalpha = `ribalpha_`fi''
            }
        }
        local `cmdbuf' `"``cmdbuf'' (area _y _x if _id==`cid', fcolor("`col'%`thisalpha'") lwidth(none))"'
        if "`ribbonborder'" != "" | `borderoverridden_`e'' == 1 {
            local `cmdbuf' `"``cmdbuf'' (line _y _x if _id==`cid', `borderopts_`e'')"'
        }
    }
    if "`interseg'" != "" {
        forvalues pos = 1/`nedges' {
            local e = `draworder`pos''
            local segid = `nsec' + `nedges' + 9000000 + `e'
            local `cmdbuf' `"``cmdbuf'' (area _y _x if _id==`segid', fcolor("`segcolor_`segid''%`segalpha_`segid''") lwidth(none))"'
        }
    }
    forvalues i = 1/`nsec' {
        local col `"`ringcolor_`i''"'
        local `cmdbuf' `"``cmdbuf'' (area _y _x if _id==`i', fcolor("`col'%`ringalpha_`i''") lwidth(none))"'
    }
    forvalues e = 1/`nedges' {
        if `linkflag_`e'' == 1 {
            local lkid = `nsec' + `nedges' + 8000000 + `e'
            local `cmdbuf' `"``cmdbuf'' (line _y _x if _id==`lkid', `linklineopts_`e'')"'
            if "`linkarrowtype_`e''" == "single" | "`linkarrowtype_`e''" == "double" {
                local `cmdbuf' `"``cmdbuf'' (pcarrow _aY1 _aX1 _aY2 _aX2 if _aid==`lkid', `linkarrowopts_`e'')"'
            }
            if "`linkarrowtype_`e''" == "double" {
                local laid2 = `lkid' + 5000000
                local `cmdbuf' `"``cmdbuf'' (pcarrow _aY1 _aX1 _aY2 _aX2 if _aid==`laid2', `linkarrowopts_`e'')"'
            }
        }
    }
    forvalues j = 1/`totalchars' {
        local lid = `lblbase' + `j'
        local `cmdbuf' `"``cmdbuf'' (scatter _y _x if _id==`lid', mlabel(_lbl) mlabangle(`labang_`lid'') mlabsize(`labsize_`lid'') mlabcolor("`labelcol_`lid''%`labelalpha_`lid''") mlabpos(0) mcolor(none) msymbol(i))"'
    }
    if "`ticks'" != "" {
        forvalues i = 1/`nsec' {
            local axisid = `tickbase' + 1000000 + `i'
            local `cmdbuf' `"``cmdbuf'' (line _y _x if _id==`axisid', lcolor("`axiscol_`axisid''%`axisalpha_`axisid''") lwidth(`axislwidth') lpattern(`ticklpattern'))"'
        }
        if `nminorrows' > 0 {
            forvalues i = 1/`nsec' {
                if `sectorhasminor_`i'' == 1 {
                    local `cmdbuf' `"``cmdbuf'' (line _y _x if _id==`minlineid_`i'', lcolor("`tickcolor_`i''%`tickalpha_`i''") lwidth(`minorlwidth') lpattern(`ticklpattern') cmissing(n))"'
                }
            }
        }
        if `ntickrows' > 0 {
            forvalues i = 1/`nsec' {
                if `sectorhasticks_`i'' == 1 {
                    local `cmdbuf' `"``cmdbuf'' (line _y _x if _id==`majlineid_`i'', lcolor("`tickcolor_`i''%`tickalpha_`i''") lwidth(`ticklwidth') lpattern(`ticklpattern') cmissing(n))"'
                }
            }
            forvalues j = 1/`ntickrows' {
                local tid = `tickbase' + `j'
                local labid = `tid' + 200000
                local `cmdbuf' `"``cmdbuf'' (scatter _y _x if _id==`labid', mlabel(_ticklbl) mlabangle(`tickang_`labid'') mlabsize(`ticklabsize_`labid'') mlabcolor("`ticklabcol_`labid''%`ticklabalpha_`labid''") mlabpos(0) mcolor(none) msymbol(i))"'
            }
        }
    }

    * Percentage axis: add drawing commands, same layering as the value axis
    * (continuous main arc + short ticks + label points).
    if "`pctticks'" != "" {
        forvalues i = 1/`nsec' {
            local axisid2 = `tickbase2' + 1000000 + `i'
            local `cmdbuf' `"``cmdbuf'' (line _y _x if _id==`axisid2', lcolor("`axiscol2_`axisid2''%`axisalpha2_`axisid2''") lwidth(`pctaxislwidth') lpattern(`pctticklpattern'))"'
        }
        if `nminorrows2' > 0 {
            forvalues i = 1/`nsec' {
                if `sectorhasminor2_`i'' == 1 {
                    local `cmdbuf' `"``cmdbuf'' (line _y _x if _id==`minlineid2_`i'', lcolor("`pcttickcolor_`i''%`pcttickalpha_`i''") lwidth(`pctminorlwidth') lpattern(`pctticklpattern') cmissing(n))"'
                }
            }
        }
        if `ntickrows2' > 0 {
            forvalues i = 1/`nsec' {
                if `sectorhasticks2_`i'' == 1 {
                    local `cmdbuf' `"``cmdbuf'' (line _y _x if _id==`majlineid2_`i'', lcolor("`pcttickcolor_`i''%`pcttickalpha_`i''") lwidth(`pctticklwidth') lpattern(`pctticklpattern') cmissing(n))"'
                }
            }
            forvalues j = 1/`ntickrows2' {
                local tid2 = `tickbase2' + `j'
                local labid2 = `tid2' + 200000
                local `cmdbuf' `"``cmdbuf'' (scatter _y _x if _id==`labid2', mlabel(_pctlbl) mlabangle(`tickang2_`labid2'') mlabsize(`pctticklabsize_`labid2'') mlabcolor("`pctticklabcolor_`labid2''%`pctticklabalpha_`labid2''") mlabpos(0) mcolor(none) msymbol(i))"'
            }
        }
    }

    * Compute the maximum radius covered by any drawn element and force a
    * symmetric x/y range, so aspectratio does not squeeze the circle into
    * an ellipse.
    local rmax_anchor = `rout'
    if `efflabelradius' > `rmax_anchor' local rmax_anchor = `efflabelradius'
    if "`ticks'" != "" {
        local ticktiplim = `rtickbase' + `ticklen' + `ticklabgap'
        if `ticktiplim' > `rmax_anchor' local rmax_anchor = `ticktiplim'
    }
    if "`pctticks'" != "" {
        local ticktiplim2 = `rtickbase2' + `pctticklen' + `pctticklabgap'
        if `ticktiplim2' > `rmax_anchor' local rmax_anchor = `ticktiplim2'
    }
    local plotrange = `rmax_anchor' * (1 + `plotmargin')

    local gopts "xsize(6) ysize(6) aspectratio(1) yscale(off range(-`plotrange' `plotrange')) xscale(off range(-`plotrange' `plotrange'))"
    local gopts `"`gopts' ylabel(none) xlabel(none) legend(off)"'
    if `"`graphregion'"' != "" local gopts `"`gopts' graphregion(`graphregion')"'
    if `"`plotregion'"'  != "" local gopts `"`gopts' plotregion(`plotregion')"'

    * title()/subtitle()/note()/caption(): passed through to twoway intact.
    if `"`title'"' != "" {
        _chordtitle_splitcomma `title'
        local cpos = r(pos)
        if `cpos' > 0 {
            local ttext = substr(`"`title'"', 1, `cpos'-1)
            local topts = substr(`"`title'"', `cpos', .)
        }
        else {
            local ttext `"`title'"'
            local topts ""
        }
        local ttext = strtrim(`"`ttext'"')
        if substr(`"`ttext'"',1,1) == char(34) {
            local gopts `"`gopts' title(`ttext'`topts')"'
        }
        else {
            local gopts `"`gopts' title(`"`ttext'"'`topts')"'
        }
    }
    if `"`subtitle'"' != "" {
        _chordtitle_splitcomma `subtitle'
        local cpos = r(pos)
        if `cpos' > 0 {
            local ttext = substr(`"`subtitle'"', 1, `cpos'-1)
            local topts = substr(`"`subtitle'"', `cpos', .)
        }
        else {
            local ttext `"`subtitle'"'
            local topts ""
        }
        local ttext = strtrim(`"`ttext'"')
        if substr(`"`ttext'"',1,1) == char(34) {
            local gopts `"`gopts' subtitle(`ttext'`topts')"'
        }
        else {
            local gopts `"`gopts' subtitle(`"`ttext'"'`topts')"'
        }
    }
    if `"`note'"' != "" {
        _chordtitle_splitcomma `note'
        local cpos = r(pos)
        if `cpos' > 0 {
            local ttext = substr(`"`note'"', 1, `cpos'-1)
            local topts = substr(`"`note'"', `cpos', .)
        }
        else {
            local ttext `"`note'"'
            local topts ""
        }
        local ttext = strtrim(`"`ttext'"')
        if substr(`"`ttext'"',1,1) == char(34) {
            local gopts `"`gopts' note(`ttext'`topts')"'
        }
        else {
            local gopts `"`gopts' note(`"`ttext'"'`topts')"'
        }
    }
    if `"`caption'"' != "" {
        _chordtitle_splitcomma `caption'
        local cpos = r(pos)
        if `cpos' > 0 {
            local ttext = substr(`"`caption'"', 1, `cpos'-1)
            local topts = substr(`"`caption'"', `cpos', .)
        }
        else {
            local ttext `"`caption'"'
            local topts ""
        }
        local ttext = strtrim(`"`ttext'"')
        if substr(`"`ttext'"',1,1) == char(34) {
            local gopts `"`gopts' caption(`ttext'`topts')"'
        }
        else {
            local gopts `"`gopts' caption(`"`ttext'"'`topts')"'
        }
    }

    if `"`scheme'"' != "" local gopts `"`gopts' scheme(`scheme')"'
    if `"`name'"'   != "" local gopts `"`gopts' name(`name')"'

    di as text "Drawing chord diagram: `nsec' sectors, `nedges' edges, total flow = `total_flow'"
    di as text "Direction (扇区排列方向): " cond(`dirmult'==1, "counterclockwise (逆时针)", "clockwise (顺时针)")
    di as text "Sector order (扇区顺序): `sectors'"
    twoway ``cmdbuf'' , `gopts'

    restore

    return local  sectors      `"`sectors'"'
    return scalar sector_count = `nsec'
    return scalar edge_count   = `nedges'
    return scalar total_flow   = `total_flow'
end