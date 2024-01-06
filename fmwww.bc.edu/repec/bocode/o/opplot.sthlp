{smcl}
{...}
{...}
{* *! opplot.sthlp version 1.04 - Biostat Global Consulting - 2024-01-04}{...}
{* Change log: }{...}
{* 				Updated}{...}
{*				version}{...}
{* Date 		number 	Name			What Changed}{...}
{* 2017-12-20	1.00	Dale Rhoda		Original version}{...}
{* xxxx-xx-xx	1.0x	<name>			<comment>}{...}
{...}
{...}
{viewerjumpto "Syntax" "opplot##syntax"}{...}
{viewerjumpto "Description" "opplot##description"}{...}
{viewerjumpto "Details" "opplot##details"}{...}
{viewerjumpto "Remarks" "opplot##remarks"}{...}
{title:Title}
{phang}
{bf:opplot} {hline 2} Make an Organ Pipe Plot


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{opt opplot} {it:yvar} {ifin} {cmd:,} CLUSTVAR(varname) [
          {it:STRATVAR}(varname)
		  {it:STRATUM}(string)
		  {it:WEIGHTvar}(varname)
	      {it:BARCOLOR1}(string) 
	      {it:BARCOLOR2}(string) 
	      {it:LINECOLOR1}(string) 
	      {it:LINECOLOR2}(string) 
		  {it:EQUALWIDTH}
	      {it:SAVEDATA}(string) 
	 	  {it:EXPORTSTRAtumname}
	      {it:EXPORT}(string) 
	      {it:EXPORTWidth}(integer) 
   	      {it:TWOWAY}(string) 
		  {it:TITLE}(string) 
	      {it:SUBtitle}(string) 
	      {it:FOOTnote}(string) 
	      {it:NOTE}(string) 
	      {it:XTITLE}(string) 
	      {it:YTITLE}(string) 
	      {it:XLABEL}(string) 
	      {it:YLABEL}(string) 
	      {it:SAVING}(string) 
	      {it:NAME}(string) 
	      {it:XSIZE}(real) 
	      {it:YSIZE}(real) 
	      {it:PLOTN}
	      {it:NLINEColor}(string) 
	      {it:NLINEWidth}(string) 
	      {it:NLINEPattern}(string) 
	      {it:YTITLE2}(string) 
	      {it:YROUND2}(integer 5) 
         {it:LCTHRESHold}(integer 999)
	 {it:BARCOLORHIGH1}(string)
	 {it:BARCOLORMID1}(string) 
	 {it:BARCOLORLOW1}(string) 
	 {it:BARCOLORHIGH2}(string)
	 {it:BARCOLORMID2}(string)
	 {it:BARCOLORLOW2}(string)
	 {it:LINECOLORHIGH1}(string)
	 {it:LINECOLORMID1}(string)
	 {it:LINECOLORLOW1}(string)
	 {it:LINECOLORHIGH2}(string)
	 {it:LINECOLORMID2}(string)
	 {it:LINECOLORLOW2}(string)
	 {it:FOOTNOTECOVG}
	 {it:FOOTNOTEDEFF}
	 {it:FOOTNOTEICC}
	{it:STRATUMNAME}(string)
	{it:HIGH}(integer 100)] {p_end}

 
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}

{title:Description}

{pstd} {cmd:opplot} generates a vertical bar chart to summarize a binary outcome
       in cluster survey data.  The plot is known as an 
       {it:organ pipe plot}.  Each cluster is represented with a vertical bar.
	   The shaded portion of the bar represents the proportion of respondents in
	   that cluster whose value of yvar is 1.  Clusters with the highest 
	   proportion of 1's (also known as {it:coverage}) are shown at the left side 
	   of the plot.  Coverage decreases monotonically from left to right.{p_end}  
{pstd} If the data are self-weighting then the shaded proportion of the plot
       is equal to the sample coverage.  If the data are weighted
	   then the user should specify the WEIGHTvar, and the shaded
	   portion of the plot will represent the weighted sample coverage.  If the
	   user specifies the WEIGHTvar then the width of each bar represents the
	   weighted proportion of the population represented by each cluster.{p_end}	 
{pstd} Organ pipe plots have some features in common with Pareto Charts from 
       the field of quality control.{p_end}
	   
