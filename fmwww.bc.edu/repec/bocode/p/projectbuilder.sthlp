{smcl}
{* *! version 2.0.1 31jul2026 Eric A. Booth and Elizabeth Teas}{...}
{vieweralsosee "[P] file" "help file"}{...}
{vieweralsosee "[D] copy" "help copy"}{...}
{viewerjumpto "Syntax"            "projectbuilder##syntax"}{...}
{viewerjumpto "Quick start"       "projectbuilder##quickstart"}{...}
{viewerjumpto "Description"       "projectbuilder##description"}{...}
{viewerjumpto "Options"           "projectbuilder##options"}{...}
{viewerjumpto "Workflow A"        "projectbuilder##wfA"}{...}
{viewerjumpto "Workflow B"        "projectbuilder##wfB"}{...}
{viewerjumpto "Optional dependencies" "projectbuilder##deps"}{...}
{viewerjumpto "What gets built"   "projectbuilder##scaffold"}{...}
{viewerjumpto "Recorded metadata" "projectbuilder##meta"}{...}
{viewerjumpto "Your data in memory" "projectbuilder##memory"}{...}
{viewerjumpto "Characters in option values" "projectbuilder##chars"}{...}
{viewerjumpto "Try it now"        "projectbuilder##tryit"}{...}
{viewerjumpto "Examples"          "projectbuilder##examples"}{...}
{viewerjumpto "Stored results"    "projectbuilder##results"}{...}
{viewerjumpto "Authors"           "projectbuilder##author"}{...}
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
rather than folded into the folder name. Leading and trailing spaces are
trimmed; interior ones are kept, in the folder name and in {cmd:r(project)}.
On macOS and Windows, where the filesystem ignores case, a name differing from
an existing project only in case is the same project and trips the 602
guard.{p_end}

{synoptset 27 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt path(string)}}base directory, created if its parent exists; default is the current directory{p_end}
{synopt:{opt des:cription(string)}}one-line description of the project{p_end}
{synopt:{opt url(string)}}source URL; recorded, and fetched now if reachable{p_end}
{synopt:{opt data(string)}}one local file, or one folder, to copy into {cmd:01_raw/} now, then convert and combine{p_end}
{synopt:{opt topic(string)}}free-text topic tag(s){p_end}
{synopt:{opt pub:licfacing(string)}}must be {cmd:yes}, {cmd:no}, or {cmd:unsure}{p_end}
{synopt:{opt time:line(string)}}refresh cadence (for example, {cmd:monthly}){p_end}
{synopt:{opt other:notes(string)}}free-text caveats or provenance{p_end}
{synopt:{opt out:comes(string)}}up to 10 outcome variable names for the profiler; recorded, not validated{p_end}
{synopt:{opt ov:er(string)}}up to 10 by-variable names for the profiler; recorded, not validated{p_end}
{synopt:{opt desc:save}}write a codebook-export call into {cmd:300_labels.do}, to run when you run that file{p_end}
{synopt:{opt rebuild}}refresh an existing project (re-ingest, re-document){p_end}
{synopt:{opt replace}}with {cmd:rebuild}, also overwrite edited code files{p_end}
{synopt:{opt builddocs}}render the documentation with {cmd:webdoc2} if installed{p_end}
{synopt:{opt noauto:convert}}skip the automatic convert/combine pass{p_end}
{synoptline}

{pstd}
All options are optional. The project name is not: {cmd:projectbuilder} with no
name stops with "source[/subsource] required". Each option may be given at most
once; repeating one raises Stata's "option ... not allowed". Two abbreviations
sit close together: {cmd:des()} is {opt description()}, while a bare
{cmd:desc} is {opt descsave}.{p_end}

