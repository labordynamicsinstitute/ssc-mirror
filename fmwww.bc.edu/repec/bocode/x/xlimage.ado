*! xlimage v3.1.0  Mario Anderson Apaza Naupa  03aug2026
*! Insert or replace an image in an Excel workbook without stacking copies,
*! and without Python.
*!
*! Intended for reproducible reports: an .xlsx template with one or more anchored
*! images. On each re-run of the do-file, xlimage places the new graph at the
*! given anchor cell -- inserting it if none is there yet, or replacing the
*! existing one -- keeping position, size, and formatting, and without letting
*! images accumulate. The same command line works on every run.
*!
*! How it works: via the anchor cell it finds the internal image file and, to
*! replace, overwrites only that PNG/JPG (the anchor XML is not rewritten, so it
*! cannot corrupt the workbook). To insert, it adds the anchor to the sheet's
*! existing drawing, or creates the drawing, relationships, and content type.
*!
*! Supports oneCellAnchor and twoCellAnchor, with or without the xdr: prefix,
*! several sheets, and several images per sheet.
*!
*! Requires Stata 14+ (unzipfile/zipfile). No Python required.

program define xlimage
    version 14.0

    syntax using/, Image(string) Cell(string) [ SHEET(string) ]

    // ---------- validation ----------
    local wb `"`using'"'
    capture confirm file `"`wb'"'
    if _rc {
        di as error "workbook not found: `wb'"
        di as error "{p 0 4}xlimage places the image into a workbook that already " ///
            "exists (your template). Create the workbook first with your formatting " ///
            "using putexcel (putexcel set ... , replace / modify), add your title " ///
            "and table, save it with putexcel save, then run xlimage again.{p_end}"
        di as error "If you already have a template, check the path or file name."
        exit 601
    }
    capture confirm file `"`image'"'
    if _rc {
        di as error "image file not found: `image'"
        exit 601
    }
    local cell = upper("`cell'")

    quietly {
        local here "`c(pwd)'"
        local stub = "__xlimg_" + strofreal(runiformint(1,999999))
        capture mkdir "`stub'"

        // ---------- unzip ----------
        cd "`stub'"
        capture unzipfile `"../`wb'"', replace
        if _rc {
            cd "`here'"
            capture rmdir "`stub'"
            noisily di as error ///
                "could not unzip the workbook (is it open in Excel?)"
            exit 603
        }
        cd "`here'"

        // ---------- locate the internal media by cell/sheet ----------
        mata: _xlimage_find("`stub'", "`cell'", `"`sheet'"')
        local target "`r(mediafile)'"
        local didinsert 0

        if "`target'" == "" {
            // no image at that cell: INSERT from scratch
            mata: _xlimage_insert("`stub'", "`cell'", `"`sheet'"')
            local target "`r(mediafile)'"
            local didinsert 1

            if "`target'" == "" {
                cd "`here'"
                capture shell rmdir /s /q "`stub'"
                capture rmdir "`stub'"
                noisily di as error ///
                    "could not insert the image (does the specified sheet exist?)"
                exit 459
            }
        }

        // ---------- write the media (new or replacement) ----------
        capture erase "`stub'/`target'"
        capture copy `"`image'"' "`stub'/`target'"
        if _rc {
            cd "`here'"
            capture shell rmdir /s /q "`stub'"
            capture rmdir "`stub'"
            noisily di as error "could not write the new image"
            exit 603
        }

        // ---------- repackage (validated recipe: stored + Content_Types) --
        cd "`stub'"
        capture erase "../__xlimg_out.zip"
        local dp ""
        capture confirm file "docProps/core.xml"
        if !_rc local dp "docProps"
        zipfile xl _rels `dp' *ontent_Types*.xml, ///
            saving("../__xlimg_out.zip", replace) complevel(0)
        cd "`here'"

        // ---------- replace the workbook with the result ----------
        capture erase `"`wb'"'
        copy "__xlimg_out.zip" `"`wb'"'
        capture erase "__xlimg_out.zip"

        // ---------- clean up ----------
        capture shell rmdir /s /q "`stub'"
        capture rmdir "`stub'"
    }

    if `didinsert' {
        di as text "image inserted at " as result "`cell'" ///
            as text " in " as result `"`wb'"'
    }
    else {
        di as text "image at " as result "`cell'" ///
            as text " replaced in " as result `"`wb'"'
        di as text "position and formatting preserved; no stacking."
    }
end

*======================================================================
* Backend Mata: resuelve celda+hoja -> archivo de imagen interno
*======================================================================
version 14.0
mata:

