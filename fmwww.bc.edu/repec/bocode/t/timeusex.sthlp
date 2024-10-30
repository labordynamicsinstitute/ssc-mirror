


{smcl}
{cmd:help timeusex}
{hline}


{title:Syntax}

{p 8 17 2}
{cmdab:timeusex:} var, diaryid(string) diaryst(string)


{title:Description}

{pstd} {bf:timeusex} {hline 2} transforms an episode file in long format —where each row represents an episode of activity— into a diary-level file that summarizes the time use information for the selected activity. 
The new file will contain variables with the following information: total time spent on the activity, number of times the diarist engages in the activity on that day, and timing and duration for the different episodes of activity. 
If instead of having so much information about a single activity, you wish to know how much time is spent across several activities, consider using the program {cmd:timeuse}.

{pstd} For the program to produce the desired results, the diary should cover an entire 24-hour period, and the episodes of activity should be non-overlapping and contain no gaps between them. 
In other words, all diaries should start at minute 0, end at minute 1440, and the end of one episode should coincide exactly with the start of the next episode. 
It may be a good idea to run {cmd:epichecks} before using this program, because if there were any errors in 'start' and/or 'end,' the program may not produce the desired results.
 

{title:Outcomes} 

{phang}
The program creates a diary level file with the following variables: 

{phang}
{bf:total}: total time in the activity

{phang}
{bf:episodes}: number of episodes devoted to the activity, iow, number of times that the diarists engages in the activity.
    
{phang}
{bf:start1 to startN}: start time (minute of diary) of the each episode of activity

{phang}
{bf:end1 to endN}: end time (minute of diary) of each episode of the activity

{phang}
{bf:duration1 to durationN}: duration (in minutes) of each episode of activity 

{phang}
{bf:start_last}: start time (minute of diary) of the last episode of the activity for that diary.

{phang}
{bf:end_last}: end time (minute of diary) of the last episode of the activity for that diary.

{phang}
{bf:duration_last}: end time (minute of diary) of the last episode of the activity for that diary.


{title:Arguments}

{phang}
{bf:var}: dummy variable taking the value 1 whenever the episode of activity
is equal to the activity of interest, and any other value otherwise. 

{phang}
{bf:diaryid(string)}: the names of the variable or variables that when considered jointly uniquely identify the diary.

{phang}
{bf:diaryst(n)}: a number that indicates the start time of the diary in a 24 hour system clock, with "0" representing midnight, "4" is 4am, and "18" would be 6pm.


{title:Variables that need to exist}

{phang}
The following variables do need to exist for the program to work since the ado file will call them at some point. 
These variables should already exist in the data, simply rename them as 'start' and 'end'.

{phang}
{bf:start}: start time of the episode expressed as minute of day. 
"start" can take values from 0 to 1439. The first episode of the diary should start at minute 0.

{phang}
{bf:end}: end time of the episode expressed as minute of day. "end" can take values from 1 to 1440. The last episode of the diary should end at minute 1440.


{title:Examples}

{p}
The following lines of code load the dataset "diary.dta" and convert it into a diary level file -where each row of data represents a day- with detailed information for several activities. 
The first example explores eating, and the second explores solitary TV use (watching TV alone). The diary starts at 4:00 am and the diary identifier is the variable 'id'.

{bf:Example 1: exploring eating}

{phang2}. {stata "net get timeuse":net get timeuse}{p_end}
{phang2}. {stata "use diary, clear":use diary, clear}{p_end}
{phang2}. {stata "gen eating=0":gen eating=0}{p_end}
{phang2}. {stata "replace eating=1 if primary==2|secondary==2":replace eating=1 if primary==2|secondary==2}{p_end}
{phang2}. {stata "timeusex eating, diaryid(personid diaryid) diaryst(4)":timeusex eating, diaryid(personid diaryid) diaryst(4)}{p_end}

{bf:Example 2: watching TV alone}

{phang2}. {stata "net get timeuse":net get timeuse}{p_end}
{phang2}. {stata "use diary, clear":use diary, clear}{p_end}
{phang2}. {stata "gen tvalone=0":gen tvalone=0}{p_end}
{phang2}. {stata "replace tvalone=1 if primary==14 & ww_alone==1":replace tvalone=1 if primary==14 & ww_alone==1}{p_end}
{phang2}. {stata "timeusex tvalone, diaryid(personid diaryid) diaryst(4)":timeusex tvalone, diaryid(personid diaryid) diaryst(4)}{p_end}

{bf:Example 3: exercising outdoors with others}

{phang2}. {stata "net get timeuse":net get timeuse}{p_end}
{phang2}. {stata "use diary, clear":use diary, clear}{p_end}
{phang2}. {stata "gen exercise=0":gen exercise=0}{p_end}
{phang2}. {stata "replace exercise=1 if primary==17 & inout==2 & ww_alone==0":replace exercise=1 if primary==17 & inout==2 & ww_alone==0}{p_end}
{phang2}. {stata "timeusex exercise, diaryid(personid diaryid) diaryst(4)":timeusex exercise, diaryid(personid diaryid) diaryst(4)}{p_end}


{title:Author:}

{pstd} Juana Lamote de Grignon Pérez, Centre for Time Use Research (UCL), juana.lamote@gmail.com

{pstd} Thanks for citing this software as follows:

{pmore}
Lamote de Grignon, J. (2024). timeuse: Stata package to facilitate the manipulation of diary-based time-use data. Available from: {browse "https://ideas.repec.org/c/boc/bocode/s459346.html":https://ideas.repec.org/c/boc/bocode/s459346.html.}


{title:Acknowledgments}

{pstd} I am grateful to Elena Mylona and Margarita Vega Rapún for their feedback during the development of the program.



