{smcl}
{* *! version 1.4.0 21Sep2025}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "bf##syntax"}{...}
{viewerjumpto "Description" "bf##description"}{...}
{viewerjumpto "Options" "bf##options"}{...}
{viewerjumpto "Examples" "bf##examples"}{...}
{title:Title}

{phang}
{bf:bf} {hline 2} Create directory structure for Dingyuan Accounting academic projects

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:bf} {it:issue} [{cmd:,} {opt lang*uage:(string)}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt lang*uage:(string)}}specify language for directory names (en/cn); may be abbreviated to {bf:lang}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:bf} creates a standardized directory structure for Dingyuan Accounting academic projects.
The command automatically detects available hard drives and prioritizes E drive, then D drive,
avoiding the system C drive (unless only C drive is available).

{pstd}
The {opt language()} option allows creating directory structures with either English or Chinese names.

{pstd}
If directories already exist, they will be overwritten/recreated to ensure a clean setup.

{marker options}{...}
{title:Options}

{phang}
{it:issue} specifies the issue number for creating the corresponding directory name.

{phang}
{opt lang*uage:(string)} specifies the language for directory names. Valid values are:
{p_end}
{pmore}{opt en}: English directory names (default){p_end}
{pmore}{opt cn}: Chinese directory names{p_end}
{pmore}Minimum abbreviation is {bf:lang}.{p_end}

{marker examples}{...}
{title:Examples}

{phang}
{stata "bf 202501"}

{pstd}
Create directory structure for Dingyuan Accounting Issue 202501 with English names.

{phang}
{stata "bf 202501, lang(en)"}

{pstd}
Create directory structure for Dingyuan Accounting Issue 202501 with English names (using abbreviation).

{phang}
{stata "bf 202501, language(cn)"}

{pstd}
Create directory structure for Dingyuan Accounting Issue 202501 with Chinese names.

{title:Directory Structure}

{pstd}
This command automatically creates the following directory structure on the selected drive:{p_end}
{pstd}English structure:{p_end}
{pstd}1. Academic Friends - base directory{p_end}
{pstd}2. Dingyuan Accounting [issue] - project directory{p_end}
{pstd}3. model - for statistical models{p_end}
{pstd}4. data - for datasets{p_end}
{pstd}5. program - for Stata do-files{p_end}
{pstd}6. report - for reports and outputs{p_end}

{pstd}Chinese structure:{p_end}
{pstd}1. 益友学术 - base directory{p_end}
{pstd}2. 鼎园会计 [issue] - project directory{p_end}
{pstd}3. 模型 - for statistical models{p_end}
{pstd}4. 数据 - for datasets{p_end}
{pstd}5. 程序 - for Stata do-files{p_end}
{pstd}6. 报告 - for reports and outputs{p_end}

{title:Drive Selection Algorithm}

{pstd}
The command uses the following algorithm to select the appropriate drive:{p_end}
{pstd}1. Prefer E drive if available{p_end}
{pstd}2. Then prefer D drive if available{p_end}
{pstd}3. Then any non-C drive{p_end}
{pstd}4. Finally use C drive if no other options{p_end}

{title:Authors}

{pstd}
Wu Lianghai{p_end}
{pstd}School of Business, Anhui University of Technology, Ma'anshan, China{p_end}
{pstd}E-mail:{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}

{pstd}
Chen Liwen{p_end}
{pstd}School of Business, Anhui University of Technology, Ma'anshan, China{p_end}
{pstd}E-mail:{browse "mailto:2184844526@qq.com":2184844526@qq.com}{p_end}

{pstd}
Wu Hanyan{p_end}
{pstd}School of Economics and Management, Nanjing University of Aeronautics and Astronautics (NUAA){p_end}
{pstd}E-mail:{browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{pstd}
Ma'anshan/Nanjing, China{p_end}

{title:Acknowledgments}

{pstd}
We sincerely appreciate Christopher F. Baum for his prompt guidance and revision suggestions.

{title:Also see}

{pstd}
Online: {help mkdir}, {help cd}
{*}