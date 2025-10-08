{smcl}
{title:Title}

{p 4 4 2}
{bf:getref} - Simulate academic references from CNKI and Google Scholar (Demo Version)


{title:Syntax}

{p 4 4 2}
{cmd:getref} {it:query_string}, {cmd:saving(}{it:filename}{cmd:)} [{cmd:format(}{it:str}{cmd:)} {cmd:replace} {cmd:language(}{it:str}{cmd:)} {cmd:source(}{it:str}{cmd:)} {cmd:apikey(}{it:str}{cmd:)}]

{p 4 4 2}
where {it:query_string} is the search term for academic references.


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt saving(filename)}}specify output filename (required){p_end}
{synopt:{opt format(str)}}output format: bib, tex, docx, or txt (default: bib){p_end}
{synopt:{opt replace}}overwrite existing file{p_end}
{synopt:{opt language(str)}}query language: english or chinese (default: english){p_end}
{synopt:{opt source(str)}}data source: cnki or google (default: google){p_end}
{synopt:{opt apikey(str)}}API key for CNKI access (required for CNKI){p_end}
{synoptline}


{title:Description}

{p 4 4 2}
The getref.ado program {bf:simulates} retrieval of academic references from CNKI and Google Scholar 
by generating placeholder reference data. This is a {bf:demonstration version} that shows the 
program structure and output formats without connecting to actual academic databases.

{p 4 4 2}
{bf:Important:} This version generates {bf:simulated reference data} for testing and demonstration 
purposes only. The references produced are generic placeholders and do not represent real published 
academic works.

{p 4 4 2}
This program demonstrates how researchers could create academic paper references in multiple formats 
and is part of the suite supporting efficient operation of art2tex.ado and case2tex.ado programs.


{title:Options}

{phang}
{opt saving(filename)} specifies the output filename where references will be 
saved. This option is required.

{phang}
{opt format(str)} specifies the output format. Valid options are:
    {it:bib} - BibTeX format (.bib)
    {it:tex} - LaTeX format (.tex) 
    {it:docx} - Microsoft Word format (.docx)
    {it:txt} - Plain text format (.txt)
Default is {it:bib}.

{phang}
{opt replace} allows overwriting an existing file.

{phang}
{opt language(str)} specifies the query language. Valid options are:
    {it:english} - English language queries
    {it:chinese} - Chinese language queries
Default is {it:english}.

{phang}
{opt source(str)} specifies the data source for references. Valid options are:
    {it:cnki} - China National Knowledge Infrastructure (simulated)
    {it:google} - Google Scholar (simulated)
Default is {it:google}.

{phang}
{opt apikey(str)} specifies the API key for CNKI access. This is required when 
using {it:cnki} as the data source, though in this simulation version any value 
is accepted.


{title:Examples}

{p 4 4 2}Simulate references from Google Scholar in BibTeX format:{p_end}
{phang2}{cmd:. getref artificial intelligence, saving("ai_refs.bib") format(bib) replace language(english) source(google)}{p_end}

{p 4 4 2}Simulate references from CNKI in BibTeX format:{p_end}
{phang2}{cmd:. getref 人工智能 会计, saving("ai_accounting.bib") format(bib) replace language(chinese) source(cnki) apikey("demo_key")}{p_end}

{p 4 4 2}Simulate references from CNKI in LaTeX format:{p_end}
{phang2}{cmd:. getref 数字化转型, saving("digital_refs.tex") format(tex) replace source(cnki) apikey("demo_key")}{p_end}

{p 4 4 2}Simulate references from Google Scholar in text format:{p_end}
{phang2}{cmd:. getref corporate governance, saving("governance.txt") format(txt) replace language(english) source(google)}{p_end}


{title:Output Details}

{p 4 4 2}
{bf:Simulated Data:} The current version generates 5 placeholder references with:
{break}    - Generic author names (Google Author 1, CNKI Author 1, etc.)
{break}    - Generic journal names
{break}    - Sequential years (2021-2025)
{break}    - Your search query embedded in titles

{p 4 4 2}
{bf:Format Specifications:}
{break}{it:BibTeX}: Generates .bib file with @article entries
{break}{it:LaTeX}: Generates .tex file with \bibitem entries  
{break}{it:Text}: Generates .txt file with plain text references
{break}{it:Word}: Generates .docx file with formatted references


{title:Limitations and Future Development}

{p 4 4 2}
{bf:Current Limitations:}
{break}- Generates simulated data only
{break}- No actual API integration
{break}- Fixed to 5 references per query
{break}- Generic reference content

{p 4 4 2}
{bf:Planned Enhancements:}
{break}- Integration with real academic APIs
{break}- Configurable number of results
{break}- Real citation data extraction
{break}- Advanced search filters


{title:Authors}

{p 4 4 2}
Wu Lianghai{p_end}
{p 4 4 2}
School of Business, Anhui University of Technology (AHUT){p_end}
{p 4 4 2}
Ma'anshan, China{p_end}
{p 4 4 2}
E-mail: {browse "agd2010@yeah.net":agd2010@yeah.net}{p_end}

{p 4 4 2}
Wu Hanyan{p_end}
{p 4 4 2}
School of Economics and Management, Nanjing University of Aeronautics and Astronautics (NUAA){p_end}
{p 4 4 2}
Nanjing, China{p_end}
{p 4 4 2}
E-mail: {browse "2325476320@qq.com":2325476320@qq.com}{p_end}

{p 4 4 2}
Chen Liwen{p_end}
{p 4 4 2}
School of Business, Anhui University of Technology (AHUT){p_end}
{p 4 4 2}
Ma'anshan, China{p_end}
{p 4 4 2}
E-mail: {browse "2184844526@qq.com":2184844526@qq.com}{p_end}

{p 4 4 2}
Program written: 30th Sep., 2025 | Demo Version{p_end}


{title:Also see}

{p 4 4 2}
{help get2ref}, {help case2tex}, {help art2tex}, {help reftex}
{*}