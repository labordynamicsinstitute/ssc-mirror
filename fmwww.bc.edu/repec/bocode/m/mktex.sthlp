{smcl}
{* 30Jan2026}{...}
{hline}
help for {hi:mktex} {right:Version 2.1 | 30Jan2026}
{hline}

{title:Title}

{p 4 4 2}
{bf:mktex} - Convert Microsoft Word (.docx) documents to LaTeX (.tex) format with complete document structure and table of contents

{title:Syntax}

{p 4 4 2}
{cmd:mktex} {cmd:using} {it:filename}.docx [{cmd:,} {ul:{it:r}eplace} {ul:{it:c}ompile} {ul:{it:l}anguage(str)}]

{p 4 4 2}
where {it:filename} is a Microsoft Word document with .docx extension.

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt r}eplace}Overwrite existing .tex file{p_end}
{synopt:{opt c}ompile}Compile to PDF using XeLaTeX (includes table of contents){p_end}
{synopt:{opt l}anguage(str)}Document language (e.g., "chinese", "english"){p_end}
{synoptline}

{title:Description}

{p 4 4 2}
{cmd:mktex} converts Microsoft Word (.docx) documents to complete LaTeX (.tex) documents with table of contents support.
The command creates a full LaTeX document structure including preamble, packages, and proper document formatting.
It is optimized for both Chinese and English documents, with automatic language detection and appropriate package selection.

{p 4 4 2}
The generated LaTeX document includes a table of contents that is properly linked in the PDF output.
For Chinese documents, the command automatically includes the ctex package and sets appropriate fonts.

{p 4 4 2}
When the {cmd:compile} option is specified, the command performs two compilations with XeLaTeX to ensure
proper table of contents generation and cross-references.

{title:Options}

{phang}{opt r} ({ul:r}eplace) overwrites an existing .tex file. Without this option, 
the command exits with an error if the output file exists. Users can specify either 
{cmd:replace} or simply {cmd:r}.

{phang}{opt c} ({ul:c}ompile) compiles the generated .tex file to PDF using XeLaTeX.
Two compilations are performed to ensure proper table of contents and cross-references.
Requires a working LaTeX installation (TeX Live, MiKTeX, or MacTeX).
Users can specify either {cmd:compile} or simply {cmd:c}.

{phang}{opt l} ({ul:l}anguage) specifies the document language. For Chinese documents, 
use "chinese", "zh", or "cn". For English documents, use "english" or "en".
Default is "chinese". Users can specify either {cmd:language(chinese)} or {cmd:l(chinese)}.

{title:Requirements}

{p 4 4 2}
1. {bf:Pandoc}: Must be installed from {browse "https://pandoc.org/installing.html"}.

{p 4 4 2}
2. {bf:LaTeX Distribution} (for PDF compilation): TeX Live, MiKTeX, or MacTeX with XeLaTeX.

{title:Cross-Platform Compatibility}

{p 4 4 2}
mktex is designed to work on multiple operating systems:

{p 6 6 2}
• {bf:Windows}: Uses system PATH to locate pandoc. Ensure pandoc is in your system PATH.

{p 6 6 2}
• {bf:macOS}: For best results on macOS, define the pandoc path in your Stata profile.do file:

{p 8 8 2}{cmd:glo pandoc /opt/homebrew/bin/pandoc} (for Homebrew installation){p_end}
{p 8 8 2}{cmd:glo pandoc /usr/local/bin/pandoc} (for MacPorts installation){p_end}

{p 6 6 2}
• {bf:Linux}: Uses system PATH. Ensure pandoc is installed and accessible.

{p 4 4 2}
The program automatically detects the operating system and adjusts its behavior accordingly.

{title:Examples}

{p 4 4 2}
Basic conversion of a Chinese document (creates .tex with table of contents):

{phang2}{cmd:. mktex using "report.docx"}{p_end}

{p 4 4 2}
Convert and compile to PDF, overwriting existing files (single-letter options):

{phang2}{cmd:. mktex using "thesis.docx", r c}{p_end}

{p 4 4 2}
Convert a Chinese document with explicit language specification:

{phang2}{cmd:. mktex using "test.docx", compile l(chinese)}{p_end}

{p 4 4 2}
Convert an English document with minimal options:

{phang2}{cmd:. mktex using "paper.docx", c l(english)}{p_end}

{p 4 4 2}
Using all single-letter abbreviations:

{phang2}{cmd:. mktex using "document.docx", r c l(english)}{p_end}

{title:Output Files}

{p 4 4 2}
The command produces the following output files:

{p 6 6 2}
1. {bf:.tex file}: A complete LaTeX document with proper document structure including:
   - Appropriate document class (article with ctex for Chinese, article for English)
   - Required packages (geometry, hyperref, booktabs, graphicx, amsmath, amssymb)
   - Table of contents generation command
   - Full document preamble and body structure
   - Proper hyperlink configuration for PDF navigation

{p 6 6 2}
2. {bf:.pdf file} (with {cmd:compile} option): A compiled PDF document with:
   - Proper table of contents with clickable links
   - Correct font rendering for the specified language
   - Proper page layout and margins
   - Hyperlinked cross-references

