{smcl}
{* *! version 1.8 28Dec2025}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "help doedit" "help doedit"}{...}
{vieweralsosee "help findfile" "help findfile"}{...}
{viewerjumpto "Syntax" "myedit##syntax"}{...}
{viewerjumpto "Description" "myedit##description"}{...}
{viewerjumpto "Examples" "myedit##examples"}{...}
{viewerjumpto "Remarks" "myedit##remarks"}{...}
{viewerjumpto "Authors" "myedit##authors"}{...}

{hline}
{center:{bf:myedit - Smart Stata Ado File Editor}}
{hline}

{pstd}
{cmd:myedit} is an intelligent command that locates and opens Stata ado files for editing.
It automatically identifies whether a command is built-in, from the official base library,
from SSC (Statistical Software Components), or from your personal ado directory.
It provides appropriate warnings and restoration instructions based on the source of the file.
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:myedit} {it:command_name} [{cmd:.ado}]

{pstd}
{it:command_name} can be specified with or without the {cmd:.ado} extension.
{p_end}

{marker also_see}{...}
{title:Also see}

{pstd}
{p_end}
{pmore}
Related commands:
{p_end}
{pmore}
{help adoedit:adoedit} - Edit ado files with built-in editor
{p_end}
{pmore}
{help adotype:adotype} - Display ado file type and location
{p_end}
{pmore}
{help doedit:doedit} - Open do-file editor
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:myedit} enhances the standard {help doedit} command by providing intelligent file location
and context-aware editing. It performs the following actions:{p_end}

{pmore}1. Checks if the command is a Stata built-in command (no ado file){p_end}
{pmore}2. Searches for the ado file in Stata's search path{p_end}
{pmore}3. Identifies the source of the file (base, personal, or SSC){p_end}
{pmore}4. Provides appropriate warnings and restoration instructions{p_end}
{pmore}5. Opens the file in Stata's built-in editor{p_end}

{pstd}
The command is particularly useful for:{p_end}

{pmore}• Modifying personal ado files{p_end}
{pmore}• Examining SSC package implementations{p_end}
{pmore}• Learning from official Stata commands (with caution){p_end}
{pmore}• Creating backups of custom modifications{p_end}

{marker examples}{...}
{title:Examples}

{phang}{hline 60}{p_end}
{phang}{ul:{bf:Example 1: Edit a personal ado file}}{p_end}
{phang}{cmd:. myedit myfunction}{p_end}
{phang}Opens {cmd:myfunction.ado} from your personal ado directory with backup warning.{p_end}

{phang}{ul:{bf:Example 2: Edit an SSC package file}}{p_end}
{phang}{cmd:. myedit estout}{p_end}
{phang}Opens {cmd:estout.ado} from SSC directory with reinstallation instructions.{p_end}

{phang}{ul:{bf:Example 3: Edit a base ado file (with caution)}}{p_end}
{phang}{cmd:. myedit summarize}{p_end}
{phang}Shows that {cmd:summarize} is a built-in command (no ado file).{p_end}
{phang}{cmd:. myedit regress}{p_end}
{phang}Opens a copy of {cmd:regress.ado} from base directory with strong warnings.{break}
The original file is preserved, and a copy named {cmd:regress2.ado} is opened for editing.{p_end}

{phang}{ul:{bf:Example 4: Using with .ado extension}}{p_end}
{phang}{cmd:. myedit myprogram.ado}{p_end}
{phang}Same as {cmd:myedit myprogram} - the extension is automatically handled.{p_end}

{phang}{hline 60}{p_end}

{marker remarks}{...}
{title:Remarks}

{pstd}
{ul:{bf:File Sources and Warnings:}}{p_end}

{pmore}{bf:Base Directory:} Contains official Stata commands. {bf:Editing these files is risky.}{break}
For base files, {cmd:myedit} automatically creates a copy with a "2" suffix inserted before the extension (e.g., regress2.ado) to prevent accidental modification of original files.{break}
Always create backups before modification.{p_end}

{pmore}{bf:Personal Directory:} Contains user-defined ado files.{break}
These are safe to edit but backups are recommended.{p_end}

{pmore}{bf:SSC Directory:} Contains community-contributed packages.{break}
The command shows how to reinstall the original version if needed.{p_end}

{pstd}
{ul:{bf:Large Files:}}{p_end}

{pstd}
Files larger than 1MB trigger a warning as Stata's editor may not handle them well.
Consider using an external editor for such files.{p_end}

{pstd}
{ul:{bf:Cross-Platform Compatibility:}}{p_end}

{pstd}
{cmd:myedit} works on Windows, macOS, and Linux, handling path differences
between operating systems automatically.{p_end}

{marker authors}{...}
{title:Authors}

{pstd}
{bf:Wu Lianghai}{p_end}
{pmore}School of Business, Anhui University of Technology (AHUT){break}
Ma'anshan, China{p_end}
{pmore}Email: {browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}

{pstd}
{bf:Wu Hanyan}{p_end}
{pmore}School of Economics and Management{break}
Nanjing University of Aeronautics and Astronautics (NUAA){break}
Nanjing, China{p_end}
{pmore}Email: {browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{pstd}
{bf:Chen Liwen}{p_end}
{pmore}School of Business, Anhui University of Technology (AHUT){break}
Ma'anshan, China{p_end}
{pmore}Email: {browse "mailto:2184844526@qq.com":2184844526@qq.com}{p_end}

{marker acknowledgments}{...}
{title:Acknowledgments}

{pstd}
The authors would like to express their sincere gratitude to {bf:Christopher F. Baum} for his constructive suggestions that helped improve this program.{break}
His advice ensured the safety of ado files from Stata's distribution base file library by implementing proper file copying mechanisms.{p_end}

{pstd}
{bf:Version History:}{p_end}
{pmore}Version 1.8 (28 Dec 2025): Fixed Chinese text in version history, updated date{p_end}
{pmore}Version 1.7 (25 Dec 2025): All comments translated to English; added acknowledgments section{p_end}
{pmore}Version 1.6 (25 Dec 2025): Fixed _request() issue, using sleep command for pause{p_end}
{pmore}Version 1.5 (25 Dec 2025): Fixed more command issue, added user interaction prompt{p_end}
{pmore}Version 1.4 (25 Dec 2025): Improved user interface and warnings{p_end}
{pmore}Version 1.3 (15 Nov 2024): Added cross-platform path handling{p_end}
{pmore}Version 1.2 (10 Aug 2024): Enhanced SSC package detection{p_end}
{pmore}Version 1.1 (05 May 2024): Added file size checking{p_end}
{pmore}Version 1.0 (01 Jan 2024): Initial release{p_end}

{pstd}
Type {cmd:help myedit} to view this help file.{p_end}

{hline}
{pstd}
{it:This help file was generated on 28 Dec 2025.}
{p_end}
{*}