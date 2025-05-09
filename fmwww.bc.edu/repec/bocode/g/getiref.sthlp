{smcl}
{* *! version 2.2  08May2025}{...}
{hi:help getiref}{right:also see: {help lianxh}}
{right: {browse "https://github.com/arlionn/getiref"}}
{hline}

{marker title}{...}
{title:Title}

{p2colset 5 16 16 2}{...}
{p2col:{hi: getiref} {hline 2}}list reference in Results Window, and download PDF, .ris, .bibtex files for given {DOI}. 
{p_end}
{p2colreset}{...}


{marker quickexample}{...}
{title:Quick examples}

{phang}. {stata "getiref  10.1257/aer.109.4.1197"}{p_end}
{phang}. {stata "getiref  10.1257/aer.109.4.1197, cite"}{p_end}
{phang}. {stata "getiref  10.1257/aer.109.4.1197, pdf bib"}{p_end}
{phang}. {stata "getiref  10.3368/jhr.50.2.317, pdf bib md"}{p_end}


{marker syntax}{...}
{title:Syntax}

{phang}
{cmd:getiref}  {it:DOI}  
[{cmd:,} {opt p:ath(str)} 
         {opt m:d}           
         {opt md1}                 
         {opt md2}                 
         {opt md3}  
         {opt l:atex}               
         {opt w:echat}              
         {opt t:ext}        
         {opt c:ite}               
         {opt cite1}               
         {opt   c1}                
         {opt cite2}               
         {opt   c2}    
         {opt ar:xiv}
                      
{p 19}       
         {opt dis:fn}  
         {opt a:ll}      
         {opt p:df}                 
         {opt   bl:ank(string)}     
         {opt   noti:tle}           
         {opt   alt:name(string)}   
         {opt b:ib} 
      
{p 19}                    
         {opt clean}               
         {opt clip:off}             
         {opt n:otip}               
         {opt nog:oogle}            
         {opt d:oicheck}                                   
         {opt fast:scihub}  
]   

{col 5}{hline 80}
{col 5} {it:options} {col 28}Description
{col 5}{hline 80}
{col 5}Searching Fields and Time Range
{col 5}{hline 32} 			 
{col 7}{cmdab:pa:th(string)}    {col 28}the directory to save PDF, .ris, bibtex files

{col 5}Style of output
{col 5}{hline 15}        
{col 7}{cmdab:m:d}                {col 28}Markdown: {it:Reference. [Link], [PDF], [Google], [Appendix]}       
{col 7}{cmd:md1}                  {col 28}Markdown: clean format. Only [Link], [PDF]
{col 7}{cmd:md2}                  {col 28}Markdown: similar as '{cmd:md}', but with blanks in links
{col 7}{cmd:md3}                  {col 28}Markdown: similar as '{cmd:md1}', but with blanks in links
{col 7}{cmdab:l:atex}             {col 28}Same as {cmd:md}, but with links in TeX format.
{col 7}{cmdab:w:echat}            {col 28}Plain text format: Author, Year, title, URL
{col 7}{cmdab:t:ext}              {col 28}Equivalent to {bf:wechat}
{col 7}{cmdab:c:ite}              {col 28}'Author (Year)', with links
{col 7}{cmd:cite1}                {col 28}'Author, Year', with links, in text format
{col 7}{cmd:c1     }              {col 28}shortcut of {cmd:cite1} 
{col 7}{cmd:cite2}                {col 28}'Author (Year)', plain text
{col 7}{cmd:c2     }              {col 28}shortcut of {cmd:cite2} 
{col 7}{cmdab:ar:xiv }            {col 28}For arXiv papers, use '2401.01645' instead of '10.48550/arXiv.2401.01645' for DOI.

