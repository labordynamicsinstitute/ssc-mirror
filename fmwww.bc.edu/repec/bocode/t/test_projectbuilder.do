* test_projectbuilder.do -- test battery for projectbuilder v2.0.1
* Run from the package folder, or from any scratch directory by naming the
* package folder:
*     stata-mp -b do test_projectbuilder.do
*     stata-mp -b do test_projectbuilder.do "/path/to/projectbuilder-stata-public"
* All paths live in globals set here; synthetic data only (no committed
* .dta/.log).  Judge success by the absence of r(NNN); and failed asserts.

* ---- where the package lives ------------------------------------------
* Read the caller's overrides BEFORE -clear all-, which drops globals.
* Resolution order, first hit wins:
*   1. an argument passed to this do-file
*   2. a global $pkgroot the caller set beforehand
*   3. the current directory, if projectbuilder.ado sits in it
*   4. -findfile-, which searches the ado-path
local argroot `"`1'"'
local preroot `"$pkgroot"'

clear all
set more off
version 16.0
set seed 20260707

global pkgroot `"`argroot'"'
if `"$pkgroot"' == "" global pkgroot `"`preroot'"'
if `"$pkgroot"' == "" {
    capture confirm file `"`c(pwd)'/projectbuilder.ado"'
    if !_rc global pkgroot `"`c(pwd)'"'
}
if `"$pkgroot"' == "" {
    capture findfile projectbuilder.ado
    if !_rc {
        local fp `"`r(fn)'"'
        local s = max(strrpos(`"`fp'"', "/"), strrpos(`"`fp'"', "\"))
        if `s' > 1 global pkgroot = substr(`"`fp'"', 1, `s' - 1)
    }
}
if `"$pkgroot"' == "" {
    di as err "test_projectbuilder: cannot locate projectbuilder.ado."
    di as err `"  Pass the package folder:  do test_projectbuilder.do "/path/to/pkg""'
    exit 601
}
confirm file "$pkgroot/projectbuilder.ado"
di as text `"test_projectbuilder: pkgroot = $pkgroot"'

* Prepend so this source copy wins over any older installed copy in PLUS.
adopath ++ "$pkgroot"

* ---- fresh scratch tree for this run ----------------------------------
tempfile tbase
global work "`tbase'_pbtest"
mkdir "$work"

* helper: load a text file one line per obs into v1 (line-oriented read)
capture program drop loadlines
program define loadlines
    import delimited using `0', clear delimiters("`=char(1)'", asstring) ///
        varnames(nonames) bindquote(nobind) encoding("utf-8")
end

* helper: write one line to a file, turning ~B into a literal backtick, so
* this do-file can emit an ado-file that itself uses local macros.
capture program drop wline
program define wline
    gettoken fh 0 : 0
    file write `fh' (subinstr(`0', "~B", char(96), .)) _n
end

di as text "{hline 70}"
di as text "TEST a1: Method B -- scaffold only, every folder and file exists"
di as text "{hline 70}"
projectbuilder Demo, path("$work")
assert `"`r(project)'"' == "Demo"
assert `"`r(path)'"'    == `"$work/Demo"'
assert r(nraw)       == 0
assert r(nconverted) == 0
assert r(rebuilt)    == 0

foreach d in 01_raw 01_raw/_archive 01_raw/_converted ///
             02_cleaned 02_cleaned/_archive ///
             03_output 03_output/_archive ///
             _code _code/_archive ///
             _documentation _documentation/_archive _documentation/website ///
             _archive {
    confirm file "$work/Demo/`d'/."
}
foreach f in 000_control.do 100_data_download.do 200_data_management.do ///
             300_labels.do 400_data_profiler.do 500_aggregation.do    ///
             600_analysis.do {
    confirm file "$work/Demo/_code/`f'"
}
foreach f in index.do _runall.do Readme.md _project_meta.txt {
    confirm file "$work/Demo/_documentation/`f'"
}
confirm file "$work/Demo/_documentation/website/index.html"

