*! example_usepackage.do -- a tour of usepackage 2.0.0
*! Eric A. Booth, Sr Researcher, Texas 2036 <eric.a.booth@gmail.com>
*!
*! Run this from a scratch directory: several steps drop ancillary files and
*! datasets into the CURRENT directory, which is where Stata puts them.
*!
*!     . cd "some/empty/folder"
*!     . do example_usepackage.do
*!
*! Nothing here is destructive, but steps marked LIVE do install packages.

version 16.0

*==========================================================================
* 1. The everyday use: one line instead of a stack of install commands
*==========================================================================

* dryrun first -- see the plan without changing anything
usepackage estout coefplot fre statplot, dryrun

* r() lets a do-file stop early rather than fail obscurely later
di "requested = " r(nreq) ", resolvable = " r(nok) ", unresolved = " r(nfail)

* LIVE: actually install them (already-installed ones are left alone)
* usepackage estout coefplot fre statplot


*==========================================================================
* 2. When the name is a COMMAND, not a PACKAGE
*==========================================================================

* dropmiss ships inside package dm89_2; bacon inside st0197.  usepackage works
* that out, but the mapping is inferred, so it asks first.  Interactively you
* get a y/n prompt; in a batch run it declines and tells you why.
usepackage dropmiss, dryrun
usepackage bacon, dryrun

* accept inferred matches without being asked (what you want unattended)
* usepackage dropmiss bacon, noconfirm

* a misspelling only resolves with -nearest-, and still asks
usepackage statplo, dryrun
usepackage statplo, nearest dryrun


*==========================================================================
* 3. Ancillary files
*==========================================================================

* Stata splits a package in two.  Installation files (.ado, .sthlp, ...) go on
* the adopath.  Ancillary files (.do, .dta, .csv, .xlsx, ...) do NOT -- they only
* arrive with -net get- and they land in the CURRENT directory.  That is why
* -findit spmap- shows two separate links.
*
* flowbca (Stata Journal st0535) is the extreme case: 2 installation files
* against 26 ancillary example datasets and do-files.

* default: ancillary files come too, and usepackage says how many
* usepackage flowbca, noconfirm

* noancillary: keep the working directory clean, and be told what you skipped
usepackage flowbca, noconfirm noancillary dryrun


*==========================================================================
* 4. Packages on GitHub
*==========================================================================

* A GitHub repository is installable when it carries stata.toc + <pkg>.pkg.
* usepackage probes branch (main, then master) and the usual layouts, so you
* do not have to work out the raw URL.

* LIVE: applyvarlabels ships 2 ancillary example files, which arrive too
usepackage applyvarlabels, github("ericabooth/applyvarlabels-stata-public")

* the same thing without the examples
* usepackage applyvarlabels, github("ericabooth/applyvarlabels-stata-public") noancillary

* sparkta2's D3 / TopoJSON assets are ancillary by extension, so they come along
* usepackage sparkta2, github("texas-2036/sparkta2-stata-public")

* all of these forms are accepted:
*   github("owner/repo")                      plain
*   github("https://github.com/owner/repo")   pasted URL
*   github("owner/repo#dev")                  pin a branch
*   github("owner/repo:ado")                  files live in ado/


*==========================================================================
* 5. Data from GitHub
*==========================================================================

* name the file you want and load it in one step
usepackage, data("datasets/gdp") files("data/gdp.csv") useit
list in 1/5
di "gdp.csv: " _N " obs, " c(k) " vars"

* Git LFS: the raw endpoint serves a 130-byte TEXT POINTER for LFS-tracked
* files, so a plain -copy- appears to work and leaves a file Stata cannot read
* ("not Stata format", r(610)).  usepackage spots the pointer and re-fetches
* from GitHub's media endpoint instead.
usepackage, data("scunning1975/mixtape") files("nsw_mixtape.dta") useit
di "nsw_mixtape.dta: " _N " obs, " c(k) " vars"

* older repositories are still on master; usepackage finds whichever is live
usepackage, data("fivethirtyeight/data") ///
    files("airline-safety/airline-safety.csv") useit
di "airline-safety.csv: " _N " obs, " c(k) " vars"

* several files, into a subdirectory of their own
cap mkdir data
usepackage, data("scunning1975/mixtape") ///
    files("nsw_mixtape.dta cps_mixtape.dta") into("data")

* name no files and usepackage lists what a repository holds and asks before
* downloading in bulk (dryrun here so nothing is fetched)
usepackage, data("datasets/population") dryrun


*==========================================================================
* 6. Packages and data in one call
*==========================================================================

usepackage estout coefplot, data("datasets/gdp") files("data/gdp.csv") dryrun


*==========================================================================
* 7. Auditing a do-file before you send it to someone
*==========================================================================

* write a small do-file that leans on user-written commands
tempfile scratch
qui file open fh using "sample_for_scan.do", write text replace
file write fh "sysuse auto, clear" _n
file write fh "summarize price mpg" _n
file write fh "regress price mpg weight" _n
file write fh "quietly estout using out.txt" _n
file write fh "capture noisily coefplot" _n
file write fh "egen tot = total(price)" _n
file write fh "zzzmadeupcommand foo" _n
qui file close fh

* scan reports what a collaborator would be missing.  Built-ins (sysuse,
* summarize, regress, egen) are not flagged; quietly/capture prefixes are
* stripped before the command name is read.  scan reports only -- it never
* installs.
usepackage, scan("sample_for_scan.do")

erase sample_for_scan.do


*==========================================================================
* 8. The pattern worth copying into a real project
*==========================================================================

/*
    At the top of a shared do-file:

        cap ssc install usepackage
        usepackage estout coefplot reghdfe, noconfirm
        if r(nfail) > 0 {
            di as error "missing packages: `r(unresolved)'"
            exit 601
        }

    and if the analysis needs data that lives in a repository:

        usepackage, data("myorg/myproject-data") files("clean/analysis.dta") useit
*/

di _n "example_usepackage.do finished."