// Insert an image. If the sheet already has a drawing, add the anchor to that
// drawing (keeping previous images); otherwise create the drawing, its rels,
// link the sheet, and register the content type. Leaves the media path in
// r(mediafile) so the .ado can copy the file.
void _xlimage_insert(string scalar stub, string scalar cell, string scalar sheet)
{
    real scalar tcol, trow, nextn
    string scalar sheetfile, snum, medianame, drawfile
    string scalar dq, nl, a_ns, xdr_ns, r_ns
    string scalar block, dxml, drels, sxml, spath, srels, srels_path
    string scalar newrid, ct, ctpath, embed, draw_rid, dpath, drels_path

    st_rclear()
    _xlimage_cell2cr(cell, tcol, trow)

    dq = char(34)
    nl = char(10)
    a_ns   = "http://schemas.openxmlformats.org/drawingml/2006/main"
    xdr_ns = "http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing"
    r_ns   = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"

    // sheet -> sheetN.xml
    sheetfile = _xlimage_sheetfile(stub, sheet)
    if (sheetfile == "") {
        return
    }
    snum = _xlimage_digits(sheetfile)
    if (snum == "") snum = "1"

    // new media name
    nextn = _xlimage_nextmedia(stub)
    medianame = "image" + strofreal(nextn) + ".png"
    _xlimage_mkdir(stub + "/xl/media")

    // does the sheet already have a <drawing>?
    spath = stub + "/xl/worksheets/" + sheetfile
    sxml = _xlimage_slurp(spath)

    if (regexm(sxml, "<drawing[^>]*r:id=" + dq + "(rId[0-9]+)" + dq)) {
        // --- BRANCH A: drawing exists, ADD the anchor to the existing drawing ---
        draw_rid = regexs(1)
        srels_path = stub + "/xl/worksheets/_rels/" + sheetfile + ".rels"
        srels = _xlimage_slurp(srels_path)
        drawfile = _xlimage_basename(_xlimage_relstarget(srels, draw_rid))
        dpath = stub + "/xl/drawings/" + drawfile
        drels_path = stub + "/xl/drawings/_rels/" + drawfile + ".rels"

        // new image rId within the drawing rels
        drels = _xlimage_slurp(drels_path)
        embed = "rId" + strofreal(_xlimage_nextrid(drels))
        drels = subinstr(drels, "</Relationships>",
            "<Relationship Id=" + dq + embed + dq +
            " Type=" + dq + r_ns + "/image" + dq +
            " Target=" + dq + "../media/" + medianame + dq + "/></Relationships>", 1)
        _xlimage_spit(drels_path, drels)

        // add the anchor before </wsDr>
        block = _xlimage_anchorblock(tcol, trow, embed, dq, a_ns, r_ns)
        dxml = _xlimage_slurp(dpath)
        dxml = subinstr(dxml, "</wsDr>", block + "</wsDr>", 1)
        _xlimage_spit(dpath, dxml)
    }
    else {
        // --- BRANCH B: no drawing, CREATE everything from scratch ---
        embed = "rId1"
        drawfile = "drawing" + snum + ".xml"

        block = _xlimage_anchorblock(tcol, trow, embed, dq, a_ns, r_ns)
        dxml = "<?xml version=" + dq + "1.0" + dq + " encoding=" + dq + "UTF-8" + dq +
               " standalone=" + dq + "yes" + dq + "?>" + nl +
               "<wsDr xmlns=" + dq + xdr_ns + dq + ">" + block + "</wsDr>"
        _xlimage_mkdir(stub + "/xl/drawings")
        _xlimage_spit(stub + "/xl/drawings/" + drawfile, dxml)

        // drawing rels
        drels = "<?xml version=" + dq + "1.0" + dq + " encoding=" + dq + "UTF-8" + dq +
                " standalone=" + dq + "yes" + dq + "?>" + nl +
                "<Relationships xmlns=" + dq +
                "http://schemas.openxmlformats.org/package/2006/relationships" + dq + ">" +
                "<Relationship Id=" + dq + embed + dq +
                " Type=" + dq + r_ns + "/image" + dq +
                " Target=" + dq + "../media/" + medianame + dq + "/></Relationships>"
        _xlimage_mkdir(stub + "/xl/drawings/_rels")
        _xlimage_spit(stub + "/xl/drawings/_rels/" + drawfile + ".rels", drels)

        // sheet rels -> drawing
        srels_path = stub + "/xl/worksheets/_rels/" + sheetfile + ".rels"
        if (fileexists(srels_path)) {
            srels = _xlimage_slurp(srels_path)
            newrid = "rId" + strofreal(_xlimage_nextrid(srels))
            srels = subinstr(srels, "</Relationships>",
                "<Relationship Id=" + dq + newrid + dq +
                " Type=" + dq + r_ns + "/drawing" + dq +
                " Target=" + dq + "../drawings/" + drawfile + dq + "/></Relationships>", 1)
        }
        else {
            newrid = "rId1"
            srels = "<?xml version=" + dq + "1.0" + dq + " encoding=" + dq + "UTF-8" + dq +
                    " standalone=" + dq + "yes" + dq + "?>" + nl +
                    "<Relationships xmlns=" + dq +
                    "http://schemas.openxmlformats.org/package/2006/relationships" + dq + ">" +
                    "<Relationship Id=" + dq + newrid + dq +
                    " Type=" + dq + r_ns + "/drawing" + dq +
                    " Target=" + dq + "../drawings/" + drawfile + dq + "/></Relationships>"
            _xlimage_mkdir(stub + "/xl/worksheets/_rels")
        }
        _xlimage_spit(srels_path, srels)

        // link the drawing into the sheet
        sxml = subinstr(sxml, "</worksheet>",
            "<drawing xmlns:r=" + dq + r_ns + dq + " r:id=" + dq + newrid + dq +
            "/></worksheet>", 1)
        _xlimage_spit(spath, sxml)

        // content types: png default + drawing override
        ctpath = stub + "/[Content_Types].xml"
        ct = _xlimage_slurp(ctpath)
        if (!regexm(ct, "Extension=" + dq + "png" + dq)) {
            ct = subinstr(ct, "<Default",
                "<Default Extension=" + dq + "png" + dq +
                " ContentType=" + dq + "image/png" + dq + "/><Default", 1)
        }
        if (!regexm(ct, "drawings/" + drawfile)) {
            ct = subinstr(ct, "</Types>",
                "<Override PartName=" + dq + "/xl/drawings/" + drawfile + dq +
                " ContentType=" + dq +
                "application/vnd.openxmlformats-officedocument.drawing+xml" + dq +
                "/></Types>", 1)
        }
        _xlimage_spit(ctpath, ct)
    }

    // expose the media path for the .ado
    st_global("r(mediafile)", "xl/media/" + medianame)
}

