{smcl}
{* *! version 2.0.0 07jul2026 Eric A. Booth}{...}
{vieweralsosee "[P] file" "help file"}{...}
{vieweralsosee "[D] copy" "help copy"}{...}
{viewerjumpto "Syntax"            "projectbuilder##syntax"}{...}
{viewerjumpto "Description"       "projectbuilder##description"}{...}
{viewerjumpto "Options"           "projectbuilder##options"}{...}
{viewerjumpto "Workflow A"        "projectbuilder##wfA"}{...}
{viewerjumpto "Workflow B"        "projectbuilder##wfB"}{...}
{viewerjumpto "Optional dependencies" "projectbuilder##deps"}{...}
{viewerjumpto "What gets built"   "projectbuilder##scaffold"}{...}
{viewerjumpto "Recorded metadata" "projectbuilder##meta"}{...}
{viewerjumpto "Examples"          "projectbuilder##examples"}{...}
{viewerjumpto "Stored results"    "projectbuilder##results"}{...}
{viewerjumpto "Author"            "projectbuilder##author"}{...}
{hline}
{pstd}help for {hi:projectbuilder}{p_end}
{hline}

{title:Title}

{p 4 8 2}
{bf:projectbuilder} {hline 2} scaffold a data-analysis project folder with a
numbered do-file pipeline, then optionally ingest data, convert it, combine it
into one analytic file, and build a documentation page.{p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:projectbuilder} {it:Source}[{cmd:/}{it:Subsource}] [{cmd:,} {it:options}]

{pstd}
{it:Source}[{cmd:/}{it:Subsource}] is one token. Enclose it in quotation marks
if it contains a space; an unquoted second word is rejected with error 198
rather than folded into the folder name.{p_end}

{synoptset 27 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt path(string)}}base directory; default is the current working directory{p_end}
{synopt:{opt des:cription(string)}}one-line description of the project{p_end}
{synopt:{opt url(string)}}source URL; recorded, and fetched now if reachable{p_end}
{synopt:{opt data(string)}}local file or folder to copy into {cmd:01_raw/} now{p_end}
{synopt:{opt topic(string)}}free-text topic tag(s){p_end}
{synopt:{opt pub:licfacing(string)}}must be {cmd:yes}, {cmd:no}, or {cmd:unsure}{p_end}
{synopt:{opt time:line(string)}}refresh cadence (for example, {cmd:monthly}){p_end}
{synopt:{opt other:notes(string)}}free-text caveats or provenance{p_end}
{synopt:{opt out:comes(string)}}up to 10 outcome variable names for the profiler{p_end}
{synopt:{opt ov:er(string)}}up to 10 by-variable names for the profiler{p_end}
{synopt:{opt descsave}}seed a codebook-export call in {cmd:300_labels.do}{p_end}
{synopt:{opt rebuild}}refresh an existing project (re-ingest, re-document){p_end}
{synopt:{opt replace}}with {cmd:rebuild}, also overwrite edited code files{p_end}
{synopt:{opt builddocs}}render the documentation with {cmd:webdoc2} if installed{p_end}
{synopt:{opt noauto:convert}}skip the automatic convert/combine pass{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:projectbuilder} creates a project folder under the current working
directory (or under {opt path()}) and fills it with a numbered do-file
pipeline, an analytic-data folder, an output folder, and a documentation
folder. Everything is written by the command itself with
{help file:file write}; there is no template folder and no shell call, so it
behaves the same on macOS, Windows, and Linux.{p_end}

{pstd}
There are two ways to use it. In {bf:Workflow A} the data exists now, so you
point {opt data()} at local files and/or {opt url()} at a source address;
{cmd:projectbuilder} copies the files in, converts them, combines them into one
analytic file, and builds the documentation. In {bf:Workflow B} you scaffold
first and add data later, then rerun with {opt rebuild} on every refresh. Both
are shown below.{p_end}