{title:Technical Details}

{p 4 4 2}
The conversion process consists of five steps:

{p 6 6 2}
1. {bf:File Validation}: Checks that the input file is a .docx file and exists.

{p 6 6 2}
2. {bf:Pandoc Conversion}: Uses pandoc to convert the .docx file to basic LaTeX format.
   On macOS, the program checks for a global pandoc path defined in profile.do.

{p 6 6 2}
3. {bf:Complete Document Creation}: Builds a full LaTeX document structure including:
   - Document class selection based on language
   - Package imports for formatting and hyperlinks
   - Table of contents setup
   - Integration of converted content

{p 6 6 2}
4. {bf:Content Integration}: Copies the converted content into the document body
   while preserving all formatting and structure.

{p 6 6 2}
5. {bf:PDF Compilation} (with {cmd:compile} option): Compiles the LaTeX file
   to PDF using XeLaTeX with two passes for proper table of contents.

{title:Chinese Quotation Marks Processing}

{p 4 4 2}
Important technical note regarding Chinese quotation marks in the generated LaTeX files:

{p 6 6 2}
• The current version (2.1) has a known limitation: Chinese double quotation marks and their surrounding text may be lost during the conversion process.

{p 6 6 2}
• Users need to manually edit the generated .tex file to restore any missing Chinese quotation marks and the corresponding text.

{p 6 6 2}
• To properly typeset Chinese left double quotation marks in LaTeX, use two consecutive backticks (``) in the .tex file.

{p 6 6 2}
• For Chinese right double quotation marks, use two consecutive apostrophes ('').

{p 6 6 2}
• Example correction in LaTeX source code:
   {it:Original missing text} → {it:He said ``This is a Chinese example.''}

{p 6 6 2}
• Always verify the converted content against the original Word document, especially sections containing Chinese punctuation.

{p 6 6 2}
• This limitation is due to character encoding issues in the pandoc conversion pipeline and will be addressed in future versions.

{title:Chinese Text Processing}

{p 4 4 2}
For Chinese documents, the command automatically:

{p 6 6 2}
• Uses ctex package for full Chinese language support

{p 6 6 2}
• Sets appropriate Chinese fonts for proper character rendering

{p 6 6 2}
• Handles Chinese punctuation and special characters

{p 6 6 2}
• Ensures proper line breaking and paragraph formatting

{title:Table of Contents}

{p 4 4 2}
The generated LaTeX document includes a functional table of contents:

{p 6 6 2}
• Automatically generated from document headings

{p 6 6 2}
• Properly formatted with LaTeX's native TOC system

{p 6 6 2}
• Clickable in PDF output when compiled with hyperref package

{p 6 6 2}
• Updated automatically during compilation process

{title:Acknowledgments}

{p 4 4 2}
The authors gratefully acknowledge the guidance and support of {bf:Christopher F. Baum}.
His valuable advice on cross-platform compatibility and macOS-specific implementations
significantly improved the program's functionality across different operating systems.
His contributions to the Stata community and willingness to share knowledge have been instrumental
in enhancing the robustness of this tool.

{title:Authors}

{p 4 4 2}
{bf:Wu Lianghai} and {bf:Chen Liwen}

{p 8 8 2}Anhui University of Technology (AHUT), Ma'anshan, China{p_end}
{p 8 8 2}Email: {stata `"copy "agd2010@yeah.net""':agd2010@yeah.net}, {stata `"copy "2184844526@qq.com""':2184844526@qq.com}

{p 4 4 2}
{bf:Wu Hanyan}

{p 8 8 2}Nanjing University of Aeronautics and Astronautics (NUAA), Nanjing, China{p_end}
{p 8 8 2}Email: {stata `"copy "2325476320@qq.com""':2325476320@qq.com}

{p 4 4 2}
{bf:Wu Xinzhuo}

{p 8 8 2}University of Bristol (UB), London, UK{p_end}
{p 8 8 2}Email: {stata `"copy "2957833979@qq.com""':2957833979@qq.com}

{p 4 4 2}
{bf:Ma Defang}

{p 8 8 2}Capital Normal University (CNU), Beijing, China{p_end}
{p 8 8 2}Email: {stata `"copy "6346@cnu.edu.cn""':6346@cnu.edu.cn}

{title:See Also}

{p 4 4 2}
{help art2tex} - Convert academic articles to LaTeX format

{p 4 4 2}
{help case2tex} - Convert case studies to LaTeX format

{p 4 4 2}
{help maketex} - Creates a TeXable file from the using file

{title:Version History}

{p 4 4 2}
2.1 (30Jan2026): Added cross-platform compatibility with macOS support; 
     users can define pandoc path in profile.do on macOS; added acknowledgment to Christopher F. Baum.

{p 4 4 2}
2.0 (28Jan2026): Added complete LaTeX document structure with table of contents;
     all options now support single-letter abbreviations; updated documentation.

{p 4 4 2}
1.0 (28Jan2026): Initial release as mktex, basic Chinese character handling.

{hline}
{p 4 4 2}
Type {cmd:help mktex} to display this help file again.
{hline}
