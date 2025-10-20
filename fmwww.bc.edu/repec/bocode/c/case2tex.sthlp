{smcl}
{* 19Oct2025}{...}
{hline}
help for {bf:case2tex} {right:Create case study paper framework following international journal standards}
{hline}

{title:Title}

{p 4 4 2}
{bf:case2tex} - Create a case study paper framework following international journal publication standards

{title:Syntax}

{p 4 4 2}
{cmd:case2tex} [, {opt l:anguage(str)} {opt f:ilename(str)} {opt r:eplace} {opt t:itle(str)} {opt a:uthor(str)}
{opt abs:tractalign(str)} {opt k:eywordseparator(str)} {opt font:(str)} {opt fonts:ize(str)} {opt lines:pacing(str)}]

{title:Description}

{p 4 4 2}
{cmd:case2tex} creates a comprehensive LaTeX template for case study papers that conforms to international journal publication standards. 
The template includes complete paper structure with predefined sections, mathematical formulas, citation examples, 
configurable abstract formatting, keyword separators, and support for both Chinese and English languages. 
It automatically creates necessary subdirectories and example files for immediate compilation.

{title:Options}

{phang}
{opt l:anguage(str)} specifies the document language. Default is {bf:chinese}. Alternative is {bf:english}.

{phang}
{opt f:ilename(str)} specifies the name of the output .tex file. Default is {bf:case_study_template}.

{phang}
{opt r:eplace} specifies that existing files can be overwritten. If this option is not specified and the output file already exists, the command will display an error and exit.

{phang}
{opt t:itle(str)} specifies the paper title. Default is {bf:案例研究标题} for Chinese or {bf:Case Study Title} for English.

{phang}
{opt a:uthor(str)} specifies the author name(s). Default is {bf:作者姓名} for Chinese or {bf:Author Name} for English.

{phang}
{opt abs:tractalign(str)} specifies abstract alignment. Options are {bf:indent} (default) or {bf:left}.

{phang}
{opt k:eywordseparator(str)} specifies keyword separator. Options are {bf:comma} (default), {bf:semicolon}, or {bf:space}.

{phang}
{opt font:(str)} specifies the main font. Default is {bf:Times New Roman}.

{phang}
{opt fonts:ize(str)} specifies the font size. Default is {bf:12pt}.

{phang}
{opt lines:pacing(str)} specifies the line spacing. Default is {bf:1.5}.

{title:Template Structure}

{p 4 4 2}
The generated template includes the following complete paper structure:
{p_end}
{p 6 6 2}
1. Title, author, and date section
{p_end}
{p 6 6 2}
2. Abstract with flexible formatting (indented or left-aligned)
{p_end}
{p 6 6 2}
3. Keywords with configurable separators
{p_end}
{p 6 6 2}
4. Introduction section with placeholder content
{p_end}
{p 6 6 2}
5. Literature Review section with citation examples
{p_end}
{p 6 6 2}
6. Methodology section with complete mathematical formulas (entropy method)
{p_end}
{p 6 6 2}
7. Case Analysis section
{p_end}
{p 6 6 2}
8. Results section
{p_end}
{p 6 6 2}
9. Discussion section
{p_end}
{p 6 6 2}
10. Conclusion section
{p_end}
{p 6 6 2}
11. Example tables and figures with proper formatting
{p_end}
{p 6 6 2}
12. References section supporting BibTeX
{p_end}
{p 6 6 2}
13. Support for comment environments for adding multi-line comments
{p_end}

{p 4 4 2}
All main sections include corresponding subsections and subsubsections for detailed organization.
The methodology section includes complete mathematical formulas demonstrating the entropy method
for indicator weight calculation, including standardization, proportion calculation, entropy value,
and weight determination formulas.

{title:Generated Files and Directories}

{p 4 4 2}
The command automatically creates the following directory structure and files:
{p_end}
{p 6 6 2}
- Main LaTeX document: {it:filename}.tex
{p_end}
{p 6 6 2}
- {bf:figures/} directory with README.txt containing image requirements
{p_end}
{p 6 6 2}
- {bf:tables/} directory with example_table.tex containing sample data table
{p_end}
{p 6 6 2}
- {bf:references.bib} file with example citations in the selected language
{p_end}

{title:Mathematical Content}