* 01_raw must be empty (no files; subfolders don't count)
local rl : dir "$work/Demo/01_raw" files "*"
assert `: word count `rl'' == 0

di as text "{hline 70}"
di as text "TEST a2: edit a code file, drop data, rebuild -> convert/combine/docs"
di as text "{hline 70}"

* sentinel line appended to a code file the 'user' has edited
tempname sfh
file open `sfh' using "$work/Demo/_code/000_control.do", write text append
file write `sfh' _n "* SENTINEL-KEEP-ME-4711" _n
file close `sfh'

* two synthetic CSVs dropped into 01_raw by hand
sysuse auto, clear
quietly export delimited using "$work/Demo/01_raw/auto_part1.csv", replace
keep make price mpg
quietly export delimited using "$work/Demo/01_raw/auto_part2.csv", replace

projectbuilder Demo, path("$work") rebuild
assert r(nraw)    == 2
assert r(rebuilt) == 1
confirm file "$work/Demo/_documentation/website/index.html"

* the rebuilt documentation mentions both raw files
loadlines "$work/Demo/_documentation/website/index.html"
quietly count if strpos(v1, "auto_part1.csv")
assert r(N) >= 1
quietly count if strpos(v1, "auto_part2.csv")
assert r(N) >= 1

* rebuild WITHOUT replace must NOT overwrite the edited code file
loadlines "$work/Demo/_code/000_control.do"
quietly count if strpos(v1, "SENTINEL-KEEP-ME-4711")
assert r(N) == 1

di as text "{hline 70}"
di as text "TEST a3: rebuild WITH replace overwrites the code file"
di as text "{hline 70}"
projectbuilder Demo, path("$work") rebuild replace
loadlines "$work/Demo/_code/000_control.do"
quietly count if strpos(v1, "SENTINEL-KEEP-ME-4711")
assert r(N) == 0

di as text "{hline 70}"
di as text "TEST b: Method A -- data() copies a folder of files into 01_raw/"
di as text "{hline 70}"
mkdir "$work/_src2"
sysuse auto, clear
quietly export delimited using "$work/_src2/src_a.csv", replace
keep make foreign
quietly export delimited using "$work/_src2/src_b.csv", replace
projectbuilder Demo2, path("$work") data("$work/_src2") ///
    description("two synthetic CSVs")
assert r(nraw) == 2
confirm file "$work/Demo2/01_raw/src_a.csv"
confirm file "$work/Demo2/01_raw/src_b.csv"

di as text "{hline 70}"
di as text "TEST c: clobber guard -- rerun without rebuild -> _rc==602"
di as text "{hline 70}"
capture noisily projectbuilder Demo, path("$work")
assert _rc == 602
confirm file "$work/Demo/_code/000_control.do"

di as text "{hline 70}"
di as text "TEST d: leaf/option validation -> _rc==198"
di as text "{hline 70}"
capture noisily projectbuilder "../evil", path("$work")
assert _rc == 198
capture noisily projectbuilder EvilPF, path("$work") publicfacing(maybe)
assert _rc == 198

di as text "{hline 70}"
di as text "TEST e: Source/Subsource nesting"
di as text "{hline 70}"
projectbuilder Agency/Extract, path("$work")
assert `"`r(project)'"' == "Agency_Extract"
assert `"`r(path)'"'    == `"$work/Agency/Extract"'
confirm file "$work/Agency/Extract/_code/000_control.do"
confirm file "$work/Agency/Extract/_documentation/website/index.html"

di as text "{hline 70}"
di as text "TEST f: a stray extra token is rejected -> _rc==198"
di as text "{hline 70}"
capture noisily projectbuilder E1 E2, path("$work")
assert _rc == 198
capture confirm file "$work/E1 E2/."
assert _rc != 0
* a quoted name containing a space is still a single, legal name
projectbuilder "Two Words", path("$work")
assert `"`r(project)'"' == "Two Words"
confirm file "$work/Two Words/_code/000_control.do"

di as text "{hline 70}"
di as text "TEST g: a bare rebuild PRESERVES the recorded metadata"
di as text "{hline 70}"
projectbuilder Meta, path("$work") description("desc one") topic("t") ///
    publicfacing(yes) timeline("annual") othernotes("from the county") ///
    outcomes(price mpg) over(foreign)
confirm file "$work/Meta/_documentation/_project_meta.txt"
copy "$work/Meta/_documentation/website/index.html" "$work/meta_index_before.html"
copy "$work/Meta/_documentation/Readme.md"          "$work/meta_readme_before.md"

projectbuilder Meta, path("$work") rebuild
assert r(rebuilt) == 1

* the placeholders must NOT have replaced the recorded values
loadlines "$work/Meta/_documentation/website/index.html"
quietly count if strpos(v1, "<p>desc one</p>")
assert r(N) == 1
quietly count if strpos(v1, "<td>t</td>")
assert r(N) == 1
quietly count if strpos(v1, "<td>annual</td>")
assert r(N) == 1
quietly count if strpos(v1, "<td>from the county</td>")
assert r(N) == 1
quietly count if strpos(v1, "add a one-line description")
assert r(N) == 0
quietly count if strpos(v1, "(not recorded)")
assert r(N) == 0

loadlines "$work/Meta/_documentation/Readme.md"
quietly count if strpos(v1, "| Topic | t |")
assert r(N) == 1
quietly count if strpos(v1, "(not recorded)")
assert r(N) == 0

* line-by-line diff: only the build-time footer may differ
loadlines "$work/meta_index_before.html"
gen long _ln = _n
tempfile before_html
quietly save `before_html'
loadlines "$work/Meta/_documentation/website/index.html"
gen long _ln = _n
rename v1 v1_after
quietly merge 1:1 _ln using `before_html'
assert _merge == 3
quietly count if v1_after != v1 & !strpos(v1, "Built ")
assert r(N) == 0

loadlines "$work/meta_readme_before.md"
gen long _ln = _n
tempfile before_md
quietly save `before_md'
loadlines "$work/Meta/_documentation/Readme.md"
gen long _ln = _n
rename v1 v1_after
quietly merge 1:1 _ln using `before_md'
assert _merge == 3
quietly count if v1_after != v1 & !strpos(v1, "Built ")
assert r(N) == 0

* -rebuild replace- keeps the recorded outcomes()/over() in the profiler
projectbuilder Meta, path("$work") rebuild replace
loadlines "$work/Meta/_code/400_data_profiler.do"
quietly count if strpos(v1, `"local outcomes "price mpg""')
assert r(N) == 1
quietly count if strpos(v1, `"local over     "foreign""')
assert r(N) == 1

* an option given on the current call still wins over the recorded value
projectbuilder Meta, path("$work") rebuild topic("procurement")
loadlines "$work/Meta/_documentation/website/index.html"
quietly count if strpos(v1, "<td>procurement</td>")
assert r(N) == 1
quietly count if strpos(v1, "<p>desc one</p>")
assert r(N) == 1

di as text "{hline 70}"
di as text "TEST h: the generated control file pins the package's version floor"
di as text "{hline 70}"
loadlines "$work/Demo2/_code/000_control.do"
quietly count if strpos(v1, "version 16.0")
assert r(N) == 1

di as text "{hline 70}"
di as text "TEST i: each output gets the escaping ITS format needs"
di as text "{hline 70}"
projectbuilder Esc, path("$work") description("R&D <b>bold</b>") ///
    topic("a&b <tag>") othernotes("left|right")

* index.html is HTML, so &, < and > all become entities
loadlines "$work/Esc/_documentation/website/index.html"
quietly count if strpos(v1, "<td>a&amp;b &lt;tag&gt;</td>")
assert r(N) == 1
quietly count if strpos(v1, "<p>R&amp;D &lt;b&gt;bold&lt;/b&gt;</p>")
assert r(N) == 1
quietly count if strpos(v1, "<td>a&b <tag></td>")
assert r(N) == 0

* Readme.md is Markdown, so it gets ONLY what Markdown misreads: | would open
* an extra table column and < would open a raw HTML tag.  A bare & is
* ordinary text and must survive as itself -- this file is read raw as often
* as it is rendered, and "R&amp;D" in an editor is simply wrong.
loadlines "$work/Esc/_documentation/Readme.md"
quietly count if strpos(v1, "| Topic | a&b &lt;tag> |")
assert r(N) == 1
quietly count if strpos(v1, "| Other notes | left\|right |")
assert r(N) == 1
quietly count if strpos(v1, "&amp;")
assert r(N) == 0                       // no HTML entity for & anywhere in the .md
quietly count if strpos(v1, "R&D &lt;b>bold&lt;/b>")
assert r(N) == 1

di as text "{hline 70}"
di as text "TEST j: a seeded 01_raw/_converted/ drives the combine branch"
di as text "{hline 70}"
* convertanything and combineall are optional and usually absent, so the
* shipped battery never reached the code path that fires when there IS
* something converted to combine.  Seed 01_raw/_converted/ by hand to reach
* it: r(nconverted) is non-zero for the first time here.
projectbuilder Seeded, path("$work") description("seeded converted fixture")
sysuse auto, clear
quietly export delimited using "$work/Seeded/01_raw/auto_raw.csv", replace
keep make price mpg foreign
quietly save "$work/Seeded/01_raw/_converted/part1.dta", replace
quietly save "$work/Seeded/01_raw/_converted/part2.dta", replace

projectbuilder Seeded, path("$work") rebuild
assert r(nraw)       == 1
assert r(nconverted) >= 2
loadlines "$work/Seeded/_documentation/website/index.html"
quietly count if strpos(v1, "part1.dta")
assert r(N) >= 1
quietly count if strpos(v1, "part2.dta")
assert r(N) >= 1

* Now put a minimal stand-in for -combineall- on the ado-path, so the call
* projectbuilder makes is actually executed and the analytic file it names
* is actually produced.  The stand-in accepts the same option signature.
mkdir "$work/_stubado"
tempname cfh
file open `cfh' using "$work/_stubado/combineall.ado", write text replace
wline `cfh' `"*! test stand-in for combineall (test_projectbuilder.do)"'
wline `cfh' `"program define combineall"'
wline `cfh' `"    version 16"'
wline `cfh' `"    syntax using/ [, CMethod(string) DIRectory(string) FILEtype(string) REPLACE ]"'
wline `cfh' `"    local fl : dir "~Bdirectory'" files "*.~Bfiletype'""'
wline `cfh' `"    local k = 0"'
wline `cfh' `"    foreach f of local fl {"'
wline `cfh' `"        local ++k"'
wline `cfh' `"        if ~Bk' == 1 use "~Bdirectory'/~Bf'", clear"'
wline `cfh' `"        else append using "~Bdirectory'/~Bf'", force"'
wline `cfh' `"    }"'
wline `cfh' `"    if ~Bk' == 0 {"'
wline `cfh' `"        di as err "combineall stand-in: nothing to combine""'
wline `cfh' `"        exit 601"'
wline `cfh' `"    }"'
wline `cfh' `"    save "~Busing'", replace"'
wline `cfh' `"end"'
file close `cfh'

adopath ++ "$work/_stubado"
capture program drop combineall
projectbuilder Seeded, path("$work") rebuild
assert r(nconverted) >= 2
confirm file "$work/Seeded/02_cleaned/Seeded_analytic.dta"
use "$work/Seeded/02_cleaned/Seeded_analytic.dta", clear
assert _N >= 148              // 74 observations from each seeded .dta
capture program drop combineall
adopath - "$work/_stubado"

di as text "{hline 70}"
di as text "TEST k: the generated 000_control.do runs; its globals are real dirs"
di as text "{hline 70}"
* stash test state: the control file runs -clear all-, which drops globals,
* programs, and adopath additions.
local W  "$work"
local PK "$pkgroot"
do "$work/Demo2/_code/000_control.do"
assert `"$root"'      == `"`W'/Demo2"'   // NB: $root is stamped absolute
assert `"$raw"'       == `"`W'/Demo2/01_raw"'
assert `"$converted"' == `"`W'/Demo2/01_raw/_converted"'
assert `"$cleaned"'   == `"`W'/Demo2/02_cleaned"'
assert `"$output"'    == `"`W'/Demo2/03_output"'
assert `"$code"'      == `"`W'/Demo2/_code"'
assert `"$docs"'      == `"`W'/Demo2/_documentation"'
foreach g in root raw converted cleaned output code docs {
    confirm file "${`g'}/."
}

*=======================================================================*
* v2.0.1 REGRESSION TESTS                                               *
* One test per defect fixed in 2.0.1.  Each says what used to happen.   *
*=======================================================================*

* TEST k ran the generated control file, which begins with -clear all-.
* That drops the globals, the helper programs, and the adopath addition made
* at the top of this file.  Locals survive it, so put everything back from
* the copies TEST k stashed.
global work    `"`W'"'
global pkgroot `"`PK'"'
adopath ++ "$pkgroot"
capture program drop loadlines
program define loadlines
    import delimited using `0', clear delimiters("`=char(1)'", asstring) ///
        varnames(nonames) bindquote(nobind) encoding("utf-8")
end
confirm file "$work/."
di as text `"test_projectbuilder: resumed with work = $work"'

di as text "{hline 70}"
di as text "TEST l: the auto-convert pass leaves the data in memory alone"
di as text "{hline 70}"
* Used to: -convertanything, clear- and -combineall- ran in the caller's
* frame, so scaffolding a project threw away the user's dataset silently.
projectbuilder MemKeep, path("$work") description("memory guard")
clear
set obs 3
gen str9 fixture_only = "fixture"
quietly export delimited using "$work/MemKeep/01_raw/fixture.csv", replace

sysuse auto, clear
local n_before = _N
local k_before = c(k)
quietly projectbuilder MemKeep, path("$work") rebuild
confirm variable make                     // the user's data is still here
assert _N == `n_before'
assert c(k) == `k_before'
capture confirm variable fixture_only     // and the fixture did NOT land in memory
assert _rc != 0

* noautoconvert leaves memory alone too (it never runs the pass at all)
sysuse auto, clear
quietly projectbuilder MemKeep, path("$work") rebuild noautoconvert
confirm variable make
assert _N == `n_before'

di as text "{hline 70}"
di as text "TEST m: a backtick is refused before anything is created"
di as text "{hline 70}"
* Used to: the run got as far as building the folder tree, then died with a
* bare "invalid syntax".  The half-built folder then blocked the corrected
* re-run with 602, so the user could not simply fix the typo and retry.
capture noisily projectbuilder Tick, path("$work") description("don`t do this")
assert _rc == 198
capture confirm file "$work/Tick/."
assert _rc != 0                            // no folder was left behind
capture confirm file "$work/Tick/_code/000_control.do"
assert _rc != 0
* so the corrected call succeeds instead of hitting the clobber guard
projectbuilder Tick, path("$work") description("dont do this")
assert r(rebuilt) == 0
confirm file "$work/Tick/_code/000_control.do"
* every free-text option is checked, not just description()
foreach o in topic timeline othernotes url {
    capture projectbuilder TickB, path("$work") `o'("bad`=char(96)'value")
    assert _rc == 198
}
capture confirm file "$work/TickB/."
assert _rc != 0

di as text "{hline 70}"
di as text "TEST n: a tilde survives into the generated files"
di as text "{hline 70}"
* Used to: pb_wl substituted its own ~D/~B markers on the finished line, so
* url("https://example.edu/~Dave/data.csv") was written out as
* ".../$ave/data.csv" -- silently, and only in the do-files, so the docs and
* the code disagreed.
projectbuilder Tilde, path("$work") noautoconvert ///
    url("https://example.edu/~Dave/data.csv") description("~Daily refresh")
loadlines "$work/Tilde/_code/100_data_download.do"
quietly count if strpos(v1, "https://example.edu/~Dave/data.csv")
assert r(N) >= 1
* NB: write the dollar sign with char(36).  A literal "$ave" in this do-file
* would be expanded as a global by Stata before -strpos- ever saw it, and
* strpos(v1, "") is 1 for every row, so the assert would pass vacuously.
quietly count if strpos(v1, char(36) + "ave")
assert r(N) == 0
loadlines "$work/Tilde/_documentation/index.do"
quietly count if strpos(v1, "wput ~Daily refresh")
assert r(N) == 1
* the docs agree with the code
loadlines "$work/Tilde/_documentation/Readme.md"
quietly count if strpos(v1, "~Daily refresh")
assert r(N) >= 1

* The markers themselves still work: the control file really does get $ and `.
* NB: do NOT assert that "~D" is absent from this file.  The description is
* stamped into its header, so a description of "~Daily refresh" puts a real
* "~D" there -- which is the point.  Check the markers pb_wl owns instead.
loadlines "$work/Tilde/_code/000_control.do"
quietly count if strpos(v1, "global raw")
assert r(N) == 1
foreach mark in "~Draw" "~Dcode" "~Dcleaned" "~Broot" "~Brun_all" {
    quietly count if strpos(v1, "`mark'")
    assert r(N) == 0
}
* and the user's own tilde survived into the header
quietly count if strpos(v1, "~Daily refresh")
assert r(N) == 1

di as text "{hline 70}"
di as text "TEST o: a relative path() still yields an absolute r(path)/\$root"
di as text "{hline 70}"
* Used to: path() was carried through verbatim, so a relative path produced a
* relative r(path) and a relative -global root- in 000_control.do -- both
* documented as absolute, and the control file has to survive being moved.
local pwd_before `"`c(pwd)'"'
quietly cd "$work"
capture mkdir "relbase"
projectbuilder RelPath, path("relbase")
local rp `"`r(path)'"'
assert substr(`"`rp'"', 1, 1) == "/" | regexm(`"`rp'"', "^[a-zA-Z]:")
confirm file `"`rp'/_code/000_control.do"'
loadlines `"`rp'/_code/000_control.do"'
quietly count if strpos(v1, `"global root ""') & ///
                (strpos(v1, `"global root "/"') | regexm(v1, `"global root "[a-zA-Z]:"'))
assert r(N) == 1
quietly cd `"`pwd_before'"'

* a path() that is already absolute is left alone
projectbuilder AbsPath, path("$work")
assert `"`r(path)'"' == `"$work/AbsPath"'

* a trailing separator on path() must not survive into a doubled one.  NB:
* do not test this by searching r(path) for "//" -- on macOS c(tmpdir) itself
* ends in a slash, so $work already contains one and the test would fail on
* the environment rather than on the code.  Compare against the exact join.
projectbuilder TrailSlash, path("$work/")
assert `"`r(path)'"' == `"$work/TrailSlash"'
confirm file `"$work/TrailSlash/_code/000_control.do"'

di as text "{hline 70}"
di as text "TEST p: _runall.do carries a literal docs path, not \$docs"
di as text "{hline 70}"
* Used to: the generated _runall.do did -cd "$docs"-, but projectbuilder runs
* that file itself under -builddocs-, before 000_control.do has ever run.  So
* $docs was empty and the cd went somewhere else entirely -- in a session
* where another project's control file HAD run, it went to that project.
macro drop docs
projectbuilder Runall, path("$work")
loadlines "$work/Runall/_documentation/_runall.do"
quietly count if strpos(v1, `"local here "$work/Runall/_documentation""')
assert r(N) == 1
* builddocs must not leave the working directory moved
local pwd_before `"`c(pwd)'"'
capture noisily projectbuilder Runall, path("$work") rebuild builddocs
assert `"`c(pwd)'"' == `"`pwd_before'"'

di as text "{hline 70}"
di as text "TEST q: the generated profiler runs under the version 16.0 pin"
di as text "{hline 70}"
* Used to: 400_data_profiler.do emitted -table `g', statistic(...)-, which is
* Stata 17 syntax, while 000_control.do pins -version 16.0-.  The shipped
* pipeline therefore stopped with r(198) on its own generated code.
projectbuilder Prof, path("$work") outcomes(price mpg) over(foreign)
sysuse auto, clear
quietly save "$work/Prof/02_cleaned/Prof_analytic.dta", replace
* run the profiler body under the pin the control file sets, without the
* -clear all- that running 000_control.do itself would do
global root      "$work/Prof"
global cleaned   "$work/Prof/02_cleaned"
capture noisily version 16.0: do "$work/Prof/_code/400_data_profiler.do"
assert _rc == 0

di as text "{hline 70}"
di as text "TEST r: recorded metadata survives \$, ~ and a stray backtick"
di as text "{hline 70}"
* Used to: the read-back did -local `m' `"`mval'"'-, a bare re-expansion.  A
* recorded $ was eaten and the damaged value written back over the original;
* a recorded backtick stopped the run, permanently, on every later rebuild.
* The help file invites hand-editing this file, so it has to survive it.
projectbuilder MetaChar, path("$work") description("placeholder") noautoconvert
tempname mch
file open `mch' using "$work/MetaChar/_documentation/_project_meta.txt", write text replace
file write `mch' ("description=cost is " + char(36) + "M per year, ~Dept share") _n
file write `mch' "created=2026-01-01" _n
file close `mch'
projectbuilder MetaChar, path("$work") rebuild noautoconvert

loadlines "$work/MetaChar/_documentation/Readme.md"
quietly count if strpos(v1, "cost is " + char(36) + "M per year, ~Dept share")
assert r(N) == 1
* and it is written back intact, not silently damaged
loadlines "$work/MetaChar/_documentation/_project_meta.txt"
quietly count if strpos(v1, "description=cost is " + char(36) + "M per year, ~Dept share")
assert r(N) == 1
* the recorded created date is honoured rather than restamped with today
loadlines "$work/MetaChar/_documentation/Readme.md"
quietly count if strpos(v1, "| Created | 2026-01-01 |")
assert r(N) == 1

* a backtick in the file is skipped with a note; the rebuild still finishes
file open `mch' using "$work/MetaChar/_documentation/_project_meta.txt", write text replace
file write `mch' ("description=Booth" + char(96) + "s cohort") _n
file write `mch' "topic=survey" _n
file close `mch'
capture noisily projectbuilder MetaChar, path("$work") rebuild noautoconvert
assert _rc == 0
loadlines "$work/MetaChar/_documentation/Readme.md"
quietly count if strpos(v1, "| Topic | survey |")   // the good keys still load
assert r(N) == 1

di as text "{hline 70}"
di as text "TEST s: a base that cannot be written names the folder, not a do-file"
di as text "{hline 70}"
* Used to: every mkdir was captured and only the BASE was checked, so on a
* read-only base the tree silently failed to appear and the run carried on to
* the first -file open-, stopping with a bare r(603) about a do-file.
capture noisily projectbuilder NoSuchBase, path("$work/missing/deeper")
assert _rc == 601

* An existing but unwritable base is caught at the target, with 693.  Making a
* directory unwritable needs -chmod-, so this half runs on Unix-likes only;
* everything above and below is platform-neutral.  $unixlike is set once here
* and reused by TEST t.
global unixlike = inlist("`c(os)'", "MacOSX", "Unix")
if $unixlike {
    capture mkdir "$work/ro"
    if !_rc {
        shell chmod 555 "$work/ro"
        capture noisily projectbuilder ROproj, path("$work/ro")
        assert _rc == 693
        shell chmod 755 "$work/ro"
    }
}
else di as text "  (skipped the unwritable-base half: needs chmod)"

di as text "{hline 70}"
di as text "TEST t: data() reports files it could not copy"
di as text "{hline 70}"
* Used to: -capture copy- swallowed the failure and only successes were
* counted, so an unreadable source file dropped out of the analytic file and
* the run still printed OK.
mkdir "$work/_src3"
sysuse auto, clear
quietly export delimited using "$work/_src3/ok1.csv", replace
quietly export delimited using "$work/_src3/ok2.csv", replace

* Making a file unreadable needs -chmod-, so the skip-and-report half is
* Unix-only.  On Windows, check the platform-neutral half instead: every
* readable file is copied and counted.
if $unixlike {
    quietly export delimited using "$work/_src3/locked.csv", replace
    shell chmod 000 "$work/_src3/locked.csv"
    capture noisily projectbuilder Skipper, path("$work") data("$work/_src3") noautoconvert
    assert r(nraw) == 2
    capture confirm file "$work/Skipper/01_raw/locked.csv"
    assert _rc != 0
    shell chmod 644 "$work/_src3/locked.csv"
}
else {
    capture noisily projectbuilder Skipper, path("$work") data("$work/_src3") noautoconvert
    assert r(nraw) == 2
    di as text "  (skipped the unreadable-file half: needs chmod)"
}
confirm file "$work/Skipper/01_raw/ok1.csv"
confirm file "$work/Skipper/01_raw/ok2.csv"

di as text "{hline 70}"
di as text "TEST u: pb_count survives a folder it cannot list"
di as text "{hline 70}"
* Used to: -local list : dir- inside the counter was uncaptured, so a missing
* or clobbered 01_raw/_converted aborted the whole run with a bare r(601).
projectbuilder Counted, path("$work") noautoconvert
capture rmdir "$work/Counted/01_raw/_converted"
* put a plain FILE where the folder should be: -: dir- errors on that too
tempname ffh
file open `ffh' using "$work/Counted/01_raw/_converted", write text replace
file write `ffh' "not a directory" _n
file close `ffh'
capture noisily projectbuilder Counted, path("$work") rebuild noautoconvert
assert _rc == 0
assert r(nconverted) == 0

di as text "{hline 70}"
di as text "TEST v: the documented examples run as written"
di as text "{hline 70}"
* The Examples section of projectbuilder.sthlp is meant to be runnable top to
* bottom in one directory.  It used to re-scaffold a project an earlier
* section had already created, so reading the help and typing along hit 602.
*
* Run them from a directory whose name contains a space.  That is the ordinary
* case on Windows ("C:\Users\First Last\...") and on Mac ("~/My Drive/..."),
* and it is where an unquoted path in generated code shows up.
mkdir "$work/_help ex"
local pwd_before `"`c(pwd)'"'
quietly cd "$work/_help ex"

projectbuilder Ex01Feed, description("Monthly vendor extract")
confirm file "Ex01Feed/_documentation/Readme.md"
projectbuilder Ex02Feed, path("projects")
projectbuilder Agency/Extract, description("One agency extract")
assert `"`r(project)'"' == "Agency_Extract"
projectbuilder "Vendor Feed 2027", description("Quoted name")
assert `"`r(project)'"' == "Vendor Feed 2027"
projectbuilder Ex01Feed, rebuild
projectbuilder Ex01Feed, rebuild topic("procurement")
projectbuilder Ex01Feed, rebuild replace
projectbuilder Ex03Rates, outcomes(enroll_rate cost_pp) over(year region)

mkdir "drop"
sysuse auto, clear
quietly export delimited using "drop/auto.csv", replace
quietly projectbuilder Ex04Auto, data("drop")
assert `"`r(project)'"' == "Ex04Auto"
assert r(nraw) == 1
assert `"`r(path)'"' != ""
* the two -display- lines exactly as the help prints them: r() macros have to
* resolve inside an expression, not just via `r(name)' macro quoting
capture noisily display "built " r(project) " with " r(nraw) " raw file(s)"
assert _rc == 0
capture noisily display "it lives at " r(path)
assert _rc == 0

* the every-option call, reusing the drop/ folder the previous example made
projectbuilder Ex07Budgets,                                      ///
    data("drop")                                                 ///
    description("County budget CSVs, one row per dept per FY")   ///
    topic("local government, budgets") publicfacing(unsure)      ///
    timeline("annual") outcomes(total_budget) over(year dept)    ///
    descsave
assert r(nraw) == 1
loadlines "Ex07Budgets/_code/300_labels.do"
quietly count if strpos(v1, "_codebook.dta")
assert r(N) >= 1                    // descsave really did seed 300_labels.do
loadlines "Ex07Budgets/_code/400_data_profiler.do"
quietly count if strpos(v1, `"local outcomes "total_budget""')
assert r(N) == 1

* a url() that cannot be reached must still leave a complete scaffold
capture noisily projectbuilder Ex08Open, url("https://example.com/data.csv")
assert _rc == 0
confirm file "Ex08Open/_code/000_control.do"
confirm file "Ex08Open/_documentation/website/index.html"
loadlines "Ex08Open/_code/100_data_download.do"
quietly count if strpos(v1, "https://example.com/data.csv")
assert r(N) >= 1                    // the fetch is recorded either way

projectbuilder Ex05Feed, noautoconvert
projectbuilder Ex01Feed, rebuild builddocs
projectbuilder Ex06Cost, description("Reported in \$ millions")
loadlines "Ex06Cost/_documentation/Readme.md"
quietly count if strpos(v1, "Reported in " + char(36) + " millions")
assert r(N) == 1

* the refresh-everything loop from the Examples section
foreach p in Ex01Feed Ex03Rates Ex04Auto {
    capture noisily projectbuilder `p', rebuild
    assert _rc == 0
}

* Because the base held a space, every path the scaffold wrote had to be
* quoted.  Prove the generated control file actually runs from here.
do "Ex01Feed/_code/000_control.do"
foreach g in root raw converted cleaned output code docs {
    confirm file "${`g'}/."
}
assert strpos("$root", " ")            // the space really did survive
quietly cd `"`pwd_before'"'

* -do 000_control.do- ran -clear all- again; restore the harness.
global work    `"`W'"'
global pkgroot `"`PK'"'
adopath ++ "$pkgroot"
capture program drop loadlines
program define loadlines
    import delimited using `0', clear delimiters("`=char(1)'", asstring) ///
        varnames(nonames) bindquote(nobind) encoding("utf-8")
end

di as text "{hline 70}"
di as text "TEST w: the Try-it-now walkthrough runs as written"
di as text "{hline 70}"
* Every clickable line in the help file's Try it now section, in order, using
* the same path("`c(tmpdir)'") the help file uses.  The walkthrough deliberately
* never calls -cd-, so this must not either: if any step secretly depended on
* the working directory, it would show up here.
local pwd_before `"`c(pwd)'"'

* c(tmpdir) survives between Stata sessions, so a previous run of this battery
* (or of the walkthrough itself) may have left pbdemo behind.  That is exactly
* the 602 the help file warns about in its opening note, so assert the warning
* is accurate, then continue as the note tells the reader to.
global c_tmpdir `"`c(tmpdir)'"'
mata: st_local("pbleft", strofreal(direxists(st_global("c_tmpdir") + "pbdemo")))
local step1 ""
if `pbleft' {
    capture noisily projectbuilder pbdemo, path("`c(tmpdir)'") ///
        description("A walkthrough") topic(demo) publicfacing(no)
    assert _rc == 602               // the help's opening note is correct
    local step1 "rebuild"
    di as text "  (pbdemo already existed; continuing with rebuild, as the help says)"
}

* Step 1
projectbuilder pbdemo, path("`c(tmpdir)'") `step1' ///
    description("A walkthrough") topic(demo) publicfacing(no)
* Step 2 -- r(path) is what every later step leans on
global pbdemo "`r(path)'"
assert `"$pbdemo"' != ""
assert substr(`"$pbdemo"', 1, 1) == "/" | regexm(`"$pbdemo"', "^[a-zA-Z]:")
* Step 3
confirm file "$pbdemo/_code/000_control.do"
confirm file "$pbdemo/_documentation/Readme.md"
* Step 4
sysuse auto, clear
quietly export delimited using "$pbdemo/01_raw/auto.csv", replace
* Step 5 -- and its claim that -describe- still shows the auto data
projectbuilder pbdemo, path("`c(tmpdir)'") rebuild
confirm variable make
assert _N == 74
* Step 6 -- both guards
capture noisily projectbuilder pbdemo, path("`c(tmpdir)'")
assert _rc == 602
capture noisily projectbuilder pbdemo2, path("`c(tmpdir)'") publicfacing(maybe)
assert _rc == 198
capture confirm file "`c(tmpdir)'pbdemo2/."
assert _rc != 0                             // "before anything is created"
* Step 7 -- the topic changes, the rest survives
projectbuilder pbdemo, path("`c(tmpdir)'") rebuild topic("procurement")
loadlines "$pbdemo/_documentation/Readme.md"
quietly count if strpos(v1, "| Topic | procurement |")
assert r(N) == 1
quietly count if strpos(v1, "A walkthrough")
assert r(N) >= 1
* Step 8 -- the control file runs and its globals are real directories
do "$pbdemo/_code/000_control.do"
foreach g in root raw converted cleaned output code docs {
    confirm file "${`g'}/."
}
* the walkthrough never moved the working directory
assert `"`c(pwd)'"' == `"`pwd_before'"'