{col 5}Control and Save
{col 5}{hline 10}        
{col 5}{cmdab:dis:fn}             {col 28}display filename of PDF document for saving by hand 
{col 5}{cmdab:p:df}               {col 28}auto save PDF document, defult name: [Author_Year_Title]
{col 7}{cmdab:bl:ank(string)}     {col 28}Deal with the 'blanks' of filename of PDF document. e.g., 
{col 30}      {bf:defult}: 'Hansen_2023_Text_in_economics'
{col 30} {bf:blank}({it:keep}): 'Hansen 2023 Text in economics'
{col 30} {bf:blank}({it:bar}) : 'Hansen-2023-Text-in-economics'
{col 7}{cmdab:noti:tle}           {col 28}don't include article title in PDF filename: 'Hansen-2023'
{col 7}{cmdab:alt:name(string)}   {col 28}User specified PDF file name. Seldom use 
{col 5}{cmdab:b:ib}               {col 28}download and list {bf:.ris} and {bf:.bibtex} files
{col 30}used for reference managers (Endnote, Zotero, etc.)
{col 5}{cmd:clean}                {col 28}Clean pattern: Display only [link] and [PDF], omit [Appendix], [Google]
{col 5}{cmdab:clip:off}            {col 28}don't send message to clipboard
{col 5}{cmdab:n:otip}              {col 28}don't display 'Tips: Text is on clipboard.'
{col 5}{cmdab:nog:oogle}           {col 28}don't display google links
{col 5}{cmdab:d:oicheck}           {col 28}get {DOI} using regular expression from text given by user. 
{col 30}e.g, get '{bf:DOI}' from 'xxx https://doi.org/{bf:DOI}, xxx'.
{col 5}{cmdab:fast:scihub}         {col 28}find the fast url of {browse "https://lovescihub.wordpress.com/":SCI-Hub}. Seldom use. Time use: 1-2 seconds
{col 5}{hline 80} 



{marker description}{...}
{title:Description}

{pstd}
{help getiref} make it easy to get meta data of most academic articles using their {it:DOI}s.
It gets information like {it:Author name}, {it:Publication year}, {it:article Title}, {it:page range}, and even provides links to PDFs, as well as {bf:.bibtex/.ris} files associated with an anticle.

{pstd}
The citation information can be displayed and exported in various styles,
including Markdown, LaTeX, or Plain text.
This feature enables easy insertion or pasting into 
{bf:.md}, {bf:.docx}, or {bf:.tex} documents.
It proves highly practical for efficient literature note-taking,
significantly saving time on downloading, organizing PDF documents, and managing references.


{marker Examples}{...}
{title:Examples}

{dlgtab:basic usage}

{pstd}
It is simple: a valid {bf:DOI} is enough

{phang2}. {stata "getiref 10.1257/aer.109.4.1197"}{p_end}

{phang}:-->{p_end}
{phang}Blanchard, O. (2019). Public Debt and Low Interest Rates. American Economic Review, 109(4), 1197–1229.{p_end}
{phang2}{browse "https://doi.org/10.1257/aer.109.4.1197":Link (rep)}{space 4}   
{browse "http://sci-hub.ren/10.1257/aer.109.4.1197":PDF}{space 4}
{browse "https://scholar.google.com/scholar?q=Public%20Debt%20and%20Low%20Interest%20Rates":Google}{space 4}   
{browse "https://www.aeaweb.org/content/file?id=9241":Appendix}
{p_end}

{phang}{bf:Tips}: Text is on clipboard. Press '{bf:Ctrl+V}' to paste, ^-^{p_end}


{dlgtab:Download PDF and .ris files}

{phang}
With option {cmd:pdf}, {help getiref} can download PDF documents for most articles. 
By default, a new folder named "{bf:_temp_getref_}" will be created in current working directory and the PDF file will 
be saved in this new folder (Note: you can copy, renanme or even delete this folder later). When {cmd:path()} is specified, the PDF files will be saved in user specified directory.{p_end}

{phang2}. {stata "getiref 10.1257/aer.109.4.1197, pdf bib"}{p_end}

{phang}:-->{p_end}
{phang2}
Blanchard, O. (2019). Public Debt and Low Interest Rates. American Economic Review, 109(4), 1197–1229. https://doi.org/10.1257/aer.109.4.1197{p_end}

