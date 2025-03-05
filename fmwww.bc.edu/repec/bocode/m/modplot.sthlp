{smcl}
{* 14 March 2024}{...}
{hline}
help for {hi:modplot}
{hline}


{title:Title}

{p 4 16 2}
{hi:modplot} —— Plotting graphs of moderating effects.{p_end}


{title:Syntax}

{p 4 13 2}
{cmdab:modplot}, 
{cmdab:m:odel:}{cmd:(}command dependentvar independentvar moderatevar controlvars, options{cmd:)}
[
{cmdab:p:lot:}
{cmdab:d:ot:}
{cmdab:r:ight:}
{cmdab:s:cheme:}{cmd:(}{help scheme intro:schemename}{cmd:)}
{cmd:other_opts}
]{p_end}


{title:Description}

{p 8 4 2}
The modplot will help you plot the moderating effects in one click, 
but you need to be aware that the picture will only be available if 
you have used the {it:plot} option. Otherwise the default will only store the 
equation for the moderating effect in the return value.
{p_end}


{title:Options}

{phang}
{cmdab:m:odel}{hi:(command dependentvar independentvar moderatevar controlvars, options)} 
specifies your regression model. Note that this command does not support 
{hi:{it:if}} and {hi:{it:in}}, and also automatically records the second 
variable in your model as the independent variable and the third variable 
as the moderator variable.
{p_end}

{phang}
{cmdab:p:lot:} specifies whether the corresponding moderating effects 
need to be plotted.
{p_end}

{phang}
{cmdab:d:ot:} specifies whether solid points need to be added to the 
ends of the line graph in the image.
{p_end}

{phang}
{cmdab:r:ight:} specifies whether the legend needs to be placed to the 
right of the image.
{p_end}

{phang}
{cmdab:s:cheme:}{cmd:(}{help scheme_option:{bf:}{it:schemename}}{cmd:)} 
Specifies the drawing style of the image. You can click on the blue 
hyperlinks to see the styles available for your Stata.
{p_end}

{phang}
{cmd:other_opts} you can add other plotting options here, such as {cmd:title("this is a title")}
{p_end}


{title:Results}

{p 8 4 2}
After running {hi:modplot}, the marginal equations for the moderating 
effects will be recorded in the return values, which you can view using 
the return list. Also, if you use the {it:plot} option, then a plot of the 
moderating effects will be generated. Note that the {it:dot} option, the 
{it:right} option, and the {it:scheme} option are used to further embellish the picture.
{p_end}


{title:Code examples}

{p 4 4 2} *- Both the independent and moderator variable are binary variables. {p_end}
{p 4 4 2}{inp:-} 
{stata `"sysuse bplong.dta, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"modplot, model(reg bp sex when agegrp, vce(r)) plot dot scheme(s1mono)"'}
{p_end}

{p 4 4 2} *- The independent variable is a binary variable but the moderator 
variable is a continuous variable. {p_end}
{p 4 4 2}{inp:-} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"modplot, model(reg price foreign length weight, vce(r)) plot dot scheme(s1mono)"'}
{p_end}

{p 4 4 2} *- The independent variable is a continuous variable but the moderator 
variable is a binary variable. {p_end}
{p 4 4 2}{inp:-} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"modplot, model(reg price length foreign weight, vce(r)) plot dot scheme(s1mono)"'}
{p_end}

{p 4 4 2} *- Both the independent and moderator variable are continuous variables. {p_end}
{p 4 4 2}{inp:-} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"modplot, model(reg price weight length foreign, vce(r)) plot dot scheme(s1mono)"'}
{p_end}

{p 4 4 2} *- Other plotting options (added by Professor Christopher F. Baum) {p_end}
{p 4 4 2}{inp:-} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"modplot, model(reg price foreign length weight, vce(r)) plot ti("Effects of length")"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"modplot, model(reg price foreign length weight, vce(r)) plot ti("Effects of length", box) legend(rows(1) size(small))"'}
{p_end}

{p 4 4 2} *- Additionally, you can use other regression estimators for regression. 
{it:modplot} theoretically supports regression methods where all coefficients 
are stored in the {it:e(b)} matrix and with coefficient term.
{p_end}


{title:Author}

{p 4 4 2}
{cmd:Basic information}{break}
Name: Shutter Zor (左祥太){break}
Affiliation: Accounting Department, Xiamen University.{break}
E-mail: {browse "mailto:Shutter_Z@outlook.com":Shutter_Z@outlook.com} {break}

{p 4 4 2}
{cmd:Other information}{break}
Blog: {browse "https://shutterzor.cn/":blog link} {break}
Bilibili: {browse "https://space.bilibili.com/40545247/":拿铁一定要加冰} {break}
WeChat Official Account: {browse "https://shutterzor.cn/images/QRcode.png":OneStata} {break}

{title:Other commands i have written}

{pstd}

{synoptset 30 }{...}
{synopt:{help oneclick} (if installed)} {stata ssc install oneclick} (to install){p_end}
{synopt:{help onetext} (if installed)} {stata ssc install onetext} (to install){p_end}
{synopt:{help econsig} (if installed)} {stata ssc install econsig} (to install){p_end}
{synopt:{help wordcloud} (if installed)} {stata ssc install wordcloud} (to install){p_end}
{p2colreset}{...}


{title:Acknowledgments}

{p 4 4 2}
Thanks to Bilibili users (导导们). Thanks to Professor Christopher F. Baum for the 
information that gave me a better understanding of Stata programming.
{p_end}


