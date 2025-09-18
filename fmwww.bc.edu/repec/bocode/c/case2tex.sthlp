{smcl}
{* 17Sep2025}{...}
{hline}
help for {bf:case2tex} {right:Create case study paper framework following international journal standards}
{hline}

{title:Title}

{p 4 4 2}
{bf:case2tex} - Create a case study paper framework following international journal publication standards

{title:Syntax}

{p 4 4 2}
{cmd:case2tex} [, {opt lan:guage(str)} {opt fil:ename(str)} {opt tit:le(str)} {opt aut:hor(str)}
{opt abs:tractalign(str)} {opt key:wordseparator(str)} {opt font(str)} {opt font:size(str)} {opt line:spacing(str)}]

{title:Description}

{p 4 4 2}
{cmd:case2tex} creates a LaTeX template for case study papers that conforms to international journal publication standards. 
The template includes flexible abstract formatting, configurable keyword separators, support for figures and tables, 
mathematical equations, and options for both .tex and .bib reference formats. The template supports both Chinese and English languages.

{title:Options}

{phang}
{opt lan:guage(str)} specifies the document language. Default is {bf:chinese}. Alternative is {bf:english}.

{phang}
{opt fil:ename(str)} specifies the name of the output .tex file. Default is {bf:case_study_template}.

{phang}
{opt tit:le(str)} specifies the paper title. Default is {bf:Case Study Title} for English or {bf:案例研究标题} for Chinese.

{phang}
{opt aut:hor(str)} specifies the author name(s). Default is {bf:Author Name} for English or {bf:作者姓名} for Chinese.

{phang}
{opt abs:tractalign(str)} specifies abstract alignment. Options are {bf:indent} (default) or {bf:left}.

{phang}
{opt key:wordseparator(str)} specifies keyword separator. Options are {bf:comma} (default), {bf:semicolon}, or {bf:space}.

{phang}
{opt font(str)} specifies the main font. Default is {bf:Times New Roman}.

{phang}
{opt font:size(str)} specifies the font size. Default is {bf:12pt}.

{phang}
{opt line:spacing(str)} specifies the line spacing. Default is {bf:1.5}.

{title:Template Structure}

{p 4 4 2}
The generated template includes the following sections:
{p_end}
{p 6 6 2}
1. Abstract and keywords with flexible formatting
{p_end}
{p 6 6 2}
2. Introduction (level 1 heading)
{p_end}
{p 6 6 2}
3. Literature Review (level 1 heading) with citation examples
{p_end}
{p 6 6 2}
4. Methodology (level 1 heading) with mathematical equations (entropy method example)
{p_end}
{p 6 6 2}
5. Case Analysis (level 1 heading)
{p_end}
{p 6 6 2}
6. Results (level 1 heading)
{p_end}
{p 6 6 2}
7. Discussion (level 1 heading)
{p_end}
{p 6 6 2}
8. Conclusion (level 1 heading)
{p_end}
{p 6 6 2}
9. Example tables and figures (automatically created in subdirectories)
{p_end}
{p 6 6 2}
10. References (supporting both .tex and .bib formats)
{p_end}

{p 4 4 2}
All main sections include subsections and subsubsections for detailed organization.
The template automatically creates 'figures' and 'tables' subdirectories and includes
example files that allow immediate compilation without modification.

{title:Generated Files}

{p 4 4 2}
The command creates the following files and directories:
{p_end}
{p 6 6 2}
- A main .tex file with the specified name
{p_end}
{p 6 6 2}
- A 'figures' directory with README instructions
{p_end}
{p 6 6 2}
- A 'tables' directory with an example table
{p_end}
{p 6 6 2}
- A references.bib file with example citations
{p_end}

{title:New Features in v1.7.3}

{p 4 4 2}
- Fixed colon duplication issue in Chinese keywords section
- Fixed reference title display issue (only one title appears now)
- Enhanced citation formatting with proper parentheses
- Improved language-specific formatting consistency
- Added comprehensive mathematical equation examples in methodology section
- Added automatic creation of subdirectories and example files
- Added support for multiple keyword separator options

{title:Examples}

{p 4 4 2}
Create a basic template with default settings (Chinese):
{p_end}
{phang2}{cmd:. case2tex}{p_end}

{p 4 4 2}
Create an English template with specific title and author:
{p_end}
{phang2}{cmd:. case2tex, language(english) title("ESG Management and Shared Value Creation") author("John Smith")}{p_end}

{p 4 4 2}
Create an English template with specific title and author and  abstractalign:
{p_end}
{phang2}{cmd:. case2tex, language(english) title("ESG Management and Shared Value Creation") author("John Smith")  abstractalign(left)}{p_end}

{p 4 4 2}
Create a Chinese template with left-aligned abstract and semicolon-separated keywords:
{p_end}
{phang2}{cmd:. case2tex, abstractalign(left) keywordseparator(semicolon)}{p_end}

{p 4 4 2}
Create an English template with specific formatting:
{p_end}
{phang2}{cmd:. case2tex, language(english) font(Arial) fontsize(11pt) linespacing(1.2)}{p_end}

{marker authors}{...}
{title:Authors}

{pstd}
{bf:Wu Lianghai, Chen Liwen, Zhao Xin, Liu Rui, Wu Hanyan}{p_end}
{pstd}School of Business, Anhui University of Technology(AHUT){p_end}
{pstd}School of Economics and Management, Nanjing University of Aeronautics and Astronautics(NUAA){p_end}
{pstd}Ma'anshan/Nanjing, China{p_end}
{pstd}{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}
{pstd}{browse "mailto:2184844526@qq.com":2184844526@qq.com}{p_end}
{pstd}{browse "mailto:1980124145@qq.com":1980124145@qq.com}{p_end}
{pstd}{browse "mailto:3221241855@qq.com":3221241855@qq.com}{p_end}
{pstd}{browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{title:Acknowledgments}

{p 4 4 2}
We sincerely appreciate Kit Baum and Christopher F. Baum for their prompt guidance and revision suggestions!

{title:Also see}

{p 4 4 2}
Online: {help latex}, {help texdoc}, {help art2tex}, {help sumtex}, {help corrtex2}, {help reftex}, {help regtex}, {help reg2tex} (if installed)
{p_end}
{*}