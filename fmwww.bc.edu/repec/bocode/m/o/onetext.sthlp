{smcl}
{* 13 July 2022}{...}
{hline}
help for {hi:onetext}
{hline}


{title:Title}
{p 4 4 2}
{bf:onetext} —— Help you do some simple Chinese text analysis.{p_end}


{title:Syntax}
{p 4 4 2}
{cmdab:onetext} {varlist}, [{cmdab:k:eyword:}{cmd:(}string{cmd:)}]
{cmdab:m:ethod:}{cmd:[}count/exist/cosine/jaccard{cmd:]}
{cmdab:g:enerate:}{cmd:(}real{cmd:)}
{p_end}


{title:Description}
{p 4 4 2}
{cmd:onetext} By entering your variable/variables, the {it:onetext} command
helps you to do some simple Chinese text analysis. It can simply count the 
occurrence frequency of a specified Chinese character in Chinese text through 
{it:method(count)}, or observe whether it appears through {it:method(exist)}.
When you have a vector of text, you can use {it:method(cosine)} and {it:method(jaccard)} 
to calculate cosine similarity and jaccard similarity respectively.
{p_end}


{title:Requirements}
{p 4 4 2}
{cmd:varlist(}{it:varname}{cmd:)} specifies the variables. When you want to 
observe whether Chinese words appear or count word frequencies, you are required 
to specify the variable as text, and only one variable can be specified. When 
you want to calculate cosine similarity or jaccard similarity, you need both 
variables to be numerical types that can be calculated.
{p_end}{break}
{p 4 4 2}
{cmd:keyword(}{it:string}{cmd:)} specify the Chinese characters you want to 
look for, such as "大数据". Noting that this item is required when you need 
to count words.
{p_end}{break}
{p 4 4 2}
{cmd:method(}{it:count/exist/cosine/jaccard}{cmd:)} specifies the way you want 
to use. Arguments other than the given characters are not allowed.
{p_end}{break}
{p 4 4 2}
{cmd:generate(}{it:varname}{cmd:)} specifies a variable to save the result.
{p_end}


{title:Examples1 - Find Chinese words.}
{p 4 4 2}{inp:.} 
{stata `"clear"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"set obs 4"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"gen text = "大数据" in 1"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace text = "大数据大数据" in 2"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace text = "数据小数据" in 3"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace text = "小数据" in 4"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"onetext text, k("大数据") m(count) g(count_text) "'}
{p_end}

{title:Examples1 - Existence of Chinese words.}
{p 4 4 2}{inp:.} 
{stata `"clear"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"set obs 4"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"gen text = "大数据" in 1"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace text = "大数据大数据" in 2"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace text = "数据小数据" in 3"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace text = "小数据" in 4"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"onetext text, k("大数据") m(exist) g(isExist) "'}
{p_end}

{title:Examples1 - Similarity calculation.}
{p 4 4 2}{inp:.} 
{stata `"clear"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"set obs 3"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"gen var1 = 1 in 1"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace var1 = 2 in 2"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace var1 = 3 in 3"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"gen var2 = 4 in 1"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace var2 = 2 in 2"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"replace var2 = 5 in 3"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"onetext var1 var2, m(cosine) g(cs) "'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"onetext var1 var2, m(jaccard) g(js) "'}
{p_end}

{title:Author}
{p 4 4 2}
{cmd:Shutter Zor(左祥太)}{break}
School of Accountancy, Wuhan Textile University.{break}
E-mail: {browse "mailto:Shutter_Z@outlook.com":Shutter_Z@outlook.com}. {break}