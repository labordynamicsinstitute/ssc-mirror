{smcl}
{* 09Feb2026}{...}
{viewerjumpto "Syntax" "thesis_diagram##syntax"}{...}
{viewerjumpto "Description" "thesis_diagram##description"}{...}
{viewerjumpto "Options" "thesis_diagram##options"}{...}
{viewerjumpto "Templates" "thesis_diagram##templates"}{...}
{viewerjumpto "Examples" "thesis_diagram##examples"}{...}
{viewerjumpto "Authors" "thesis_diagram##authors"}{...}
{viewerjumpto "Version" "thesis_diagram##version"}{...}

{title:Title}

{p 4 4 2}
{bf:thesis_diagram} - Generate LaTeX code for thesis framework diagrams with 5 templates

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:thesis_diagram}, {cmdab:filename(string)} [{cmdab:template(integer 1)} {cmdab:title(string)} {cmdab:author(string)} {cmdab:university(string)} {cmdab:language(string)} {cmdab:simple} {cmdab:replace}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt filename(string)}}Output LaTeX filename (required){p_end}
{synopt:{opt template(integer 1)}}Template number 1-5 (default: 1){p_end}
{synopt:{opt title(string)}}Diagram title{p_end}
{synopt:{opt author(string)}}Author name{p_end}
{synopt:{opt university(string)}}University/institution name{p_end}
{synopt:{opt language(string)}}Language: english or chinese (default: english){p_end}
{synopt:{opt simple}}Use simplified version for templates 2 and 3{p_end}
{synopt:{opt replace}}Overwrite existing file{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:thesis_diagram} generates professional LaTeX code for thesis and dissertation 
framework diagrams. It supports 5 different templates suitable for various 
research designs and methodologies. The program creates a standalone LaTeX 
file that can be compiled to produce high-quality vector graphics for 
academic publications.

{p 4 4 2}
The generated diagrams include proper figure captions and are optimized 
for clarity and visual appeal. The program supports both English and 
Chinese languages, making it suitable for international and Chinese 
academic contexts.

{marker options}{...}
{title:Options}

{phang}
{opt filename(string)} specifies the output LaTeX filename. If no 
.tex extension is provided, it will be added automatically.

{phang}
{opt template(integer 1)} selects the diagram template. Valid values are 
1 through 5:
{break}1: Classic hierarchical structure
{break}2: Flowchart diagram
{break}3: Modular design
{break}4: Three-column research framework
{break}5: Logical thinking diagram (What-Why-How framework, Chinese only)

{phang}
{opt title(string)} sets the main title of the diagram. If not specified, 
default titles are used based on the language setting.

{phang}
{opt author(string)} includes the author name in the diagram.

{phang}
{opt university(string)} includes the university/institution name in the diagram.

{phang}
{opt language(string)} sets the language for the diagram. Use "english" 
or "chinese" (or "c"/"中" for Chinese). Default is English. Note: Template 5 
is Chinese-only regardless of language setting.

{phang}
{opt simple} creates simplified versions of templates 2 and 3 without 
additional decision points or timeline elements. This option is only 
effective for templates 2 and 3.

{phang}
{opt replace} allows overwriting an existing file with the same name.

{marker templates}{...}
{title:Templates}

{title:Template 1: Classic Hierarchical Structure}
{p 4 4 2}
A traditional top-down hierarchical framework showing research chapters 
or sections in sequential order. Suitable for standard dissertation 
structures.

{title:Template 2: Flowchart Diagram}
{p 4 4 2}
A process-oriented flowchart showing research steps with optional 
decision points. Ideal for methodological research designs.

{title:Template 3: Modular Design}
{p 4 4 2}
A modular approach with four interconnected components (theory, method, 
empirical, conclusion) around a central research question. The simple 
version omits the timeline.

{title:Template 4: Three-Column Research Framework}
{p 4 4 2}
A three-column layout with Literature Review (left), Research Questions 
(center), and Research Methods (right). Optimized for clarity and 
minimal text overlap.

