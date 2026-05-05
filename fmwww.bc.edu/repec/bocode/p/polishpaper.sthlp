{smcl}
{* *! version 2.1 02May2026}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "help" "help help"}{...}
{viewerjumpto "Syntax" "polishpaper##syntax"}{...}
{viewerjumpto "Description" "polishpaper##description"}{...}
{viewerjumpto "Options" "polishpaper##options"}{...}
{viewerjumpto "Examples" "polishpaper##examples"}{...}
{viewerjumpto "Stored results" "polishpaper##results"}{...}
{viewerjumpto "Authors" "polishpaper##authors"}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:polishpaper} {hline 2}}Generate a Structured Polishing Template for Academic Papers{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:polishpaper}
[{cmd:,} {it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt language(string)}}Specify output language (Chinese/中文/zh or English/英文/en){p_end}
{synopt:{opt saving(string)}}Specify filename for output text file{p_end}
{synopt:{opt replace}}Overwrite existing file with the same name{p_end}
{synopt:{opt author(string)}}Specify author name{p_end}
{synopt:{opt date(string)}}Specify date used in the template{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:{ul:l}anguage(string)} supports "Chinese", "中文", "zh", "English", "英文", "en".
Default is "English".
{p_end}{p 4 6 2}
{cmd:{ul:s}aving(string)} specifies the filename for the output text file.
Default is "polish_template.txt".
{p_end}{p 4 6 2}
{cmd:{ul:a}uthor(string)} specifies the author name.
If not specified, defaults to "Prof. Wu Lianghai, Wu Hanyan & Yang Lu".
{p_end}{p 4 6 2}
{cmd:{ul:d}ate(string)} specifies the date information to use in the template.
Recommended format is "DDMonYYYY" (e.g., 20Mar2026). Default is "20Mar2026".
{p_end}{p 4 6 2}
{p_end}


{marker description}{...}
{title:Description}

{pstd}
The {cmd:polishpaper} command generates a structured text file containing
a polishing template for academic papers. The template includes seven tasks
designed to guide users through the manuscript revision process.

{pstd}
The seven tasks are:
{break}1. Improve Paragraph (Clarity & Conciseness)
{break}2. Paraphrase Sentence (Avoid Plagiarism)
{break}3. Suggest Title
{break}4. Generate Keywords
{break}5. Write Conclusion
{break}6. Discussion Outline
{break}7. Argue Significance

{pstd}
Version history:
{break}v2.0 (02May2026): Added {cmd:author()} and {cmd:date()} options;
improved bilingual support with zh/en language aliases
{break}v1.0 (20Mar2026): Initial release


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt language(string)} specifies the output language for the template.
Valid values are: "Chinese", "中文", "zh" (for Chinese), "English",
"英文", "en" (for English). When English is selected (default), the
template content is in English; when Chinese is selected, the template
content is in Chinese.
The option can be abbreviated as {cmd:l}.

{phang}
{opt saving(string)} specifies the filename for the output text file.
The default is "polish_template.txt" in the current working directory.
If the filename does not include a path, the file will be saved in the
current directory. Use quotes if the filename contains spaces.
The option can be abbreviated as {cmd:s}.

{phang}
{opt author(string)} specifies the author name to be included in the
template header. If not specified, defaults to "Prof. Wu Lianghai,
Wu Hanyan & Yang Lu". This option allows users to personalize the generated
template.
The option can be abbreviated as {cmd:a}.

{phang}
{opt date(string)} specifies the date information to use in the template.
The recommended format is "DDMonYYYY" (e.g., 20Mar2026). If not specified,
defaults to "20Mar2026".
The option can be abbreviated as {cmd:d}.

{phang}
{opt replace} overwrites an existing file with the same name.
If the target file already exists and this option is not specified,
the program will report an error and terminate. 

{marker examples}{...}
{title:Examples}

{pstd}Basic example with English template{p_end}

{phang2}{cmd:. polishpaper}{p_end}

{pstd}Generate Chinese template using zh alias (abbreviated options){p_end}

{phang2}{cmd:. polishpaper, l(zh) s(my_polish.txt)}{p_end}

{pstd}Generate Chinese template using Chinese keyword (full option names){p_end}

{phang2}{cmd:. polishpaper, language(Chinese) saving(my_polish.txt)}{p_end}

{pstd}Complete example with all options (using abbreviations){p_end}

{phang2}{cmd:. polishpaper, l(Chinese) s("D:\Paper\polish_template.txt") a("Prof. Wang Wu") d("25Mar2026") r}{p_end}

{pstd}Generate English template with custom author and date (full option names){p_end}

{phang2}{cmd:. polishpaper, language(en) author("Dr. Li Hua & Prof. Zhang Wei") date("01Apr2026")}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:polishpaper} does not store results in {cmd:r()}. All output is
directly written to the specified text file, and generation information
is displayed in the Stata results window.

{marker authors}{...}
{title:Authors}

{pstd}
{browse "mailto:agd2010@yeah.net":Wu Lianghai}{break}
School of Business, Anhui University of Technology (AHUT){break}
Ma'anshan, China

{pstd}
{browse "mailto:2325476320@qq.com":Wu Hanyan}{break}
School of Economics and Management, Nanjing University of Aeronautics
and Astronautics (NUAA){break}
Nanjing, China

{pstd}
{browse "mailto:1026835594@qq.com":Yang Lu}{break}
Finance Bureau of Rugao City, Jiangsu Province, China{break}
Rugao, China

{pstd}
Technical Support: Intelligent Accounting Laboratory,
Anhui University of Technology{break}
Last Updated: 02 May 2026


{title:Also see}

{psee}
Manual: {help [P] file}{p_end}

{psee}
Online: For questions or suggestions, please contact the
{browse "mailto:agd2010@yeah.net":first author}{p_end}
{*}