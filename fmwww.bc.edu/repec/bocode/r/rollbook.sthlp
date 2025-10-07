{smcl}
{title:Title}

{phang}
{cmd:rollbook} {hline 2} Student sampling program for class roll management

{title:Description}

{pstd}
{cmd:rollbook} is a Stata program designed to facilitate student sampling from class roll Excel files.
It provides multiple sampling methods including random sampling, sampling by serial number,
sampling by student ID parity (odd/even), and sampling by major. The program reads Excel files
with specific column names (序号, 学号, 姓名, 专业) and displays the sampling results in a formatted output.

{title:Syntax}

{p 8 15 2}
{cmd:rollbook} {cmd:using} {it:filename}{cmd:,} [{cmd:n(}{it:integer}{cmd:)} {cmd:serial(}{it:string}{cmd:)} {cmd:even(}{it:string}{cmd:)} {cmd:major(}{it:string}{cmd:)} {cmd:sheet(}{it:string}{cmd:)}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{cmd:n(}{it:integer}{cmd:)}}Specifies the number of students to randomly sample{p_end}
{synopt:{cmd:serial(}{it:string}{cmd:)}}Specifies serial numbers to select (space-separated){p_end}
{synopt:{cmd:even(}{it:string}{cmd:)}}Selects students based on student ID parity ("odd" or "even"){p_end}
{synopt:{cmd:major(}{it:string}{cmd:)}}Selects students from a specific major{p_end}
{synopt:{cmd:sheet(}{it:string}{cmd:)}}Specifies the worksheet name to read from Excel file{p_end}
{synoptline}

{title:Options}

{phang}
{cmd:n(}{it:integer}{cmd:)} specifies the number of students to randomly sample from the roll.
This option is required when no other selection method is specified.

{phang}
{cmd:serial(}{it:string}{cmd:)} allows selection of specific students by their serial numbers.
Multiple serial numbers can be provided as a space-separated list.

{phang}
{cmd:even(}{it:string}{cmd:)} selects students based on the parity (odd or even) of the last digit
of their student ID. Valid values are "odd" or "even".

{phang}
{cmd:major(}{it:string}{cmd:)} selects all students from a specified major.

{phang}
{cmd:sheet(}{it:string}{cmd:)} specifies the worksheet name to read from the Excel file. If not specified,
the program will read the first worksheet by default. This is useful when the Excel file contains multiple worksheets.

{title:Examples}

{phang}
{cmd:. rollbook using "rollbook.xlsx", n(5)}

{pstd}
Randomly samples 5 students from the Excel file.

{phang}
{cmd:. rollbook using "rollbook.xlsx", serial(8 18)}

{pstd}
Selects students with serial numbers 8 and 18.

{phang}
{cmd:. rollbook using "rollbook.xlsx", even(odd)}

{pstd}
Selects students whose student ID ends with an odd digit.

{phang}
{cmd:. rollbook using "rollbook.xlsx", major("Accounting")}

{pstd}
Selects all students from the "Accounting" major.

{phang}
{cmd:. rollbook using "rollbook.xlsx", sheet("ClassA") n(3)}

{pstd}
Randomly samples 3 students from the "ClassA" worksheet in the Excel file.

{phang}
{cmd:. rollbook using "rollbook.xlsx", sheet("ClassB") major("Finance")}

{pstd}
Selects all Finance major students from the "ClassB" worksheet.

{title:Required Excel Format}

{pstd}
The Excel file must contain the following columns with these exact names (in Chinese):

{p 8 8}{it:序号} (Serial number){p_end}
{p 8 8}{it:学号} (Student ID){p_end}
{p 8 8}{it:姓名} (Name){p_end}
{p 8 8}{it:专业} (Major){p_end}

{title:File Location}

{pstd}
The program expects the rollbook.xlsx file to be located in the current working directory.
If the file is not found, the program will display an error message with instructions.

{title:Authors}

{pstd}
Wu Lianghai{p_end}
{pstd}
School of Business, Anhui University of Technology (AHUT){p_end}
{pstd}
Ma'anshan, China{p_end}
{pstd}
E-mail: {browse "agd2010@yeah.net":agd2010@yeah.net}{p_end}

{pstd}
Chen Liwen{p_end}
{pstd}
School of Business, Anhui University of Technology (AHUT){p_end}
{pstd}
Ma'anshan, China{p_end}
{pstd}
E-mail: {browse "2184844526@qq.com":2184844526@qq.com}{p_end}

{pstd}
Hu Fangfang{p_end}
{pstd}
School of Finance and Economics, Wanjiang University of Technology (WJUT){p_end}
{pstd}
Ma'anshan, China{p_end}
{pstd}
E-mail: {browse "huff470@163.com":huff470@163.com}{p_end}

{pstd}
Jin Xuening{p_end}
{pstd}
School of Business, Anhui University of Technology (AHUT){p_end}
{pstd}
Ma'anshan, China{p_end}
{pstd}
E-mail: {browse "1418924481@qq.com":1418924481@qq.com}{p_end}

{title:Also see}

{pstd}
{help import excel} for importing Excel files into Stata{p_end}
{pstd}
{help sample} for Stata's built-in sampling command{p_end}
[file content end]