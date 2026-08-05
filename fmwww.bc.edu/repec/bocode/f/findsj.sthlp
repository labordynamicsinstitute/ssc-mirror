{smcl}
{* *! version 3.2.10  03Aug2026}{...}
{vieweralsosee "[R] search" "help search"}{...}
{vieweralsosee "[R] net" "help net"}{...}
{viewerjumpto "Syntax" "findsj##syntax"}{...}
{viewerjumpto "Description" "findsj##description"}{...}
{viewerjumpto "Installation" "findsj##installation"}{...}
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
Export search results

{p 8 16 2}
{cmd:findsj}
[{it:keywords}]
{cmd:,} {opt md} | {opt markdown} | {opt latex} | {opt tex} |
{opt plain} | {opt text} | {opt txt}
[{opt noclip}]


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
{cmd:,} {opt bib} | {opt ris}


{pstd}
Update local database

{p 8 16 2}
{cmd:findsj}
{cmd:,} {opt update}

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

{syntab:Search source}
{synopt:{opt online}}query the Stata Journal website even when the local database is available{p_end}

{syntab:Display control}
{synopt:{opt n(#)}}maximum results to display or export; default is {cmd:n(10)}{p_end}
{synopt:{opt allresults}}display or export all search results{p_end}

{syntab:Citation and export}
{synopt:{opt ref}}display DOI information; citation buttons are shown by default{p_end}
{synopt:{opt bib}}download the selected article's BibTeX file{p_end}
{synopt:{opt ris}}download the selected article's RIS file{p_end}
{synopt:{opt md}}export results in Markdown format{p_end}
{synopt:{opt markdown}}same as {cmd:md}{p_end}
{synopt:{opt latex}}export results in LaTeX format{p_end}
{synopt:{opt tex}}same as {cmd:latex}{p_end}
{synopt:{opt plain}}export results in plain text format{p_end}
{synopt:{opt text}}same as {cmd:plain}{p_end}
{synopt:{opt txt}}same as {cmd:plain}{p_end}
{synopt:{opt noclip}}disable automatic clipboard copying{p_end}
{synopt:{opt getdoi}}display DOI information (auto-enabled with {cmd:ref}){p_end}

{syntab:Database management}
{synopt:{opt update}}update the local database and version metadata from GitHub{p_end}

{syntab:Path management}
{synopt:{opt setpath(path)}}set custom download path for BibTeX/RIS files{p_end}
{synopt:{opt querypath}}display current download path{p_end}
{synopt:{opt resetpath}}reset to default path (current directory){p_end}

{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:findsj} searches and cites articles published in the {it:Stata Journal}
(2001-present). It provides an integrated workflow
for finding articles, opening publisher links, generating citations, and launching
package searches associated with journal articles.

{pstd}
Key features:

{phang2}
{bf:1. Interactive Search} - Search by keyword, author, or title. {cmd:findsj}
uses the bundled local database first and falls back to the official Stata Journal
website when the database is unavailable. Specify {cmd:online} to query the website
even when the local database is available. {cmd:findsj} displays or exports the
website-supplied matches without applying an additional query-term post-filter. The
{cmd:n()} and {cmd:allresults} options continue to control how many results are
displayed or exported.

{phang2}
{bf:2. Clickable Buttons} - Each search result displays interactive buttons that execute 
actions with a single click:

{phang3}
• {bf:Web} - Opens article page in your browser{break}
• {bf:PDF} - Opens a DOI-based publisher PDF link; access may be restricted{break}
• {bf:Google} - Searches article on Google Scholar{break}
• {bf:Install} - Searches for installable Stata packages{break}
• {bf:.md}, {bf:.latex}, and {bf:.txt} - Generate a citation (when a DOI is available){break}
• {bf:BibTeX} - Downloads BibTeX reference file{break}
• {bf:RIS} - Downloads RIS reference file

{phang2}
{bf:3. Citation Generation} - Generate properly formatted citations in three formats:

{phang3}
• {bf:Markdown} (.md) - For R Markdown, Quarto, and Markdown documents{break}
• {bf:LaTeX} (.tex) - For LaTeX papers and Overleaf{break}
• {bf:Plain text} (.txt) - For Word and plain text documents

{phang3}
Citation format follows the private bundled {cmd:_getiref} component:{break}
Cox, N. J. (2007). Speaking Stata: Identifying Spells. The Stata Journal, 7(2), 249-265.

{phang2}
{bf:4. File Export with Quick Access} - Export citations are saved to current directory 
with four access buttons:

{phang3}
• {bf:View} - Open in Stata's viewer{break}
• {bf:Open_Mac} - Open the exported file or its containing folder on macOS{break}
• {bf:Open_Win} - Open the exported file or reveal it in File Explorer on Windows{break}
• {bf:dir} - Browse to file location

{phang2}
{bf:5. Automatic Clipboard} - Batch citation exports are copied automatically on
Windows and macOS (disable with {cmd:noclip}). Linux exports are saved to a file,
but automatic clipboard copying is not supported.

{phang2}
{bf:6. Smart Database} - The local database ({cmd:findsj.dta}) contains 1,269
records and enables fast offline searching and local-first DOI lookup. Updates are
available from GitHub.


{marker installation}{...}
{title:Installation}

{pstd}
{cmd:findsj} requires Stata 16 or later.

{pstd}
For the recommended SSC installation, type:

{phang2}{cmd:. ssc install findsj, all replace}{p_end}

{pstd}
This installation places the runtime databases ({cmd:findsj.dta} and
{cmd:findsj_version.dta}) in the PLUS package directory together with the
program and help files for {cmd:findsj} and its private {cmd:_getiref} component. Local
search therefore works immediately and continues to use the installed database
after the current working directory is changed.

{pstd}
The private {cmd:_getiref} component is namespaced for {cmd:findsj} citation
links. It can coexist with the independently installed public {help getiref}
package, and uninstalling either package does not remove the other command.

{pstd}
The {cmd:all} option additionally downloads ancillary files such as
{cmd:findsj_examples.do}, {cmd:findsj_examples.log}, and {cmd:README.txt}; it is
not required for the runtime database, but is recommended so that the complete
distribution and reproducibility materials are obtained together. The
{cmd:replace} option lets the same command upgrade an existing installation.

{pstd}
To refresh the database later without reinstalling the package, use
{cmd:findsj, update} (see {it:Database management} below).


{marker options}{...}
{title:Options}

{dlgtab:Search scope}

{phang}
{opt author} searches for articles by author name. In local-database searches, each
query term is matched as a complete name token, and a multiple-term query requires
all tokens to be present. Thus, the local search {cmd:findsj lian, author} does not
match {it:Iliana}, and {cmd:findsj "Christopher F. Baum", author} requires the
complete tokens {it:Christopher}, {it:F}, and {it:Baum}. In online searches, the
Stata Journal website controls matching; {cmd:findsj} does not apply an additional
query-term post-filter, including its local complete-token rule.

{phang}
{opt title} searches for articles by words in the title.

{phang}
{opt keyword} searches across titles, author lists, and abstracts. This is the default
if no scope is specified.


{dlgtab:Search source}

{phang}
{opt online} bypasses the bundled database and queries the official Stata Journal
website. This is useful for comparing the two search paths or requesting current
website results without removing {cmd:findsj.dta}. Subject to {cmd:n()} or
{cmd:allresults}, {cmd:findsj} displays or exports the website-supplied matches
without applying an additional query-term post-filter. In particular, online
author results may reflect broader website matching than a local complete-token
author search.
Internet access is required.


{dlgtab:Display control}

{phang}
{opt n(#)} specifies the maximum number of results to display or export.
Default is 10. The argument must be a positive integer.
Use {cmd:allresults} to display or export all matches.

{phang}
{opt allresults} displays or exports all search results without limit. Useful for
comprehensive reviews or when exporting complete citation lists.


{dlgtab:Citation and export}

{phang}
{opt ref} displays DOI information for matching search results. The three clickable
citation-format buttons are already included in the standard result row whenever a
DOI is available:

{phang2}
• {bf:.md} - Click to generate Markdown citation via private {cmd:_getiref}{break}
• {bf:.latex} - Click to generate LaTeX citation via private {cmd:_getiref}{break}
• {bf:.txt} - Click to generate plain text citation via private {cmd:_getiref}

{pmore}
For an article ID, {cmd:findsj article_id, ref} displays the three citation formats
for that article. For a regular search, {cmd:ref} is equivalent to {cmd:getdoi}; it
is not required to make citation buttons appear.

{phang}
{opt md} or {opt markdown} exports search results as formatted citations in
Markdown format. By default, the first 10 results are exported; {cmd:n()} changes
that limit, and {cmd:allresults} exports every match. The output includes:

{phang2}
• Citations displayed in Results window{break}
• File saved as {bf:_findsj_temp_out_.md} in current directory{break}
• Citations copied to the clipboard on Windows and macOS (unless {cmd:noclip} is specified){break}
• Four access buttons: {bf:View}, {bf:Open_Mac}, {bf:Open_Win}, {bf:dir}

{pmore}
Citation format example:{break}
Cox, N. J. (2007). Speaking Stata: Identifying Spells. The Stata Journal, 7(2). 
[Link](https://...), [PDF](https://...), [Google](<https://...>)

{phang}
{opt latex} or {opt tex} exports citations in LaTeX format with \href commands.
The same {cmd:n()} and {cmd:allresults} limits apply. File saved as
{bf:_findsj_temp_out_.tex}.

{pmore}
Format example:{break}
Cox, N. J. (2007). Speaking Stata: Identifying Spells. The Stata Journal, 7(2). 
\href{https://...}{Link}, \href{https://...}{PDF}, \href{https://...}{Google}

{phang}
{opt plain}, {opt text}, or {opt txt} exports citations in plain text format. File
saved as {bf:_findsj_temp_out_.txt}. The same {cmd:n()} and {cmd:allresults}
limits apply.

{pmore}
Format example:{break}
Cox, N. J. (2007). Speaking Stata: Identifying Spells. The Stata Journal, 7(2). 
Link: https://..., PDF: https://..., Google: https://...

{pmore}
The fixed {bf:_findsj_temp_out_.md}, {bf:_findsj_temp_out_.tex}, and
{bf:_findsj_temp_out_.txt} names denote temporary working files in the current
directory. An existing file with the applicable name is overwritten.
The Results window prints a notice before replacement.

{phang}
{opt noclip} disables automatic clipboard copying. By default, export formats
({cmd:md}, {cmd:latex}, {cmd:plain}, {cmd:text}, and {cmd:txt}) copy citations to
the system clipboard using PowerShell on Windows or {cmd:pbcopy} on macOS.
Automatic clipboard copying is not supported on Linux; the exported file is still
created.

{phang}
{opt getdoi} displays the DOI found for each displayed result. The lookup needed
for the standard PDF and citation actions is already attempted for every displayed
result, using local metadata first and an online DOI lookup when needed. This option:

{phang2}
• Adds the DOI value as a separate line in the displayed result{break}
• Does not change the search match set or ordering{break}
• Is automatically activated when {cmd:ref} is specified


{dlgtab:Database management}

{phang}
{opt update} downloads and validates the latest {cmd:findsj.dta} and
{cmd:findsj_version.dta} from GitHub, then installs them as one transaction.
The caller's active dataset, including unsaved changes, is preserved. If either
file cannot be installed, the previous runtime files are restored.

{pmore}
The database and version-metadata files are updated in place where
{cmd:findsj.ado} is installed in PLUS; changing the current working directory
does not change the database used for local search. The bundled database
contains 1,269 records with article metadata, including DOI and page information
where available. A GitHub Actions workflow checks the Stata Journal website
monthly and updates the repository database when its contents change.


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


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Important}: All examples produce clickable buttons in the output. Simply click 
any blue underlined text or button with your mouse to execute the action.

    {hline}
{pstd}{bf:Basic Search}{p_end}

{phang2}{inp:.} {stata "findsj panel data":findsj panel data}{p_end}
{pmore}→ Searches for "panel data" and displays 10 results with the available action buttons{p_end}

{phang2}{inp:.} {stata "findsj cox, author":findsj cox, author}{p_end}
{pmore}→ Finds all articles by Nicholas J. Cox{p_end}

{phang2}{inp:.} {stata "findsj Christopher F. Baum, author":findsj Christopher F. Baum, author}{p_end}
{pmore}→ In the local database, requires all three complete author-name tokens to match{p_end}

{phang2}{inp:.} {stata "findsj lian, author online allresults":findsj lian, author online allresults}{p_end}
{pmore}→ Displays the website-supplied author matches without an additional
{cmd:findsj} query-term post-filter{p_end}

{phang2}{inp:.} {stata "findsj propensity score matching, title":findsj propensity score matching, title}{p_end}
{pmore}→ Searches article titles only{p_end}

{phang2}{inp:.} {stata "findsj instrumental variable, n(20)":findsj instrumental variable, n(20)}{p_end}
{pmore}→ Shows first 20 results{p_end}

{phang2}{inp:.} {stata "findsj difference-in-differences, allresults":findsj difference-in-differences, allresults}{p_end}
{pmore}→ Shows all matching articles{p_end}

    {hline}
{pstd}{bf:Using Interactive Buttons}{p_end}

{phang2}{inp:.} {stata "findsj fixed effects":findsj fixed effects}{p_end}
{pmore}For each result, click:{p_end}
{pmore2}• {bf:Web} to read the article page online{p_end}
{pmore2}• {bf:PDF} to open the DOI-based publisher PDF link (access may be restricted){p_end}
{pmore2}• {bf:Google} to search on Google Scholar{p_end}
{pmore2}• {bf:Install} to launch a Stata package search{p_end}
{pmore2}• {bf:.md}, {bf:.latex}, or {bf:.txt} to generate a citation{p_end}
{pmore2}• {bf:BibTeX} to download BibTeX file{p_end}
{pmore2}• {bf:RIS} to download RIS file for Zotero/EndNote{p_end}

    {hline}
{pstd}{bf:Citation Generation and DOI Display}{p_end}

{phang2}{inp:.} {stata "findsj matching, ref":findsj matching, ref}{p_end}
{pmore}→ Displays DOI information in addition to the standard result buttons{p_end}
{pmore}→ Citation buttons (.md, .latex, .txt) appear by default when a DOI is available{p_end}

{phang2}{inp:.} {stata "findsj st0001, ref":findsj st0001, ref}{p_end}
{pmore}→ Shows citation buttons for specific article ID{p_end}
{pmore}→ Useful when you already know the article ID{p_end}

    {hline}
{pstd}{bf:Citation Export - Batch Mode}{p_end}

{phang2}{inp:.} {stata "findsj causal inference, md":findsj causal inference, md}{p_end}
{pmore}→ Exports first 10 citations in Markdown format{p_end}
{pmore}→ Saves to _findsj_temp_out_.md{p_end}
{pmore}→ Copies to the clipboard automatically on Windows and macOS{p_end}
{pmore}→ Shows View/Open_Mac/Open_Win/dir buttons{p_end}

{phang2}{inp:.} {stata "findsj meta-analysis, latex allresults":findsj meta-analysis, latex allresults}{p_end}
{pmore}→ Exports ALL results in LaTeX format{p_end}
{pmore}→ Perfect for comprehensive literature reviews{p_end}

{phang2}{inp:.} {stata "findsj quantile regression, plain noclip":findsj quantile regression, plain noclip}{p_end}
{pmore}→ Exports in plain text without clipboard{p_end}
{pmore}→ Use when you don't want clipboard overwritten{p_end}

    {hline}
{pstd}{bf:Reference File Download}{p_end}

{phang2}{inp:.} {stata "findsj st0377, bib":findsj st0377, bib}{p_end}
{pmore}→ Downloads BibTeX file for article st0377{p_end}
{pmore}→ File saved to the configured path{p_end}

{phang2}{inp:.} {stata "findsj dm0065, ris":findsj dm0065, ris}{p_end}
{pmore}→ Downloads RIS file for EndNote/Zotero/Mendeley{p_end}

{phang2}{bf:Tip}: You can also click {bf:BibTeX} or {bf:RIS} buttons in search results{p_end}

    {hline}
{pstd}{bf:Database Management}{p_end}

{phang2}{inp:.} {stata "findsj, update":findsj, update}{p_end}
{pmore}→ Downloads and validates the current database and version metadata from GitHub{p_end}

    {hline}
{pstd}{bf:Download Path Configuration}{p_end}

{phang2}{inp:.} {stata "findsj, setpath(d:/MyPapers/References)":findsj, setpath(d:/MyPapers/References)}{p_end}
{pmore}→ Sets custom download location{p_end}
{pmore}→ Applies to all BibTeX and RIS downloads{p_end}
{pmore}→ Setting persists across sessions{p_end}

{phang2}{inp:.} {stata "findsj, querypath":findsj, querypath}{p_end}
{pmore}→ Shows current download path{p_end}

{phang2}{inp:.} {stata "findsj, resetpath":findsj, resetpath}{p_end}
{pmore}→ Resets to default (current directory){p_end}

    {hline}
{pstd}{bf:Advanced Usage}{p_end}

{phang2}{inp:.} {stata "findsj survival analysis, md allresults noclip":findsj survival analysis, md allresults noclip}{p_end}
{pmore}→ Export all matching results in Markdown without clipboard copying{p_end}



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
{synopt:{cmd:r(search_source)}}search source: local or online{p_end}
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
{browse "https://github.com/BlueDayDreeaming/findsj":GitHub repository}


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
Web: {browse "https://github.com/BlueDayDreeaming/findsj":GitHub},
{browse "https://www.stata-journal.com":Stata Journal}, 
{browse "https://www.lianxh.cn":Lianxh}
