


{smcl}
{cmd:help sequence}
{hline}


{title:Syntax}

{p 8 17 2}
{cmdab:sequence:}
[var1] [var2] ... [var30], diaryid(string) diaryst(n)


{title:Description}

{phang}
{bf:sequence} {hline 2} transforms a time use file in calendar long format —where each row represents a time interval of constant duration in a person's day— into an episode-level file. 
In the episode file, each row represents an episode of activity, a period of time during which there is no change in any of the variables specified in the syntax. 
If however, you desire to create an episode-level file starting from another episode file, use the command {cmd:sequencex} instead.



{title:Arguments}

{phang}
{bf:var1 to var30}: variable/s used to define the episode of activity. These variables are usually the activity, and the other diary fields such as location, copresence, etc... 
Up to 30 variables can be specified to define the episodes of activity. 
The variables need to be numeric, strings are not allowed. 

{phang}
{bf:diaryid(string)}: the names of the variable or variables that when considered jointly uniquely identify the diary. 

{phang}
{bf:diaryst(n)}: diary start time, a number is expected. eg. 4 if the diary starts at 4 am or 0 if the diary starts at midnight. A 24-hour clock is used.


{title:Variables that need to exist}

{phang}
In addition to the variables specified in the argument, the variable 'tslot' needs to be there for the program to work:

{phang}
{bf:tslot}: variable indicating the number of time slot for each row of data. 
The time slots are the intervals of time into which the day is divided. 
For example, in a diary organised into 10-minute time slots, 144 time slots are expected, taking values from 1 to 144. 
Before creating the episodes, the program will check that all diaries have the same number of time slots and that they have the expected values. 
If this variable is called something other than "tslot", simply rename it before running the program.

{title:Outcomes} 

{pstd} {bf:epnum}: variable indicating the episode number for each data row.

{pstd} {bf:start}: variable showing the start time of the episode of activity expressed as minute of the day. It can take values from 0 to 1439.

{pstd} {bf:end}: variable showing the end time of the episode of activity expressed as minute of the day. It can take values from 1 to 1440.

{pstd} {bf:time}: shows the duration of the episode of activity. It is calculated as end-start. 

{pstd} {bf:clockst}: start time of the activity expressed in clock format.   


{title:Examples}

{pstd} The following lines of code load the dataset "example_calendar.dta" and convert it into an episode file. 
In the first example the episodes are defined by the primary activity only. 
In the second example the location field is used to define the episodes. 
In the third example, three variables are used: the primary activity, the secondary activity and the location.
Note how the number of episodes drops when fewer variables are used to define the episodes. The diary starts at 4:00 am and the diaries are uniquely identified by the variables 'personid' and 'diaryid'.

{bf:Example 1: episodes defined by primary only} 

{phang2}. {stata "net get calendar":net get calendar}{p_end}
{phang2}. {stata "use example_calendar, clear":use example_calendar, clear}{p_end}
{phang2}. {stata "sequence primary, diaryid(personid diaryid) diaryst(4)":sequence primary, diaryid(personid diaryid) diaryst(4)}{p_end}

{bf:Example 2: episodes defined by location} 

{phang2}. {stata "net get calendar":net get calendar}{p_end}
{phang2}. {stata "use example_calendar, clear":use example_calendar, clear}{p_end}
{phang2}. {stata "sequence location, diaryid(personid diaryid) diaryst(4)":sequence location, diaryid(personid diaryid) diaryst(4)}{p_end}

{bf:Example 3: episodes defined by primary, secondary and location} 

{phang2}. {stata "net get calendar":net get calendar}{p_end}
{phang2}. {stata "use example_calendar, clear":use example_calendar, clear}{p_end}
{phang2}. {stata "sequence primary secondary location, diaryid(personid diaryid) diaryst(4)":sequence primary secondary location, diaryid(personid diaryid) diaryst(4)}{p_end}

{title:Author}

{pstd} Juana Lamote de Grignon Pérez, Centre for Time Use Research (UCL), juana.lamote@gmail.com

{pstd} Thanks for citing this software as follows:

{pmore}
Lamote de Grignon, J. (2024). sequence: Stata module to create episode files from calendar files. Available from http://...”


{title:Acknowledgments}

{pstd} I am grateful to Elena Mylona and Margarita Vega Rapún for their feedback during the development of the program.