{phang2}
{space 6} {bf:PDF}:{space 2} dir {space 2} {browse "https://sci.bban.top/pdf/10.1257/aer.109.4.1197.pdf":view_online} {space 2} Open{p_end}
{phang2}
{space 1} {bf:Citation}:{space 4} . {space 2} 
{browse "http://api.crossref.org/works/10.1257/aer.109.4.1197/transform/application/x-bibtex":Bibtex} {space 2} 
{browse "http://api.crossref.org/works/10.1257/aer.109.4.1197/transform/application/x-research-info-systems":RIS} {p_end}
{phang2}
{space 2}Notes: {bf:RIS} - EndNote, ProCite, Mendeley{p_end}
{phang2}
{space 9}{bf:Bibtex} - LaTeX, Zotero, Mendeley{p_end}

{phang2}
Note that if you click '{bf:Bibtex}' or '{bf:RIS}' in the {bf:Results Window}, the corresponding .bibtex or .ris file will be opened by your reference manager software, such as Endnote of Zotero.{p_end}


{dlgtab:List meta data in Markdown format}

{phang2}. {stata "getiref 10.3368/jhr.50.2.317, md"}{p_end}

{phang}:-->{p_end}
{phang2}Colin Cameron, A., & Miller, D. L. (2015).
A Practitioner's Guide to Cluster-Robust Inference.
Journal of Human Resources, 50(2), 317–372.
[Link]({browse "https://doi.org/10.3368/jhr.50.2.317"}),
[PDF]({browse "http://sci-hub.ren/10.3368/jhr.50.2.317"}),
[Google](<{browse "https://scholar.google.com/scholar?q=A Practitioner's Guide to Cluster-Robust Inference"}>).{p_end}

{phang2}If you press shortcut '{bf:Ctrl+V} (Windows)' or '{bf:Cmd+V} (MacOSX)' in the Markdown editor, it will be rendered (converted) into the linked text as following:{p_end}

{phang2}
{space 3}Colin Cameron, A., & Miller, D. L. (2015).
A Practitioner's Guide to Cluster-Robust Inference.
Journal of Human Resources, 50(2), 317–372.
{browse "https://doi.org/10.3368/jhr.50.2.317":Link},
{browse "http://sci-hub.ren/10.3368/jhr.50.2.317":PDF},
{browse "https://scholar.google.com/scholar?q=A Practitioner's Guide to Cluster-Robust Inference":Google}{p_end}


{dlgtab:In text citation format:}

{phang2}. {stata "getiref 10.1257/aer.109.4.1197, cite"}{p_end}

