{smcl}
{* *! version 1.0.0  E Brini, ST Borgen, NT Borgen 28sept2023}{...}
{cmd:help pheatplot}
{hline}

{title:Title}

{p2colset 5 18 2 10}{...}
{p2col :{hi:pheatplot} {hline 2}}Compare pairwise p-values {p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 13 2}
{cmd:pheatplot} {cmd: {varname},} 
		[{opt differences}
		{opth interaction(varname)}
		{opt frame}({it:newframename})
		{opt pn:ame}({it:name}) 
		{opt bn:ame}({it:name})
		{opt heatoptsp}({it:options}) 
		{opt heatoptsb}({it:options})
		{opt pvalues}({it:off})
		{opt save}({it:filename})
		{opt hexplot}]
		
{marker options}{...}
{synoptset 27 tabbed}{...}
{synopthdr :options}
{synoptline}
{p2coldent : {opt differences}}requests that heatplot of differences between coefficients is displayed.{p_end}
{p2coldent : {opth interaction(varname)}}specifies the interaction variable, if 
	any.{p_end}
{p2coldent : {opt frame}({it:newframename})}specifies the name of the frame that holds 
	coefficients, standard errors, p-values, and confidence intervals.{p_end}
{p2coldent : {opt pn:ame}({it:name})}provides a name for the heatplot of the p-values.{p_end}
{p2coldent : {opt bn:ame}({it:name})}provides a name for the heatplot of the coefficients.{p_end}
{p2coldent : {opt heatoptsp}({it:options})}passes options along to the heatplot 
	of the p-values.{p_end}
{p2coldent : {opt heatoptsb}({it:options})}passes options along to the heatplot 
	of the coefficients.{p_end}
{p2coldent : {opt pvalues}({it:off})}removes the numeric display of p-values from heatplot of p-values.{p_end}
{p2coldent : {opt save}({it:filename})}saves a table holding results.{p_end}
{p2coldent : {opt hexplot}}requests that hexagon plots are used instead of heat plots.{p_end}
{synoptline}
{p2colreset}{...}
{marker weights}{...}
{pstd}


{title:Description}

{pstd}
{cmd:pheatplot} is a postestimation command that calculates 
pairwise comparisons of estimates using {helpb lincom} and visualizes the 
differences and the p-values of the difference in heatplots. The categorical 
variable that will be compared is placed after the command name, followed by 
options. In the previous regression model, the categorical variable must be 
included using factor-variables ({helpb fvvarlist}).

{pstd}
See {browse "https://osf.io/preprints/socarxiv/fghcd/":Brini, Borgen, and Borgen (2023)}
for descriptions and examples of the {cmd:pheatplot} command. 

{title:Options}
	
{phang}	
{opt differences} requests that heatplot of differences between coefficients is displayed. The 
	default is that the plot of differences between coefficients is not shown. 
	
{phang}	
{opth interaction(varname)} specifies the interaction variable, if 
	any. Interactions must be included using factor-variable operators 
	({helpb fvvarlist}).
	
{phang}	
{opt frame}({it:newframename}) specifies the name of the frame that holds 
	coefficients, standard errors, p-values, and confidence intervals. 
	Specifying a frame will return a frame after the program ends. 
	
{phang}	
{opt pn:ame}({it:name}) provides a name for the heatplot of the 
	p-values. 
	
{phang}	
{opt bn:ame}({it:name}) provides a name for the heatplot of the 
	coefficients.
	
{phang}	
{opt heatoptsp}({it:options}) affects rendition of the p-value plot. Options specified 
	here is passed along to the heatplot 
	of the p-values. See {it:heatplot {help heatplot##options:options}} for 
	list of available options. 
	
{phang}	
{opt heatoptsb}({it:options}) affects rendition of the coefficient plot. Options specified 
	here is passed along to the heatplot of the coefficients. 
	See {it:heatplot {help heatplot##options:options}} for list of available options.

{phang}	
{opt pvalues}({it:off}) removes the numeric display of p-values in the heatplot 
	of the p-values. This option should be used in combination with 
	heatoptsp(values({help heatplot##options:options})) if the user wants to customize the display of p-values. 
	
{phang}	
{opt save}({it:filename}) saves a table in .docx format which includes difference between 
	coefficients, standard errors, and p-values. 

{phang}	
{opt hexplot} requests that hexagon plots are used instead of heat plots. The default 
	is that the user-contributed command heatplot is used rather than hexplot. 


{title:Examples}

{pstd}
Setup{p_end}
{phang2}{cmd:. sysuse nlsw88, clear}{p_end}
{phang2}{cmd:. drop if inlist(occupation,9,10,12)}

{pstd}
Test differences in occupation dummies. {p_end}
{phang2}{cmd:. regress wage i.occupation}{p_end}
{phang2}{cmd:. pheatplot occupation}

{pstd}
Test difference in union effects by occupation dummies. {p_end}
{phang2}{cmd:. regress wage i.occupation##i.union}{p_end}
{phang2}{cmd:. pheatplot occupation, interaction(i.union)}

{pstd}
Test difference in age effects by occupation dummies. {p_end}
{phang2}{cmd:. regress wage i.occupation##c.age}{p_end}
{phang2}{cmd:. pheatplot occupation, interaction(c.age)}


{title:Stored results}

{cmd:pheatplot} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(pvalues)}}matrix holding p-values{p_end}
{synopt:{cmd:r(differences)}}matrix holding differences between coefficients{p_end}

{p2colreset}{...}

{title:Version requirements}

The {cmd:pheatplot} command requires Stata 17.0 or later. 

{title:Package dependencies}

{pstd}
{cmd:pheatplot} uses {helpb heatplot} to visualize the p-values and differences between coefficients. 
To install this command, type: 

{phang2}
{cmd:. ssc install heatplot}


{title:Reference}

{p 4 8 2}
{browse "https://osf.io/preprints/socarxiv/fghcd/": Brini, Elisa, Solveig T. Borgen, and Nicolai T. Borgen (2023)}.
Avoiding the eyeballing fallacy: Visualizing statistical differences between 
estimates using the pheatplot command. {it:SocArXiv}. 
doi:10.31235/osf.io/fghcd{p_end}

{p 4 8 2}
{browse "https://ideas.repec.org/c/boc/bocode/s458598.html": Jann, Ben (2019)}.
HEATPLOT: Stata module to create heat plots and hexagon plots. Statistical 
Software Components S458598, Boston College Department of Economics.{p_end}

{title:Authors}

{p 4 4 2} Elisa Brini, University of Oslo{break}
elisa.brini@sosgeo.uio.no{p_end}

{p 4 4 2} Solveig T. Borgen, University of Oslo{break}
s.t.borgen@sosgeo.uio.no{p_end}

{p 4 4 2} Nicolai T. Borgen, Oslo Metropolitan University{break}
n.t.borgen@isp.uio.no{p_end}




