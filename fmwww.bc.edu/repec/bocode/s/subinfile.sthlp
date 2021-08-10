{smcl}
{* 19Sep2016}{...}
{hi:help subinfile}
{hline}

{title:Title}

{phang}
{bf:subinfile} {hline 2} subinfile is intended for use by programmers who want to perform byte-based substitution for the contents of a text-formatted file.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:subinfile}{it: filesource}{cmd:,} [{it:options}]

{phang}
{it:filesource} must be the path and file name, whereas the file must be a text-formatted one, no matter the extention name.


{marker description}{...}
{title:Description}

{pstd}
{cmd:subinfile} find the occorance of a strings and replace it with another. {p_end}

{pstd}
{cmd:subinfile} requires Stata version 14 or higher. {p_end}


{marker options}{...}
{title:Options for subinfile}

{phang}
{opt index(string)} specifies the line which contains it will be kept. Those lines without the key string specified by index() option will be dropped. {p_end}

{phang}
{opt indexregex} specifies that the contents you specify in index() is to be interpreted as a regular expression. {p_end}

{phang}
{opt from(string)} and {opt to(string)} specifies the string which is to be replaced whereas the to() option specifies the new string which 
will be used to replace the old one. {p_end}

{phang}
{opt fromregex} specifies that the contents you specify in from() is to be interpreted as a regular expression. {p_end}

{phang}
{opt dropempty} drops the empty line. If you specify both from() and dropempty, Stata will first replace the string 
you specify and then drop the empty line. {p_end}

{phang}
{opt save(string)} specifies the path and the file name to be saved. If you do not sepcify the format of the file, 
it will be saved as .txt by default. {p_end}

{phang}
{opt replace} permits save to overwrite an existing file which is not read-only. If you do not specify the option save(string), the original file
will be replaced. {p_end}

{pstd}
If you sepcify the option {opt index(string)}, {opt from(string)} and {opt dropempty} in one command at the same time, the 
option {opt index(string)} will be executed first, then {opt from(string)}, and {opt dropempty} at last. {p_end}


{marker example}{...}
{title:Example}

{pstd}
Use command {cmdab:file} to creat a text file to test subinfile

{phang}
{stata `"clear"'}
{p_end}
{phang}
{stata `"set more off"'}
{p_end}
{phang}
{stata `"tempname temp"'}
{p_end}
{phang}
{stata `"file open `temp' using D:\temp.txt, write text replace"'}
{p_end}
{phang}
{stata `"file write `temp' "stata" _n"'}
{p_end}
{phang}
{stata `"file write `temp' "abcdefg" _n"'}
{p_end}
{phang}
{stata `"file write `temp' "123456789""'} 
{p_end}
{phang}
{stata `"file close `temp'"'} 
{p_end}

{pstd}
Use command {cmdab:subinfile} to substitute "stata" to "STATA".

{phang}
{stata `"subinfile D:\temp.txt, from("stata") to("STATA") save(D:\temp1.txt)"'}
{p_end}

{pstd}
Use command {cmdab:subinfile} to keep the lines that contain "stata".

{phang}
{stata `"subinfile D:\temp.txt, index("stata") save(D:\temp2.txt)"'}
{p_end}

{pstd}
Use command {cmdab:subinfile} and regular expression to substitute "abcdefg" to "alphabetic".

{phang}
{stata `"subinfile D:\temp.txt, from("[a-z]{7}") to("alphabetic") fromregex save(D:\temp3.txt)"'}
{p_end}

{pstd}
Use command {cmdab:subinfile} and regular expression to delete "123456789".

{phang}
{stata `"subinfile D:\temp.txt, from("\d") fromregex save(D:\temp4.txt)"'}
{p_end}

{pstd}
Use command {cmdab:subinfile} to drop all letters and then drop empty line.

{phang}
{stata `"subinfile D:\temp.txt, from([a-zA-Z]) fromregex dropempty replace"'}
{p_end}


{title:Author}

{pstd}Chuntao LI{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}chtl@zuel.edu.cn{p_end}

{pstd}Yuan XUE{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}xueyuan19920310@163.com{p_end}

{pstd}Rong GAO{p_end}
{pstd}Guangxi University Of Finance and Economics{p_end}
{pstd}Nanning, China{p_end}
{pstd}highsun_gao@163.com{p_end}