{pstd} Organ pipe plots were developed for the field of vaccination coverage
       surveys, but they can be helpful for any type of cluster survey with binary
	   outcomes.  The plots are useful for understanding the heterogeneity in
	   cluster-level coverage, which is related to the intracluster correlation
	   coefficient.  The plots are also useful for identifying clusters with 
	   surprisingly low or surprisingly high coverage.{p_end}
	   
{pstd} Because the width of the bars can vary substantially, organ pipe plots
       typically do not label the columns.  If the viewer wants to identify 
	   which bar represents which clusters, they consult an accompanying data
	   table which is (optionally) produced by this command.
	   {p_end}
	   
{marker details}{...}

{dlgtab:Required Inputs} 

{pstd} {bf:yvar} - Binary variable which takes on only values of 0, 1 or missing (.).
       This is the variable whose coverage the program estimates.  As far as 
	   opplot is concerned, a missing value is the same as a 0; neither
	   respondent has evidence of the outcome.  All respondents are included in
	   the denominator and only those whose value of yvar==1 are included in
	   the numerator.
	   {p_end}
	   
{pstd} {bf:CLUSTVAR}(varname) - Variable that holds the cluster ID.
	   {p_end}
	   
{dlgtab:Optional Inputs} 
	   	   
{pstd} {bf:STRATVAR}(varname) - opplot is meant to show data for one stratum per plot.
       If the dataset holds data for more than one stratum, specify the name of
	   the stratum ID variable and use the {cmd:stratum} option to specify
	   which stratum to plot.{p_end}
	   	   
{pstd} {bf:STRATUM}(string) - The value of {cmd:stratvar} for which to make the plot.  E.g., 
       if you want to plot coverage in stratum 14, specify stratum(14). {p_end}

{pstd} {bf:STRATUMNAME}(string) - The name of the stratum that will be added as a note to the dataset. Name should correspond with the value provided in {cmd:stratum} {p_end}
	   	   
{pstd} {bf:WEIGHTvar}(varname) - Variable that holds the survey weight.  The 
       weights are assumed to be equal if this option is omitted.{p_end}
	   	   
{pstd} {bf:BARCOLOR1}(string) - Valid Stata color used to represent respondents 
       with yvar == 1.  This is the shade for the lower portion of the bars.  
	   Default is pink.{p_end}
	   	   
{pstd} {bf:BARCOLOR2}(string) - Valid Stata color used to represent respondents 
       with yvar == 0 or missing.  This is the shade for the upper portion of
	   the bars.  Default is white.{p_end}
	   
{pstd} {bf:LINECOLOR1}(string) - Valid Stata color used to mark the boundaries 
       between the lower portions of the bars.  (Should have good contrast
	   with BARCOLOR1.)  Default is barcolor1*1.5.{p_end}
	   	   
{pstd} {bf:LINECOLOR2}(string) - Valid Stata color used to mark the boundaries
       between the upper portions of the bars.  (Should have good contrast with 
	   BARCOLOR2.)  Default is black*0.5.{p_end}
	   	   
{pstd} {bf:EQUALWIDTH} - If this option is included, all bars (clusters) that
       have at least one non-missing value of yvar will appear with equal width,
	   regardless of the number of respondents in the cluster and regardless
	   of the values of the weightvar.  (Note: EQUALWIDTH causes this program
	   to IGNORE the weightvar.){p_end}
	   
{pstd} {bf:SAVEDATA}(string) - If this option is specified, the command will 
       save a dataset and name it using the string specified, which doesn't need 
	   to be in double quotes. The dataset includes one row per bar in the plot.  
	   The left-most bar is represented by row 1 and the right-most bar by the 
	   last row in the dataset.  The dataset holds several informative columns 
	   describing what variable is summarized, how many respondents are 
	   represented in each bar, the proportion of the population represented by
	   each bar, and the sample coverage in each bar (rounded to the nearest 
	   percent).  This dataset can be useful for identifying the cluster ID for 
	   bars that show surprisingly low or surprisingly high coverage.  SAVEDATA 
	   uses the replace option when saving the dataset, so an existing dataset 
	   with the same filename will be overwritten.{p_end}
	   
{pstd} {bf:EXPORTSTRAtumname} - If this option is specified, the command will 
       export a .PNG image of the plot to the current working directory and uses
	   the string from the {cmd:stratum} option as the filename.  If user wants a 
	   different filename or a different directory, use the {cmd:export}
	   option.{p_end}
	   	   
