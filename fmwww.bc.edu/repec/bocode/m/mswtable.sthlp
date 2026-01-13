{smcl}
{* 10Jan2026}{...}
{hi:help mswtable}
{hline}

{p 1}{bf:{ul on}Title{ul off}}{p_end}

{p 6}{hi:mswtable} {hline 2} MSWord tables:  descriptive statistics and regression estimates

{p 1}{bf:{ul on}Syntax{ul off}}{p_end}

{p 6 15 2}
{cmd:mswtable} , {opth colw:idth(string)}
[ {help mswtable##comopt:{it:options}}
 ]


{pstd}{it:note}:  {opth colwidth(string)} is required, and either {opth mat(string)} or {opth est(string)}{p_end}


{synoptset 23 tabbed}{...}
{marker comopt}{synopthdr:Core Options}
{synoptline}
{synopt :{opth colw:idth(string)}}width of each column (in inches) ({ul:required} option)
  {p_end}
{synopt :{opth mat(string)}}matrix input: name of matrix
  {p_end}
{synopt :{opth est(string)}}estimates input: list of stored equations
  {p_end}
{synopt :{opth dec:imals(string)}}number of decimal places, column- or row-specific
  {p_end}
{synopt :{opth font(string)}}font: type of font, font sizes
  {p_end}
{synopt :{opth title(string)}}title for table
  {p_end}
{synopt :{opth subt:itle(string)}}subtitle for table
  {p_end}
{synopt :{opth note#(string)}}notes placed at foot of table (maximum nine)
  {p_end}
{synopt :{opth ct_set(string)}}column titles: set font (bold, underline, italic, none) and justification
  {p_end}
{synopt :{opth ct(string)}}column titles
  {p_end}
{synopt :{opth rt_set(string)}}row titles: set font (bold, underline, italic, none) and justification
  {p_end}
{synopt :{opth rt(string)}}row titles
  {p_end}
{synopt :{opth outf:ile(string)}}MSWord table: file name and directory
  {p_end}

{marker comopt}{synopthdr:Est_ Options}
{synoptline}
{synopt :{opth est_stat(string)}}estimates input: requests equation statistics (N, AIC, etc.)
  {p_end}
{synopt :{opth est_star(string)}}estimates input: requests coeff tests: asterisks
  {p_end}
{synopt :{opth est_se(string)}}estimates input: requests coeff uncertainty and/or tests (se, ci, z, p)
  {p_end}
{synopt :{opth est_vars(string)}}estimates input: subset of right-hand-side variables to show in table
  {p_end}
{synopt :{opth est_no(string)}}estimates input: equations omitted from coefficient precision ({cmd:est_star} & {cmd:est_se})
  {p_end}

{marker comopt}{synopthdr:Beyond Core}
{synoptline}
{synopt :{opth cst_set(string)}}column-spanning titles: set font (bold, underline, italic, none) and justification
  {p_end}
{synopt :{opth cst#(string)}}column-spanning titles: lower level (maximum ten)
  {p_end}
{synopt :{opth cst1#(string)}}column-spanning titles: higher level (maximum five)
  {p_end}
{synopt :{opth rst_set(string)}}row-spanning titles: set font (bold, underline, italic, none) and indentation
  {p_end}
{synopt :{opth rst#(string)}}row-spanning titles: text and location (maximum fifteen)
  {p_end}
{synopt :{opth add_cols(string)}}insert blank column(s)
  {p_end}
{synopt :{opth extra#(string)}}extra information rows, placed below coefficients and statistics (maximum nine)
  {p_end}

{marker comopt}{synopthdr:Additional Options}
{synoptline}
{synopt :{opth add_means(string)}}add means of right-hand-side variables
  {p_end}
{synopt :{opth add_mat(string)}}add matrix
  {p_end}
{synopt :{opth add_excel(string)}}add excel spreadsheet
  {p_end}
{synopt :{opth title1(string)}}title for table, alternative syntax (two columns)
  {p_end}
{synopt :{space 3}{opth title2(string)}}
  {p_end}
{synopt :{opt firstX}}top row in table: extra space after
  {p_end}
{synopt :{opt lastX}}bottom row in table: extra space before
  {p_end}
{synopt :{opt extra_place}}reverse placement of rows for {cmd:est_stat} and {cmd:extra#}
  {p_end}
{synopt :{opth tline(string)}}top line in table: format (bold, double, neither)
  {p_end}
{synopt :{opth bline(string)}}bottom line in table: format (bold, double, neither)
  {p_end}
{synopt :{opt slim}}do not insert empty rows (rows for aesthetics only)
  {p_end}
{synopt :{opth tabname(string)}}name for putdocx table 
  {p_end}

{marker comopt}{synopthdr:Multiple Panels (max 7)}
{synoptline}
{synopt :{opth mat#(string)}}matrix input: identifies matrices, panel-specific
  {p_end}
{synopt :{opth est#(string)}}estimates input: identifies stored equations, panel-specific
  {p_end}
{synopt :{opth est_stat#(string)}}estimates input: equation statistics, panel-specific
  {p_end}
{synopt :{opth est_vars#(string)}}estimates input: variable selection, panel-specific
  {p_end}
{synopt :{opth dec#(string)}}number of decimal places, panel-specific
  {p_end}
{synopt :{opt pline}}draw lines separating panels
  {p_end}
{synopt :{opth pspace(string)}}size of vertical gap between panels
  {p_end}
{synopt :{opth pt_set(string)}}panel titles: font, justification, row-title indentation
  {p_end}
{synopt :{opth pt#(string)}}panel titles, panel-specific
  {p_end}
{synopt :{opth rt#(string)}}row titles, panel-specific
  {p_end}
{synopt :{opth rst##(string)}}row-spanning titles, panel-specific
  {p_end}
{synopt :{opth extra##(string)}}extra information rows, panel-specific
  {p_end}
{synopt :{opth add_means(string)}}add means of right-hand-side variables, panel-specific
  {p_end}
{synopt :{opth add_mat(string)}}add matrices, panel-specific
  {p_end}


{p 1}{bf:{ul on}Description{ul off}}{p_end}

{pstd} {cmd:mswtable} produces a table in MSWord format (using {cmd:putdocx table}).{p_end}

{pstd} As input, {cmd:mswtable} requires either:{p_end}
{p 6 9} 1. Stata matrix, identified in {cmd:mat}(){p_end}
{p 6 9} 2. Equations stored via {cmd:estimates store}, identified in {cmd:est}(){p_end}

{pstd} {cmd:est}() input can be augmented with:{p_end}
{p 6 9} 3. Means of right-hand-side variables ({cmd:add_means}){p_end}
{p 6 9} 4. Matrix ({cmd:add_mat}){p_end}

{pstd} And both {cmd:mat}() input and {cmd:est}() input can be augmented with:{p_end}
{p 6 9} 5. Excel spreadsheet ({cmd:add_excel}){p_end}

{pstd} {cmd:mswtable} will construct a table with multiple panels (seven panels maximum).{p_end}

{pstd} The constructed table can be saved as a MSWord table (option {bf:outfile}).
Alternatively, if {bf:outfile} is {ul:not} specified but {bf:tabname} instead, the
table (as named in {bf:tabname}) is available for further development and polishing via {cmd:putdocx table}.{p_end}

{pstd} {cmd:mswtable} applies the table aesthetics of the author (e.g. line spacing, justification).
Some of this is modifiable.  ({it:note}: option {cmd:slim} eliminates lines that are inserted for visual
appearance only.){p_end}


{p 1}{bf:{ul on}Options{ul off}}{p_end}

{marker comoptd}{it:{dlgtab:core options}}

{phang} {opth colw:idth(string)} specifies column widths in inches, left to right.  This includes the   
column for the row titles (first column on left) and the columns requested by {cmd:add_} options
({cmd:add_means}, {cmd:add_mat}, {cmd:add_excel}).  "string" is an array of numbers (decimals
are permitted), separated by comma or space.  Column widths can be repeated via shorthand
"#*#": "3*0.8" is equivalent to "0.8,0.8,0.8".  {cmd:colwidth} is required.{p_end}
{pmore} Examples:  {cmd:colw(1.2,0.8,0.8,1)}{p_end}
{p 19}             {cmd:colw(1.5 4*1.1 1.2)}{p_end}

{phang} {opth mat(string)} identifies the input matrix.  ({it:note}: The author's procedure {cmd:matstat}
offers a convenient means of generating a matrix of descriptive statistics.){p_end}

{phang} {opth est(string)} identifies equations that have been stored via {cmd:estimates store}.  Separate the
equation names with comma or space.  In the MSWord table, the columns are ordered left to right as listed
in "string".{p_end}
{p 8 15}{it:notes}:{space 1}Estimation procedure {ul:must} store regression table in r(table) matrix; most/all
estimation procedures do so{p_end}
{p 15 15}{cmd:estimates store} can be applied after {cmd:margins} if the {cmd:post} option has been specified{p_end}
{p 15 15}Equations are aligned in the MSWord table by matching on the names of the right-hand-side variables{p_end}
{pmore} Examples:  {cmd:est(mod1 mod2 mod3 mod4)}{p_end}
{p 19}             {cmd:est(eq3,eq2,eq1)}{p_end}

{phang} {opth dec:imals(string)} specifies number of decimal places for each column/row, including additional columns due to {cmd:add_} options ({cmd:add_means}, {cmd:add_mat}, {cmd:add_excel}) but excluding 
far-left column (row titles).  "string" contains "cols" or "rows", followed by a set of integers; separate
by comma or space.  "cols" and "rows" indicate column-wise and row-wise application, respectively;  
"cols" is the default and may be omitted.  Decimal-place specification can be repeated via shorthand
"#*#": "4*2" is equivalent to "2,2,2,2".  Also, {cmd:mswtable} will fill in based on the last integer
specified: {cmd:dec(1 1 0)} is equivalent to {cmd:dec(1 1 0 0 0)}.  If option {cmd:dec}() is omitted, 
the default is one decimal place.{p_end}
{p 8 15} {it:notes}:{space 1}{cmd:dec} has no effect for {cmd:add_excel} columns that contain alphabetic
characters; even so, include these columns in {cmd:dec}{p_end}
{p 15 15}decimal places for equation statistics (N, AIC) are specified separately (see {cmd:est_stat} below){p_end}
{pmore} Examples:  {cmd:dec(2 2 2 1)}{p_end}
{p 19}             {cmd:dec(rows,5*1,0)}{p_end}

{phang} {opth font(string)} identifies the name of the font and font sizes.  Current 
default font is Cambria, with font sizes (in points):{p_end}
{p 11} 12.5{space 3}title{p_end}
{p 11} 12{space 5}subtitle{p_end}
{p 11} 12{space 5}column and row titles{p_end}
{p 11} 11.5{space 3}body of table{p_end}
{p 11} 10.5{space 3}notes{p_end}
{p 8 8}(Fonts sizes for other table contents, including {cmd:est_se} options - see
{bf:{ul on}Technical Odds and Ends{ul off}} below.){p_end}
  
{p 8}"string" can take two forms:{p_end}
{p 11} (i){space 2}name of font only (must be font available in MSWord){p_end}
{p 11} (ii){space 1}name of font and font sizes (in points){p_end}
{pmore} If (ii), then the name of font is specified followed by the five font sizes; {ul:all five} sizes
must be specified and ordered as shown above.  Separate by comma or space.  Some font names are multiple
words; place these names within quotation marks.  (Font name and font sizes can be permanently re-set at
lines 246ff in mswtable.ado.){p_end}

{pmore} Examples:  {cmd:font(Garamond,12.5,12,12,12,10.5)}{p_end}
{p 19}             {cmd:font("Lucida Sans")}{p_end}
{p 19}             {cmd:font(Arial 12 12 11 10 10)}{p_end}

{phang} {opth title(string)} adds a title above the table, and {opth subt:itle(string)} adds
a subtitle.  Place title/subtitle text within quotation marks.  Multiple lines are indicated
by using "\" as separator; maximum is three lines.  Following the text:{p_end}
{p 11 17}(i){space 2}font:  "bold", "underline", "italic", "none" (default){p_end}
{p 11 17}(ii){space 1}justification:  "left", "center" (default), "right"{p_end}
{pmore}Both font and justification can be requested, in either order.  Separate from
title/subtitle text with comma or space.{p_end}
{pmore}{it:note}: for alternative syntax for table title, see {cmd:title1}
and {cmd:title2} below{p_end}
{pmore} Example:  {cmd:title("Table 2. Regression Results,\by Major Region",bold,left)}{p_end}

{phang} {opth note1(string)} . . . {opth note9(string)} adds notes to the foot of the table
(maximum nine).  "string" is text within quotes.  If lengthy, it can be convenient to place
text in local macro.  A blank line can be inserted by, for example, {cmd:note3(" ")}; blank
lines are allocated less height.  (Option {cmd:slim} eliminates blank lines, including the
blank line that precedes {cmd:note#}.){p_end}

{phang} {opth ct_set(string)} formats the column titles {cmd:ct}().  In either order and separated
by comma or space, "string" contains:{p_end}
{p 11 17}(i){space 2}font:  "bold", "underline", "italic", "none" (default){p_end}
{p 11 17}(ii){space 1}justification:  "left", "center", "right" (default){p_end}
{pmore}Either/both font and justification can be requested.  If {cmd:ct_set} is omitted, column titles
are not bold/underlined/italic and they are right-justified.{p_end}
{pmore} Example:  {cmd:ct_set(underline,center)}{p_end}

{phang} {opth ct(string)} are column titles.  Separate the titles for each successive column with
"!".  Do {ul:not} embed quotation marks; spaces between words in the title are allowed.  Titles are applied
left to right, beginning with the far left column (row title column) and including columns added via {cmd: add_}
options ({cmd:add_means}, {cmd:add_mat}, {cmd:add_excel}).  By default column titles are right-justified
(see {cmd:ct_set}).  Column titles can be left blank by specifying successive "!" ("!!" or "! !").  Multiple
lines in each column title are indicated by using "\" as separator; maximum is four lines.  If {cmd:ct} is
not specified, default is input matrix column names.{p_end}
{pmore} Often it is convenient to construct "string" separately as a local macro.{p_end}
{pmore} Example:  {cmd:ct("`ctitles'")}{p_end}

{phang} {opth rt_set(string)} formats the row titles {cmd:rt}().  In any order and separated
by comma or space, "string" contains:{p_end}
{p 11 17} (i){space 3}font:  "bold", "underline", "italic", "none" (default){p_end}
{p 11 17} (ii){space 2}justification:  "left" (default), "center", "right"{p_end}
{p 11 17} (iii){space 1}"Intercept" right-justified (if last data row):  "intercept_right"{p_end}
{p 11 17} (iv){space 2}"Total" right-justified (if last data row):  "total_right"{p_end}
{pmore}Any or all of these can be requested.  If {cmd:rt_set} is omitted, row titles
are not bold/underlined/italic and they are left-justified.{p_end}
{pmore} Example:  {cmd:rt_set(intercept_right)}{p_end}

{phang} {opth rt(string)} are row titles.  Separate the titles for each successive row with
"!".  Do {ul:not} embed quotation marks; spaces between words in the title are allowed.  Row
titles can be left blank by specifying successive "!" ("!!" or "! !").  Multiple lines in each
row title are indicated by using "\" as separator; maximum is two lines.  Row titles can extend
through the equation statistics rows, adhering to the order in {cmd:est_stat}.  If {cmd:rt} is
not specified, default is input matrix row names.{p_end}
{pmore} As with {cmd:ct}(), it is convenient to make "string" a local macro that contains the set of row titles,
in order.{p_end}

{phang} {opth outf:ile(string)} specifies name for MSWord file and where it is to be saved.  If not   
specified, then putdocx table remains open (and the table can be referred to as named in {cmd:tabname}()).  
Within quotes, full file specification should be provided: exact directory + file name.  "replace"  
(default) or "append" are options; these follow the file specification, with comma or space  
as separator.  If "append", each table is started on a new page ({cmd:putdocx} option "pagebreak").  
A further option is "landscape"; this requests landscape orientation (default is portrait).{p_end}
{pmore} Example:  {cmd:outf("c:/Users/johnc/project1/analysis/tab1", append landscape)}{p_end}

{marker comoptd}{it:{dlgtab:est_ options}}

{phang} {opth est_stat(string)} requests equation "statistics" (N, AIC, etc).  
These are placed at the bottom of the table, following the coefficients.  "string"
consists of pairs:{p_end}
{p 11 16} (i){space 2}name of the statistic (Stata naming convention){p_end}
{p 11 16} (ii){space 1}number of decimal places for the statistic{p_end}
{pmore} Separate (i) and (ii) with comma or space.  Multiple statistics can be requested - separate
with "!".  Certain statistics are renamed, e.g. "r2_a" becomes "Adjusted R-squared".  For further
renaming, insert at lines 345ff in mswtable.ado.  Alternatively, statistic names can be applied
via {opth rt(string)}.{p_end}
{pmore} Examples:  {cmd:est_stat(N,0 ! r2_a,2 ! bic,1)}{p_end}
{p 19}             {cmd:est_stat(N 0 ! r2_a 2)}{p_end}

{phang} {opth est_star(string)} requests that asterisks be placed on the regression coefficients,
immediately to the right.  "string" is a listing of p-value thresholds (maximum three), separated
by comma or space; they {ul:must} be listed in descending order.  In the MSWord table, the first p-value
will be denoted by one asterisk, the second by two, and the third by three.  Default values are 
0.05, 0.01, and 0.001; {cmd:est_star} without arguments requests these three.  {cmd:mswtable} does
not automatically generate a footnote indicating what the asterisks represent, this must be done
manually (e.g. as {cmd:note1}).{p_end}
{pmore} Examples:  {cmd:est_star}{p_end}
{p 19}             {cmd:est_star(0.10 0.05)}{p_end}

{phang} {opth est_se(string)} requests inclusion of regression coefficients' uncertainty or statistical
tests.  The available items for "string" are many; they fall into three categories:{p_end}

{pmore} (i){space 3}One of the following:{p_end}
{p 14 22}        "se"{space 4}standard error{p_end}
{p 14 22}        "ci"{space 4}confidence interval (95%){p_end}
{p 14 22}        "ci()"{space 2}confidence interval, specifying:  p-value, size of font, and comma vs. dash as separator (see below){p_end}
{p 14 22}        "z"{space 5}z-statistic (or for some models, t-statistic instead){p_end}
{p 14 22}        "p"{space 5}p-value for z-statistic (two-sided test){p_end}

{p 8 14} (ii){space 2}"below" or "beside" or "beside()":  this is placement of item (i), either below or immediately
to the right of the coefficient.  "beside" placement is incompatible with {cmd:est_star}.{p_end}

{p 8 14} (iii){space 1}"paren" or "bracket":  whether enclosed in parentheses or bracket (or neither).{p_end}

{p 8 8} Separate items (i), (ii), and (iii) with comma or space.  Any or all of the three can be specified, in
any order.  The defaults are "se", "below", and neither parentheses nor bracket; {cmd:est_se} without arguments
requests these three.{p_end}

{pmore} "beside()" requests "beside" location, and within the parentheses (separated by comma or space):{p_end}
{p 11 19}- text for column title, within quotation marks ({ul:must} be first element within parentheses){p_end}
{p 11 19}- width of columns (in inches){p_end}
{p 11 19}- number of spaces to be inserted in front of column title and contents of each cell{p_end}
{p 10 10}The second and third items are optional and can occur in either order.  {cmd:mswtable} assumes:{p_end}
{p 11 19}- if numeric >=.40 & <2: column width (inches){p_end}
{p 11 19}- if numeric >=2 & <=5: number of spaces ({ul:must} be integer){p_end}

{pmore} "ci()" is syntax for specifying within the parentheses: p-value, size of font, and comma vs. dash.{p_end}
{p 11 13}- if numeric <.40:  p-value (default is .05){p_end}
{p 11 13}- if numeric >5:  font size (default is 1.5-point less than body-of-table font){p_end}
{p 11 13}- if "dash":  separate lower and upper bounds by dash (default is comma){p_end}
{p 10 10} Any or all of these can be specified, in any order; separate by comma or space.{p_end}

{pmore} Within one {opth est_se(string)}, two items can be requested (i.e. "below" and "beside").  Separate
with "!".{p_end}

{p 8 51}Examples:   {cmd:est_se}{space 26}standard error, below, no parentheses/bracket{p_end}
{p 19 51}           {cmd:est_se(z beside paren)}{space 10}z-statistic, beside, in parentheses{p_end}
{p 19 51}           {cmd:est_se(p beside("p value",1,3))}{space 1}p value, beside, no parentheses/bracket,
"p value" columm title, 1.0 inch column width, 3 extra spaces{p_end}
{p 19 51}           {cmd:est_se(ci(.10))}{space 17}90% confidence interval, below, no parentheses/brackets{p_end}
{p 19 51}           {cmd:est_se(ci(10.5,dash),bracket)}{space 3}95% confidence interval, font size 10.5,
separate by dash, below, in brackets{p_end}

{phang} {opth est_vars(string)} specifies which right-hand-side variables to include in the table (default is
inclusion of all variables).  "string" are the names of the variables, separated by comma or space.  These are
the names employed in the regression procedure, not as re-named via {cmd:rt}().  Factor variable notation must
be simplified to "i.<{it:variable}>", e.g. "i.region" not "ib3.region".  Intercept must be explicitly requested
(usually "_cons").{p_end}
{pmore}Example:  {cmd:est_vars(schooling,i.region,_cons)}{p_end}

{phang} {opth est_no(string)} singles out equations for which {cmd:est_star} and {cmd:est_se} are {ul:not} applied.  
"string" is a list of integers, separated by comma or space, specifying columns in the equation matrix:
from the left, the first equation is "1", the second equation is "2", and so forth.  (Columns inserted due
to {cmd:add_means}, {cmd:add_mat}, or {cmd:add_excel} are {ul:not} counted.){space 2}The 
default is to apply {cmd:est_star} and {cmd:est_se} to all equations.{p_end}
{pmore}Example:  {cmd:est_no(4,5)}{p_end}


{p 1}{bf:{ul on}Examples: Core Options Only{ul off}}{p_end}
{asis}

    Matrix input
    ------------

    #d ;

    local ctitles
    "Region !
     Mean\DFS !
     Mean\IFS !
     N\Surveys ! ";

    local regions 
    "East & Southern Africa ! 
     Middle & West Africa !
     Latin America & Caribbean !
     South & Southeast Asia !
     West Asia & North Africa !
     All Regions";

     mswtable, mat(TAB11) 
               colw(2.1,0.8,0.8,1)
               dec(1,1,0)
               title("Table 1.  Mean DFS and Mean IFS")
               ct("`ctitles'") 
               rt("`regions'") 
               note1("Sample:  currently-in-union women ages 15-49")
               outf("$D/analysis/tab1", append);


     Estimates input
     ---------------

     #d ;

     local cols
     "Explanatory Variables !
      1 !
      2 !
      3 !
      4 !";

     local xvars 
     "Total Fertility Rate ! 
      Contraceptive prevalence !
      % births unwanted !
      Mean ideal number !
      Cure fraction !
      East & Southern Africa !
      Middle & West Africa !
      Latin America & Carib !
      South & Southeast Asia !
      West Asia & North Africa !
      Intercept !
      Number of surveys !
      R-squared (adjusted) !
      BIC";

      mswtable, est(eq1 eq2 eq3 eq4)
                colw(2.0,1.0,0.8,0.8,0.8) 
                dec(2 2 1 1)
                est_stat(N,0! r2_a,2! bic,1)
                est_star(.10,.01,.001) 
                est_se
                title("Table 2.  Modeling DFS")
                subt("OLS Estimates")
                note1("Significance:    * p<.05   ** p<.01   *** p<.001")
                note2(" ")
                note3("Standard error in parentheses")
                ct("`cols'")
                rt("`xvars'")
                outf("$D/analysis/tab2");

      mswtable, est(eq1 eq2 eq3 eq4) 
                colw(2.0,1.0,3*0.8) 
                dec(2)
                est_stat(N,0! r2_a,2! bic,1)
                est_se(ci,beside,bracket)
                title("Table 2.  Modeling DFS",bold)
                subt("OLS Estimates",bold)
                note1("`NOTE1'")
                note2(" ")
                note3("`NOTE3'")
                ct_set(underline)
                ct("`cols'")
                rt("`xvars'")
                outf("$D/analysis/tab2", append landscape);


{smcl}
{marker comoptd}{it:{dlgtab:beyond core}}

{phang} {opth cst_set(string)} formats the column-spanning titles {cmd:cst#} and {cmd:cst1#} (see
below).  Alternatively, {opth cst_set1(string)} and {opth cst_set11(string)} format the first-level and
second-level separately.  In either order and separated by comma or space, "string" contains:{p_end}
{p 11 17} (i){space 2}font:  "bold", "underline" (default), "italic", "none"{p_end}
{p 11 17} (ii){space 1}justification:  "left", "center" (default), "right"{p_end}
{pmore}Both font and justification can be requested.{p_end}
{pmore} Examples:  {cmd:cst_set(bold right)}{p_end}
{p 19}             {cmd:cst_set1(underline,center)}{space 2}{cmd:cst_set11(bold,center)}{p_end}

{phang} {opth cst1(string)} . . . {opth cst10(string)} are column titles that span multiple columns.  
They are placed in a row above the main column-by-column titles, and by default are underlined and 
centered (see {cmd:cst_set}).  Contents of {cmd:cst#} are as follows, in this order and separated
by comma or space:{p_end}
{p 11 17} (i){space 3}text for title, in quotes{p_end}
{p 11 17} (ii){space 2}starting column for spanning title{p_end}
{p 11 17} (iii){space 1}number of columns to be spanned{p_end}
{pmore}Item (i):{space 2}multiple lines are indicated by using "\" as separator; maximum is three
lines.{p_end}
{pmore}Item (ii):{space 1}"starting column" refers to the data matrix (i.e. far-left row title column
is excluded).{p_end}
{pmore}Items (ii) and (iii):{space 1}columns due to {cmd:add_means}, {cmd:add_mat} or {cmd:add_excel} are
counted, but {ul:not} columns inserted for {cmd:est_star} or {cmd:est_se} or {cmd:add_cols}.{p_end}
{pmore}{it:note}: {cmd:cst1}...{cmd:cst#} in terms of columns {ul:must} be ordered left to right.{p_end}
{pmore} Examples:  {cmd:cst1("Means" 1 2)}{p_end}
{p 19}             {cmd:cst2("Demographic\Variables",3,3)}{p_end}

{phang} {opth cst11(string)} . . . {opth cst15(string)} are higher-level column-spanning titles placed  
above {cmd:cst1}-{cmd:cst10}.  The syntax is identical to {cmd:cst1}-{cmd:cst10}, except maximum is two lines.  
{cmd:cst11}-{cmd:cst15} presume {cmd:cst1}-{cmd:cst10} has been specified.{p_end}

{phang} {opth rst_set(string)} specifies two optional features of the row spanning titles {cmd:rst#},
in either order and separated by comma or space:{p_end}
{p 11 16} (i){space 2}font: "bold", "underline", "italic", "none" (default){p_end}
{p 11 16} (ii){space 1}indentation: indent rows encompassed by row spanning title; no indent is default{p_end}
{pmore} Syntax for indentation is either: "indent" (3 spaces); "indent()", with number of spaces (1-8) in parentheses.{p_end}
{pmore} Examples:  {cmd:rst_set(underline)}{p_end}
{p 19}             {cmd:rst_set(bold,indent)}{p_end}

{phang} {opth rst1(string)} . . . {opth rst15(string)} are row-spanning titles, i.e. titles that apply to multiple
rows.  The rows might be, for example, categories of a variable (e.g. for place of residence, "rural" "small city"
"large city").  The row-spanning title is inserted above the rows to which it applies - text as specified, with
the remainder of the row blank.  The spanning title may be bold or underlined or italic, or none of these 
(default); see {cmd:rst_set}.  Each {cmd:rst#} must consist of the following, separated by comma or space:{p_end}
{p 11 16} (i){space 3}text for title, in quotes; row spanning titles can {ul:not} contain multiple lines or commas{p_end}
{p 11 16} (ii){space 2}starting row for spanning title{p_end}
{p 11 16} (iii){space 1}number of rows encompassed by spanning title{p_end}
{pmore} {it:notes}: starting row is {ul:without} taking into account rows inserted for previous row spanning titles{p_end}
{p 15 15}row spanning title is inserted {ul:above} the row specified by (ii){p_end}
{p 15 15}the {cmd:rst#} {ul:must} be ordered top to bottom of the table{p_end}
{p 15 15}row spanning title can {ul:not} contain comma{p_end}
{pmore} Example:  {cmd:rst1("Place of Residence",4,3)}{p_end}

{phang} {opth add_cols(string)} requests insertion of blank columns.  Typically this is
simply for visual purposes, i.e. clear visual separation of sets of columns.  "string"
consists of pairs:{p_end}
{p 11 16} (i){space 2}column {ul:before which} blank column will be inserted{p_end}
{p 11 16} (ii){space 1}width of column, in inches (decimals are permitted){p_end}
{pmore} Separate (i) and (ii) with comma or space.  Multiple column insertions can be
requested - separate with "!".  Item (i) refers to columns in the data matrix, 
i.e. excluding left-hand column (row title column) but including extra columns due to
{cmd:add_} options ({cmd:add_means}, {cmd:add_mat}, {cmd:add_excel}).{p_end}
{pmore} Example:  {cmd:add_cols(3,0.2 ! 6,0.4)}{p_end}

{phang} {opth extra1(string)} . . . {opth extra9(string)} are additional rows of information.  
These are added to the foot of the table, following data specified in {cmd:mat}() or {cmd:est}()
and also following equation statistics (option {cmd:est_stat}()) but prior to {cmd:note#}.  
Each "string" contains column-by-column text, starting with the first column on left (row title column).
Columns inserted due to {cmd:add_means}, {cmd:add_mat}, or {cmd:add_excel} are included.   
Separate the column entries with "!", and do {ul:not} embed quotation marks.  Spaces within
entries are allowed.  Cells can be left blank by specifying successive "!" ("!!" or
"! !").  Empty rows (i.e. entirely "! !") are one-third height.{p_end}
{pmore} Examples:  {cmd:extra1(State fixed effects !No !No !Yes !Yes)}{p_end}
{p 19}             {cmd:extra1(State fixed effects ! ! Yes ! !Yes)}{p_end}


{marker comoptd}{it:{dlgtab:additional options}}

{phang} {opth add_means(string)} requests addition of column of mean values of the right-hand-side variables.  
"string" contains two items, in this order and separated by comma or space:{p_end}
{p 11 16} (i){space 2}"left" or "right" - whether the column of means will become the far-left or far-right column{p_end}
{p 11 16} (ii){space 1}equation name - must be among the equation names in {cmd:est}(){p_end}
{pmore} "left" is the default for item (i) and may be omitted.{p_end}
{pmore}The following options {ul:must} account for the {cmd:add_means} column: 
{cmd:colwidth}, {cmd:dec}, {cmd:ct}, {cmd:cst#}, {cmd:cst1#}, {cmd:extra#}{p_end}
{pmore}Examples:  {cmd:add_means(eq1)}{p_end}
{p 19}            {cmd:add_means(right,eq1)}{p_end}

{phang} {opth add_mat(string)} requests insertion of a matrix.  This enables one to augment a table of 
estimation results with other numerical values.  "string" contains two items, in this order and
separated by comma or space:{p_end}
{p 11 16} (i){space 2}"left" or "right" - whether the matrix will become the far-left or far-right columns{p_end}
{p 11 16} (ii){space 1}matrix name{p_end}
{pmore}"left" is the default for item (i) and may be omitted.
The matrix will be inserted at the top row.  It may have fewer rows than the remainder of the table.
And the matrix may contain missing values (".") - {cmd:mswtable} replaces these with " ".{p_end}
{pmore}The following options {ul:must} account for the {cmd:add_mat} columns: 
{cmd:colwidth}, {cmd:dec}, {cmd:ct}, {cmd:cst#}, {cmd:cst1#}, {cmd:extra#}{p_end}
{pmore}Examples:  {cmd:add_mat(SUM)}{p_end}
{p 19}            {cmd:add_mat(right ZZ)}{p_end}

{phang} {opth add_excel(string)} requests insertion of an excel spreadsheet.  Among other uses, this facilitates
inclusion of alphanumeric columns.  "string" contains two items, in this order and separated by
comma or space:{p_end}
{p 11 16} (i){space 2}"left" or "right" - whether the spreadsheet will become the far-left or far-right columns{p_end}
{p 11 16} (ii){space 1}excel spreadsheet file (full file specification - exact directory + file name + xlsx){p_end}
{pmore}"left" is the default for item (i) and may be omitted.
The spreadsheet is inserted at the top row.  It may have fewer rows than the remainder
of the table.  And the spreadsheet may contain missing values (".") - {cmd:mswtable} replaces
these with " ".  The spreadsheet must {ul:not} have a first row containing column
titles.  {it:note}: {cmd:dec} is not applied if excel column contains alphabetic or
alphanumeric values.{p_end}
{pmore}The following options {ul:must} account for the {cmd:add_excel} columns: 
{cmd:colwidth}, {cmd:dec}, {cmd:ct}, {cmd:cst#}, {cmd:cst1#}, {cmd:extra#}{p_end}
{pmore}Example:  {cmd:add_excel(right,"c:/Users/johnc/data/info1.xlsx")}{p_end}

{phang} {cmd:add_} options - compatibilities:{p_end}
{p 8 10} - {cmd:add_means} and {cmd:add_mat} supplement {cmd:est}() input but {ul:not} {cmd:mat}() input{p_end}
{p 8 10} - {cmd:add_means} and {cmd:add_mat} {ul:cannot} be requested together{p_end}
{p 8 10} - {cmd:add_excel} can supplement either {cmd:est}() or {cmd:mat}() input{p_end}
{p 8 10} - {cmd:add_excel} and {cmd:add_mat}: if both are requested, excel is placed on outside
(far left or far right){p_end}

{phang} {opth title1(string)} and {opth title2(string)} is two-column alternative to
{opth title(string)}.  Syntax and options are same as {cmd:title}, except:{p_end}
{p 11 16} (i){space 2}default horizontal justification for both columns is "left"{p_end}
{p 11 16} (ii){space 1}default width of {cmd:title1} is 0.8 inches, which can be modified
by specifying numeric value following text{p_end}
{pmore} Subtitle, if requested, is placed in {cmd:title2} column.{p_end}
{pmore} Example:  {cmd:title1("Table A.11.",bold,1.2)}{space 2}{cmd:title2("Full Regression Results, by Major Region")}{p_end}

{phang} {opt firstX} and {opt lastX} request insertion of low-height row between:{p_end}
{p 11 16} (i){space 2}first data row and next row  [{cmd:firstX}]{p_end}
{p 11 16} (ii){space 1}last data row and previous row  [{cmd:lastX}]{p_end}
{pmore} These are for visual enhancement and might be appropriate if, for example, the first
or last row is "Total", or to provide some separation for the regression intercept.  
In multi-panel tables, this request is carried out panel-by-panel.  
{it:note}: option {cmd:slim} overrides these two options.

{phang} {opt extra_place} reverses the placement of the {cmd:est_stat} and {cmd:extra#} rows.
The default order is {cmd:est_stat} followed by {cmd:extra#}.{p_end}

{phang} {opth tline(string)} and {opth bline(string)} control the appearance of the lines:{p_end}
{p 11 18} {cmd:tline}: at the top of table (above column titles but below title and subtitle){p_end}
{p 11 18} {cmd:bline}: at the bottom of table (immediately before any notes){p_end}
{pmore} Options are "double" (double line) and "bold" (single bold line); both options  
{ul:cannot} be requested together.  The default is non-bold single line.{p_end}

{phang} {opt slim} eliminates rows that contain no information.  These are rows inserted only
to improve visual clarity.  (note: {cmd:slim} does {ul:not} block {cmd:add_cols}.){p_end}

{phang} {opth tabname(string)} gives a name to the table, for {cmd:putdocx} use.  
The name can be used post-{cmd:mswtable} if the table is not saved (i.e. no {cmd:outfile} option),
allowing for additions or other enhancements to the table via {cmd:putdocx table}.{p_end}


{p 1}{bf:{ul on}More Examples{ul off}}{p_end}
{asis}

    Matrix input
    ------------

    #d ;

     mswtable, mat(TAB11) 
               colw(2.1,0.8,0.8,1)
               dec(1,1,0)
               title("Table 1.  Mean DFS and Mean IFS")
               subt("Estimates by Region")
               ct("`ctitles'") 
               cst1("Means",1,2) cst2("Sample",3,1)
               rt("`regions'") 
               lastX
               note1("Sample:  currently-in-union women ages 15-49")
               note2(" ")
               note3("DFS = Desired Family Size")
               note4("IFS = Ideal Family Size")
               outf("$D/analysis/tab1");


     Estimates input
     ---------------

     #d ;

      mswtable, est(eq1 eq2 eq3 eq4) 
                colw(2.0,4*0.8,1.0) 
                dec(4*2 1)
                est_stat(N,0! r2_a,2! bic,1)
                est_star 
                est_se(paren)
                add_means(right eq4)
                add_cols(1,0.2 ! 5,0.2)
                title("Table 2.  Modeling DFS")
                subt("OLS Estimates")
                extra1(State fixed effects !No !No !Yes !Yes)
                extra2(Ridiculous model !Yes !No !Yes !No)
                note1("Significance:    * p<.05   ** p<.01   *** p<.001")
                ct("`cols'")
                rt("`xvars'")
                lastX
                outf("$D/analysis/tab2", append);

      mswtable, est(eq1 eq2 eq3 eq4)   
                colw(2.0,2*0.7,4*0.8) 
                dec(2)
                est_no(4)
                est_stat(N,0! r2_a,2! bic,1)
                est_se(ci(.01,10),bracket)
                add_excel("c:/Users/johnc/data/info1.xlsx")
                title1("Table 11.") 
                title2("Modeling Desired Family Size [DFS],\by Major Geopolitical Region")
                subt("Linear Regressions, with Fixed Effects for State")
                extra1(State fixed effects !No !No !Yes !Yes)
                extra2(Ridiculous model !Yes !No !Yes !No)
                note1("0.90 confidence interval in brackets")
                note2(" ")
                note3("Sample:  Women Ages 30+")
                cst_set(right)
                cst("Equations",4,4)
                ct_set(underline)
                ct("`cols'")
                rt("`xvars'")
                rst_set(underline,indent)
                rst1("Demographic",1,5)  rst2("Region",6,5)
                outf("$D/analysis/tab3", landscape);


{smcl}
{marker comoptd}{it:{dlgtab:multiple panels (max 7)}}

{phang} Column titles ({cmd:ct}) cannot be panel-specific - these are fixed across panels.{p_end}

{phang} {opth mat1(string)} . . . {opth mat7(string)} identifies the input matrices, panel-by-panel.  The  
suffix indexes the panel.  These are stacked in sequential order, hence all matrices must contain the same
number of columns.{p_end}

{phang} {opth est1(string)} . . . {opth est7(string)} identifies the names of equations available
via {cmd:estimates store}, panel-by-panel.  See {cmd:est} above.  
The suffix indexes the panel.  These are stacked in sequential order, hence all panels must contain the
same number of equations.{p_end}
{pmore} Examples:  {cmd:est1(mod11 mod12 mod13 mod14)}{p_end}
{p 19}             {cmd:est2(mod21 mod22 mod23 mod24)}{p_end}

{phang} {opth est_stat1(string)} . . . {opth est_stat7(string)} requests equation "statistics" (N, AIC, etc),
panel-by-panel.  For syntax, see {cmd:est_stat} above.  If only {cmd:est_stat}() is specified, the same equation
statistics are provided for every panel.{p_end}

{phang} {opth est_vars1(string)} . . . {opth est_vars7(string)} specifies right-hand-side variables to
show, panel-by-panel.  For syntax, see {cmd:est_vars} above.  If only {cmd:est_vars}() is specified,
the same set of variables is selected for every panel.{p_end}

{phang} {opth dec1(string)} . . . {opth dec7(string)} sets the decimal places panel-by-panel.  For
syntax, see {cmd:dec} above.  "rows" can be specified only in {cmd:dec1} (and then applies to every
panel).  If only {cmd:dec}() is specified, this is applied to every panel.{p_end}

{phang} {opt pline} draws single lines separating the panels.  
The lines are drawn immediately above the panel titles (if any).{p_end}

{phang} {opth pspace(string)} specifies size of vertical gap between panels: "large" or "small" relative to default.{p_end}

{phang} {opth pt_set(string)} specifies format of panel titles (see {cmd:pt#}), and row-title
indentation.  Separate with comma or space:{p_end}
{p 11 17} (i){space 3}title font:  "bold", "underline" (default), "italic", "none"{p_end}
{p 11 17} (ii){space 2}title justification:  "left" (default), "center", "right"{p_end}
{p 11 17} (iii){space 1}indentation: indent row titles (+ row-spanning titles) within panels; no indent is default{p_end}
{p 8 8} Any/all three can be requested.  And for the font, any {ul:two} combinations of "underline", "bold", and "italic"
can be requested.{p_end}
{pmore} Syntax for indentation is either: "indent" (3 spaces); "indent()", with number of spaces (1-8) in parentheses.{p_end}
{pmore} Example:   {cmd:pt_set(bold,indent(5))}{p_end}

{phang} {opth pt1(string)} . . . {opth pt7(string)} are text labels for the panels.  
The suffix indexes the panel.  
Text should be enclosed in quotes.  
Multiple lines are allowed, using "\" as separator; maximum is two lines.  
In the MSWord table, each panel title is inserted as a separate row, and by default is underlined and
left-justified (see {cmd:pt_set}).  Panel titles are optional: titles may be provided for all, some, 
or none of the panels.{p_end}

{phang} {opth rt1(string)} . . . {opth rt7(string)} identify text labels for the rows, with the suffix
indexing the panel.  See {cmd:rt} above.  If only {cmd:rt}() is specified, then the same row titles are
applied to every panel.{p_end}

{phang} {opth rst11(string)} - {opth rst19(string)} . . . {opth rst71(string)} - {opth rst79(string)}
are panel-specific row spanning titles, maximum nine per panel (as against fifteen in one-panel table).   
Suffixes 11-19 are for the first panel, suffixes 21-29 for the second panel, etc.  
For syntax, see {cmd:rst1} - {cmd:rst15} above.  Numbering of rows is {ul:within-panel} (i.e. the first
row of each panel is 1).  {opth rst1(string)} - {opth rst15(string)} instead can be specified, in which
case the same row spanning titles are applied to every panel.  
Either {cmd:rst1}-{cmd:rst15}  OR  {cmd:rst11}-{cmd:rst19} etc. must be chosen, they cannot be mixed.  
If the row spanning  titles are panel-specific, they may be specified for some but not all panels
(as indicated by suffixes 11-19, 21-29, etc.).{p_end}

{phang} {opth extra11(string)} - {opth extra18(string)} . . . {opth extra71(string)} - {opth extra78(string)} are
additional rows of information, panel-by-panel.  Suffixes 11-18 are for the first panel, suffixes 21-28 for the
second panel, etc.  For syntax, see {cmd:extra1} - {cmd:extra9} above. {opth extra1(string)} - {opth extra9(string)} 
instead can be specified, in which case one set of extra rows is inserted at the bottom of the table ({ul:not} 
panel-by-panel), and option {cmd:extra_place} has no effect.{p_end}

{phang} {opth add_means(string)}.  
An equation name for {ul:every} panel must be specified, in order.
These must be consistent with the names in {cmd:est#}.  Separate with comma or space.
The panel-by-panel equation names follow "left" or "right", unless this is omitted ("left" is default).
Placement of means "left" or "right" is the same in every panel.{p_end}
{pmore} Examples:  {cmd:add_means(mod1 mod2 mod3)}{p_end}
{p 19}             {cmd:add_means(right,eq1_1,eq2_1,eq3_1}}{p_end}

{phang} {opth add_mat(string)}.  
The matrices must be panel-specific, and ordered from first to last panel.  Separate with comma or
space.  The panel-by-panel matrix names follow "left" or "right", unless this is omitted ("left" is
default).  The placement "left" or "right" is the same in every panel.  All {cmd:add_mat} matrices
{ul:must} have the same number of columns.{p_end}
{pmore} Example:  {cmd:add_mat(right,X1,X2,X3}}{p_end}

{phang} {opth add_excel(string)}.  
There is no panel-specific syntax for this option.  The spreadsheet will be appended to the full
table -- all panels inclusive.{p_end}


{p 1}{bf:{ul on}Multiple Panel Example{ul off}}{p_end}
{asis}

     mswtable, est1(eq1_1 eq1_2 eq1_3 eq1_4) 
               est2(eq2_1 eq2_2 eq2_3 eq2_4) 
               colw(2.0,1.0,0.8,0.8,0.8) 
               dec(2)
               est_stat(N,0! r2_a,2! bic,1)
               est_star(.01,.001) 
               title("Table 4.  Modeling DFS")
               subt("OLS Estimates")
               extra11(State fixed effects !No !No !Yes !Yes)
               extra12(Ridiculous model !Yes !No !Yes !No)
               extra21(State fixed effects !No !No !Yes !Yes)
               extra22(Ridiculous model !Yes !No !Yes !No)
               note1("Significance:    * p<.05   ** p<.01   *** p<.001")
               cst1("Equations" 1 4)
               ct("`cols'")
               rt1("`xvars'")  rt2("`xvars'")
               pt_set(center,bold)
               pt1("Low fertility (TFR < 4.5)")
               pt2("High fertility (TFR >= 4.5)")
               pline  pspace(large)  
               tline(double) bline(double)
               outf("$D/analysis/tab4");


{smcl}
{p 1}{bf:{ul on}Technical odds and ends{ul off}}{p_end}

{pstd} {it:Cell justification (horizontal), non-modifiable}:{p_end}
{p 8 10} - left-justified:  row titles; notes ({cmd:note#}); {cmd:est_star} asterisks; {cmd:est_se} cells 
in "beside" location{p_end}
{p 8 10} - right-justified:  all data cells; row titles for {cmd:est_stat} and {cmd:extra#}{p_end}

{pstd} {it:Table width}:{p_end}
{pmore}{cmd:mswtable} constrains the width of the table to be the sum of the column widths ({cmd:colwidth}),
plus columns inserted for {cmd:est_star}, {cmd:est_se}, {cmd:add_cols}, {cmd:add_means}, {cmd:add_mat}, and
{cmd:add_excel}.  Although MSWord does not always perfectly comply (?!?).{p_end}

{pstd} {it:Line spacing within cells}:{p_end}
{pmore}So far as I can tell, line spacing within cells can only be set within MSWord.  This is relevant if
e.g. column titles are multi-row.  {cmd:mswtable} is designed assuming line spacing = "single".{p_end}

{pstd} {cmd:est_se} {it:column widths}:{p_end}
{pmore}In "beside" placement:{p_end}
{p 8 10} - asterisk columns: 0.28 inch{p_end}
{p 8 10} - standard errors, p-values, z-statistics: 0.75*{cmd:colwidth} (unless set in "beside()"){p_end}
{p 8 10} - confidence intervals: 1.4*{cmd:colwidth}{p_end}

{pstd} {cmd:est_se} {it:decimal points}:{p_end}
{p 8 10} - standard errors: one decimal point more than the coefficients (see {cmd:dec}){p_end}
{p 8 10} - z-statistics: two decimal points{p_end}
{p 8 10} - p-values: three decimal points{p_end}
{p 8 10} - confidence intervals: same as coefficients (see {cmd:dec}){p_end}

{pstd} {it:Default font sizes}:{p_end}
{p 8 10} - statistics (N, aic, etc): 0.5-point less than body-of-table font{p_end}
{p 8 10} - "extra" information: 0.5-point less than body-of-table font{p_end}
{p 8 10} - standard errors, z-statistics, p-values: 1.0-point less than body-of-table font{p_end}
{p 8 10} - confidence intervals: 1.5-point less than body-of-table font (but see "ci()" sub-option to {cmd:est_se}){p_end}
{p 8 10} {it:note}: these default sizes can be modified at lines 270ff in mswtable.ado{p_end}

{pstd} {it:Fonts and row heights}:{p_end}
{pmore} Some fonts are by their nature taller (or shorter).  {cmd:mswtable} accounts for this in setting
row heights.  Specifically, row heights are inflated for {it:Arial} and {it:LM Roman 12}.  Inflation/deflation 
can be applied to other fonts by inserting code at lines 288ff in mswtable.ado.{p_end}

{pstd} {cmd:rt} {it:row titles and row heights}:{p_end}
{pmore} {cmd:mswtable} is not smart about row heights.  Rows with multi-line titles are set higher,
but only those rows, resulting in non-uniform row heights if the row titles are not entirely one line or two lines.  
Confining all row titles to one line is recommended.{p_end}

{pstd} {cmd:extra#}:{p_end}
{pmore} {cmd:extra} rows can be used for quantitative values not available in the statistics Stata offers following regression estimation, if these values are placed in macros.  
These could be, for example, mean values of the dependent variables.{p_end}


{p 1}{bf:{ul on}Matrix basics{ul off}}{p_end}
{asis}

     List existing matrices:  matrix dir

     Examine contents of matrix:  matrix list A

     Create 5x3 matrix with cell contents ".":  matrix A = J(5,3,.)

     Create matrix from results:  matrix A = r(table)

     Combine matrices side-by-side:  matrix C = A,B  ("column join")

     Stack matrices:  matrix D = A\B\C  ("row join")

     Transpose matrix:  matrix B = A'

     Sub-matrix extraction:
        matrix B = A[2,1...]      2nd row, all columns
        matrix B = A[1...,3]      All rows, 3rd column
        matrix B = A[2...,2]      2nd to last row, 2nd column
        matrix B = A[3,3...]      3rd row, 3rd to last column
        matrix B = A[1..3,1...]   1st through 3rd row, all columns
        matrix B = A[2..4,1..3]   2nd through 4th row, 1st through 3rd column

     Sub-matrix substitution:
        matrix B[1,1] = A         Copy in matrix A, upper left corner at row 1 and column 1
        matrix B[2,3] = A         Copy in matrix A, upper left corner at row 2 and column 3


{smcl}
{p 1}{bf:{ul on}Author{ul off}}{p_end}

{pstd} John Casterline, Ohio State University, casterline.10@osu.edu




