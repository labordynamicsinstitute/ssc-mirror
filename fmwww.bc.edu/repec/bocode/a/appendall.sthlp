{smcl}
{* 06May2025}{...}
{hline}
help for {hi:appendall}
{hline}

{title:Appending All Eligible Files in the Specified Folder}

{cmd:appendall} appending all eligible files (such as Stata, Excel, CSV or Text) in the specified folder.


{marker syntax}{...}
{title:Syntax}

{p 4 31 2}
{cmd:appendall } {cmd:using} {it:folder} [ , {opt s:ave(filepath)} {opt s:ubdirectory}
 {opt a:ttribute(string)} {opt o:rder(string)} {opt p:attern(string)} {opt r:egex} {opt t:ype(filetype)}
 {opt i:mportopt(options)} {opt c:omplete}  {opt d:o(program)} {opt pr:ogress} {opt op:en} {it:append_options} ]


{title:Options}

{phang}
{opt s:ave(filepath)} is optional, defines name and path about new appended file. The default file name is "AppendALLFile".

{phang}
{opt s:ubdirectory} is optional, also appends files in the subdirectory of {it:folder}.

{phang}
{opt a:ttribute(string)} is optional, specifies file attributes such as {opt a:ttribute}{cmd:(}{res:-H-S}{cmd:)}. The default is none. 

{phang}
{opt o:rder(string)} is optional, specifies the ordering method for appended files. The default is to order by files' names (i.e. {opt o:rder}{cmd:(}{res:ON}{cmd:)}).

{phang}
{opt p:attern(string)} is optional, sets criteria of name to filter appended files.

{phang} 
{opt r:egex} is optional, treats the {opt p:attern(string)} as a regular expression. The default as a general match.

{phang} 
{opt t:ype(filetype)} is optional, specifies new saved file format (one of {res:dta}, {res:csv}, {res:txt}, {res:xls}, {res:xlsx} or {res:excel}). The default is {opt t:ype}{cmd:(}{res:dta}{cmd:)}.

{phang}
{opt i:mportopt(options)} are optional, are any options available for {helpb import} if {opt t:ype(filetype)} is not "dta".

{phang}
{opt c:omplete} is optional, keep complete path (if option {opt s:ubdirectory} is set) and type (i.e. '.dta') of files in variable "{res:Filename}".

{phang}
{opt d:o(program)} is optional, is a pre-processing inbuilt program (or a do file) with standard Stata syntax,
 such as {cmd: do({it:myprogram [args], [options]})} or {cmd:do(do {it:filename [args]})}.

{phang}
{opt pr:ogress} is optional, displays the appending progress of files.

{phang}
{opt o:pen} is optional, loads appended file in {opt s:ave(filepath)}.

{phang}
{it:append_options} are optional, are any options available for {helpb append}.


{p 4}{res:*** Important Notes:}{p_end}
{p 4 7 2}1. If option {opt s:ave(filepath)} only have a file name without a path, the default path is the {it:folder} in {cmd:using};{p_end}
{p 4 7 2}2. If The size of appended excel files are larger than 40MB, you had better execute program "{cmd:set excelxlsxlargefile on}" before using command {cmd:appendall}.{p_end}


{title:Examples}

{phang}
{cmd:. appendall using "E:\New folder"}

{phang}
{cmd:. appendall using "E:\New folder", save("E:\Researchdata\result")}

{phang}
{cmd:. appendall using "E:\New folder", subdirectory}

{phang}
{cmd:. appendall using "E:\New folder", save("result") subdirectory}

{phang}
{cmd:. appendall using "E:\New folder", subdirectory complete}

{phang}
{cmd:. appendall using "E:\New folder", attribute(-H-S)}

{phang}
{cmd:. appendall using "E:\New folder", order(OD)}

{phang}
{cmd:. appendall using "E:\New folder", pattern(2020)}

{phang}
{cmd:. appendall using "E:\New folder", pattern("^2") regex}

{phang}
{cmd:. appendall using "E:\New folder", save("result") subdirectory open}

{phang}
{cmd:. appendall using "E:\New folder", save("result") subdirectory force}

{phang}
{cmd:. appendall using "E:\New folder", save("result") subdirectory attribute(-H-S) pattern("^2") regex}

{phang}
{cmd:. appendall using "E:\New folder", save("result") type(csv)}

{phang}
{cmd:. appendall using "E:\New folder", save("result") type(txt) importopt(delim(tab) encoding(utf-8))}

{phang}
{cmd:. appendall using "E:\New folder", save("result") type(xls) subdirectory}

{phang}
{cmd:. appendall using "E:\New folder", save("result") type(xlsx) importopt(firstrow)}

{phang}
{cmd:. appendall using "E:\New folder", save("result") type(excel) importopt(firstrow case(preserve))}

{phang}
{cmd:. appendall using "E:\New folder", save("result") type(excel) importopt(firstrow) keep(var1 var3 var6)}

{phang}
{cmd:. appendall using "E:\New folder", save("result") do(mydo)}  //mydo is a user-defined program

{phang}
{cmd:. appendall using "E:\New folder", save("result") progress}


{title:Authors}

{phang}
{cmd:Dejin Xie}, School of Economics and Management, Nanchang University, China.{break}
 E-mail: {browse "mailto:xiedejin@ncu.edu.cn":xiedejin@ncu.edu.cn}. {break}


{title:Also see}

{p 4 14 2}Help:  {helpb append}, {helpb merge}, {helpb joinby}, {helpb cross}.{p_end}
