{smcl}
{right:version:  1.0}
{hi:help for autofill} {right:Oct. 1st, 2021}
{hline}

{title:Title}

{p 4 2 2}{hi:autofill}  -  Fill all kinds of {help missing:missing values} based on existing data{p_end}

{title:Syntax}

{p 4 2 2}{cmd:autofill} {help varlist:varlist} , forward|backward [groupby({help varname:varname})]{p_end}

{p 6 12 2}{it:varlist}  - The varlist whose data include missing value.{p_end}

{p 6 12 2}{it:forward}|{it:backward} - You need choose one from the options "forward" and "backward". If you choose "forward", the program will use the existing values to replace the missing values before them. If you choose "backward", the program will use the existing values to replace the missing values after them.{p_end}

{p 6 12 2}{it:groupby(varname)}  - Select a variable and group it according to its value. The observation with different values of this variable will be marked as different groups. Missing values in one group will not be replaced by existing values in other groups.{p_end}

{title:Description}

{p 4 2 2}{hi:Autofill} program makes it easy to fill in missing values with existing values in the data. It applies to all types of missing values in the Stata and can operate on lots of variables simultaneously. In addition, it provides a way to fill the missing values by group.{p_end}

{title:Example}

{p 4 2 2}You can creat the following dataset.{p_end}
{p 8 4 2}I | T | X | Y{p_end}
{p 7 4 2}---+---+---+---{p_end}
{p 8 4 2}a | 1 | . | .{p_end}
{p 8 4 2}a | 2 | 5 | .{p_end}
{p 8 4 2}a | 3 | . | 4{p_end}
{p 8 4 2}b | 1 | 3 | .{p_end}
{p 8 4 2}b | 2 | . | 5{p_end}
{p 4 2 2}a,b is two individuals, T=1,2,3 are different times, and X,Y is two variable values of individuals at different times.{p_end}

{p 4 2 2}{cmd:autofill X Y, backward} - You will get the following dataset.{p_end}
{p 8 4 2}I | T | X | Y{p_end}
{p 7 4 2}---+---+---+---{p_end}
{p 8 4 2}a | 1 | . | .{p_end}
{p 8 4 2}a | 2 | 5 | .{p_end}
{p 8 4 2}a | 3 | 5 | 4{p_end}
{p 8 4 2}b | 1 | 3 | 4{p_end}
{p 8 4 2}b | 2 | 3 | 5{p_end}

{p 4 2 2}{cmd:autofill X Y, forward} - You will get the following dataset.{p_end}
{p 8 4 2}I | T | X | Y{p_end}
{p 7 4 2}---+---+---+---{p_end}
{p 8 4 2}a | 1 | 5 | 4{p_end}
{p 8 4 2}a | 2 | 5 | 4{p_end}
{p 8 4 2}a | 3 | 3 | 4{p_end}
{p 8 4 2}b | 1 | 3 | 5{p_end}
{p 8 4 2}b | 2 | . | 5{p_end}

{p 4 2 2}{cmd:autofill X Y, forward groupby(I)} - You will get the following dataset.{p_end}
{p 8 4 2}I | T | X | Y{p_end}
{p 7 4 2}---+---+---+---{p_end}
{p 8 4 2}a | 1 | 5 | 4{p_end}
{p 8 4 2}a | 2 | 5 | 4{p_end}
{p 8 4 2}a | 3 | . | 4{p_end}
{p 8 4 2}b | 1 | 3 | 5{p_end}
{p 8 4 2}b | 2 | . | 5{p_end}
{p 4 2 2}After using {it:groupby(I)}, the X value of b at time T=1 does not replace the X value of  the previous observation(a at time T=3).{p_end}

{title:Author}

{p 4 2 2}Xia P.S.{p_end}
{p 4 2 2}University of Chinese Academy of Sciences{p_end}
{p 4 2 2}Email: xia_ps@yeah.net{p_end}