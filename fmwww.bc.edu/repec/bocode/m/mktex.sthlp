{smcl}
{* 31Jan2026}{...}
{hline}
help for {hi:mktex} {right:Version 2.9 | 31Jan2026}
{hline}

{title:Title}

{p 4 4 2}
{bf:mktex} - Convert Microsoft Word (.docx) documents to LaTeX (.tex) format with full document structure and optional PDF compilation

{title:Syntax}

{p 8 12 2}
{cmd:mktex} {cmd:using} {it:filename}.docx [{cmd:,} {opt replace} {opt compile} {opt language(str)} {opt noctex} {opt notoc} {opt simple} {opt r} {opt c}]

{p 8 12 2}
{cmd:mktex} {cmd:,} {opt check}

{p 4 4 2}
where {it:filename} is a Microsoft Word document with .docx extension.

{synoptset 24 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt replace}}overwrite existing output files{p_end}
{synopt:{opt compile}}compile the generated LaTeX file to PDF{p_end}
{synopt:{opt language(str)}}set document language (e.g., "chinese", "english"){p_end}
{synopt:{opt noctex}}disable automatic ctex package for Chinese documents{p_end}
{synopt:{opt notoc}}disable table of contents generation{p_end}
{synopt:{opt simple}}create minimal LaTeX document without full structure{p_end}
{synopt:{opt r}}short for {opt replace}{p_end}
{synopt:{opt c}}short for {opt compile}{p_end}
{synoptline}

{title:Description}

{p 4 4 2}
{cmd:mktex} converts Microsoft Word (.docx) documents to LaTeX (.tex) documents. 
It generates complete LaTeX documents with proper preamble, document structure, 
and optional table of contents. The command supports both full document generation 
and minimal ("simple") output for embedding in existing documents.

{p 4 4 2}
When the {cmd:compile} option is specified, the command compiles the generated 
LaTeX file to PDF using available LaTeX engines (pdflatex, xelatex, lualatex, or latex).

{p 4 4 2}
The {cmd:check} option verifies the installation of pandoc and LaTeX, providing 
system-specific guidance for setup.

{title:Options}

{phang}{opt replace} (or {opt r}) overwrites existing output files. Without this option, 
the command exits with an error if the output .tex file already exists.

{phang}{opt compile} (or {opt c}) compiles the generated LaTeX file to PDF. 
The command automatically detects available LaTeX engines and performs one or two 
compilations (for proper table of contents when enabled).

{phang}{opt language(str)} specifies the document language. For Chinese documents, 
use "chinese", "zh", or "cn". For English documents, use "english" or "en". 
Default is "chinese" unless {opt noctex} is specified.

{phang}{opt noctex} disables automatic inclusion of the ctex package for Chinese documents. 
Use this option when you want to handle Chinese typesetting manually or when using 
alternative LaTeX packages.

{phang}{opt notoc} disables table of contents generation in full document mode.

{phang}{opt simple} creates a minimal LaTeX document containing only the converted content 
with basic preamble. This is useful for embedding content in existing LaTeX documents 
or when experiencing compilation issues with the full document structure.

{phang}{opt check} verifies the installation of pandoc and LaTeX, displays system 
information, and provides troubleshooting guidance. This option does not require 
a {cmd:using} specification.

{title:Requirements}

{p 4 4 2}
1. {bf:Pandoc}: Must be installed from {browse "https://pandoc.org/installing.html"}.

{p 4 4 2}
2. {bf:LaTeX Distribution} (for PDF compilation): TeX Live, MiKTeX, or MacTeX.

{title:Cross-Platform Compatibility}

{p 4 4 2}
mktex is designed to work on multiple operating systems:

{p 6 6 2}
• {bf:Windows}: Uses system PATH to locate pandoc and LaTeX.

{p 6 6 2}
• {bf:macOS}: Automatically checks for pandoc. For custom installations, you can 
define the pandoc path in your Stata profile.do file: {cmd:glo pandoc /path/to/pandoc}

{p 6 6 2}
• {bf:Linux}: Uses system PATH for both pandoc and LaTeX.

{p 4 4 2}
The program includes a comprehensive installation checker ({cmd:mktex, check}) 
that provides OS-specific troubleshooting advice.

{title:Examples}

{p 4 4 2}
Basic conversion with default settings (Chinese document):

