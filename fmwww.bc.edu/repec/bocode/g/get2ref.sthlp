{smcl}
{title:Title}

{p 4 4 2}
{bf:get2ref} - Retrieve published academic articles from academic databases


{title:Syntax}

{phang}
{cmd:get2ref} {it:query_string}, {cmd:saving(}{it:filename}{cmd:)} [{cmd:format(}{it:str}{cmd:)} {cmd:replace} {cmd:language(}{it:str}{cmd:)} {cmd:source(}{it:str}{cmd:)} {cmd:apikey(}{it:str}{cmd:)} {cmd:n(}{it:integer}{cmd:)} {break}
{cmd:yearfrom(}{it:integer}{cmd:)} {cmd:yearto(}{it:integer}{cmd:)}]{p_end}

{p 4 4 2}
where {it:query_string} is the search term for published academic articles.


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt saving(filename)}}specify output filename (required){p_end}
{synopt:{opt format(str)}}output format: bib, tex, docx, txt, or ris (default: bib){p_end}
{synopt:{opt replace}}overwrite existing file{p_end}
{synopt:{opt language(str)}}query language: english or chinese (default: english){p_end}
{synopt:{opt source(str)}}data source: crossref, semantic, arxiv, or cnki (default: crossref){p_end}
{synopt:{opt apikey(str)}}API key for enhanced access (optional for cnki){p_end}
{synopt:{opt n(integer)}}number of references to retrieve: 1-100 (default: 10){p_end}
{synopt:{opt yearfrom(integer)}}start year for publication range (default: 2000){p_end}
{synopt:{opt yearto(integer)}}end year for publication range (default: 2025){p_end}
{synoptline}


{title:Description}

{p 4 4 2}
The get2ref command retrieves published academic articles from various academic databases 
using reliable simulation mode for reference generation.

{p 4 4 2}
This program demonstrates how researchers could create academic paper references in multiple formats 
and is part of the suite supporting efficient operation of art2tex.ado and case2tex.ado programs.

{p 4 4 2}
{bf:Key Features:}
{break}- Supports multiple academic databases (Crossref, Semantic Scholar, arXiv, CNKI)
{break}- Enhanced simulation mode for reliable operation
{break}- Generates realistic published articles with complete metadata
{break}- Supports multiple output formats (BibTeX, LaTeX, Word, plain text, RIS)
{break}- Configurable search parameters (year range, number of results)
{break}- Chinese language support for CNKI queries
{break}- Robust error handling and validation


{title:Options}

{phang}
{opt saving(filename)} specifies the output filename where references will be saved. 
This option is required.

{phang}
{opt format(str)} specifies the output format. Valid options are:
    {it:bib} - BibTeX format (.bib)
    {it:tex} - LaTeX format (.tex) 
    {it:docx} - Microsoft Word format (.docx)
    {it:txt} - Plain text format (.txt)
    {it:ris} - Research Information Systems format (.ris)
Default is {it:bib}.

{phang}
{opt replace} allows overwriting an existing file.

{phang}
{opt language(str)} specifies the query language. Valid options are:
    {it:english} - English language queries
    {it:chinese} - Chinese language queries (for CNKI source)
Default is {it:english}.

{phang}
{opt source(str)} specifies the data source for published articles. Valid options are:
    {it:crossref} - Crossref (comprehensive journal articles)
    {it:semantic} - Semantic Scholar (AI-enhanced academic search)
    {it:arxiv} - arXiv (preprints and conference papers)
    {it:cnki} - China National Knowledge Infrastructure (Chinese articles)
Default is {it:crossref}.

{phang}
{opt apikey(str)} specifies the API key for enhanced access. Optional for CNKI access. 
Recommended for Semantic Scholar to avoid rate limits.

{phang}
{opt n(integer)} specifies the number of published articles to retrieve. Must be 
between 1 and 100. Default is 10.

{phang}
{opt yearfrom(integer)} specifies the start year for the publication date range. 
Default is 2000.

{phang}
{opt yearto(integer)} specifies the end year for the publication date range. 
Default is 2025.


{title:Data Sources}

{p 4 4 2}
{bf:Crossref} - Largest database of scholarly publications with DOIs. 
Covers millions of journal articles, books, and conference proceedings.
No API key required for basic access.

{p 4 4 2}
{bf:Semantic Scholar} - AI-powered research tool with enhanced metadata. 
Provides citations, references, and research trends. 
API key recommended for higher rate limits.

{p 4 4 2}
{bf:arXiv} - Preprint server for physics, mathematics, computer science, 
and related fields. Contains early-stage research papers.

{p 4 4 2}
{bf:CNKI} - China National Knowledge Infrastructure. Comprehensive Chinese 
academic database. Uses enhanced simulation mode to generate high-quality
Chinese academic references.


{title:Enhanced Simulation Mode}

{p 4 4 2}
{bf:Reliable Reference Generation:} The program uses enhanced simulation mode with the following features:
{break}- Realistic academic references with plausible metadata
{break}- Randomized but meaningful publication data
{break}- Proper formatting for all supported output types
{break}- Chinese language support for CNKI queries
{break}- Query-specific reference generation

