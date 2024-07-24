{smcl}
{* 23 July 2024}{...}
{hline}
help for {hi:wordcloud}
{hline}


{title:Title}

{p 4 4 2}
{hi:wordcloud} —— Program for drawing word cloud figure based on {it:echarts} developed by Baidu.{p_end}


{title:Syntax}

{p 4 4 2}
{cmdab:wordcloud}, 
{cmdab:n:ame:}{cmd:(}{it:varname}{cmd:)}
{cmdab:v:alue:}{cmd:(}{it:varname}{cmd:)}
{cmdab:f:ile:}{cmd:(}{it:filename.html}{cmd:)}
[
{cmdab:t:itle:}{cmd:(}{it:string}{cmd:)}
{cmdab:l:abel:}{cmd:(}{it:string}{cmd:)}
]
{p_end}


{title:Description}

{p 4 4 2}
{cmd:wordcloud} is a program for drawing word clouds based on changes made to 
echarts for the Stata programming style. It relies heavily on the versatility 
and interactivity of {bf:HTML} mapping. Note that since the final {bf:HTML} file 
generated contains online scripts, you need to make sure that your computer 
is connected to the Internet, otherwise you may not be able to load the final image.
{p_end}

{p 4 4 2}
In addition, you can refer to the official website of echarts for more settings 
on chart detail options. Since the final image file is saved in {bf:HTML} format, 
make sure you have sufficient knowledge of {bf:HTML} or intuition of the programming 
language before making changes.
{it:{browse "https://echarts.apache.org/en/index.html" :-Link-}}
{p_end}


{title:Requirements}

{p 4 4 2}
{cmdab:n:ame:}{cmd:(}{it:varname}{cmd:)} This variable is used to specify 
specific text, such as in a word cloud map composed of word frequencies, and 
this variable should be used to specify specific words.
{p_end}

{p 4 4 2}
{cmdab:v:alue:}{cmd:(}{it:varname}{cmd:)} This variable is used to specify 
the size of the specific value corresponding to the text, which should be 
of numeric type. For example, in a word cloud map composed of word frequencies, 
this variable should be used to specify the frequency of occurrence of words.
{p_end}

{p 4 4 2}
{cmdab:f:ile:}{cmd:(}{it:filename.html}{cmd:)} This variable is used to specify 
the name and path of the saved file. For example, if you specify it as 
{it:"a.html"}, then the final graphics file will be stored in the current 
Stata working path. Of course, you can also specify any other path.
{p_end}

{p 4 4 2}
{cmdab:t:itle:}{cmd:(}{it:string}{cmd:)} This is an optional option, usually 
used to specify the title of the generated image, which will be displayed on 
the left at the top of the page.
{p_end}

{p 4 4 2}
{cmdab:l:abel:}{cmd:(}{it:string}{cmd:)} This is an option that is usually 
used to specify the label that is displayed after hovering over text in html.
{p_end}


{title:Results}

{p 4 4 2}
After running {hi:wordcloud}, You will get an html file, please note where the 
html file is stored. If you can't load this html file, please refresh the web 
page after networking.
{p_end}


{title:Examples}

{p 4 4 2} *- Generating Sample Data {p_end}

{p 4 4 2}{inp:.} 
{stata `"clear"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"set obs 12"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"gen name = "你好" in 1"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace name = "Hello" in 2"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace name = "Привет " in 3"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace name = "こんにちは" in 4"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace name = "안녕하세요" in 5"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace name = "Bonjour" in 6"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace name = "Hallo" in 7"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace name = "مرحب" in 8"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace name = "¡¡Buenas!" in 9"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace name = "здравей" in 10"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace name = "Γεια σου" in 11"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace name = "สวัสดีครับ" in 12"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"gen value = 1000 in 1"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace value = int(runiform()*1000) if value == ."'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"wordcloud, n(name) v(value) f("test.html")"'}
{p_end}


{title:Author}

{p 4 4 2}
{cmd:Shutter Zor(左祥太)}{break}
Accounting Department, Xiamen University{break}
E-mail: {browse "mailto:Shutter_Z@outlook.com":Shutter_Z@outlook.com}{break}