// build a <oneCellAnchor> block (openpyxl format, accepted by Excel)
string scalar _xlimage_anchorblock(real scalar tcol, real scalar trow,
    string scalar embed, string scalar dq, string scalar a_ns, string scalar r_ns)
{
    string scalar b
    b = "<oneCellAnchor><from>" +
        "<col>" + strofreal(tcol) + "</col><colOff>0</colOff>" +
        "<row>" + strofreal(trow) + "</row><rowOff>0</rowOff>" +
        "</from><ext cx=" + dq + "4762500" + dq + " cy=" + dq + "2857500" + dq + "/>" +
        "<pic><nvPicPr>" +
        "<cNvPr id=" + dq + "1" + dq + " name=" + dq + "Image" + dq +
        " descr=" + dq + "Picture" + dq + "/>" +
        "<cNvPicPr/></nvPicPr>" +
        "<blipFill><a:blip xmlns:a=" + dq + a_ns + dq +
        " xmlns:r=" + dq + r_ns + dq +
        " cstate=" + dq + "print" + dq + " r:embed=" + dq + embed + dq + "/>" +
        "<a:stretch xmlns:a=" + dq + a_ns + dq + "><a:fillRect/></a:stretch></blipFill>" +
        "<spPr><a:prstGeom xmlns:a=" + dq + a_ns + dq +
        " prst=" + dq + "rect" + dq + "/></spPr>" +
        "</pic><clientData/></oneCellAnchor>"
    return(b)
}

void _xlimage_find(string scalar stub, string scalar cell, string scalar sheet)
{
    real scalar tcol, trow
    string scalar sheetfile, drawfile, embed, mtarget

    _xlimage_cell2cr(cell, tcol, trow)
    st_rclear()

    // 1) sheet -> sheetN.xml
    sheetfile = _xlimage_sheetfile(stub, sheet)
    if (sheetfile == "") {
        return
    }

    // 2) sheetN.xml -> drawingN.xml
    drawfile = _xlimage_drawfile(stub, sheetfile)
    if (drawfile == "") {
        return
    }

    // 3) drawingN.xml -> embed rId of the anchor at (tcol,trow)
    embed = _xlimage_embedat(stub, drawfile, tcol, trow)
    if (embed == "") {
        return
    }

    // 4) embed -> media target
    mtarget = _xlimage_mediatarget(stub, drawfile, embed)
    if (mtarget == "") {
        return
    }

    st_global("r(mediafile)", mtarget)
}