* restore the harness after that -clear all-
global work    `"`W'"'
global pkgroot `"`PK'"'
adopath ++ "$pkgroot"
capture program drop loadlines
program define loadlines
    import delimited using `0', clear delimiters("`=char(1)'", asstring) ///
        varnames(nonames) bindquote(nobind) encoding("utf-8")
end

di as text "{hline 70}"
di as text "TEST x0: Workflow A and the Quick start run exactly as printed"
di as text "{hline 70}"
* Workflow A's worked example used to read from a folder called budget_drop
* that the help never told you to create, so the first thing a reader ran
* produced an empty project and a green OK.  Step 1 now makes the folder.
mkdir "$work/_wfa"
local pwd_before `"`c(pwd)'"'
quietly cd "$work/_wfa"

* Workflow A, Step 1 as printed
mkdir "budget_drop"
sysuse auto, clear
quietly export delimited using "budget_drop/budgets_fy24.csv", replace
quietly export delimited using "budget_drop/budgets_fy25.csv", replace
* Workflow A, Step 2 as printed
projectbuilder CountyBudgets,                                  ///
      data("budget_drop")                                      ///
      description("County budget CSVs, one row per dept per FY") ///
      topic("local government, budgets") publicfacing(unsure)  ///
      timeline("annual") outcomes(total_budget) over(year dept) ///
      descsave
