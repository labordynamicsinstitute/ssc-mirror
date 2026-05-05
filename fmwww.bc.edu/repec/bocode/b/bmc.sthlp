{smcl}
{* *! version 2.7 02May2026}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "help" "help help"}{...}
{viewerjumpto "Syntax" "bmc##syntax"}{...}
{viewerjumpto "Description" "bmc##description"}{...}
{viewerjumpto "Options" "bmc##options"}{...}
{viewerjumpto "Examples" "bmc##examples"}{...}
{viewerjumpto "Stored results" "bmc##results"}{...}
{viewerjumpto "References" "bmc##references"}{...}
{viewerjumpto "Authors" "bmc##authors"}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:bmc} {hline 2}}Automatically Generate Chapter Configuration Text Files for Academic Monograph{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:bmc}
[{cmd:,} {it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt chapter(#)}}Specify chapter number (must be a positive integer){p_end}
{synopt:{opt title(string)}}Specify chapter title{p_end}
{synopt:{opt language(string)}}Specify configuration file language{p_end}
{synopt:{opt logo(string)}}Specify institution logo filename (without extension){p_end}
{synopt:{opt monograph(string)}}Specify academic monograph title{p_end}

{syntab:Length Control}
{synopt:{opt length(#)}}Specify chapter text length (word count){p_end}
{synopt:{opt caselength(#)}}Specify mini case text length (word count){p_end}
{synopt:{opt slide(#)}}Specify number of slides to generate{p_end}

{syntab:Output}
{synopt:{opt save(string)}}Specify save path for configuration file{p_end}
{synopt:{opt date(string)}}Specify date used in the file{p_end}
{synopt:{opt author(string)}}Specify author name{p_end}
{synopt:{opt replace}}Overwrite existing file with the same name{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:chapter()} option must be specified. If {cmd:title()} is not provided, the program will prompt the user for input.
{p_end}{p 4 6 2}
{cmd:language()} supports "Chinese", "中文", "English", "英文". {cmd:language()} can be abbreviated as {cmd:lang()}.
{p_end}{p 4 6 2}
{cmd:logo()} specifies the base name of the logo file (e.g., "ahut" for ahut.jpg).
{p_end}{p 4 6 2}
{cmd:monograph()} can be abbreviated as {cmd:mono()} or {cmd:m()}.
{p_end}{p 4 6 2}
{cmd:caselength()} can be abbreviated as {cmd:case()}.
{p_end}{p 4 6 2}
{cmd:slide()} can be abbreviated as {cmd:slides()} or {cmd:s()}.
{p_end}{p 4 6 2}
{cmd:replace} can be abbreviated as {cmd:r}.


{marker description}{...}
{title:Description}

{pstd}
The {cmd:bmc} command is used to automatically generate configuration text files for each chapter of academic monographs. Based on user-input chapter information, the command generates standardized {cmd:bmc#.txt} files containing detailed instructions for seven tasks including chapter content development, LaTeX document generation, teaching plan creation, slide design, and case study writing.

{pstd}
The generated configuration files follow a standard format and can be used for automated document generation workflows. This is particularly useful for academic writing projects that require batch processing of multiple chapters. The version 2.7 adds a {cmd:monograph()} option to customize the academic monograph title, allowing users to generate configuration files for different monograph projects.

{pstd}
Version history:
{break}v2.7 (02May2026): Added {cmd:monograph()} option for monograph title customization
{break}v2.6 (18Jan2026): Added {cmd:slide()} option with default value 10
{break}v2.5 (15Jan2026): Added {cmd:caselength()} option with default value 1000
{break}v2.0 (10Jan2026): Full bilingual support with language() option
{break}v1.0 (05Jan2026): Initial release


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt chapter(#)} specifies the chapter number for which to generate the configuration file. Must be a positive integer, e.g., 8 for Chapter 8.

{phang}
{opt title(string)} specifies the chapter title. If this option is not provided, the program will interactively prompt the user for input. The title should concisely reflect the chapter content.

{phang}
{opt language(string)} specifies the output language for the configuration file. Valid values are: "Chinese", "中文" (default), "English", "英文". When English is selected, all prompt text in the configuration file will be in English.

{phang}
{opt logo(string)} specifies the base name of the institution logo file (without extension). For example, "ahut" for ahut.jpg, ahut.pdf, or ahut.png files. The default value is "ahut". This logo will be referenced in LaTeX documents generated from the configuration.

{phang}
{opt monograph(string)} specifies the title of the academic monograph. This allows users to generate configuration files for different monograph projects. The default value is "智能会计：理论、工具与应用" ({it:Intelligent Accounting: Theory, Tools and Applications}). This option can be abbreviated as {opt mono()} or {opt m()}.

{dlgtab:Length Control}

{phang}
{opt length(#)} specifies the total length (word count) of the chapter text. Must be a positive integer, default value is 8000. This value will appear in the configuration file's length control instructions.

{phang}
{opt caselength(#)} specifies the total length (word count) of the mini case study text. Must be a positive integer, default value is 1000. This value will appear in item 6 of the configuration file. This option can be abbreviated as {opt case()}.

{phang}
{opt slide(#)} specifies the number of slides to generate for the presentation. Must be a positive integer, default value is 10. This value determines the slide count specified in item 5 of the configuration file. This option can be abbreviated as {opt slides()} or {opt s()}.

{dlgtab:Output}

{phang}
{opt save(string)} specifies the save path for the generated {cmd:bmc#.txt} file. Supports Windows path format. If the path does not end with a backslash, the program will automatically add one.

{phang}
{opt date(string)} specifies the date information to use in the configuration file. The recommended format is "DDMonYYYY" (e.g., 18Jan2026). If not specified, defaults to "18Jan2026".

{phang}
{opt author(string)} specifies the author name. If not specified, defaults to "Prof. Wu Lianghai". This information will appear in the author field of the configuration file.

{phang}
{opt replace} overwrites an existing file with the same name. If the target file already exists and this option is not specified, the program will report an error and terminate. This option can be abbreviated as {opt r}.


{marker examples}{...}
{title:Examples}

{pstd}Basic example with default monograph title{p_end}

{phang2}{cmd:. bmc, chapter(8) title("Intelligent Financial Reporting and Analysis")}{p_end}

{pstd}Specify custom monograph title{p_end}

{phang2}{cmd:. bmc, chapter(9) title("Application of RPA in Financial Process Automation") monograph("Advanced Accounting Information Systems") language(English)}{p_end}

{pstd}Using mono() abbreviation{p_end}

{phang2}{cmd:. bmc, chapter(10) title("Artificial Intelligence in Auditing") mono("Digital Transformation in Accounting")}{p_end}

{pstd}Complete example with monograph customization{p_end}

{phang2}{cmd:. bmc, chapter(11) title("Blockchain and Accounting Information Systems") monograph("Emerging Technologies in Accounting") length(8500) caselength(2000) slide(12) logo(mit) author("Prof. John Smith") language(English) replace}{p_end}

{pstd}Different monographs for different projects{p_end}

{phang2}{cmd:. bmc, chapter(1) title("Introduction") monograph("Financial Data Analytics") length(5000) slide(8)}{p_end}
{phang2}{cmd:. bmc, chapter(2) title("Data Preprocessing") monograph("Financial Data Analytics") length(6000) slide(12)}{p_end}
{phang2}{cmd:. bmc, chapter(1) title("Overview") monograph("RPA in Finance and Accounting") length(4500) slide(10)}{p_end}

{pstd}Interactive title input with custom monograph{p_end}

{phang2}{cmd:. bmc, chapter(14) save("D:\Smart Accounting\Project Files") monograph("智能财务分析与决策") language(Chinese) slide(25)}{p_end}
{pmore2}The program will prompt: {it:请输入第14章标题（例如：智能财务报告与分析）：}{p_end}

{pstd}Complete parameter example with custom monograph{p_end}

{phang2}{cmd:. bmc, chapter(15) title("Ethical Considerations in AI Accounting") monograph("AI Ethics in Accounting and Finance") save("F:\Academic Monograph\Smart Accounting\Chapter Configurations") date("30Jan2026") length(9500) caselength(3000) slide(15) author("Prof. Wang Wu") language(Chinese) logo(fudan) replace}{p_end}

{pstd}Using m() abbreviation for monograph{p_end}

{phang2}{cmd:. bmc, chapter(16) title("Introduction to Smart Accounting") m("智能会计导论") slide(8)}{p_end}
{phang2}{cmd:. bmc, chapter(17) title("Advanced Data Mining Techniques") m("大数据与会计分析") slide(25)}{p_end}
{phang2}{cmd:. bmc, chapter(18) title("Case Study: Implementation of RPA") m("财务机器人应用案例") slide(12)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:bmc} does not store results in {cmd:r()}. All output is directly written to the specified text file, and generation information is displayed in the Stata results window.


{marker references}{...}
{title:References}

{pstd}
Wu, Lianghai. 2026. {it:Intelligent Accounting: Theory, Tools and Applications}. Beijing: Higher Education Press.

{pstd}
Intelligent Accounting Research Team. 2026. "Transformation and Development of Accounting Education in the Intelligent Era." {it:Accounting Research} 42(1): 15-28.

{pstd}
Smith, J., & Wu, L. 2026. "Intelligent Process Automation in Accounting: A Case Study of RPA Implementation." {it:Journal of Accounting Information Systems} 18(3): 45-62.


{marker authors}{...}
{title:Authors}

{pstd}
{browse "mailto:agd2010@yeah.net":Wu Lianghai} (First Author){break}
School of Business, Anhui University of Technology (AHUT){break}
Ma'anshan, China

{pstd}
{browse "mailto:2325476320@qq.com":Wu Hanyan} (Second Author){break}
School of Economics and Management, Nanjing University of Aeronautics and Astronautics (NUAA){break}
Nanjing, China

{pstd}
{browse "mailto:huff470@163.com":Hu Fangfang} (Third Author){break}
School of Finance and Economics, Wanjiang University of Technology (WJUT){break}
Ma'anshan, China

{pstd}
Technical Support: Intelligent Accounting Laboratory, Anhui University of Technology{break}
Last Updated: 02 May 2026


{title:Also see}

{psee}
Manual: {help [P] file}{p_end}

{psee}
Online: For questions or suggestions, please contact the {browse "mailto:agd2010@yeah.net":first author}{p_end}
{*}