{smcl}
{* Help file for log2md}
{hline}

{cmd:help log2md_cn}    {browse "help log2md":英文版本}

{hline}

{title:标题}

{phang}
{cmd:log2md} - 生成带有自定义功能（如标题、代码块包裹）的 Markdown 格式日志。

{marker s_Syntax}
{title:语法}

{phang}
{cmd:log2md} {it:filename} [{cmd:,} {opt replace} {opt append} {opt title(string)}]

{marker s_Options}
{title:选项}
{dlgtab:Main Options}

{phang}{opt replace}  如果文件已存在，覆盖现有文件，不能与 {cmd:append} 一起使用。{p_end}

{phang}{opt append}   将新内容附加到现有文件，不能与 {cmd:replace} 一起使用。{p_end}

{phang}{opt title(string)} 为日志文件添加自定义标题。{cmd:string} 是用户定义的标题。{p_end}

{marker s_Description}
{title:描述}

{phang}
{cmd:log2md} 命令生成 Markdown 格式的日志文件，所有命令输出都包装在代码块中，适合在 Markdown 平台（如 GitHub 或 Jupyter Notebooks）中阅读和共享。
{p_end}

{phang}
通过该命令，用户可以轻松记录日志内容，包括自定义标题、时间戳和日志模式（替换或追加）。
{p_end}

{marker s_UsageNotes}
{title:使用说明}

{phang}
- 日志文件以 Markdown 格式创建，包含时间戳、标题等信息，内容被包装在代码块中。{p_end}

{phang}
- {cmd:log close} 用于关闭日志文件，完成写入操作。{p_end}

{phang}
- 如果未指定 {opt replace} 或 {opt append}，默认使用 {opt replace} 格式。{p_end}

{phang}
- 使用 {opt append} 时，指定的文件必须存在，否则会报错。{p_end}

{phang}
- 分隔符默认为 `---`，相当于 Markdown 的分隔线。{p_end}

{phang}
- {stata log2md }进行代码块包裹的逻辑为：在进行自定义标题等输入后，将默认以分隔符`---`对log工作日志进行分隔。

{phang}
- 并在起始位置以“```”作为标志，对log日志内容进行代码块包裹，以log close表示关闭日志。

{phang}
- 当采用append选项追加时，将自动检查，对上一次log日志进行代码块包裹结束补齐。

{phang}
- 采用replace选项时，代码块包裹将只有起始位置有“```”{p_end}

{marker s_Examples}
{title:Examples}

{phang}{it:Examples 1} - 创建一个新日志文件并使用自定义标题：{p_end}

{phang2}{stata log2md mylog.md, replace title("我的分析")}{p_end}

{phang2}{stata sysdir}{p_end}

{phang2}{stata sysuse auto, clear}{p_end}

{phang2}{stata describe}{p_end}

{phang2}{stata log close}{p_end}

    - 下述{stata open2}命令需要进行下载，当然你也可以手工打开该Markdown文件
	
{phang2}{stata open2 mylog.md}{p_end}

{phang2}{stata shellout mylog.md}{p_end}


{phang}{it:Examples 2} - 将新内容附加到现有日志文件.

{phang2}{stata log2md mylog.md, append title("附加结果")}{p_end}

{phang2}{stata set more on }{p_end}

{phang2}{stata set more off}{p_end}

{phang2}{stata dir}{p_end}

{phang2}{stata sysdir}{p_end}

    - 下述{stata open}命令需要进行下载。{stata open}命令可以列出并打开当前工作路径，并将当前工作目录的路径复制到系统剪贴板
	
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

{psee}  Help:{help cnuse}, {help topsis}{p_end}