assert r(nraw) == 2                       // the files really were ingested
confirm file "CountyBudgets/01_raw/budgets_fy24.csv"
confirm file "CountyBudgets/01_raw/budgets_fy25.csv"
* Workflow A, Step 3 as printed
do "CountyBudgets/_code/000_control.do"
foreach g in root raw converted cleaned output code docs {
    confirm file "${`g'}/."
}
quietly cd `"`pwd_before'"'
global work    `"`W'"'
global pkgroot `"`PK'"'
adopath ++ "$pkgroot"
capture program drop loadlines
program define loadlines
    import delimited using `0', clear delimiters("`=char(1)'", asstring) ///
        varnames(nonames) bindquote(nobind) encoding("utf-8")
end

* the Quick start block: two alternatives, then the refresh
mkdir "$work/_qs"
local pwd_before `"`c(pwd)'"'
quietly cd "$work/_qs"
projectbuilder MyProject, description("What this project is for")
capture noisily projectbuilder MyProject, data("nothing_here") ///
    description("What this project is for")
assert _rc == 602                         // the help says exactly this
projectbuilder MyProject, rebuild
assert r(rebuilt) == 1
quietly cd `"`pwd_before'"'

di as text "{hline 70}"
di as text "TEST x: what a first-time user is told when the companions are absent"
di as text "{hline 70}"
* A new user on a bare install has neither convertanything nor combineall, so
* nothing is converted and no analytic file appears.  The summary used to end
* "projectbuilder OK" and then tell them to "Review 02_cleaned/<proj>_analytic
* .dta" -- a file that was never created.  Drop PLUS from the adopath to
* reproduce a bare install even on a machine where the companions ARE present.
* Drop PLUS to simulate a machine without the optional companions.  Remember
* where it was: -adopath - PLUS- is not undone by anything later in this file,
* and forgetting to put it back silently disables convertanything, combineall,
* descsave and webdoc2 for EVERY test after this one -- which quietly turned
* their checks into no-ops.
local pk       `"$pkgroot"'
local plusdir  `"`c(sysdir_plus)'"'
adopath - PLUS
capture which convertanything
local haveconv = (_rc == 0)
assert !`haveconv'                       // PLUS really is off the path now

mkdir "$work/_bare"
sysuse auto, clear
quietly export delimited using "$work/_bare/a.csv", replace
projectbuilder Bare, path("$work") data("$work/_bare")
assert r(nraw) == 1
assert r(nconverted) == 0
capture confirm file "$work/Bare/02_cleaned/Bare_analytic.dta"
assert _rc != 0                          // there is genuinely no analytic file
* the scaffold is still complete -- that is the promise of a no-dependency tool
confirm file "$work/Bare/_code/000_control.do"
confirm file "$work/Bare/_documentation/website/index.html"
* Put PLUS back before anything else runs, then the package copy on top of it.
adopath ++ `"`plusdir'"'
adopath ++ `"`pk'"'
capture which convertanything
assert _rc == 0                          // the companions are reachable again

