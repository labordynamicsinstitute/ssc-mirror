


{smcl}
{* *! version 1.0.0}{...}
{cmd:help clocktomin}
{hline}


{title:Syntax}

{p 8 17 2}
{cmdab:clocktomin:} var1 var2, diaryid(string) diaryst(n) 

{title:Description}

{pstd} {bf:clocktomin} {hline 2} converts the variables containing the start and 
end times of the activity, from a string looking like a clock, to 
the minute-of-the-day format required by the programs included in the {cmd:timeuse} package. 
Running the command will create the variables 'start' and 'end' while preserving the original timing variables: var1 and var2.

{pstd} An example of time use files that express activity timings in this format is the American Time Use Survey. 
In the original variable containing the start time of the activity, 4:30 am is represented as "04:30:00", whereas in the 'start' and 'end' variables, 4:30 am is represented by the number 30 (assuming the diary starts at 4 am). 
However, when inspecting the variables in the data editor, they will still display the time as a clock because the program attaches clock-like value labels, but 'start' and 'end' are numerical. 
If only the beginning of the episode of activity is provided in the original dataset, use the program {cmd:clocktomins} instead. 

{pstd} ATUS datasets have one peculiarity, the end of the last episode of activity reported is not the same as the time at which the diary started -as most time use surveys- but the actual time at which the activity ended. 
In case the user is working with a file from ATUS, the program provides a second end variable, 'end_atus' which captures the true end time for the last episode of activity in each diary. 
If the file is not an ATUS file, 'end_atus' will probably take the same value as 'end'.

{title:Arguments}

{phang}
{bf:var1}: variable containing the start time of the activity as a string that looks like a clock that also shows seconds, eg. "04:00:00".

{phang}
{bf:var2}: variable containing the end time of the activity as a string that looks like a clock that also shows seconds, eg. "04:00:00".

{phang}
{bf:diaryid(string)}: the names of the variable or variables that when considered jointly uniquely identify the diary. 

{phang}
{bf:diaryst(n)}: number that indicates the start time of the diary in a 24 hour system clock, with "0" representing midnight, "4" is 4am, and "18" would be 6pm.


{title:Outcomes} 

{phang}
{bf:start}: start time of the episode expressed as minute of day. 
'start' can take values from 0 to 1439. The first episode of the diary should start at minute
        0.

{phang}
{bf:end}: end time of the episode expressed as minute of day. 
'end' can take values from 1 to 1440. The last episode of the diary should end at minute 1440.


{title:Example}

{p}
The following code loads the dataset "atusdiary.dta" and creates the variables 'start', 'end', and 'end_atus' from the string variables included in the dataset.
"atusdiary.dta" is a small dataset with the exact same format as the American Time Use Survey (although with just a few variables). 
The variables 'tustarttim' and 'tustoptime' are the variables containing the start and end time of the episode of activity.
'start', 'end', and 'end_atus' measure the time at which the activity ends expressed as minute-of-the-day. 
Describing the package, {stata "ssc describe timeuse":ssc describe timeuse} may be needed before loading the example datasets. 

{phang2}. {stata "net get timeuse":net get timeuse}{p_end}
{phang2}. {stata "use atusdiary, clear":use atusdiary, clear}{p_end}
{phang2}. {stata "clocktomin tustarttim tustoptime, diaryid(tucaseid) diaryst(4)":clocktomin tustarttim tustoptime, diaryid(tucaseid) diaryst(4)}{p_end}
{phang2}. {stata "order tucaseid tustarttim start tustoptime end":order tucaseid tustarttim start tustoptime end}{p_end}
{phang2}. {stata "browse tucaseid tustarttim start tustoptime end":browse tucaseid tustarttim start tustoptime end}{p_end}

{title:Author:}

{pstd} Juana Lamote de Grignon Pérez, Centre for Time Use Research (UCL), juana.lamote@gmail.com

{pstd} Thanks for citing this software as follows:

{pmore}
Lamote de Grignon, J. (2024). timeuse: Stata package to facilitate the manipulation of diary-based time-use data. Available from: {browse "https://ideas.repec.org/c/boc/bocode/s459346.html":https://ideas.repec.org/c/boc/bocode/s459346.html.}


{title:Acknowledgments}

{pstd} I am grateful to Elena Mylona and Margarita Vega Rapún for their feedback during the development of the program.
