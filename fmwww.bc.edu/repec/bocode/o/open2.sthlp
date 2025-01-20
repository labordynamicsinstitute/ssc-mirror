{smcl}

{cmd:help open2 {stata "help open2_cn": 中文版本}}


{title:Title}

    {hi:open2} — Open files, directories, or execute commands across platforms

{title:Syntax}

    {cmd:open2} [{it:anything}] [{cmd:using/}] [, {cmd:cd}]

{title:Description}

    {pstd}{cmd:open2} is a versatile command that opens files, directories, or executes system commands. It automatically detects the operating system (Windows, macOS, or others) and applies the appropriate logic to handle the request.

{title:Options}
    {phang}{opt cd}
        Opens the current working directory in the system's file explorer.

{title:Remarks}
    {pstd}If no {cmd:using} or {cmd:cd} is specified, {cmd:open2} will attempt to execute the given command or open the specified file/application directly.{p_end}
    {pstd}The command determines the operating system using Stata's {cmd:c(os)} macro and applies platform-specific behavior.{p_end}

{title:Examples}
    {phang}{bf:Open a file or application (Windows):}{p_end}
    {cmd:. open2 using "C:\path\to\yourfile.txt"}

    {phang}{bf:Change directory and open it in file explorer:}{p_end}
    {cmd:. open2 , cd}

    {phang}{bf:Execute a command (e.g., open an application):}{p_end}
    {cmd:. open2 "notepad"}

    {phang}{bf:Open a file on macOS:}{p_end}
    {cmd:. open2 using "/path/to/yourfile.txt"}

{title:Examples2}

    *- Open a txt file
    {phang}{stata "open2 门槛回归结果.txt"}{p_end}
    
    *- Open a csv file
    {phang}{stata "open2 auto.csv"}{p_end}
    
    *- Open a Word file
    {phang}{stata "open2 门槛回归结果.doc"}{p_end}
    
    *- Open a pdf file
  {phang}{stata "open2 C:\Users\Metrics\Desktop\Stata命令汇总表.pdf"}{p_end}
    {phang}{stata "open2 D:\Stata16\Stata16\bcuse\enwei.pdf"}{p_end}
	
	
	
    *- Open a markdown file
    {phang}{stata "open2 什么叫图床.md"}{p_end}
	
    *- Open a web page
      {phang}{stata "open2 常用链接.html"}{p_end}
    
    *- Open the current directory defined by cd
   {phang}{stata "open2 ,cd"}{p_end}
   
    *- Open an application
    {phang}{stata "open2 D:\Stata16\Stata16\StataSE-64.exe"}{p_end}


{title:Details}
    {pstd}{cmd:open2} processes the request as follows:{p_end}
    {phang}{ul:Windows:}{p_end}
    {pstd}- Uses {cmd:winexec} to execute commands, open files, or applications.{p_end}
    {pstd}- Opens the file explorer if {cmd:cd} is specified.{p_end}
    {phang}{ul:macOS:}{p_end}
    {pstd}- Uses {cmd:shell open} to open files, directories, or applications.{p_end}
    {pstd}- Opens Finder if {cmd:cd} is specified.{p_end}
    {phang}{ul:Other operating systems:}{p_end}
    {pstd}- Attempts to execute the command using {cmd:shell}.{p_end}


{title:Author}
{phang}

  {cmd:Wang Qiang} ,   Xi’an Jiaotong University, China.{break}
  
  E-mail: {browse "740130359@qq.com":740130359@qq.com}. {break}


{marker also see}{...}

{title:also see}

{psee}在线帮助：{help cnuse}, {help topsis}, {help open}, {help open2}{p_end}

	
	