di as text "{hline 70}"
di as text "TEST y: data() that does not exist is reported, not glossed over"
di as text "{hline 70}"
* Workflow A's first worked example used to be run verbatim against a folder
* that did not exist; the run said so in passing and then printed OK, so the
* reader's first project was empty and looked successful.
capture noisily projectbuilder Missing, path("$work") data("$work/no_such_drop")
assert _rc == 0                          // still a usable scaffold
assert r(nraw) == 0
confirm file "$work/Missing/_code/000_control.do"

di as text "{hline 70}"
di as text "TEST z: rebuild on a project that is not there says so"
di as text "{hline 70}"
* -rebuild- on a missing project scaffolds one rather than erroring, which is
* what makes it safe in a scheduled script.  A mistyped name therefore looks
* like a successful refresh unless the run says otherwise.  r(rebuilt)
* distinguishes the two cases.
capture noisily projectbuilder NeverMade, path("$work") rebuild
assert _rc == 0
assert r(rebuilt) == 0                   // scaffolded, NOT refreshed
confirm file "$work/NeverMade/_code/000_control.do"
* and a real refresh does report 1
projectbuilder NeverMade, path("$work") rebuild
assert r(rebuilt) == 1

* the -replace- gotcha the Options section now warns about: an option that
* changes a guarded do-file needs -replace- to take effect
projectbuilder Guarded, path("$work")
projectbuilder Guarded, path("$work") rebuild descsave
loadlines "$work/Guarded/_code/300_labels.do"
quietly count if strpos(v1, "_codebook.dta")
assert r(N) == 0                         // bare rebuild leaves _code/ alone
projectbuilder Guarded, path("$work") rebuild replace descsave
loadlines "$work/Guarded/_code/300_labels.do"
quietly count if strpos(v1, "_codebook.dta")
assert r(N) >= 1                         // with replace, it lands

