*! version 1.19, 2026-08-29
*! version 1.18, 2026-08-28
*! version 1.17, 2026-08-28
*! version 1.16, 2026-08-23
*! version 1.15, 2026-08-23
*! version 1.14, 2026-08-23
*! version 1.13, 2026-08-23
*! version 1.12, 2026-08-22
*! version 1.11, 2026-08-21
*! version 1.10, 2026-08-21
*! version 1.9, 2026-08-21
*! version 1.8, 2026-08-21
*! version 1.7, 2026-08-21
*! version 1.6, 2026-08-11
program define ishere
    version 14

    gettoken subcmd : 0
    local subl = lower("`subcmd'")
    local isfig = inlist("`subl'", "fig", "figure")
    local istab = inlist("`subl'", "tab", "table")
    local isdisp = ("`subl'" == "display")

    // ---------------------------------------------------------------
    // Mode 2b: emit display value for MD tag replacement
    // ---------------------------------------------------------------
    if `isdisp' {
        gettoken junk 0 : 0
        display `0'
        exit 0
    }

    // ---------------------------------------------------------------
    // Mode 2: emit markdown/HTML insertion for figures and tables
    // ---------------------------------------------------------------
    if `isfig' | `istab' {
        syntax anything using/ [, Height(string) Width(string) Zoom(string) CSSFile(string) TItle(string)]

        removequotes, t(`using')
        local using `r(s)'
        local using = subinstr("`using'", "\", "/", .)

        local filepath `using'
        if "`filepath'" == "" {
            di as error "ishere `subcmd': using(filename) is required"
            exit 198
        }
        if strpos("`filepath'", ".") == 0 {
            di as error "filename must have an extension"
            exit 198
        }
        mata: st_local("extension", pathsuffix("`filepath'"))
        local extension = lower("`extension'")

        local capattr
        if `"`title'"' != "" {
            mata: st_local("title_esc", ishere_html_escape(st_local("title")))
            local capattr `" data-tohtml-title="`title_esc'""'
        }

        if `isfig' {
            if "`zoom'" == "" & "`height'" == "" & "`width'" == "" local zoom "100%"
            if !inlist("`extension'", ".png", ".jpg", ".jpeg", ".svg", ".gif", ".bmp", ".webp") {
                di as error "unsupported image format: `extension'"
                exit 198
            }
            if "`zoom'" != "" {
                if strpos("`zoom'", "%") == 0 local zoom "`zoom'%"
                di
                display `"<img src="http://fmwww.bc.edu/repec/bocode/i/`filepath'" style="zoom:`zoom';"`capattr'>"'
            }
            else {
                if "`width'" == "" local width "auto"
                if "`height'" == "" local height "auto"
                di
                display `"<img src="http://fmwww.bc.edu/repec/bocode/i/`filepath'" width="`width'" height="`height'"`capattr'>"'
            }
            exit
        }

        // table: iframe is only a log marker; tohtml inlines the HTML table.
        if inlist("`extension'", ".html", ".htm") {
            if "`width'" == "" local width "100%"
            mata: ishere_ensure_table_css(st_local("filepath"), st_local("cssfile"))
            di
            display `"<iframe src='http://fmwww.bc.edu/repec/bocode/i/`filepath'' width='`width'' frameBorder='0'`capattr'></iframe>"'
        }
        else if "`extension'" == ".md" {
            di
            display `"<iframe `filepath'`capattr'></iframe>"'
        }
        else {
            di as error "unsupported table format: `extension'"
            di as error "allowed: .html, .htm, .md"
            exit 198
        }
        exit
    }

    // ---------------------------------------------------------------
    // Mode 1: placeholder — code block or markdown header only
    // ---------------------------------------------------------------
    syntax [anything(everything)]
    local a = strtrim(`"`anything'"')

    // code block marker: ishere  or  ishere ```
    if `"`a'"' == "" | `"`a'"' == "```" {
        exit
    }

    // header: ishere # ...
    if usubstr(`"`a'"', 1, 1) == "#" {
        exit
    }

    di as error `"ishere: unsupported argument `a'"'
    di as error "placeholder mode: ishere  |  ishere # heading"
    di as error "emit mode: ishere display ..."
    di as error "           ishere fig|figure using filename [, zoom() height() width() title()]"
    di as error "           ishere tab|table using filename [, height() width() cssfile() title()]"
    exit 198
end


