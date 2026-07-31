{smcl}
{* *! version 1.0.0  2026-07-20}{...}
{viewerjumpto "Syntax" "projectbackup##syntax"}{...}
{viewerjumpto "Description" "projectbackup##description"}{...}
{viewerjumpto "Getting started" "projectbackup##quickstart"}{...}
{viewerjumpto "Options" "projectbackup##options"}{...}
{viewerjumpto "Safety checks" "projectbackup##safety"}{...}
{viewerjumpto "The backup log" "projectbackup##log"}{...}
{viewerjumpto "Stata Journal (.zippy)" "projectbackup##zippy"}{...}
{viewerjumpto "Stored results" "projectbackup##results"}{...}
{viewerjumpto "Examples" "projectbackup##examples"}{...}
{viewerjumpto "Remarks" "projectbackup##remarks"}{...}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{cmd:projectbackup} {hline 2}}Zip up a project folder, subfolders included, in native Stata{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmd:projectbackup} [{it:folder}] [{cmd:,} {it:options}]

{p 4 4 2}
{it:folder} is the directory to back up.  If omitted, the current working
directory ({cmd:c(pwd)}) is used.  Quote it if it contains spaces.

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Where it goes}
{synopt :{cmdab:arch:ive(}{it:dir}{cmd:)}}folder to hold the zip; default {it:folder}{cmd:/_archive}{p_end}
{synopt :{cmdab:pre:fix(}{it:str}{cmd:)}}zip-name prefix; default {cmd:backup_}{it:foldername}{p_end}
{synopt :{cmd:replace}}overwrite an existing zip of the same name{p_end}

{syntab :Naming}
{synopt :{cmdab:time:stamp}}append {cmd:_YYYYMMDD_HHMMSS}, so every backup is unique and sorts by date{p_end}
{synopt :{cmdab:lab:el(}{it:str}{cmd:)}}insert a tag into the name, e.g. {cmd:label(pre-refactor)}{p_end}

{syntab :What goes in}
{synopt :{cmdab:ex:clude(}{it:patterns}{cmd:)}}top-level files/folders to skip; {cmd:*} and {cmd:?} wildcards ok{p_end}
{synopt :{cmdab:nodot:files}}skip top-level dot-entries ({cmd:.git}, {cmd:.DS_Store}, ...){p_end}

{syntab :Log and manifest}
{synopt :{cmd:toc}}create/append {cmd:_backup_log.md} in the archive folder{p_end}
{synopt :{cmdab:note:(}{it:str}{cmd:)}}note recorded in the log row (turns on {cmd:toc}){p_end}
{synopt :{cmdab:man:ifest}}write {it:zipname}{cmd:_manifest.txt} listing every archived file{p_end}

