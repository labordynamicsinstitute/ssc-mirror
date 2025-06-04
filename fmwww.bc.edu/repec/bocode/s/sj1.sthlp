{smcl}
{hline}
{cmd:help sj1}
{hline}
{p 4 4 2}
{vieweralsosee "cnuse" "net describe http://fmwww.bc.edu/repec/bocode/c/cnuse"}{p_end}
{p 4 4 2}
{vieweralsosee "topsis" "net describe http://fmwww.bc.edu/repec/bocode/t/topsis"}{p_end}
{p 4 4 2}
{vieweralsosee "log2md" "net describe http://fmwww.bc.edu/repec/bocode/l/log2md"}{p_end}
{p 4 4 2}
{vieweralsosee "" "--"}{p_end}

{viewerjumpto "Title" "sj1##title"}{...}
{viewerjumpto "Syntax" "sj1##syntax"}{...}
{viewerjumpto "Description" "sj1##description"}{...}
{viewerjumpto "Enhanced Features" "sj1##enhanced_features"}{...}
{viewerjumpto "Examples" "sj1##examples"}{...}
{title:Title}

{p2colset 5 16 16 2}{...}
{p2col:{hi: sj1} {hline 2}}Enhanced Stata Journal Navigator - Formatted DOI Output or SJ Content &  PDF Links for  Paper Browsing in Stata Access{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:sj1}
[
{it:volume} 
{it:issue} 
{cmd:,}
{opt paper}
{opt doi}
{opt help}
]

{synoptset 20 tabbed}{...}
{synopthdr:Options}
{synoptline}
{synopt:{opt paper}}Display paper titles with clickable PDF links{p_end}
{synopt:{opt doi}}Display paper DOI identifiers (instead of PDF links){p_end}
{synopt:{opt help}}Display this help documentation{p_end}
{synoptline}

{pstd}Notes:{p_end}
{pstd}1. {it:volume} must be an integer between 1-25{p_end}
{pstd}2. When {it:issue} is omitted, displays all issues (1-4) for the volume{p_end}
{pstd}3. {opt paper} and {opt doi} options cannot be used together{p_end}

{marker description}{...}
{title:Description}

{pstd}{cmd:sj1} provides enhanced navigation for the Stata Journal, simplifying access to SJ content.{p_end}

{pstd}{cmd:sj1} is an enhanced version of official commands with these benefits:{p_end}
{p 6 8 2}
• Automatically formats output with journal metadata and statistics{p_end}
{p 6 8 2}
• Supports batch display of all issues in a volume{p_end}
{p 6 8 2}
• Provides clickable PDF links for one-click paper access{p_end}
{p 6 8 2}
• Displays DOI identifiers for academic citation{p_end}

{pstd}For comprehensive information about the Stata Journal, execute the Stata command {stata "help sj":help sj} in the command window. Additional resources are available at:{p_end}
{p 6 8 2}
• Official website: {browse "https://www.stata-journal.com"}{p_end}
{p 6 8 2}
• Historical archives: {browse "https://www.stata-journal.com/archives.html"}{p_end}

{pstd}You can access SJ community contributions through:{p_end}
{p 6 8 2}
1. Menu: {bf:Help} > {bf:SJ and User-written Commands} > {bf:Stata Journal}{p_end}
{p 6 8 2}
2. Command line: {stata "net from https://www.stata-journal.com/software": net from https://www.stata-journal.com/software}{p_end}

{marker enhanced_features}{...}
{title:Enhanced Features}

{pstd}{cmd:sj1} extends beyond {cmd:net sj volume-issue} equivalence by:{p_end}
{p 6 8 2}
• Generating paper metadata with DOI identifiers when {opt doi} specified{p_end}
{p 6 8 2}
• Outputting all volume content when {it:issue} omitted (default behavior){p_end}

{pstd}{ul:PDF Access Methods}{p_end}
{pstd}Two PDF link formats are provided:{p_end}
{p 6 8 2}
1. {bf:Sage Official Link} (Recommended):{p_end}
{p 8 10 2}- Markdown format: {bf:[-PDF-Sage]}{p_end}
{p 8 10 2}- Resolves to: {browse "https://journals.sagepub.com/doi/pdf/doi"}{p_end}
{p 6 8 2}
2. {bf:SCI-HUB Mirror}:{p_end}
{p 8 10 2}- Note: May not contain articles published within last 3 years{p_end}

{pstd}{ul:Important  Notice}{p_end}
{pstd}All retrieved articles are provided exclusively for academic research purposes. Commercial use is strictly prohibited.

{pstd}{ul:Underlying Implementation}{p_end}
{p 8 12 2}
{cmd:sj1} {it:volume} {it:issue} [, paper]{p_end}
{p 12 12 2}is equivalent to{p_end}
{p 12 12 2}{cmd:net sj} {it:volume}-{it:issue}{p_end}

{p 8 12 2}
{cmd:sj1} {it:volume} {it:issue} [, doi]{p_end}
{p 12 12 2}provides DOI identifiers for journal papers{p_end}

{marker examples}{...}
{title:Examples}

{pstd}View help documentation{p_end}
{phang}{stata "sj1, help":. sj1, help}{p_end}

{pstd}Display papers from Volume 19, Issue 4 with PDF links{p_end}
{phang}{stata "sj1 19 4, paper":. sj1 19 4, paper}{p_end}

{pstd}Display papers from Volume 22, Issue 2 with DOI identifiers{p_end}
{phang}{stata "sj1 21 1, doi":. sj1 22 2, doi}{p_end}

{pstd}Display all issues for Volume 18{p_end}
{phang}{stata "sj1 18":. sj1 18}{p_end}

{pstd}Output all issues from Volume 18 with accessible PDF links{p_end}
{phang}{stata "sj1 18, paper":. sj1 18, paper}{p_end}

{pstd}Display papers from Volume 18 with DOI identifiers{p_end}
{phang}{stata "sj1 18, doi":. sj1 18, doi}{p_end}


{title:Related external commands}

{pstd}
For the {cmd:songbl} command (if installed), see {help songbl}.

{pstd}
To navigate or open the table of contents of {it:The Stata Journals}:

{phang2}
{stata "songbl sj":songbl sj}

{pstd}
To access program files from specific articles:

{phang2}
{stata "songbl paper SJ-19-4, j(sj)":songbl paper SJ-19-4, j(sj)}


{title:Author & Questions and Suggestions}

{p 4 4 2}
{cmd:Wang Qiang}, Xi'an Jiaotong University, China{p_end}

{p 4 4 2}
Some of the titles of the papers contain special symbols such as double quotation marks, which may cause the interruption of the code operation in some years. We have checked and updated the databases of all years as much as possible.

    If you encounter any issues or have suggestions while using the tool, we will address them promptly. 
    Email: {browse "mailto:740130359@qq.com":740130359@qq.com}


{marker alsosee}{...}
{title:Also see}
{p 4 4 2}

{psee}{help cnuse} (if installed),{help topsis} (if installed),{help log2md} (if installed){p_end}

    Online help: {help net}, {help sj}

{p 4 4 2}
Related resources: {browse "https://www.stata-journal.com":Stata Journal website}, {browse "https://www.stata-journal.com/archives.html":SJ Archives}
	
{hline}
