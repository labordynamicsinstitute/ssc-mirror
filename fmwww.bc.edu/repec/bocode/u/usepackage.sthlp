{smcl}
{* *! version 2.0.0  25jul2026}{...}
{vieweralsosee "[R] net" "help net"}{...}
{vieweralsosee "[R] ssc" "help ssc"}{...}
{vieweralsosee "[R] search" "help search"}{...}
{viewerjumpto "Syntax" "usepackage##syntax"}{...}
{viewerjumpto "Description" "usepackage##description"}{...}
{viewerjumpto "Options" "usepackage##options"}{...}
{viewerjumpto "Ancillary files" "usepackage##ancillary"}{...}
{viewerjumpto "GitHub packages" "usepackage##github"}{...}
{viewerjumpto "GitHub data" "usepackage##data"}{...}
{viewerjumpto "Pairing with require" "usepackage##require"}{...}
{viewerjumpto "Remarks" "usepackage##remarks"}{...}
{viewerjumpto "Examples" "usepackage##examples"}{...}
{viewerjumpto "Stored results" "usepackage##results"}{...}
{viewerjumpto "Author" "usepackage##author"}{...}
{hline}
help for {hi:usepackage}{right:v 2.0.0}
{hline}

{title:Title}

{p 4 8 2}
{bf:usepackage} {hline 2} find, verify, and install the user-written packages
(and data) a do-file needs


{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:usepackage} {it:pkgname} [{it:pkgname} ...]
[{cmd:,} {it:options}]

{p 8 15 2}
{cmd:usepackage} {it:pkgname} {cmd:,} {cmdab:git:hub(}{it:owner/repo}{cmd:)}
[{it:options}]

{p 8 15 2}
{cmd:usepackage} [{cmd:*}] {cmd:,} {cmdab:git:hub(}{it:owner}{cmd:)}
{c -} list the packages an account or repository ships

{p 8 15 2}
{cmd:usepackage} {cmd:,} {cmd:data(}{it:owner/repo}{cmd:)}
[{cmd:files(}{it:filelist}{cmd:)} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Which packages}
{synopt :{cmdab:u:pdate}}reinstall the listed packages even if already present{p_end}
{synopt :{cmdab:near:est}}also consider similarly {it:named} packages{p_end}
{synopt :{cmd:from(}{it:url}{cmd:)}}install from this net source, skipping the search{p_end}

{syntab:Confirmation and reporting}
{synopt :{cmdab:noconf:irm}}accept inferred matches without asking{p_end}
{synopt :{cmdab:dry:run}}report what would happen; install nothing{p_end}

{syntab:Ancillary files}
{synopt :{cmdab:noanc:illary}}do {it:not} fetch ancillary files (default is to fetch them){p_end}

{syntab:GitHub}
{synopt :{cmdab:git:hub(}{it:owner/repo}{cmd:)}}install a package from a GitHub repository, or from {it:owner} alone to search that account{p_end}
{synopt :{cmdab:gho:wner(}{it:owners}{cmd:)}}accounts to search when a name is on neither SSC nor the catalogue{p_end}
{synopt :{cmd:data(}{it:owner/repo}{cmd:)}}fetch data files from a GitHub repository{p_end}
{synopt :{cmdab:f:iles(}{it:filelist}{cmd:)}}which repository files to fetch{p_end}
{synopt :{cmdab:br:anch(}{it:name}{cmd:)}}branch to use (default: try {cmd:main}, then {cmd:master}){p_end}
{synopt :{cmd:into(}{it:dir}{cmd:)}}directory to fetch data into (default: current){p_end}
{synopt :{cmdab:use:it}}load the fetched dataset when exactly one was fetched{p_end}

{syntab:Auditing a do-file}
{synopt :{cmd:scan(}{it:filename}{cmd:)}}report commands in a do-file that do not resolve{p_end}
{synoptline}


{marker description}{title:Description}

{p 4 4 2}
{cmd:usepackage} takes a list of user-written packages a do-file needs and makes
sure they are installed, so a shared do-file can begin with one line instead of
a stack of {helpb ssc:ssc install} and {helpb net:net install} commands, or a
paragraph of instructions telling the reader to go run {helpb findit}.

{p 4 4 2}
For each name it works through, in order: is it already installed; is it on
{browse "http://repec.org/bocode/s/sscsubmit.html":SSC}; and failing that, does
the {helpb net##search_options:net search} catalogue know it (which covers the
{it:Stata Journal} and the {it:Stata Technical Bulletin}). It reports what it
found, what it skipped, and why, and finishes with a one-line tally.