{pstd}
{cmd:projectbuilder} never overwrites an existing project: a plain call on a
folder that already exists stops with error 602. Use {opt rebuild} to opt in to
working on an existing project. A {opt rebuild} preserves any do-file in
{cmd:_code/} you have edited unless you also give {opt replace}; the
documentation, being a derived artifact, is regenerated on every {opt rebuild}.{p_end}


{marker options}{...}
{title:Options}

{phang}
{opt path(string)} sets the base directory under which the project folder is
created. The default is the current working directory. The project is created
at {it:path}{cmd:/}{it:Source} (or {it:path}{cmd:/}{it:Source}{cmd:/}{it:Subsource}).{p_end}

{phang}
{opt description(string)} is a one-line description of the project. It is
stamped into the documentation and the pipeline headers.{p_end}

{phang}
{opt url(string)} records a source URL. The fetch is written into
{cmd:100_data_download.do} so it is reproducible, and it is attempted once at
scaffold time; if the address is reachable the file lands in {cmd:01_raw/}.{p_end}

{phang}
{opt data(string)} names a local file, or a folder of files, to copy into
{cmd:01_raw/} now. This is the Workflow A entry point for data you already
have on disk.{p_end}

{phang}
{opt topic(string)}, {opt publicfacing(string)}, {opt timeline(string)}, and
{opt othernotes(string)} are metadata stamped into the documentation.
{opt publicfacing()} must be {cmd:yes}, {cmd:no}, {cmd:unsure}, or empty.{p_end}

{phang}
{opt outcomes(string)} and {opt over(string)} seed the suggested locals in
{cmd:400_data_profiler.do}. Each is capped at 10 items, with a note when
trimmed. Both are recorded as {it:strings}, not validated as varlists: at
scaffold time the analytic file usually does not exist yet, so there is nothing
to validate against. Two consequences follow. Names are written through
verbatim, so abbreviations and wildcards such as {cmd:pri*} are recorded but
never expanded. Names that turn out not to exist are not an error either: the
generated profiler tests each name with {helpb confirm:confirm variable} and
skips the ones the analytic file does not have.{p_end}

{phang}
{opt descsave} adds a codebook-export call (via {cmd:descsave} from SSC) to
{cmd:300_labels.do}, writing an Excel codebook into {cmd:_documentation/}.{p_end}