{phang}:-->{p_end}
{phang2}[{browse "https://doi.org/10.1257/aer.109.4.1197":Blanchard}](https://doi.org/10.1257/aer.109.4.1197)
([{browse "http://sci-hub.ren/10.1257/aer.109.4.1197":2019}](http://sci-hub.ren/10.1257/aer.109.4.1197)){p_end}  
{phang2}It will be shown in Markdown editor as 
'{browse "https://doi.org/10.1257/aer.109.4.1197":Blanchard}
({browse "http://sci-hub.ren/10.1257/aer.109.4.1197":2019})'.{p_end}  
    
{col 9}{ul:version 2:}

{phang2}. {stata "getiref 10.1257/aer.109.4.1197, cite2"}{p_end}

{phang2}Similar as the {cmd:cite} case, but the text does not have a hyperlink.{p_end}


{dlgtab:Special cases:}

{pstd}
The following two commands are equivalent, and 'ar' means 'arxiv'.:

{phang2}. {stata "getiref 2303.17564, ar"}{p_end}

{phang2}. {stata "getiref 10.48550/arXiv.2303.17564"}{p_end}


{title:Appendix: About DOI}

{bf:What is DOI?}

{pstd}
We always see reference in form '{bf:Blanchard, O. (2019). Public Debt and Low Interest Rates. American Economic Review, 109(4), 1197–1229. https://doi.org/{browse "https://doi.org/10.1257/aer.109.4.1197":10.1257/aer.109.4.1197}}'.

{pstd}
Here, {bf:10.1257/aer.109.4.1197} is called 
{bf:DOI} (Digital Object Identifier),
a persistent identifier used to uniquely identify this paper,
whereas its location and other metadata may change. 

{pstd}
DOIs include a prefix (prefixes always start with {bf:10.})
and a suffix, separated by a forward slash (/).
Prefacing the DOI with {browse "https://www.doi.org/":doi.org/}
will turn it into an actionable link, 
for example, {browse "https://www.doi.org/10.1257/aer.109.4.1197":https://www.doi.org}/{bf:10.1257}/aer.109.4.1197.
Clicking that link will 'resolve' it, i.e. redirect to the
latest information about the object it identifies,
even if the object changes or moves.

{pstd}
Some typical DOIs are list as follwoing:

{phang2}
o {browse "https://doi.org/10.48550/arXiv.2312.05400":10.48550/arXiv.2312.05400} (arXiv) 
{p_end}
{phang2}
o {browse "https://doi.org/10.1177/1536867X231212453":10.1177/1536867X231212453} (Stata Journal) 
{p_end}
{phang2}
o {browse "https://doi.org/10.1162/rest.90.3.592":10.1162/rest.90.3.592} (RES) 
{p_end}
{phang2}
o {browse "https://doi.org/10.3386/w31184":10.3386/w31184} (NBER) 
{p_end}

{pstd}
See {browse "https://www.doi.org/the-identifier/what-is-a-doi/":DOI-1}, {browse "https://academicguides.waldenu.edu/library/doi":DOI-2} or {browse "https://www.doi.org/the-identifier/resources/handbook":DOI-Handbook} for details.
{p_end}	

{bf:How to use DOI?}

{pstd}
Inspite of prefacing the DOI with {browse "https://www.doi.org/":doi.org/} to redirect to the article page, we can also get more detailed information of the article using meta data.

{pstd}
There are two main DOI Registration Agencies, {bf:Crossref} and {bf:Datacite}. 
They provide detail meta data
({browse "https://search.crossref.org/":crossref},
{browse "https://support.datacite.org/reference/create-metadata-record-1":datacite})
for most paper with DOI. The meta data can be obtained easily using API.
See {browse "https://project-thor.readme.io/docs/searching-doi-registries":Searching DOI metadata} for details. 

{pstd}
Nowadays, there are many Open-access papers. 
We can abtain their PDF documents using DOI.
For example, given {it:{browse "https://www.doi.org/10.48550/arXiv.2312.05400":10.48550/arXiv.2312.05400}}, which has the form of {it:10.48550/arXiv.{{bf:ar_ID}}},
we can get the PDF document of this paper with URL: {bf:https://arxiv.org/pdf/{bf:{ar_ID}}.pdf},
i.e., {browse "https://arxiv.org/pdf/2312.05400.pdf"}


{title:Saved results}

{pstd}
{cmd:getiref} saves the following in {cmd:r()} in case of the following commands:

{phang}. {stata "getiref 10.1257/aer.109.4.1197, md pdf bib"}{p_end} 
{phang}. {stata "ret list"}{p_end} 

{pstd}
{bf:Scalars}{p_end}

{synoptset 15 tabbed}{...}
{synopt:{cmd:r(got_pdf)}}  1 = got PDF document, 0 = failed. (Note: option {cmd:pdf} or {cmd:all} required){p_end}
{synopt:{cmd:r(got_bib)}}  1 = got .bibtex and .ris files, 0 = failed. (Note: option {cmd:bib} or {cmd:all} required){p_end}
{synopt:{cmd:r(with_rep)}} 1 = with replication codes/data, 0 = no.{p_end}
{synopt:{cmd:r(with_app)}} 1 = with online appendix or supplementary documents, 0 = no.{p_end}

{pstd}
{bf:Macros}{p_end}

{dlgtab:Basic}

{synoptset 15 tabbed}{...}
{synopt:{cmd:r(doi)}}10.1257/aer.109.4.1197 {space 4}Mark as {bf:{DOI}}{p_end}
{synopt:{cmd:r(author1)}}Blanchard{p_end}
{synopt:{cmd:r(year)}}2019{p_end}
{synopt:{cmd:r(title)}}Public Debt and Low Interest Rates{p_end}
{synopt:{cmd:r(filename)}}Blanchard_2019_Public_Debt_and_Low_Interest_Rates{p_end}
{synopt:{cmd:r(link)}}https://doi.org/{bf:{DOI}}{p_end}
{synopt:{cmd:r(refbody)}}Blanchard, O. (2019). Public Debt and Low Interest Rates. American Economic Review, 109(4), 1197–1229.{p_end}
{synopt:{cmd:r(ref)}}{cmd:r(refbody)} + {cmd:r(link)}{p_end}
{synopt:{cmd:r(pdf_web)}}http://sci-hub.ren/{bf:{DOI}}{p_end}

{dlgtab:Advanced: for programer}

{p 6 2 2}{cmd:r(pdfurl)}{space 13}https://sci.bban.top/pdf/{bf:{DOI}}.pdf{p_end}
{p 6 2 2}{cmd:r(refdis)}{space 13}{cmd:r(refbody)}. Links ([Link], [PDF], [Google], [Appendix]){p_end}
{p 6 2 2}{cmd:r(ref_link_pdf)}{space 7}{cmd:r(refbody)} + {cmd:r(link)} + {cmd:r(pdf_web)}{p_end}
{p 6 2 2}{cmd:r(ref_link_pdf_full)}{space 2}{cmd:r(refbody)}. [Link], {cmd:r(pdfurl)}.{p_end}
{p 6 2 2}{cmd:r(pdf_br)}{space 13}browse "http://sci-hub.ren/{bf:{DOI}}":PDF{p_end}
{p 6 2 2}{cmd:r(pdf_br_full)}{space 8}browse "https://sci.bban.top/pdf/{bf:{DOI}}.pdf":PDF{p_end}
{p 6 2 2}{cmd:r(au_yr_doi)}{space 10}Blanchard-2019-10.1257_aer.109.4.1197{p_end}
{p 6 2 2}{cmd:r(ris)}{space 16}http://api.crossref.org/works/{bf:{DOI}}/transform/application/x-research-info-systems{p_end}
{p 6 20 20}{cmd:r(bibtex)}{space 13}http://api.crossref.org/works/{bf:{DOI}}/transform/application/x-bibtex{p_end}

{pstd}
You can {help display} specific return value as following:

{phang}{space 4}. {stata `"dis `"`r(refdis)'"'"'}{p_end} 
{pstd}
Moreover, if you have a long list of DOIs, say {{bf:DOI_i}}
a loop on {bf:DOI_i} can be used to get a reference list.


{title:Authors}

{phang}
{cmd:Yujun Lian* (连玉君)} Lingnan College, Sun Yat-Sen University, China.{break}
E-mail: {browse "mailto:arlionn@163.com":arlionn@163.com} {break}
Blog: {browse "https://www.lianxh.cn":lianxh.cn} {break}
{p_end}


{title:Questions and Suggestions}

{p 4 4 2}
If you encounter any issues or have suggestions while using the tool,
we will address them promptly. Please email us at:
{browse "mailto:arlionn@163.com":arlionn@163.com}.

{p 4 4 2}
You can also submit your suggestions by filling out
{browse "https://github.com/arlionn/getiref/issues/":Issues}
in the project's {browse "https://github.com/arlionn/getiref":GitHub} repository.
For Chinese users, please visit the {browse "https://gitee.com/arlionn/getiref":Gitee} repository.


{title:Also see}

{psee} Online:  
{help lianxh} (if installed),
{help songbl} (if installed),
{help cnssc} (if installed)