{syntab :Housekeeping}
{synopt :{cmd:keep(}{it:#}{cmd:)}}after backing up, keep only the newest {it:#} timestamped backups{p_end}
{synopt :{cmdab:removeall}}delete all matching backups and make no new one{p_end}

{syntab :Stata Journal}
{synopt :{cmdab:zippy}}also save a {cmd:.zippy} copy (an email-safe {cmd:.zip} for SJ submissions){p_end}

{syntab :Look before you leap}
{synopt :{cmdab:dry:run}}scan and report size/counts/path lengths only; write nothing{p_end}
{synopt :{cmdab:man:ifest}}(above) can be combined with {cmd:dryrun} once you commit to writing{p_end}
{synopt :{cmd:force}}override the size / file-count safety stops{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:projectbackup} archives a folder and everything under it into a single
{cmd:.zip}, using nothing but Stata's own {helpb zipfile} and Mata.  There is no
shelling out, no {cmd:tar}, {cmd:7z}, or PowerShell -- so the same command works
the same way on macOS, Windows, and Linux, and inside restricted environments
where you cannot run external programs.

{pstd}
It is built for the everyday "snapshot my project" habit: point it at a project
folder and it drops a dated zip into an {cmd:_archive} subfolder, optionally
keeping a running Markdown log of every backup you have taken.  Before it writes
anything it walks the tree and warns you about the things that make zipping go
wrong -- a folder that is too big, too many files, or paths so deeply nested
that Windows will refuse to extract them.


{marker quickstart}{...}
{title:Getting started}

{pstd}
Back up the current project to {cmd:./_archive/backup_}{it:foldername}{cmd:.zip}:

{p 8 12 2}{cmd:. projectbackup}{p_end}

{pstd}
Back up a specific folder, with a unique dated name and a log entry:

{p 8 12 2}{cmd:. projectbackup "~/Documents/MyProject", timestamp toc}{p_end}

{pstd}
Not sure how big it is?  Measure first, write nothing:

{p 8 12 2}{cmd:. projectbackup "~/Documents/MyProject", dryrun}{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Where it goes}

{phang}
{cmd:archive(}{it:dir}{cmd:)} is the folder the zip is written to.  The default
is an {cmd:_archive} subfolder of the source folder, which is created if it does
not exist (its parent must already exist).  {cmd:projectbackup} never packs its
own archive folder into the backup when that folder sits at the top level of the
source -- so your old backups are not nested inside each new one.

{phang}
{cmd:prefix(}{it:str}{cmd:)} sets the leading part of the zip name.  The default
is {cmd:backup_} followed by the source folder's name.  Spaces become
underscores.

{phang}
{cmd:replace} overwrites an existing zip of the same name.  Without it, a name
clash is an error (so a backup is never silently destroyed).  With {cmd:timestamp}
you rarely need {cmd:replace}, because each name is unique.

{dlgtab:Naming}

{phang}
{cmd:timestamp} appends {cmd:_YYYYMMDD_HHMMSS} to the name.  This makes every
backup unique and -- crucially -- makes the names sort chronologically, which is
what {cmd:keep()} relies on.

{phang}
{cmd:label(}{it:str}{cmd:)} inserts your own tag, e.g.
{cmd:backup_myproj_pre-refactor.zip}.  Combine with {cmd:timestamp} to get both a
label and a date.

{dlgtab:What goes in}

{phang}
{cmd:exclude(}{it:patterns}{cmd:)} lists top-level files or folders to leave out,
separated by spaces; {cmd:*} and {cmd:?} wildcards are allowed and matching is
case-insensitive.  Quoting the whole list or each pattern makes no difference:
{cmd:exclude("data output .git")} and {cmd:exclude(data output .git)} behave
identically.  To match a name that contains a space, use a wildcard, e.g.
{cmd:exclude(raw*)} for a folder named {cmd:raw data}.  Exclusions apply at the
top level only -- a subfolder named {cmd:output} nested three levels down is kept.

{phang}
{cmd:nodotfiles} skips every top-level entry whose name starts with a dot
({cmd:.git}, {cmd:.Rhistory}, {cmd:.DS_Store}, ...).  Handy for excluding version
-control and OS clutter without naming each one.

{dlgtab:Log and manifest}

{phang}
{cmd:toc} creates {cmd:_backup_log.md} in the archive folder if it does not
exist, then appends one row per backup (date, time, archive name, file count,
size, note).  The log is a plain Markdown table, written with Stata's
{helpb file} command, so it renders on GitHub and reads fine in any editor.  See
{help projectbackup##log:The backup log}.

{phang}
{cmd:note(}{it:str}{cmd:)} records a free-text note in the log row and turns on
{cmd:toc} automatically.  A pipe ({cmd:|}) in the note is replaced by a slash so
it cannot break the Markdown table.

{phang}
{cmd:manifest} writes {it:zipname}{cmd:_manifest.txt} beside the zip: a sorted,
plain-text list of every file that went in (paths relative to the source
folder).  Useful as a quick "what was in that backup" index without unzipping.

{dlgtab:Housekeeping}

{phang}
{cmd:keep(}{it:#}{cmd:)} keeps only the newest {it:#} {bf:timestamped} backups
for this prefix, deleting older ones (and their {cmd:.zippy} twins) right after a
successful backup.  Only names carrying a {cmd:_YYYYMMDD_HHMMSS} stamp are
eligible, because only those sort by date; labelled or plain backups are never
pruned.  Use {cmd:keep()} together with {cmd:timestamp}.

{phang}
{cmd:removeall} deletes every backup ({cmd:.zip} and {cmd:.zippy}) that matches
the current prefix in the archive folder, and does {it:not} create a new one.
This is the cleanup counterpart to a normal run.

{dlgtab:Stata Journal}

{phang}
{cmd:zippy} additionally saves the archive with a {cmd:.zippy} extension.  The
{browse "https://www.stata-journal.com/submissions/":Stata Journal} asks authors
to rename {cmd:.zip} attachments (mail servers often strip {cmd:.zip}); a
{cmd:.zippy} file is a byte-for-byte copy that survives email, and the recipient
renames it back to {cmd:.zip}.  See {help projectbackup##zippy:Stata Journal}.

{dlgtab:Look before you leap}

{phang}
{cmd:dryrun} does the full scan -- file count, total size, largest file, deepest
nesting, longest path -- and prints a report {it:without writing anything}.  It
is the safe way to size up an unfamiliar or possibly huge folder.

{phang}
{cmd:force} overrides the hard safety stops (see below).  It has no effect on the
soft warnings, which never block a backup.


{marker safety}{...}
{title:Safety checks}

{pstd}
Before writing, {cmd:projectbackup} walks the whole tree in Mata and checks for
the conditions that make zipping fail, hang, or produce an archive that will not
open elsewhere.  There are two tiers.

{pstd}
{bf:Hard stops} (backup refused unless you add {cmd:force}):

{p2colset 8 22 24 2}{...}
{p2col :{space 2}total size > 2 GB}Stata's {help zipfile} is single-threaded and offers no compression tuning; multi-GB zips are slow and can fail to open in older unzip tools.{p_end}
{p2col :{space 2}any file > 2 GB}the classic ZIP format's per-file limit; large individual files are the usual culprit.{p_end}
{p2col :{space 2}> 100,000 files}the file count at which the walk and the zip both become impractically slow.{p_end}
{p2colreset}{...}

{pstd}
{bf:Soft warnings} (printed, but the backup proceeds):

{p2colset 8 22 24 2}{...}
{p2col :{space 2}size > 500 MB}"this may take a while."{p_end}
{p2col :{space 2}> 20,000 files}"this may take a while."{p_end}
{p2col :{space 2}path > 200 chars}Windows extraction may hit the 260-character {cmd:MAX_PATH} limit; the offending path is shown.{p_end}
{p2colreset}{...}

{pstd}
When a hard stop fires, {cmd:projectbackup} prints concrete advice: exclude the
heavy subfolders and back up code separately from data, split big subfolders into
their own zips, or reach for a dedicated archiver for genuinely multi-GB trees.
Run with {cmd:dryrun} to see all of this without committing.


{marker log}{...}
{title:The backup log}

{pstd}
With {cmd:toc} (or {cmd:note()}), a Markdown table named {cmd:_backup_log.md}
accumulates in the archive folder, e.g.:

{p 8 8 2}{c |} date {c |} time {c |} archive {c |} files {c |} size {c |} note {c |}{p_end}
{p 8 8 2}{c |}------{c |}------{c |}---------{c |}-------{c |}------{c |}------{c |}{p_end}
{p 8 8 2}{c |} 20 Jul 2026 {c |} 21:37:53 {c |} backup_myproj_20260720_213753.zip {c |} 128 {c |} 4.2 MB {c |} pre-refactor {c |}{p_end}

{pstd}
Newest rows are appended at the bottom.  Because it is plain Markdown it renders
as a table on GitHub and stays readable as text everywhere else.


{marker zippy}{...}
{title:Stata Journal submissions (.zippy)}

{pstd}
{cmd:zippy} is a convenience for authors submitting to the
{it:Stata Journal}.  Their submission guidelines ask that {cmd:.zip} files be
renamed before emailing, because many mail systems block or quarantine
{cmd:.zip} attachments.  {cmd:projectbackup, ... zippy} writes both the normal
{cmd:.zip} and an identical copy ending in {cmd:.zippy}; you attach the
{cmd:.zippy}, and the editor renames it back to {cmd:.zip} on receipt.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:projectbackup} is {cmd:rclass}.  A normal run stores:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt :{cmd:r(nfiles)}}number of files archived{p_end}
{synopt :{cmd:r(ndirs)}}number of subfolders{p_end}
{synopt :{cmd:r(bytes)}}total uncompressed size, in bytes{p_end}
{synopt :{cmd:r(zipbytes)}}size of the written zip, in bytes{p_end}
{synopt :{cmd:r(maxdepth)}}deepest nesting level{p_end}
{synopt :{cmd:r(maxplen)}}longest relative path, in characters{p_end}
{synopt :{cmd:r(seconds)}}wall-clock time taken{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt :{cmd:r(zipfile)}}full path of the zip written{p_end}
{synopt :{cmd:r(zippy)}}full path of the {cmd:.zippy} copy (with {cmd:zippy}){p_end}
{synopt :{cmd:r(folder)}}source folder (absolute){p_end}
{synopt :{cmd:r(archive)}}archive folder (absolute){p_end}
{synopt :{cmd:r(size)}}human-readable total size{p_end}

{pstd}
{cmd:dryrun} stores everything except {cmd:r(zipfile)}, {cmd:r(zipbytes)}, and
{cmd:r(seconds)}.  {cmd:removeall} stores {cmd:r(archive)} and
{cmd:r(nremoved)} (count of files deleted).


{marker examples}{...}
{title:Examples}

{pstd}{bf:1. Simplest possible -- back up the current project}{p_end}
{p 8 12 2}{cmd:. projectbackup}{p_end}

{pstd}{bf:2. Dated snapshot with a log entry}{p_end}
{p 8 12 2}{cmd:. projectbackup ".", timestamp toc}{p_end}

{pstd}{bf:3. Measure a folder before committing to a backup}{p_end}
{p 8 12 2}{cmd:. projectbackup "~/BigStudy", dryrun}{p_end}

{pstd}{bf:4. Back up code only -- skip data, output, and version control}{p_end}
{p 8 12 2}{cmd:. projectbackup, exclude(data output *.dta) nodotfiles timestamp}{p_end}

{pstd}{bf:5. A named milestone snapshot}{p_end}
{p 8 12 2}{cmd:. projectbackup, label(before-reviewer-revisions) timestamp toc note(v1 submitted)}{p_end}

{pstd}{bf:6. Rolling snapshots -- keep only the five most recent}{p_end}
{p 8 12 2}{cmd:. projectbackup, timestamp keep(5)}{p_end}

{pstd}{bf:7. Send the archive somewhere outside the project}{p_end}
{p 8 12 2}{cmd:. projectbackup "~/Documents/MyProject", archive("~/Dropbox/backups") timestamp}{p_end}

{pstd}{bf:8. A record of exactly what was archived}{p_end}
{p 8 12 2}{cmd:. projectbackup, manifest timestamp}{p_end}

{pstd}{bf:9. Package a folder for a Stata Journal submission}{p_end}
{p 8 12 2}{cmd:. projectbackup "~/sj-package", zippy}{p_end}

{pstd}{bf:10. Clear out every backup for this project}{p_end}
{p 8 12 2}{cmd:. projectbackup, removeall}{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
Paths inside the zip are stored relative to the source folder, so unzipping in an
empty directory reproduces the project's layout exactly (no absolute-path
folders).  Zipping is done through a single {help zipfile} call after the tree
has been scanned, so the file count and size you are warned about are the file
count and size that go in.

{pstd}
Because everything is native, {cmd:projectbackup} runs in the same command on any
platform Stata supports and needs no configuration.  The one platform-specific
caveat is Windows' 260-character path limit on extraction, which the long-path
warning is there to catch in advance.


{title:Author}

{pstd}Eric A. Booth.  Feedback to {browse "mailto:eric.a.booth@gmail.com":eric.a.booth@gmail.com}.{p_end}


{title:Also see}

{psee}
Online:  {helpb zipfile}, {helpb unzipfile}, {helpb file}, {helpb mkdir}
{p_end}
