{smcl}
{* *! version 2.4 09-Sep-2025}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Related commands" "help art2tex"}{...}
{viewerjumpto "Syntax" "art2tex##syntax"}{...}
{viewerjumpto "Description" "art2tex##description"}{...}
{viewerjumpto "Options" "art2tex##options"}{...}
{viewerjumpto "Examples" "art2tex##examples"}{...}
{viewerjumpto "Compilation Instructions" "art2tex##compilation"}{...}
{viewerjumpto "Authors" "art2tex##authors"}{...}
{title:Title}

{p 4 4 2}
{bf:art2tex} - Automatically generate structured academic paper LaTeX framework (Chinese/English support){p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 8 2} {cmd:art2tex} [{cmd:,} {cmd:LANGuage}({it:string}) {cmd:filename}({it:string}) {cmd:Title}({it:string}) {cmd:Author}({it:string})]{p_end}

{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:art2tex} is a professional Stata program designed for empirical researchers in economics, management, and related fields.
It automatically generates LaTeX paper frameworks that comply with international academic standards, with support for both Chinese and English papers.
The program creates complete document structures, preset table environments, mathematical formulas, reference formats,
and generates accompanying Stata table export commands and BibTeX reference templates.{p_end}

{p 4 4 2}
Key features include:{p_end}
{p 6 6 2}• Intelligent generation of complete LaTeX documents with abstract, keywords, and chapter structure{p_end}
{p 6 6 2}• Preconfigured variable definition tables, empirical model formulas, and regression table templates{p_end}
{p 6 6 2}• Automatic creation of tables and figures directories{p_end}
{p 6 6 2}• Generation of accompanying Stata table export command scripts{p_end}
{p 6 6 2}• Generation of accompanying Stata figure export command scripts{p_end}
{p 6 6 2}• Pre-built figure environments in introduction, theoretical analysis, and robustness sections{p_end}
{p 6 6 2}• Support for XeLaTeX compilation and BibTeX reference management{p_end}
{p 6 6 2}• Bilingual support for both Chinese and English papers{p_end}

{marker options}{...}
{title:Options}

{phang}
{opt LANGuage(string)} specifies document language, defaults to "chinese". Supports "chinese" or "english".{p_end}

{phang}
{opt filename(string)} specifies output LaTeX filename, defaults to "paper.tex".{p_end}

{phang}
{opt Title(string)} specifies paper title. Defaults to "论文标题" for Chinese or "Paper Title" for English.{p_end}

{phang}
{opt Author(string)} specifies author names, multiple authors separated by spaces. Defaults to "作者姓名" for Chinese or "Author Name" for English.{p_end}

{marker examples}{...}
{title:Examples}

{p 4 4 2}Generate default Chinese paper framework:{p_end}
{phang2}{cmd:. art2tex}{p_end}

{p 4 4 2}Generate English paper framework:{p_end}
{phang2}{cmd:. art2tex, language(english)}{p_end}

{p 4 4 2}Custom title and authors:{p_end}
{phang2}{cmd:. art2tex, title("ESG Performance and Corporate Green Innovation") author("John Zhang Mary Li") language(english)}{p_end}

{p 4 4 2}Specify filename and language:{p_end}
{phang2}{cmd:. art2tex, filename("my_paper") language("chinese")}{p_end}

{marker compilation}{...}
{title:Compilation Instructions}

{p 4 4 2}
Generated LaTeX documents require compilation with XeLaTeX and BibTeX. Recommended compilation sequence:{p_end}
{p 6 6 2}1. {cmd:xelatex paper}{p_end}
{p 6 6 2}2. {cmd:bibtex paper} (essential for reference compilation){p_end}
{p 6 6 2}3. {cmd:xelatex paper}{p_end}
{p 6 6 2}4. {cmd:xelatex paper}{p_end}

{p 4 4 2}
For Chinese papers, ensure your TeX distribution includes Chinese font support.{p_end}

{p 4 4 2}
Recommended environment: TeX Live 2023 or later, with a LaTeX-supported editor (TeXstudio, VS Code, etc.).{p_end}

{marker authors}{...}
{title:Authors}

{pstd}
{bf:Wu Lianghai, Chen Liwen, Liu Changyun, Zhao Xin}{p_end}
{pstd}School of Business, Anhui University of Technology(AHUT){p_end}
{pstd}Ma'anshan, China{p_end}
{pstd}{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}
{pstd}{browse "mailto:2184844526@qq.com":2184844526@qq.com}{p_end}
{pstd}{browse "mailto:2437563124@qq.com":2437563124@qq.com}{p_end}
{pstd}{browse "mailto:1980124145@qq.com":1980124145@qq.com}{p_end}

{pstd}
{bf:Hu Fangfang}{p_end}
{pstd}School of Finance and Economics, Wanjiang University of Technology(WJUT){p_end}
{pstd}Ma'anshan, China{p_end}
{pstd}{browse "mailto:huff470@163.com":huff470@163.com}{p_end}

{pstd}
{bf:Wu Hanyan}{p_end}
{pstd}School of Economics and Management, Nanjing University of Aeronautics and Astronautics(NUAA){p_end}
{pstd}Nanjing, China{p_end}
{pstd}{browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{pstd}
{bf:Wu Xinzhuo}{p_end}
{pstd}University of Bristol(UB){p_end}
{pstd}{browse "mailto:2957833979@qq.com":2957833979@qq.com}{p_end}

{title:Also see}

{p 4 4 2}
Related commands: {help esttab}, {help estout}, {help latex}, {help sumtex}, {help corrtex2}, {help regtex}, {help reg2tex}, {help reftex}{p_end}
{*}