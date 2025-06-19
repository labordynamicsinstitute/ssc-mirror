{smcl}
{hline}
{cmd:help cie}
{hline}
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

{viewerjumpto "Title" "cie##title"}{...}
{viewerjumpto "Syntax" "cie##syntax"}{...}
{viewerjumpto "Description" "cie##description"}{...}
{viewerjumpto "Website Updates" "cie##website_change"}{...}
{viewerjumpto "Examples" "cie##examples"}{...}
{viewerjumpto "Notes" "cie##notes"}{...}
{viewerjumpto "Alsosee" "cie##alsosee"}{...}


{title:Title}

{p2colset 5 16 16 2}{...}
{p2col:{hi: cie} {hline 2}}Navigation Tool for China Industrial Economics Journal{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:cie}
{it:year}
{it:issue}
[{cmd:,}
{opt help}
]

{synoptset 20 tabbed}{...}
{synopthdr:Options}
{synoptline}
{synopt:{opt help}}display a brief guide on using the {cmd:cie} command{p_end}
{synoptline}

{pstd}Parameters:{p_end}
{pstd}1. {it:year}: Four-digit year (2017 to present){p_end}
{pstd}2. {it:issue}: Two-digit issue number (01-12){p_end}

{marker description}{...}
{title:Description}

{pstd}{cmd:cie} provides access to the China Industrial Economics journal, supporting browsing and downloading of articles and supplemental materials.{p_end}

{pstd}This command directly interfaces with the official website, providing access to all journal content and supplementary materials from 2017 to present.{p_end}

{pstd}Since Issue 11, 2016, China Industrial Economics has publicly shared research data, programs, processed data, and supplemental materials through its official website.{p_end}

{pstd}Adapted for the website redesign in 2024, this command offers one-stop access to articles and supplementary materials.{p_end}

{marker website_change}{...}
{title:Website Updates & Data Availability}

{pstd}{browse "https://mp.weixin.qq.com/s/b-khe3G8pztSpKLXebCt9A":May 28, 2025 Announcement}: China Industrial Economics editorial office has officially migrated to the new URL ({browse "https://ciejournal.ajcass.com":ciejournal.ajcass.com}) 

{pstd}April 30, 2024 Announcement: {browse "https://mp.weixin.qq.com/s/MbJsf2jDwkZUJjoQ1Cpodw":New submission system launched}{p_end}

{pstd}November 2016 Announcement : Commenced public sharing of research data, programs, processed data, case materials, and supplementary articles too lengthy for print.{p_end}

{marker examples}{...}
{title:Examples}

{pstd}Browse articles from Issue 12, 2024{p_end}
{phang}{stata "cie 2024 12":. cie 2024 12}{p_end}

{pstd}Browse articles from Issue 03, 2024{p_end}
{phang}{stata "cie 2024 03":. cie 2024 03}{p_end}

{pstd}Browse articles from Issue 10, 2022{p_end}
{phang}{stata "cie 2022 10":. cie 2022 10}{p_end}

{pstd}Access content from Issue 08, 2017{p_end}
{phang}{stata "cie 2017 08":. cie 2017 08}{p_end}

{pstd}Display command help{p_end}
{phang}{stata "help cie":. help cie}{p_end}
{phang}{stata "cie 2017 ,help":. cie 2017 ,help}{p_end}
{phang}{stata "cie 2017 08,help":. cie 2017 08,help}{p_end}


{marker notes}{...}
{title:Notes}

{pstd}(1) Year format {p_end}
{pstd}   - Must use four-digit format (e.g., 2017, 2025) - two-digit abbreviations (e.g., 17, 25) are invalid{p_end}

{pstd}(2) Issue format{p_end}
{pstd}   - Must use two-digit format (e.g., 01, 05, 12) - single-digit (e.g., 1, 5) are not accepted{p_end}

{pstd}(3) Journal coverage{p_end}
{pstd}   - Only supports content from Issue 1, 2017 onward{p_end}

{pstd}(4) Supplemental materials{p_end}
{pstd}   - Download links appear only when available. Some articles may lack supplements{p_end}

{pstd}(5) Command distinction{p_end}
{pstd}   - The parameter format for year and issue specifications in the cie command
    syntax differs from other journal navigation commands such as {help sj1} and {help jqte}
    due to distinct database schema implementations.

	
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
Related resources: {browse "https://ciejournal.ajcass.com":ciejournal.ajcass.com}

{hline}
