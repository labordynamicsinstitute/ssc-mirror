{smcl}
{* 16may2025}{...}

{title:Title}

{p 4 4 2}{hi:myreg2} {hline 2} Export formatted regression table to a Word document (Table 2)


{title:Table of contents}

    {help myreg2##syn:Syntax}
    {help myreg2##des:Description}
    {help myreg2##opt:Options}
    {help myreg2##exa:Examples}


{marker syn}
{title:Syntax}

    myreg2 [varname] [, all dp(#) cilimiter(str) title(str) notes(str) model(str) pvalue constant export(str)]

{marker des}
{title:Description}

{p 4 4 2}
{cmd:myreg2}  exports regression results to a Word document after the collection 
command in Stata 17. It is designed for creating tables formatted like Table 2 
in epidemiological journals.  The command combines regression results for a 
sepcific exposure variable or all variables from multiple models into a single Table.
 
{marker opt}
{title:Options}
{marker main}
{dlgtab:Main}

{p 4 8 2}
{cmd:dp(}{it:{help myreg2##fmt:fmt}}{cmd:)} sets the number of decimal points 
for coef(95%CI). The default format is 2. 

{p 4 8 2}
{cmd:ci(}{it:{help myreg2##fmt:str}}{cmd:)} sets the delimiter for 95%CI. 
The default format is -. Common choice can be ci(","), or ci(" to "). 

{p 4 8 2}
{cmd:model(}{it:{help myreg2##fmt:str}}{cmd:)} names each model 
The default format is Model 1; Model 2; Model3. 
Other option can be something like model("Unadjusted" "SES adjusted" "Full model").

{p 4 8 2}
{cmd:pval} requests p values to be shown. When p value is less than 0.001, 
it will be shown as p<0.001 instead of the exact number.

{p 4 8 2}
{cmd:constant} requests constant to be shown. By default, constant is not shown.

{p 4 8 2}
{cmd:all} requests all variables (covariates) in the models to be reported.

{p 4 8 2}
{cmd:note(}{it:{help myreg2##fmt:str}}{cmd:)} provides notes to the table. 

{p 4 8 2}
{cmd:export(}{it:{help myreg2##fmt:str}}{cmd:)} saves table to a word document
 with option of replace or append. example: export(table2.docx,replace)  

{marker exa}
{title:Examples}

{p 4 4 2}
The following examples are intended to illustrate the basic usage of
{cmd:myreg2}.  


        {com}. webuse lbw
        {txt}(Low birth weight data by Hosmer & Lemeshow)
		
        {com}. collect clear
        {txt}(clear stored results)
		
        {com}. collect: quietly logistic low i.smoke
        {txt}(first model results stored)
        
        {com}. collect: quietly logistic low i.smoke i.race age
        {txt}(second model results stored)
        
        {com}. myreg2 i.smoke
        {txt}(combine results of smoking on low birth weight based two logistic regression models)

        {com}. myreg2 i.smoke,model("Unadjusted" "Adjusted") export(table2.docx,replace)
        {txt}(save resutls to word document table2.docx)
        
        {com}. myreg2 i.smoke,dp(2) ci(" to ") pval all
        {txt}(results shown as 2 decimal points, 95%CI in the format of 95%CI(1.08 to 3.74), report all variables)

        {com}. myreg2 i.smoke,dp(2) ci(" to ") pval all export(table2.docx,append)
        {txt}(export results to table2.docx and append)
				
{marker aut}
{title:Author}

{p 4 4 2}
Professor Zumin Shi, Department of Nutrition Sciences, Qatar University, zumin.shi@gmail.com

{marker als}
{title:Also see}

    Manual:  {hi:[R] estimates}

{p 4 13 2}Online:  help for
 {helpb epitable2},
 {helpb epitable3}
{p_end}
