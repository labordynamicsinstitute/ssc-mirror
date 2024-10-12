{smcl}
{* 04oct2024}{...}
{title:correlationchords: A Circular Chord Diagram of Correlations}

{p 4 4 2} Version 18.0

{p 4 4 2} October 4, 2024

{title:Syntax}

{p 4 4 2} {opt correlationchords}
{varlist}{cmd:,}
{it:{help correlationchords##mandatory_options:mandatory_options}}
{it:{help correlationchords##customlabel:customlabel}}
({it:{help correlationchords##discrete_color_options:discrete_color_options}} {c |} {it:{help correlationchords##continuous_color_options:continuous_color_options}})

{title:Description}

{p 4 4 2} {cmd:correlationchords} is a highly customizable circular chord graph that visualizes the significance level obtained when performing an independence test for all possible combinations of two of a list of variables.

{title:Program Limitations}

{p 4 4 2} 1. Due to the complexity of the syntax of the program, it is recomended to run it through its dialog box.

{p 4 4 2} 2. Processing time for the variables increases quadratically depending on the number of variables to be analyzed. Therefore, graphs intended to check the relationship among a large list of variables may require a long time to calculate.

{p 4 4 2} 3. Users of the more basic versions of Stata (StataBE) should not have issues when analyzing 30 or fewer variables, but due to the variable limit, they may experience problems beyond this number.

{p 4 4 2} 4. correlationchords is not suitable for quantitative variables and should only be used for qualitative variables.

{title:Options}

{synoptset 40 tabbed}{...}
{marker mandatory_options}{...}
{synopthdr :Mandatory Options}
{synopt :{opt test(string)}}Chooses the test whose p-value will be plotted:{p_end}
{synopt :}	{cmd:chi2} uses Pearson’s χ² test.{p_end}
{synopt :}	{cmd:exact1sided} uses Fisher’s exact one-sided test.{p_end}
{synopt :}	{cmd:exact2sided} uses Fisher’s exact two-sided test.{p_end}
{synopt :{opt startangle(#)}}Sets the position in degrees that the first variable will adopt on the circumference.{p_end}
{synopt :{opt strength(#)}}Sets the strength with which the chords will be pulled towards the center of the circumference. It is recommended not to use values below 0.{p_end}
{synopt :{opt labeldistance(#)}}Sets the distance from the center to the variable labels in radii of the circumference.{p_end}
{synopt :{opt labelorientation(string)}}Sets the orientation of the labels:{p_end}
{synopt :}	{cmd:perpendicular}	orients the labels perpendicular to their radius.{p_end}
{synopt :}	{cmd:parallel}	orients the labels parallel to their radius.{p_end}
{synopt :{opt labelcolor(string)}}Sets the color of the labels in RGB.{p_end}
{synopt :{opt labelsize(string)}}Sets the size of the labels in pt.{p_end}
{synopt :{opt colorscheme(string)}}Sets the color scheme that will be used to color the chords:{p_end}
{synopt :}	{cmd:discrete} colors the chords using up to 3 colors.{p_end}
{synopt :}	{cmd:continuous} colors the chords using a color gradient.{p_end}
{p2colreset}{...}

{synoptset 40 tabbed}{...}
{marker customlabel}{...}
{synopthdr :Custom Labels}
{synopt :{opt customlabel(string)}}Uses custom labels. A blank space " " separates the labels. If case of labels with multiple words, group the words with quotation marks "". If left blank, the variable names will be used as labels.{p_end}
{p2colreset}{...}

{synoptset 40 tabbed}{...}
{marker discrete_color_options}{...}
{synopthdr :Discrete Color Options}
{synopt :{opt significationdiscrete(#)}}Sets the p-value threshold below which the chords will be displayed.{p_end}
{synopt :{opt colordiscrete(string)}}Sets the color of the chord in RGB.{p_end}
{synopt :{opt linewidthdiscrete(#)}}Sets the width of the chord in pt.{p_end}
{synopt :{opt colordiscretesignificative(string)}}When present, it represents the chords with a significant p-value that also surpass the Bonferroni correction, applying this color to these chords in RGB.{p_end}
{synopt :{opt linewidthdiscretesignificative(#)}}Sets the width of significant chords that surpass the Bonferroni’s correction if {cmd:colordiscretesignificative} is present.{p_end}
{synopt :{opt colordiscretenotsignificative(string)}}When present, also displays chords with non-significant p-values, setting this color for these chords in RGB.{p_end}
{synopt :{opt linewidthdiscretenotsignificative(#)}}Sets the width of non-significant chords if {cmd:colordiscretenotsignificative} is present.{p_end}
{p2colreset}{...}

{synoptset 40 tabbed}{...}
{marker continuous_color_options}{...}
{synopthdr :Continuous Color Options}
{synopt :{opt significationcontinuous(#)}}Sets the p-value threshold below or equal to which the chords will be displayed.{p_end}
{synopt :{opt colorcontinuousmin(string)}}Sets the color of the chord when p = 0 in RGB.{p_end}
{synopt :{opt linewidthcontinuousmin(#)}}Sets the width of the chord when p = 0 in pt.{p_end}
{synopt :{opt colorcontinuousmax(string)}}Sets the color of the chord when p = {cmd:significationcontinuous} in RGB.{p_end}
{synopt :{opt linewidthcontinuousmax(#)}}Sets the width of the chord when p = {cmd:significationcontinuous} in pt.{p_end}
{synopt :{opt sensecontinuous(string)}}Sets the hue path along which the first color will transition to the second color:{p_end}
{synopt :}	{cmd:short} sets the shortest path, for example, from red to yellow through orange.{p_end}
{synopt :}	{cmd:long} sets the longest path, for example, from red to yellow, passing through violet, blue, and green.{p_end}
{synopt :{opt legend}}When present, shows a legend with the color gradient.{p_end}
{p2colreset}{...}

{title:Formulas}

{p 4 4 2} Bonferroni correction = p / (number of variables * (number of variables - 1) * 2)

{title:Author}

{p 4 4 2} Emilio Domínguez-Durán, emilienko@gmail.com