// "B7" -> col,row zero-based
void _xlimage_cell2cr(string scalar cell, real scalar col, real scalar row)
{
    string scalar L, D, ch
    real scalar i, c
    L = "" ; D = ""
    for (i=1; i<=strlen(cell); i++) {
        ch = substr(cell,i,1)
        if (regexm(ch, "[A-Za-z]")) L = L + ch
        else if (regexm(ch, "[0-9]")) D = D + ch
    }
    c = 0
    for (i=1; i<=strlen(L); i++) c = c*26 + (ascii(strupper(substr(L,i,1))) - 64)
    col = c - 1
    row = strtoreal(D) - 1
}

// sheet (name) -> relative path sheetN.xml. If sheet=="" uses the first sheet.
string scalar _xlimage_sheetfile(string scalar stub, string scalar sheet)
{
    string scalar wbxml, wbrels, rid, tgt, dq, esc
    dq = char(34)
    wbxml  = _xlimage_slurp(stub + "/xl/workbook.xml")
    wbrels = _xlimage_slurp(stub + "/xl/_rels/workbook.xml.rels")
    if (wbxml == "") return("")

    if (sheet == "") {
        if (regexm(wbxml, "<sheet[^>]*r:id=" + dq + "(rId[0-9]+)" + dq)) rid = regexs(1)
        else return("")
    }
    else {
        esc = _xlimage_esc(sheet)
        if (regexm(wbxml, "<sheet[^>]*name=" + dq + esc + dq + "[^>]*r:id=" + dq + "(rId[0-9]+)" + dq))
            rid = regexs(1)
        else if (regexm(wbxml, "<sheet[^>]*r:id=" + dq + "(rId[0-9]+)" + dq + "[^>]*name=" + dq + esc + dq))
            rid = regexs(1)
        else return("")
    }
    tgt = _xlimage_relstarget(wbrels, rid)
    if (tgt == "") return("")
    return(_xlimage_basename(tgt))
}

// sheetN.xml -> drawingN.xml (via <drawing r:id> and sheetN.xml.rels)
string scalar _xlimage_drawfile(string scalar stub, string scalar sheetfile)
{
    string scalar sxml, srels, drid, tgt
    sxml = _xlimage_slurp(stub + "/xl/worksheets/" + sheetfile)
    if (sxml == "") return("")
    if (!regexm(sxml, "<drawing[^>]*r:id=" + char(34) + "(rId[0-9]+)" + char(34))) return("")
    drid = regexs(1)
    srels = _xlimage_slurp(stub + "/xl/worksheets/_rels/" + sheetfile + ".rels")
    tgt = _xlimage_relstarget(srels, drid)
    if (tgt == "") return("")
    return(_xlimage_basename(tgt))
}

// in drawingN.xml, find the r:embed of the anchor whose <from> = (tcol,trow)
string scalar _xlimage_embedat(string scalar stub, string scalar drawfile,
                               real scalar tcol, real scalar trow)
{
    string scalar dxml, rest, anchor, tagchunk, closetag, aft
    real scalar fc, fr, p, q, startlt

    dxml = _xlimage_slurp(stub + "/xl/drawings/" + drawfile)
    if (dxml == "") return("")

    rest = dxml
    while (1) {
        if (!regexm(rest, "<(xdr:)?(one|two)CellAnchor")) break
        p = strpos(rest, "CellAnchor")

        startlt = p
        while (startlt > 1 & substr(rest, startlt, 1) != "<") startlt = startlt - 1

        tagchunk = substr(rest, startlt, 40)
        if (regexm(tagchunk, "<((xdr:)?(one|two)CellAnchor)")) closetag = "</" + regexs(1) + ">"
        else break

        q = strpos(rest, closetag)
        if (q == 0) break
        anchor = substr(rest, startlt, q + strlen(closetag) - startlt)

        fc = -1 ; fr = -1
        if (regexm(anchor, "<(xdr:)?from>")) {
            aft = substr(anchor, strpos(anchor, "from>"), .)
            if (regexm(aft, "<(xdr:)?col>([0-9]+)</(xdr:)?col>")) fc = strtoreal(regexs(2))
            if (regexm(aft, "<(xdr:)?row>([0-9]+)</(xdr:)?row>")) fr = strtoreal(regexs(2))
        }

        if (fc == tcol & fr == trow) {
            if (regexm(anchor, "r:embed=" + char(34) + "(rId[0-9]+)" + char(34))) return(regexs(1))
        }

        rest = substr(rest, startlt + strlen(anchor), .)
    }
    return("")
}