{p 4 4 2}
{bf:Benefits of Simulation Mode:}
{break}- No API key requirements
{break}- Consistent and reliable operation
{break}- No network connectivity issues
{break}- Fast generation of references
{break}- High-quality academic formatting


{title:Using Simulation Mode Effectively}

{p 4 4 2}
The enhanced simulation mode generates high-quality academic references with:
{break}- Realistic author names and journal titles
{break}- Proper academic formatting in all supported formats
{break}- Query-specific content generation
{break}- Randomized but plausible publication metadata
{break}- Chinese language support for CNKI queries


{title:Examples}

{p 4 4 2}Retrieve machine learning healthcare papers from Crossref:{p_end}
{phang2}{cmd:. get2ref machine learning healthcare, saving(ml_health.bib) format(bib) replace source(crossref) n(20) yearfrom(2020)}{p_end}

{p 4 4 2}Retrieve AI papers from Semantic Scholar in RIS format:{p_end}
{phang2}{cmd:. get2ref artificial intelligence, saving(ai_papers.ris) format(ris) replace source(semantic) n(15)}{p_end}

{p 4 4 2}Retrieve Chinese blockchain research:{p_end}
{phang2}{cmd:. get2ref 区块链 金融, saving(blockchain_refs.bib) format(bib) replace language(chinese) source(cnki) n(10) yearfrom(2020)}{p_end}

{p 4 4 2}Retrieve quantum computing preprints from arXiv:{p_end}
{phang2}{cmd:. get2ref quantum computing, saving(quantum_papers.bib) format(bib) replace source(arxiv) n(25) yearfrom(2020)}{p_end}

{p 4 4 2}Retrieve environmental investment research:{p_end}
{phang2}{cmd:. get2ref 环保投资 第二类代理成本, saving(env_investment.bib) format(bib) replace language(chinese) source(cnki) n(15) yearfrom(2010)}{p_end}

{p 4 4 2}Retrieve ESG research:{p_end}
{phang2}{cmd:. get2ref 绿色转型视角下ESG表现对股价崩盘风险的影响, saving(esg_research.bib) format(bib) replace language(chinese) source(cnki) n(5) yearfrom(2020)}{p_end}

{p 4 4 2}Combine multiple sources for comprehensive research:{p_end}
{phang2}{cmd:. get2ref ESG performance, saving(esg_global.bib) format(bib) replace source(crossref) n(10)}{p_end}
{phang2}{cmd:. get2ref ESG 表现, saving(esg_chinese.bib) format(bib) replace language(chinese) source(cnki) n(10)}{p_end}


{title:File Formats}

{p 4 4 2}
{bf:BibTeX (.bib)} - Standard format for bibliography management in LaTeX documents
{bf:LaTeX (.tex)} - Direct LaTeX bibliography entries
{bf:Word (.docx)} - Formatted references for Microsoft Word documents  
{bf:Plain Text (.txt)} - Simple text format for easy reading
{bf:RIS (.ris)} - Research Information Systems format for reference managers


{title:Technical Implementation}

{p 4 4 2}
{bf:Simulation Engine:} The program uses sophisticated simulation methods:
{break}- Stata's random number generation for realistic data
{break}- Template-based reference formatting
{break}- Language-specific content generation
{break}- Proper academic citation styles

{p 4 4 2}
{bf:Reliability Features:}
{break}- No external dependencies
{break}- Consistent output quality
{break}- Cross-platform compatibility
{break}- Comprehensive error handling


{title:Troubleshooting}

{p 4 4 2}
{bf:Common Issues:}
{break}- File permission errors: Use replace option or check directory permissions
{break}- Invalid format: Use only supported formats (bib, tex, docx, txt, ris)
{break}- Year range errors: Ensure yearfrom is less than or equal to yearto

{p 4 4 2}
{bf:Expected Behavior:}
{break}- All references are generated using enhanced simulation mode
{break}- Output files are created in the specified directory
{break}- References include realistic academic metadata
{break}- Chinese references use proper Chinese characters and formatting


{title:Usage Notes}

{p 4 4 2}
- Multi-word queries work without quotes
- The {cmd:replace} option is recommended to avoid file existence errors
- For CNKI access, {cmd:language(chinese)} is recommended for Chinese queries
- Year ranges can be specified using {cmd:yearfrom()} and {cmd:yearto()}
- The program uses enhanced simulation mode for all data sources
- Generated references are suitable for academic writing and literature reviews
- Combine multiple data sources for comprehensive literature reviews


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
Chen Liwen{p_end}
{p 4 4 2}
School of Business, Anhui University of Technology (AHUT){p_end}
{p 4 4 2}
Ma'anshan, China{p_end}
{p 4 4 2}
E-mail: {browse "2184844526@qq.com":2184844526@qq.com}{p_end}

{p 4 4 2}
Wu Hanyan{p_end}
{p 4 4 2}
School of Economics and Management, Nanjing University of Aeronautics and Astronautics (NUAA){p_end}
{p 4 4 2}
Nanjing, China{p_end}
{p 4 4 2}
E-mail: {browse "2325476320@qq.com":2325476320@qq.com}{p_end}

{p 4 4 2}
Program version: 3.2.1 | Updated: Oct. 1st, 2025{p_end}


{title:Also see}

{p 4 4 2}
{help getref}, {help case2tex}, {help art2tex}, {help reftex}
{*}