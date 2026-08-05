{smcl}
{* *! version 2.0.0 26may2026 Eric A. Booth and Elizabeth Teas}{...}
{vieweralsosee "doedit"   "help doedit"}{...}
{vieweralsosee "findfile" "help findfile"}{...}
{vieweralsosee "view"     "help view"}{...}
{vieweralsosee "viewsource" "help viewsource"}{...}
{viewerjumpto "Syntax"      "editanything##syntax"}{...}
{viewerjumpto "Description" "editanything##description"}{...}
{viewerjumpto "Options"     "editanything##options"}{...}
{viewerjumpto "Examples"    "editanything##examples"}{...}
{viewerjumpto "Returns"     "editanything##returns"}{...}
{viewerjumpto "Remarks"     "editanything##remarks"}{...}
{viewerjumpto "Authors"     "editanything##authors"}{...}
{hline}
Help file for {hi:editanything}
{hline}

{title:Title}

{phang}
{bf:editanything} {hline 2} Open any text file in Stata's Do-file Editor, Viewer, or your OS default app


{marker syntax}{...}
{title:Syntax}

{phang2}
{cmd:editanything} {it:filename} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Open mode (pick at most one; default is the Do-file Editor)}
{synopt:{opt ed:itor}}open in the Do-file Editor (default){p_end}
{synopt:{opt v:iew}}open read-only in the Viewer (renders SMCL for {it:.sthlp}/{it:.hlp}/{it:.smcl}){p_end}
{synopt:{opt ext:ernal}}hand off to the OS default application for that file type{p_end}
{synopt:{opt show:path}}print a clickable file path; do not open anything{p_end}
{synopt:{opt clip:board}}copy the file's contents to the system clipboard{p_end}

{syntab :File resolution}
{synopt:{opt ext:ension(str)}}default extension to try when {it:filename} has none (default: {bf:ado}){p_end}
{synopt:{opt personal}}look in {bf:c(sysdir_personal)} first when searching{p_end}
{synopt:{opt new}}create a new empty file at {it:filename} and open it{p_end}

{syntab :Safety / behavior}
{synopt:{opt rep:lace}}copy a Stata-supplied (base/updates) ado into PERSONAL, then open the copy{p_end}
{synopt:{opt f:orce}}edit a Stata-supplied file in place anyway, or bypass the 32 KB size guard{p_end}
{synopt:{opt q:uietly}}suppress the file-info banner{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:editanything} is a one-command replacement for SSC's {help adoedit:adoedit}
that works on {it:any} text file — not just {it:.ado}.  Point it at a filename
(with or without an extension) and it will:

{phang2}1.  Search the current directory, the full ado-path
    ({help adopath}), and {bf:PERSONAL} for the file.{p_end}
{phang2}2.  Optionally fall back to common extensions ({bf:.ado}, {bf:.sthlp},
    {bf:.hlp}, {bf:.do}) when none is given.{p_end}
{phang2}3.  Show a clickable path plus the file's size and detected
    extension.{p_end}
{phang2}4.  Dispatch to the requested viewer/editor/external app.{p_end}

{pstd}
Supported text formats (this is just the {it:tested} list — anything plain-text
will open):

{phang2}
{bf:Stata} — {it:.ado .sthlp .hlp .smcl .do .mata .gph}{break}
{bf:Markup / docs} — {it:.md .markdown .html .htm .tex .bib .xml .rst}{break}
{bf:Data}  — {it:.csv .tsv .txt .raw .log}{break}
{bf:Code}  — {it:.R .r .py .js .css .sql .sh .bat .ps1}{break}
{bf:Config} — {it:.json .yaml .yml .toml .ini .cfg .conf .env}
{p_end}

{pstd}
Non-text files (e.g. {it:.dta}, {it:.xlsx}, {it:.pdf}, {it:.png}) cannot be
opened in the Do-file Editor, but {opt external} will hand them off to your
OS default app.


{marker options}{...}
{title:Options}

{dlgtab:Open mode}

{phang}
{opt editor} (default) opens the resolved file in Stata's Do-file Editor with
{help doedit}.  Files larger than 32 KB cannot be opened on Stata < 11 — see
{opt force} and {opt external} below.

{phang}
{opt view} opens the file read-only in the Viewer.  For {it:.sthlp}, {it:.hlp},
and {it:.smcl} files the SMCL is rendered; for everything else the raw text is
shown verbatim ({cmd:view "{it:file}", asis}).  Handy for skimming long help
files or logs without risking edits.

{phang}
{opt external} delegates to your OS default app via {help winexec}
({cmd:open} on macOS, {cmd:start} on Windows, {cmd:xdg-open} on Linux).  Use
this for files that exceed the Do-file Editor's size limit or that are not
plain text (e.g. {it:.pdf}, {it:.xlsx}, {it:.dta}, images).

{phang}
{opt showpath} skips opening the file entirely and just prints the clickable
{help browse} link.  Useful in scripts where you want the path returned in
{cmd:r(file)} without launching the editor.

{phang}
{opt clipboard} copies the raw contents of the resolved file to the system
clipboard (uses {cmd:pbcopy} on macOS, {cmd:clip} on Windows, {cmd:xclip} on
Linux).  Great for pasting a snippet into a Slack message or an email.

{dlgtab:File resolution}