{p 8 12 2}{cmd:. mktex using "report.docx"}{p_end}

{p 4 4 2}
Convert, compile to PDF, and overwrite existing files:

{p 8 12 2}{cmd:. mktex using "thesis.docx", replace compile}{p_end}
{p 8 12 2}{cmd:. mktex using "thesis.docx", r c} {it:(short form)}{p_end}

{p 4 4 2}
Create a simple LaTeX document without full structure:

{p 8 12 2}{cmd:. mktex using "content.docx", simple}{p_end}

{p 4 4 2}
Convert an English document without table of contents:

{p 8 12 2}{cmd:. mktex using "paper.docx", language(english) notoc}{p_end}

{p 4 4 2}
Check installation status:

{p 8 12 2}{cmd:. mktex, check}{p_end}

{p 4 4 2}
Convert a Chinese document without automatic ctex package:

{p 8 12 2}{cmd:. mktex using "document.docx", noctex}{p_end}

{title:Output Files}

{p 4 4 2}
The command can produce the following output files:

{p 6 6 2}
1. {bf:.tex file}: A LaTeX document. In full mode (default), this includes complete 
document structure with preamble, packages, title, optional table of contents, 
and content. In simple mode, it includes minimal preamble and content only.

{p 6 6 2}
2. {bf:.pdf file} (with {cmd:compile} option): A compiled PDF document. When table 
of contents is enabled, two compilation passes are performed for proper TOC generation.

{p 6 6 2}
3. {bf:Log files}: Various LaTeX auxiliary files (.aux, .log, .toc, etc.) are 
automatically cleaned up after successful compilation.

{title:Technical Details}

{p 4 4 2}
The conversion process consists of multiple steps:

{p 6 6 2}
1. {bf:File Validation}: Checks file existence, extension (.docx), and output file conflicts.
   Handles Unicode filenames by creating temporary ASCII-named copies.

{p 6 6 2}
2. {bf:Pandoc Conversion}: Uses pandoc to convert .docx to basic LaTeX format with 
appropriate command-line options.

{p 6 6 2}
3. {bf:Content Processing}: Cleans the pandoc output, removes duplicate document 
structure commands, and handles special characters and quotation marks.

{p 6 6 2}
4. {bf:Document Creation}: Builds either a full LaTeX document (with customizable 
preamble, packages, title, optional TOC) or a simple document (minimal structure).

{p 6 6 2}
5. {bf:PDF Compilation} (optional): Automatically detects available LaTeX engine 
(pdflatex, xelatex, lualatex, or latex), performs multiple passes when TOC is enabled, 
and cleans auxiliary files.

{title:Chinese Language Support}

{p 4 4 2}
By default, mktex assumes Chinese documents and includes the ctex package with UTF8 encoding:

{p 6 6 2}
• Automatic ctex package inclusion can be disabled with {opt noctex}

{p 6 6 2}
• Language detection can be overridden with {opt language()} option

{p 6 6 2}
• The command handles character encoding issues and quotation mark processing

{title:Error Handling}

{p 4 4 2}
The program includes comprehensive error handling:

{p 6 6 2}
• File validation with descriptive error messages

{p 6 6 2}
• Pandoc installation checking with OS-specific guidance

{p 6 6 2}
• LaTeX compilation error reporting

{p 6 6 2}
• Temporary file cleanup to prevent file accumulation

{p 6 6 2}
• Unicode filename handling with automatic ASCII conversion

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

{p 8 8 2}University of Bristol (UB), UK{p_end}
{p 8 8 2}Email: {stata `"copy "2957833979@qq.com""':2957833979@qq.com}

{p 4 4 2}
{bf:Ma Defang}

{p 8 8 2}Capital Normal University (CNU), Beijing, China{p_end}
{p 8 8 2}Email: {stata `"copy "6346@cnu.edu.cn""':6346@cnu.edu.cn}

{title:Version History}

{p 4 4 2}
2.9 (31Jan2026): Fixed display command syntax issues; improved Unicode filename handling; 
enhanced error messages; fixed variable name inconsistencies; improved cross-platform compatibility.

{p 4 4 2}
2.5 (31Jan2026): Added {opt simple} mode for minimal LaTeX output; improved error handling; 
enhanced LaTeX engine detection; added {opt noctex} and {opt notoc} options; updated 
installation checker with better diagnostics; fixed macOS compatibility issues.

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