// embed -> media target (relative xl/media/imageN.ext), reading drawingN.xml.rels
string scalar _xlimage_mediatarget(string scalar stub, string scalar drawfile,
                                   string scalar embed)
{
    string scalar drels, tgt
    drels = _xlimage_slurp(stub + "/xl/drawings/_rels/" + drawfile + ".rels")
    tgt = _xlimage_relstarget(drels, embed)
    if (tgt == "") return("")
    // normalize: /xl/media/x -> xl/media/x ; ../media/x -> xl/media/x
    if (substr(tgt,1,1) == "/") tgt = substr(tgt,2,.)
    if (substr(tgt,1,3) != "xl/") {
        if (regexm(tgt, "media/[^/]+$")) tgt = "xl/" + regexs(0)
    }
    return(tgt)
}

//---- utilities ----

// read a whole text file
string scalar _xlimage_slurp(string scalar path)
{
    real scalar fh
    string scalar s, line
    if (!fileexists(path)) return("")
    fh = fopen(path, "r")
    s = ""
    while ((line = fget(fh)) != J(0,0,"")) s = s + line
    fclose(fh)
    return(s)
}

// given an rId, return its Target in a .rels (any attribute order)
string scalar _xlimage_relstarget(string scalar rels, string scalar rid)
{
    string scalar dq, notq
    dq = char(34)
    notq = "([^" + dq + "]+)"
    if (rels == "") return("")
    if (regexm(rels, "Id=" + dq + rid + dq + "[^>]*Target=" + dq + notq + dq)) return(regexs(1))
    if (regexm(rels, "Target=" + dq + notq + dq + "[^>]*Id=" + dq + rid + dq)) return(regexs(1))
    return("")
}

// last component of a path
string scalar _xlimage_basename(string scalar path)
{
    real scalar i
    for (i = strlen(path); i >= 1; i--) {
        if (substr(path,i,1) == "/") return(substr(path, i+1, .))
    }
    return(path)
}

// extract only the digits from a string (sheet1.xml -> 1)
string scalar _xlimage_digits(string scalar s)
{
    string scalar out, ch
    real scalar i
    out = ""
    for (i=1; i<=strlen(s); i++) {
        ch = substr(s,i,1)
        if (regexm(ch, "[0-9]")) out = out + ch
    }
    return(out)
}

// next media number (scans xl/media/imageN.*)
real scalar _xlimage_nextmedia(string scalar stub)
{
    string scalar mdir, f
    real scalar i, n, maxn, nfiles
    string colvector flist

    mdir = stub + "/xl/media"
    if (!direxists(mdir)) return(1)
    flist = dir(mdir, "files", "*")
    maxn = 0
    nfiles = rows(flist)
    for (i=1; i<=nfiles; i++) {
        f = flist[i]
        if (regexm(f, "image([0-9]+)")) {
            n = strtoreal(regexs(1))
            if (n > maxn) maxn = n
        }
    }
    return(maxn + 1)
}

// next available rId in a .rels file
real scalar _xlimage_nextrid(string scalar rels)
{
    real scalar maxn, n, p
    string scalar rest
    maxn = 0
    rest = rels
    while (regexm(rest, "Id=" + char(34) + "rId([0-9]+)" + char(34))) {
        n = strtoreal(regexs(1))
        if (n > maxn) maxn = n
        p = strpos(rest, "rId" + regexs(1))
        rest = substr(rest, p + strlen("rId" + regexs(1)), .)
    }
    return(maxn + 1)
}

// create folder (silent if it already exists)
void _xlimage_mkdir(string scalar path)
{
    if (!direxists(path)) mkdir(path)
}

// write string to file (overwrite)
void _xlimage_spit(string scalar path, string scalar content)
{
    real scalar fh
    unlink(path)
    fh = fopen(path, "w")
    fput(fh, content)
    fclose(fh)
}

// regex-escape the special characters common in sheet names
string scalar _xlimage_esc(string scalar s)
{
    string scalar out, ch, special, bs
    real scalar i
    bs = char(92)
    special = ".^$*+?()[]{}|" + bs
    out = ""
    for (i=1; i<=strlen(s); i++) {
        ch = substr(s,i,1)
        if (strpos(special, ch) > 0) out = out + bs + ch
        else out = out + ch
    }
    return(out)
}

end
