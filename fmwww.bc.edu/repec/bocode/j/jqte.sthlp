{smcl}
{hline}
{cmd:help jqte}
{p 4 4 2}
{vieweralsosee "cnuse" "net describe http://fmwww.bc.edu/repec/bocode/c/cnuse"}{p_end}
{p 4 4 2}
{vieweralsosee "topsis" "net describe http://fmwww.bc.edu/repec/bocode/t/topsis"}{p_end}
{p 4 4 2}
{vieweralsosee "log2md" "net describe http://fmwww.bc.edu/repec/bocode/l/log2md"}{p_end}
{p 4 4 2}
{vieweralsosee "sj1" "help sj1"}{p_end}
{p 4 4 2}
{vieweralsosee "cie" "help cie"}{p_end}
{p 4 4 2}
{vieweralsosee "jqte" "help jqte"}{p_end}
{p 4 4 2}
{vieweralsosee "" "--"}{p_end}


{viewerjumpto "Title" "jqte##title"}{...}
{viewerjumpto "Syntax" "jqte##syntax"}{...}
{viewerjumpto "Description" "jqte##description"}{...}
{viewerjumpto "Examples" "jqte##examples"}{...}
{viewerjumpto "Notes" "jqte##notes"}{...}
{viewerjumpto "Alsosee" "jqte##alsosee"}{...}

{title:Title}

{p2colset 5 16 16 2}{...}
{p2col:{hi: jqte} {hline 2}}Journal Navigation Tool for Journal of Quantitative & Technological Economics{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:jqte}
{it:year}
{it:issue}
[
{cmd:,}
{opt help}
]

{synoptset 20 tabbed}{...}
{synopthdr:Options}
{synoptline}
{synopt:{opt help}}Display this help document{p_end}
{synoptline}

{pstd}Parameter Description:{p_end}
{pstd}1. {it:year}: Four-digit year (2018 to present){p_end}
{pstd}2. {it:issue}: issue number (1-12){p_end}

{marker description}{...}
{title:Description}

{pstd}{cmd:jqte} command provides navigation functionality for the Journal of Quantitative & Technological Economics , supporting browsing and downloading of journal articles and their attachments.{p_end}

{pstd}This command directly accesses the official website data of Journal of Quantitative & Technological Economics, supporting browsing and attachment downloads for all journal content from 2018 to present.{p_end}

{pstd}February 2022: Journal of Quantitative & Technological Economics announced that starting from Issue 9 of 2022, the journal will publicly release original data and program code on its official website.{p_end}

{marker examples}{...}
{title:Examples}

{pstd}View all article information for Issue 5, 2025{p_end}
{phang}{stata "jqte 2025 5":. jqte 2025  5}{p_end}

{pstd}View Issue 9, 2022 (contains attachments){p_end}
{phang}{stata "jqte 2022 9":. jqte 2022  9}{p_end}

{pstd}View Issue 8, 2018 (pre-attachment release period){p_end}
{phang}{stata "jqte 2018 8":. jqte 2018  8}{p_end}

{hline}
{phang}{stata "jqte 2023 2":. jqte 2023  2}{p_end}
{phang}{stata "jqte 2023 3":. jqte 2023  3}{p_end}
{hline}

{pstd}Display command help information{p_end}
{phang}{stata "help jqte":. help jqte}{p_end}

{marker notes}{...}
{title:Notes}

{pstd}(1) Year Format{p_end}
{pstd}- Must be four-digit format (e.g., 2018, 2025), cannot be abbreviated to two digits (e.g., 18, 25){p_end}

{pstd}(2) Issue Format {p_end}
{pstd}- For Issues 1 to 9, the issue value must be entered as a single digit (e.g., 1, 9){p_end}

{pstd}(3) Journal Coverage {p_end}
{pstd}- Only supports content from Issue 1, 2018 to present. Journals prior to this period may not be supported{p_end}

{pstd}(4) Attachment Availability {p_end}
{pstd}- Attachment links are only displayed for issues after Issue 9, 2022 when attachments are provided with the paper{p_end}

{pstd}(5) Command Distinction {p_end}
{pstd}- This command differs in syntax format from other journal navigation commands like {help sj1} and {help cie}. Please distinguish carefully{p_end}

	
{title:Author & Questions and Suggestions}

{p 4 4 2}
{cmd:Wang Qiang}, Xi'an Jiaotong University, China{p_end}

{p 4 4 2}
    If you encounter any issues or have suggestions while using the tool, we will address them promptly. 
	
    Email: {browse "mailto:740130359@qq.com":740130359@qq.com}	

{marker alsosee}{...}
{title:Also see}
{p 4 4 2}

{psee}{help cnuse} (if installed),  {help topsis} (if installed),  {help log2md} (if installed),  {help sj1} (if installed),  {help jqte} (if installed){p_end}

{p 4 4 2}
Related resources: {browse "https://www.jqte.net/sljjjsjjyj/ch/index.aspx":Journal of Quantitative & Technological Economics}

{hline}


