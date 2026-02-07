{smcl}
{* 05Feb2026}{...}
{hline}
help for {hi:mktex} {right:Version 3.0 | 05Feb2026}
{hline}

{title:Title}

{p 4 4 2}
{bf:mktex} - Convert Microsoft Word (.docx) documents to LaTeX (.tex) 
format with full document structure and optional PDF compilation

{marker limitations}{...}
{title:Important Limitations}

{p 4 4 2}
{bf:mktex} is optimized for converting plain text Word documents. 
Documents containing complex elements may require additional manual 
adjustment or alternative conversion methods:

{p 6 6 2}
• {bf:Tables}: Complex table formatting may not convert correctly{p_end}
{p 6 6 2}
• {bf:Mathematical formulas}: Use direct pandoc conversion for better results{p_end}
{p 6 6 2}
• {bf:Underlined text}: Underline formatting (\ul{}) is removed for compatibility{p_end}
{p 6 6 2}
• {bf:Complex formatting}: Advanced Word features may be simplified{p_end}

{p 4 4 2}
For documents with tables, mathematical formulas, or complex formatting, 
we recommend using pandoc directly:

{p 8 8 2}{bf:For English documents:}{p_end}
{p 10 10 2}{cmd:shell pandoc filename.docx -o filename.tex --standalone}{p_end}

{p 8 8 2}{bf:For Chinese documents:}{p_end}
{p 10 10 2}{cmd:shell pandoc filename.docx -o filename.tex --standalone}{p_end}
{p 10 10 2}{cmd:    --pdf-engine=xelatex -V lang=chinese}{p_end}
{p 10 10 2}{cmd:    -V documentclass=ctexart -M mainfont="Microsoft YaHei"}{p_end}

{p 4 4 2}
Optional Chinese fonts include: "Microsoft YaHei", "SimHei", "SimSun".

{title:Syntax}

{p 8 12 2}
{cmd:mktex} {cmd:using} {it:filename}.docx [{cmd:,} {opt replace} 
{opt compile} {opt language(str)} {opt noctex} {opt notoc} {opt simple} 
{opt r} {opt c}]

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
{cmd:mktex} converts Microsoft Word (.docx) documents to LaTeX (.tex) 
documents. It generates complete LaTeX documents with proper preamble, 
document structure, and optional table of contents. The command supports 
both full document generation and minimal ("simple") output for embedding 
in existing documents.

{p 4 4 2}
When the {cmd:compile} option is specified, the command compiles the 
generated LaTeX file to PDF using available LaTeX engines (pdflatex, 
xelatex, lualatex, or latex). If compilation fails, detailed troubleshooting 
guidance is provided.

{p 4 4 2}
The {cmd:check} option verifies the installation of pandoc and LaTeX, 
providing system-specific guidance for setup.

{marker troubleshooting}{...}
{title:Troubleshooting PDF Compilation}

{p 4 4 2}
If PDF compilation fails, check the following:

{p 6 6 2}
1. {bf:Check the log file}: Open {it:filename}.log in a text editor and look 
for error messages starting with '!'.{p_end}

{p 6 6 2}
2. {bf:Common issues}:{p_end}
{p 8 8 2}• Complex tables may not convert correctly{p_end}
{p 8 8 2}• Mathematical formulas may need manual adjustment{p_end}
{p 8 8 2}• Special characters may cause compilation errors{p_end}
{p 8 8 2}• Underlined text (\ul{}) is automatically removed{p_end}

