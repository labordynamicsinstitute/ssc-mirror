{smcl}
{* version 9.5  17aug2025 *}
{vieweralsosee "" "--"}{...}
{vieweralsosee "reftex" "help reftex"}{...}
{viewerjumpto "Title" "reftex##title"}{...}
{viewerjumpto "Syntax" "reftex##syntax"}{...}
{viewerjumpto "Description" "reftex##description"}{...}
{viewerjumpto "Options" "reftex##options"}{...}
{viewerjumpto "Input Format" "reftex##input"}{...}
{viewerjumpto "Examples" "reftex##examples"}{...}
{viewerjumpto "Version History" "reftex##history"}{...}
{viewerjumpto "Authors" "reftex##authors"}{...}

{marker title}{...}
{title:Title}

{p 4 8 2}
{bf:reftex} {hline 2} Enhanced bibliography processor with LaTeX escaping and mixed language support

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:reftex} {cmd:using} {it:{help filename}}{cmd:,} {opt outfile(filename)} 
[{opt debug} {opt replace} {opt lang(language)}]

{synoptset 25 tabbed}{...}
{synopthdr:Options}
{synoptline}
{syntab:Required}
{synopt:{opt out:file(filename)}}output LaTeX file{p_end}

{syntab:Optional}
{synopt:{opt lang(language)}}processing language: {it:chn}, {it:eng}, or {it:mix}{p_end}
{synopt:{opt debug}}display detailed processing information{p_end}
{synopt:{opt replace}}overwrite existing output file{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:reftex} converts plain text bibliographies into formatted LaTeX bibliographies with proper escaping of special characters. 
It supports Chinese, English, and mixed-language bibliographies with intelligent formatting rules for each language.

{pstd}
{ul:Key features}:{p_end}
{p2colset 9 28 30 2}{...}
{p2col :•} Automatic LaTeX character escaping (e.g., &, %, $, #){p_end}
{p2col :•} Chinese format: Authors (Year). Title...{p_end}
{p2col :•} English format: Authors (Year) Title, {it:Journal}, {bf:Volume}(Issue), Pages{p_end}
{p2col :•} Mixed language auto-detection (Chinese characters){p_end}
{p2col :•} Double period prevention system{p_end}
{p2col :•} Complete LaTeX document generation{p_end}
{p2colreset}{...}

{marker options}{...}
{title:Options}

{phang}
{opt outfile(filename)} specifies the output LaTeX file path. This option is required.

{phang}
{opt lang(language)} sets the processing language:
{p_end}
{pmore}{it:chn}: Chinese format (default){p_end}
{pmore}{it:eng}: English format{p_end}
{pmore}{it:mix}: Auto-detect language per entry{p_end}

{phang}
{opt debug} displays detailed processing information for debugging.

{phang}
{opt replace} overwrites the output file if it already exists.

{marker input}{...}
{title:Input Format Requirements}

{pstd}
Input files must follow these specifications:{p_end}

{p2colset 9 15 17 2}{...}
{p2col :1.} Each entry starts with [{it:number}] at beginning of line{p_end}
{p2col :2.} Entry content continues on subsequent lines{p_end}
{p2col :3.} {ul:Chinese format}: Authors Year. Title...{p_end}
{p2col :4.} {ul:English format}: Authors, Year, Title, Journal, Volume, Pages{p_end}
{p2colreset}{...}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. reftex using "references.txt", outfile("bib.tex") lang(chn) replace}{p_end}
{phang2}{it:Convert Chinese bibliography}

{phang2}{cmd:. reftex using "mixed_refs.txt", outfile("output.tex") lang(mix) debug}{p_end}
{phang2}{it:Convert mixed bibliography with debug mode}

{phang2}{cmd:. reftex using "english_bib.txt", outfile("eng.tex") lang(eng) replace}{p_end}
{phang2}{it:Convert English bibliography}

{marker history}{...}
{title:Version History}

{pstd}
{bf:v9.5} (17aug2025){p_end}
{pmore}- Fixed double period issue by cleaning field endings{p_end}
{pmore}- Enhanced trailing punctuation removal{p_end}
{pmore}- Improved end punctuation detection{p_end}

{pstd}
{bf:v9.4} (15aug2025){p_end}
{pmore}- Fixed double period issue with temporary file approach{p_end}

{pstd}
{bf:v9.3} (12aug2025){p_end}
{pmore}- Fixed double period issue at end of English entries{p_end}

{pstd}
{bf:v9.2} (10aug2025){p_end}
{pmore}- Added mixed language support (chn/eng/mix){p_end}

{pstd}
{bf:v9.1} (05aug2025){p_end}
{pmore}- Added LaTeX special character escaping{p_end}

{marker authors}{...}
{title:Authors}

{pstd}
Wu Lianghai{p_end}
{pmore}School of Business{p_end}
{pmore}Anhui University of Technology{p_end}
{pmore}Ma'anshan, China{p_end}
{pmore}{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}

{pstd}
Wu Hanyan{p_end}
{pmore}School of Economics and Management{p_end}
{pmore}Nanjing University of Aeronautics and Astronautics{p_end}
{pmore}Nanjing, China{p_end}
{pmore}{browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{pstd}
Chen Liwen{p_end}
{pmore}School of Business{p_end}
{pmore}Anhui University of Technology{p_end}
{pmore}Ma'anshan, China{p_end}
{pmore}{browse "mailto:2184844526@qq.com":2184844526@qq.com}{p_end}
{* }