{pstd} {bf:EXPORT}(string) - Specify a filename and extension where the plot
       should be exported (e.g., plot.png).  Use an extension that is 
	   compatible with the graph export width option (e.g., .png or .tif).{p_end}
	   	   
{pstd} {bf:EXPORTwidth}(integer) - The default width of opplot's export option
       is 2000 pixels.  You may specify a different width with this option.{p_end}
	      	   
{pstd} {bf:TWOWAY}(string) - The opplot command calls Stata's twoway command
       for plotting.  You may use the {cmd:twoway} option to pass through any valid
	   twoway options that are not already hard-coded here.  See the list
	   below under 'All Else'.{p_end}
	      	   
{pstd} {bf:PLOTN} - If specified, the plot will include a second y-axis and a 
       line showing the number of respondents (N) per cluster.  User may specify
	   the properties of the line and of the axis title and labels using options
	   listed below. {p_end}
	   
{pstd} {bf:NLINEColor}(string) - Color for the line that shows N. {p_end}

{pstd} {bf:NLINEWidth}(string) - Width of the line that shows N. {p_end}

{pstd} {bf:NLINEPattern}(string) - Pattern of the line that shows N. {p_end}

{pstd} {bf:YTITLE2}(string) - Title for second y-axis if the user specifies the
       PLOTN option.  Default is "Number of Respondents".{p_end}

{pstd} {bf:YROUND2}(integer 5) - Affects the labels on the second y-axis if the 
       user specifies the PLOTN option.  The scale will run from 0 up to the
	   (maximum number of respondents in a cluster plus one) rounded up to the next multiple
	   of YROUND2.  Default is to round up to the next multiple of 5.{p_end}

{pstd}	{bf:FOOTNOTECOVG} - Adds the Estimated Coverage as a footnote to the plot. {p_end}

{pstd}  {bf:FOOTNOTEDEFF} - Adds the Design Effect as a footnote to the plot. {p_end}

{pstd}  {bf:FOOTNOTEICC} - Adds the Intercluster Correlation Coefficient as a footnote to the plot. {p_end}
	   
{pstd} {bf:All Else} - Several standard twoway options are hard-coded as pass-thru 
	   options here.  These include title, subtitle, note, xtitle, ytitle, xlabel, 
	   ylabel, saving, name, xsize and ysize.  Note that {bf:ytitle} defaults to "Percent of cluster".  
	   You may specify ytitle(" ") to see a blank title or ytitle(none) will 
	   yield no ytitle and will therefore shift the figure slightly to the left.  Note that 
	   with the {bf:name} option, the user only needs to specify the name; the 
	   code always includes the {it:replace} option when the user specifies a name.
	   Note also that the {cmd:footnote} option is a 
	   synonym for the note option.) (See {help twoway_options}). {p_end}	

{dlgtab: Add High, Medium and Low Coverage Categories} 

{pstd} The next set of input options should only be used to see the plot stratified into high, medium and low coverage categories. {p_end}

{pstd} {bf:LCTHRESHold}(integer) - Low coverage threshold holds the numeric percent value used to identify low coverage. 
All clusters with coverage less than or equal to this number will be assigned to the low category. 
If not specified, all of the options listed below will be ignored. 
If specified, you should use a note to tell the reader the meaning of the three bar colors.  (At this time, opplot does not use a legend.){p_end}

{pstd} {bf:HIGH}(integer) - High coverage threshold holds the numeric percent value used to identify high coverage. 
All clusters with coverage greater than or equal to this number will be assigned to the high cagtegory. Default value is 100.{p_end}

{pstd} (Note: If you specify the same high and low threshold, then the plot will be stratified into only two categories: high vs. low and clusters with coverage EXACTLY equal to the threshold will fall in the low category.)

{pstd} Each category (HIGH, MID and LOW) can have different color options specified for the bars and lines. {p_end}


{pstd} {bf:BARCOLORHIGH1}(string) - Valid Stata color used to represent respondents with yvar == 1 with high coverage as specified in {cmd:high}.  
This is the shade for the lower portion of the bars.  Default is dark blue with RGB values 103 169 207.{p_end}
	  	   
