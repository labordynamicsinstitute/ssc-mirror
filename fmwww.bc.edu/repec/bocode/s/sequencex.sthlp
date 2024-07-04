


{smcl}
{* *! version 1.1.0  01jul2009}{...}
{cmd:help sequencex}
{hline}


{title:Syntax}

{p 8 17 2}
{cmdab:sequencex:}
[var1] [var2] ... [var30], diaryid(string) diaryst(n)



{title:Description}

{phang}
{bf:sequencex} {hline 2} transforms an episode file in long format —where each row represents an episode of activity— into another episode file defined by different variables. 
A new episode will be defined any time there is a change in any of the variables specified in the syntax. 
The new episode file will be a simplified version of the original one and will most likely contain fewer episodes than the original. 
It may be a good idea to run {cmd:epichecks} before using this program, because if there were any errors in 'start' and/or 'end,' the program may not produce the desired results.  
If however, the starting file is a calendar file, use the program {cmd:sequence} instead.

{title:Arguments}

{phang}
{bf:var1 to var30}: variable/s used to define the episode of activity. These variables are usually the activity and the other diary fields such as location, copresence, etc... Up to 30 variables can be specified to define the episodes of activity. The variables need to be numeric, strings are not allowed.

{phang}
{bf:diaryid(string)}: the names of the variable or variables that when considered jointly uniquely identify the diary. 

{phang}
{bf:diaryst(n)}: diary start time, a number is expected. eg. 4 if the diary starts at 4 am or 0 if the diary starts at midnight. A 24-hour clock is used.


{title:Variables that need to exist}

{phang}
In addition to the variables specified in the argument, the following variable START needs to be there for the program to work:

{phang}
{bf:start}: start time of the episode of activity expressed as minute of the day. It can take values from 0 to 1439. 

{title:Outcomes} 

{pstd} {bf:epnum}: variable indicating the episode number for each data row.

{pstd} {bf:start}: variable showing the start time of the episode of activity expressed as minute of the day. It can take values from 0 to 1439.

{pstd} {bf:end}: variable showing the end time of the episode of activity expressed as minute of the day. It can take values from 1 to 1440.

{pstd} {bf:time}: shows the duration of the episode of activity (=end-start). 

{pstd} {bf:clockst}: start time of the activity expressed in clock format.   



{title:Examples}

{p}
The following lines of code load the dataset "example_diary.dta" -an episode file where the episodes of activity are defined by the following variables: 
primary activity, secondary activity, copresence, location, and enjoyment among others- and creates new episode files defined by fewer variables. 


{bf:Example 1: episodes defined by primary activity only} 

{p}
This could be useful if you are only interested in changes in the primary activity. 

{phang2}. {stata "net get diary":net get diary}{p_end}
{phang2}. {stata "use example_diary, clear":use example_diary, clear}{p_end}
{phang2}. {stata "sequencex primary, diaryid(personid diaryid) diaryst(4)":sequencex primary, diaryid(personid diaryid) diaryst(4)}{p_end}


{bf:Example 2: episodes defined by the copresence fields} 

{p}
If you are not interested in what people are doing but on where they are, this transformation could make sense.

{phang2}. {stata "net get diary":net get diary}{p_end}
{phang2}. {stata "use example_diary, clear":use example_diary, clear}{p_end}
{phang2}. {stata "sequencex ww_alone ww_child ww_partner ww_other, diaryid(personid diaryid) diaryst(4)":sequencex ww_alone ww_child ww_partner ww_other, diaryid(personid diaryid) diaryst(4)}{p_end}

{bf:Example 3: episodes defined by the enjoyment field} 

{p}
This may be useful if you are interested in exploring how often people change their mood throughout the day.

{phang2}. {stata "net get diary":net get diary}{p_end}
{phang2}. {stata "use example_diary, clear":use example_diary, clear}{p_end}
{phang2}. {stata "sequencex enjoyment, diaryid(personid diaryid) diaryst(4)":sequencex enjoyment, diaryid(personid diaryid) diaryst(4)}{p_end}


{title:Author}

{pstd} Juana Lamote de Grignon Pérez, Centre for Time Use Research (UCL), juana.lamote@gmail.com

{pstd} Thanks for citing this software as follows:

{pmore}
Lamote de Grignon, J. (2024). sequencex: Stata module to create episode files from other episode files. Available from http://...”



{title:Acknowledgments}

{pstd} I am grateful to Elena Mylona and Margarita Vega Rapún for their feedback during the development of the program.