{pstd}
The convert-and-combine step named on the {opt data()} row needs
{cmd:convertanything} and {cmd:combineall}, which are optional and not
installed by default. Without them you still get the folder tree, the
do-files, and the documentation. See
{help projectbuilder##deps:Optional dependencies}.{p_end}


{marker quickstart}{...}
{title:Quick start}

{pstd}
Start one of two ways. If the data has not arrived yet, build the folder
now:{p_end}
{cmd}{...}
        . projectbuilder MyProject, description("What this project is for")
{txt}{...}

{pstd}If you already have the files, point at the folder holding them and get
them ingested in the same call:{p_end}
{cmd}{...}
        . projectbuilder MyProject, data("the_folder_the_files_are_in") ///
              description("What this project is for")
{txt}{...}

{pstd}
Use one or the other, not both: the second call would stop with error 602,
because {cmd:MyProject} already exists. From then on, every data refresh is the
same one command:{p_end}
{cmd}{...}
        . projectbuilder MyProject, rebuild
{txt}{...}

{pstd}
That is the whole daily loop. The folder is created under the current
directory unless you name another in {opt path()}; a plain rerun never
overwrites an existing project; and the dataset in memory is left alone. To
click through a full worked example in the Viewer, see
{help projectbuilder##tryit:Try it now}.{p_end}


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
documentation, being a derived artifact, is regenerated on every {opt rebuild}.
The dataset in memory is left untouched throughout; see
{help projectbuilder##memory:Your data in memory}.{p_end}

{pstd}
For a guided tour you can click through in the Viewer, see
{help projectbuilder##tryit:Try it now}.{p_end}


{marker options}{...}
{title:Options}

{phang}
{opt path(string)} sets the base directory under which the project folder is
created. The default is the current working directory. The project is created
at {it:path}{cmd:/}{it:Source} (or {it:path}{cmd:/}{it:Source}{cmd:/}{it:Subsource}).
A relative path is resolved against the current directory, so {cmd:r(path)} and
the {cmd:$root} stamped into {cmd:000_control.do} are always absolute. The base
itself is created if its own parent already exists; {cmd:path("new/deeper")}
where neither level exists stops with error 601 rather than making two levels
at once.{p_end}

{phang}
{opt description(string)} is a one-line description of the project. It is
stamped into the documentation and into the header of
{cmd:_code/000_control.do}, so the first file a colleague opens says what the
project is for.{p_end}

{phang}
{opt url(string)} records a source URL. The fetch is written into
{cmd:100_data_download.do} so it is reproducible, and it is attempted once at
scaffold time; if the address is reachable the file lands in {cmd:01_raw/}.{p_end}

{phang}
{opt data(string)} names one local file, or one folder of files, to copy into
{cmd:01_raw/} now, after which the automatic convert/combine pass runs unless
{opt noautoconvert} is given. This is the Workflow A entry point for data you
already have on disk. It takes a single path: wildcards are not expanded and a
space-separated list is not split, so {cmd:data("*.csv")} looks for a file
literally named {cmd:*.csv}, does not find one, and says so. Point it at the
folder instead. A relative path is read from the current directory.{p_end}

{phang}
{opt topic(string)}, {opt publicfacing(string)}, {opt timeline(string)}, and
{opt othernotes(string)} are metadata stamped into the documentation.
{opt publicfacing()} must be {cmd:yes}, {cmd:no}, {cmd:unsure}, or empty; case
does not matter, and surrounding spaces are trimmed.{p_end}

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
{opt descsave} writes a codebook-export call (via {cmd:descsave} from SSC) into
{cmd:300_labels.do}. Nothing is exported at scaffold time: the codebook appears
in {cmd:_documentation/} when you run {cmd:300_labels.do}, as both
{it:project}{cmd:_codebook.dta} (which is what {cmd:descsave} produces, one
observation per variable) and {it:project}{cmd:_codebook.xlsx}, exported from it
with Stata's own {helpb export_excel:export excel} so it can be read without
Stata. The block is wrapped in {helpb preserve}, so running
{cmd:300_labels.do} leaves the analytic file loaded as before. Like the other
options it is remembered, so a later {opt rebuild} keeps it. Note the
abbreviations here: {cmd:des()} is {opt description()}, while a bare
{cmd:desc} is {opt descsave}.{p_end}

{phang}
{opt rebuild} refreshes an existing project: it re-runs the convert/combine
pass over {cmd:01_raw/} and regenerates the documentation. Every data refresh
is just another {opt rebuild}. Metadata recorded earlier survives a bare
{opt rebuild}; see {help projectbuilder##meta:Recorded metadata} below. Given
for a project that does not exist yet, {opt rebuild} is not an error: it
scaffolds one, and says that is what it did. That is what makes the command
safe to put in a scheduled script, but it also means a mistyped name plus
{opt rebuild} produces a second, empty project rather than a complaint. Check
{cmd:r(rebuilt)}, which is {cmd:1} only when an existing project was
refreshed.{p_end}

{phang}
{opt replace} has effect only with {opt rebuild}: it allows the numbered
do-files to be overwritten. Without it, a {opt rebuild} leaves your edited
do-files untouched. One consequence catches people out: adding an option that
changes what a do-file should contain, such as {opt descsave} or a new
{opt outcomes()}, has no visible effect on a bare {opt rebuild}, because the
do-file it would rewrite is one of the guarded ones. Add {opt replace} to make
those options reach {cmd:_code/}. The documentation, which is not guarded,
updates either way.{p_end}

{phang}
{opt builddocs} renders {cmd:_documentation/website/index.html} with
{cmd:webdoc2} if it is installed. Documentation is always built either way; this
option only makes it prettier. The render runs {cmd:_documentation/_runall.do},
so its output appears in your log, and a render that fails part way -- most
often because the {cmd:webdoc2} package directory is not on the adopath -- will
print its own error there. That failure is caught: the built-in
{cmd:index.html} is kept and the run still succeeds.{p_end}

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
{bf:Step 1.} Have the files in a folder. In real work that folder is whatever
the agency sent you; to follow along here, make one:{p_end}

{cmd}{...}
        . mkdir "budget_drop"
        . sysuse auto, clear
        . export delimited using "budget_drop/budgets_fy24.csv", replace
        . export delimited using "budget_drop/budgets_fy25.csv", replace
{txt}{...}

{pstd}
{bf:Step 2.} Scaffold and ingest in a single call. Point {opt data()} at that
folder (and/or {opt url()} at the source). Run it from the directory that should
hold the new project folder, or name that directory in {opt path()}:{p_end}

{cmd}{...}
        . projectbuilder CountyBudgets,                                  ///
              data("budget_drop")                                        ///
              description("County budget CSVs, one row per dept per FY") ///
              topic("local government, budgets") publicfacing(unsure)    ///
              timeline("annual") outcomes(total_budget) over(year dept)  ///
              descsave
{txt}{...}

{pstd}
{opt data()} is read relative to the current directory unless you give a full
path. If it does not exist, {cmd:projectbuilder} says so in red and still builds
the scaffold, so an empty {cmd:01_raw/} after this step means the path was
wrong, not that the command failed.{p_end}

{pstd}
This copies every file from {cmd:budget_drop/} into {cmd:CountyBudgets/01_raw/}
and writes the documentation page. What happens next depends on which optional
companions are installed, and {bf:neither is installed by default} -- check with
{cmd:which convertanything} and {cmd:which combineall} before reading the output.
With {cmd:convertanything} installed, {cmd:projectbuilder} converts
{cmd:01_raw/} into {cmd:01_raw/_converted/}; with {cmd:combineall} also
installed, it appends the converted files into
{cmd:02_cleaned/CountyBudgets_analytic.dta}. Without them you get the full
folder tree, the do-files, and the documentation, and the run tells you what it
skipped and how to install it. See
{help projectbuilder##deps:Optional dependencies}.
(If a source lives online, add {cmd:url("https://.../data.csv")}; it is fetched
now and the fetch is recorded in {cmd:100_data_download.do}.){p_end}

{pstd}
{bf:Step 3.} Open {cmd:_code/000_control.do} and run it to set the path
globals. Then check whether {cmd:02_cleaned/CountyBudgets_analytic.dta} exists,
because the rest of the pipeline reads it. The "Next steps" block printed at the
end of Step 2 already tells you which case you are in. If the file exists, work
down from {cmd:300_labels.do}. If it does not, {cmd:convertanything} or
{cmd:combineall} was missing, and the run printed the install command for
whichever one it could not find; install them and rerun with {opt rebuild}, or
run {cmd:200_data_management.do} yourself. Skipping this check makes
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
tool is missing, the generated do-file still {it:contains} the call, so it
remains a working example, and the step is skipped rather than failing.{p_end}

{pstd}
Where you see the note depends on when the tool is needed.
{cmd:convertanything}, {cmd:combineall}, and {cmd:webdoc2} do their work while
{cmd:projectbuilder} runs, so a missing one is named on screen along with its
install command. {cmd:descsave} and {cmd:srctag}/{cmd:srcfind} do their work
later, when you run {cmd:300_labels.do}, so their notes live inside that file
and appear only when you run it.{p_end}

{p2colset 8 26 28 2}{...}
{p2col:{bf:convertanything}}bulk-convert mixed formats in {cmd:01_raw/} to {cmd:.dta} in {cmd:01_raw/_converted/} (author's GitHub){p_end}
{p2col:{bf:combineall}}append or merge the converted files into the analytic file (author's GitHub){p_end}
{p2col:{bf:descsave}}write a codebook (.dta plus .xlsx) from {cmd:300_labels.do} (SSC: {cmd:ssc install descsave}){p_end}
{p2col:{bf:srctag} / {bf:srcfind}}tag and search each variable's source lineage (author's GitHub){p_end}
{p2col:{bf:webdoc2}}render a richer {cmd:index.html} (author's GitHub; needs {cmd:ssc install webdoc}, and see the note below){p_end}
{p2colreset}{...}

{pstd}
{bf:webdoc2 needs one extra step.} Its renderer injects a file called
{cmd:header.html}, and webdoc2 ships that as an {it:ancillary} file, so
{cmd:net install webdoc2} does not place it:{p_end}

{cmd}{...}
        . ssc install webdoc
        . net install webdoc2, from("https://raw.githubusercontent.com/ericabooth/webdoc2-stata-public/main/") replace
        . net get webdoc2, from("https://raw.githubusercontent.com/ericabooth/webdoc2-stata-public/main/") replace
{txt}{...}

{pstd}
The last line drops {cmd:header.html} into your current directory. {opt builddocs}
looks for it there, and on the adopath, before it renders, and carries a copy
into {cmd:_documentation/} for the duration of the render. Put it somewhere on
your adopath -- your PERSONAL directory is the usual place -- and it will be
found from anywhere. Without it the render stops, {cmd:projectbuilder} says so
and names this remedy, and the built-in {cmd:website/index.html} is left
untouched.{p_end}

{pstd}
{bf:Keep non-data files out of }{cmd:01_raw/}{bf:.} The automatic pass hands
every file it finds there to {cmd:convertanything}, which reads delimited text
by extension. A {cmd:README.txt} or a notes file sitting beside the data is
therefore read as a dataset and appended into the analytic file, and a
{cmd:.pdf} or a file with no extension is skipped without comment. Two files
whose names differ only by extension, such as {cmd:report.csv} and
{cmd:report.xlsx}, both convert to {cmd:report.dta} and the second overwrites
the first. When the converted count does not match the raw count,
{cmd:projectbuilder} says so; {cmd:r(nraw)} and {cmd:r(nconverted)} let a
script check the same thing. Put documentation in {cmd:_documentation/} and
leave {cmd:01_raw/} for data.{p_end}

{pstd}
The analytic file is a straight append of the converted files and carries no
column saying which raw file each row came from. If you need that, add it in
{cmd:200_data_management.do}, or install {cmd:srctag}, which is what it is
for.{p_end}

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
The {cmd:_archive/} folders are made for your convenience and are never written
to by {cmd:projectbuilder}. Nothing is moved into them automatically -- not by
{opt rebuild}, and not by {opt replace}, which overwrites an edited do-file in
place with no copy kept. Move anything you want to keep before running
{opt replace}, or keep {cmd:_code/} under version control.{p_end}

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
already on record. A {it:non-empty} option on the current call always wins, so
{cmd:rebuild description("...")} is how you change a recorded value. An empty
one is treated as not supplied: {cmd:rebuild topic("")} does not clear the
topic, it re-reads the recorded one. To clear a value, delete it from
{cmd:_project_meta.txt}, which is plain text and meant to be edited
directly.{p_end}

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
{cmd:Readme.md} are derived artifacts and are rewritten on every call. Both
sides draw on the same recorded metadata, so a bare {opt rebuild} leaves them
agreeing.{p_end}

{pstd}
They do diverge in one ordinary case: changing a value on a refresh, as in
{cmd:rebuild topic("procurement")}, rewrites {cmd:index.html} and
{cmd:Readme.md} with the new topic but leaves the guarded {cmd:index.do}
showing the old one. That is the guard doing its job, on the assumption that
you may have edited {cmd:index.do} yourself. Add {opt replace} to bring
{cmd:index.do} back in line, or edit it directly. The same asymmetry applies to
hand edits: an edit to {cmd:index.do} reaches {cmd:index.html} only when
{opt builddocs} renders it with {cmd:webdoc2}, whereas an edit to the generated
{cmd:index.html} is overwritten by the next call.{p_end}


{marker memory}{...}
{title:Your data in memory}

{pstd}
{cmd:projectbuilder} leaves the dataset in memory exactly as it found it. That
is worth stating because the automatic pass does load data: {cmd:convertanything}
runs with {cmd:clear}, and {cmd:combineall} does its own {cmd:use} and
{cmd:save}. The command wraps that pass in {helpb preserve}, so a scaffold or a
refresh in the middle of an analysis session does not cost you your data.{p_end}

{pstd}
Two consequences follow. Nothing you have in memory is written into the
project, so the analytic file is built only from what is on disk in
{cmd:01_raw/}. And because {helpb preserve} writes a temporary copy, a
{opt rebuild} while a very large dataset is loaded costs one round trip to
disk; {opt noautoconvert} skips the pass, and with it the preserve.{p_end}


{marker chars}{...}
{title:Characters in option values}

{pstd}
The free-text options are written into do-files and documentation pages, which
puts three characters worth knowing about.{p_end}

{phang}
{bf:Backtick.} Rejected, with an error naming the option. A backtick opens a
macro reference Stata cannot close, and it used to stop the command partway
through, after the folders had been made but before the do-files were written.
Type an apostrophe instead.{p_end}

{phang}
{bf:Dollar sign.} Stata expands globals while it parses the command line, so
{cmd:description("costs $M per year")} reaches {cmd:projectbuilder} with the
{cmd:$M} already gone. This is true of every Stata command and cannot be
fixed here. Write {cmd:\$M}, or put the value in
{cmd:_documentation/_project_meta.txt} by hand, where it is read back
literally and survives every later {opt rebuild}.{p_end}

{phang}
{bf:Tilde.} Passes through unchanged, including in a URL such as
{cmd:url("https://example.edu/~Dave/data.csv")}.{p_end}


{marker tryit}{...}
{title:Try it now}

{pstd}
Every line below is clickable. The demo is built in your temporary directory,
so nothing lands in a folder you care about, and your working directory is
never changed. Click them in order; each step assumes the one before it. The
whole sequence is identical on Windows, macOS, and Linux.{p_end}

{pstd}
If you, or anyone else on this machine, has walked through this before, Step 1
will stop with error 602: {cmd:projectbuilder} does not overwrite an existing
project, which is the point Step 6 makes on purpose. Add {opt rebuild} to
Step 1 and read the rest as a refresh, or delete the folder Step 2 names and
start over. On a shared server, give {opt path()} a directory of your own
instead of the temporary one.{p_end}

{pstd}{bf:Step 1.} Scaffold a project with no data yet, in the temporary
directory Stata already uses. Read the "Next steps" block it prints:{p_end}
{p 8 12 2}{stata `"projectbuilder pbdemo, path("`c(tmpdir)'") description("A walkthrough") topic(demo) publicfacing(no)"':. projectbuilder pbdemo, path("`c(tmpdir)'") description("A walkthrough") topic(demo) publicfacing(no)}{p_end}

{pstd}{bf:Step 2.} Keep the folder it built. {cmd:r(path)} is the absolute path
of the new project, so nothing below has to guess at separators or spell out a
directory:{p_end}
{p 8 12 2}{stata `"global pbdemo "`r(path)'""':. global pbdemo "`r(path)'"}{p_end}
{p 8 12 2}{stata `"display "$pbdemo""':. display "$pbdemo"}{p_end}

{pstd}{bf:Step 3.} Look at what it wrote. The control file is the one that
matters; every path in the project is derived from its {cmd:$root}:{p_end}
{p 8 12 2}{stata `"type "$pbdemo/_code/000_control.do""':. type "$pbdemo/_code/000_control.do"}{p_end}
{p 8 12 2}{stata `"type "$pbdemo/_documentation/Readme.md""':. type "$pbdemo/_documentation/Readme.md"}{p_end}

{pstd}{bf:Step 4.} Put some data in {cmd:01_raw/}, the way a real drop would
arrive:{p_end}
{p 8 12 2}{stata "sysuse auto, clear":. sysuse auto, clear}{p_end}
{p 8 12 2}{stata `"export delimited using "$pbdemo/01_raw/auto.csv", replace"':. export delimited using "$pbdemo/01_raw/auto.csv", replace}{p_end}

{pstd}{bf:Step 5.} Refresh. This is the command you rerun on every data
update, and the only one you need to remember:{p_end}
{p 8 12 2}{stata `"projectbuilder pbdemo, path("`c(tmpdir)'") rebuild"':. projectbuilder pbdemo, path("`c(tmpdir)'") rebuild}{p_end}
{p 8 12 2}{stata "describe":. describe}{p_end}

{pstd}
The {cmd:describe} still shows the auto data: the refresh did not disturb it.
If {cmd:convertanything} and {cmd:combineall} are installed, the run also built
{cmd:02_cleaned/pbdemo_analytic.dta}; if not, it printed the install command for
whichever one was missing and built everything else.{p_end}

{pstd}{bf:Step 6.} Confirm that the guards work. Both of these are supposed to
fail. The first stops with error 602, because a plain call never overwrites an
existing project. The second stops with error 198, before any folder is
created, because {opt publicfacing()} takes only yes, no, or unsure:{p_end}
{p 8 12 2}{stata `"projectbuilder pbdemo, path("`c(tmpdir)'")"':. projectbuilder pbdemo, path("`c(tmpdir)'")}{p_end}
{p 8 12 2}{stata `"projectbuilder pbdemo2, path("`c(tmpdir)'") publicfacing(maybe)"':. projectbuilder pbdemo2, path("`c(tmpdir)'") publicfacing(maybe)}{p_end}

{pstd}{bf:Step 7.} Change one recorded value and watch the rest survive. The
topic changes; the description, timeline, and creation date do not:{p_end}
{p 8 12 2}{stata `"projectbuilder pbdemo, path("`c(tmpdir)'") rebuild topic("procurement")"':. projectbuilder pbdemo, path("`c(tmpdir)'") rebuild topic("procurement")}{p_end}
{p 8 12 2}{stata `"type "$pbdemo/_documentation/_project_meta.txt""':. type "$pbdemo/_documentation/_project_meta.txt"}{p_end}

{pstd}{bf:Step 8.} Last, run the control file. It sets the path globals every
other do-file in the project relies on, and it is the only file you edit if the
project ever moves:{p_end}
{p 8 12 2}{stata `"do "$pbdemo/_code/000_control.do""':. do "$pbdemo/_code/000_control.do"}{p_end}
{p 8 12 2}{stata "macro list root raw cleaned":. macro list root raw cleaned}{p_end}

{pstd}
Run this one last, because the control file begins with {cmd:clear all}: it
drops the auto data the steps above were using. ({cmd:clear all} clears data
and programs but leaves globals alone, so {cmd:$pbdemo} survives it.) That is
the control file doing its job at the top of a pipeline, not something
{cmd:projectbuilder} does to you.{p_end}

{pstd}
Nothing needs cleaning up. The demo sits in your temporary directory, which the
operating system clears on its own schedule. {cmd:projectbuilder} makes no
shell call and never deletes anything, so removing a project is always
something you do yourself.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
Every example below runs as written, top to bottom, in one directory. The names
are all distinct, so nothing trips the clobber guard, and the {opt rebuild}
examples refresh a project an earlier line created. Paths use forward slashes,
which Stata accepts on Windows as well as macOS and Linux.{p_end}

{pstd}Scaffold an empty project in the current directory, then look at the
documentation it wrote:{p_end}
{cmd}{...}
        . projectbuilder Ex01Feed, description("Monthly vendor extract")
        . type "Ex01Feed/_documentation/Readme.md"
{txt}{...}

{pstd}Scaffold under a named base directory instead of the current one. The
base is created if its parent already exists:{p_end}
{cmd}{...}
        . projectbuilder Ex02Feed, path("projects")
{txt}{...}

{pstd}Scaffold a subsource under a source; the project label joins them with an
underscore, so the analytic file is {cmd:Agency_Extract_analytic.dta}:{p_end}
{cmd}{...}
        . projectbuilder Agency/Extract, description("One agency extract")
{txt}{...}

{pstd}Quote a name that contains a space. An unquoted second word is an error,
not a longer folder name:{p_end}
{cmd}{...}
        . projectbuilder "Vendor Feed 2027", description("Quoted name")
{txt}{...}

{pstd}Refresh a project after new files land in {cmd:01_raw/}. The recorded
metadata is kept, and edited do-files in {cmd:_code/} are left alone:{p_end}
{cmd}{...}
        . projectbuilder Ex01Feed, rebuild
{txt}{...}

{pstd}Change one recorded value on a refresh; everything else stays as it
was:{p_end}
{cmd}{...}
        . projectbuilder Ex01Feed, rebuild topic("procurement")
{txt}{...}

{pstd}Refresh and reset the numbered do-files to the shipped templates,
discarding your edits to them:{p_end}
{cmd}{...}
        . projectbuilder Ex01Feed, rebuild replace
{txt}{...}

{pstd}Seed the profiler with the variables you already know you care about.
They are recorded, not validated, so it is safe to name variables the analytic
file does not have yet:{p_end}
{cmd}{...}
        . projectbuilder Ex03Rates,                       ///
              outcomes(enroll_rate cost_pp) over(year region)
{txt}{...}

{pstd}Use the stored results to drive the next step of a script rather than
retyping the path:{p_end}
{cmd}{...}
        . mkdir "drop"
        . sysuse auto, clear
        . export delimited using "drop/auto.csv", replace
        . quietly projectbuilder Ex04Auto, data("drop")
        . display "built " r(project) " with " r(nraw) " raw file(s)"
        . display "it lives at " r(path)
{txt}{...}

{pstd}Refresh a whole set of projects on a schedule. Each call is idempotent,
so this is safe to rerun:{p_end}
{cmd}{...}
        . foreach p in Ex01Feed Ex03Rates Ex04Auto {c -(}
          2.     capture noisily projectbuilder `p', rebuild
          3. {c )-}
{txt}{...}

{pstd}Scaffold and ingest in one call: copy a folder of files in, record every
piece of metadata at once, and seed the profiler. This reuses the {cmd:drop}
folder made two examples above:{p_end}
{cmd}{...}
        . projectbuilder Ex07Budgets,                                    ///
              data("drop")                                               ///
              description("County budget CSVs, one row per dept per FY") ///
              topic("local government, budgets") publicfacing(unsure)    ///
              timeline("annual") outcomes(total_budget) over(year dept)  ///
              descsave
{txt}{...}

{pstd}Record a source URL. It is fetched now if the address is reachable, and
the fetch is written into {cmd:100_data_download.do} either way. The address
below is a placeholder, so expect the fetch to miss and the scaffold to be
built anyway; that is the behavior to rely on when a source is temporarily
down:{p_end}
{cmd}{...}
        . projectbuilder Ex08Open, url("https://example.com/data.csv")
{txt}{...}

{pstd}Scaffold without running the convert/combine pass, so
{cmd:01_raw/_converted/} and the analytic file are not built. Files named in
{opt data()} are still copied into {cmd:01_raw/}. This is also the fastest
option when a large dataset is loaded, since it skips the {helpb preserve} the
pass would otherwise do:{p_end}
{cmd}{...}
        . projectbuilder Ex05Feed, noautoconvert
{txt}{...}

{pstd}Rebuild and render the documentation with {cmd:webdoc2} when it is
installed:{p_end}
{cmd}{...}
        . projectbuilder Ex01Feed, rebuild builddocs
{txt}{...}

{pstd}Write a literal dollar sign. Stata expands {cmd:$total} before
{cmd:projectbuilder} ever sees it, so escape it:{p_end}
{cmd}{...}
        . projectbuilder Ex06Cost, description("Reported in \$ millions")
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
