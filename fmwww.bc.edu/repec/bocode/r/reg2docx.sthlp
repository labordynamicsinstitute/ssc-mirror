﻿{smcl}
{* 14July2017}{...}
{hi:help reg2docx}
{hline}

{title:Title}

{phang}
{bf:reg2docx} {hline 2} Report regression results to formatted table in DOCX file.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:reg2docx} {it:modellist} {it:using filename} {cmd:,} [{it:options}]

{marker description}{...}
{title:Description}

{pstd}
{cmd:reg2docx} is used after {cmd:est store}. Users can estimate different regression models. After that they can save the regression results with {cmd:est store} command.
Then, users can call {cmd:reg2docx} to design a formatted table output for all the saved models to a docx file.
The docx file can be appended to other docx files generated by {cmd:putdocx}, {cmd:sum2docx}, {cmd:t2docx} and {cmd:corr2docx},
either using the {it:append} option or the command can be as following: {p_end}

{phang}
{stata `"putdocx append d:/mytable0.docx d:/mytable1.docx d:/mytable2.docx, saving(d:/mytable.docx,replace)"'}
{p_end}

{marker options}{...}
{title:Options for reg2docx}

{phang}
{opt replace} permits to overwrite an existing file. {p_end}

{phang}
{opt append} permits to append the output to an existing file. {p_end}

{phang}
{opt title(string)} specify the title of the table. The default is title("Regression Table"). {p_end}

{phang}
{opt pagesize(psize)} sets the page size of the document. {it:psize} may be letter, legal, A3, A4, or B4JIS.  The default is pagesize(A4). {p_end}

{phang}
{opt font(fontname[, size[, color]])} sets the font, font size, and font color for the document. Note that the font size and font color may be specified individually without specifying fontname.
Use font("", size) to specify font size only. Use font("", "", color) to specify font color only. The default is font("Times New Roman"). {p_end}

{phang}
{opt landscape} changes the document orientation from portrait to landscape. {p_end}

{phang}
{opt note(string)} adds notes under the table. {p_end}

{phang}
{opt b(string)} specify format for coefficient. {p_end}

{phang}
{opt t}{opt [}{opt (fmt)}{opt ]} output t-statistics and specify the format. {p_end}

{phang}
{opt z}{opt [}{opt (fmt)}{opt ]} output z-statistics and specify the format. {p_end}

{phang}
{opt p}{opt [}{opt (fmt)}{opt ]} output p-values and specify the format. {p_end}

{phang}
{opt se}{opt [}{opt (fmt)}{opt ]} output standard error and specify the format. {p_end}

{phang}
{opt scalars(scalarlist)} specify the scalars to be output. Including all the scalars you can get in ereturn list after a regression command. The format of the scalar is defined in parentheses after the scalar.(e.g. r2(%9.2f), %9.3f by default) {p_end}

{phang}
{opt noconstant} do not output intercept. {p_end}

{phang}
{opt constant} output intercept. {p_end}

{phang}
{opt noobs} do not output the number of observations. {p_end}

{phang}
{opt nostar} do not output significance stars. {p_end}

{phang}
{opt star}{opt [}{opt (symbol level [...])}{opt ]} output significance of the coefficients. {p_end}

{phang}
{opt staraux} the significance stars be printed next to the t-statistics (or standard errors, etc.) instead of the coefficient. {p_end}

{phang}
{opt mtitles(titlelist)} specift model's title in the table header. {p_end}

{phang}
{opt nomtitle} suppresses printing of model titles. {p_end}

{phang}
{opt depvar} prints the name of the dependent variable of a model as the model's title in the table header. {p_end}

{phang}
{opt order(list)} change order of coefficients. {p_end}

{phang}
{opt indicate(groups)} indicate presence of parameters. {p_end}

{phang}
{opt drop(droplist)} drop individual coefficients. {p_end}

{phang}
{opt noparentheses} do not print parentheses around t-statistics. {p_end}

{phang}
{opt parentheses} print parentheses around t-statistics. {p_end}

{phang}
{opt brackets} use brackets instead of parentheses. {p_end}

{marker example}{...}
{title:Example}

{pstd}

{phang}
{stata `"clear"'}
{p_end}

{phang}
{stata `"set obs 1000"'}
{p_end}

{phang}
{stata `"gen x1 = uniform()"'}
{p_end}

{phang}
{stata `"gen x2 = uniform()"'}
{p_end}

{phang}
{stata `"gen x3 = uniform()"'}
{p_end}

{phang}
{stata `"gen x4 = uniform()"'}
{p_end}

{phang}
{stata `"gen x5 = uniform()"'}
{p_end}

{phang}
{stata `"gen x6 = uniform()"'}
{p_end}

{phang}
{stata `"gen ind = mod(_n,10)"'}
{p_end}

{phang}
{stata `"tab ind, gen(ind)"'}
{p_end}

{phang}
{stata `"gen y = 0.4+.5*x1+.6*x2+.7*x3+.8*x4+rnormal()*3"'}
{p_end}

{phang}
{stata `"replace y = y-.7*x5-.8*x6"'}
{p_end}

{phang}
{stata `"forvalue i = 1(1)10 {c -(}"'}
{p_end}

{phang}
{stata `"    replace y = y+sqrt(`i')*ind`i'"'}
{p_end}

{phang}
{stata `"{c )-}"'}
{p_end}

{phang}
{stata `"reg y x1 x5 x6 ind2-ind10"'}
{p_end}

{phang}
{stata `"est store m1"'}
{p_end}

{phang}
{stata `"reg y x1 x2  x5 x6 ind2-ind10"'}
{p_end}

{phang}
{stata `"est store m2"'}
{p_end}

{phang}
{stata `"reg y x1 x2 x3  x5 x6 ind2-ind10"'}
{p_end}

{phang}
{stata `"est store m3"'}
{p_end}

{phang}
{stata `"reg y x1 x2 x3 x4 x5 x6 ind2-ind10"'}
{p_end}

{phang}
{stata `"est store m4"'}
{p_end}

{phang}
{stata `"reg2docx m1 m2 m3 m4 using d:/mytable2.docx, replace indicate("ind=ind*") drop(x2 x3) scalars(N r2(%9.3f) r2_a(%9.2f)) order(x6 x5) b(%9.3f) t(%7.2f) title(table2: OLS regression results) mtitles("model 1" "model 2" "" "model 4")"'}
{p_end}

{title:Author}

{pstd}Chuntao LI{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}chtl@zuel.edu.cn{p_end}

{pstd}Yuan XUE{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}xueyuan19920310@163.com{p_end}



{title:Also see}

{synoptset 30 }{...}
{synopt:{help sum2docx} (if installed)} {stata ssc install sum2docx} (to install){p_end}
{synopt:{help t2docx} (if installed)} {stata ssc install t2docx} (to install){p_end}
{synopt:{help corr2docx} (if installed)} {stata ssc install corr2docx} (to install){p_end}
{p2colreset}{...}

