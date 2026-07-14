{smcl}
{* *! version 1.3.0  13July2026}{...}
{hline}
{title:fm — File manager}
{hline}

{p 4 4 2}
{cmd:fm} classifies files in a specified directory by their first
English character and moves them into corresponding alphabetical
subdirectories. With the {opt flatten} option, it reverses the
process — recursively moving all files from subdirectories back
into the current directory.

{title:Syntax}

{p 4 4 2}
{cmdab:fm} [{it:directory_path}] [{opt ,} {opt r:eplace} {opt dryrun}]

{p 4 4 2}
{cmdab:fm} [{it:directory_path}] {opt ,} {opt flatten} [{opt r:eplace} {opt dryrun}]

{p 4 4 2}
If {it:directory_path} is omitted, the current working directory
({cmd:c(pwd)}) is used.

{title:Description}

{p 4 4 2}
{cmd:fm} has two operating modes:

{p 4 4 2}
{bf:Classify mode (default)}{break}
{cmd:fm} scans all files (not subdirectories) in the target directory
and moves each file into a subdirectory named after the lowercase
first character of its filename. Three category groups determine the
target location:

{p 4 8 2}
{bf:a}–{bf:z}{break}
Files starting with an English letter (case-insensitive).
For example, {it:Apple.do} and {it:apple.ado} both go to {bf:a/}.

{p 4 8 2}
{bf:0-9}{break}
Files starting with a digit.
For example, {it:123data.csv} goes to {bf:0-9/}.

{p 4 8 2}
{bf:_other}{break}
Files starting with any other character — dots, underscores, Chinese
characters, symbols, etc.
For example, {it:.hiddenfile}, {it:_config.json}, and {it:数据.txt}
all go to {bf:_other/}.

{p 4 4 2}
{bf:Flatten mode} ({opt flatten}){break}
Recursively scans all subdirectories of the target directory and moves
every file found up to the target directory itself. After all files
have been moved, empty subdirectories are automatically removed. The
end result is a single flat folder containing all files — the reverse
of classify mode.

{p 4 4 2}
Files already at the top level of the target directory are not moved.
Only files within subdirectories (at any depth) are relocated.
Non-empty directories (e.g., those containing unreadable files or
protected subdirectories) are retained.

{title:Options}

{p 4 8 2}
{opt flatten} activates flatten mode. All files from all
subdirectories are recursively moved to the target directory. Without
this option, {cmd:fm} runs in the default classify mode.

{p 4 8 2}
{opt r:eplace} specifies that existing files in the destination
may be overwritten. In classify mode, this applies to files already
in the target category subdirectory. In flatten mode, it applies
to files already present at the target directory level. The default
behavior is to skip files and display a warning.

{p 4 8 2}
{opt dryrun} runs the program in preview mode. The planned file moves
and directory removals are displayed to the screen, but no files or
directories are actually created, copied, moved, or erased. Use this
to see what would happen before committing to changes.

{title:Examples}

{p 4 4 2}
Organize all files in a specific personal ado directory:{p_end}
{p 4 8 2}{cmd:fm D:/Stata18/ado/personal/}{p_end}

{p 4 4 2}
Preview what would happen in the current directory:{p_end}
{p 4 8 2}{cmd:fm , dryrun}{p_end}

{p 4 4 2}
Organize a project folder, overwriting any existing files:{p_end}
{p 4 8 2}{cmd:fm ./myproject/ , replace}{p_end}

{p 4 4 2}
Flatten all subdirectories into the current directory:{p_end}
{p 4 8 2}{cmd:fm , flatten}{p_end}

{p 4 4 2}
Preview flattening a specific folder:{p_end}
{p 4 8 2}{cmd:fm ./myproject/ , flatten dryrun}{p_end}

{p 4 4 2}
Flatten with overwrite for name collisions:{p_end}
{p 4 8 2}{cmd:fm ./myproject/ , flatten replace}{p_end}

{title:Remarks}

{p 4 4 2}
In classify mode, {cmd:fm} only processes files at the top level of
the target directory. Subdirectories and their contents are ignored.

{p 4 4 2}
In flatten mode, {cmd:fm} recursively processes all subdirectories
at any depth. Files already at the top level are left in place. After
moving all files, empty subdirectories are removed in multiple passes
(deepest first) so that the target directory contains only files. The
program uses shell-level file listing ({cmd:dir} / {cmd:find}) to
correctly handle filenames with spaces and special characters. If
shell commands are unavailable, it falls back to Stata's built-in
{cmd:dir} macro as a safety net.

{p 4 4 2}
Filenames containing spaces or special characters (e.g.,
{it:summary stats.doc}) are handled correctly in both classify and
flatten modes when the underlying shell supports standard listing
commands ({cmd:dir} on Windows, {cmd:find} or {cmd:ls} on
Unix / macOS / Git Bash).

{p 4 4 2}
Category subdirectories (a/ through z/, 0-9/, and _other/) are
automatically created as needed in classify mode. They will not be
created if no files require a particular category.

{p 4 4 2}
Hidden files (those whose names begin with a dot) are placed in the
{bf:_other/} category in classify mode.

{p 4 4 2}
Files that share the same name and target location will collide.
This is especially common in flatten mode when different
subdirectories contain files with the same name. Without the
{opt replace} option, subsequent occurrences are skipped with a
warning. Use {opt replace} to overwrite them.

{title:Authors}

{p 4 8 2}
{bf:Wu Lianghai}{break}
School of Business, Anhui University of Technology (AHUT){break}
Ma'anshan, Anhui, China{break}
{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}

{p 4 8 2}
{bf:Chen Liwen}{break}
School of Business, Anhui University of Technology (AHUT){break}
Ma'anshan, Anhui, China{break}
{browse "mailto:2184844526@qq.com":2184844526@qq.com}

{p 4 8 2}
{bf:Wu Hanyan}{break}
School of Economics and Management, NUAA{break}
Nanjing, Jiangsu, China{break}
{browse "mailto:2325476320@qq.com":2325476320@qq.com}

{title:Version}

{p 4 4 2}
fm.ado v1.3.0, 13July2026.

{title:Also see}

{p 4 8 2}
{help dir}  {help mkdir}  {help copy}  {help erase}

{hline}
