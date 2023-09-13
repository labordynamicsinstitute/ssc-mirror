{smcl}
{* 31 Jan 2019}{...}
{hline}
help for {hi:sctostreamcsv}
{hline}

{title:Title}

{phang2}{cmdab:sctostreamcsv} {hline 2} This command adds variables to sensor streams files outputted alongside data exported from {browse "https://www.surveycto.com/":SurveyCTO}. The added variables are calculations based on the sensor recordings in those files.{p_end}

{title:Syntax}

{phang2} {cmdab:sctostreamcsv} ,
		{cmdab:media:folder(}{it:folder_path}{cmd:)} {cmdab:output:folder(}{it:folder_path}{cmd:)}
	[
		{cmdab:keyvar} {cmdab:replace} {cmdab:quiet} {cmdab:still} {cmdab:moving}
		{cmdab:llbet:ween(}{it:string}{cmd:)} {cmdab:slbet:ween(}{it:string}{cmd:)}
		{cmdab:spbet:ween(}{it:string}{cmd:)} {cmdab:mvbet:ween(}{it:string}{cmd:)}
	]{p_end}

{marker opts}{...}
{synoptset 24}{...}
{synopthdr:options}
{synoptline}
{pstd}{it:Required options:}{p_end}
{synopt :{cmdab:media:folder(}{it:folder_path}{cmd:)}} Folder where the .csv stream files used as an input to this command are saved.{p_end}
{synopt :{cmdab:output:folder(}{it:folder_path}{cmd:)}} Folder where the new .csv files generated by this command will be saved.{p_end}

{pstd}{it:Output options:}{p_end}
{synopt :{cmdab:keyvar}} Saves the UUID key of the submission the sensor stream belongs to in a variable inside the file. By default the key is only in the file name.{p_end}
{synopt :{cmdab:replace}} Replace files already in the output folder. Default is to skip files already in the output folder and not update them.{p_end}

{pstd}{it:Standardized Statistics options:}{p_end}
{synopt :{cmdab:quiet}} Add a statistic indicating which time period the sound level around the device was quiet. Requires sound level sensor files.{p_end}
{synopt :{cmdab:still}} Add a statistic indicating which time period the device was completely still. Requires movement sensor files.{p_end}
{synopt :{cmdab:moving}} Add a statistic indicating which time period the device was moving. Requires movement sensor files.{p_end}

