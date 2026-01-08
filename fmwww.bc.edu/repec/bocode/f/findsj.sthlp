{smcl}
{* *! version 1.5.0  31dec2025}{...}
{vieweralsosee "[R] search" "help search"}{...}
{vieweralsosee "[R] net" "help net"}{...}
{viewerjumpto "Syntax" "findsj##syntax"}{...}
{viewerjumpto "Description" "findsj##description"}{...}
{viewerjumpto "Options" "findsj##options"}{...}
{viewerjumpto "Examples" "findsj##examples"}{...}
{viewerjumpto "Stored results" "findsj##results"}{...}
{viewerjumpto "Remarks" "findsj##remarks"}{...}
{viewerjumpto "Authors" "findsj##authors"}{...}
{hline}
{title:Title}

{p2colset 5 16 18 2}{...}
{p2col:{cmd:findsj} {hline 2}}Search and cite Stata Journal articles with interactive buttons{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Search for articles

{p 8 16 2}
{cmd:findsj}
[{it:keywords}]
[{cmd:,} {it:options}]


{pstd}
Show citation formats for specific article

{p 8 16 2}
{cmd:findsj}
{it:article_id}
{cmd:,} {opt ref}


{pstd}
Download BibTeX or RIS file

{p 8 16 2}
{cmd:findsj}
{it:article_id}
{cmd:,} {opt type(bib|ris)}


{pstd}
Update local database

{p 8 16 2}
{cmd:findsj}
{cmd:,} {opt update} [{opt source(github|gitee|both)}]


{pstd}
Configure download path

{p 8 16 2}
{cmd:findsj}
{cmd:,} {opt setpath(path)} | {opt querypath} | {opt resetpath}


{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Search scope}
{synopt:{opt author}}search by author name{p_end}
{synopt:{opt title}}search by article title{p_end}
{synopt:{opt keyword}}search by keyword (default){p_end}

{syntab:Display control}
{synopt:{opt n(#)}}number of results to display; default is {cmd:n(10)}{p_end}
{synopt:{opt allresults}}display all search results{p_end}
{synopt:{opt nobrowser}}suppress clickable buttons and links{p_end}
{synopt:{opt nopdf}}hide PDF download buttons{p_end}
{synopt:{opt nopkg}}hide package installation buttons{p_end}

{syntab:Citation and export}
{synopt:{opt ref}}enable citation buttons (.md, .latex, .txt) for each article{p_end}
{synopt:{opt md}}export all results in Markdown format{p_end}
{synopt:{opt markdown}}same as {cmd:md}{p_end}
{synopt:{opt latex}}export all results in LaTeX format{p_end}
{synopt:{opt tex}}same as {cmd:latex}{p_end}
{synopt:{opt plain}}export all results in plain text format{p_end}
{synopt:{opt noclip}}disable automatic clipboard copying{p_end}
{synopt:{opt getdoi}}fetch DOI information (auto-enabled with {cmd:ref}){p_end}

{syntab:Database management}
{synopt:{opt update}}update local database from specified source{p_end}
{synopt:{opt source(string)}}download source: {cmd:github}, {cmd:gitee}, or {cmd:both}{p_end}

{syntab:Path management}
{synopt:{opt setpath(path)}}set custom download path for BibTeX/RIS files{p_end}
{synopt:{opt querypath}}display current download path{p_end}
{synopt:{opt resetpath}}reset to default path (current directory){p_end}

{syntab:Other}
{synopt:{opt clear}}clear previous search results{p_end}
{synopt:{opt debug}}enable debug mode with trace output{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:findsj} searches articles published in the {it:Stata Journal} (2001-present) 
and {it:Stata Technical Bulletin} (1991-2000). It provides an integrated workflow 
for finding, reading, citing, and installing Stata packages from journal articles.

{pstd}
Key features:

{phang2}
{bf:1. Interactive Search} - Search by keyword, author, or title with real-time results from 
the official Stata Journal website.

{phang2}
{bf:2. Clickable Buttons} - Each search result displays interactive buttons that execute 
actions with a single click:

{phang3}
• {bf:Article} - Opens article page in your browser{break}
• {bf:PDF} - Opens full-text PDF in browser (requires DOI){break}
• {bf:Google} - Searches article on Google Scholar{break}
• {bf:Install} - Searches for installable Stata packages{break}
• {bf:Ref} - Displays citation format buttons{break}
• {bf:BibTeX} - Downloads BibTeX reference file{break}
• {bf:RIS} - Downloads RIS reference file

{phang2}
{bf:3. Citation Generation} - Generate properly formatted citations in three formats:

{phang3}
• {bf:Markdown} (.md) - For R Markdown, Quarto, and Markdown documents{break}
• {bf:LaTeX} (.tex) - For LaTeX papers and Overleaf{break}
• {bf:Plain text} (.txt) - For Word and plain text documents

{phang3}
Citation format follows {cmd:getiref} style:{break}
Cox, N. J. (2007). Speaking Stata: Identifying Spells. The Stata Journal, 7(2), 249-265.

{phang2}
{bf:4. File Export with Quick Access} - Export citations are saved to current directory 
with four access buttons:

{phang3}
• {bf:View} - Open in Stata's viewer{break}
• {bf:Open_Mac} - Open with default Mac app{break}
• {bf:Open_Win} - Open with default Windows app{break}
• {bf:dir} - Browse to file location

{phang2}
{bf:5. Automatic Clipboard} - Citations are automatically copied to clipboard (disable with {cmd:noclip}).

{phang2}
{bf:6. Smart Database} - Local database (findsj.dta) enables offline DOI lookup and faster 
citation generation. Updates available from GitHub or Gitee (China mirror).


{marker options}{...}
{title:Options}

{dlgtab:Search scope}

{phang}
{opt author} searches for articles by author name. Example: {cmd:findsj cox, author}

{phang}
{opt title} searches for articles by words in the title.

{phang}
{opt keyword} searches across titles, abstracts, and keywords. This is the default 
if no scope is specified.


{dlgtab:Display control}

{phang}
{opt n(#)} specifies maximum number of results to display. Default is 10. 
Use {cmd:allresults} to show all matches.

{phang}
{opt allresults} displays all search results without limit. Useful for comprehensive 
reviews or when exporting complete citation lists.

{phang}
{opt nobrowser} suppresses all clickable buttons and links. Use when working in 
batch mode or when buttons are not needed. By default, seven buttons appear 
for each result: {bf:Article}, {bf:PDF}, {bf:Google}, {bf:Install}, {bf:Ref}, 
{bf:BibTeX}, and {bf:RIS}.

{phang}
{opt nopdf} hides PDF download buttons. PDF links require DOI information from 
the local database or online fetch.

{phang}
{opt nopkg} hides the {bf:Install} button. By default, this button executes 
{cmd:search article_id} to find installable packages associated with the article.


{dlgtab:Citation and export}

{phang}
{opt ref} enables citation mode. When specified, each search result displays three 
clickable format buttons below the article information:

{phang2}
• {bf:.md} - Click to generate Markdown citation via {cmd:getiref}{break}
• {bf:.latex} - Click to generate LaTeX citation via {cmd:getiref}{break}
• {bf:.txt} - Click to generate plain text citation via {cmd:getiref}

{pmore}
This option automatically enables {cmd:getdoi} to fetch DOI information required 
for citation generation.

{phang}
{opt md} or {opt markdown} exports all search results as formatted citations in 
Markdown format. The output includes:

{phang2}
• Citations displayed in Results window{break}
• File saved as {bf:_findsj_temp_out_.md} in current directory{break}
• Citations copied to clipboard (unless {cmd:noclip} specified){break}
• Four access buttons: {bf:View}, {bf:Open_Mac}, {bf:Open_Win}, {bf:dir}

{pmore}
Citation format example:{break}
Cox, N. J. (2007). Speaking Stata: Identifying Spells. The Stata Journal, 7(2). 
[Link](https://...), [PDF](https://...), [Google](<https://...>)

{phang}
{opt latex} or {opt tex} exports citations in LaTeX format with \href commands. 
File saved as {bf:_findsj_temp_out_.txt}.

{pmore}
Format example:{break}
Cox, N. J. (2007). Speaking Stata: Identifying Spells. The Stata Journal, 7(2). 
\href{https://...}{Link}, \href{https://...}{PDF}, \href{https://...}{Google}

{phang}
{opt plain} exports citations in plain text format. File saved as {bf:_findsj_temp_out_.txt}.

{pmore}
Format example:{break}
Cox, N. J. (2007). Speaking Stata: Identifying Spells. The Stata Journal, 7(2). 
Link: https://..., PDF: https://..., Google: https://...

{phang}
{opt noclip} disables automatic clipboard copying. By default, export formats 
({cmd:md}, {cmd:latex}, {cmd:plain}) automatically copy citations to system clipboard 
using PowerShell (Windows) or pbcopy (Mac).

{phang}
{opt getdoi} fetches DOI and page information for all articles. This option:

{phang2}
• First searches local database (findsj.dta) if available{break}
• Falls back to real-time web fetch if not in database{break}
• Enables complete citations with page numbers{break}
• Enables PDF download links{break}
• Is automatically activated when {cmd:ref} is specified


{dlgtab:Database management}

{phang}
{opt update} initiates database update process. Without {cmd:source()}, displays 
clickable buttons for available sources. With {cmd:source()}, downloads database 
from specified location.

{phang}
{opt source(string)} specifies download source:

{phang2}
• {bf:github} - Download from GitHub{break}
• {bf:gitee} - Download from Gitee mirror (fallback when GitHub is unavailable){break}
• {bf:both} - Try GitHub first, fallback to Gitee if failed (recommended for reliability)

{pmore}
The database file (findsj.dta) is updated in place where findsj.ado is installed. 
Contains DOI and page information for all Stata Journal articles. The database is 
automatically updated by GitHub Actions that monitor the Stata Journal website for 
new publications. {cmd:findsj} checks once daily and reminds if database is >120 days old.


{dlgtab:Path management}

{phang}
{opt setpath(path)} sets persistent download directory for BibTeX and RIS files. 
Directory must exist. Setting is saved to {bf:findsj_config.txt} in personal ado 
directory and persists across Stata sessions.

{pmore}
Example: {cmd:findsj, setpath(d:/references)}

{phang}
{opt querypath} displays current download path. Shows custom path if set, otherwise 
shows default (current working directory).

{phang}
{opt resetpath} resets download path to default by removing configuration file.


{dlgtab:Other}

{phang}
{opt clear} clears previous search results before new search. Helps avoid confusion 
with multiple searches.

{phang}
{opt debug} enables trace mode for troubleshooting. Use when reporting issues.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Important}: All examples produce clickable buttons in the output. Simply click 
any blue underlined text or button with your mouse to execute the action.

    {hline}
{pstd}{bf:Basic Search}{p_end}

{phang2}{cmd:. findsj panel data}{p_end}
{pmore}→ Searches for "panel data", displays 10 results with 7 buttons each{p_end}

{phang2}{cmd:. findsj cox, author}{p_end}
{pmore}→ Finds all articles by Nicholas J. Cox{p_end}

{phang2}{cmd:. findsj propensity score matching, title}{p_end}
{pmore}→ Searches article titles only{p_end}

{phang2}{cmd:. findsj instrumental variable, n(20)}{p_end}
{pmore}→ Shows first 20 results{p_end}

{phang2}{cmd:. findsj difference-in-differences, allresults}{p_end}
{pmore}→ Shows all matching articles{p_end}

    {hline}
{pstd}{bf:Using Interactive Buttons}{p_end}

{phang2}{cmd:. findsj fixed effects}{p_end}
{pmore}For each result, click:{p_end}
{pmore2}• {bf:Article} to read abstract online{p_end}
{pmore2}• {bf:PDF} to view full text in browser{p_end}
{pmore2}• {bf:Google} to search on Google Scholar{p_end}
{pmore2}• {bf:Install} to find and install Stata package{p_end}
{pmore2}• {bf:Ref} to see citation format options{p_end}
{pmore2}• {bf:BibTeX} to download BibTeX file{p_end}
{pmore2}• {bf:RIS} to download RIS file for Zotero/EndNote{p_end}

    {hline}
{pstd}{bf:Citation Generation - Individual Articles}{p_end}

{phang2}{cmd:. findsj matching, ref}{p_end}
{pmore}→ Shows three format buttons (.md, .latex, .txt) below each result{p_end}
{pmore}→ Click any button to generate and copy that citation format{p_end}

{phang2}{cmd:. findsj st0001, ref}{p_end}
{pmore}→ Shows citation buttons for specific article ID{p_end}
{pmore}→ Useful when you already know the article ID{p_end}

    {hline}
{pstd}{bf:Citation Export - Batch Mode}{p_end}

{phang2}{cmd:. findsj causal inference, md}{p_end}
{pmore}→ Exports first 10 citations in Markdown format{p_end}
{pmore}→ Saves to _findsj_temp_out_.md{p_end}
{pmore}→ Copies to clipboard automatically{p_end}
{pmore}→ Shows View/Open_Mac/Open_Win/dir buttons{p_end}

{phang2}{cmd:. findsj meta-analysis, latex allresults}{p_end}
{pmore}→ Exports ALL results in LaTeX format{p_end}
{pmore}→ Perfect for comprehensive literature reviews{p_end}

{phang2}{cmd:. findsj quantile regression, plain noclip}{p_end}
{pmore}→ Exports in plain text without clipboard{p_end}
{pmore}→ Use when you don't want clipboard overwritten{p_end}

    {hline}
{pstd}{bf:Reference File Download}{p_end}

{phang2}{cmd:. findsj st0377, type(bib)}{p_end}
{pmore}→ Downloads BibTeX file for article st0377{p_end}
{pmore}→ File saved to configured path and auto-opened{p_end}

{phang2}{cmd:. findsj dm0065, type(ris)}{p_end}
{pmore}→ Downloads RIS file for EndNote/Zotero/Mendeley{p_end}

{phang2}{bf:Tip}: You can also click {bf:BibTeX} or {bf:RIS} buttons in search results{p_end}

    {hline}
{pstd}{bf:Database Management}{p_end}

{phang2}{cmd:. findsj, update}{p_end}
{pmore}→ Shows clickable buttons for GitHub, Gitee, and both{p_end}
{pmore}→ Click your preferred source to start download{p_end}

{phang2}{cmd:. findsj, update source(both)}{p_end}
{pmore}→ Downloads from GitHub, falls back to Gitee if failed{p_end}
{pmore}→ Recommended for reliability{p_end}

{phang2}{cmd:. findsj, update source(github)}{p_end}
{pmore}→ Downloads from GitHub only{p_end}

{phang2}{cmd:. findsj, update source(gitee)}{p_end}
{pmore}→ Downloads from Gitee (faster for China users){p_end}

    {hline}
{pstd}{bf:Download Path Configuration}{p_end}

{phang2}{cmd:. findsj, setpath(d:/MyPapers/References)}{p_end}
{pmore}→ Sets custom download location{p_end}
{pmore}→ Applies to all BibTeX and RIS downloads{p_end}
{pmore}→ Setting persists across sessions{p_end}

{phang2}{cmd:. findsj, querypath}{p_end}
{pmore}→ Shows current download path{p_end}

{phang2}{cmd:. findsj, resetpath}{p_end}
{pmore}→ Resets to default (current directory){p_end}

    {hline}
{pstd}{bf:Advanced Usage}{p_end}

{phang2}{cmd:. findsj simulation monte carlo, nopdf nopkg}{p_end}
{pmore}→ Minimal output: hides PDF and Install buttons{p_end}

{phang2}{cmd:. findsj bootstrap, nobrowser}{p_end}
{pmore}→ No clickable buttons (for batch scripts){p_end}

{phang2}{cmd:. findsj survival analysis, md allresults getdoi}{p_end}
{pmore}→ Export all results with complete DOI information{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:findsj} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(n_results)}}number of articles found{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(keywords)}}search keywords used{p_end}
{synopt:{cmd:r(scope)}}search scope: author, title, or keyword{p_end}
{synopt:{cmd:r(url)}}URL of search results page{p_end}
{synopt:{cmd:r(art_id_1)}}article ID of first result{p_end}
{synopt:{cmd:r(title_1)}}title of first result{p_end}
{synopt:{cmd:r(author_1)}}author of first result{p_end}
{synopt:{cmd:r(doi_1)}}DOI of first result (if available){p_end}
{synopt:{cmd:r(url_1)}}URL of first result article page{p_end}
{p2colreset}{...}


{marker remarks}{...}
{title:Remarks}

{pstd}
Complete documentation and examples available at:{break}
{browse "https://github.com/arlionn/findsj":GitHub repository}{break}
{browse "https://gitee.com/ChuChengWan/findsj":Gitee mirror (China)}


{marker authors}{...}
{title:Authors}

{pstd}
Yujun Lian{break}
Lingnan College, Sun Yat-sen University{break}
Email: {browse "mailto:arlionn@163.com":arlionn@163.com}{break}
Web: {browse "https://www.lianxh.cn":www.lianxh.cn}

{pstd}
Chucheng Wan{break}
Email: {browse "mailto:chucheng.wan@outlook.com":chucheng.wan@outlook.com}


{title:Also See}

{psee}
Help: {helpb search}, {helpb net}, {helpb ssc}

{psee}
Web: {browse "https://github.com/arlionn/findsj":GitHub}, 
{browse "https://gitee.com/ChuChengWan/findsj":Gitee}, 
{browse "https://www.stata-journal.com":Stata Journal}, 
{browse "https://www.lianxh.cn":Lianxh}