{phang}
{opt rebuild} refreshes an existing project: it re-runs the convert/combine
pass over {cmd:01_raw/} and regenerates the documentation. Every data refresh
is just another {opt rebuild}. Metadata recorded earlier survives a bare
{opt rebuild}; see {help projectbuilder##meta:Recorded metadata} below.{p_end}

{phang}
{opt replace} has effect only with {opt rebuild}: it allows the numbered
do-files to be overwritten. Without it, a {opt rebuild} leaves your edited
do-files untouched.{p_end}

{phang}
{opt builddocs} renders {cmd:_documentation/website/index.html} with
{cmd:webdoc2} if it is installed. Documentation is always built either way; this
option only makes it prettier.{p_end}

{phang}
{opt noautoconvert} skips the automatic {cmd:convertanything} and
{cmd:combineall} pass. The calls still appear in {cmd:200_data_management.do} so
you can run them yourself.{p_end}


{marker wfA}{...}
{title:Workflow A -- the data already exists (local files or a source URL)}

{pstd}
You have a folder of CSV or Excel files on disk (or a public download URL), and
you want a project built around them in one command.{p_end}

{pstd}
{bf:Step 1.} Scaffold and ingest in a single call. Point {opt data()} at the
folder of files (and/or {opt url()} at the source). Run it from the directory
that should hold the new project folder, or name that directory in
{opt path()}:{p_end}

{cmd}{...}
        . projectbuilder CountyBudgets,                                  ///
              data("budget_drop")                                        ///
              description("County budget CSVs, one row per dept per FY") ///
              topic("local government, budgets") publicfacing(unsure)    ///
              timeline("annual") outcomes(total_budget) over(year dept)  ///
              descsave
{txt}{...}

{pstd}
This copies every file from {cmd:budget_drop/} into {cmd:CountyBudgets/01_raw/}
and writes the documentation page. What happens next depends on which optional
companions are installed. With {cmd:convertanything} installed,
{cmd:projectbuilder} converts {cmd:01_raw/} into {cmd:01_raw/_converted/}; with
{cmd:combineall} also installed, it appends the converted files into
{cmd:02_cleaned/CountyBudgets_analytic.dta}. Neither is installed by default.
(If a source lives online, add {cmd:url("https://.../data.csv")}; it is fetched
now and the fetch is recorded in {cmd:100_data_download.do}.){p_end}

{pstd}
{bf:Step 2.} Open {cmd:_code/000_control.do} and run it to set the path
globals. Then check whether {cmd:02_cleaned/CountyBudgets_analytic.dta} exists,
because the rest of the pipeline reads it. If it does, work down from
{cmd:300_labels.do}. If it does not, {cmd:convertanything} or {cmd:combineall}
was missing, and the run printed the install command for whichever one it could
not find; install them and rerun with {opt rebuild}, or run
{cmd:200_data_management.do} yourself. Skipping this check makes
{cmd:300_labels.do} stop with error 601 on its opening {cmd:use}.{p_end}


{marker wfB}{...}
{title:Workflow B -- scaffold now, data later, rebuild on every refresh}

{pstd}
You want the project structure now, before the data has arrived.{p_end}

{pstd}
{bf:Step 1.} Scaffold with no {opt data()} and no {opt url()}. You get the full
tree, an empty {cmd:01_raw/}, and printed next steps:{p_end}

{cmd}{...}
        . projectbuilder VendorFeed, description("Monthly vendor extract")
{txt}{...}

{pstd}
{bf:Step 2.} When the files arrive, drop them into
{cmd:VendorFeed/01_raw/}.{p_end}

{pstd}
{bf:Step 3.} Rerun with {opt rebuild}. {cmd:projectbuilder} detects the new
files, re-runs the convert/combine pass, and regenerates the documentation:{p_end}

{cmd}{...}
        . projectbuilder VendorFeed, rebuild
{txt}{...}

{pstd}
Every later refresh is the same {opt rebuild}. It is idempotent: it will not
overwrite a do-file you have edited in {cmd:_code/} unless you add
{opt replace}, and the description, topic, and other metadata you recorded at
scaffold time are carried forward rather than reset to placeholders.{p_end}


{marker deps}{...}
{title:Optional dependencies}

{pstd}
{cmd:projectbuilder} has no hard dependencies. A few companion tools make it do
more when installed; each is detected with {help capture:capture which}. If a
tool is missing, the generated do-file still {it:contains} the call (so it is a
working example), the automatic pass skips that step, and a one-line note names
the package and its install command.{p_end}

{p2colset 8 26 28 2}{...}
{p2col:{bf:convertanything}}bulk-convert mixed formats in {cmd:01_raw/} to {cmd:.dta} in {cmd:01_raw/_converted/} (author's GitHub){p_end}
{p2col:{bf:combineall}}append or merge the converted files into the analytic file (author's GitHub){p_end}
{p2col:{bf:descsave}}write an Excel codebook from {cmd:300_labels.do} (SSC: {cmd:ssc install descsave}){p_end}
{p2col:{bf:srctag} / {bf:srcfind}}tag and search each variable's source lineage (author's GitHub){p_end}
{p2col:{bf:webdoc2}}render a richer {cmd:index.html} (author's GitHub; needs {cmd:ssc install webdoc}){p_end}
{p2colreset}{...}

{pstd}
The convert-then-combine chain is the heart of {cmd:200_data_management.do}:
{cmd:convertanything} turns every raw file into a cleaned {cmd:.dta}, then
{cmd:combineall} with {cmd:cmethod(append)} stacks those into one analytic file.
When {cmd:webdoc2} is absent, {cmd:projectbuilder} writes a plain but complete
{cmd:index.html} and {cmd:Readme.md} directly, so the documentation always
exists.{p_end}


{marker scaffold}{...}
{title:What gets built}

{pstd}
After {cmd:projectbuilder MyProject} you have:{p_end}

{cmd}{...}
        MyProject/
        +-- 01_raw/                raw source files (write-once)
        |   +-- _archive/
        |   +-- _converted/        convertanything output (.dta per raw file)
        +-- 02_cleaned/            <project>_analytic.dta lives here
        |   +-- _archive/
        +-- 03_output/             logs, tables, exhibits
        |   +-- _archive/
        +-- _code/
        |   +-- 000_control.do     every path in one place; run-all block
        |   +-- 100_data_download.do
        |   +-- 200_data_management.do   convertanything -> combineall
        |   +-- 300_labels.do
        |   +-- 400_data_profiler.do
        |   +-- 500_aggregation.do
        |   +-- 600_analysis.do
        |   +-- _archive/
        +-- _documentation/
        |   +-- index.do             webdoc2 source
        |   +-- _runall.do           renders website/index.html
        |   +-- _project_meta.txt    recorded metadata, read back on rebuild
        |   +-- Readme.md
        |   +-- website/index.html
        |   +-- _archive/
        +-- _archive/
{txt}{...}

{pstd}
{cmd:000_control.do} pins the language version, stamps {cmd:$root} with the
absolute path of the new folder (one loudly commented line to edit if the
project ever moves), derives {cmd:$raw}, {cmd:$converted}, {cmd:$cleaned},
{cmd:$output}, {cmd:$code}, and {cmd:$docs} from it, and ends with a run-all
block over the numbered pipeline.{p_end}

{pstd}
The version pin is {cmd:version 16.0}, this package's own floor, not the release
of the Stata that generated the file. Pinning the generating release would write
something like {cmd:version 19.5}, which every earlier installation rejects, so
the control file would not run for a teammate on Stata 16 through 19. Raise the
pin by hand if the project comes to depend on newer syntax.{p_end}


{marker meta}{...}
{title:Recorded metadata}

{pstd}
The metadata options are recorded once and reused. {cmd:projectbuilder} writes
{opt description()}, {opt url()}, {opt topic()}, {opt publicfacing()},
{opt timeline()}, {opt othernotes()}, {opt outcomes()}, {opt over()}, and the
creation date into {cmd:_documentation/_project_meta.txt}, one {cmd:key=value}
per line. On any later call, each value the call does not supply is read back
from that file. A bare {cmd:projectbuilder MyProject, rebuild} therefore keeps
the description and topic it was given at scaffold time instead of replacing
them with placeholders, and {opt rebuild} {opt replace} rewrites
{cmd:400_data_profiler.do} with the {opt outcomes()} and {opt over()} names
already on record. An option supplied on the current call always wins, so
{cmd:rebuild description("...")} is how you change a recorded value. The file is
plain text and can also be edited directly.{p_end}

{pstd}
The {cmd:Created} row of the documentation is the date of the first scaffold,
carried in the same file, so a rebuild does not restamp it with today. The date
and time of the current build appear separately in the footer line of
{cmd:index.html} and {cmd:Readme.md}. That footer is the only line a rebuild is
expected to change when nothing else about the project has moved.{p_end}

{pstd}
{cmd:_documentation/index.do} is guarded in the same way as the numbered
do-files: a {opt rebuild} without {opt replace} leaves it exactly as written, on
the assumption that you may have edited it. {cmd:website/index.html} and
{cmd:Readme.md} are derived artifacts and are rewritten on every call. Because
both sides now draw on the same recorded metadata, the guarded {cmd:index.do}
and the regenerated {cmd:index.html} agree after a rebuild. They diverge only if
you edit one of them by hand, and the two edits behave differently: an edit to
{cmd:index.do} reaches {cmd:index.html} only when {opt builddocs} renders it
with {cmd:webdoc2}, whereas an edit to the generated {cmd:index.html} is
overwritten by the next call. To change what both say, pass the option again or
edit {cmd:_project_meta.txt}.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Scaffold an empty project in the current directory, then look at the
documentation it wrote:{p_end}
{cmd}{...}
        . projectbuilder VendorFeed, description("Monthly vendor extract")
        . type "VendorFeed/_documentation/Readme.md"
{txt}{...}

{pstd}Scaffold under a named base directory instead of the current one:{p_end}
{cmd}{...}
        . projectbuilder VendorFeed2, path("projects")
{txt}{...}

{pstd}Scaffold a subsource under a source; the project label joins them with an
underscore:{p_end}
{cmd}{...}
        . projectbuilder Agency/Extract, description("One agency extract")
{txt}{...}

{pstd}Refresh a project after new files land in {cmd:01_raw/}. The recorded
metadata is kept, and edited do-files in {cmd:_code/} are left alone:{p_end}
{cmd}{...}
        . projectbuilder VendorFeed, rebuild
{txt}{...}

{pstd}Change one recorded value on a refresh; everything else stays as it
was:{p_end}
{cmd}{...}
        . projectbuilder VendorFeed, rebuild topic("procurement")
{txt}{...}

{pstd}Refresh and reset the numbered do-files to the shipped templates,
discarding your edits to them:{p_end}
{cmd}{...}
        . projectbuilder VendorFeed, rebuild replace
{txt}{...}

{pstd}Scaffold and ingest in one call: copy a folder of files in, record the
metadata, and seed the profiler:{p_end}
{cmd}{...}
        . projectbuilder CountyBudgets,                                  ///
              data("budget_drop")                                        ///
              description("County budget CSVs, one row per dept per FY") ///
              topic("local government, budgets") publicfacing(unsure)    ///
              timeline("annual") outcomes(total_budget) over(year dept)  ///
              descsave
{txt}{...}

{pstd}Record a source URL. It is fetched now if the address is reachable, and
the fetch is written into {cmd:100_data_download.do} either way:{p_end}
{cmd}{...}
        . projectbuilder OpenData, url("https://example.com/data.csv")
{txt}{...}

{pstd}Scaffold without running the convert/combine pass, leaving
{cmd:01_raw/} untouched:{p_end}
{cmd}{...}
        . projectbuilder VendorFeed3, noautoconvert
{txt}{...}

{pstd}Rebuild and render the documentation with {cmd:webdoc2} when it is
installed:{p_end}
{cmd}{...}
        . projectbuilder VendorFeed, rebuild builddocs
{txt}{...}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:projectbuilder} is {help return:rclass} and stores:{p_end}

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(nraw)}}number of files in {cmd:01_raw/}{p_end}
{synopt:{cmd:r(nconverted)}}number of {cmd:.dta} files in {cmd:01_raw/_converted/}{p_end}
{synopt:{cmd:r(rebuilt)}}1 if this call refreshed an existing project, else 0{p_end}
{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(project)}}project label (slashes become underscores){p_end}
{synopt:{cmd:r(path)}}absolute path of the project folder{p_end}
{p2colreset}{...}


{marker author}{...}
{title:Authors}

{pstd}
Eric A. Booth, Sr Researcher, Texas 2036{break}
Support: {browse "mailto:eric.a.booth@gmail.com":eric.a.booth@gmail.com}{p_end}

{pstd}
Elizabeth Teas, Sr Research Scientist, Far Harbor, LLC{break}
{browse "mailto:elizabeth@farharbor.com":elizabeth@farharbor.com}{p_end}

{pstd}
Companion package to {it:Applied Program Evaluation Using Stata}.{p_end}

{hline}