{pstd} {bf:BARCOLORHIGH2}(string) - Valid Stata color used to represent respondents with yvar == 0 or missing with high coverage as specified in {cmd:high}.  
This is the shade for the upper portion of the bars.  Default is gs15.{p_end}
	   
{pstd} {bf:LINECOLORHIGH1}(string) - Valid Stata color used to mark the boundaries between the lower portions of the bars with high coverage as specified in {cmd:high}.
  (Should have good contrast with BARCOLORHIGH1.)  Default is gs15.{p_end}
	   	   
{pstd} {bf:LINECOLORHIGH2}(string) - Valid Stata color used to mark the boundaries between the upper portions of the bars with high coverage as specified in {cmd:high}. 
 (Should have good contrast with BARCOLORHIGH2.)  Default is black*0.5.{p_end}


{pstd} {bf:BARCOLORMID1}(string) - Valid Stata color used to represent respondents with yvar == 1 with middle coverage.  
This is the shade for the lower portion of the bars.  Default is light blue with RGB values 0 0 128.{p_end}
	  	   
{pstd} {bf:BARCOLORMID2}(string) - Valid Stata color used to represent respondents with yvar == 0 or missing with middle coverage.  
This is the shade for the upper portion of the bars.  Default is gs15.{p_end}
	   
{pstd} {bf:LINECOLORMID1}(string) - Valid Stata color used to mark the boundaries between the lower portions of the bars with middle coverage.
  (Should have good contrast with BARCOLORMID1.)  Default is gs15.{p_end}
	   	   
{pstd} {bf:LINECOLORMID2}(string) - Valid Stata color used to mark the boundaries between the upper portions of the bars with middle coverage. 
 (Should have good contrast with BARCOLORMID2.)  Default is black*0.5.{p_end}


{pstd} {bf:BARCOLORLOW1}(string) - Valid Stata color used to represent respondents with yvar == 1 with low coverage as specified in {cmd:lcthreshold}.  
This is the shade for the lower portion of the bars.  Default is orange with RGB values 255 91 0.{p_end}
	  	   
{pstd} {bf:BARCOLORLOW2}(string) - Valid Stata color used to represent respondents with yvar == 0 or missing with low coverage as specified in {cmd:lcthreshold}.  
This is the shade for the upper portion of the bars.  Default is gs15.{p_end}
	   
{pstd} {bf:LINECOLORLOW1}(string) - Valid Stata color used to mark the boundaries between the lower portions of the bars with low coverage as specified in {cmd:lcthreshold}.
  (Should have good contrast with BARCOLORLOW1.)  Default is gs15.{p_end}
	   	   
{pstd} {bf:LINECOLORLOW2}(string) - Valid Stata color used to mark the boundaries between the upper portions of the bars with low coverage as specified in {cmd:lcthreshold}. 
 (Should have good contrast with BARCOLORLOW2.)  Default is gs15.{p_end}

{dlgtab:A note on bar width} 

{pstd}  If the user does not specify a weightvar and does not specify the 
        equalwidth option, then the data are assumed to be self-weighted and 
		each cluster's bar width is proportional to the number of respondents 
		there.  (This is the same as saying that the bar width is proportional
		to the sum of weights in the cluster.){p_end}

{pstd}  If the user does specify a weightvar, then each bar width is
		proportional to the sum of weights in the cluster.{p_end}
		
{pstd}  If the user specifies the equalwidth option, then every bar will have 
		equal width, regardless of whether the user specified the weightvar.  In
		other words, the equalwidth option will override the weightvar 
		option. {p_end}		

{dlgtab:A note on conflicting versions of opplot.ado} 

{pstd}  This program is currently available from two sources: 1) as a 
		standalone command from the Stata SSC, and 2) as part of a bundle 
		of programs called the Vaccination Coverage Quality Indicators (VCQI)
		from the World Health Organization.  The code is meant to be precisely 
		the same from both sources, but over time there is a danger that you 
		will have an old version from one source and an updated version from the 
		other.  You will need to check your adopath to see which version is
		used when you invoke the command.{p_end}

{hline}

{title:Examples - See accompanying opplot_demo.do to run these examples}

{cmd: * Make fake data with 2 strata with 10 clusters each with 10 respondents each}
{cmd: . clear all}
{cmd: . set seed 8675309}
{cmd: . set obs 200}
{cmd: . gen clusterid = mod(_n-1,10)+1}
{cmd: . bysort clusterid: gen stratumid = _n <= 10}