{title:Template 5: Logical Thinking Diagram}
{p 4 4 2}
A comprehensive "What-Why-How" research framework based on logical 
thinking processes. Includes four levels: What (connotation), Why 
(motivation), How (implementation), and Policy Recommendations. 
This template is Chinese-only.

{marker examples}{...}
{title:Examples}

{title:Template 3 Examples}

{phang}
{stata `"thesis_diagram, filename("template3_simple.tex") template(3) title("Modular Research Design") author("Jane Smith") university("Research University") language(english) simple replace"'}

{p 4 4 2}
Generates Template 3 simplified version in English with centered layout.

{phang}
{stata `"thesis_diagram, filename("模块化设计.tex") template(3) title("模块化研究设计") author("张三") university("研究大学") language(chinese) simple replace"'}

{p 4 4 2}
Generates Template 3 simplified version in Chinese with centered layout.

{title:Template 4 Examples}

{phang}
{stata `"thesis_diagram, filename("template4_research.tex") template(4) title("Three-Column Research Framework") author("John Doe") university("University of Example") language(english) replace"'}

{p 4 4 2}
Generates Template 4 in English with improved layout.

{phang}
{stata `"thesis_diagram, filename("三栏框架.tex") template(4) title("双碳战略与企业社会责任耦合研究") author("李四") university("示例大学") language(chinese) replace"'}

{p 4 4 2}
Generates Template 4 in Chinese with improved layout.

{title:Template 5 Examples}

{phang}
{stata `"thesis_diagram, filename("逻辑思路图.tex") template(5) title("双碳战略与企业社会责任耦合机制研究") author("王教授") university("科技大学") language(chinese) replace"'}

{p 4 4 2}
Generates Template 5 (Chinese-only) with improved layout.

{title:Basic Examples}

{phang}
{stata `"thesis_diagram, filename("my_thesis.tex") template(1) title("My Dissertation Framework") author("Your Name") university("Your University") replace"'}

{p 4 4 2}
Generates a basic hierarchical framework.

{phang}
{stata `"thesis_diagram, filename("quick_flowchart.tex") template(2) simple replace"'}

{p 4 4 2}
Generates a quick simplified flowchart.

{title:Compilation Commands}

{p 4 4 2}
After generating the LaTeX file, compile it using one of these methods:

{phang2}
For English documents:{break}
{cmd:pdflatex --interaction=nonstopmode filename.tex}

{phang2}
For Chinese documents:{break}
{cmd:xelatex --interaction=nonstopmode filename.tex}{break}
or{break}
{cmd:lualatex --interaction=nonstopmode filename.tex}

{title:Troubleshooting}

{p 4 4 2}
If you encounter compilation errors:

1. Ensure you have a complete LaTeX distribution installed (TeX Live, MiKTeX, or MacTeX)
2. For Chinese documents, ensure you have the necessary Chinese fonts installed
3. Use the {cmd:replace} option if you need to regenerate the file
4. Check that the generated .tex file does not contain any special characters that might cause issues

{title:Authors}

{p 4 4 2}
Wu Lianghai, Anhui University of Technology (AHUT){break}
Email: {browse "mailto:agd2010@yeah.net":agd2010@yeah.net}

{p 4 4 2}
Wu Hanyan, School of Economics and Management,{break}
Nanjing University of Aeronautics and Astronautics (NUAA){break}
Email: {browse "mailto:2325476320@qq.com":2325476320@qq.com}

{p 4 4 2}
Jin Xuening, Anhui University of Technology (AHUT){break}
Email: {browse "mailto:1418924481@qq.com":1418924481@qq.com}

{marker version}{...}
{title:Version}

{p 4 4 2}
Version 6.1.8, 09Feb2026

{space 4}{hline}

{p 4 4 2}
This program is distributed under the MIT License.{break}
For updates and bug reports, contact the authors.{break}
Compilation requires a LaTeX distribution (TeX Live, MiKTeX, etc.).{break}
Chinese language support requires XeLaTeX or LuaLaTeX.
{*}