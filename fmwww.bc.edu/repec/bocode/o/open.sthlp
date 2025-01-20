{smcl}

{cmd:help open {stata "help open_cn": 中文版本}}

{hline}

{title:help open}

{hline}

{title:Title}
    {phang}open -- Open the current working directory and copy the path to clipboard

{title:Syntax}
    {phang}{cmd:open}

{title:Description}
    {phang}The {cmd:open} command performs the following actions:{p_end}
    {p 8 12 2}1. Opens the current working directory in the system's default file explorer.{p_end}
    {p 8 12 2}2. Copies the path of the current working directory to the system clipboard.{p_end}
    {p 8 12 2}3. Displays the current working directory in the results window as a clickable hyperlink.{p_end}
    {p 8 12 2}4. Outputs the full path of the current working directory in plain text.{p_end}

{title:Usage Notes}
    {phang}- Quickly access the Stata working directory from your system's file explorer.{p_end}
    {phang}- Paste the copied path into other tools using Ctrl+V or equivalent.{p_end}

{title:Examples}
    {phang}*-This command opens the current working directory in the file explorer.{p_end}
    {phang}{stata "open"}{p_end}


{title:Author}

{phang}
{cmd:Wang Qiang} ,   Xi’an Jiaotong University, China.{break}
E-mail: {browse "740130359@qq.com":740130359@qq.com}. {break}
{p_end}

{marker alsosee}{...}
{title:alsosee}

{psee}  Help：{help cnuse}, {help topsis}{p_end}

{title:Acknowledgments}
    {phang}This command leverages external system commands for clipboard and file explorer interaction.{p_end}