{cmd: * The yes/no outcome variable here is y.  It can take values of 0, 1, or missing(.).}
{cmd: * If it takes any other values, opplot will complain and abort.}

{cmd: . gen y = runiform() > clusterid/10}
{cmd: * Artificially boost coverage in stratum 1}
{cmd: . replace y = 1 if runiform() > .5 & stratumid == 1}

{cmd: * Basic demo...two plots...one for each stratum}
{cmd: . opplot y , clustvar(clusterid) stratvar(stratumid) stratum(0) title(Stratum 0) name(Demo0,replace)}
{cmd: . opplot y , clustvar(clusterid) stratvar(stratumid) stratum(1) title(Stratum 1) name(Demo1,replace)}

{cmd: * Without the stratum arguments, all data are plotted}
{cmd: opplot y , clustvar(clusterid) title(All Strata) name(Demo2, replace) }

{cmd: * Change bar colors}
{cmd: . opplot y , clustvar(clusterid) stratvar(stratumid) ///}
{cmd:  		stratum(1) title(Stratum 1) name(Demo3,replace) ///}
{cmd: 		barcolor1(red) barcolor2(gs8)}

{cmd: * Demo different bar widths if weights differ}
{cmd: . gen weight = 1}
{cmd: . replace weight = 2 if clusterid == 1}
{cmd: . save fauxdata, replace}

{cmd: . opplot y , clustvar(clusterid) stratvar(stratumid) ///}
{cmd: 		weightvar(weight) ///}
{cmd: 		stratum(1) title(Stratum 1) name(Demo4,replace) ///}
{cmd: 		barcolor1(red) barcolor2(gs8)	}

{cmd: * Change line colors		}
{cmd: . opplot y , clustvar(clusterid) stratvar(stratumid) ///}
{cmd: 		weightvar(weight) ///}
{cmd: 		stratum(1) title(Stratum 1) name(Demo5,replace) ///}
{cmd: 		barcolor1(red) barcolor2(gs8)	///}
{cmd: 		linecolor1(white) linecolor2(green)}

{cmd: * Change ylabel}
{cmd: * Demo ylabel xtitle ytitle subtitle footnote}
{cmd: * Demo export}
{cmd: . opplot y , clustvar(clusterid) stratvar(stratumid) ///}
{cmd: 		weightvar(weight) ///}
{cmd: 		stratum(1) title(Stratum 1) name(Demo6,replace) ///}
{cmd: 		ylabel(0(25)100,angle(0)) ///}
{cmd: 		xtitle(XTitle) ytitle(YTitle) ///}
{cmd: 		subtitle(Subtitle) footnote(Footnote) ///}
{cmd: 		export(Stratum_1.png)}

{cmd: * The exportstratumname option saves you the trouble of coming}
{cmd: * up with the export filename		}
{cmd: . opplot y , clustvar(clusterid) stratvar(stratumid) ///}
{cmd: 		stratum(0) title(Stratum 0) name(Demo0,replace) ///}
{cmd: 		exportstratumname}

{cmd: * The exportwidth options lets you specify that a larger file is saved}
{cmd: * with better resolution for some purposes}
{cmd: . opplot y , clustvar(clusterid) stratvar(stratumid) ///}
{cmd: 		stratum(0) title(Stratum 0) name(Demo0,replace) ///}
{cmd: 		exportstratumname exportwidth(3000)}

{cmd: * Demo changing the aspect ratio of the figure using xsize and ysize		}
{cmd: . opplot y , clustvar(clusterid) stratvar(stratumid) ///}
{cmd: 		stratum(0) title(Stratum 0) name(Demo7,replace) ///}
{cmd:  		xsize(20) ysize(6) export(Stratum_0_wide.png)}

{cmd: * Demo saving the accompanying dataset and having a look at it		}
{cmd: . opplot y , clustvar(clusterid) stratvar(stratumid) ///}
{cmd: 		stratum(0) title(Stratum 0) name(Demo7,replace) ///}
{cmd:  		xsize(20) ysize(6) savedata(Demo7)}
{cmd: . use Demo7, clear }
{cmd: . browse }

{cmd: . use fauxdata, clear}

{cmd: * Demo plotting the number of respondents		}
{cmd: . opplot y , clustvar(clusterid) stratvar(stratumid) ///}
{cmd: 		stratum(0) title(Stratum 0) name(Demo8,replace) ///}
{cmd:  		xsize(20) ysize(6) plotn}

{cmd: * Demo plotting the number of respondents using all related options	}
{cmd: . opplot y , clustvar(clusterid) stratvar(stratumid) ///}
{cmd: 		stratum(0) title(Stratum 0) name(Demo9,replace) ///}
{cmd:  		xsize(20) ysize(6) plotn nlinecolor(red) nlinewidth(*2) ///}
{cmd:   	nlinepattern(dash) ytitle2(Number of Respondents (N)) ///}
{cmd:   	yround2(2)}


{cmd: * Demo adding high, medium and low coverage categories.}
{cmd: * Only specify the lcthreshold. All other values will use defaults.}
{cmd: . opplot y , clustvar(clusterid) stratvar(stratumid) ///}
{cmd: 		stratum(1) title(Stratum 1) name(Demo10,replace) ///}
{cmd:  		lcthreshold(50) ///}
{cmd:       note("Different colors for clusters with a) 100% coverage, b) >50% and < 100%, and c) <= 50%.")}

{cmd: * Demo adding high, medium and low coverage categories.}
{cmd: * Specify both the lcthreshold {it:(slightly lower than previous run)} and high. All other values will use defaults.}
{cmd: . opplot y , clustvar(clusterid) stratvar(stratumid) ///}
{cmd: 		stratum(0) title(Stratum 0) name(Demo11,replace) ///}
{cmd:  		lcthreshold(20) high(90) ///}
{cmd:       note("Different colors for clusters with a) >= 90% coverage, b) >20% and < 90%, and c) <= 20%.")}

{cmd: * Demo adding high, medium and low coverage categories with specified barcolor options.}
{cmd: * Change both the lcthreshold and high. Define barcolors for high, medium and low coverage categories.}
{cmd: . opplot y , clustvar(clusterid) stratvar(stratumid) ///}
{cmd: 		stratum(0) title(Stratum 0) name(Demo12,replace) ///}
{cmd:  		lcthreshold(35) high(80) ///}
{cmd:		barcolorhigh1(67 162 202) barcolormid1(123 204 196) barcolorlow1(186 228 188) ///}
{cmd:       note("Different colors for clusters with a) >= 80% coverage, b) >35% and < 80%, and c) <= 35%.")}		

{cmd: * Demo portraying only two categories by setting lcthreshold == high.}
{cmd: * Note that in this case, any clusters exactly equal to the threshold are}
{cmd: * shown in the *lower* category color.}
{cmd: . opplot y , clustvar(clusterid) stratvar(stratumid) ///}
{cmd:        stratum(0) title(Stratum 0) name(Demo13,replace) ///}
{cmd:        lcthreshold(50) high(50) ///}
{cmd:	 	 note("Different colors for clusters with a) > 50% coverage and b) <= 50%.")}


{title:Authors}
{p}

Dale Rhoda, Mary Prier, and Mary Kay Trimner, Biostat Global Consulting

Email {browse "mailto:Dale.Rhoda@biostatglobal.com":Dale.Rhoda@biostatglobal.com}

{title:Links to YouTube Videos}

{pstd} The {cmd:opplot} command is distributed with (but not dependent upon) the 
       World Health Organization's suite of Stata programs known as the 
	   Vaccination Coverage Quality Indicators (VCQI) (pronounced {it:Vicki}). 
	   Organ pipe plots are described in some of the VCQI training videos:{p_end}
	   
{pmore} {browse "https://youtu.be/k-2NJMT_uvo":Organ Pipe Plots - Overview}{p_end}
{pmore} {browse "https://youtu.be/sSGR60eOBrI":Organ Pipe Plots - Drilling Down} 
        (Describes useful features of the optional dataset that can be saved with
		each plot.){p_end}

{title:Links to PowerPoint Presentations}

{pstd} Organ pipe plots were featured in a talk at the 2018 Stata Conference.{p_end}
	   
{pmore} {browse "https://www.stata.com/meeting/columbus18/slides/columbus18_Prier.pptx":2018 conference presentation}{p_end}
{pmore} {browse "https://www.dropbox.com/s/o3psw0d50l0arvf/opplot_presentation.pptx?dl=0":Includes additional slides that describe new features}{p_end}

