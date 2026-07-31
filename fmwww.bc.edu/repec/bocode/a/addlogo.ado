*! addlogo 1.0.0  Eric Booth  18jul2026
*! Stamp a logo onto a Stata graph: export the graph, composite a logo, save it.
*!
*! Syntax:
*!   addlogo [using imagefile] , logo(file) saving(file) [options]
*!
*! With no  using , the CURRENT graph (or the one in name()) is exported first.
*! A  using  ending in .gph is opened and rendered; any other  using  is treated
*! as an already-exported image (png/tif/jpg/...).
*!
*! Options:
*!   logo(file)      logo image, ideally a PNG with transparency          (required)
*!   saving(file)    output file; format inferred from extension          (required)
*!   position(str)   nw n ne w c e sw s se                     (default: se)
*!   scale(#)        logo width as a fraction of graph width    (default: .12)
*!   pad(#)          margin from edge as a fraction of width    (default: .02)
*!   opacity(#)      0..1 alpha multiplier for the logo         (default: 1)
*!   width(#)        export width in px for the current graph   (default: 2400)
*!   name(str)       export a specific named graph in memory
*!   engine(str)     auto | python | magick                    (default: auto)
*!   pyexec(str)     python interpreter that has Pillow
*!   magickexec(str) path to the ImageMagick 'magick' binary
*!   replace         overwrite saving() if it exists
*!
*! Set-once defaults (e.g. in profile.do) avoid macOS PATH surprises:
*!   global ADDLOGO_PY     "/opt/homebrew/bin/python3"   // must have Pillow
*!   global ADDLOGO_MAGICK "/opt/homebrew/bin/magick"

program define addlogo, rclass
    version 16.0

    syntax [using/] ,                       ///
        Logo(string)                        ///
        SAVing(string)                      ///
        [                                   ///
        POSition(string)                    ///
        SCale(real 0.12)                    ///
        PAD(real 0.02)                      ///
        OPacity(real 1.0)                   ///
        Width(integer 2400)                 ///
        Name(string)                        ///
        ENGine(string)                      ///
        PYexec(string)                      ///
        MAGICKexec(string)                  ///
        replace                             ///
        ]

    // ---------- defaults & light validation ----------
    if ("`position'" == "") local position se
    local position = lower("`position'")
    if (`"`engine'"' == "") local engine auto
    local engine = lower("`engine'")
    if (!inlist("`engine'","auto","python","magick")) {
        di as error "addlogo: engine() must be auto, python, or magick"
        exit 198
    }
    if (`opacity' < 0 | `opacity' > 1) {
        di as error "addlogo: opacity() must be between 0 and 1"
        exit 198
    }

    capture confirm file "`logo'"
    if (_rc) {
        di as error "addlogo: logo file not found: `logo'"
        exit 601
    }

    // ---------- overwrite guard ----------
    if ("`replace'" == "") {
        capture confirm file "`saving'"
        if (_rc == 0) {
            di as error "addlogo: `saving' already exists (specify -replace-)"
            exit 602
        }
    }

    // ---------- resolve the base image ----------
    // The intermediate export goes to a clean sibling of saving(): Stata
    // tempfile names contain a period, which confuses graph export's file-
    // type (suffix) detection.
    local dot = strrpos(`"`saving'"', ".")
    if (`dot' > 0) local stub = substr(`"`saving'"', 1, `dot' - 1)
    else           local stub `"`saving'"'
    local basepng `"`stub'__addlogo_base.png"'
    local madebase 0

    if (`"`using'"' != "") {
        capture confirm file `"`using'"'
        if (_rc) {
            di as error "addlogo: file not found: `using'"
            exit 601
        }
        if (substr(lower(`"`using'"'), -4, 4) == ".gph") {
            capture noisily graph use `"`using'"'
            if (_rc) exit _rc
            capture noisily graph export `"`basepng'"', width(`width') replace
            if (_rc) exit _rc
            local base `"`basepng'"'
            local madebase 1
        }
        else {
            local base `"`using'"'
        }
    }
    else {
        if ("`name'" != "") local gname name(`name')
        capture noisily graph export `"`basepng'"', width(`width') replace `gname'
        if (_rc) {
            di as error "addlogo: could not export the current graph " ///
                        "(is a graph open, or pass a name()/using?)"
            exit _rc
        }
        local base `"`basepng'"'
        local madebase 1
    }

    // ---------- resolve engine executables (survive minimal GUI PATH) ----------
    local magick ""
    if (`"`magickexec'"' != "")            local magick `"`magickexec'"'
    else if (`"$ADDLOGO_MAGICK"' != "")    local magick "$ADDLOGO_MAGICK"
    else {
        foreach c in /opt/homebrew/bin/magick /usr/local/bin/magick {
            if ("`magick'" == "") {
                capture confirm file "`c'"
                if (_rc == 0) local magick "`c'"
            }
        }
    }

    local py ""
    if (`"`pyexec'"' != "")          local py `"`pyexec'"'
    else if (`"$ADDLOGO_PY"' != "")  local py "$ADDLOGO_PY"
    else {
        foreach c in /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3 {
            if ("`py'" == "") {
                capture confirm file "`c'"
                if (_rc == 0) local py "`c'"
            }
        }
    }
    if ("`py'" == "") local py "python3"

    if ("`engine'" == "auto") {
        if ("`magick'" != "") local engine magick
        else                  local engine python
    }
    if ("`engine'" == "magick" & "`magick'" == "") local magick "magick"

    // fresh write so the success test below is meaningful
    capture erase "`saving'"

    // ---------- composite ----------
    if ("`engine'" == "python") {
        capture findfile addlogo_helper.py
        if (_rc) {
            di as error "addlogo: cannot find addlogo_helper.py on the adopath " ///
                        "(reinstall the package; keep it beside addlogo.ado)"
            exit 601
        }
        local pyscript "`r(fn)'"
        shell "`py'" "`pyscript'" --base "`base'" --logo "`logo'" ///
              --out "`saving'" --position "`position'" ///
              --scale `scale' --pad `pad' --opacity `opacity'
    }
    else {   // magick
        // base width, to size the logo & pad relative to the graph
        tempfile wtmp
        shell "`magick'" identify -format "%w" "`base'" > "`wtmp'" 2>/dev/null
        capture file close _alf
        file open _alf using "`wtmp'", read text
        file read _alf _wline
        file close _alf
        local bw = real(trim("`_wline'"))
        if (`bw' >= . | `bw' <= 0) {
            di as error "addlogo: could not read base width via ImageMagick"
            exit 459
        }
        local lw = round(`scale' * `bw')
        if (`lw' < 1) local lw 1
        local padpx = round(`pad' * `bw')

        // gravity + offsets from the chosen anchor
        local grav SouthEast
        if ("`position'" == "nw") local grav NorthWest
        if ("`position'" == "n")  local grav North
        if ("`position'" == "ne") local grav NorthEast
        if ("`position'" == "w")  local grav West
        if ("`position'" == "c")  local grav Center
        if ("`position'" == "e")  local grav East
        if ("`position'" == "sw") local grav SouthWest
        if ("`position'" == "s")  local grav South
        if ("`position'" == "se") local grav SouthEast
        local dx `padpx'
        local dy `padpx'
        if (inlist("`position'","n","c","s")) local dx 0
        if (inlist("`position'","w","c","e")) local dy 0

        // resize + apply opacity, then composite
        tempfile lgt
        local logopng "`lgt'.png"
        shell "`magick'" "`logo'" -resize `lw'x ///
              -channel A -evaluate multiply `opacity' +channel "`logopng'"
        shell "`magick'" "`base'" "`logopng'" ///
              -gravity `grav' -geometry +`dx'+`dy' -composite "`saving'"
    }

    if (`madebase') capture erase `"`basepng'"'

    // ---------- confirm & report ----------
    capture confirm file "`saving'"
    if (_rc) {
        di as error "addlogo: compositing failed (engine=`engine'); see messages above."
        exit 459
    }
    di as text "addlogo: wrote " as result `""`saving'""' ///
       as text "  [engine=`engine', pos=`position', scale=`scale', opacity=`opacity']"

    return local engine "`engine'"
    return local file `"`saving'"'
end
