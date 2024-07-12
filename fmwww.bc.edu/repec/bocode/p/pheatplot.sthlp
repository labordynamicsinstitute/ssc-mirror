{smcl}
{* *! version 1.1.0  E Brini, ST Borgen, NT Borgen 02july2024}{...}
{cmd:help pheatplot}
{hline}

{title:Title}

{p2colset 5 18 2 10}{...}
{p2col :{hi:pheatplot} {hline 2}}Visualizing statistical significance across coefficients {p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 13 2}
{cmd:pheatplot} {cmd: {varname},} 
		[
		{opt threshold(#)}
		{opth interaction(varname)}
		{opt frame}({it:newframename})
		{opt pn:ame}({it:name} [, {it:replace}]) 
		{opt bn:ame}({it:name} [, {it:replace}])
		{opt heatoptsp}({it:options}) 
		{opt heatoptsb}({it:options})
		{opt pvalues}({it:off})
		{opt savet:able}({it:filename} [, {it:save_options}])
		{opt saveg:raph}({it:filename.suffix} [, {it:replace}])
		{opt differences}
		{opt hexplot}
		{opt mono}]
		
{marker options}{...}
{synoptset 27 tabbed}{...}
{synopthdr :options}
{synoptline}
{p2coldent : {opt threshold(#)}}sets the critical threshold value; default is threshold(.10).{p_end}
{p2coldent : {opth interaction(varname)}}specifies the interaction variable, if 
	any.{p_end}
{p2coldent : {opt frame}({it:newframename})}specifies the name of the frame that holds 
	coefficients, standard errors, p-values, and confidence intervals.{p_end}
{p2coldent : {opt pn:ame}({it:name})}provides a name for the heat plot of the p-values.{p_end}
{p2coldent : {opt bn:ame}({it:name})}provides a name for the heat plot of the coefficients.{p_end}
{p2coldent : {opt heatoptsp}({it:options})}passes options along to the heat plot 
	of the p-values.{p_end}
{p2coldent : {opt heatoptsb}({it:options})}passes options along to the heat plot 
	of the coefficients.{p_end}
{p2coldent : {opt pvalues}({it:off})}removes the numeric display of p-values from heat plot of p-values.{p_end}
{p2coldent : {opt savet:able}({it:filename})}saves a table holding results.{p_end}
{p2coldent : {opt saveg:raph}({it:filename.suffix})}exports to a file the heat plot of p-values.{p_end}
{p2coldent : {opt differences}}requests that heat plot of differences between coefficients is displayed.{p_end}
{p2coldent : {opt hexplot}}requests that hexagon plots are used instead of heat plots.{p_end}
{p2coldent : {opt mono}}requests that heat plots are shown in grayscale color palette.{p_end}
{synoptline}
{p2colreset}{...}
{marker weights}{...}
{pstd}


{title:Description}

{pstd}
{cmd:pheatplot} is a postestimation command that calculates pairwise comparisons 
of estimates using {helpb lincom} and provides a heat plot by color to visualize the 
p-values of the difference between the categories of a factor variable or 
their interaction effects. It can be used after all single-equation estimation 
commands that allows for factor variable notation and 
the use of the postestimation command {helpb lincom}. The categorical variable that will be compared is 
placed after the command name, followed by options. In the previous regression 
model, the categorical variable must be included using factor variable 
notation ({helpb fvvarlist}).

{pstd}
See {browse "https://osf.io/preprints/socarxiv/fghcd/":Brini, Borgen, and Borgen (2023)}
for descriptions and examples of the {cmd:pheatplot} command. 


{title:Options}
	
{phang}	
{opt threshold} sets the critical threshold value, with the color gradient differing 
	below and above this threshold. This allows the user to identify and communicate 
	whether differences are statistically significant at specific levels, while at 
	the same time avoiding strict cutoff values. The default is threshold(.10).

{phang}	
{opth interaction(varname)} specifies the interaction variable, if 
	any. Interactions must be included using factor-variable operators 
	({helpb fvvarlist}).
	
{phang}	
{opt frame}({it:newframename}) specifies the name of the frame that holds 
	coefficients, standard errors, p-values, and confidence intervals. 
	Specifying {\tt frame()} will return a frame after the program ends. 
	
{phang}	
{opt pn:ame}({it:name}) provides a name for the heat plot of the 
	p-values. 
	
{phang}	
{opt bn:ame}({it:name}) provides a name for the heat plot of the 
	coefficients.
	
{phang}	
{opt heatoptsp}({it:options}) affects rendition of the p-value plot. Options specified 
	here is passed along to the heat plot 
	of the p-values. See {it:heatplot {help heatplot##options:options}} for 
	list of available options. 
	
{phang}	
{opt heatoptsb}({it:options}) affects the rendition of the plot of differences 
	between coefficients. Options specified here are passed along to the heat plot 
	of the differences between coefficients. See {it:heatplot {help heatplot##options:options}} for list of available options. Use of {opt heatoptsb()} requires that the option {opt differences} is specified

{phang}	
{opt pvalues}({it:off}) removes the numeric display of p-values in the heat plot 
	of the p-values. This option should be used in combination with 
	heatoptsp(values({it:options})) if the user wants to customize the display of p-values. 
	
{phang}	
{opt savet:able}({it:filename}) saves a table in .docx format which includes the difference between
	coefficients and the standard errors and p-values from testing whether there
	are statistically significant differences between the coefficients. The {it: save_options} from {cmd:putdocx} can 
	be used to {it:replace} an exisiting file or {it:append} the active file to the end 
	of a exisiting file. See {it:putdocx begin {help putdocx begin:save_options}} for list of available options.
	
{phang}	
{opt saveg:raph}({it:filename.suffix [, replace]}) exports to file the heat plot of p-values. The suffix could be (with output format in paranthesis)
	ps (PostScript), eps (Encapsulated PostScript), svg (Scalable Vector Graphics), 
	emf (Enhanced Metafile), pdf (Portable Document Format), png (Portable Network Graphics),
	tif (Tagged Image File Format), gif (Graphics Interchange Format), or jpg (Joint Photographic Experts Group).
	
{phang}	
{opt differences} requests that heatplot of differences between coefficients is displayed. The 
	default is that the plot of differences between coefficients is not shown. 
		
{phang}	
{opt hexplot} requests that hexagon plots are used instead of heat plots. The default 
	is that the user-contributed command heatplot is used rather than hexplot. 
	
{phang}	
{opt mono} requests that the heat plots are shown in grayscale color palette. 


{title:Examples}

{pstd}
Setup. {p_end}
{phang2}{cmd:. sysuse nlsw88, clear}{p_end}
{phang2}{cmd:. drop if inlist(occupation,9,10,12)}

{pstd}
Test differences in occupation indicator variables. {p_end}
{phang2}{cmd:. regress wage i.occupation}{p_end}
{phang2}{cmd:. pheatplot occupation}

{pstd}
Test difference in union effects by occupation. {p_end}
{phang2}{cmd:. regress wage i.occupation##i.union}{p_end}
{phang2}{cmd:. pheatplot occupation, interaction(i.union)}

{pstd}
Test difference in age effects by occupation. {p_end}
{phang2}{cmd:. regress wage i.occupation##c.age}{p_end}
{phang2}{cmd:. pheatplot occupation, interaction(c.age)}

{pstd}
Test differences in occupation indicator variables after a logistic regression model. {p_end}
{phang2}{cmd:. logit union i.occupation}{p_end}
{phang2}{cmd:. pheatplot occupation}

{pstd}
Test differences in occupation indicator variables after {helpb margins}. {p_end}
{phang2}{cmd:. logit union i.occupation}{p_end}
{phang2}{cmd:. margins, dydx(occupation) post}{p_end}
{phang2}{cmd:. pheatplot occupation}

{pstd}
Changing the threshold cutoff value. {p_end}
{phang2}{cmd:. regress wage i.occupation}{p_end}
{phang2}{cmd:. pheatplot occupation, threshold(.05)}

{pstd}
Requesting that the graph is shown using a color palette. {p_end}
{phang2}{cmd:. regress wage i.occupation}{p_end}
{phang2}{cmd:. pheatplot occupation, color}

{pstd}
Use alternative color palettes. {p_end}
{phang2}{cmd:. regress wage i.occupation}{p_end}
{phang2}{cmd:. pheatplot occupation, heatoptsp(color(Blues))}

{pstd}
Customizing the look of the graph using heatoptsp(). {p_end}
{phang2}{cmd:. use http://www.stata-press.com/data/mlmus2/gcse, clear}{p_end}
{phang2}{cmd:. regress gcse i.school}{p_end}
{phang2}{cmd:. pheatplot school, pvalues(off) heatoptsp(scale(0.7) ramp(scale(.7) 	///}{p_end}
{phang3}{cmd: legend(symysize(.5) symxsize(.5)) space(12) right  					///}{p_end}
{phang3}{cmd: label(#10) subtitle(P-value) format(%9.2f)) ylabel(2(3)65, nogrid)	///}{p_end}
{phang3}{cmd: xlabel(1(3)64, nogrid))}


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
{cmd:pheatplot} uses {helpb heatplot} to visualize the statistical significance 
of differencs between coefficients. To install this command, type: 

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

{p 4 8 2}
{browse "https://journals.sagepub.com/doi/10.1177/1536867X231175264": Jann, Ben (2023)}.
Color palettes for Stata graphics: an update. The Stata Journal 23(2): 336–385.{p_end}


{title:Authors}

{p 4 4 2} Elisa Brini, University of Florence{break}
elisa.brini@unifi.it{p_end}

{p 4 4 2} Solveig T. Borgen, University of Oslo{break}
s.t.borgen@sosgeo.uio.no{p_end}

{p 4 4 2} Nicolai T. Borgen, University of Oslo{break}
n.t.borgen@isp.uio.no{p_end}