{p 4 4 2}
The name you ask for is often a {it:command} rather than a {it:package}:
{cmd:dropmiss} ships inside package {cmd:dm89_2}, {cmd:bacon} inside
{cmd:st0197}. {cmd:usepackage} recognises that case, but because the mapping is
{it:inferred} it asks before installing (see {help usepackage##ancillary:below}
and {opt noconfirm}).

{p 4 4 2}
{cmd:usepackage} is partly inspired by the LaTeX command of the same name.


{marker options}{title:Options}

{phang}
{cmdab:u:pdate} reinstalls each listed package even when it is already present.
Without it, an installed package is left alone and reported as such.

{phang}
{cmdab:near:est} widens the search: after looking for a package of that name and
for a package whose description mentions that command, {cmd:usepackage} will also
offer the closest name it saw in the catalogue. Because that match is a guess, it
is always offered for confirmation, never installed silently.

{phang}
{cmd:from(}{it:url}{cmd:)} installs from a net source directly and skips
searching. Use it when you already know where a package lives.

{phang}
{cmdab:noconf:irm} accepts inferred matches without asking. Use it when running
unattended. In a batch run {cmd:usepackage} will {it:not} prompt: without
{opt noconfirm} an inferred match is reported and left uninstalled, rather than
hanging on a question nobody can answer.

{phang}
{cmdab:dry:run} reports what would be installed, from where, and whether
ancillary files are involved, without changing anything. Good for checking a
do-file's dependency list before handing it to someone.

{phang}
{cmdab:noanc:illary} suppresses ancillary files. See
{help usepackage##ancillary:Ancillary files}.

{phang}
{cmdab:git:hub(}{it:owner/repo}{cmd:)} installs a package from a GitHub
repository. See {help usepackage##github:GitHub packages}.

{phang}
{cmd:data(}{it:owner/repo}{cmd:)}, {cmdab:f:iles()}, {cmd:into()},
{cmdab:use:it} fetch data. See {help usepackage##data:GitHub data}.

{phang}
{cmdab:br:anch(}{it:name}{cmd:)} pins the branch. By default {cmd:main} is tried
first, then {cmd:master}.

{phang}
{cmd:scan(}{it:filename}{cmd:)} reads a do-file and lists the commands in it that
do not resolve on this machine, so you can see what a collaborator would be
missing before you send it. It reports; it never installs.


{marker ancillary}{title:Ancillary files}

{p 4 4 2}
Stata splits a package's contents in two. {it:Installation files} are copied onto
your adopath by {helpb net install}. {it:Ancillary files} are not: they arrive
only with {helpb net get}, and they land in the {bf:current directory}. Which is
which is decided purely by extension: {cmd:.ado}, {cmd:.sthlp}, {cmd:.mata},
{cmd:.py} and friends are installed; {cmd:.do}, {cmd:.dta}, {cmd:.csv},
{cmd:.xlsx}, {cmd:.html}, {cmd:.js} are ancillary.

{p 4 4 2}
This is why {cmd:findit spmap} offers two separate links, and why
{cmd:net describe st0535} lists 2 installation files against 26 ancillary ones
(the {cmd:flowbca} examples and their datasets).

{p 4 4 2}
{cmd:usepackage} fetches ancillary files {bf:by default}, on the view that if a
package author shipped worked examples you probably want them. It says how many
arrived. Specify {opt noancillary} to skip them, in which case it tells you how
many exist and how to get them later:

{p 8 8 2}{cmd:. usepackage flowbca, noancillary}{p_end}
{p 8 8 2}{cmd:      26 ancillary file(s) available; noancillary specified, so they were not fetched}{p_end}
{p 8 8 2}{cmd:      to get them later: net get st0535}{p_end}

{p 4 4 2}
{opt noancillary} is worth reaching for when you are installing into a working
directory you would rather not fill with example datasets.


{marker github}{title:GitHub packages}

{p 4 4 2}
{cmd:github()} installs from a GitHub repository. A repository is installable
when it carries a {cmd:stata.toc} and a {it:pkgname}{cmd:.pkg} manifest;
{cmd:usepackage} probes for them rather than making you work out the exact raw
URL. It tries branch {cmd:main} then {cmd:master}, and at each branch looks at
the repository root and then in {cmd:ado/}, {cmd:src/}, {cmd:stata/} and
{cmd:code/}.

{p 4 4 2}
All of these are accepted:

{p 8 8 2}{cmd:. usepackage applyvarlabels, github("ericabooth/applyvarlabels-stata-public")}{p_end}
{p 8 8 2}{cmd:. usepackage sparkta2, github("texas-2036/sparkta2-stata-public")}{p_end}
{p 8 8 2}{cmd:. usepackage mypkg, github("https://github.com/owner/repo")}     // pasted URL{p_end}
{p 8 8 2}{cmd:. usepackage mypkg, github("https://github.com/owner/repo/tree/main")}{p_end}
{p 8 8 2}{cmd:. usepackage mypkg, github("owner/repo.git")}{p_end}
{p 8 8 2}{cmd:. usepackage mypkg, github("owner/repo#dev")}                    // pin a branch{p_end}
{p 8 8 2}{cmd:. usepackage mypkg, github("owner/repo:ado")}                    // files live in ado/{p_end}

{p 4 4 2}
If no {cmd:stata.toc} turns up, {cmd:usepackage} says so and points you at
{cmd:data()}, since a repository of datasets is not a package.

{title:Searching a whole account}

{p 4 4 2}
You usually remember the command, not which repository it sits in. Give
{cmd:github()} a bare {it:owner} and {cmd:usepackage} works it out:

{p 8 8 2}{cmd:. usepackage editanything, github("texas-2036")}{p_end}
{p 8 8 2}{cmd:      searching repositories owned by texas-2036}{p_end}
{p 8 8 2}{cmd:      14 repositor(ies) listed; narrowing by name}{p_end}
{p 8 8 2}{cmd:      matched texas-2036/EditAnything-stata-public in owner texas-2036}{p_end}

{p 4 4 2}
It lists the account's repositories in {bf:one} request against the ordinary
GitHub API (60 an hour), not the code-search API (about 10 a minute), then
narrows by name before probing anything: an exactly matching repository name
first, then names beginning with the package name, then names containing it.

{p 4 4 2}
The distinction that decides whether you are asked: a repository containing a
{it:pkgname}{cmd:.pkg} has {it:declared} that it ships the package, which is
proof rather than resemblance, so it installs. A repository whose name merely
looks right but carries no matching {cmd:.pkg} is offered for confirmation.

{title:Listing what an account (or a repository) ships}

{p 4 4 2}
Leave the package name off, or give {cmd:*}, and {cmd:github()} becomes a
catalogue rather than an install:

{p 8 8 2}{cmd:. usepackage, github("texas-2036")}{p_end}
{p 8 8 2}{cmd:. usepackage *, github("texas-2036")}     // the same thing{p_end}

{p 8 8 2}{cmd:      14 repositor(ies); checking each for a stata.toc...}{p_end}
{p 8 8 2}{cmd:      --------------------------------------------------------}{p_end}
{p 8 8 2}{cmd:      package          repository                      branch}{p_end}
{p 8 8 2}{cmd:      --------------------------------------------------------}{p_end}
{p 8 8 2}{cmd:      driveuse         driveuse-stata-public            main}{p_end}
{p 8 8 2}{cmd:      editanything     EditAnything-stata-public        main}{p_end}
{p 8 8 2}{cmd:      sparkta2         sparkta2-stata-public            main}{p_end}
{p 8 8 2}{cmd:      --------------------------------------------------------}{p_end}
{p 8 8 2}{cmd:      5 package(s) in 5 repositor(ies); 9 have no stata.toc}{p_end}

{p 4 4 2}
The package names come from each repository's {cmd:stata.toc}, which is what
{cmd:net install} itself reads, so the list is what is genuinely installable
rather than a guess from file names. Repositories with no {cmd:stata.toc} are
counted but not listed. Point it at one repository instead to see just that:

{p 8 8 2}{cmd:. usepackage *, github("texas-2036/sparkta2-stata-public")}{p_end}


{title:Searching your own accounts automatically}

{p 4 4 2}
If you keep packages on GitHub, name the accounts once and stop typing
{cmd:github()} at all. Put this in {helpb profile.do}:

{p 8 8 2}{cmd:global usepackage_github "ericabooth texas-2036"}{p_end}

{p 4 4 2}
and any name that is on neither SSC nor the {cmd:net search} catalogue is looked
for in those accounts, in order, before {cmd:usepackage} gives up:

{p 8 8 2}{cmd:. usepackage editanything}{p_end}
{p 8 8 2}{cmd:      not found on SSC, and no match in the net search catalogue}{p_end}
{p 8 8 2}{cmd:      searching repositories owned by ericabooth}{p_end}
{p 8 8 2}{cmd:      matched ericabooth/EditAnything-stata-public in owner ericabooth}{p_end}
{p 8 8 2}{cmd:      installed from https://raw.githubusercontent.com/...}{p_end}

{p 4 4 2}
{cmd:ghowner()} does the same for one call without setting the global. Both mean
a single mixed list can span SSC, the Stata Journal, and your own repositories:

{p 8 8 2}{cmd:. usepackage fre editanything sparkta2}{p_end}


{marker data}{title:GitHub data}

{p 4 4 2}
Plenty of the data a do-file needs now lives in a GitHub repository rather than a
package. {cmd:data()} fetches it. Name the files you want:

{p 8 8 2}{cmd:. usepackage, data("datasets/gdp") files("data/gdp.csv") useit}{p_end}

{p 4 4 2}
or name none and {cmd:usepackage} lists every {cmd:.dta}, {cmd:.csv},
{cmd:.tsv}, {cmd:.xlsx} and {cmd:.txt} it can see and asks before downloading in
bulk. {cmd:useit} loads the result when exactly one file was fetched, choosing
{helpb use}, {helpb import delimited} or {helpb import excel} by extension.

{p 4 4 2}
Two things this handles that a hand-written {helpb copy} does not.

{p 4 4 2}
{bf:Branch guessing.} Older repositories are on {cmd:master}, newer ones on
{cmd:main}; {cmd:usepackage} finds whichever is live.

{p 4 4 2}
{bf:Git LFS.} A repository that tracks large files with Git LFS serves a
130-byte {it:text pointer} from the raw endpoint instead of the data, so a plain
{cmd:copy} appears to succeed and leaves you with a file Stata cannot read
({cmd:not Stata format}, {cmd:r(610)}). {cmd:usepackage} notices the pointer and
silently re-fetches from GitHub's media endpoint, reporting that it did so.


{marker require}{title:Pairing with require (version pinning)}

{p 4 4 2}
{cmd:usepackage} answers {it:"is it here, and if not where does it live?"}. It
does {bf:not} check versions. If you need that {hline 2} and for reproducible
research you do {hline 2} pair it with {bf:require} by Sergio Correia and
Matthew P. Seay ({it:Stata Journal} 24(4):599-613, 2024;
{stata "net describe pr0081, from(https://www.stata-journal.com/software/sj24-4)":pr0081},
also {stata "ssc describe require":on SSC}).

{p 4 4 2}
The two solve different halves of one problem and compose cleanly:

{p 8 8 2}{cmd:. usepackage estout coefplot reghdfe ftools, noconfirm}{p_end}
{p 8 8 2}{cmd:. require reghdfe >= 6.0.0, install}{p_end}
{p 8 8 2}{cmd:. require ftools  >= 2.49.0, install}{p_end}

{p 4 4 2}
{cmd:usepackage} gets the packages there whatever they happen to be called and
wherever they live; {cmd:require} then asserts that the versions are ones your
results were produced under. That second step matters more than it sounds:
newer releases of estimation commands can change point estimates or standard
errors, so "installed" is not the same as "the same".

{p 4 4 2}
Use {cmd:require}'s requirements-file form when a project has several do-files:

{p 8 8 2}{cmd:. require using "requirements.txt", install}{p_end}

{p 4 4 2}
and generate that file from what you currently have with
{cmd:require, list save}. Reach for {cmd:usepackage} first when you do not yet
know what is missing or where it comes from, and for {cmd:require} to hold a
known-good set steady afterwards.

{p 4 4 2}
Division of labour, briefly:

{synoptset 30 tabbed}{...}
{synopt :{bf:usepackage}}discovery {c -} SSC, SJ/STB catalogue, GitHub; command-to-package
resolution; ancillary files; data{p_end}
{synopt :{bf:require}}enforcement {c -} minimum or exact versions, semantic-version
parsing, requirements files, required Stata version{p_end}

{p 4 4 2}
{bf:github} by E. F. Haghish ({it:Stata Journal} 20(4):931-951, 2020) is the
third relative: it is the deeper tool for GitHub-hosted package {it:lifecycle}
(release tags, author-declared dependency chains, update checks, {cmd:uninstall},
building packages). It works entirely through the GitHub API, including the
code-search endpoint, so it is rate-limited in a way {cmd:usepackage}'s
raw-endpoint probing is not. Prefer {cmd:github} when you want a tagged release
or an author's declared dependencies; prefer {cmd:usepackage} for one mixed list
across SSC, the Journal, and GitHub, or when you need data.


{marker remarks}{title:Remarks}

{p 4 4 2}
{bf:A personal copy can mask a package.} An {cmd:.ado} sitting in your PERSONAL
directory wins over anything {cmd:net install} writes to PLUS, so you can install
a package and still run the old code. When the command it finds is a PERSONAL
copy, {cmd:usepackage} says so instead of quietly reporting success.

{p 4 4 2}
{bf:Searching is chatty in a log.} Finding non-SSC packages means calling
{helpb net##search_options:net search}, which writes its catalogue to any open
log even when run quietly. Nothing is printed to the Results window, but expect
the raw catalogue in a log file. (In version 1 this output could not be
suppressed at all.)

{p 4 4 2}
{bf:usepackage only saves typing for more than one package.} For a single known
package, {cmd:ssc install} is shorter.


{marker examples}{title:Examples}

{pstd}{bf:Setup}{p_end}
{phang2}{cmd:. cap ado uninstall statplot}{p_end}
{phang2}{cmd:. cap ssc install usepackage}{p_end}

{pstd}{bf:A list of packages, in one line} {hline 2} the everyday use{p_end}
{phang2}{cmd:. usepackage estout coefplot fre statplot}{p_end}

{pstd}{bf:Check first, install nothing}{p_end}
{phang2}{cmd:. usepackage estout coefplot fre statplot, dryrun}{p_end}

{pstd}{bf:Update packages you already have}{p_end}
{phang2}{cmd:. usepackage estout fre, update}{p_end}

{pstd}{bf:A command that lives in a differently named package}{p_end}
{phang2}{cmd:. usepackage dropmiss}{p_end}
{phang2}{it:reports that dm89_2 ships dropmiss and asks before installing}{p_end}
{phang2}{cmd:. usepackage dropmiss, noconfirm}{p_end}
{phang2}{it:accepts that inferred match without asking}{p_end}

{pstd}{bf:A misspelling, with nearest}{p_end}
{phang2}{cmd:. usepackage statplo, nearest}{p_end}

{pstd}{bf:Skip the example datasets a package ships}{p_end}
{phang2}{cmd:. usepackage flowbca, noconfirm noancillary}{p_end}

{pstd}{bf:Install from a known source, no searching}{p_end}
{phang2}{cmd:. usepackage dm89_2, from("http://www.stata-journal.com/software/sj15-4")}{p_end}

{pstd}{bf:A package on GitHub}{p_end}
{phang2}{cmd:. usepackage applyvarlabels, github("ericabooth/applyvarlabels-stata-public")}{p_end}
{phang2}{it:probes the layout, installs, and fetches the 2 ancillary example files}{p_end}

{phang2}{cmd:. usepackage sparkta2, github("texas-2036/sparkta2-stata-public")}{p_end}
{phang2}{it:its D3 and TopoJSON assets are ancillary, so they come too}{p_end}

{pstd}{bf:Search a whole GitHub account instead of naming the repository}{p_end}
{phang2}{cmd:. usepackage editanything, github("texas-2036")}{p_end}
{phang2}{it:lists the account's repos, narrows by name, installs the one that ships it}{p_end}

{pstd}{bf:What Stata packages does an account ship?}{p_end}
{phang2}{cmd:. usepackage, github("texas-2036")}{p_end}
{phang2}{cmd:. usepackage *, github("ericabooth")}{p_end}

{pstd}{bf:A pasted repository URL, in any of its usual shapes}{p_end}
{phang2}{cmd:. usepackage editanything, github("https://github.com/texas-2036/EditAnything-stata-public")}{p_end}
{phang2}{cmd:. usepackage editanything, github("https://github.com/texas-2036/EditAnything-stata-public/tree/main")}{p_end}

{pstd}{bf:Set your own accounts once, then forget about GitHub}{p_end}
{phang2}{cmd:. global usepackage_github "ericabooth texas-2036"}    // in profile.do{p_end}
{phang2}{cmd:. usepackage editanything}{p_end}
{phang2}{it:not on SSC or in the catalogue, so those accounts are searched}{p_end}

{pstd}{bf:One list spanning SSC, the Stata Journal, and your own repositories}{p_end}
{phang2}{cmd:. usepackage fre dropmiss editanything sparkta2, noconfirm}{p_end}

{pstd}{bf:Install, then pin the versions with require}{p_end}
{phang2}{cmd:. usepackage estout coefplot reghdfe ftools, noconfirm}{p_end}
{phang2}{cmd:. require reghdfe >= 6.0.0, install}{p_end}
{phang2}{it:see} {help usepackage##require:Pairing with require}{p_end}

{pstd}{bf:One data file from GitHub, loaded}{p_end}
{phang2}{cmd:. usepackage, data("datasets/gdp") files("data/gdp.csv") useit}{p_end}
{phang2}{cmd:. list in 1/5}{p_end}

{pstd}{bf:A Stata dataset held under Git LFS}{p_end}
{phang2}{cmd:. usepackage, data("scunning1975/mixtape") files("nsw_mixtape.dta") useit}{p_end}
{phang2}{it:the raw endpoint serves an LFS pointer; usepackage re-fetches the real file}{p_end}

{pstd}{bf:A repository still on master}{p_end}
{phang2}{cmd:. usepackage, data("fivethirtyeight/data") files("airline-safety/airline-safety.csv") useit}{p_end}

{pstd}{bf:Several data files into a subdirectory}{p_end}
{phang2}{cmd:. usepackage, data("scunning1975/mixtape") files("nsw_mixtape.dta cps_mixtape.dta") into("data")}{p_end}

{pstd}{bf:See what data a repository holds before taking any}{p_end}
{phang2}{cmd:. usepackage, data("datasets/population") dryrun}{p_end}

{pstd}{bf:Packages and data in one call}{p_end}
{phang2}{cmd:. usepackage estout coefplot, data("datasets/gdp") files("data/gdp.csv")}{p_end}

{pstd}{bf:Audit a do-file before sending it out}{p_end}
{phang2}{cmd:. usepackage, scan("analysis.do")}{p_end}
{phang2}{it:lists the commands a collaborator would be missing}{p_end}

{pstd}{bf:What a shared do-file might open with}{p_end}
{phang2}{cmd:. usepackage estout coefplot fre reghdfe, noconfirm}{p_end}


{marker results}{title:Stored results}

{pstd}{cmd:usepackage} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(nreq)}}packages requested{p_end}
{synopt:{cmd:r(nok)}}packages installed{p_end}
{synopt:{cmd:r(nskip)}}packages already present{p_end}
{synopt:{cmd:r(ndefer)}}inferred matches left awaiting confirmation{p_end}
{synopt:{cmd:r(nfail)}}packages not resolved{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(unresolved)}}names that could not be found{p_end}
{synopt:{cmd:r(deferred)}}names whose match needs confirming{p_end}

{pstd}So a do-file can stop rather than fail obscurely later:

{phang2}{cmd:. usepackage estout coefplot reghdfe, noconfirm}{p_end}
{phang2}{cmd:. if r(nfail) > 0 {c -(}}{p_end}
{phang2}{cmd:.     di as error "missing: `r(unresolved)'"}{p_end}
{phang2}{cmd:.     exit 601}{p_end}
{phang2}{cmd:. {c )-}}{p_end}


{marker author}{title:Author}

{p 4 4 2}Eric A. Booth, Sr Researcher, Texas 2036{break}
{browse "mailto:eric.a.booth@gmail.com":eric.a.booth@gmail.com}{break}
{browse "https://github.com/ericabooth/usepackage-stata-public":github.com/ericabooth/usepackage-stata-public}

{p 4 4 2}
Version 1.0.0 (2011) was written at the Public Policy Research Institute, Texas
A&M University.


{title:Also see}

{p 4 8 2}
Help: {manhelp net R:net}, {manhelp ssc R:ssc},
{helpb search}, {helpb findit}, {helpb adoupdate}
{p_end}

{p 4 8 2}
Related community commands: {helpb require} (Correia and Seay, {it:SJ} 24(4)) for
version pinning {c -} see {help usepackage##require:Pairing with require};
{helpb github} (Haghish, {it:SJ} 20(4)) for GitHub release tags and
author-declared dependencies.
{p_end}
