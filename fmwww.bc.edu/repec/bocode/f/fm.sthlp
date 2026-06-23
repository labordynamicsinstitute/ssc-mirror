{smcl}
{* *! version 1.0.1  22June2026}{...}
{hline}
{title:fm — File classification manager}
{hline}

{p 4 4 2}
{cmd:fm} classifies files in a specified directory by their first
English character and moves them into corresponding alphabetical
subdirectories. This is useful for keeping personal ado directories,
project folders, or any file collection tidy and easy to navigate.

{title:Syntax}

{p 4 4 2}
{cmdab:fm} [{it:directory_path}] [{opt ,} {opt r:eplace} {opt dryrun}]

{p 4 4 2}
If {it:directory_path} is omitted, the current working directory
({cmd:c(pwd)}) is used.

{title:Description}

{p 4 4 2}
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

{title:Options}

{p 4 8 2}
{opt r:eplace} specifies that existing files in the destination
subdirectory may be overwritten. The default behavior is to skip files
that already exist in the target subdirectory and display a warning.

{p 4 8 2}
{opt dryrun} runs the program in preview mode. The planned file moves
are displayed to the screen, but no files or directories are actually
created, copied, or erased. Use this to see what would happen before
committing to changes.

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
Organize the current working directory with replace:{p_end}
{p 4 8 2}{cmd:fm , replace}{p_end}

{title:Remarks}

{p 4 4 2}
{cmd:fm} only processes files at the top level of the target directory.
Subdirectories and their contents are ignored.

{p 4 4 2}
Category subdirectories (a/ through z/, 0-9/, and _other/) are
automatically created as needed. They will not be created if no files
require a particular category.

{p 4 4 2}
Hidden files (those whose names begin with a dot) are placed in the
{bf:_other/} category.

{p 4 4 2}
Files that share the same name and target category will collide.
Without the {opt replace} option, the second and subsequent occurrences
are skipped with a warning. Use {opt replace} to overwrite them.

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
fm.ado v1.0.1, 22June2026.

{title:Also see}

{p 4 8 2}
{help dir}  {help mkdir}  {help copy}  {help erase}

{hline}
