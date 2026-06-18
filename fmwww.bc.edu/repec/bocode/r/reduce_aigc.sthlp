{smcl}
{* 06June2026}{...}
{title:Title}

{p 8 12 2}
{hi:reduce_aigc} {hline 2} Reduce AIGC similarity in Word documents (bilingual)

{title:Syntax}

{p 8 16 2}
{hi:reduce_aigc} , {bf:input(}{it:filename}{bf:)} [{bf:output(}{it:filename}{bf:)} 
    {bf:target(}{it:#}{bf:)} {bf:intensity(}{it:#}{bf:)} 
    {bf:dict(}{it:filename}{bf:)} {bf:methods(}{it:string}{bf:)}
    {bf:language(}{it:string}{bf:)}]

{title:Description}

{p 4 4 2}
{hi:reduce_aigc} calls an enhanced Python script ({it:reduce_word.py}) to perform multiple
text transformations on Microsoft Word (.docx) documents. It reduces the likelihood of
being flagged as AI-generated content (AIGC) or plagiarized text, with full
bilingual support (English/Chinese) and optimization for official similarity checks
such as VIP (维普).

{p 4 4 2}
{bf:Features:}

{space 4}- 7 reduction methods (synonym replacement, voice change, negative inversion,
 
{space 4}  sentence split/merge, order adjustment, abbreviation expansion, modifier addition)

{space 4}- Full Chinese support with jieba分词 for accurate word segmentation

{space 4}- User-defined synonym dictionaries (JSON/TXT/CSV)

{space 4}- Adjustable target similarity and reduction intensity

{space 4}- XML-compatible text cleaning to handle special characters

{title:Options}

{p 8 12 2}
{bf:input(}{it:string}{bf:)} Specifies the input Word (.docx) file (required).

{p 8 12 2}
{bf:output(}{it:string}{bf:)} Specifies the output Word file. If omitted, the output
file is automatically named by inserting {it:_reduced} before .docx.

{p 8 12 2}
{bf:target(}{it:real}{bf:)} Target similarity level (0.1 to 0.95). Lower values
apply more aggressive reduction. Default is {it:0.3} (30% similarity).

{p 8 12 2}
{bf:intensity(}{it:real}{bf:)} Controls overall reduction intensity (0.1 to 0.95).
Higher values apply more transformations. Default is {it:0.5}.

{p 8 12 2}
{bf:dict(}{it:string}{bf:)} User-defined synonym dictionary file.
Supported formats: JSON, TXT (key=value), CSV. See examples below.

{p 8 12 2}
{bf:methods(}{it:string}{bf:)} Comma-separated list of reduction methods to use.
Available methods:

{space 16}{cmd:synonym} - Synonym replacement

{space 16}{cmd:voice}   - Active/passive voice conversion

{space 16}{cmd:neg}     - Affirmative/double negative conversion

{space 16}{cmd:split}   - Sentence split/merge

{space 16}{cmd:order}   - Word order adjustment

{space 16}{cmd:expand}  - Abbreviation expansion (English only)

{space 16}{cmd:modifier}- Modifier addition

{p 8 12 2}
{bf:language(}{it:string}{bf:)} Language mode: {cmd:zh} (Chinese) or {cmd:en} (English).
Default is {it:zh}.

{title:Reduction Methods Details}

{p 4 4 2}
The tool uses multiple strategies to reduce text similarity:

{space 4}1. {bf:Synonym Replacement} - Replace words with semantically equivalent alternatives
{space 4}   Uses built-in synonym dictionaries (100+ entries in Chinese, 50+ in English)

{space 4}2. {bf:Voice Change} - Convert between active and passive structures
{space 4}   Examples: "执行了" → "被执行", "performs" → "is performed by"

{space 4}3. {bf:Negative Inversion} - Convert affirmative to double-negative forms
{space 4}   Examples: "很重要" → "不是不重要", "important" → "not unimportant"

{space 4}4. {bf:Split/Merge} - Split long sentences or merge short ones
{space 4}   Chinese: splits at 30+ characters; English: splits at 80+ characters

{space 4}5. {bf:Order Adjustment} - Adjust clause or phrase order
{space 4}   Examples: "因为...所以..." ↔ "...，因为..."

{space 4}6. {bf:Abbreviation Expansion} - Expand common abbreviations (English only)
{space 4}   Examples: "e.g." → "for example", "i.e." → "that is"

{space 4}7. {bf:Modifier Addition} - Add appropriate modifiers
{space 4}   Examples: "显著地", "明显地", "significantly", "notably"

{title:User Dictionary Formats}

{p 4 4 2}
{bf:JSON format (recommended for Chinese):}
{space 4} {{cmd:"研究": ["探讨", "考察", "分析", "探究"],}
{space 4} {cmd:"方法": ["方式", "手段", "途径", "策略"],}
{space 4} {cmd:"重要": ["关键", "核心", "主要", "首要"]}}

{p 4 4 2}
{bf:TXT format (key=value):}
{space 4}{cmd:研究=探讨,考察,分析,探究}
{space 4}{cmd:方法=方式,手段,途径,策略}
{space 4}{cmd:重要=关键,核心,主要,首要}

{p 4 4 2}
{bf:CSV format:}
{space 4}{cmd:研究,探讨,考察,分析,探究}
{space 4}{cmd:方法,方式,手段,途径,策略}
{space 4}{cmd:重要,关键,核心,主要,首要}

{title:Requirements}

{p 4 4 2}
{bf:Software Requirements:}
{space 4}- Stata 12.0 or higher
{space 4}- Python 3.6 or higher

{p 4 4 2}
{bf:Python Packages (install via pip):}
{space 4}{cmd:pip install python-docx} (required)
{space 4}{cmd:pip install jieba} (strongly recommended for Chinese mode)

{p 4 4 2}
{bf:File Location:}

{space 4}All three files must be in the same directory:

{space 4}- {it:reduce_aigc.ado}

{space 4}- {it:reduce_aigc.sthlp}

{space 4}- {it:reduce_word.py}

{space 4}Recommended path: {it:D:/Stata18/ado/personal/}

{title:Setup Instructions}

{p 4 4 2}
{bf:Step 1: Install Python packages}
{space 4}! python -m pip install python-docx jieba -i https://pypi.tuna.tsinghua.edu.cn/simple

{p 4 4 2}
{bf:Step 2: Set Python path in Stata (permanently)}
{space 4}set python_exec "C:\Users\YourName\...\python.exe", permanently

{p 4 4 2}
{bf:Step 3: Verify installation}
{space 4}python: import jieba; print("OK")
{space 4}python: import docx; print("OK")

{title:Examples}

{p 8 12 2}
{bf:Basic usage (Chinese, default):}
{cmd:. reduce_aigc , input("thesis.docx")}

{p 8 12 2}
{bf:With custom parameters:}
{cmd:. reduce_aigc , input("thesis.docx") target(0.25) intensity(0.6)}

{p 8 12 2}
{bf:Specify output file:}
{cmd:. reduce_aigc , input("thesis.docx") output("final.docx") target(0.2)}

{p 8 12 2}
{bf:Use custom dictionary:}
{cmd:. reduce_aigc , input("thesis.docx") dict("mydict.json")}

{p 8 12 2}
{bf:Use specific methods only:}
{cmd:. reduce_aigc , input("thesis.docx") methods("synonym,voice,split") target(0.3)}

{p 8 12 2}
{bf:English document:}
{cmd:. reduce_aigc , input("paper.docx") language("en") target(0.25) intensity(0.6)}

{title:Recommendations for Similarity Checks (e.g., VIP 维普)}

{p 4 4 2}
Recommended parameter settings based on required similarity:

{space 4}{bf:First draft (target < 40%):}
{space 8}{cmd:target(0.35) intensity(0.4)}

{space 4}{bf:Final submission (target < 30%):}
{space 8}{cmd:target(0.25) intensity(0.6)}

{space 4}{bf:Strict requirement (target < 20%):}
{space 8}{cmd:target(0.15) intensity(0.8)}

{space 4}{bf:Extreme requirement (target < 12%):}
{space 8}{cmd:target(0.10) intensity(0.9)}

{title:Output Statistics}

{p 4 4 2}
After processing, the program displays:

{space 4}- Total paragraphs processed

{space 4}- Number of modified paragraphs

{space 4}- Modification percentage

{space 4}- Total changes made

{space 4}- Methods used

{space 4}- Output file path

{title:Troubleshooting}

{p 4 4 2}
{bf:Error: "All strings must be XML compatible"}
{space 4}The document contains special control characters. The script automatically
{space 4}cleans these. If the error persists, save the document as a new .docx file.

{p 4 4 2}
{bf:Error: "No module named 'jieba'"}
{space 4}Install jieba: {cmd:pip install jieba -i https://pypi.tuna.tsinghua.edu.cn/simple}

{p 4 4 2}
{bf:Error: "Cannot find file reduce_word.py"}
{space 4}Ensure reduce_word.py is in the same directory as reduce_aigc.ado.

{p 4 4 2}
{bf:Download timeout when installing packages}
{space 4}Use domestic mirrors: {cmd:-i https://pypi.tuna.tsinghua.edu.cn/simple}

{title:Notes}

{p 4 4 2}

{space 8}1. Always manually review the output to ensure academic integrity and readability.{break}

{space 8}2. Start with lower intensity (0.4-0.5) and gradually increase.{break}

{space 8}3. Use custom dictionaries to protect technical terms from being replaced.{break}

{space 8}4. For Chinese documents, jieba is strongly recommended for better results.{break}

{space 8}5. The script automatically cleans XML-incompatible characters.{break}

{space 8}6. Both paragraphs and tables are processed.{break}

{space 8}7. Original document formatting (bold, italic, font size, etc.) is preserved.

{title:Performance}

{p 4 4 2}
Example with a 700-paragraph Chinese thesis:

{space 8}- Processing time: ~1-2 minutes

{space 8}- Modification rate: typically 10-30% depending on intensity

{space 8}- Memory usage: ~200-500 MB

{title:Authors}

{p 4 4 2}
{bf:Wu Lianghai}{break}
School of Business, Anhui University of Technology (AHUT), Ma'anshan, China{break}
{browse "mailto:agd2010@yeah.net":Email: agd2010@yeah.net}

{p 4 4 2}
{bf:Wu Hanyan}{break}
School of Economics and Management, Nanjing University of Aeronautics and Astronautics (NUAA), China{break}
{browse "mailto:2325476320@qq.com":Email: 2325476320@qq.com}

{p 4 4 2}
{bf:Chen Liwen}{break}
School of Business, Anhui University of Technology (AHUT), Ma'anshan, China{break}
{browse "mailto:2184844526@qq.com":Email: 2184844526@qq.com}

{title:Version}

{p 4 4 2}
8.0 (bilingual support + jieba integration + XML cleaning)

{title:Date}

{p 4 4 2}
06June2026

{title:Acknowledgments}

{p 4 4 2}
Thanks to the open-source community for python-docx and jieba packages.

{hline}