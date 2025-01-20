{smcl}
{cmd:help open_cn {stata "help open": 英文版本}}

{hline}

{title:help open}

{hline}


{title:Title}
    {phang}open -- 打开当前工作目录并将路径复制到剪贴板

{title:Syntax}
    {phang}{cmd:open}

	
{title:Description}
    {phang}{cmd:open} 命令执行以下操作：{p_end}
    {p 8 12 2}1. 在系统默认的文件资源管理器中打开当前工作目录。{p_end}
    {p 8 12 2}2. 将当前工作目录的路径复制到系统剪贴板。{p_end}
    {p 8 12 2}3. 在结果窗口中以可点击的超链接形式显示当前工作目录。{p_end}
    {p 8 12 2}4. 以纯文本形式输出当前工作目录的完整路径。{p_end}

	
{title:Usage Notes}
    {phang}- 通过系统的文件资源管理器快速访问 Stata 工作目录。{p_end}
    {phang}- 使用 Ctrl+V 或等效操作将复制的路径粘贴到其他工具中。{p_end}

{title:Examples}
    {phang}*-此命令在文件资源管理器中打开当前工作目录。{p_end}
	{phang}{stata "open"}{p_end}
  
  
{title:Author}

{phang}
{cmd:Wang Qiang} ,   Xi’an Jiaotong University, China.{break}

    E-mail: {browse "740130359@qq.com":740130359@qq.com}. {break}

{marker alsosee}{...}
{title:另见}

{psee}在线帮助：{help cnuse}, {help topsis}{p_end}


{title:Acknowledgments}
    {phang}此命令利用外部系统命令进行剪贴板和文件资源管理器的交互。{p_end}

