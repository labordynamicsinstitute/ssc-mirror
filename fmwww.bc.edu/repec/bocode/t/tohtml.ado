*! version 1.45, 2026-08-29
*! version 1.44, 2026-08-29
*! version 1.43, 2026-08-29
*! version 1.42, 2026-08-28
*! version 1.41, 2026-08-28
*! version 1.40, 2026-08-28
*! version 1.39, 2026-08-28
*! version 1.38, 2026-08-28
*! version 1.37, 2026-08-28
*! version 1.36, 2026-08-24
*! version 1.35, 2026-08-24
*! version 1.34, 2026-08-23
*! version 1.33, 2026-08-23
*! version 1.32, 2026-08-23
*! version 1.31, 2026-08-23
*! version 1.30, 2026-08-23
*! version 1.29, 2026-08-23
*! version 1.28, 2026-08-23
*! version 1.27, 2026-08-23
*! version 1.26, 2026-08-22
*! version 1.25, 2026-08-22
*! version 1.24, 2026-08-21
*! version 1.23, 2026-08-21
*! version 1.22, 2026-08-21
*! version 1.21, 2026-08-21
*! version 1.20, 2026-08-21
*! version 1.19, 2026-08-21
*! version 1.18, 2026-08-21
*! version 1.17, 2026-08-21
*! version 1.16, 2026-08-21
*! version 1.15, 2026-08-21
*! version 1.14, 2026-08-21
*! version 1.13, 2026-08-21
*! version 1.12, 2026-08-19
*! version 1.11, 2026-08-19
*! version 1.10, 2026-08-19
*! version 1.9, 2026-08-19
*! version 1.8, 2026-08-12
*! version 1.7, 2026-08-12
*! version 1.6, 2026-08-11
*! version 1.5, 2026-08-11
*! version 1.4, 2026-08-11
*! version 1.3, 2026-08-11
*! version 1.2, 2026-08-11
*! version 1.1, 2026-08-11
*! version 1.0, 2026-04-28
program define tohtml
version 16
    tohtml_require
    syntax anything ,  [ MD(string) REPlace HTML(string) ///
                         CSS(string) MATHJAX EMBED ///
                         CLEAN CLEANCODE ///
                         BUNDLE ZIP(string) ///
                         width(string) height(string) zoom(string) ///
                         TABWidth(string) TABHeight(string)]

    if "`clean'" != "" & "`cleancode'" != "" {
        di as error "options clean and cleancode may not be combined"
        exit 198
    }

    removequotes , t(`anything')
    local anything  `r(s)'
    local anything = subinstr(`"`anything'"', "\", "/", .)


    // 判断anything is a file or a folder
    local nf : word count `anything'
    if `nf' > 1 { // multiple file path specified
        alltohtml `anything', width(`width') height(`height') zoom(`zoom') 
        mclean2 `0'
        exit
    }
    else if `nf' == 1 { //single file path specified
        mata: st_numscalar("flag",direxists("`anything'"))
        if flag==1 { // anything is a path crteate a tempfile
            alltohtml `anything', width(`width') height(`height') zoom(`zoom') 
            mclean2 `0'
            exit
        }
    }

   // log file specified
    confirm file `"`anything'"'
    if "`clean'" != "" {
        mclean `0'
        exit
    }
    if "`cleancode'" != "" {
        cleancode `0'
        exit
    }

    local src_orig `anything'
    mata: tohtml_init_resource_root(`"`src_orig'"')
    // SMCL → text log (tempfile owned here so it survives until this program ends)
    tempfile _tohtml_smcltxt
    tohtml_ensure_textlog, from(`"`anything'"') dest(`"`_tohtml_smcltxt'.log"')
    local infile `r(file)'

    // name outputs from original path; read content from (possibly translated) file
    tohtml_resolve_md, from(`"`src_orig'"') md(`"`md'"') html(`"`html'"')
    local outfile `r(md)'
    local html `r(html)'
    tohtml_check_md_collision, from(`"`src_orig'"') md(`"`outfile'"')

    // If outfile exists and no replace, stop
    capture confirm new file `"`outfile'"'
    if _rc  & "`replace'" == "" {
        di as error "output file exists; use replace"
        exit 602
    }

    if `"`html'"' != "" {
        capture confirm new file "`html'"
        if _rc  & "`replace'" == "" {
            di as error "output file exists; use replace"
            exit 602
        }
   }

    // If replace is specified, erase existing outfile
    if "`replace'" != "" {
        capture erase `"`outfile'"'
        capture erase `"`html'"'
    }



    local repl = ("`replace'" != "")
    mata: rewrite_md(`"`infile'"', `"`outfile'"', `repl')

    di as text "% markdown written to " "`outfile'"

    // Optional: regenerate HTML from cleaned markdown
    if "`html'" != "" {
        tohtml_emit_html, md(`"`outfile'"') html(`"`html'"') css(`"`css'"') `mathjax' `embed' ///
            tabwidth(`tabwidth') tabheight(`tabheight')
        if "`zip'" != "" | "`bundle'" != "" {
            tohtml_bundle, html(`"`html'"') md(`"`outfile'"') zip(`"`zip'"') `replace'
        }
    }
    else if "`css'" != "" | "`mathjax'" != "" | "`embed'" != "" | "`bundle'" != "" | "`zip'" != "" ///
        | "`tabwidth'" != "" | "`tabheight'" != "" {
        di as error "css()/mathjax/embed/bundle/zip/tabwidth()/tabheight() require html()"
        exit 198
    }
end


program define cleancode
    syntax anything , CLEANCODE [MD(string) REPlace HTML(string) ///
                                         CSS(string) MATHJAX EMBED ///
                                         BUNDLE ZIP(string) ///
                                         width(string) height(string) zoom(string) ///
                                         TABWidth(string) TABHeight(string)]

    removequotes , t(`anything')
    local anything  `r(s)'
    local anything = subinstr(`"`anything'"', "\", "/", .)
    confirm file `"`anything'"'
    local src_orig `anything'
    mata: tohtml_init_resource_root(`"`src_orig'"')
    tempfile _tohtml_smcltxt
    tohtml_ensure_textlog, from(`"`anything'"') dest(`"`_tohtml_smcltxt'.log"')
    local anything `r(file)'

    tohtml_resolve_md, from(`"`src_orig'"') md(`"`md'"') html(`"`html'"')
    local outfile `r(md)'
    local html `r(html)'
    local infile `anything'
    tohtml_check_md_collision, from(`"`src_orig'"') md(`"`outfile'"')

    capture confirm new file `"`outfile'"'
    if _rc  & "`replace'" == "" {
        di as error "output file exists; use replace"
        exit 602
    }

    if `"`html'"' != "" {
        capture confirm new file "`html'"
        if _rc  & "`replace'" == "" {
            di as error "output file exists; use replace"
            exit 602
        }
   }

    // If replace is specified, erase existing outfile
    if "`replace'" != "" {
        capture erase `"`outfile'"'
        capture erase `"`html'"'
    }

    local replout = ("`replace'" != "")
    // Keep Stata commands (and img/iframe embeds) from the log; drop output
    mata: rewrite_md_cleancode(`"`infile'"', `"`outfile'"', `replout')

    di as text `"% markdown written to `outfile'"'

    // Optional: regenerate HTML from code markdown
    if "`html'" != "" {
        tohtml_emit_html, md(`"`outfile'"') html(`"`html'"') css(`"`css'"') `mathjax' `embed' highlight ///
            tabwidth(`tabwidth') tabheight(`tabheight')
        if "`zip'" != "" | "`bundle'" != "" {
            tohtml_bundle, html(`"`html'"') md(`"`outfile'"') zip(`"`zip'"') `replace'
        }
    }
    else if "`css'" != "" | "`mathjax'" != "" | "`embed'" != "" | "`bundle'" != "" | "`zip'" != "" ///
        | "`tabwidth'" != "" | "`tabheight'" != "" {
        di as error "css()/mathjax/embed/bundle/zip/tabwidth()/tabheight() require html()"
        exit 198
    }
end

cap program drop removequotes
program define removequotes,rclass
	version 16
	syntax, t(string)
	return local s `t'
end


program define mclean
    syntax anything , [MD(string)  REPlace HTML(string) CSS(string) MATHJAX ///
                       EMBED CLEAN CLEANCODE ///
                       BUNDLE ZIP(string) ///
                       width(string) height(string) zoom(string) ///
                       TABWidth(string) TABHeight(string)]
    // only keep lines that start with #, <iframe, <img

    removequotes , t(`anything')
    local anything  `r(s)'
    local anything = subinstr(`"`anything'"', "\", "/", .)
    confirm file `"`anything'"'
    local src_orig `anything'
    mata: tohtml_init_resource_root(`"`src_orig'"')
    tempfile _tohtml_smcltxt
    tohtml_ensure_textlog, from(`"`anything'"') dest(`"`_tohtml_smcltxt'.log"')
    local anything `r(file)'

    tohtml_resolve_md, from(`"`src_orig'"') md(`"`md'"') html(`"`html'"')
    local outfile `r(md)'
    local html `r(html)'
    local infile `anything'
    tohtml_check_md_collision, from(`"`src_orig'"') md(`"`outfile'"')

    // If outfile exists and no replace, stop
    capture confirm file `"`outfile'"'
    if _rc == 0 & "`replace'" == "" {
        di as error "output file exists; use replace"
        exit 602
    }

    if `"`html'"' != "" {
        capture confirm new file "`html'"
        if _rc  & "`replace'" == "" {
            di as error "output file exists; use replace"
            exit 602
        }
   }

    // If replace is specified, erase existing outfile
    if "`replace'" != "" {
        capture erase `"`outfile'"'
        capture erase `"`html'"'
    }


    local repl = ("`replace'" != "")
    mata: rewrite_md2(`"`infile'"', `"`outfile'"', `repl')
    di as text "% markdown written to " `"`outfile'"'

    // Optional: regenerate HTML from cleaned markdown
    if "`html'" != "" {
        tohtml_emit_html, md(`"`outfile'"') html(`"`html'"') css(`"`css'"') `mathjax' `embed' ///
            tabwidth(`tabwidth') tabheight(`tabheight')
        if "`zip'" != "" | "`bundle'" != "" {
            tohtml_bundle, html(`"`html'"') md(`"`outfile'"') zip(`"`zip'"') `replace'
        }
    }
    else if "`css'" != "" | "`mathjax'" != "" | "`embed'" != "" | "`bundle'" != "" | "`zip'" != "" ///
        | "`tabwidth'" != "" | "`tabheight'" != "" {
        di as error "css()/mathjax/embed/bundle/zip/tabwidth()/tabheight() require html()"
        exit 198
    }
end



program define mclean2
    syntax [anything] , [MD(string)  REPlace HTML(string) CSS(string) MATHJAX ///
                       EMBED CLEAN CLEANCODE ///
                       BUNDLE ZIP(string) ///
                       width(string) height(string) zoom(string) ///
                       TABWidth(string) TABHeight(string)]
    // only keep lines that start with #, <iframe, <img

    // removequotes , t(`anything')
    // local anything  `r(s)'
    local anything `c(pwd)'/_tempfile_log_.md

    tohtml_resolve_md, from(`"`anything'"') md(`"`md'"') html(`"`html'"')
    local outfile `r(md)'
    local html `r(html)'
    local infile `anything'
    tohtml_check_md_collision, from(`"`anything'"') md(`"`outfile'"')

    // If outfile exists and no replace, stop

    capture confirm new file `"`outfile'"'
    if _rc  & "`replace'" == "" {
        di as error "output file exists; use replace"
        exit 602
    }

    if `"`html'"' != "" {
        capture confirm new file "`html'"
        if _rc  & "`replace'" == "" {
            di as error "output file exists; use replace"
            exit 602
        }
   }

    // If replace is specified, erase existing outfile
    if "`replace'" != "" {
        capture erase `"`outfile'"'
        capture erase `"`html'"'
    }
  


    local repl = ("`replace'" != "")
    mata: rewrite_md2(`"`infile'"', `"`outfile'"', `repl')
    di as text "% markdown written to " `"`outfile'"'

    // Optional: regenerate HTML from cleaned markdown
    if "`html'" != "" {
        tohtml_emit_html, md(`"`outfile'"') html(`"`html'"') css(`"`css'"') `mathjax' `embed' ///
            tabwidth(`tabwidth') tabheight(`tabheight')
        if "`zip'" != "" | "`bundle'" != "" {
            tohtml_bundle, html(`"`html'"') md(`"`outfile'"') zip(`"`zip'"') `replace'
        }
    }
    else if "`css'" != "" | "`mathjax'" != "" | "`embed'" != "" | "`bundle'" != "" | "`zip'" != "" ///
        | "`tabwidth'" != "" | "`tabheight'" != "" {
        di as error "css()/mathjax/embed/bundle/zip/tabwidth()/tabheight() require html()"
        exit 198
    }
end



capture program drop tohtml_ensure_textlog
program define tohtml_ensure_textlog, rclass
    version 16
    syntax , FROM(string) [DEST(string)]

    local from = subinstr(`"`from'"', "\", "/", .)
    confirm file `"`from'"'

    mata: st_local("suf", pathsuffix(st_local("from")))
    local is_smcl = (ustrlower("`suf'") == ".smcl")

    if !`is_smcl' {
        // content peek: first non-empty line is {smcl}
        tempname fh
        file open `fh' using `"`from'"', read text
        local found 0
        local nread 0
        while `nread' < 40 {
            file read `fh' line
            if r(eof) continue, break
            local ++nread
            local t = ustrtrim(`"`macval(line)'"')
            if `"`t'"' == "" continue
            if `"`t'"' == "{smcl}" local found 1
            continue, break
        }
        file close `fh'
        local is_smcl = `found'
    }

    if !`is_smcl' {
        return local file `"`from'"'
        return scalar translated = 0
        exit
    }

    if `"`dest'"' == "" {
        di as error "tohtml_ensure_textlog: dest() required for SMCL input"
        exit 198
    }
    local dest = subinstr(`"`dest'"', "\", "/", .)

    quietly translate `"`from'"' `"`dest'"', translator(smcl2log) replace
    di as text "% SMCL log translated to text: `dest'"
    return local file `"`dest'"'
    return scalar translated = 1
end


capture program drop tohtml_require
program define tohtml_require
    version 16
    // Never ssc install. Tell the user what is missing.

    mata: st_numscalar("tohtml_has_mm", findexternal("mm_outsheet()") != NULL)
    if tohtml_has_mm == 0 {
        di as error "tohtml requires moremata (Mata function mm_outsheet)"
        di as error "install with:  ssc install moremata"
        exit 111
    }
end

capture program drop tohtml_require_fs
program define tohtml_require_fs
    version 16
    capture which fs
    if _rc {
        di as error "tohtml directory mode requires fs (Nick Cox)"
        di as error "install with:  ssc install fs"
        exit 111
    }
end


capture program drop tohtml_resolve_md
program define tohtml_resolve_md, rclass
    version 16
    syntax , FROM(string) [MD(string) HTML(string)]

    local from = subinstr(`"`from'"', "\", "/", .)
    local md = subinstr(`"`md'"', "\", "/", .)
    local html = subinstr(`"`html'"', "\", "/", .)

    if `"`html'"' == "" {
        local html = ustrregexra(`"`from'"', "\.[^.]+$", "") + ".html"
    }
    if ustrright(ustrlower(`"`html'"'), 5) != ".html" {
        local html `"`html'.html"'
    }

    if `"`md'"' == "" {
        local md = ustrregexra(`"`html'"', "\.[Hh][Tt][Mm][Ll]$", ".md")
    }
    else if ustrright(ustrlower(`"`md'"'), 3) != ".md" {
        local md `"`md'.md"'
    }

    return local md `"`md'"'
    return local html `"`html'"'
end


capture program drop tohtml_check_md_collision
program define tohtml_check_md_collision
    version 16
    syntax , FROM(string) MD(string)
    mata: st_numscalar("tohtml_md_same", paths_are_same(st_local("from"), st_local("md")))
    if tohtml_md_same {
        di as error "input file and Markdown output file must be different"
        exit 198
    }
end


capture program drop tohtml_emit_html
program define tohtml_emit_html
    version 16
    syntax , MD(string) HTML(string) [CSS(string) MATHJAX HIGHLIGHT EMBED TABWidth(string) TABHeight(string)]

    mata: st_local("html_dir", path_dir(`"`html'"'))
    if "`html_dir'" == "" local html_dir "."

    // HTML tables are always inlined (same path as embed).
    local convimg = ("`embed'" != "")
    mata: tohtml_inline_tables(`"`md'"', `convimg')

    if "`embed'" != "" {
        mata: st_local("embase", tohtml_get_resource_root())
        markdown `"`md'"', saving(`"`html'"') replace embedimage basedir(`"`embase'"')
    }
    else {
        mata: tohtml_fix_default_refs(`"`md'"', `"`html_dir'"')
        markdown `"`md'"', saving(`"`html'"') replace
    }
    tohtml_style, html(`"`html'"') css(`"`css'"') md(`"`md'"') `mathjax' `highlight' `embed'
    mata: inject_embed_table_styles(`"`html'"')
    if "`embed'" == "" {
        mata: tohtml_finish_default_refs(`"`html'"')
    }
    mata: inject_table_scroll_css(`"`html'"', `"`tabwidth'"', `"`tabheight'"')
end

capture program drop tohtml_style
program define tohtml_style
    version 16
    syntax , HTML(string) [CSS(string) MATHJAX HIGHLIGHT EMBED MD(string)]

    // Default stylesheet is package tohtml.css (GitHub-like). css() is only
    // for a custom file; there is no githubstyle alias.
    local css_l = ustrlower(strtrim(`"`css'"'))
    if `"`css_l'"' == "" {
        quietly findfile tohtml.css
        if `"`r(fn)'"' == "" {
            di as error "tohtml.css not found; reinstall the tohtml package"
            exit 601
        }
        local css_src `"`r(fn)'"'
        local css_base "tohtml.css"
    }
    else {
        confirm file `"`css'"'
        local css_src `css'
        mata: st_local("css_base", path_base(normalize_path(st_local("css_src"))))
    }

    if "`embed'" != "" {
        mata: inject_css_inline(`"`html'"', `"`css_src'"')
    }
    else {
        mata: st_local("html_dir", path_dir(`"`html'"'))
        if "`html_dir'" == "" local html_dir "."
        cap mkdir "`html_dir'/css"
        local css_dest "`html_dir'/css/`css_base'"

        mata: st_local("css_norm", normalize_path(`"`css_src'"'))
        mata: st_local("css_dest_norm", normalize_path(`"`css_dest'"'))
        if `"`css_norm'"' != `"`css_dest_norm'"' {
            copy `"`css_src'"' `"`css_dest'"', replace
        }
        mata: inject_css(`"`html'"', "./css/`css_base'")
    }
    mata: normalize_stata_code_class(`"`html'"')

    // cleancode HTML: syntax-highlight ```stata blocks (CDN; no user option)
    if "`highlight'" != "" {
        mata: inject_highlightjs(`"`html'"')
    }

    // MathJax is opt-in and only injected when equations are present
    if "`mathjax'" != "" {
        local mathsrc `md'
        if `"`mathsrc'"' == "" local mathsrc `html'
        mata: st_numscalar("hasmath", content_has_math(`"`mathsrc'"'))
        if hasmath {
            mata: inject_mathjax(`"`html'"')
        }
        else {
            di as text "% mathjax skipped (no equations detected in `mathsrc')"
        }
    }
end



capture program drop tohtml_bundle
program define tohtml_bundle
    version 16
    syntax , HTML(string) [MD(string) ZIP(string) REPlace]

    mata: st_local("html_dir", path_dir(`"`html'"'))
    if "`html_dir'" == "" local html_dir "."

    cap mkdir "`html_dir'/css"
    cap mkdir "`html_dir'/figures"
    cap mkdir "`html_dir'/tables"

    mata: bundle_report(`"`html'"', `"`md'"')
    di as text "% resources bundled under `html_dir'/{css,figures,tables}"

    if `"`zip'"' == "" exit

    // resolve zip archive path
    if `"`zip'"' == "." | lower(`"`zip'"') == "auto" {
        mata: st_local("html_base", path_base(`"`html'"'))
        local stub = ustrregexra("`html_base'", "\.[^.]+$", "")
        local zipfile "`html_dir'/`stub'.zip"
    }
    else {
        local zipfile `zip'
        local zipfile = subinstr(`"`zipfile'"', "\", "/", .)
        mata: st_local("zip_suf", pathsuffix(`"`zipfile'"'))
        if "`zip_suf'" == "" local zipfile `"`zipfile'.zip"'
        // bare filename -> place next to HTML
        mata: st_local("zip_dir", path_dir(`"`zipfile'"'))
        if "`zip_dir'" == "" local zipfile "`html_dir'/`zipfile'"
    }

    if "`replace'" != "" {
        capture erase `"`zipfile'"'
    }
    else {
        capture confirm new file `"`zipfile'"'
        if _rc {
            di as error "zip file exists; use replace"
            exit 602
        }
    }

    // build relative file list from package root, then zipfile
    mata: st_local("html_base", path_base(`"`html'"'))
    mata: st_local("html_dir_abs", normalize_path(`"`html_dir'"'))
    mata: st_local("zipfile_abs", normalize_path(`"`zipfile'"'))
    mata: st_local("zip_base", path_base(st_local("zipfile_abs")))
    mata: st_local("zip_parent", path_dir(st_local("zipfile_abs")))
    if "`zip_parent'" == "" local zip_parent "."
    mata: st_local("zip_parent", normalize_path(st_local("zip_parent")))

    local pwd0 `"`c(pwd)'"'
    quietly cd `"`html_dir_abs'"'

    local zlist `"`html_base'"'
    capture local fs : dir "css" files "*"
    if _rc == 0 {
        foreach f of local fs {
            local zlist `"`zlist' "css/`f'""'
        }
    }
    // only pack figures/tables that the report actually references
    if `"`bundle_zip_rel'"' != "" {
        foreach f of local bundle_zip_rel {
            capture confirm file `"`f'"'
            if _rc == 0 {
                local zlist `"`zlist' "`f'""'
            }
        }
    }
    // include cleaned markdown when it lives in the package root
    if `"`md'"' != "" {
        mata: st_local("md_norm", normalize_path(`"`md'"'))
        mata: st_local("md_dir", path_dir(st_local("md_norm")))
        if "`md_dir'" == "" local md_dir "."
        mata: st_local("md_dir_norm", normalize_path(`"`md_dir'"'))
        if `"`md_dir_norm'"' == `"`html_dir_abs'"' {
            mata: st_local("md_base", path_base(`"`md_norm'"'))
            confirm file `"`md_base'"'
            local zlist `"`zlist' "`md_base'""'
        }
    }

    if `"`zip_parent'"' == `"`html_dir_abs'"' {
        local zsave `"`zip_base'"'
    }
    else {
        local zsave `"`zipfile_abs'"'
    }

    capture noi zipfile `zlist', saving(`"`zsave'"', replace)
    local rc = _rc
    quietly cd `"`pwd0'"'
    if `rc' {
        di as error "zipfile failed"
        exit `rc'
    }
    di as text "% archive written to " `"`zipfile_abs'"'
end



mata:


string scalar path_dir(string scalar p)
{
    if (strtrim(p) == "") return("")
    return(pathgetparent(p))
}

string scalar path_base(string scalar p)
{
    return(pathbasename(p))
}



void function inject_css(string scalar htmlfile, string scalar css_rel)
{
    lines = cat(htmlfile)
    if (rows(lines) == 0) return

    // avoid duplicate injection
    if (sum(ustrpos(lines, css_rel) :> 0) > 0) return

    link = "<link rel=" + char(34) + "stylesheet" + char(34) + " href="http://fmwww.bc.edu/repec/bocode/t/+&#32;char(34)&#32;+&#32;css_rel&#32;+&#32;char(34)&#32;+">"
    idx = selectindex(ustrpos(lines, "</head>") :> 0)
    if (length(idx) > 0) {
        i = idx[1]
        if (i > 1) {
            lines = lines[|1 \ i-1|] \ link \ lines[|i \ rows(lines)|]
        }
        else {
            lines = link \ lines
        }
    }
    else {
        lines = link \ lines
    }

    mm_outsheet(htmlfile, lines, "replace")
}

void function inject_css_inline(string scalar htmlfile, string scalar cssfile)
{
    // embed: put report CSS in <style> so HTML does not need ./css/tohtml.css
    if (!fileexists(cssfile)) return
    css = cat(cssfile)
    if (rows(css) == 0) return

    lines = cat(htmlfile)
    if (rows(lines) == 0) return
    if (sum(ustrpos(lines, "tohtml-inline-css") :> 0) > 0) return

    q = char(34)
    open = "<style id=" + q + "tohtml-inline-css" + q + ">"
    close = "</style>"
    block = open \ css \ close

    idx = selectindex(ustrpos(lines, "</head>") :> 0)
    if (length(idx) > 0) {
        i = idx[1]
        if (i > 1) {
            lines = lines[|1 \ i-1|] \ block \ lines[|i \ rows(lines)|]
        }
        else {
            lines = block \ lines
        }
    }
    else {
        lines = block \ lines
    }

    mm_outsheet(htmlfile, lines, "replace")
}

void function normalize_stata_code_class(string scalar htmlfile)
{
    // Stata markdown: ```stata → language-stata; leftover ```{stata} → language-{stata}
    lines = cat(htmlfile)
    if (rows(lines) == 0) return
    ugly = "language-" + "{" + "stata" + "}"
    lines = usubinstr(lines, ugly, "language-stata", .)
    mm_outsheet(htmlfile, lines, "replace")
}

// ---------- bundle / zip helpers ----------

real scalar path_is_abs(string scalar p)
{
    return(pathisabs(p))
}

string scalar path_suffix_lower(string scalar p)
{
    return(ustrlower(pathsuffix(p)))
}

string scalar embed_kind(string scalar path)
{
    ext = path_suffix_lower(path)
    if (ext == ".png" | ext == ".jpg" | ext == ".jpeg" | ext == ".svg" |
        ext == ".gif" | ext == ".bmp" | ext == ".webp") return("fig")
    if (ext == ".html" | ext == ".htm" | ext == ".md") return("tab")
    return("")
}

real scalar path_is_remote(string scalar p)
{
    pl = strtrim(p)
    if (pl == "") return(1)
    if (ustrpos(ustrlower(pl), "data:") == 1) return(1)
    if (pathisurl(pl)) return(1)
    return(0)
}

string colvector path_ancestors(string scalar din)
{
    out = J(0, 1, "")
    d = strtrim(din)
    if (d == "") d = pwd()
    if (!pathisabs(d)) d = pathresolve(pwd(), d)
    for (k = 1; k <= 8; k++) {
        if (d == "") break
        if (rows(out) > 0) {
            if (sum(out :== d) > 0) break
        }
        out = out \ d
        p = pathgetparent(d)
        if (p == "" | p == d) break
        d = p
    }
    return(out)
}

string colvector unique_keep_order(string colvector v)
{
    out = J(0, 1, "")
    for (i = 1; i <= rows(v); i++) {
        if (v[i] == "") continue
        if (rows(out) > 0) {
            if (sum(out :== v[i]) > 0) continue
        }
        out = out \ v[i]
    }
    return(out)
}

void function tohtml_init_resource_root(string scalar logfile)
{
    external string scalar tohtml_resource_root
    d = pathgetparent(logfile)
    if (d == "") d = pwd()
    if (!pathisabs(d)) d = pathresolve(pwd(), d)
    tohtml_resource_root = d
}

string scalar tohtml_get_resource_root()
{
    external string scalar tohtml_resource_root
    if (tohtml_resource_root == "") return(pwd())
    return(tohtml_resource_root)
}

void function tohtml_note_resource_base(string scalar base)
{
    external string scalar tohtml_resource_root
    if (base == "") return
    tohtml_resource_root = base
}

string scalar path_rel_to_base(string scalar absfile, string scalar base)
{
    a = normalize_path(absfile)
    b = normalize_path(base)
    if (a == "" | b == "") return("")
    pref = ustrlower(b) + "/"
    if (ustrpos(ustrlower(a), pref) != 1) return("")
    return(substr(a, strlen(b) + 2, .))
}

string scalar path_rel_to_dir(string scalar absfile, string scalar dir)
{
    // Relative path from dir to file, using ../ when file is not inside dir.
    d = normalize_path(dir)
    if (d != "" & !pathisabs(d)) d = pathresolve(pwd(), d)
    a = normalize_path(absfile)
    if (a != "" & !pathisabs(a)) a = pathresolve(pwd(), a)
    rel = path_rel_to_base(a, d)
    if (rel != "") return(subinstr(rel, "\", "/", .))
    prefix = ""
    for (k = 1; k <= 8; k++) {
        p = pathgetparent(d)
        if (p == "" | p == d) break
        prefix = prefix + "../"
        rel = path_rel_to_base(a, p)
        if (rel != "") return(prefix + subinstr(rel, "\", "/", .))
        d = p
    }
    return("")
}

string scalar resolve_local_file(string scalar src, string scalar root)
{
    src0 = strtrim(src)
    root0 = root
    if (path_is_remote(src0)) return("")

    if (pathisabs(src0)) {
        if (fileexists(src0)) return(src0)
        return("")
    }

    bases = unique_keep_order(path_ancestors(tohtml_get_resource_root()) \ path_ancestors(root0) \ path_ancestors(pwd()))
    for (j = 1; j <= rows(bases); j++) {
        cand = pathresolve(bases[j], src0)
        if (fileexists(cand)) {
            tohtml_note_resource_base(bases[j])
            return(cand)
        }
    }
    if (fileexists(src0)) {
        tohtml_note_resource_base(pwd())
        return(pathresolve(pwd(), src0))
    }
    return("")
}

real scalar path_is_under(string scalar file, string scalar dir)
{
    f = abs_path_key(file)
    d = abs_path_key(dir)
    if (f == "" | d == "") return(0)
    if (f == d) return(1)
    return(ustrpos(f, d + "/") == 1)
}

string scalar unique_bundle_name(string scalar destdir, string scalar base, string colvector used)
{
    // Only suffix when THIS run already claimed the basename.
    // An existing dest file is overwritten (copy, replace), not copied as _2.
    if (sum(used :== base) == 0) return(base)

    suf = pathsuffix(base)
    stem = pathrmsuffix(base)
    for (k = 2; k <= 9999; k++) {
        cand = stem + "_" + strofreal(k) + suf
        if (sum(used :== cand) == 0) return(cand)
    }
    return(stem + "_x" + suf)
}

string colvector extract_src_attrs(string scalar s)
{
    out = J(0, 1, "")
    s2 = s
    for (k = 1; k <= 30; k++) {
        if (ustrregexm(s2, `"src *= *"([^"]+)""')) {
            out = out \ ustrregexs(1)
            s2 = usubinstr(s2, ustrregexs(0), "", 1)
        }
        else if (ustrregexm(s2, `"src *= *'([^']+)'"')) {
            out = out \ ustrregexs(1)
            s2 = usubinstr(s2, ustrregexs(0), "", 1)
        }
        else break
    }
    return(out)
}

string colvector extract_embed_srcs(string colvector lines)
{
    out = J(0, 1, "")
    infence = 0
    for (i = 1; i <= rows(lines); i++) {
        if (is_md_fence_line(lines[i])) {
            infence = !infence
            continue
        }
        if (infence) continue
        out = out \ extract_src_attrs(lines[i])
    }
    return(out)
}

string colvector extract_md_images(string colvector lines)
{
    out = J(0, 1, "")
    infence = 0
    for (i = 1; i <= rows(lines); i++) {
        if (is_md_fence_line(lines[i])) {
            infence = !infence
            continue
        }
        if (infence) continue
        s2 = lines[i]
        for (k = 1; k <= 30; k++) {
            if (ustrregexm(s2, `"!\[[^\]]*\]\(([^)]+)\)"')) {
                out = out \ ustrregexs(1)
                s2 = usubinstr(s2, ustrregexs(0), "", 1)
            }
            else break
        }
    }
    return(out)
}

string colvector replace_path_refs(string colvector lines, string scalar oldp, string scalar newref)
{
    // Replace a file path only where it is a complete src / markdown target,
    // not as a substring of a longer path.
    if (oldp == "" | newref == "" | oldp == newref) return(lines)
    dq = char(34)
    sq = char(39)
    olds = (oldp \ slash_norm_src(oldp) \ normalize_path(oldp))
    olds = olds \ subinstr(normalize_path(oldp), "/", char(92), .)
    olds = uniqrows(select(olds, olds :!= ""))
    infence = 0
    for (i = 1; i <= rows(lines); i++) {
        line = lines[i]
        if (is_md_fence_line(line)) {
            infence = !infence
            continue
        }
        if (infence) continue
        for (j = 1; j <= rows(olds); j++) {
            op = olds[j]
            if (op == "" | op == newref) continue
            line = usubinstr(line, "src=" + dq + op + dq, "src=" + dq + newref + dq, .)
            line = usubinstr(line, "src=" + sq + op + sq, "src=" + sq + newref + sq, .)
            line = usubinstr(line, "href=" + dq + op + dq, "href=" + dq + newref + dq, .)
            line = usubinstr(line, "href=" + sq + op + sq, "href=" + sq + newref + sq, .)
            line = usubinstr(line, "](" + op + ")", "](" + newref + ")", .)
        }
        lines[i] = line
    }
    return(lines)
}

void function fix_table_override_css(string scalar tabfile)
{
    // Older outreg2e HTML injected GitHub tohtml.css (as table-override.css)
    // into iframes. That restyles collect / outreg three-line tables.
    // Strip those script hooks; leave the table's own <style> alone.
    if (!fileexists(tabfile)) return
    lines = cat(tabfile)
    if (rows(lines) == 0) return
    n = rows(lines)
    keep = J(n, 1, 1)
    i = 1
    while (i <= n) {
        if (ustrpos(ustrlower(lines[i]), "<script") > 0) {
            j = i
            hit = 0
            while (j <= n) {
                if (ustrpos(lines[j], "table-override.css") > 0) hit = 1
                if (ustrpos(ustrlower(lines[j]), "</script>") > 0) break
                j++
            }
            if (hit) {
                for (k = i; k <= j; k++) keep[k] = 0
                i = j + 1
                continue
            }
        }
        i++
    }
    if (sum(keep) == n) return
    if (sum(keep) == 0) return
    mm_outsheet(tabfile, select(lines, keep), "replace")
}

void function stata_copy_file(string scalar src, string scalar dest)
{
    cmd = "copy " + char(34) + src + char(34) + " " + char(34) + dest + char(34) + ", replace"
    stata(cmd, 1)
}

void function bundle_report(string scalar htmlfile, string scalar mdfile)
{
    htmlfile = normalize_path(htmlfile)
    root = pathgetparent(htmlfile)
    if (root == "") root = "."

    figdir = pathjoin(root, "figures")
    tabdir = pathjoin(root, "tables")
    stata("cap mkdir " + char(34) + figdir + char(34), 1)
    stata("cap mkdir " + char(34) + tabdir + char(34), 1)

    html = cat(htmlfile)
    md = J(0, 1, "")
    hasmd = 0
    if (mdfile != "") {
        mdfile = normalize_path(mdfile)
        if (fileexists(mdfile)) {
            md = cat(mdfile)
            hasmd = 1
        }
    }

    srcs = extract_embed_srcs(html)
    if (hasmd) srcs = srcs \ extract_embed_srcs(md) \ extract_md_images(md)
    srcs = select(srcs, srcs :!= "")
    if (rows(srcs) > 0) srcs = uniqrows(srcs)
    if (rows(srcs) > 1) srcs = srcs[order(-strlen(srcs), 1)]

    used_fig = J(0, 1, "")
    used_tab = J(0, 1, "")
    copied_key = J(0, 1, "")
    copied_ref = J(0, 1, "")
    ziprel = J(0, 1, "")

    for (i = 1; i <= rows(srcs); i++) {
        src = strtrim(srcs[i])
        if (path_is_remote(src)) continue

        resolved = resolve_local_file(src, root)
        if (resolved == "") {
            printf("{txt}note: resource not found, skipped: %s\n", src)
            continue
        }
        kind = embed_kind(resolved)
        if (kind == "") {
            printf("{txt}note: unsupported resource type, skipped: %s\n", src)
            continue
        }

        key = abs_path_key(resolved)
        if (rows(copied_key) > 0) {
            hit = selectindex(copied_key :== key)
            if (length(hit) > 0) {
                newref = copied_ref[hit[1]]
                html = replace_path_refs(html, src, newref)
                if (hasmd) md = replace_path_refs(md, src, newref)
                continue
            }
        }

        if (kind == "fig") {
            dest_dir = figdir
            relprefix = "./figures/"
            zipfolder = "figures/"
        }
        else {
            dest_dir = tabdir
            relprefix = "./tables/"
            zipfolder = "tables/"
        }

        // Already lives in the bundle folder: keep the original name, do not copy as _2
        if (path_is_under(resolved, dest_dir)) {
            base = pathbasename(resolved)
            if (kind == "fig") {
                if (sum(used_fig :== base) == 0) used_fig = used_fig \ base
            }
            else {
                if (sum(used_tab :== base) == 0) used_tab = used_tab \ base
            }
            newref = relprefix + base
            copied_key = copied_key \ key
            copied_ref = copied_ref \ newref
            ziprel = ziprel \ (zipfolder + base)
            html = replace_path_refs(html, src, newref)
            if (hasmd) md = replace_path_refs(md, src, newref)
            if (kind == "tab" & (path_suffix_lower(resolved) == ".html" |
                path_suffix_lower(resolved) == ".htm")) {
                fix_table_override_css(resolved)
                css_bases = copy_table_companion_css(resolved, resolved)
                for (k = 1; k <= rows(css_bases); k++) {
                    ziprel = ziprel \ (zipfolder + css_bases[k])
                }
            }
            continue
        }

        base = pathbasename(resolved)
        if (kind == "fig") {
            base = unique_bundle_name(dest_dir, base, used_fig)
            used_fig = used_fig \ base
        }
        else {
            base = unique_bundle_name(dest_dir, base, used_tab)
            used_tab = used_tab \ base
        }
        dest = pathjoin(dest_dir, base)
        if (!paths_are_same(resolved, dest)) {
            stata_copy_file(resolved, dest)
        }
        newref = relprefix + base
        copied_key = copied_key \ key
        copied_ref = copied_ref \ newref
        dest_key = abs_path_key(dest)
        if (dest_key != key) {
            copied_key = copied_key \ dest_key
            copied_ref = copied_ref \ newref
        }
        ziprel = ziprel \ (zipfolder + base)
        html = replace_path_refs(html, src, newref)
        if (hasmd) md = replace_path_refs(md, src, newref)
        if (slash_norm_src(resolved) != slash_norm_src(src)) {
            html = replace_path_refs(html, resolved, newref)
            if (hasmd) md = replace_path_refs(md, resolved, newref)
        }
        if (kind == "tab" & (path_suffix_lower(dest) == ".html" |
            path_suffix_lower(dest) == ".htm")) {
            fix_table_override_css(dest)
            css_bases = copy_table_companion_css(resolved, dest)
            for (k = 1; k <= rows(css_bases); k++) {
                ziprel = ziprel \ (zipfolder + css_bases[k])
            }
        }
    }

    mm_outsheet(htmlfile, html, "replace")
    if (hasmd) mm_outsheet(mdfile, md, "replace")

    if (rows(ziprel) > 0) ziprel = uniqrows(ziprel)
    s = ""
    for (j = 1; j <= rows(ziprel); j++) {
        if (ziprel[j] == "") continue
        s = s + (s == "" ? "" : " ") + char(34) + ziprel[j] + char(34)
    }
    st_local("bundle_zip_rel", s)
}

string colvector function keep_stata_code_lines(string colvector lines)
{
    // Keep Stata echoed commands (lines starting with . or >) and embed tags.
    // Drop command output and other non-command lines.
    n = rows(lines)
    if (n == 0) return(lines)

    work = J(n, 1, "")
    for (i = 1; i <= n; i++) {
        s = ustrltrim(lines[i])
        changed = 1
        while (changed) {
            changed = 0
            if (ustrpos(s, "{com}") == 1) {
                s = ustrltrim(usubstr(s, 6, .))
                changed = 1
            }
            else if (ustrpos(s, "{res}") == 1) {
                s = ustrltrim(usubstr(s, 6, .))
                changed = 1
            }
            else if (ustrpos(s, "{txt}") == 1) {
                s = ustrltrim(usubstr(s, 6, .))
                changed = 1
            }
        }
        work[i] = s
    }

    keep = (usubstr(work, 1, 1) :== ".") :| (usubstr(work, 1, 1) :== ">")
    keep = keep :| (ustrpos(work, "<iframe") :== 1) :| (ustrpos(work, "<img") :== 1)
    // After display-tag replacement, keep narrative blocks (markers have no . prefix)
    keep = keep :| (get_textcell_index(work) :> 0)
    return(select(lines, keep))
}

void function rewrite_md_cleancode(string scalar ofi, string scalar tfi, real scalar replace)
{
    // Replace {ishere display ...} from the full log first, then drop output.
    fcon = cat(ofi)
    fcon = merge_html_vectorized(fcon)
    fcon = drop_stata_log_header(fcon)
    fcon = ishererep(fcon)
    fcon = merge_html_vectorized(fcon)
    fcon = clean_textcell_content(fcon)
    fcon = subisheredintxt(fcon)
    fcon = keep_stata_code_lines(fcon)
    rewrite_md_finish(fcon, tfi, replace, 1)
}

void function rewrite_md(string scalar ofi, string scalar tfi, real scalar replace)
{
    fcon = cat(ofi)
    fcon = merge_html_vectorized(fcon)
    fcon = fence_stata_log_header(fcon)
    fcon = ishererep(fcon)
    fcon = merge_html_vectorized(fcon)
    fcon = clean_textcell_content(fcon)
    fcon = subisheredintxt(fcon)
    rewrite_md_finish(fcon, tfi, replace, 0)
}

void function rewrite_md_finish(string colvector fcon, string scalar tfi, real scalar replace, real scalar strip_prompt)
{
    // 3. 移除前缀
    prefixes = (">", "{com}", "{res}", "{txt}")
    fcon = remove_prefix_and_trim(fcon, prefixes)

    // cleancode: splice "> " wraps back onto the ". command" they continue
    if (strip_prompt) {
        fcon = join_stata_cmd_continuations(fcon)
    }

    flag = strpos(strtrim(substr(fcon, 2, .)), "ishere"):==1
    rem = strtrim(substr(fcon, strpos(fcon, "ishere"):+strlen("ishere")+1, .))
    flag2 = (rem:== "") + (rem:=="```")
    flag = flag:* flag2

    if (sum(flag) > 0) {
        idx = selectindex(flag)
        fcon[idx] = J(length(idx),1,"```")
    }
   
    // 5. 去除空行
    fcon = select(fcon, strtrim(fcon) :!= ".")
    // fcon = select(fcon, strtrim(fcon) :!= "")

    // 5b. 删除特定行
    bad1 = subinstr((substr(fcon,2,.))," ","",.) :== "capturelogclose"
    bad2 = strtrim(fcon) :== "{smcl}"
    bad3 = subinstr((substr(fcon,2,.))," ","",.) :== "{sf}{uloff}"
    fcon = select(fcon, !(bad1 :| bad2 :| bad3))
    
    // . ishere # hearder -> # header
    fcon = get_dot_header(fcon)

    // cleancode: drop the Stata prompt so the fence looks like a do-file
    if (strip_prompt) {
        fcon = strip_stata_cmd_prompt(fcon)
    }
    
    // fcon= remove_img_iframe(fcon)
    // Open a Stata fence after the ```text log header (or at file start)
    // so users do not need ishere / ishere ``` as code-block markers.
    fcon = ensure_stata_fence_open(fcon)
    // 6. 【核心】动态修复：标题 / 图 / 表 / 叙事块外的代码自动加围栏
    fcon = insert_backtick_before_hash(fcon)
    fcon = add_two_blank_lines(fcon)
    
    // 7. （可选）过滤短代码块
    fconlen = char_lengths_including_backticks(fcon)
    fcon = select(fcon, !(fconlen :< 2*(strlen("```")+2)))
    
    // 将md源代码插入到<iframe ></iframe>位置
    fcon = splice_md_iframes(fcon)

    // Opening Stata code fences: ```  →  ```stata  (keep ```text etc.)
    fcon = tag_stata_opening_fences(fcon)
    fcon = slash_normalize_embed_paths(fcon)

    // 8. 输出
    if (replace == 0) {
        mm_outsheet(tfi, fcon)
    } else {
        mm_outsheet(tfi, fcon, "replace")
    }
}


void function rewrite_md2(string scalar ofi, string scalar tfi, real scalar replace)
{
    // 1. 读取文件
    fcon = cat(ofi)
    fcon = merge_html_vectorized(fcon)
    fcon = drop_stata_log_header(fcon)
    fcon = ishererep(fcon)
    // 2. 合并 HTML 行
    fcon = merge_html_vectorized(fcon)

    fcon = clean_textcell_content(fcon)
    
    // 2b. 替换文本块中的 ishere display 占位符
    fcon = subisheredintxt(fcon)
    
    // 3. 移除前缀
    prefixes = (">", "{com}", "{res}", "{txt}")
    fcon = remove_prefix_and_trim(fcon, prefixes)
    // . ishere # hearder -> # header
    fcon = get_dot_header(fcon)
    // 4. 
    fcon_trim = ustrltrim(fcon)
    flag = (ustrpos(fcon_trim, "#") :== 1)
    flag = flag :| (ustrpos(fcon_trim, "<img") :== 1)
    flag = flag :| (ustrpos(fcon_trim, "<iframe") :== 1)
    flag = flag :| get_textcell_index(fcon_trim)
    // 增加 textcell 块的识别

    fcon = select(fcon, flag)
    fcon_trim = ustrltrim(fcon)
    
    flag = (strpos(fcon_trim, "_ishere_"):== 1)
    if (sum(flag) > 0) {
        idx = selectindex(flag)
        fcon[idx] = J(length(idx),1,"") 
    }

    // 将md源代码插入到<iframe ></iframe>位置
    fcon = splice_md_iframes(fcon)
    
    
    fcon = slash_normalize_embed_paths(fcon)
    // 8. 输出
    if (replace == 0) {
        mm_outsheet(tfi, fcon)
    } else {
        mm_outsheet(tfi, fcon, "replace")
    }
}

string colvector splice_md_iframes(string colvector fcon)
{
    // Replace <iframe path.md ></iframe> with the file contents.
    // Keep every line before the first iframe (flag[1] > 1), not only when
    // the iframe is not the last line — clean mode often ends with the table.
    regex = `"(\s*<iframe\s*.*\.md\s*></iframe>\s*)"'
    flag = selectindex(regexm(fcon, regex))
    if (length(flag) == 0) return(fcon)
    n = length(fcon)
    nflag = length(flag)
    if (flag[1] > 1) fconnew = fcon[1::(flag[1]-1)]
    else fconnew = J(0, 1, "")
    for (i = 1; i <= nflag; i++) {
        fconnew = fconnew \ extractmdtable(fcon[flag[i]])
        if (i < nflag) {
            a = flag[i] + 1
            b = flag[i + 1] - 1
            if (a <= b) fconnew = fconnew \ fcon[a::b]
            else fconnew = fconnew \ " "
        }
        else if (flag[i] < n) {
            fconnew = fconnew \ fcon[(flag[i]+1)::n]
        }
    }
    return(fconnew)
}

string colvector extractmdtable(string scalar line){
    src = iframe_bare_path(line)
    resolved = resolve_local_file(src, tohtml_get_resource_root())
    if (resolved == "") {
        printf("{err}extractmdtable: file not exist: %s\n", src)
        return(J(0, 1, ""))
    }
    mdtext = cat(resolved)
    flag = 1
    pos = 1
    maxn = length(mdtext)
    while(flag & pos < maxn ){
        line3 = ustrtrim(mdtext[1])
        if(strlen(line3) == 0){
            if(length(mdtext) > 1){
                mdtext = mdtext[2::length(mdtext)]
            }
            else{
                mdtext = J(0,1,"")
            }
        }
        else{
            flag = 0
        }
        pos = pos + 1
    }
    return(mdtext)
}

string scalar iframe_bare_path(string scalar line)
{
    line2 = usubinstr(line, "<iframe", "", 1)
    line2 = usubinstr(line2, "</iframe>", "", 1)
    line2 = strtrim(line2)
    if (strlen(line2) > 0) {
        if (substr(line2, strlen(line2), 1) == ">") {
            line2 = strtrim(substr(line2, 1, strlen(line2)-1))
        }
    }
    // Markdown-table markers are "<iframe path.md></iframe>". Keep only
    // the path token so data-tohtml-title= and other attributes are ignored.
    if (ustrregexm(ustrltrim(line2), `"^([^ \t>]+)"')) {
        return(ustrregexs(1))
    }
    return(line2)
}

string scalar html_data_attr(string scalar tag, string scalar name)
{
    if (name == "") return("")
    if (ustrregexm(tag, "(?i)" + name + `" *= *"([^"]*)""')) return(ustrregexs(1))
    if (ustrregexm(tag, "(?i)" + name + `" *= *'([^']*)'"')) return(ustrregexs(1))
    return("")
}

string scalar strip_html_attr(string scalar tag, string scalar name)
{
    if (name == "") return(tag)
    tag = ustrregexra(tag, "(?i)[ \t]+" + name + `" *= *"[^"]*""', "")
    tag = ustrregexra(tag, "(?i)[ \t]+" + name + `" *= *'[^']*'"', "")
    return(tag)
}

string colvector wrap_captioned_block(string scalar kind, string scalar cap, string colvector body)
{
    string scalar q, open, close, capel, cls, capcls
    if (ustrtrim(cap) == "") return(body)
    q = char(34)
    if (kind == "figure") {
        cls = "tohtml-figure"
        capcls = "tohtml-fig-title"
    }
    else {
        cls = "tohtml-table-block"
        capcls = "tohtml-table-title"
    }
    open = "<figure class=" + q + cls + q + ">"
    capel = "<figcaption class=" + q + capcls + q + ">" + cap + "</figcaption>"
    close = "</figure>"
    if (kind == "figure") {
        return((open) \ body \ (capel) \ (close))
    }
    return((open) \ (capel) \ body \ (close))
}

string colvector wrap_img_caption(string scalar line, real scalar convert_img)
{
    string scalar cap, img
    cap = html_data_attr(line, "data-tohtml-title")
    img = strip_html_attr(line, "data-tohtml-title")
    if (convert_img) {
        img = rewrite_md_bang_images(html_img_to_md_image(img))
    }
    if (ustrtrim(cap) == "") return((img))
    if (convert_img) {
        return(wrap_captioned_block("figure", cap, ("" \ img \ "")))
    }
    return(wrap_captioned_block("figure", cap, (img)))
}

real scalar img_ext_embeddable(string scalar src)
{
    ext = path_suffix_lower(src)
    if (ext == ".png" | ext == ".jpg" | ext == ".jpeg") return(1)
    if (ext == ".gif" | ext == ".tif" | ext == ".tiff") return(1)
    return(0)
}

string scalar slash_norm_src(string scalar src)
{
    return(subinstr(strtrim(src), "\", "/", .))
}

string scalar src_for_default(string scalar src, string scalar basedir)
{
    // Keep absolute paths. Keep relative paths if they resolve from basedir
    // (the report HTML folder). Otherwise use the file's absolute path.
    src0 = slash_norm_src(src)
    basedir0 = basedir
    if (src0 == "" | path_is_remote(src0)) return(src0)
    resolved = resolve_local_file(src0, basedir0)
    if (pathisabs(src0)) return(src0)
    if (basedir0 == "") basedir0 = pwd()
    if (!pathisabs(basedir0)) basedir0 = pathresolve(pwd(), basedir0)
    cand = pathresolve(basedir0, src0)
    if (fileexists(cand)) return(src0)
    if (resolved != "") return(slash_norm_src(resolved))
    return(src0)
}

string colvector slash_normalize_embed_paths(string colvector lines)
{
    infence = 0
    for (i = 1; i <= rows(lines); i++) {
        line = lines[i]
        if (is_md_fence_line(line)) {
            infence = !infence
            continue
        }
        if (infence) continue
        srcs = extract_src_attrs(line)
        if (rows(srcs) > 0) {
            for (j = 1; j <= rows(srcs); j++) {
                src = srcs[j]
                if (src == "" | path_is_remote(src)) continue
                news = slash_norm_src(src)
                if (news != src) line = subinstr(line, src, news, .)
            }
        }
        else {
            t = ustrltrim(line)
            if (usubstr(t, 1, 7) == "<iframe") {
                bp = iframe_bare_path(line)
                if (bp != "" & !path_is_remote(bp)) {
                    news = slash_norm_src(bp)
                    if (news != bp) line = subinstr(line, bp, news, 1)
                }
            }
        }
        mdsrcs = extract_md_images((line \ J(0, 1, "")))
        for (j = 1; j <= rows(mdsrcs); j++) {
            src = mdsrcs[j]
            if (src == "" | path_is_remote(src)) continue
            news = slash_norm_src(src)
            if (news != src) line = subinstr(line, src, news, .)
        }
        lines[i] = line
    }
    return(lines)
}

string scalar rewrite_md_bang_images(string scalar line)
{
    // Remote ![](http...) must not go through embedimage (fetch can fail).
    // Local paths are left as written (absolute or relative); Windows
    // absolute paths convert to Base64 under markdown, embedimage.
    s = line
    out = ""
    for (k = 1; k <= 40; k++) {
        if (!ustrregexm(s, `"^(.*?)(!\[[^\]]*\]\()([^)]+)(\))(.*)"')) {
            out = out + s
            break
        }
        pre = ustrregexs(1)
        open = ustrregexs(2)
        src = ustrregexs(3)
        close = ustrregexs(4)
        post = ustrregexs(5)
        out = out + pre
        if (path_is_remote(src)) {
            q = char(34)
            out = out + "<img src="http://fmwww.bc.edu/repec/bocode/t/+&#32;q&#32;+&#32;src&#32;+&#32;q&#32;+">"
        }
        else if (img_ext_embeddable(src)) {
            out = out + open + slash_norm_src(src) + close
        }
        else {
            out = out + open + src + close
        }
        s = post
    }
    return(out)
}

string scalar html_img_to_md_image(string scalar line)
{
    out = ""
    rest = line
    for (k = 1; k <= 30; k++) {
        low = ustrlower(rest)
        p = ustrpos(low, "<img")
        if (p == 0) {
            out = out + rest
            break
        }
        out = out + usubstr(rest, 1, p - 1)
        rest = usubstr(rest, p, .)
        gt = ustrpos(rest, ">")
        if (gt == 0) {
            out = out + rest
            rest = ""
            break
        }
        tag = usubstr(rest, 1, gt)
        rest = usubstr(rest, gt + 1, .)
        srcs = extract_src_attrs(tag)
        src = ""
        if (rows(srcs) > 0) src = srcs[1]
        if (src != "" & img_ext_embeddable(src) & !path_is_remote(src)) {
            out = out + "![](" + slash_norm_src(src) + ")"
        }
        else {
            out = out + tag
        }
    }
    return(out)
}

string colvector split_newlines(string scalar s)
{
    s = usubinstr(s, char(13) + char(10), char(10), .)
    s = usubinstr(s, char(13), char(10), .)
    if (s == "") return(J(0, 1, ""))
    if (usubstr(s, ustrlen(s), 1) == char(10)) {
        s = usubstr(s, 1, ustrlen(s) - 1)
    }
    if (s == "") return(J(0, 1, ""))
    nlf = ustrlen(s) - ustrlen(usubinstr(s, char(10), "", .))
    n = nlf + 1
    out = J(n, 1, "")
    rest = s
    for (i = 1; i <= n; i++) {
        p = ustrpos(rest, char(10))
        if (p == 0) {
            out[i] = rest
            break
        }
        out[i] = usubstr(rest, 1, p - 1)
        rest = usubstr(rest, p + 1, .)
    }
    return(out)
}

void function collect_embed_style(string scalar st)
{
    external string scalar tohtml_embed_css
    st = ustrtrim(st)
    if (st == "") return
    // iframe-document rules must not restyle the report page
    st = ustrregexra(st, `"(?i)html\s*,\s*body\s*\{[^}]*\}"', "")
    st = ustrtrim(st)
    if (st == "") return
    if (tohtml_embed_css == "") {
        tohtml_embed_css = st
        return
    }
    if (ustrpos(tohtml_embed_css, st) == 0) {
        tohtml_embed_css = tohtml_embed_css + char(10) + st
    }
}

string scalar join_lines(string colvector lines)
{
    s = ""
    for (i = 1; i <= rows(lines); i++) {
        s = s + lines[i] + char(10)
    }
    return(s)
}

string colvector extract_link_css_hrefs(string scalar blob)
{
    out = J(0, 1, "")
    s = blob
    for (k = 1; k <= 30; k++) {
        if (ustrregexm(s, "(?is)<link\b[^>]*>")) {
            tag = ustrregexs(0)
            s = usubinstr(s, tag, "", 1)
            tlow = ustrlower(tag)
            if (ustrpos(tlow, "stylesheet") == 0 & ustrpos(tlow, "text/css") == 0) continue
            href = ""
            if (ustrregexm(tag, `"href *= *"([^"]+)""')) href = ustrregexs(1)
            else if (ustrregexm(tag, `"href *= *'([^']+)'"')) href = ustrregexs(1)
            if (href != "") out = out \ href
        }
        else break
    }
    return(out)
}

string colvector companion_css_files(string scalar htmlfile)
{
    out = J(0, 1, "")
    if (!fileexists(htmlfile)) return(out)
    dir = pathgetparent(htmlfile)
    if (dir == "") dir = pwd()
    blob = join_lines(cat(htmlfile))
    hrefs = extract_link_css_hrefs(blob)
    for (i = 1; i <= rows(hrefs); i++) {
        f = strtrim(hrefs[i])
        if (f == "" | path_is_remote(f)) continue
        if (!pathisabs(f)) f = pathresolve(dir, f)
        if (fileexists(f)) out = out \ f
    }
    sib = pathjoin(dir, pathrmsuffix(pathbasename(htmlfile)) + ".css")
    if (fileexists(sib)) out = out \ sib
    if (rows(out) == 0) {
        g = guess_companion_css(htmlfile, dir)
        if (g != "") out = out \ g
    }
    return(unique_abs_paths(out))
}

string colvector unique_abs_paths(string colvector files)
{
    if (rows(files) == 0) return(files)
    keep = J(rows(files), 1, 0)
    keys = J(0, 1, "")
    for (i = 1; i <= rows(files); i++) {
        if (files[i] == "") continue
        k = abs_path_key(files[i])
        if (k == "") k = slash_norm_src(files[i])
        if (rows(keys) > 0) {
            if (sum(keys :== k) > 0) continue
        }
        keys = keys \ k
        keep[i] = 1
    }
    if (sum(keep) == 0) return(J(0, 1, ""))
    return(select(files, keep))
}

string scalar first_table_class(string scalar blob)
{
    cls = ""
    if (ustrregexm(blob, `"(?is)<table\b[^>]*class *= *"([^"]+)""')) cls = ustrregexs(1)
    else if (ustrregexm(blob, `"(?is)<table\b[^>]*class *= *'([^']+)'"')) cls = ustrregexs(1)
    cls = strtrim(cls)
    if (cls == "") return("")
    p = ustrpos(cls, " ")
    if (p > 0) cls = usubstr(cls, 1, p - 1)
    return(cls)
}

real scalar reserved_css_name(string scalar base)
{
    b = ustrlower(pathbasename(base))
    return(b == "tohtml.css" | b == "table-override.css")
}

real scalar css_looks_collect(string scalar cssfile)
{
    if (!fileexists(cssfile)) return(0)
    raw = cat(cssfile)
    if (rows(raw) == 0) return(0)
    blob = join_lines(raw)
    return(ustrpos(blob, "border-collapse") > 0 | ustrpos(blob, ".Table") > 0)
}

real scalar css_mentions_table_class(string scalar cssfile, string scalar cls)
{
    if (cls == "" | !fileexists(cssfile)) return(0)
    blob = join_lines(cat(cssfile))
    return(ustrpos(blob, "." + cls + "_") > 0 | ustrpos(blob, "." + cls + "{") > 0 | ustrpos(blob, "." + cls + " ") > 0)
}

string scalar guess_companion_css(string scalar htmlfile, string scalar hdir)
{
    names = dir(hdir, "files", "*.css")
    if (rows(names) == 0) return("")
    blob = ""
    if (fileexists(htmlfile)) blob = join_lines(cat(htmlfile))
    cls = first_table_class(blob)
    unpaired = J(0, 1, "")
    classhit = J(0, 1, "")
    for (i = 1; i <= rows(names); i++) {
        base = names[i]
        if (reserved_css_name(base)) continue
        full = pathjoin(hdir, base)
        if (!css_looks_collect(full)) continue
        stem = pathrmsuffix(base)
        if (fileexists(pathjoin(hdir, stem + ".html")) | fileexists(pathjoin(hdir, stem + ".htm"))) continue
        unpaired = unpaired \ full
        if (css_mentions_table_class(full, cls)) classhit = classhit \ full
    }
    if (rows(classhit) == 1) return(classhit[1])
    if (rows(unpaired) == 1) return(unpaired[1])
    return("")
}

void function collect_embed_css_file(string scalar cssfile)
{
    if (!fileexists(cssfile)) return
    css = cat(cssfile)
    if (rows(css) == 0) return
    block = "<style>" + char(10) + join_lines(css) + "</style>"
    collect_embed_style(block)
}

string colvector copy_table_companion_css(string scalar src_html, string scalar dest_html)
{
    // Follow <link rel=stylesheet> in the source table, same-name CSS,
    // and a unique unpaired collect CSS. Copy them next to dest and
    // rewrite hrefs so zip/bundle iframes keep collect/tableonly styles.
    csss = companion_css_files(src_html)
    dest_dir = pathgetparent(dest_html)
    if (dest_dir == "") dest_dir = pwd()
    dest_lines = cat(dest_html)
    used = J(0, 1, "")
    dest_bases = J(0, 1, "")
    seen_key = J(0, 1, "")
    for (i = 1; i <= rows(csss); i++) {
        key = abs_path_key(csss[i])
        if (key != "" & rows(seen_key) > 0) {
            if (sum(seen_key :== key) > 0) continue
        }
        if (key != "") seen_key = seen_key \ key
        oldbase = pathbasename(csss[i])
        base = unique_bundle_name(dest_dir, oldbase, used)
        used = used \ base
        dest_css = pathjoin(dest_dir, base)
        if (abs_path_key(csss[i]) != abs_path_key(dest_css)) {
            stata_copy_file(csss[i], dest_css)
        }
        dest_lines = replace_path_refs(dest_lines, csss[i], base)
        dest_lines = replace_path_refs(dest_lines, slash_norm_src(csss[i]), base)
        if (oldbase != base) {
            dest_lines = replace_path_refs(dest_lines, oldbase, base)
        }
        dest_bases = dest_bases \ base
    }
    mm_outsheet(dest_html, dest_lines, "replace")
    ensure_table_css_link(dest_html)
    return(dest_bases)
}

string scalar table_css_link_tag(string scalar href)
{
    q = char(34)
    return("<link rel=" + q + "stylesheet" + q + " type=" + q + "text/css" + q + " href=" + q + href + q + ">")
}

real scalar is_stylesheet_link_line(string scalar line)
{
    t = ustrlower(ustrtrim(line))
    if (ustrpos(t, "<link") != 1) return(0)
    if (ustrpos(t, "stylesheet") > 0) return(1)
    if (ustrpos(t, "text/css") > 0) return(1)
    return(0)
}

string colvector drop_stylesheet_link_lines(string colvector lines)
{
    if (rows(lines) == 0) return(lines)
    keep = J(rows(lines), 1, 1)
    for (i = 1; i <= rows(lines); i++) {
        if (is_stylesheet_link_line(lines[i])) keep[i] = 0
    }
    if (sum(keep) == 0) return(J(0, 1, ""))
    return(select(lines, keep))
}

real scalar lines_already_link_css(string colvector lines, string scalar cssbase)
{
    hrefs = extract_link_css_hrefs(join_lines(lines))
    want = ustrlower(subinstr(cssbase, "\", "/", .))
    for (i = 1; i <= rows(hrefs); i++) {
        got = ustrlower(subinstr(pathbasename(hrefs[i]), "\", "/", .))
        if (got == want) return(1)
    }
    return(0)
}

string colvector attach_table_css_link(string colvector lines, string scalar href)
{
    blob = ustrlower(join_lines(lines))
    link = table_css_link_tag(href)
    has_html = ustrpos(blob, "<html") > 0
    has_head_close = ustrpos(blob, "</head>") > 0

    if (has_head_close) {
        for (i = 1; i <= rows(lines); i++) {
            if (ustrpos(ustrlower(lines[i]), "</head>") > 0) {
                if (i == 1) return(link \ lines)
                return(lines[|1 \ i-1|] \ link \ lines[|i \ rows(lines)|])
            }
        }
    }
    if (has_html) {
        return(lines \ link)
    }

    q = char(34)
    lines = drop_stylesheet_link_lines(lines)
    open = "<!DOCTYPE html>" \ "<html>" \ "<head>" \
        "<meta charset=" + q + "utf-8" + q + ">" \ link \ "</head>" \ "<body>"
    return(open \ lines \ "</body>" \ "</html>")
}

void function ensure_table_css_link(string scalar htmlfile)
{
    // collect export, tableonly writes a <table> fragment plus basename.css
    // and no <link>. Wrap the fragment and put the stylesheet in <head>
    // so an iframe (default / zip) can apply the style.
    if (!fileexists(htmlfile)) return
    csss = companion_css_files(htmlfile)
    if (rows(csss) == 0) return

    lines = cat(htmlfile)
    hdir = pathgetparent(htmlfile)
    if (hdir == "") hdir = pwd()
    sib = pathjoin(hdir, pathrmsuffix(pathbasename(htmlfile)) + ".css")
    csspath = csss[1]
    for (i = 1; i <= rows(csss); i++) {
        if (abs_path_key(csss[i]) == abs_path_key(sib)) {
            csspath = csss[i]
            break
        }
    }

    href = path_rel_to_dir(csspath, hdir)
    if (href == "") href = pathbasename(csspath)

    blob = ustrlower(join_lines(lines))
    if (ustrpos(blob, "<style") > 0 &
        (ustrpos(blob, ".table") > 0 | ustrpos(blob, ".texout-table") > 0 |
         ustrpos(blob, "border-top-style") > 0)) return
    already = lines_already_link_css(lines, pathbasename(csspath))
    if (already & (ustrpos(blob, "<html") > 0 | ustrpos(blob, "</head>") > 0)) return

    lines = attach_table_css_link(lines, href)
    mm_outsheet(htmlfile, lines, "replace")
}

string colvector extract_html_table_fragment(string scalar htmlfile)
{
    // Body markup only. CSS braces in <style> break Stata markdown; styles
    // are collected and injected into the HTML <head> after conversion.
    raw = cat(htmlfile)
    if (rows(raw) == 0) return(J(0, 1, ""))

    full = ""
    for (i = 1; i <= rows(raw); i++) {
        full = full + raw[i] + char(10)
    }

    for (k = 1; k <= 20; k++) {
        if (ustrregexm(full, "(?is)<script\b[^>]*>.*?</script>")) {
            full = usubinstr(full, ustrregexs(0), "", 1)
        }
        else break
    }

    styles = ""
    work = full
    for (k = 1; k <= 20; k++) {
        if (ustrregexm(work, "(?is)<style\b[^>]*>.*?</style>")) {
            styles = styles + ustrregexs(0) + char(10)
            work = usubinstr(work, ustrregexs(0), "", 1)
        }
        else break
    }

    body = ""
    if (ustrregexm(full, "(?is)<body\b[^>]*>(.*)</body>")) {
        body = ustrregexs(1)
        for (k = 1; k <= 20; k++) {
            if (ustrregexm(body, "(?is)<style\b[^>]*>.*?</style>")) {
                styles = styles + ustrregexs(0) + char(10)
                body = usubinstr(body, ustrregexs(0), "", 1)
            }
            else break
        }
        for (k = 1; k <= 20; k++) {
            if (ustrregexm(body, "(?is)<script\b[^>]*>.*?</script>")) {
                body = usubinstr(body, ustrregexs(0), "", 1)
            }
            else break
        }
    }
    else {
        body = work
    }

    collect_embed_style(styles)
    cssfiles = companion_css_files(htmlfile)
    for (i = 1; i <= rows(cssfiles); i++) {
        collect_embed_css_file(cssfiles[i])
    }
    body = ustrtrim(body)
    for (k = 1; k <= 20; k++) {
        if (ustrregexm(body, "(?is)<link\b[^>]*>")) {
            body = usubinstr(body, ustrregexs(0), "", 1)
        }
        else break
    }
    body = ustrtrim(body)
    if (body == "") return(J(0, 1, ""))
    wrapped = "<div class=" + char(34) + "tohtml-embedded-table" + char(34) + ">" + char(10) + body + char(10) + "</div>"
    return(split_newlines(wrapped))
}

string colvector inline_iframe_tables(string colvector lines, string scalar mdfile, real scalar convert_img)
{
    root = pathgetparent(mdfile)
    if (root == "") root = pwd()
    out = J(0, 1, "")
    infence = 0
    for (i = 1; i <= rows(lines); i++) {
        line = lines[i]
        if (is_md_fence_line(line)) {
            infence = !infence
            out = out \ line
            continue
        }
        if (infence) {
            out = out \ line
            continue
        }
        t = ustrltrim(line)
        if (usubstr(t, 1, 7) != "<iframe") {
            out = out \ wrap_img_caption(line, convert_img)
            continue
        }
        cap = html_data_attr(line, "data-tohtml-title")
        srcs = extract_src_attrs(line)
        src = ""
        if (rows(srcs) > 0) src = srcs[1]
        else src = iframe_bare_path(line)
        if (src == "" | path_is_remote(src)) {
            out = out \ line
            continue
        }
        ext = path_suffix_lower(src)
        resolved = resolve_local_file(src, root)
        if (resolved == "") {
            printf("{txt}note: table file not found, iframe kept: %s\n", src)
            out = out \ line
            continue
        }
        if (ext == ".md") {
            frag = cat(resolved)
        }
        else if (ext == ".html" | ext == ".htm") {
            frag = extract_html_table_fragment(resolved)
        }
        else {
            out = out \ line
            continue
        }
        if (rows(frag) == 0) {
            printf("{txt}note: empty table file, iframe kept: %s\n", src)
            out = out \ line
            continue
        }
        frag = select(frag, strtrim(frag) :!= "")
        if (ext == ".md" & ustrtrim(cap) != "") {
            q = char(34)
            capel = "<p class=" + q + "tohtml-table-title" + q + ">" + cap + "</p>"
            out = out \ "" \ capel \ "" \ frag \ ""
        }
        else {
            out = out \ "" \ wrap_captioned_block("table", cap, frag) \ ""
        }
    }
    return(out)
}

void function tohtml_inline_tables(string scalar mdfile, real scalar convert_img)
{
    external string scalar tohtml_embed_css
    if (!fileexists(mdfile)) {
        errprintf("tohtml: Markdown file not found: %s\n", mdfile)
        exit(601)
    }
    tohtml_embed_css = ""
    lines = cat(mdfile)
    lines = inline_iframe_tables(lines, mdfile, convert_img)
    mm_outsheet(mdfile, lines, "replace")
}

void function tohtml_prepare_embed(string scalar mdfile)
{
    tohtml_inline_tables(mdfile, 1)
}

void function inject_embed_table_styles(string scalar htmlfile)
{
    external string scalar tohtml_embed_css
    if (tohtml_embed_css == "") return
    lines = cat(htmlfile)
    if (rows(lines) == 0) return

    csslines = split_newlines(tohtml_embed_css)
    idx = selectindex(ustrpos(lines, "</head>") :> 0)
    if (length(idx) > 0) {
        i = idx[1]
        if (i > 1) {
            lines = lines[|1 \ i-1|] \ csslines \ lines[|i \ rows(lines)|]
        }
        else {
            lines = csslines \ lines
        }
    }
    else {
        lines = csslines \ lines
    }
    mm_outsheet(htmlfile, lines, "replace")
}

string scalar normalize_table_css_size(string scalar raw, string scalar def)
{
    string scalar s, sl
    s = ustrtrim(raw)
    if (s == "") return(def)
    sl = ustrlower(s)
    if (sl == "none" | sl == "off" | sl == ".") return("none")
    if (ustrregexm(s, "[;{}<>" + char(34) + char(39) + "]")) return(def)
    if (ustrregexm(s, "^[0-9]+(\.[0-9]+)?$")) return(s + "px")
    return(s)
}

void function inject_table_scroll_css(string scalar htmlfile, string scalar maxw, string scalar maxh)
{
    string scalar css, q, ox, oy
    string colvector lines, csslines

    maxw = normalize_table_css_size(maxw, "100%")
    maxh = normalize_table_css_size(maxh, "80vh")
    if (maxw == "none") ox = "visible"
    else ox = "auto"
    if (maxh == "none") oy = "visible"
    else oy = "auto"
    q = char(34)
    css = "<style id=" + q + "tohtml-table-scroll" + q + ">" + char(10)
    css = css + ".tohtml-embedded-table {" + char(10)
    css = css + "  overflow-x: " + ox + " !important;" + char(10)
    css = css + "  overflow-y: " + oy + " !important;" + char(10)
    css = css + "  width: max-content !important;" + char(10)
    css = css + "  max-width: " + maxw + " !important;" + char(10)
    css = css + "  max-height: " + maxh + " !important;" + char(10)
    css = css + "  -webkit-overflow-scrolling: touch;" + char(10)
    css = css + "}" + char(10)
    css = css + ".tohtml-embedded-table table," + char(10)
    css = css + ".tohtml-embedded-table .texout-table {" + char(10)
    css = css + "  max-width: none !important;" + char(10)
    css = css + "  width: max-content;" + char(10)
    css = css + "}" + char(10)
    css = css + ".tohtml-embedded-table .texout-table-wrap {" + char(10)
    css = css + "  overflow: visible !important;" + char(10)
    css = css + "  width: max-content;" + char(10)
    css = css + "  max-width: none;" + char(10)
    css = css + "}" + char(10)
    css = css + "</style>"

    lines = cat(htmlfile)
    if (rows(lines) == 0) return
    // Stata markdown has no </head>; a leading <style> would lose to
    // the later ./css/tohtml.css link. Append so tabwidth/tabheight win.
    csslines = split_newlines(css)
    lines = lines \ csslines
    mm_outsheet(htmlfile, lines, "replace")
}

void function tohtml_fix_default_refs(string scalar reportfile, string scalar basedir)
{
    // Default (non-embed, non-zip) insertion: keep absolute or relative src
    // as written when it works from the report HTML folder. If a relative
    // iframe/img path does not resolve there, rewrite it to the file's
    // absolute path. Attach collect-export CSS on table HTML files.
    if (!fileexists(reportfile)) {
        cand = pathjoin(pwd(), reportfile)
        if (fileexists(cand)) reportfile = cand
    }
    if (!fileexists(reportfile)) return
    if (!pathisabs(reportfile)) reportfile = pathresolve(pwd(), reportfile)
    if (basedir == "") basedir = pathgetparent(reportfile)
    if (basedir == "") basedir = pwd()
    if (!pathisabs(basedir)) basedir = pathresolve(pwd(), basedir)
    lines = cat(reportfile)
    if (rows(lines) == 0) return
    srcs = extract_embed_srcs(lines) \ extract_md_images(lines)
    srcs = select(srcs, srcs :!= "")
    if (rows(srcs) == 0) {
        return
    }
    srcs = uniqrows(srcs)
    if (rows(srcs) > 1) srcs = srcs[order(-strlen(srcs), 1)]
    changed = 0

    for (i = 1; i <= rows(srcs); i++) {
        src = strtrim(srcs[i])
        if (src == "" | path_is_remote(src)) continue
        ext = path_suffix_lower(src)
        resolved = resolve_local_file(src, basedir)
        if (ext == ".html" | ext == ".htm") {
            if (resolved != "") {
                fix_table_override_css(resolved)
                ensure_table_css_link(resolved)
            }
        }
        news = src_for_default(src, basedir)
        if (news == "" | news == src) continue
        lines = replace_path_refs(lines, src, news)
        changed = 1
    }
    if (changed) mm_outsheet(reportfile, lines, "replace")
}

void function tohtml_finish_default_refs(string scalar htmlfile)
{
    tohtml_fix_default_refs(htmlfile, pathgetparent(htmlfile))
}


real colvector is_md_fence_line(string colvector lines)
{
    // ``` or ```lang  (info string after the backticks)
    t = strtrim(lines)
    return(usubstr(t, 1, 3) :== "```")
}

string colvector tag_stata_opening_fences(string colvector lines)
{
    // Odd-numbered fences are openings. Bare ``` become ```stata for Typora/GitHub highlighting.
    // Leave closings and fences that already have an info string (```text, ```stata, ...).
    n = rows(lines)
    if (n == 0) return(lines)
    is_bt = is_md_fence_line(lines)
    k = 0
    for (i = 1; i <= n; i++) {
        if (!is_bt[i]) continue
        k++
        if (mod(k, 2) == 0) continue
        t = strtrim(lines[i])
        if (t == "```") lines[i] = "```stata"
    }
    return(lines)
}

real colvector char_lengths_including_backticks(string colvector lines)
{
    n = rows(lines)
    if (n == 0) return(J(0, 1, .))
    is_bt_start = is_md_fence_line(lines)
    idx_bt = selectindex(is_bt_start)
    n_bt = length(idx_bt)
    lens = strlen(lines)
    result = J(n, 1, .)
    if (n_bt <= 1) return(J(n, 1, .))
    npair = floor(n_bt / 2)
    i1 = rangen(1, npair*2-1, npair)
    i2 = rangen(2, npair*2, npair)
    // inpair = J(n,1,0)
    for (i = 1; i <= npair; i++) { 
// 		idx_bt[i2[i]],idx_bt[i1[i]]
         flag =selectindex(((1::n):<= idx_bt[i2[i]]) - ((1::n):< idx_bt[i1[i]]))
        //  inpair[flag] = J(length(flag),1,1)
         result[flag] = J(length(flag),1,sum(lens[flag]))
    }

    
    return(result)
}



real scalar is_html_embed_open(string scalar line)
{
    t = ustrltrim(line)
    if (usubstr(t, 1, 7) == "<iframe") return(1)
    if (usubstr(t, 1, 4) == "<img") return(1)
    return(0)
}

real scalar html_embed_tag_complete(string scalar line)
{
    t = ustrltrim(line)
    if (usubstr(t, 1, 7) == "<iframe") {
        return(ustrpos(ustrlower(t), "</iframe>") > 0)
    }
    if (usubstr(t, 1, 4) == "<img") {
        return(ustrregexm(t, ">\s*$"))
    }
    return(1)
}

real scalar is_stata_wrap_cont(string scalar line)
{
    return(usubstr(ustrltrim(line), 1, 1) == ">")
}

real scalar is_stata_cmd_echo(string scalar line)
{
    t = ustrltrim(line)
    return(usubstr(t, 1, 1) == ".")
}

string scalar take_stata_wrap_payload(string scalar line)
{
    t = ustrltrim(line)
    if (usubstr(t, 1, 1) != ">") return(t)
    return(strtrim(usubstr(t, 2, .)))
}

real scalar line_ends_with_triple_slash(string scalar line)
{
    // User-written "///" continuation: keep the line break, do not splice.
    return(ustrregexm(ustrrtrim(line), "///$"))
}

string colvector join_stata_cmd_continuations(string colvector lines)
{
    // Join Stata linesize wraps ("> ...") onto the preceding ". command".
    // Do not join after a user "///" break: only the ">" prompt is stripped later.
    n = rows(lines)
    if (n == 0) return(lines)
    out = J(0, 1, "")
    i = 1
    while (i <= n) {
        line = lines[i]
        if (is_stata_cmd_echo(line) | is_stata_wrap_cont(line)) {
            while (i < n) {
                if (!is_stata_wrap_cont(lines[i + 1])) break
                if (line_ends_with_triple_slash(line)) break
                line = join_stata_wrap(line, lines[i + 1])
                i++
            }
        }
        out = out \ line
        i++
    }
    return(out)
}

string colvector strip_stata_cmd_prompt(string colvector lines)
{
    // Remove the Stata echo prompt (". " / "> ") from command lines.
    // Require a following space/tab/EOL so a narrative ".5" is left alone.
    n = rows(lines)
    if (n == 0) return(lines)
    out = J(n, 1, "")
    for (i = 1; i <= n; i++) {
        s = lines[i]
        t = ustrltrim(s)
        c = usubstr(t, 1, 1)
        if (c == ".") {
            rest = usubstr(t, 2, .)
            if (rest == "" | usubstr(rest, 1, 1) == " " | usubstr(rest, 1, 1) == char(9)) {
                out[i] = ustrltrim(rest)
                continue
            }
        }
        else if (c == ">") {
            // Drop only the wrap prompt; keep spaces after ">" (/// indent).
            out[i] = usubstr(t, 2, .)
            continue
        }
        out[i] = s
    }
    return(out)
}

string scalar join_stata_wrap(string scalar line, string scalar nxt)
{
    payload = take_stata_wrap_payload(nxt)
    // Stata drops the space between HTML attributes when it wraps at that
    // space. Restore it only if the previous line already closed a quoted
    // value. If the wrap split a name (data-tohtml-ti / tle="..."), do not
    // insert a space.
    if (payload != "" & ustrregexm(ustrlower(payload), `"^[a-z][a-z0-9_-]* *="')) {
        last = usubstr(ustrrtrim(line), ustrlen(ustrrtrim(line)), 1)
        if (last == char(34) | last == char(39) | last == ">") {
            return(line + " " + payload)
        }
    }
    return(line + payload)
}

string colvector merge_html_vectorized(string colvector f)
{
    // Stata splits lines longer than linesize; the next line starts with "> ".
    // Join those output wraps (log paths, <iframe>/<img>, long results).
    // Do not join ". command" continuations: /** ... **/ narrative is echoed
    // that way and must stay on separate lines until clean_textcell_content.
    n = rows(f)
    if (n == 0) return(f)
    out = J(0, 1, "")
    i = 1
    while (i <= n) {
        line = f[i]
        if (is_html_embed_open(line)) {
            while (i < n & !html_embed_tag_complete(line)) {
                if (!is_stata_wrap_cont(f[i + 1])) break
                line = join_stata_wrap(line, f[i + 1])
                i++
            }
        }
        else if (ustrtrim(line) != "" & !is_stata_cmd_echo(line) &
            !is_stata_wrap_cont(line) &
            usubstr(ustrltrim(line), 1, 3) != "```") {
            while (i < n) {
                if (!is_stata_wrap_cont(f[i + 1])) break
                line = join_stata_wrap(line, f[i + 1])
                i++
            }
        }
        out = out \ line
        i++
    }
    return(out)
}

string colvector remove_prefix_and_trim(string colvector lines,string rowvector prefixes)   
{
    // 定义要移除的前缀列表（按优先级或任意顺序）
    //prefixes = ("< >", "{txt}", "{com}", "{res}")  // 注意：">" 单独处理更安全

    // 先单独处理 ">"（因为它不是花括号结构，且可能与其他混淆）
    // 只有当行首是 ">" 时才去掉（注意：可能有空格？根据需求决定是否先 trim）
    // 这里假设前缀是严格在最开头（无前导空格），若需忽略前导空格，请先 strtrim
    
    n = rows(lines)
    result = lines

    // 1. 处理行首的 ">"
    // idx_gt = selectindex(substr(result, 1, 1) :== ">")
    // if (rows(idx_gt) > 0) {
    //     result[idx_gt] = ustrtrim(substr(result[idx_gt], 2, .))
    // }

    // 2. 处理 {txt}, {com}, {res}
    for (i = 2; i <= cols(prefixes); i++) {  // 跳过第1个（">" 已处理）
        pre = prefixes[i]
        len_pre = strlen(pre)
        // 找出以 pre 开头的行
        matches = (substr(result, 1, len_pre) :== pre)
        idx = selectindex(matches)
        if (length(idx) > 0) {
            result[idx] = ustrtrim(substr(result[idx], len_pre + 1, .))
        }
    }

    return(result)
}

real colvector cumcount_backtick3(string colvector lines)
{
    n = rows(lines)
    if (n == 0) return(J(0, 1, .))
    
    is_bt = is_md_fence_line(lines) 
    
    // 累积和：到当前行为止（含）的 ``` 行数
    cumsum = runningsum(is_bt)
    
    // 当前行"之前"的数量 = 上一行的 cumsum
    count_before = J(n, 1, 0)
    if (n > 1) count_before[|2 \ n|] = cumsum[|1 \ n-1|]
    
    return(count_before)
}

real scalar line_is_md_fence(string scalar s)
{
    return(usubstr(strtrim(s), 1, 3) == "```")
}

real scalar next_nonempty_is_md_fence(string colvector fcon, real scalar i)
{
    n = rows(fcon)
    j = i + 1
    while (j <= n) {
        if (ustrtrim(fcon[j]) != "") break
        j++
    }
    if (j > n) return(0)
    return(line_is_md_fence(fcon[j]))
}

string colvector ensure_stata_fence_open(string colvector lines)
{
    // After ```text ... ``` (log header), open a Stata fence so the rest of
    // the log is inside a code block. If the user already wrote ishere ```
    // / **```, do not add a second opener.
    n = rows(lines)
    if (n == 0) return(lines)

    k = 1
    while (k <= n) {
        if (ustrtrim(lines[k]) != "") break
        k++
    }
    if (k > n) return(lines)

    insert_at = 0
    if (strtrim(lines[k]) == "```text") {
        j = k + 1
        while (j <= n) {
            if (line_is_md_fence(lines[j])) {
                insert_at = j
                break
            }
            j++
        }
        if (insert_at == 0) return(lines)
    }
    else {
        if (line_is_md_fence(lines[k])) return(lines)
        insert_at = k - 1
    }

    m = insert_at + 1
    while (m <= n) {
        if (ustrtrim(lines[m]) != "") break
        m++
    }
    if (m > n) return(lines)
    if (line_is_md_fence(lines[m])) return(lines)

    if (insert_at <= 0) return("```" \ lines)
    if (insert_at >= n) return(lines \ "```")
    return(lines[|1 \ insert_at|] \ "```" \ lines[|insert_at + 1 \ n|])
}

string colvector insert_backtick_before_hash(string colvector fcon)
{
    n = rows(fcon)
    if (n == 0) return(J(0, 1, ""))
    lens = strlen("_ishere_")

    out = J(0, 1, "")
    inside = 0

    for (i = 1; i <= n; i++) {
        line = fcon[i]
        t = ustrltrim(line)

        if (line_is_md_fence(line)) {
            out = out \ line
            inside = !inside
            continue
        }

        is_heading = (usubstr(t, 1, 1) == "#")
        is_iframe = (usubstr(t, 1, 7) == "<iframe")
        is_img = (usubstr(t, 1, 4) == "<img")
        is_tc_start = 0
        is_tc_end = 0
        if (usubstr(t, 1, lens) == "_ishere_") {
            rem = ustrltrim(usubstr(t, lens + 1, .))
            if (usubstr(rem, 1, 2) == "/*") is_tc_start = 1
            if (usubstr(rem, 1, 2) == "*/") is_tc_end = 1
        }

        is_break = is_heading | is_iframe | is_img | is_tc_start
        if (is_break & inside) {
            out = out \ "```"
            inside = 0
        }

        if (is_tc_start | is_tc_end) {
            out = out \ ""
        }
        else {
            out = out \ line
        }

        is_reopen = is_heading | is_iframe | is_img | is_tc_end
        if (is_reopen & !inside) {
            if (!next_nonempty_is_md_fence(fcon, i)) {
                out = out \ "```"
                inside = 1
            }
        }
    }

    if (inside) out = out \ "```"
    return(out)
}


string colvector add_two_blank_lines(string colvector lines)
{
    n = rows(lines)
    if (n == 0) return(lines)

    out = J(0, 1, "")
    code_block_count = 0
    
    for (i = 1; i <= n; i++) {
        line = lines[i]
        
        // 检查当前行是否是代码块标记
        if (ustrpos(ustrtrim(line), "```") == 1) {
            code_block_count = code_block_count + 1
            
            // 如果是奇数个代码块，在它前面加两个空行
            if (mod(code_block_count, 2) == 1) {
                out = out \ "" \ ""
                // 添加当前代码块标记行
                out = out \ line
            }
    
            // 如果是偶数个代码块，在它后面加两个空行
            if (mod(code_block_count, 2) == 0) {
                out = out \ line \ "" \ ""
            }
        }
        else {
            // 非代码块标记行直接添加
            out = out \ line
        }
    }
    
    return(out)
}

void function merge_cmdlog_blocks(string scalar clean_md, string scalar cmdlog_md, string scalar out_md, real scalar replace)
{
 
    clean = cat(clean_md)
    clean = ishererep(clean)
    clean = merge_html_vectorized(clean)
    clean = subisheredintxt(clean)
    clean_trim = ustrltrim(clean)
    is_embed = (substr(clean_trim, 1, strlen("<iframe")) :== "<iframe") :| ///
        (substr(clean_trim, 1, strlen("<img")) :== "<img")
    embeds = select(clean, is_embed)
    n_embed = rows(embeds)

    // 2. 读取 cmdlog
    cmd = cat(cmdlog_md)
    // 删除 log using 开始的行
    flag = ustrpos(cmd, "log") :* ustrpos(cmd, "using")
    flag = flag :* ustrpos(cmd, "text") 
    flag = flag :* ustrpos(cmd, "replace") 
    //flag
    if (sum(flag) > 0) {
        flag1 = selectindex(flag)
        cmd = select(cmd, (1::length(cmd)) :!=flag1[1])
    }
    flag = ustrpos(cmd, "log") :* ustrpos(cmd, "close")
    if (sum(flag) > 0) {
        flag1 = selectindex(flag)
        if (length(flag1) ==1 ) {
            cmd = select(cmd, (1::length(cmd)) :!=flag1[1])
         }
         else{
            //cmd = select(cmd, (1::length(cmd)) :!=flag1[length(flag1)])
            cmd[flag1[length(flag1)]] = "ishere ```"
            cmd = select(cmd, (1::length(cmd)) :!=flag1[1])
         }
    }
        

    cmd = ishererep2(cmd)
    n_cmd = rows(cmd)

    // Handle initial comment block 
    first_non_empty = 0
    for (k = 1; k <= n_cmd; k++) {
        if (ustrtrim(cmd[k]) != "") {
             first_non_empty = k
             break
        }
    }

    if (first_non_empty > 0) {
         line_first = ustrtrim(cmd[first_non_empty])
         is_comment = 0
         end_comment = 0
         
         if (usubstr(line_first, 1, 2) == "/*") {
             is_comment = 1
             for (k = first_non_empty; k <= n_cmd; k++) {
                 if (ustrpos(cmd[k], "*/") > 0) {
                     end_comment = k
                     break
                 }
             }
         }
         else if (usubstr(line_first, 1, 1) == "*") {
             is_comment = 1
             end_comment = first_non_empty
             for (k = first_non_empty + 1; k <= n_cmd; k++) {
                 if (usubstr(ustrtrim(cmd[k]), 1, 1) == "*") {
                     end_comment = k
                 } 
                 else {
                     break
                 }
             }
         }
         
         if (is_comment & end_comment > 0) {
             pre = J(0, 1, "")
             if (first_non_empty > 1) pre = cmd[|1 \ first_non_empty-1|]
             
             mid = cmd[|first_non_empty \ end_comment|]
             
             post = J(0, 1, "")
             if (end_comment < n_cmd) post = cmd[|end_comment+1 \ n_cmd|]
             
             cmd = pre \ "```" \ mid \ "```" \ post
             n_cmd = rows(cmd)
         }
    }

    // 3. 检查 /** **/  闭合（拒绝旧版 ishere /* */）
      cmd = check_isheretxt_closed(cmd)

    // 4. 统计 ishere fig/tab 数量
    count_markers = 0
    for (i = 1; i <= n_cmd; i++) {
        line = ustrltrim(cmd[i])
        if (ustrpos(line, "ishere fig") == 1 | ustrpos(line, "ishere tab") == 1) {
            count_markers = count_markers + 1
        }
    }
    
    if (n_embed > 0 & count_markers != n_embed) {
        errprintf("ishere fig/tab count (%g) does not match embed count (%g)\n", count_markers, n_embed)
        _error(498)
    }

    // 5. 合并输出
    result = J(0, 1, "")
    embed_i = 1
    i = 1

    while (i <= n_cmd) {
        line = cmd[i]
        line_trim = ustrtrim(line)

        // (1) 处理 ishere fig/tab (含 smart /// 判断)
        is_target = 0
        if (ustrpos(line_trim, "ishere") == 1) {
             suffix = ustrtrim(substr(line_trim, 7, .)) 
             suffix = ustrlower(suffix)
             if (substr(suffix, 1, 3) == "fig" | substr(suffix, 1, 3) == "tab") {
                 is_target = 1
             }
        }
        
        if (is_target) {
             // 替换为图表
             if (embed_i <= n_embed) {
                result = result \ embeds[embed_i]
                embed_i = embed_i + 1
             }
             
             // 智能跳过 /// 分行
             while (i <= n_cmd) {
                 curr = ustrtrim(cmd[i]) 
                 len = strlen(curr)
                 if (len >= 3) {
                     if (substr(curr, len-2, 3) == "///") {
                         i = i + 1 // consume current line and check next
                         continue
                     }
                 }
                 break 
             }
             i = i + 1
             continue
        }

        // (2) ishere # -> #
        if (ustrpos(line_trim, "ishere ") == 1) {
            islen = strlen("ishere")
             rem = ustrltrim(substr(line_trim, islen+1, .))
             if (substr(rem, 1, 1) == "#") {
                 result = result \ rem
                 i = i + 1
                 continue
             }
        }


        // (4) ishere [0|1] -> ```
        if (ustrpos(line_trim, "ishere") == 1) {
            islen = strlen("ishere")
            rem = ustrtrim(substr(line_trim, islen+1, .))
            if (rem == "" | rem == "```") {
                result = result \ "```"
                i = i + 1
                continue
            }
        }
        
        // 保留其他行
        result = result \ line
        i = i + 1
    }

    // 5b. 替换文本块中的 ishere display 占位符
    //result = subisheredintxt(result)

    // 6. 【核心】动态修复：直到所有 # 行都在代码块外
    result = ensure_stata_fence_open(result)
    result = insert_backtick_before_hash(result)
    
    // 7. （可选）过滤短代码块
    fconlen = char_lengths_including_backticks(result)
    result = select(result, !(fconlen :< 2*(strlen("```")+2)))   
    
    fcon = result
    // 将md源代码插入到<iframe ></iframe>位置
    result = splice_md_iframes(fcon)
    

    // 8b. 在代码块之间插入两个空行
    //result = add_two_blank_lines(result)

    // 9. 输出
    if (replace == 0) {
        mm_outsheet(out_md, result)
    }
    if (replace == 1) {
        mm_outsheet(out_md, result, "replace")
    }

}

void function inject_mathjax(string scalar htmlfile)
{
    lines = cat(htmlfile)
    if (rows(lines) == 0) return

    // avoid duplicate injection
    if (sum(ustrpos(lines, "MathJax-script") :> 0) > 0) return

    script =      "<script>" 
    script = script + "MathJax = {"
    script = script + "  tex: {"
    script = script + "    inlineMath: [['$', '$'], ['\\(', '\\)']],"
    script = script + "    displayMath: [['$$', '$$'], ['\\[', '\\]']]"
    script = script + "  }"
    script = script + "};"
    script = script + "</script>"
    script = script + "<script id=" + char(34) + "MathJax-script" + char(34) + " async src=" + char(34) + "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js" + char(34) + "></script>"
    
    idx = selectindex(ustrpos(lines, "</head>") :> 0)
    if (length(idx) > 0) {
        i = idx[1]
        if (i > 1) {
            lines = lines[|1 \ i-1|] \ script \ lines[|i \ rows(lines)|]
        }
        else {
            lines = script \ lines
        }
    }
    else {
        lines = script \ lines
    }

    mm_outsheet(htmlfile, lines, "replace")
}

void function inject_highlightjs(string scalar htmlfile)
{
    // Token highlighting for ```stata. Core CDN bundle omits Stata; load it extra.
    // Run after DOMContentLoaded so <pre><code> exists (scripts sit in <head>).
    lines = cat(htmlfile)
    if (rows(lines) == 0) return
    if (sum(ustrpos(lines, "highlight.min.js") :> 0) > 0) return

    q = char(34)
    cdn = "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.11.1/build/"
    script = "<link rel=" + q + "stylesheet" + q + " href=" + q + cdn + "styles/github.min.css" + q + ">"
    script = script + "<script src="http://fmwww.bc.edu/repec/bocode/t/+&#32;q&#32;+&#32;cdn&#32;+"highlight.min.js" + q + "></script>"
    script = script + "<script src=" + q + cdn + "languages/stata.min.js" + q + "></script>"
    script = script + "<script>document.addEventListener(" + q + "DOMContentLoaded" + q
    script = script + ",function(){hljs.highlightAll();});</script>"

    idx = selectindex(ustrpos(lines, "</head>") :> 0)
    if (length(idx) > 0) {
        i = idx[1]
        if (i > 1) {
            lines = lines[|1 \ i-1|] \ script \ lines[|i \ rows(lines)|]
        }
        else {
            lines = script \ lines
        }
    }
    else {
        lines = script \ lines
    }

    mm_outsheet(htmlfile, lines, "replace")
}

real scalar content_has_math(string scalar filepath)
{
    // Detect TeX delimiters used by inject_mathjax configuration.
    // Do not use "$" in a regex: in .ado files it is a Stata global, and in
    // ICU regex it is an end-of-string anchor.
    lines = cat(filepath)
    n = rows(lines)
    for (i = 1; i <= n; i++) {
        s = lines[i]
        if (ustrpos(s, "$$") > 0) return(1)
        if (ustrpos(s, "\\(") > 0) return(1)
        if (ustrpos(s, "\\[") > 0) return(1)
        if (line_has_inline_math(s)) return(1)
    }
    return(0)
}

real scalar line_has_inline_math(string scalar s)
{
    n = ustrlen(s)
    dollar = char(36)
    for (i = 1; i <= n; i++) {
        if (usubstr(s, i, 1) != dollar) continue
        if (i < n & usubstr(s, i + 1, 1) == dollar) {
            i = i + 1
            continue
        }
        if (i > 1 & usubstr(s, i - 1, 1) == char(92)) continue
        for (j = i + 1; j <= n; j++) {
            if (usubstr(s, j, 1) != dollar) continue
            if (j < n & usubstr(s, j + 1, 1) == dollar) {
                j = j + 1
                continue
            }
            if (usubstr(s, j - 1, 1) == char(92)) continue
            if (j > i + 1) return(1)
            break
        }
    }
    return(0)
}



string colvector function line_cmd_token(string scalar raw)
{
    // Strip SMCL / prompt; return space-free command token for matching
    s = ustrltrim(raw)
    changed = 1
    while (changed) {
        changed = 0
        if (ustrpos(s, "{com}") == 1) {
            s = ustrltrim(usubstr(s, 6, .))
            changed = 1
        }
        else if (ustrpos(s, "{res}") == 1) {
            s = ustrltrim(usubstr(s, 6, .))
            changed = 1
        }
        else if (ustrpos(s, "{txt}") == 1) {
            s = ustrltrim(usubstr(s, 6, .))
            changed = 1
        }
    }
    if (usubstr(s, 1, 1) == "." | usubstr(s, 1, 1) == ">") {
        s = ustrltrim(usubstr(s, 2, .))
    }
    return(usubinstr(s, " ", "", .))
}

void function reject_deprecated_isheretxt(string colvector lines)
{
    for (i = 1; i <= rows(lines); i++) {
        tok = line_cmd_token(lines[i])
        if (tok == "ishere/*" | tok == "ishere*/" |
            ustrpos(tok, "ishere/*") == 1 | ustrpos(tok, "ishere*/") == 1) {
            errprintf("Error: ishere /* and ishere */ are no longer supported; use /** and **/\n")
            _error(199)
        }
    }
}

string colvector function normalize_mdblock_markers(string colvector content)
{
    // Only /** ... **/ mark markdown narrative blocks (internal: _ishere_/* ... _ishere_*/)
    lines = content
    for (i = 1; i <= rows(lines); i++) {
        tok = line_cmd_token(lines[i])
        if (tok == "/**") {
            lines[i] = "_ishere_/*"
        }
        else if (tok == "**/") {
            lines[i] = "_ishere_*/"
        }
    }
    return(lines)
}

string colvector clean_textcell_content(string colvector lines)
{
    // Markdown narrative blocks: /** ... **/ only
    reject_deprecated_isheretxt(lines)
    lines = normalize_mdblock_markers(lines)

    trim = ustrtrim(lines)
    r12 = (trim :== "_ishere_/*")
    r22 = (trim :== "_ishere_*/")

    if (sum(r12) != sum(r22)) {
        errprintf("Error: unmatched /** and **/\n")
        _error(199)
    }
    if (sum(r12) == 0) {
        return(lines)
    }

    idx12 = selectindex(r12)
    idx22 = selectindex(r22)

    if (length(idx12) != length(idx22)) {
        errprintf("Error: unmatched /** and **/\n")
        _error(199)
    }

    for (i = 1; i <= length(idx12); i++) {
        if (idx12[i] >= idx22[i]) {
            errprintf("Error: unmatched /** and **/\n")
            _error(199)
        }
        if ((i + 1) <= length(idx12)) {
            if (idx12[i + 1] < idx22[i]) {
                errprintf("Error: overlapping /** and **/\n")
                _error(199)
            }
        }
        // Strip leading "." / ">" from log-echoed lines inside the block
        for (j = idx12[i] + 1; j <= idx22[i] - 1; j++) {
            s = ustrltrim(lines[j])
            if (usubstr(s, 1, 1) == "." | usubstr(s, 1, 1) == ">") {
                lines[j] = ustrltrim(usubstr(s, 2, .))
            }
        }
        lines[idx12[i]] = "_ishere_/*"
        lines[idx22[i]] = "_ishere_*/"
    }
    return(lines)
}




// a new function moving lines starting with <img or <iframe to the next line if the next line starts with . ishere tab or fig
real colvector get_textcell_index(string colvector lines)
{
   text_start = selectindex(lines:=="_ishere_/*")
   text_end = selectindex(lines:=="_ishere_*/")
   text_idx = J(rows(lines),1,0)
   for (i=1;i<=length(text_start);i++){ 
       text_idx[text_start[i]::text_end[i]] = J(length(text_start[i]::text_end[i]),1,i)
   }
    return(text_idx)
}



string colvector function get_dot_header(string colvector lines)
{
    lines2 = strltrim(lines)
    flag = (ustrpos(lines2, ".") :== 1)
    lines3 = strltrim(substr(lines2, 2, .))
    flag2 = (ustrpos(lines3, "ishere") :== 1)
    lines3 = strltrim(substr(lines3,strlen("ishere")+1,.))
    flag3 = (ustrpos(lines3, "#") :== 1)
    flag = flag :& flag2 :& flag3
    if (sum(flag) > 0) {
        idx = selectindex(flag)
        lines[idx] = lines3[idx]
    }
    return(lines)
}


string colvector function get_header(string colvector lines)
{
    lines2 = strltrim(lines)
    flag = (ustrpos(lines2, "ishere") :== 1)
    lines2 = strltrim(substr(lines2,strlen("ishere")+1,.))
    flag2 = (ustrpos(lines2, "#") :== 1)
    flag = flag :& flag2 
    if (sum(flag) > 0) {
        idx = selectindex(flag)
        lines[idx] = lines2[idx]
    }
    return(lines)
}


string colvector function check_isheretxt_closed(string colvector lines)
{
    // Do-file path: same /** ... **/ rules as clean_textcell_content
    reject_deprecated_isheretxt(lines)
    lines = normalize_mdblock_markers(lines)

    trim = ustrtrim(lines)
    flag1 = (trim :== "_ishere_/*")
    flag2 = (trim :== "_ishere_*/")
    if (sum(flag1) != sum(flag2)) {
        errprintf("Error: unmatched /** and **/\n")
        _error(199)
    }
    if (sum(flag1) == 0) {
        return(lines)
    }
    idx1 = selectindex(flag1)
    idx2 = selectindex(flag2)

    for (i = 1; i <= length(idx1); i++) {
        if (idx2[i] <= idx1[i]) {
            errprintf("Error: unmatched /** and **/\n")
            _error(199)
        }
        if ((i + 1) <= length(idx1)) {
            if (idx1[i + 1] < idx2[i]) {
                errprintf("Error: overlapping /** and **/\n")
                _error(199)
            }
        }
        lines[idx1[i]] = "_ishere_/*"
        lines[idx2[i]] = "_ishere_*/"
    }
    return(lines)
}

string scalar normalize_path(string scalar pin)
{
    // Slash-fold for HTML/MD and prefix compares. Joining uses pathjoin/pathresolve.
    p = pin
    p = subinstr(p, "\\", "/", .)
    p = subinstr(p, "\", "/", .)
    while (strlen(p) > 1 & substr(p, strlen(p), 1) == "/") {
        p = substr(p, 1, strlen(p) - 1)
    }
    return(p)
}

string scalar abs_path_key(string scalar pin)
{
    string scalar drive, s, piece, out, p
    real scalar n, j, i
    string colvector tok

    p = strtrim(pin)
    if (p == "" | p == ".") p = pwd()
    else if (!pathisabs(p)) p = pathresolve(pwd(), p)
    p = normalize_path(p)

    drive = ""
    if (strlen(p) >= 2 & substr(p, 2, 1) == ":") {
        drive = usubstr(p, 1, 2)
        p = usubstr(p, 3, .)
    }
    if (usubstr(p, 1, 1) == "/") p = usubstr(p, 2, .)

    tok = J(0, 1, "")
    s = p
    while (s != "") {
        j = ustrpos(s, "/")
        if (j == 0) {
            piece = s
            s = ""
        }
        else {
            piece = usubstr(s, 1, j - 1)
            s = usubstr(s, j + 1, .)
        }
        if (piece == "" | piece == ".") continue
        if (piece == "..") {
            n = rows(tok)
            if (n > 0) tok = (n == 1 ? J(0, 1, "") : tok[|1 \ n-1|])
            continue
        }
        tok = tok \ piece
    }

    out = drive + "/"
    for (i = 1; i <= rows(tok); i++) {
        if (i > 1) out = out + "/"
        out = out + tok[i]
    }
    if (c("os") == "Windows") out = ustrlower(out)
    return(out)
}

real scalar paths_are_same(string scalar a, string scalar b)
{
    if (strtrim(a) == "" | strtrim(b) == "") return(0)
    return(abs_path_key(a) == abs_path_key(b))
}

real rowvector stata_log_header_range(string colvector lines)
{
    real scalar n, i, start
    string scalar tr

    n = rows(lines)
    if (n == 0) return((0, 0))
    i = 1
    while (i <= n & ustrtrim(lines[i]) == "") i++
    if (i > n) return((0, 0))
    start = i
    tr = ustrtrim(lines[i])
    if (!ustrregexm(tr, "^[-]{10,}$")) return((0, 0))
    i++

    // name:
    while (i <= n & ustrtrim(lines[i]) == "") i++
    if (i > n) return((0, 0))
    tr = ustrlower(ustrtrim(lines[i]))
    if (!ustrregexm(tr, "^name:")) return((0, 0))
    i++
    while (i <= n & usubstr(ustrltrim(lines[i]), 1, 1) == ">") i++

    // log:  (not "log type:")
    while (i <= n & ustrtrim(lines[i]) == "") i++
    if (i > n) return((0, 0))
    tr = ustrlower(ustrtrim(lines[i]))
    if (!ustrregexm(tr, "^log:") | ustrregexm(tr, "^log type:")) return((0, 0))
    i++
    while (i <= n & usubstr(ustrltrim(lines[i]), 1, 1) == ">") i++

    // log type:
    while (i <= n & ustrtrim(lines[i]) == "") i++
    if (i > n) return((0, 0))
    tr = ustrlower(ustrtrim(lines[i]))
    if (!ustrregexm(tr, "^log type:")) return((0, 0))
    i++
    while (i <= n & usubstr(ustrltrim(lines[i]), 1, 1) == ">") i++

    // opened on:
    while (i <= n & ustrtrim(lines[i]) == "") i++
    if (i > n) return((0, 0))
    tr = ustrlower(ustrtrim(lines[i]))
    if (!ustrregexm(tr, "^opened on:")) return((0, 0))
    i++
    while (i <= n & usubstr(ustrltrim(lines[i]), 1, 1) == ">") i++

    return((start, i - 1))
}

string colvector fence_stata_log_header(string colvector lines)
{
    real rowvector r
    real scalar a, b, n
    string colvector left, mid, right

    r = stata_log_header_range(lines)
    if (r[1] == 0) return(lines)
    a = r[1]
    b = r[2]
    n = rows(lines)
    left  = (a == 1 ? J(0, 1, "") : lines[|1 \ a-1|])
    mid   = lines[|a \ b|]
    right = (b == n ? J(0, 1, "") : lines[|b+1 \ n|])
    return(left \ "```text" \ mid \ "```" \ right)
}

string colvector drop_stata_log_header(string colvector lines)
{
    real rowvector r
    real scalar a, b, n

    r = stata_log_header_range(lines)
    if (r[1] == 0) return(lines)
    a = r[1]
    b = r[2]
    n = rows(lines)
    if (a == 1 & b == n) return(J(0, 1, ""))
    if (a == 1) return(lines[|b+1 \ n|])
    if (b == n) return(lines[|1 \ a-1|])
    return(lines[|1 \ a-1|] \ lines[|b+1 \ n|])
}

string scalar strip_smcl_prefixes(string scalar raw)
{
    s = ustrltrim(raw)
    changed = 1
    while (changed) {
        changed = 0
        if (ustrpos(s, "{com}") == 1) {
            s = ustrltrim(usubstr(s, 6, .))
            changed = 1
        }
        else if (ustrpos(s, "{res}") == 1) {
            s = ustrltrim(usubstr(s, 6, .))
            changed = 1
        }
        else if (ustrpos(s, "{txt}") == 1) {
            s = ustrltrim(usubstr(s, 6, .))
            changed = 1
        }
    }
    return(s)
}

string scalar norm_disp_args(string scalar s)
{
    return(ustrtrim(ustrregexra(s, "\s+", " ")))
}

string scalar display_value_after(string colvector lines, real scalar i)
{
    n = rows(lines)
    for (j = i + 1; j <= n; j++) {
        nxt = strtrim(strip_smcl_prefixes(lines[j]))
        if (nxt == "") continue
        if (nxt == "_ishere_/*" | nxt == "_ishere_*/" |
            ustrpos(nxt, ".") == 1 | ustrpos(nxt, ">") == 1 |
            ustrpos(nxt, "/**") == 1) return("")
        return(nxt)
    }
    return("")
}

string scalar replace_ishere_display_tag(string scalar line, string scalar want, string scalar val)
{
    s = line
    out = ""
    for (t = 1; t <= 30; t++) {
        p = ustrpos(ustrlower(s), "{ishere")
        if (p == 0) {
            out = out + s
            break
        }
        rest = usubstr(s, p, .)
        q = ustrpos(rest, "}")
        if (q == 0) {
            out = out + s
            break
        }
        tag = usubstr(rest, 1, q)
        out = out + usubstr(s, 1, p - 1)
        inner = ustrtrim(usubstr(tag, 2, ustrlen(tag) - 2))
        matched = 0
        if (ustrregexm(inner, "^ishere\s+display\s+(.*)$")) {
            args = ustrtrim(ustrregexs(1))
            if (norm_disp_args(args) == want) {
                out = out + " " + val + " "
                matched = 1
            }
        }
        if (!matched) out = out + tag
        s = usubstr(rest, q + 1, .)
    }
    return(out)
}

string colvector function subisheredintxt(string colvector lines)
{
    n = rows(lines)
    if (n == 0) return(lines)

    lines2 = strltrim(lines)
    textflag = get_textcell_index(lines2)

    // Step 1: 找到所有 . ishere display 命令行及其输出值
    flag = (ustrpos(lines2, ".") :== 1)
    lines3 = strltrim(substr(lines2, 2, .))
    flag = flag :& (ustrpos(lines3, "ishere") :== 1)
    lines4 = strtrim(substr(lines3, strlen("ishere")+1, .))
    flag = flag :& (ustrpos(lines4, "display") :== 1)

    // SMCL logs: {com}. ishere display ...
    if (sum(flag) == 0) {
        stripped = J(n, 1, "")
        for (i = 1; i <= n; i++) stripped[i] = strip_smcl_prefixes(lines2[i])
        flag = (ustrpos(stripped, ".") :== 1)
        lines3 = strltrim(substr(stripped, 2, .))
        flag = flag :& (ustrpos(lines3, "ishere") :== 1)
        lines4 = strtrim(substr(lines3, strlen("ishere")+1, .))
        flag = flag :& (ustrpos(lines4, "display") :== 1)
        lines2 = stripped
    }

    if (sum(flag) == 0 | sum(textflag) == 0) {
        return(lines)
    }

    // Step 2: 提取 display 参数（压缩空白后按字面比较，避免 e(r2) 被当成正则）
    lines5 = substr(lines4, strlen("display")+1, .)
    lines5 = strtrim(lines5)
    dispcmd = select(lines5, flag)

    idx = selectindex(flag)
    n_displays = rows(idx)

    for (i = 1; i <= n_displays; i++) {
        val = display_value_after(lines, idx[i])
        if (val == "") continue
        want = norm_disp_args(dispcmd[i])
        if (want == "") continue
        after = ((1::n) :> idx[i]) :* textflag
        textrow = select(textflag, after)
        if (length(textrow) == 0) continue
        text_j = selectindex(textflag :== textrow[1])
        for (k = 1; k <= length(text_j); k++) {
            lines[text_j[k]] = replace_ishere_display_tag(lines[text_j[k]], want, val)
        }
    }

    return(lines)
}


end


///////////////////////////
capture program drop alltohtml
program define alltohtml,rclass
    version 16
    syntax anything, [width(string) height(string) zoom(string)]
    tohtml_require_fs

    // check directory exists
    if "`zoom'"=="" local zoom "100%"
    else{
        if strpos("`zoom'", "%") == 0 local zoom "`zoom'%"
    }
    
    if "`height'" == "" local height "400px"
    if "`width'" == "" local width "100%"    
    local zoomstyle  style="zoom:`zoom';"
    mata: ifig = `"<img src="http://fmwww.bc.edu/repec/bocode/t/_filepath_" `zoomstyle' />"'

    mata: tables = J(0,1,"")
    mata: tabletitles = J(0,1,"")

    // normalize path
    foreach folder in `anything' {

        local folder = subinstr(`"`folder'"', "\", "/", .)
        // if ends with / remove
        if substr(`"`folder'"', -1, 1) == "/" local folder = substr(`"`folder'"', 1, strlen(`"`folder'"')-1)
    
        // check directory exists
        mata: st_numscalar("pathexists",direxists(st_local("folder")))
        if pathexists == 0 {
            display as error "Directory `folder' does not exist."
            exit 198
        }
        mata: itab = "<iframe src='http://fmwww.bc.edu/repec/bocode/t/_filepath_' width='`width'' height='`height'' frameBorder='0'></iframe>"
        quietly fs "`folder'/table*.html"

        foreach file in `r(files)' {
           local file `file'
           mata: tabletitles = tabletitles \ `"`file'"'
           local file `folder'/`file'
           mata: tables = tables \ usubinstr(itab,"_filepath_",`"`file'"',1)
        }

        mata: itab = "<iframe _filepath_ ></iframe>"
        quietly fs "`folder'/table*.md"
        foreach file in `r(files)' {
            local file `file'
            mata: tabletitles = tabletitles \ `"`file'"'
            local file `folder'/`file'
            mata: tables = tables \ usubinstr(itab,"_filepath_",`"`file'"',1)
        }
    
        // common image extensions for files starting with 'figure'
        foreach ext in png jpg jpeg svg gif bmp webp {
            quietly fs "`folder'/figure*.`ext'"
            foreach file in `r(files)' {
              local file `file'
              mata: tabletitles = tabletitles \ `"`file'"'
              local file `folder'/`file'
              mata: tables = tables \ usubinstr(ifig,"_filepath_",`"`file'"',1)
            }
        }



    }     


    // use fs (assumed present) to list files in the folder
    // Collect HTML tables and figure-prefixed images
 

    // html files

    mata: st_numscalar("ntables", length(tables))

    if ntables == 0 {
        display  `"No tables or figures found in `folder'"'
        //exit 
    }
    

    mata: tables = tables, ("### " :+ tabletitles)
    local templog `"`c(pwd)'/_tempfile_log_.md"'
    mata: write_log(tables)
    cap confirm file `"`templog'"'
    if _rc == 0 {
        display `"`templog' created"'
        return local templog `templog'
    }
    

end

mata:
void write_log(string matrix tables)
{
   n = rows(tables)
   if (n==0) exit
   tables = sort(tables, 2)   // 按第二列排序后再写出
   fh ="# Figures and Tables"
   for(i=1; i<=n; i++) {
    fh = fh \ "" \ ""
    fh = fh \ tables[i,2] \ tables[i,1]
   }
   mm_outsheet(st_local("templog"), fh, "replace")

}

string colvector function ishererep(string colvector content)
{
    lines = content
    lines2 = usubinstr(lines, " ", "", .)
    flag = selectindex(ustrpos(lines2, ".**#") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\.\s*\*\*\s*", ". ishere ")
    }
    // . **/*  →  . /**   (do not use ishere /*)
    flag = selectindex(ustrpos(lines2, ".**/*") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\.\s*\*\*\s*/\*", ". /**")
    }
    // > **/  (spaces removed: >**/)
    flag = selectindex(ustrpos(lines2, ">**/") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\>\s*\*\*\s*/", "> **/")
    }

    flag = selectindex(ustrpos(lines2, ".**```") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\.\s*\*\*\s*", ". ishere ")
    }
    return(lines)
}


string colvector function ishererep2(string colvector content)
{
    lines = content
    lines2 = usubinstr(lines, " ", "", .)
    flag = selectindex(ustrpos(lines2, "**#") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\s*\*\*\s*", "ishere ")
    }
    // **/* → /** 
    flag = selectindex(ustrpos(lines2, "**/*") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\s*\*\*\s*/\*", "/**")
    }
    // **/ closing (avoid matching /**)
    flag = selectindex((ustrpos(lines2, "**/") :== 1) :* (ustrpos(lines2, "/**") :!= 1))
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\s*\*\*\s*/", "**/")
    }

    flag = selectindex(ustrpos(lines2, "**```") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\s*\*\*\s*", "ishere ")
    }
    return(lines)
}

end