{p 6 6 2}
3. {bf:Solutions}:{p_end}
{p 8 8 2}• Simplify the Word document (remove complex formatting){p_end}
{p 8 8 2}• Use pandoc directly (see {help mktex##limitations:Limitations} above){p_end}
{p 8 8 2}• Manually edit the generated .tex file to fix LaTeX errors{p_end}

{title:Options}

{phang}{opt replace} (or {opt r}) overwrites existing output files. 
Without this option, the command exits with an error if the output .tex 
file already exists.{p_end}

{phang}{opt compile} (or {opt c}) compiles the generated LaTeX file to 
PDF. The command automatically detects available LaTeX engines and performs 
one or two compilations (for proper table of contents when enabled). If 
compilation fails, detailed error analysis and solutions are provided.{p_end}

{phang}{opt language(str)} specifies the document language. For Chinese 
documents, use "chinese", "zh", or "cn". For English documents, use 
"english" or "en". Default is "chinese" unless {opt noctex} is specified.{p_end}

{phang}{opt noctex} disables automatic inclusion of the ctex package for 
Chinese documents. Use this option when you want to handle Chinese 
typesetting manually or when using alternative LaTeX packages.{p_end}

{phang}{opt notoc} disables table of contents generation in full document 
mode.{p_end}

{phang}{opt simple} creates a minimal LaTeX document containing only the 
converted content with basic preamble. This is useful for embedding content 
in existing LaTeX documents or when experiencing compilation issues with 
the full document structure.{p_end}

{phang}{opt check} verifies the installation of pandoc and LaTeX, displays 
system information, and provides troubleshooting guidance. This option does 
not require a {cmd:using} specification.{p_end}

{title:Requirements}

{p 4 4 2}
1. {bf:Pandoc}: Must be installed from 
{browse "https://pandoc.org/installing.html"}.{p_end}

{p 4 4 2}
2. {bf:LaTeX Distribution} (for PDF compilation): TeX Live, MiKTeX, or 
MacTeX.{p_end}

{title:Examples}

{p 4 4 2}
Basic conversion with default settings (Chinese document):{p_end}

{p 8 12 2}{cmd:. mktex using "report.docx"}{p_end}

{p 4 4 2}
Convert, compile to PDF, and overwrite existing files:{p_end}

{p 8 12 2}{cmd:. mktex using "thesis.docx", replace compile}{p_end}
{p 8 12 2}{cmd:. mktex using "thesis.docx", r c} {it:(short form)}{p_end}

{p 4 4 2}
Create a simple LaTeX document without full structure:{p_end}

{p 8 12 2}{cmd:. mktex using "content.docx", simple}{p_end}

{p 4 4 2}
Convert an English document without table of contents:{p_end}

{p 8 12 2}{cmd:. mktex using "paper.docx", language(english) notoc}{p_end}

{p 4 4 2}
Check installation status:{p_end}

{p 8 12 2}{cmd:. mktex, check}{p_end}

{title:Output Files}

{p 4 4 2}
The command can produce the following output files:{p_end}

{p 6 6 2}
1. {bf:.tex file}: A LaTeX document. In full mode (default), this includes 
complete document structure with preamble, packages, title, optional table 
of contents, and content. In simple mode, it includes minimal preamble and 
content only.{p_end}

{p 6 6 2}
2. {bf:.pdf file} (with {cmd:compile} option): A compiled PDF document. 
When table of contents is enabled, two compilation passes are performed for 
proper TOC generation.{p_end}

{p 6 6 2}
3. {bf:Log files}: Various LaTeX auxiliary files (.aux, .log, .toc, etc.) 
are automatically cleaned up after successful compilation. If compilation 
fails, the .log file is preserved for error analysis.{p_end}

{title:Authors}

{p 4 4 2}
{bf:Wu Lianghai}, {bf:Chen Liwen}, {bf:Wu Hanyan}, {bf:Wu Xinzhuo}, and 
{bf:Ma Defang}{p_end}

{p 8 8 2}
Anhui University of Technology (AHUT), Ma'anshan, China{p_end}
{p 8 8 2}
Email: {stata `"copy "agd2010@yeah.net""':agd2010@yeah.net}, 
{stata `"copy "2184844526@qq.com""':2184844526@qq.com}{p_end}

{p 8 8 2}
Nanjing University of Aeronautics and Astronautics (NUAA), Nanjing, China{p_end}
{p 8 8 2}
Email: {stata `"copy "2325476320@qq.com""':2325476320@qq.com}{p_end}

{p 8 8 2}
University of Bristol (UB), UK{p_end}
{p 8 8 2}
Email: {stata `"copy "2957833979@qq.com""':2957833979@qq.com}{p_end}

{p 8 8 2}
Capital Normal University (CNU), Beijing, China{p_end}
{p 8 8 2}
Email: {stata `"copy "6346@cnu.edu.cn""':6346@cnu.edu.cn}{p_end}

{title:Version History}

{p 4 4 2}
3.0 (05Feb2026): Enhanced error handling and troubleshooting guidance; 
added clear warnings about limitations; improved compilation failure 
diagnostics; maintained backward compatibility.{p_end}

{p 4 4 2}
2.92 (05Feb2026): Updated program header comments with comprehensive 
guidance for handling DOCX files containing tables and mathematical formulas; 
improved documentation clarity.{p_end}

{p 4 4 2}
2.9 (31Jan2026): Fixed display command syntax issues; improved Unicode 
filename handling; enhanced error messages; fixed variable name 
inconsistencies; improved cross-platform compatibility.{p_end}

{p 4 4 2}
2.5 (31Jan2026): Added {opt simple} mode for minimal LaTeX output; 
improved error handling; enhanced LaTeX engine detection; added {opt noctex} 
and {opt notoc} options; updated installation checker with better 
diagnostics; fixed macOS compatibility issues.{p_end}

{p 4 4 2}
2.1 (30Jan2026): Added cross-platform compatibility with macOS support; 
users can define pandoc path in profile.do on macOS.{p_end}

{p 4 4 2}
2.0 (28Jan2026): Added complete LaTeX document structure with table of 
contents; all options now support single-letter abbreviations; updated 
documentation.{p_end}

{p 4 4 2}
1.0 (28Jan2026): Initial release as mktex, basic Chinese character 
handling.{p_end}

{title:Acknowledgments}

{p 4 4 2}
We extend our sincere gratitude to {bf:Christopher F. Baum} for his 
enthusiastic support and timely scientific guidance. His valuable insights 
and constructive feedback have been instrumental in the continuous 
improvement and refinement of this program. We deeply appreciate his 
dedication to supporting the Stata community.{p_end}

{hline}
{p 4 4 2}
Type {cmd:help mktex} to display this help file again.
{p 4 4 2}
For direct pandoc conversion of complex documents, see examples in 
{help mktex##limitations:Limitations} section.
{*}