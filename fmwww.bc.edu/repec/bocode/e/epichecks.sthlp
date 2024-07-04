


{smcl}
{* *! version 1.1.0  01jul2024}{...}
{cmd:help epichecks}
{hline}


{title:Syntax}

{p 8 17 2}
{cmdab:epichecks:} , diaryid(string)


{title:Description}

{pstd} {bf:epichecks} {hline 2} performs a few quality checks on the episode file and its key variables: 'start' and 'end'. 
First, the program checks for missing values in 'start' and 'end'. 
Second, the program checks that the diary starts at minute 0 and ends at minute 1440, as it should. 
Third, the program checks that there are no gaps between episodes and no partially or totally overlapping episodes 
(in other words, the beginning of every episode of activity must coincide exactly with the end of the previous episode). 

{pstd} If all these conditions are fulfilled, the episodes of activity are correctly defined and will add up to 1440 minutes per day. 
If the program finds that any of these conditions is not fulfilled, it will display a red message in the results window to warn the user about the problem so that it can be fixed. 
The program creates flag variables to facilitate inspection and correction of the problematic cases. 
It is a good idea to run {cmd:epichecks} before using any of the commands included in the {cmd:timeuse} package that use an episode file as a starting point, as otherwise, the programs may not produce the desired results.


{title:Arguments}

{phang}
{bf:diaryid(string)}: the names of the variable or variables that when considered jointly uniquely identify the diary. 


{title:Variables that need to exist}

{phang}
The following variables do need to exist in order for the program to work. 

{phang}
{bf:start}: start time of the episode expressed as minute of day. 
'start' can take values from 0 to 1439. The first episode of the diary 
should start at minute 0.

{phang}
{bf:end}: end time of the episode expressed as minute of day. 'end' can take values from 1 to 1440. The last episode of the diary should end at minute 1440.


{title:Outcomes} 

{bf:flag_start}: flags diaries with some missing/invalid value in 'start'.

{bf:flag_end}: flags diaries with with some missing/invalid value in 'end'. 

{bf:flag_badstart}: flags diaries where the first episode of activity does not start at minute 0.

{bf:flag_badend}: flags diaries where the last episode of activity does not end at minute 1440.

{bf:flag_gaps}: flags diaries containing at least one episode where start_n!=end_n-1.


{title:Examples}

{p}
The following examples start by loading the dataset "example_diary.dta" and run the quality checks. 
In the first example, the report shows that the diary file is unproblematic. 
In the remaining examples, we introduce errors and show how the report displays them. 
After the errors are fixed (by either actually fixing them or dropping the diaries that have problems), the program {cmd:epichecks} is run again to show how the report is clean once the problems have been solved. 


{bf:Example 1: a file without problems}

{phang2}. {stata "net get diary":net get diary}{p_end}
{phang2}. {stata "use example_diary, clear":use example_diary, clear}{p_end}
{phang2}. {stata "epichecks, diaryid(personid diaryid)":epichecks, diaryid(personid diaryid)}{p_end}


{bf:Example 2: a file problems in the diary start time}

{phang2}. {stata "net get diary":net get diary}{p_end}
{phang2}. {stata "use example_diary, clear":use example_diary, clear}{p_end}
{phang2}. {stata "replace start=5 if personid<5 & epnum==1":replace start=5 if personid<5 & epnum==1}{p_end}
{phang2}. {stata "epichecks, diaryid(personid diaryid)":epichecks, diaryid(personid diaryid)}{p_end}
{phang2}. {stata "replace start=0 if personid<5 & epnum==1":replace start=0 if personid<5 & epnum==1}{p_end}
{phang2}. {stata "epichecks, diaryid(personid diaryid)":epichecks, diaryid(personid diaryid)}{p_end}


{bf:Example 3: a file problems in the diary end time}

{phang2}. {stata "net get diary":net get diary}{p_end}
{phang2}. {stata "use example_diary, clear":use example_diary, clear}{p_end}
{phang2}. {stata "bysort personid diaryid: egen lastep=max(epnum)":bysort personid diaryid: egen lastep=max(epnum)}{p_end}
{phang2}. {stata "replace end=1430 if personid<=5 & epnum==lastep":replace end=1430 if personid<=5 & epnum==lastep}{p_end}
{phang2}. {stata "epichecks, diaryid(personid diaryid)":epichecks, diaryid(personid diaryid)}{p_end}
{phang2}. {stata "replace end=1440 if personid<=5 & epnum==lastep":replace end=1440 if personid<=5 & epnum==lastep}{p_end}
{phang2}. {stata "epichecks, diaryid(personid diaryid)":epichecks, diaryid(personid diaryid)}{p_end}


{bf:Example 4: a file with partly overlapping episodes}

{phang2}. {stata "net get diary":net get diary}{p_end}
{phang2}. {stata "use example_diary, clear":use example_diary, clear}{p_end}
{phang2}. {stata "egen udid=group(personid diaryid)":egen udid=group(personid diaryid)}{p_end}
{phang2}. {stata "xtset udid epnum":xtset udid epnum}{p_end}
{phang2}. {stata "replace start=l1.end+2 if epnum==3 & udid<=5":replace start=l1.end+2 if epnum==3 & udid<=5}{p_end}
{phang2}. {stata "epichecks, diaryid(personid diaryid)":epichecks, diaryid(personid diaryid)}{p_end}
{phang2}. {stata "drop if flag_gaps==1":drop if flag_gaps==1}{p_end}
{phang2}. {stata "epichecks, diaryid(personid diaryid)":epichecks, diaryid(personid diaryid)}{p_end}


{title:Author:}

{pstd} Juana Lamote de Grignon Pérez, Centre for Time Use Research (UCL), juana.lamote@gmail.com

{pstd} Thanks for citing this software as follows:

{pmore}
Lamote de Grignon, J. (2024). epichecks: Stata module to detect errors in episode files. Available from http://...”



{title:Acknowledgments:}

{pstd} I am grateful to Elena Mylona and Margarita Vega Rapún for their feedback during the development of the program.

