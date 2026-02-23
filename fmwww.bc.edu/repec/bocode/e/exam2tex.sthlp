{smcl}
{* 20Feb2026}
{* exam2tex - Generate Standardized LaTeX Exam Templates}
{* Authors: Wu Lianghai, Hu Fangfang, Chen Liwen, Yang Lu, Wu Hanyan}

{title:exam2tex -- Generate Standardized LaTeX Exam Templates}
{hline}

{p 4 4 2}
{cmd:exam2tex} generates a professional LaTeX exam template that can be
compiled directly to PDF. It creates a complete framework with proper
formatting, bilingual support, and customizable sections for efficient
exam creation. The program includes automatic LaTeX special character
escaping, one-click compilation options, and ensures proper question
numbering alignment across all sections.
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 4 2}
{cmd:exam2tex} [{it:filename}] [, 
    {it:subject}({it:string}) 
    {it:grade}({it:string}) 
    {it:date}({it:string}) 
    {it:duration}({it:string}) 
    {it:totalpoints}({it:string})
    {it:teacher}({it:string}) 
    {it:language}({it:string})
    {it:header}({it:string}) 
    {it:questionstart}({it:#})
    {it:sections}({it:numlist}) 
    {it:replace} 
    {it:texengine}({it:string})
    {it:compile}]
{p_end}

{marker options}{...}
{title:Options}

{synoptset 20}{...}
{synopthdr}
{synoptline}
{synopt:{opt subject(string)}}Exam subject (e.g., "Mathematics", "物理学"){p_end}
{synopt:{opt grade(string)}}Grade/Class information (e.g., "Grade 10", "高一(3)班"){p_end}
{synopt:{opt date(string)}}Exam date (default: \today){p_end}
{synopt:{opt duration(string)}}Exam duration (default: "120 minutes"){p_end}
{synopt:{opt totalpoints(string)}}Total points possible (default: "100"){p_end}
{synopt:{opt teacher(string)}}Teacher/Instructor name{p_end}
{synopt:{opt language(string)}}Language selection: en (English, default) or cn (Chinese){p_end}
{synopt:{opt header(string)}}Custom LaTeX code to insert in preamble{p_end}
{synopt:{opt questionstart(#)}}Starting question number (default: 1){p_end}
{synopt:{opt sections(numlist)}}Number of questions per section. Example: sections(5 4 3){p_end}
{synopt:{opt replace}}Replace existing output file{p_end}
{synopt:{opt texengine(string)}}LaTeX engine: pdflatex (default), xelatex, or lualatex{p_end}
{synopt:{opt compile}}Automatically compile the generated .tex file to PDF (runs twice for correct references){p_end}
{synoptline}

{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:exam2tex} creates a complete, professionally formatted LaTeX exam
template that follows academic standards. Version 1.0.1 includes a critical
fix for question numbering alignment in English papers, ensuring all
question numbers are consistently left-aligned throughout the document.
The generated file includes:
{p_end}

{marker features}{...}
{title:Key Features}

{p 4 4 2}
{bf:Professional Document Structure}
{p_end}
{phang2}
    - Complete LaTeX preamble with essential packages
    - Proper page geometry and margin settings
    - Customizable header/footer with exam information
    - Automatic question numbering and sectioning
    - Optimized headheight (14.5pt) to eliminate LaTeX warnings
{p_end}

{p 4 4 2}
{bf:Perfect Question Numbering Alignment}
{p_end}
{phang2}
    - All question numbers are consistently left-aligned using \noindent
    - No indentation differences between first and subsequent questions
    - Works identically for both English and Chinese documents
    - Professional appearance meeting academic standards
{p_end}

{p 4 4 2}
{bf:Bilingual Support}
{p_end}
{phang2}
    - Full support for both English (language(en)) and Chinese (language(cn))
    - Automatic loading of appropriate language packages
    - Localized instructions and section headings
    - Compatible with xelatex for Chinese documents
{p_end}

{p 4 4 2}
{bf:Flexible Exam Design}
{p_end}
{phang2}
    - Multiple sections with customizable question counts
    - Adjustable starting question number
    - Custom LaTeX code injection via header() option
    - Support for various LaTeX engines
{p_end}

{p 4 4 2}
{bf:LaTeX Safety Features}
{p_end}
{phang2}
    - Automatic escaping of underscores and other special characters
    - Prevents common LaTeX compilation errors
    - Properly formatted placeholder underlines
{p_end}

{p 4 4 2}
{bf:One-Click Compilation}
{p_end}
{phang2}
    - New {cmd:compile} option for automatic PDF generation
    - Runs LaTeX engine twice to resolve all references
    - Displays compilation progress and results
{p_end}

{marker examples}{...}
{title:Examples}

{p 4 4 2}
{bf:Basic English Exam}
{p_end}
{p 8 8 2}
    . exam2tex midterm, subject("Calculus I") grade("University Year 1")
{p_end}
{p 8 8 2}
    . exam2tex midterm, subject("Calculus I") grade("University Year 1") 
        date("2026-03-01") duration("3 hours") totalpoints("120")
{p_end}

{p 4 4 2}
{bf:English Exam with One-Click Compilation}
{p_end}
{p 8 8 2}
    . exam2tex midterm, subject("Calculus I") grade("University Year 1") 
        date("2026-03-01") duration("3 hours") /// totalpoints("120") compile
{p_end}

{p 4 4 2}
{bf:Chinese Language Exam (using XeLaTeX)}
{p_end}
{p 8 8 2}
    . exam2tex final, subject("现代汉语") grade("二年级") 
        language(cn) texengine(xelatex) sections(4 5 4) compile
{p_end}

{p 4 4 2}
{bf:Multi-Section Exam with Custom Header}
{p_end}
{p 8 8 2}
    . exam2tex physics_final, subject("Physics 101") grade("Freshman") 
        sections(5 3 4 2) questionstart(1) ///
        header("\newcommand{\bonuspoints}{10}") replace compile
{p_end}

{p 4 4 2}
{bf:Exam with Custom Teacher Name}
{p_end}
{p 8 8 2}
    . exam2tex final_exam, subject("Economics") grade("Sophomore") 
        teacher("Prof. Smith") date("2026-05-15") compile
{p_end}

{p 4 4 2}
{bf:Testing Question Numbering Alignment}
{p_end}
{p 8 8 2}
    . exam2tex alignment_test, subject("Test") grade("Demo") 
        sections(3 4) compile
{p_end}
{p 8 8 2}
    {bf:Note:} All question numbers will be perfectly aligned at the left margin,
    both in Section A (questions 1-3) and Section B (questions 4-7).
{p_end}

{marker compilation}{...}
{title:Compiling to PDF}

{p 4 4 2}
After generating the .tex file, you can compile it to PDF using your preferred
LaTeX engine. The program displays the appropriate command:
{p_end}
{p 8 8 2}
    . pdflatex midterm.tex    (for English documents)
{p_end}
{p 8 8 2}
    . xelatex chinese_exam.tex (for Chinese documents)
{p_end}
{p 4 4 2}
For documents with cross-references, you need to run the compilation command
twice to resolve all references properly. Use the {cmd:compile} option to
automatically handle this.
{p_end}

{marker notes}{...}
{title:Technical Notes}

{p 4 4 2}
{bf:Question Numbering Implementation}
{p_end}
{phang2}
    - Version 1.0.1 uses \noindent before each question number
    - This ensures all numbers start at the left margin
    - Fix applies to both sectioned and non-sectioned exams
    - Maintains consistent appearance across English and Chinese documents
{p_end}

{p 4 4 2}
{bf:LaTeX Special Characters}
{p_end}
{phang2}
    - Underscores (_) in any user input are automatically escaped as {\_}
    - This prevents the common "Missing $" error in LaTeX compilation
    - Placeholder underlines are properly formatted using {\_\_\_\_}
{p_end}

{p 4 4 2}
{bf:Automatic Compilation}
{p_end}
{phang2}
    - The {cmd:compile} option runs the LaTeX engine twice
    - First run: Generates initial PDF and auxiliary files
    - Second run: Resolves cross-references and page numbers
    - PDF is saved in the same directory as the .tex file
{p_end}

{p 4 4 2}
{bf:Warning Elimination}
{p_end}
{phang2}
    - Headheight is set to 14.5pt to eliminate fancyhdr warnings
    - LastPage references are properly resolved with two compilations
    - No LaTeX errors should appear during compilation
{p_end}

{marker requirements}{...}
{title:Requirements}

{p 4 4 2}
A working LaTeX distribution must be installed on your system:
{p_end}
{phang2}
    - Windows: MiKTeX ({browse "https://miktex.org":https://miktex.org}) or TeX Live
    - macOS: MacTeX ({browse "https://tug.org/mactex/":https://tug.org/mactex/})
    - Linux: TeX Live (via package manager)
{p_end}

{p 4 4 2}
For Chinese documents, ensure your LaTeX distribution includes:
{p_end}
{phang2}
    - ctex package (for xelatex compilation)
    - Appropriate Chinese fonts
{p_end}

{marker authors}{...}
{title:Authors}

{pstd}
{bf:Wu Lianghai}
{break}School of Business, Anhui University of Technology (AHUT)
{break}Ma'anshan, Anhui, China
{break}{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}
{p_end}

{pstd}
{bf:Hu Fangfang}
{break}Wanjiang University of Technology (WJUT)
{break}Ma'anshan, Anhui, China
{break}{browse "mailto:huff470@163.com":huff470@163.com}
{p_end}

{pstd}
{bf:Chen Liwen}
{break}School of Business, Anhui University of Technology (AHUT)
{break}Ma'anshan, Anhui, China
{break}{browse "mailto:2184844526@qq.com":2184844526@qq.com}
{p_end}

{pstd}
{bf:Yang Lu}
{break}Rugao City Finance Bureau, Jiangsu Province
{break}Jiangsu, China
{break}{browse "mailto:1026835594@qq.com":1026835594@qq.com}
{p_end}

{pstd}
{bf:Wu Hanyan}
{break}School of Economics and Management
{break}Nanjing University of Aeronautics and Astronautics (NUAA)
{break}Nanjing, Jiangsu, China
{break}{browse "mailto:2325476320@qq.com":2325476320@qq.com}
{p_end}

{marker references}{...}
{title:References}

{phang}
LaTeX Project. (2026). {it:LaTeX - A document preparation system}.
    {browse "https://www.latex-project.org/":https://www.latex-project.org/}
{p_end}

{phang}
CTAN. (2026). {it:The ctex package}.
    {browse "https://ctan.org/pkg/ctex":https://ctan.org/pkg/ctex}
{p_end}

{phang}
StataCorp. (2025). {it:Stata 18 User's Guide}. College Station, TX: Stata Press.
{p_end}

{marker also}{...}
{title:Also See}

{phang}
Online: {browse "https://www.overleaf.com":Overleaf} - Online LaTeX Editor
{p_end}

{phang}
Stata commands: {help file}, {help filefilter}, {help shell}
{p_end}

{marker version}{...}
{title:Version}

{p 4 4 2}
Version 1.0.1 - 20 February 2026
{p_end}

{p 4 4 2}
{bf:Update History}
{p_end}
{phang2}
    v1.0.1 (20Feb2026): Fixed question numbering alignment issue in English
    papers. All question numbers now consistently left-aligned using \noindent.
    This ensures professional appearance matching academic standards.
{p_end}
{phang2}
    v1.0.0 (15Feb2026): Initial release with bilingual support,
    automatic special character escaping, and one-click compilation
{p_end}