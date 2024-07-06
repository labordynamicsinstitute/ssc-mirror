


{smcl}
{* *! version 1.0.0}{...}
{cmd:help clocktomins}
{hline}


{title:Syntax}

{p 8 17 2}
{cmdab:clocktomins:} var, epnum(string) diaryid(string) diaryst(n) 

{title:Description}

{pstd} {bf:clocktomins} {hline 2} takes a string variable containing the start time of an activity and creates the variables 'start' and 'end', 
which measure the beginning and end of the activity in minutes elapsed since the beginning of the diary, as required by the programs in the {cmd:timeuse} package. 
An example of time use files that express activity timings in this format is the American Time Use Survey. 
In the original variable containing the start time of the activity, 4:30 am is represented as "04:30:00", whereas in the 'start' variable, 4:30 am is represented by the number 30 (assuming the diary starts at 4 am). 
When inspecting the 'start' variable in the data editor, it will appear as "04:30:00" because the program attaches a clock-like value label, but ‘start’ is numerical. 

{pstd} The program also creates the 'end' variable, by assuming the end of the episode is the beginning of the next episode. 
This program creates 'end' from 'start' when no end time is provided in the original dataset. 
If the original data also contains a string variable with the end time of the activity episode (as in the American Time Use Survey files), the user should use the {cmd:clocktminb} program instead, which creates both the 'start' and 'end' variables from the dataset's variables.


{title:Arguments}

{phang}
{bf:var}: variable containing the start time of the activity as a string that looks like a clock that also shows seconds, eg. "04:00:00".

{phang}
{bf:epnum(string)}: name of the variable containing the episode number. It is the variable that indicates the sequence in which the different episodes of activity happen. If no such variable exists in the dataset but the episodes of activity are ordered, simply create it like this: "bysort diaryid: gen epnum=_n".

{phang}
{bf:diaryid(string)}: the names of the variable or variables that when considered jointly uniquely identify the diary. 

{phang}
{bf:diaryst(n)}: number that indicates the start time of the diary in a 24 hour system clock, with "0" representing midnight, "4" is 4am, and "18" would be 6pm.

{title:Outcomes} 

{phang}
{bf:start}: start time of the episode expressed as minute of day. 'start' can take values from 0 to 1439. The first episode of the diary should start at minute
        0.

{phang}
{bf:end}: end time of the episode expressed as minute of day. 'end' can take values from 1 to 1440. The last episode of the diary should end at minute 1440.


{title:Example:}

{p}
The following lines of code load the dataset "atusdiary.dta" and creates the variables 'start' and 'end' from a variable containing the start time of the activity expressed as a clock.  
"atusdiary.dta" is a small dataset with the exact same format as the American Time Use Survey (although with just a few variables).
In the American Time Use survey, the start and end time of activities is measured by the variables 'tustarttim' and 'tustoptime', but for the sake of the example we will assume we only have 'tustarttim'.


{phang2}. {stata "net get timeuse":net get timeuse}{p_end}
{phang2}. {stata "use atusdiary, clear":use atusdiary, clear}{p_end}
{phang2}. {stata "clocktomins tustarttim, diaryid(tucaseid) epnum(tuactivity_n) diaryst(4)":clocktomins tustarttim, diaryid(tucaseid) epnum(tuactivity_n) diaryst(4)}{p_end}


{title:Author}

{pstd} Juana Lamote de Grignon Pérez, Centre for Time Use Research (UCL), juana.lamote@gmail.com

{pstd} Thanks for citing this software as follows:

{pmore}
Lamote de Grignon, J. (2024). clocktomins: Stata module to convert episode start time from string to minute-of-the day. Available from: {browse "https://ideas.repec.org/c/boc/bocode/s459346.html":https://ideas.repec.org/c/boc/bocode/s459346.html.}



{title:Acknowledgments}

{pstd} I am grateful to Elena Mylona and Margarita Vega Rapún for their feedback during the development of the program.