{phang}
{opt extension(str)} sets the default extension to try when {it:filename}
has none.  The default is {bf:ado}.  Example: {cmd:editanything mynotes, ext(md)}
will look for {bf:mynotes.md} on the ado-path.

{phang}
{opt personal} looks in {bf:c(sysdir_personal)} ({bf:`c(sysdir_personal)'})
{it:first} when resolving the filename.  Useful when you have a local override
of a community-contributed ado.

{phang}
{opt new} creates a brand-new empty file at {it:filename} (in {help pwd:pwd}
if no path is given), then opens it in the Do-file Editor.  Errors if a file
already exists at that path.

{dlgtab:Safety / behavior}

{phang}
{opt replace} is the recommended pattern for tweaking Stata-supplied ados:
it copies {bf:/ado/base/.../foo.ado} into {bf:c(sysdir_personal)} and opens
the copy, so Stata updates won't overwrite your edits.

{phang}
{opt force} bypasses the two guardrails: it edits Stata-supplied files in
place and skips the 32 KB do-edit size check on Stata < 11.

{phang}
{opt quietly} suppresses the file-info banner (path / size / type / flags).


{marker examples}{...}
{title:Examples}

{pstd}{ul:Open an ado from the ado-path}{p_end}
{phang2}{cmd:. editanything regress}              {it:(finds regress.ado)}{p_end}
{phang2}{cmd:. editanything regress.ado}{p_end}

{pstd}{ul:Open a help file in the Viewer (rendered SMCL)}{p_end}
{phang2}{cmd:. editanything regress.sthlp, view}{p_end}

{pstd}{ul:Edit any non-Stata text file from the Do-file Editor}{p_end}
{phang2}{cmd:. editanything README.md}{p_end}
{phang2}{cmd:. editanything analysis.py}{p_end}
{phang2}{cmd:. editanything pipeline.R}{p_end}
{phang2}{cmd:. editanything "config/settings.toml"}{p_end}

{pstd}{ul:Peek at a CSV without importing it}{p_end}
{phang2}{cmd:. editanything raw/survey_responses.csv, view}{p_end}

{pstd}{ul:Open a big log in the OS default text editor}{p_end}
{phang2}{cmd:. editanything analysis.log, external}{p_end}

{pstd}{ul:Safely customize a Stata-supplied ado}{p_end}
{phang2}{cmd:. editanything ttest, replace}        {it:(clones to PERSONAL, opens copy)}{p_end}

{pstd}{ul:Start a brand-new file in the current directory}{p_end}
{phang2}{cmd:. editanything new_helper, new}                  {it:(makes new_helper.ado)}{p_end}
{phang2}{cmd:. editanything project_notes, new ext(md)}       {it:(makes project_notes.md)}{p_end}

{pstd}{ul:Find a file's path without opening it}{p_end}
{phang2}{cmd:. editanything regress, showpath}{p_end}
{phang2}{cmd:. display "`r(file)'"}{p_end}

{pstd}{ul:Snag a snippet to the clipboard for pasting elsewhere}{p_end}
{phang2}{cmd:. editanything mymodel.do, clipboard}{p_end}

{pstd}{ul:Prefer your own override over the community version}{p_end}
{phang2}{cmd:. editanything outreg2, personal}{p_end}


{marker returns}{...}
{title:Stored results}

{pstd}{cmd:editanything} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(size)}}file size in bytes (when detectable){p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(file)}}fully-resolved file path{p_end}
{synopt:{cmd:r(basename)}}filename portion only (no directory){p_end}
{synopt:{cmd:r(extension)}}detected extension (lowercased, no dot){p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}{ul:Why not just type {cmd:doedit}?}  Three reasons:

{phang2}1. {cmd:doedit} requires the {it:exact} path — {cmd:editanything} searches
   the ado-path so {cmd:editanything regress} just works.{p_end}
{phang2}2. {cmd:editanything} refuses to clobber Stata-supplied ados and offers
   {opt replace} to copy them into PERSONAL first.{p_end}
{phang2}3. {cmd:editanything} extends the workflow to any text file, not just
   {it:.ado} — same muscle memory for {it:.py}, {it:.md}, {it:.csv}, etc.{p_end}

{pstd}{ul:What about huge files?}  Stata's Do-file Editor cannot open files >
32 KB on Stata < 11, and very large files can be slow even on current Stata.
Use {opt external} to delegate to your OS editor (BBEdit, VS Code, Notepad++,
etc.) or {opt view} to skim read-only.

{pstd}{ul:Cross-platform path handling.}  Backslashes are normalized to forward
slashes for display, leading {bf:~} is expanded to {bf:$HOME}, and the
clipboard / external-app calls dispatch to the right OS-native tool.


{marker authors}{...}
{title:Authors}

{pstd}
Eric A. Booth{break}
Texas 2036{break}
Email: {browse "mailto:eric.a.booth@gmail.com":eric.a.booth@gmail.com}{break}
GitHub: {browse "https://www.github.com/ericabooth":www.github.com/ericabooth}

{pstd}
Elizabeth Teas{break}
Sr Research Scientist, Far Harbor, LLC{break}
Email: {browse "mailto:elizabeth@farharbor.com":elizabeth@farharbor.com}{break}


{pstd}
Issues and pull requests welcome at
{browse "https://github.com/ericabooth/EditAnything-stata-public":github.com/ericabooth/EditAnything-stata-public}.