capture program drop removequotes
program define removequotes, rclass
    version 14
    syntax, [t(string)]
    return local s `t'
end

mata:
string scalar ishere_html_escape(string scalar s)
{
    s = usubinstr(s, "&", "&amp;", .)
    s = usubinstr(s, "<", "&lt;", .)
    s = usubinstr(s, ">", "&gt;", .)
    s = usubinstr(s, char(34), "&quot;", .)
    s = usubinstr(s, char(39), "&#39;", .)
    return(s)
}

string scalar ishere_join_lines(string colvector lines)
{
    s = ""
    for (i = 1; i <= rows(lines); i++) {
        s = s + lines[i] + char(10)
    }
    return(s)
}

string colvector ishere_link_css_hrefs(string scalar blob)
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

string scalar ishere_css_href(string scalar htmlfile, string scalar cssfile)
{
    hdir = pathgetparent(htmlfile)
    if (hdir == "") hdir = pwd()
    a = subinstr(cssfile, "\", "/", .)
    b = subinstr(hdir, "\", "/", .)
    while (strlen(b) > 1 & substr(b, strlen(b), 1) == "/") {
        b = substr(b, 1, strlen(b) - 1)
    }
    pref = ustrlower(b) + "/"
    if (ustrpos(ustrlower(a), pref) == 1) {
        return(substr(a, strlen(b) + 2, .))
    }
    pdir = pathgetparent(hdir)
    if (pdir != "") {
        pb = subinstr(pdir, "\", "/", .)
        while (strlen(pb) > 1 & substr(pb, strlen(pb), 1) == "/") {
            pb = substr(pb, 1, strlen(pb) - 1)
        }
        if (ustrpos(ustrlower(a), ustrlower(pb) + "/") == 1) {
            rest = substr(a, strlen(pb) + 2, .)
            if (pathgetparent(rest) == "" | pathgetparent(rest) == ".") {
                return("../" + pathbasename(cssfile))
            }
        }
    }
    return(pathbasename(cssfile))
}

string scalar ishere_stylesheet_link(string scalar href)
{
    q = char(34)
    return("<link rel=" + q + "stylesheet" + q + " type=" + q + "text/css" + q + " href=" + q + href + q + ">")
}

real scalar ishere_is_stylesheet_line(string scalar line)
{
    t = ustrlower(ustrtrim(line))
    if (ustrpos(t, "<link") != 1) return(0)
    if (ustrpos(t, "stylesheet") > 0) return(1)
    if (ustrpos(t, "text/css") > 0) return(1)
    return(0)
}

string colvector ishere_drop_stylesheet_lines(string colvector lines)
{
    if (rows(lines) == 0) return(lines)
    keep = J(rows(lines), 1, 1)
    for (i = 1; i <= rows(lines); i++) {
        if (ishere_is_stylesheet_line(lines[i])) keep[i] = 0
    }
    if (sum(keep) == 0) return(J(0, 1, ""))
    return(select(lines, keep))
}

real scalar ishere_already_links_css(string colvector lines, string scalar cssbase)
{
    hrefs = ishere_link_css_hrefs(ishere_join_lines(lines))
    want = ustrlower(subinstr(cssbase, "\", "/", .))
    for (i = 1; i <= rows(hrefs); i++) {
        got = ustrlower(subinstr(pathbasename(hrefs[i]), "\", "/", .))
        if (got == want) return(1)
    }
    return(0)
}

string colvector ishere_attach_css_link(string colvector lines, string scalar href)
{
    blob = ustrlower(ishere_join_lines(lines))
    link = ishere_stylesheet_link(href)
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

    // collect export, tableonly writes a <table> fragment. Put the
    // stylesheet in <head> so an iframe can apply it.
    q = char(34)
    lines = ishere_drop_stylesheet_lines(lines)
    open = "<!DOCTYPE html>" \ "<html>" \ "<head>" \
        "<meta charset=" + q + "utf-8" + q + ">" \ link \ "</head>" \ "<body>"
    return(open \ lines \ "</body>" \ "</html>")
}

void function ishere_write_lines(string scalar path, string colvector lines)
{
    unlink(path)
    fh = fopen(path, "w")
    for (i = 1; i <= rows(lines); i++) {
        fput(fh, lines[i])
    }
    fclose(fh)
}

string scalar ishere_first_table_class(string scalar blob)
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

real scalar ishere_reserved_css_name(string scalar base)
{
    b = ustrlower(pathbasename(base))
    return(b == "tohtml.css" | b == "table-override.css")
}

real scalar ishere_css_looks_collect(string scalar cssfile)
{
    if (!fileexists(cssfile)) return(0)
    raw = cat(cssfile)
    if (rows(raw) == 0) return(0)
    blob = ""
    for (i = 1; i <= rows(raw); i++) blob = blob + raw[i] + char(10)
    return(ustrpos(blob, "border-collapse") > 0 | ustrpos(blob, ".Table") > 0)
}

real scalar ishere_css_mentions_class(string scalar cssfile, string scalar cls)
{
    if (cls == "" | !fileexists(cssfile)) return(0)
    raw = cat(cssfile)
    if (rows(raw) == 0) return(0)
    blob = ""
    for (i = 1; i <= rows(raw); i++) blob = blob + raw[i] + char(10)
    return(ustrpos(blob, "." + cls + "_") > 0 | ustrpos(blob, "." + cls + "{") > 0 | ustrpos(blob, "." + cls + " ") > 0)
}

string scalar ishere_guess_companion_css(string scalar htmlpath, string scalar hdir)
{
    names = dir(hdir, "files", "*.css")
    if (rows(names) == 0) return("")
    blob = ""
    if (fileexists(htmlpath)) {
        raw = cat(htmlpath)
        for (i = 1; i <= rows(raw); i++) blob = blob + raw[i] + char(10)
    }
    cls = ishere_first_table_class(blob)
    unpaired = J(0, 1, "")
    classhit = J(0, 1, "")
    for (i = 1; i <= rows(names); i++) {
        base = names[i]
        if (ishere_reserved_css_name(base)) continue
        full = pathjoin(hdir, base)
        if (!ishere_css_looks_collect(full)) continue
        stem = pathrmsuffix(base)
        if (fileexists(pathjoin(hdir, stem + ".html")) | fileexists(pathjoin(hdir, stem + ".htm"))) continue
        unpaired = unpaired \ full
        if (ishere_css_mentions_class(full, cls)) classhit = classhit \ full
    }
    if (rows(classhit) == 1) return(classhit[1])
    if (rows(unpaired) == 1) return(unpaired[1])
    return("")
}

void function ishere_strip_override_css(string scalar htmlfile)
{
    if (!fileexists(htmlfile)) return
    lines = cat(htmlfile)
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
    ishere_write_lines(htmlfile, select(lines, keep))
}

void function ishere_ensure_table_css(string scalar htmlfile, string scalar cssopt)
{
    htmlfile = strtrim(htmlfile)
    cssopt = strtrim(cssopt)
    if (htmlfile == "") return
    htmlpath = htmlfile
    if (!fileexists(htmlpath)) {
        cand = pathjoin(pwd(), htmlfile)
        if (fileexists(cand)) htmlpath = cand
    }
    if (!fileexists(htmlpath)) return
    if (!pathisabs(htmlpath)) htmlpath = pathresolve(pwd(), htmlpath)
    ishere_strip_override_css(htmlpath)

    raw = cat(htmlpath)
    blob = ""
    for (i = 1; i <= rows(raw); i++) blob = blob + raw[i] + char(10)
    blow = ustrlower(blob)
    if (cssopt == "" & ustrpos(blow, "<style") > 0 &
        (ustrpos(blob, ".Table") > 0 | ustrpos(blow, ".texout-table") > 0 |
         ustrpos(blow, "border-top-style") > 0)) {
        return
    }

    hdir = pathgetparent(htmlpath)
    if (hdir == "") hdir = pwd()

    csspath = ""
    if (cssopt != "") {
        csspath = cssopt
        if (!fileexists(csspath)) {
            c1 = pathjoin(hdir, pathbasename(cssopt))
            c2 = pathjoin(pwd(), cssopt)
            if (fileexists(c1)) csspath = c1
            else if (fileexists(c2)) csspath = c2
        }
        if (fileexists(csspath) & !pathisabs(csspath)) csspath = pathresolve(pwd(), csspath)
        if (!fileexists(csspath)) {
            errprintf("ishere: CSS file not found: %s\n", cssopt)
            exit(601)
        }
    }
    else {
        csspath = pathjoin(hdir, pathrmsuffix(pathbasename(htmlpath)) + ".css")
        if (!fileexists(csspath)) csspath = ishere_guess_companion_css(htmlpath, hdir)
    }
    if (!fileexists(csspath)) return
    if (!pathisabs(csspath)) csspath = pathresolve(pwd(), csspath)

    lines = cat(htmlpath)
    href = ishere_css_href(htmlpath, csspath)
    if (ishere_already_links_css(lines, pathbasename(csspath))) {
        blob = ustrlower(ishere_join_lines(lines))
        if (ustrpos(blob, "<html") > 0 | ustrpos(blob, "</head>") > 0) return
    }

    lines = ishere_attach_css_link(lines, href)
    ishere_write_lines(htmlpath, lines)
}
end