{p 4 4 2}
The template includes comprehensive mathematical formulas in the methodology section:
{p_end}
{p 6 6 2}
- Data standardization formula
{p_end}
{p 6 6 2}
- Proportion calculation formula
{p_end}
{p 6 6 2}
- Entropy value calculation
{p_end}
{p 6 6 2}
- Indicator weight determination
{p_end}
{p 6 6 2}
All formulas are properly labeled and referenced in the text.
{p_end}

{title:Citation Support}

{p 4 4 2}
The template includes natbib package support with example citations in the literature review section.
The references.bib file contains sample entries that demonstrate proper BibTeX formatting for both
Chinese and English publications.

{title:Comment Environment Support}

{p 4 4 2}
The template now includes the {bf:comment} package, allowing users to easily add multi-line comments
in their LaTeX documents. This is particularly useful for:

{p 6 6 2}
- Temporarily excluding large sections of text during drafting
{p_end}
{p 6 6 2}
- Adding notes and reminders that should not appear in the final document
{p_end}
{p 6 6 2}
- Creating multiple versions of the same document by selectively commenting sections
{p_end}

{p 4 4 2}
Usage example:
{p_end}
{hline}
\begin{comment}
This text will not appear in the final document.
You can add multiple paragraphs here.
\end{comment}
{hline}

{title:Examples}

{p 4 4 2}
Create a basic template with default settings (Chinese):
{p_end}
{phang2}{cmd:. case2tex}{p_end}

{p 4 4 2}
Create an English template with specific title and author:
{p_end}
{phang2}{cmd:. case2tex, language(english) title("Data Asset Management Case Study") author("John Smith")}{p_end}

{p 4 4 2}
Overwrite existing template files:
{p_end}
{phang2}{cmd:. case2tex, replace}{p_end}

{p 4 4 2}
Create an English template with left-aligned abstract and semicolon-separated keywords:
{p_end}
{phang2}{cmd:. case2tex, language(english) abstractalign(left) keywordseparator(semicolon)}{p_end}

{p 4 4 2}
Create a Chinese template with custom formatting:
{p_end}
{phang2}{cmd:. case2tex, font("SimSun") fontsize("11pt") linespacing("1.2")}{p_end}

{p 4 4 2}
Create template with custom filename:
{p_end}
{phang2}{cmd:. case2tex, filename("my_case_study") replace}{p_end}

{marker authors}{...}
{title:Authors}

{pstd}
Wu Lianghai{p_end}
{pstd}School of Business, Anhui University of Technology, Ma'anshan, China{p_end}
{pstd}{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}

{pstd}
Chen Liwen{p_end}
{pstd}School of Business, Anhui University of Technology, Ma'anshan, China{p_end}
{pstd}{browse "mailto:2184844526@qq.com":2184844526@qq.com}{p_end}

{pstd}
Zhao Xin{p_end}
{pstd}School of Business, Anhui University of Technology, Ma'anshan, China{p_end}
{pstd}{browse "mailto:1980124145@qq.com":1980124145@qq.com}{p_end}

{pstd}
Liu Rui{p_end}
{pstd}School of Business, Anhui University of Technology, Ma'anshan, China{p_end}
{pstd}{browse "mailto:3221241855@qq.com":3221241855@qq.com}{p_end}

{pstd}
Wu Hanyan{p_end}
{pstd}School of Economics and Management, Nanjing University of Aeronautics and Astronautics (NUAA), Nanjing, China{p_end}
{pstd}{browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{pstd}Ma'anshan/Nanjing, China{p_end}

{title:Compilation Instructions}

{p 4 4 2}
After generating the template, compile using the following sequence:
{p_end}
{p 6 6 2}
1. XeLaTeX → 2. BibTeX → 3. XeLaTeX → 4. XeLaTeX
{p_end}

{p 4 4 2}
Make sure the required image files exist in the figures directory before compilation.
The template expects the following image files (or modify the .tex file accordingly):
{p_end}
{p 6 6 2}
- figures/global_data_growth.png
{p_end}
{p 6 6 2}
- figures/scatter_plot.png
{p_end}

{title:Acknowledgments}

{p 4 4 2}
We sincerely appreciate Christopher F. Baum for his prompt guidance and revision suggestions!

{title:Also see}

{p 4 4 2}
Online: {help latex}, {help texdoc}, {help art2tex}, {help sumtex}, {help corrtex2}, {help reftex}, {help regtex}, {help reg2tex}, {help getref}, {help get2ref}(if installed)
{p_end}
{*}
[file content end]