di as text "{hline 70}"
di as text "TEST aa: what the run prints back can be pasted straight back in"
di as text "{hline 70}"
* The "Rerun:" line printed the name bare, so a project called
* "Vendor Feed 2027" produced a command projectbuilder itself rejects with
* "too many project names".  Two separate readers hit this.
* NB: use a NAMED log -- -log close _all- would close the batch log this whole
* battery is written to, and -quietly- would keep the very lines under test out
* of it.  Widen linesize first: the hint carries an absolute path and the log
* would otherwise wrap it onto a continuation line, defeating any match.
local ls_before = c(linesize)
set linesize 250

projectbuilder "Spaced Name 2027", path("$work") description("quoted name")

log using "$work/rerun.log", replace text name(pbcap)
projectbuilder "Spaced Name 2027", path("$work") rebuild
log close pbcap
loadlines "$work/rerun.log"
* the one line a user is most likely to copy must be runnable as printed:
* quoted name, and the path() they built with
quietly count if strpos(v1, "Rerun:") & ///
                strpos(v1, `"projectbuilder "Spaced Name 2027""') & ///
                strpos(v1, `"path("$work")"') & strpos(v1, "rebuild")
assert r(N) == 1
* and never the bare, unpasteable form
quietly count if strpos(v1, "Rerun:") & strpos(v1, "projectbuilder Spaced Name 2027,")
assert r(N) == 0

* A name without a space is printed bare -- but path() is printed EVEN WHEN THE
* USER DID NOT TYPE IT.  That is deliberate: the base is absolute by this point,
* so the hint runs from any directory.  Printing it only when path() was typed
* meant that a project built in the current directory produced a hint which,
* pasted anywhere else, scaffolded a second empty project.
local pwd_before `"`c(pwd)'"'
quietly cd "$work"
projectbuilder Plain
log using "$work/rerun2.log", replace text name(pbcap)
projectbuilder Plain, rebuild
log close pbcap
quietly cd `"`pwd_before'"'
loadlines "$work/rerun2.log"
quietly count if strpos(v1, "Rerun:") & strpos(v1, "projectbuilder Plain,") & ///
                strpos(v1, "path(") & strpos(v1, "rebuild")
assert r(N) == 1
* the name itself is still unquoted when it has no space
quietly count if strpos(v1, "Rerun:") & strpos(v1, char(34) + "Plain" + char(34))
assert r(N) == 0
set linesize `ls_before'

di as text "{hline 70}"
di as text "TEST bb: descsave is remembered like every other recorded option"
di as text "{hline 70}"
* descsave was the one option missing from _project_meta.txt, so a bare
* rebuild reported "Descsave: no" and -rebuild replace- deleted the codebook
* call it had originally written.
projectbuilder Cb, path("$work") description("codebook") descsave noautoconvert
loadlines "$work/Cb/_code/300_labels.do"
quietly count if strpos(v1, "_codebook.dta")
assert r(N) >= 1
loadlines "$work/Cb/_documentation/_project_meta.txt"
quietly count if strpos(v1, "descsave=descsave")
assert r(N) == 1
* a bare rebuild keeps it on record ...
projectbuilder Cb, path("$work") rebuild noautoconvert
loadlines "$work/Cb/_documentation/_project_meta.txt"
quietly count if strpos(v1, "descsave=descsave")
assert r(N) == 1
* ... and -rebuild replace- rewrites 300_labels.do WITH the call still in it
projectbuilder Cb, path("$work") rebuild replace noautoconvert
loadlines "$work/Cb/_code/300_labels.do"
quietly count if strpos(v1, "_codebook.dta")
assert r(N) >= 1

di as text "{hline 70}"
di as text "TEST cc: publicfacing() trims, othernotes is echoed, description reaches _code/"
di as text "{hline 70}"
* publicfacing("yes ") used to be rejected with 198 over one trailing space
projectbuilder Pf, path("$work") publicfacing("Yes ") ///
    othernotes("sent by the county in August") description("A tidy description")
loadlines "$work/Pf/_documentation/Readme.md"
quietly count if strpos(v1, "| Public-facing | yes |")
assert r(N) == 1
* the help says description() reaches the pipeline headers -- check that it does
loadlines "$work/Pf/_code/000_control.do"
quietly count if strpos(v1, "A tidy description")
assert r(N) == 1

di as text "{hline 70}"
di as text "TEST dd: every generated do-file actually RUNS"
di as text "{hline 70}"
* The battery used to check what the generated files CONTAIN, and ran only
* 000_control.do.  That let a real defect ship in 300_labels.do: the descsave
* block passed a -replace- option that -descsave- does not have, so on any
* machine where descsave IS installed the file stopped with r(198).  The
* "not installed" branch is what everyone else hits, which is why nobody saw
* it.  Run all seven, in order, and require rc 0 from each.
mkdir "$work/_gen"
local pwd_before `"`c(pwd)'"'
quietly cd "$work/_gen"

projectbuilder Gen, description("generated-pipeline check") ///
    topic("testing") publicfacing(no) timeline("annual")    ///
    outcomes(price mpg) over(foreign) descsave
sysuse auto, clear
quietly export delimited using "Gen/01_raw/auto_a.csv", replace
keep make price mpg foreign
quietly export delimited using "Gen/01_raw/auto_b.csv", replace
quietly projectbuilder Gen, rebuild

* 300 onward read the analytic file, which only exists if the companions are
* installed.  Seed it by hand when they are not, so the pipeline is exercised
* on every machine rather than only on the author's.
capture confirm file "Gen/02_cleaned/Gen_analytic.dta"
if _rc {
    sysuse auto, clear
    quietly save "Gen/02_cleaned/Gen_analytic.dta", replace
    di as text "  (seeded the analytic file: companions absent on this machine)"
}

local genpwd `"`c(pwd)'"'
foreach f in 000_control.do 100_data_download.do 200_data_management.do ///
             300_labels.do 400_data_profiler.do 500_aggregation.do     ///
             600_analysis.do {
    capture noisily do "`genpwd'/Gen/_code/`f'"
    local generc = _rc
    adopath ++ "$pkgroot"          // each control-file run drops the addition
    if `generc' di as err "  FAILED: `f' returned r(`generc')"
    assert `generc' == 0
}
di as text "  all seven generated do-files ran"
* 000_control.do ran -clear all-, which dropped the helper program; restore it
capture program drop loadlines
program define loadlines
    import delimited using `0', clear delimiters("`=char(1)'", asstring) ///
        varnames(nonames) bindquote(nobind) encoding("utf-8")
end

* descsave really produced something, and left the analytic data loaded
capture which descsave
if !_rc {
    confirm file "`genpwd'/Gen/_documentation/Gen_codebook.dta"
    di as text "  descsave wrote the codebook dataset"
}

* no file-writer marker survived into any generated file
foreach f in _code/000_control.do _code/100_data_download.do            ///
             _code/200_data_management.do _code/300_labels.do           ///
             _code/400_data_profiler.do _code/500_aggregation.do        ///
             _code/600_analysis.do _documentation/index.do              ///
             _documentation/_runall.do {
    loadlines "`genpwd'/Gen/`f'"
    quietly count if strpos(v1, "~D") | strpos(v1, "~B")
    assert r(N) == 0
}
di as text "  no ~D/~B markers left anywhere in the generated files"
quietly cd `"`pwd_before'"'
global work    `"`W'"'
global pkgroot `"`PK'"'
adopath ++ "$pkgroot"

di as text "{hline 70}"
di as text "TEST ee: builddocs renders into website/, or says why it could not"
di as text "{hline 70}"
* Two bugs lived here.  webdoc2 writes index.html BESIDE index.do, so the
* rendered page never reached website/index.html -- which is the page the run
* points you at and the one the built-in fallback writes.  And the generated
* _runall.do swallowed webdoc2's error, so every render reported success.
*
* The render also needs webdoc2's header.html, which webdoc2 ships as an
* ANCILLARY file: -net install webdoc2- never places it.  _runall.do therefore
* looks for it before it cd's into _documentation/ and borrows a copy.
mkdir "$work/_docs"
local pwd_before `"`c(pwd)'"'
quietly cd "$work/_docs"

projectbuilder Rendered, description("builddocs check") topic("docs")

capture which webdoc2
local havewd2 = (_rc == 0)
capture findfile "header.html"
local havehdr = (_rc == 0)

capture noisily projectbuilder Rendered, rebuild builddocs
assert _rc == 0                              // never fatal, either way
confirm file "Rendered/_documentation/website/index.html"

if `havewd2' & `havehdr' {
    * The render should have succeeded and landed in website/.
    loadlines "Rendered/_documentation/website/index.html"
    quietly count if strpos(lower(v1), "bootstrap")
    assert r(N) >= 1                         // it is the webdoc2 page ...
    quietly count if strpos(v1, "Install webdoc2 for a richer")
    assert r(N) == 0                         // ... not the built-in fallback
    * and the borrowed header was not left lying in the project
    capture confirm file "Rendered/_documentation/header.html"
    assert _rc != 0
    di as text "  webdoc2 rendered into website/index.html"
}
else {
    * Without webdoc2, or without its header.html, the built-in page must
    * survive intact -- that is the whole promise of the fallback.
    loadlines "Rendered/_documentation/website/index.html"
    quietly count if strpos(v1, "Install webdoc2 for a richer")
    assert r(N) == 1
    di as text "  (webdoc2/header.html unavailable; checked the fallback instead)"
}
quietly cd `"`pwd_before'"'

di as text ""
di as text "{hline 70}"
di as text "projectbuilder v2.0.1: ALL TESTS PASSED"
di as text "{hline 70}"
