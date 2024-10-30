



{smcl}
{cmd:help tocalendar}
{hline}



{title:Syntax}

{p 8 17 2}
{cmdab:tocalendar:} , diaryid(string) diaryst(n)

{title:Description}

{pstd} {bf:tocalendar} {hline 2} converts an episode file in long format —where each row represents an episode of activity— into a calendar file in long format, 
where each row of data represents a time slot of constant duration. 
The new file will have the same number of observations for each diary. 
The number of observations in the calendar file produced will depend on the duration of the time interval, which will be determined by the shortest episode in the data, 
most likely coinciding with the duration of the time interval in the diary instrument used to collect the data. 
For example, in a file where the shortest episode lasts 10 minutes, the calendar file created will have 144 time slots or observations per diary. 

{pstd} It may be a good idea to run {cmd:epichecks} before using this program, because if there were any errors in 'start' and/or 'end,' the program may not produce the desired results.


{title:Arguments}


{phang}
{bf:diaryid(string)}: the names of the variable or variables that when considered jointly uniquely identify the diary.

{phang}
{bf:diaryst(n)}: a number that indicates the start time of the diary in a 24 hour system clock, with "0" representing midnight, "4" is 4am, and "18" would be 6pm.


{title:Outcomes}

{phang}
{bf:tslot}: variable containing the time slot. 

{phang}
{bf:start}: variable containing the start time of the time slot, expressed as minute of the day (0-1439). 

{phang}
{bf:end}: variable containing the end time of the time slot, expressed as minute of the day (1-1440). 

{title:Variables that need to exist}

{p}
The following variables need to exist in the dataset for the program to work. 
If you have an episode file these variables should be there although they may have different names, in that case simply rename them.

{phang}
{bf:epnum}: variable indicating the episode number within each diary.

{phang}
{bf:time}: variable indicating the duration of the episode (in minutes).



{title:Example:}

{p}
The following lines of code load the dataset "diary.dta" and convert it into a diary level file -where each row of data represents a day. episode file defined by the primary activity, secondary activity and location. The diary starts at 4:00 am and the diary identifier is the variable 'id'.
Describing the package, {stata "ssc describe timeuse":ssc describe timeuse} may be needed before loading the example datasets. 

{phang2}. {stata "net get timeuse":net get timeuse}{p_end}
{phang2}. {stata "use diary, clear":use example_diary, clear}{p_end}
{phang2}. {stata "tocalendar, diaryid(personid diaryid) diaryst(4)":tocalendar, diaryid(personid diaryid) diaryst(4)}{p_end}


{title:Author:}

{pstd} Juana Lamote de Grignon Pérez, Centre for Time Use Research (UCL), juana.lamote@gmail.com

{pstd} Thanks for citing this software as follows:

{pmore}
Lamote de Grignon, J. (2024). timeuse: Stata package to facilitate the manipulation of diary-based time-use data. Available from: {browse "https://ideas.repec.org/c/boc/bocode/s459346.html":https://ideas.repec.org/c/boc/bocode/s459346.html.}

{title:Acknowledgments:}

{pstd} I am grateful to Elena Mylona and Margarita Vega Rapún for their feedback during the development of the program.