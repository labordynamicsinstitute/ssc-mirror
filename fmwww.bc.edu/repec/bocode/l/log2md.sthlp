{smcl}
{cmd:help log2md {stata "help log2md_cn": 中文版本}}
{hline}

{title:log2md}
{hline}

{title:Title}
    {p2colset 5 15 22 2}{...}
    {p2col :{hi: log2md} {hline 2}}Creates enhanced logs in Markdown format with customizable features like titles, separators, and code block wrapping.{p_end}

{marker s_Syntax}
{title:Syntax}
    {p 4 10 6}
    {cmd:log2md} {it:filename} [{cmd:,} {opt replace} {opt append} {opt title(string)} ]

{marker s_Options}
{title:Options}

{dlgtab:Main}
    {p 4 12 6}{opt replace}: Overwrite the existing file if it already exists. Cannot be used with {cmd:append}. {p_end}
    {p 4 12 6}{opt append}: Append new content to an existing file. Cannot be used with {cmd:replace}. {p_end}
    {p 4 12 6}{opt title(string)}: Adds a custom title to the log file. Replace {cmd:string} with your desired title. {p_end}


{marker s_Description}
{title:Description}

{phang}
The {cmd:log2md} command generates a Markdown-formatted log file. All command outputs are wrapped in code blocks, making them ideal for sharing on Markdown platforms such as GitHub or Jupyter Notebooks.
{p_end}

{phang}
This command allows users to record logs easily, including custom titles, timestamps, and log modes (replace or append).
{p_end}

{marker s_UsageNotes}
{title:Usage Notes}

{phang}
- The log file is created in Markdown format and includes information such as timestamps, titles, and content wrapped in code blocks.{p_end}

{phang}
- Use {cmd:log close} to close the log file and complete the writing process.{p_end}

{phang}
- If neither {opt replace} nor {opt append} is specified, the default is {opt replace}.

{phang}
- When using {opt append}, the specified file must exist; otherwise, an error will occur.{p_end}

{phang}
- The default separator is `---`, which corresponds to a Markdown horizontal line.{p_end}

{phang}
- The {stata log2md} logic for code block wrapping is as follows: After custom title input, the log content will be separated by the default `---` separator and wrapped in code blocks starting with “```”. The log ends with {cmd:log close}.

{phang}
- When using the {opt append} option, the command will automatically check and ensure proper code block wrapping for the previous log.{p_end}

{phang}
- When using the {opt replace} option, only the beginning of the log will include the “```” code block marker.{p_end}

{marker s_Examples}
{title:Examples}

{phang}{it:Example 1} - Create a new log file with a custom title:{p_end}

{phang2}{stata log2md mylog.md, replace title("My Analysis")}{p_end}

{phang2}{stata sysdir}{p_end}

{phang2}{stata sysuse auto, clear}{p_end}

{phang2}{stata describe}{p_end}

{phang2}{stata log close}{p_end}

    - The following {stata open2} command requires downloading, or you can manually open the Markdown file:
	
{phang2}{stata open2 mylog.md}{p_end}

{phang2}{stata shellout mylog.md}{p_end}

{phang}{it:Example 2} - Append new content to an existing log file:{p_end}

{phang2}{stata log2md mylog.md, append title("Additional Results")}{p_end}

{phang2}{stata set more on }{p_end}

{phang2}{stata set more off}{p_end}

{phang2}{stata dir}{p_end}

{phang2}{stata sysdir}{p_end}

    - The following {stata open} command requires downloading. 
	
    - The {stata open} command lists and opens the current working directory and copies the directory path to the system clipboard:
	
{phang2}{stata sysuse auto, clear}{p_end}

{phang2}{stata open}{p_end}
       
{phang2}{stata log close}{p_end}

{phang2}{stata open2 mylog.md}{p_end}

{title:Author}

{phang}
{cmd:Wang Qiang} ,   Xi’an Jiaotong University, China.{break}

    E-mail: {browse "740130359@qq.com":740130359@qq.com}. {break}
{marker alsosee}{...}

{title:also see}

{psee} Help:{help cnuse}, {help topsis}{p_end}