{pstd}{it:Customizable Statistics options:}{p_end}
{synopt :{cmdab:llbet:ween(}{it:{help sctostreamcsv##customstats:range_string}}{cmd:)}} Manually specified statistics for the light level stream.{p_end}
{synopt :{cmdab:slbet:ween(}{it:{help sctostreamcsv##customstats:range_string}}{cmd:)}} Manually specified statistics for the sound level stream.{p_end}
{synopt :{cmdab:spbet:ween(}{it:{help sctostreamcsv##customstats:range_string}}{cmd:)}} Manually specified statistics for the sound pitch stream.{p_end}
{synopt :{cmdab:mvbet:ween(}{it:{help sctostreamcsv##customstats:range_string}}{cmd:)}} Manually specified statistics for the movement stream.{p_end}

{synoptline}

{marker desc}
{title:Description}

{pstd}{cmd:sctostreamcsv} is a command that adds statistics to the sensor stream .csv files outputted by the {it:sensor_stream} field in {browse "https://www.surveycto.com/":SurveyCTO's} data collection tool. The .csv files include sensor data (light level, sound level, sound pitch and movement) recorded during the interview by the device used in the data collection. The unit of observation (what each row represents) in the .csv files this command uses as input is the time period the sensor data was reported on. The default is one second, but this can be changed in the survey form definition.{p_end}

{pstd}This command adds one column for each {it:Standardized Statistics} option and/or each {it:Customizable Statistics} option specified by the user to the individual sensor stream .csv files. Each of these statistics are calculated as booleans, i.e. either true or false. For example, was it quiet or not, was the sensor within a certain range or not. This boolean, represented as 1 or 0 where 1 is true, is calculated for each time period for that sensor and added in the row in the .csv file corresponding to that time period.{p_end}

{pstd}After calculating the statistics the command generates a new .csv file and saves it in the {cmdab:output:folder(}{it:folder_path}{cmd:)}, giving it the same name the file had in the {cmdab:media:folder()}. If the file already exists in the output folder, then the file is skipped. So the only way to add new statistics to already generated files is to use the option {cmd:replace}. Note that this overwrites any manual edits made to the files after they were generated by this command.{p_end}

{marker optslong}
{title:Options}

{pstd}{it:{ul:{hi:Required options:}}}{p_end}
{phang}{cmdab:media:folder(}{it:string}{cmd:)} indicates where the .csv files exported from the SurveyCTO server are saved. This is called the media folder because that is the name of the folder where SurveyCTO Sync, SurveyCTO's desktop export tool, saves these files. Other files not relevant to this command may also be stored in this folder as this command can tell which files are sensor stream files based on the file name.{p_end}

{phang}{cmdab:output:folder(}{it:string}{cmd:)} indicates where the newly generated csv files will be saved. This folder should not be the same folder as the folder in {cmdab:media:folder()}. The output folder is used to list which files have already been processed and therefore should be skipped by this command (unless {cmd:replace} is used).{p_end}

{pstd}{it:{ul:{hi:Output options:}}}{p_end}
{phang}{cmdab:keyvar} tells the command to save the uniquely identifying ID key of the submission the sensor stream belongs to in a variable called {it:key} in the new .csv file. The key is always stored in the file name even if this option is not used. This is not the same ID as any ID entered manually by the enumerators in the field. This ID is generated automatically by SurveyCTO for each submission. Multiple submissions might have the same human-entered ID (e.g. if the same respondent is surveyed multiple times for a panel survey) but each such submission will have a unique ID key generated by SurveyCTO. This column is not added by default as that saves disk space and the information is stored in the file name regardless.{p_end}

{phang}{cmdab:replace} makes the command overwrite any files already in the {cmdab:output:folder()} instead of skipping those files. Since this will overwrite the files in the output folder, all manual edits made after the files were originally generated will be lost. Using this option is the only way to update a .csv file already generated by this command.{p_end}

{pstd}{it:{ul:{hi:Standardized Statistics options:}}}{p_end}
{phang}{cmdab:quiet} adds a variable called {it:quiet} to each SL (sound level) sensor stream .csv file. This variable will be 1 for all time periods for which the mean sound level is less than 25dB. For all other non-missing values this variable will be 0. An error will be generated if this option is used and no SL sensor files exist in the {cmdab:media:folder()} folder.{p_end}

{phang}{cmdab:still} adds a variable called {it:still} to each MV (movement) sensor stream .csv file. This variable will be 1 for all time periods for which the mean movement is less than 0.25 m/s^2. For all other non-missing values this variable will be 0. An error will be generated if this option is used and no MV sensor files exist in the {cmdab:media:folder()} folder.{p_end}

{phang}{cmdab:moving} adds a variable called {it:moving} to each MV (movement) sensor stream .csv file. This variable will be 1 for all time periods for which the mean movement is greater than 2 m/s^2. For all other non-missing values this variable will be 0. An error will be generated if this option is used and no MV sensor files exist in the {cmdab:media:folder()} folder.{p_end}

{marker customstats}
{pstd}{it:{ul:{hi:Customizable Statistics options:}}}{p_end}
{pstd}All of the following options take a {inp:{it:range_string}} as a value. The {it:range_string} is used to indicate the name of the new variable this command should create and for which range this variable should be 1 for each time period. The new variable is 0 for all other non-missing values. Each new variable in the {it:range_string} must be specified as: {inp:{it:varname}({it:min max})}, where {it:varname} is the name of the new variable to be created and {it:min} and {it:max} are the lower and upper boundaries for the range. Round brackets indicate that the boundary is exclusive, and straight brackets indicate it is inclusive. One of min or max can be replaced with a question mark to have a greater-than or less-than expression instead of a range. Multiple new variables can be specified in the same {it:range_string}. See examples below.{p_end}

{phang}{cmdab:llbet:ween(}{it:range_string}{cmd:)} allows the user to manually specify statistics for the light level stream. See documentation on {it:range_string} above and examples below. An error will be generated if this option is used and no light level sensor files exist in the {cmdab:media:folder()} folder.{p_end}

{phang}{cmdab:slbet:ween(}{it:range_string}{cmd:)} allows the user to manually specify statistics for the sound level stream. See documentation on {it:range_string} above and examples below. An error will be generated if this option is used and no sound level sensor files exist in the {cmdab:media:folder()} folder.{p_end}

{phang}{cmdab:spbet:ween(}{it:range_string}{cmd:)} allows the user to manually specify statistics for the sound pitch stream. See documentation on {it:range_string} above and examples below. An error will be generated if this option is used and no sound pitch sensor files exist in the {cmdab:media:folder()} folder.{p_end}

{phang}{cmdab:mvbet:ween(}{it:range_string}{cmd:)} allows the user to manually specify statistics for the movement stream. See documentation on {it:range_string} above and examples below. An error will be generated if this option is used and no movement sensor files exist in the {cmdab:media:folder()} folder.{p_end}

{pstd}{ul:range_string examples:}{p_end}

{phang}{inp:llbetween(}{it:indoors_lit(100 750)}{inp:)} will create a variable in light level stream files named {it:indoors_lit} that is 1 for each time period where the mean light level was between 100 lux (exclusive) and 750 lux (exclusive).{p_end}

{phang}{inp:slbetween(}{it:quiet(? 25)}{inp:)} will create a variable in sound level stream files named {it:quiet} that is 1 for each time period where the mean sound level was below 25 dB (exclusive). This is identical to the variable created when using option {inp:quiet}.{p_end}

{phang}{inp:mvbetween(}{it:mv1[.2 .25) mv2[1 ?]}{inp:)} will create two variables in movement stream files named {it:mv1} and {it:mv2}. {it:mv1} will be 1 for each time period where the mean movement is between .2  m/s^2 (inclusive) and .25 m/s^2 (exclusive). {it:mv2} will be 1 for each time period where the mean movement is greater than 1 m/s^2 (inclusive).{p_end}

{marker examples}
{title:Examples}

{pstd}All examples will use the following globals as folder paths:{p_end}

{pstd}{inp:global project "}C:\Users\username\Documents\ProjectA{inp:"}{p_end}
{pstd}{inp:global media "}$project\raw_data\media{inp:"}{p_end}
{pstd}{inp:global output "}$project\outputs{inp:"}{p_end}

{pstd}{hi:Example 1.}{p_end}

{pstd}{inp:sctostreamcsv, mediafolder(}{it:"$media"}{inp:) outputfolder(}{it:"$output"}{inp:) quiet still}{p_end}

{pstd}This is a very simple way to run the command. The command will read sensor stream .csv files in the media folder with the prefix SL (because {inp:quiet} was used) and the prefix MV (because {inp:still} was used) and create the {it:quiet} variable in the SL files and the {it:still} variable in the MV files and save the new files in the output folder. If a file already exists in the output folder then it is skipped. Any sensor stream files with prefix SP or LL in the media folder will be ignored as no statistic applicable to either of those streams was specified.{p_end}

{pstd}{hi:Example 2.}{p_end}

{pstd}{inp:sctostreamcsv, mediafolder(}{it:"$media"}{inp:) outputfolder(}{it:"$output"}{inp:) quiet slbetween(}{it:loud(60 ?)}{inp:) replace}{p_end}

{pstd}In this example, the command will only read SL sensor stream .csv files from the media folder as sound level is the only sensor for which statistics are specified. The {it:quiet} and {it:loud} variables will be added to all SL files in the media folder. Any files in the output folder already in the output folder will be overwritten if the corresponding original file is still in the media folder.{p_end}

{title:Author}

{phang}This command was developed by {browse "https://www.surveycto.com/about/contact/":SurveyCTO}.{p_end}

{phang}See this command's {browse "https://github.com/surveycto/scto":repository} for more information where you can also submit feedback and feature requests.{p_end}
