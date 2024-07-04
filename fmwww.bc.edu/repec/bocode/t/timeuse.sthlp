


{smcl}
{* *! version 1.0  30Jun2024∫}{...}
{cmd:help timeuse}
{hline}


{title:Syntax}

{p 8 17 2}
{cmdab:timeuse:} var, diaryid(string)


{title:Description}

{phang}
{bf:timeuse} {hline 2} transforms an episode file into a diary-level file containing basic time use information, 
such as total time spent on the activity and the number of episodes for the different categories of activities contained in 'var'. 
If you are interested in the timing of the activities, see the program {cmd:timeusex}. 
It may be a good idea to run {cmd:epichecks} before using this program, because if there were any errors in 'start' and/or 'end,' the program may not produce the desired results. 

{title:Arguments}

{phang}
{bf:var}: categorical variable capturing the activity. The categories of 'var' do not need to be labelled but it is recommended that they are. 'var' can have missing values but no negative values are allowed. If missing values take values below zero, make sure you recode them before running the command. 

{phang}
{bf:diaryid(string)}: the names of the variable or variables that when considered jointly uniquely identify the diary.


{title:Variables that need to exist}

{phang}
The following variables do need to exist in order for the program to work since the ado file will call them at some point. If, as you should, you are working with diary data, these variables must exist, simply rename them.

{phang}
{bf:start}: start time of the episode expressed as minute of day. "start" can take values from 0 to 1439. The first episode of the diary should start at minute 0.

{phang}
{bf:end}: end time of the episode expressed as minute of day. "end" can take values from 1 to 1440. The last episode of the diary should end at minute 1440.


{title:Outcomes} 

{phang}
The program creates a diary level file with the following variables: 

{phang}
{bf:var_1 to var_n}: variables containing total time spent on each of the 1 to N categories of activity. 

{phang}
{bf:var_1_n to var_N_n}: number of episodes for each of the 1 to N categories of 'var'.


{title:Examples}

{p}
The following example loads the dataset "example_diary.dta" and runs the program {cmd:timeuse} to create a diary level file with time use information for the categories of activity included in the variable primary.
After running the problem a small report will be displayed in the results window that will tell the user whether or not the variables created containing the time spent on each category of activity add up to 1440 or not. That the categories of activity do not add up to 1440 is not necessarily a problem. Datasets often have missing values and in those cases, it is expected that the sum of the different activities does not add up to 1440 minutes.

{bf:Example 1: time spent across the different categories of 'primary'} 

{p}
In this example, primary has missing values and as a result, the sum of the different categories of activity created does not add up to 1440. 

{phang2}. {stata "net get diary":net get diary}{p_end}
{phang2}. {stata "use example_diary, clear":use example_diary, clear}{p_end}
{phang2}. {stata "timeuse primary, diaryid(personid diaryid)":timeuse primary, diaryid(personid diaryid)}{p_end}

{bf:Example 2: time spent outdoors and indoors} 

{p}
To have categories of activity adding up to 1440 minutes, we give valid values to the missing values in the variable 'inout'.

{phang2}. {stata "net get diary":net get diary}{p_end}
{phang2}. {stata "use example_diary, clear":use example_diary, clear}{p_end}
{phang2}. {stata "lab define inout 4 unknown, modify":lab define inout 4 unknown, modify}{p_end}
{phang2}. {stata "recode inout (.=4)":recode inout (.=4)}{p_end}
{phang2}. {stata "timeuse inout, diaryid(personid diaryid)":timeuse inout, diaryid(personid diaryid)}{p_end}



{title:Author:}

{pstd} Juana Lamote de Grignon Pérez, Centre for Time Use Research (UCL), juana.lamote@gmail.com

{pstd} Thanks for citing this software as follows:

{pmore}
Lamote de Grignon, J. (2024). timeuse: Stata module to extract basic time use information for multiple activities. Available from https://ideas.repec.org/c/boc/bocode/s459346.html”



{title:Acknowledgments:}

{pstd} I am grateful to Elena Mylona and Margarita Vega Rapún for their feedback during the development of the program.



