{smcl}
{* 3jun2024}{...}
{hi:help mswtable}
{hline}

{p 1}{bf:{ul on}Title{ul off}}{p_end}

{p 6}{hi:mswtable} {hline 2} Wrapper for putdocx table

{p 1}{bf:{ul on}Syntax{ul off}}{p_end}

{p 6 15 2}
{cmd:mswtable} , {opth colw:idth(string)}
[ {help mswtable##comopt:{it:options}}
 ]


{synoptset 23 tabbed}{...}
{marker comopt}{synopthdr:Core Options}
{synoptline}
{synopt :{opth colw:idth(string)}}width of each column (in inches) ({ul:required} option)
  {p_end}
{synopt :{opth mat(string)}}matrix input: identifies matrix
  {p_end}
{synopt :{opth est(string)}}estimates input: identifies stored equations
  {p_end}
{synopt :{opth est_stat(string)}}estimates input: requests equation statistics (N, AIC, etc.)
  {p_end}
{synopt :{opth est_star(string)}}estimates input, coefficient tests: requests asterisks
  {p_end}
{synopt :{opth est_se(string)}}estimates input, coefficient precision: requests standard error, etc.
  {p_end}
{synopt :{opth sdec(string)}}number of decimal places, column-specific 
  {p_end}
{synopt :{opth font(string)}}font: type of font, font sizes
  {p_end}
{synopt :{opth title(string)}}title for table
  {p_end}
{synopt :{opth subt:itle(string)}}subtitle for table
  {p_end}
{synopt :{opth note#(string)}}notes placed at foot of table (maximum nine)
  {p_end}
{synopt :{opth ct(string)}}column titles
  {p_end}
{synopt :{opth cst_set(string)}}column-spanning titles: set font (bold, underline, neither)
  {p_end}
{synopt :{opth cst#(string)}}column-spanning titles: lower level (maximum ten)
  {p_end}
{synopt :{opth cst1#(string)}}column-spanning titles: higher level (maximum five)
  {p_end}
{synopt :{opth rt(string)}}row titles
  {p_end}
{synopt :{opth rst_set(string)}}row-spanning titles: set font (bold, underline, neither) and indentation
  {p_end}
{synopt :{opth rst#(string)}}row-spanning titles: text and location (maximum sixteen)
  {p_end}
{synopt :{opth extra#(string)}}extra information rows (maximum nine), placed below coefficients and statistics
  {p_end}
{synopt :{opth outf:ile(string)}}MSWord table: directory where it is to be written
  {p_end}

{marker comopt}{synopthdr:Additional Options}
{synoptline}
{synopt :{opth est_means(string)}}add column of means of right-hand-side variables
  {p_end}
{synopt :{opth est_mat(string)}}add matrix
  {p_end}
{synopt :{opth est_no(string)}}equations omitted from coefficient precision (options {cmd:est_star} and {cmd:est_se})
  {p_end}
{synopt :{opt extra_place}}reverse placement of rows for {cmd:est_stat} and {cmd:extra#}
  {p_end}
{synopt :{opth tline(string)}}top line in table: format (bold, double, neither)
  {p_end}
{synopt :{opth bline(string)}}bottom line in table: format (bold, double, neither)
  {p_end}
{synopt :{opt firstX}}top row in table: extra space after
  {p_end}
{synopt :{opt lastX}}bottom row in table: extra space before
  {p_end}
{synopt :{opt slim}}eliminate rows without information (rows inserted for aesthetics only)
  {p_end}
{synopt :{opth tabname(string)}}name for putdocx table 
  {p_end}

{marker comopt}{synopthdr:Multiple Panels (max 5)}
{synoptline}
{synopt :{opth mat#(string)}}matrix input: identifies matrices panel-by-panel
  {p_end}
{synopt :{opth est#(string)}}estimates input: identifies stored equations panel-by-panel
  {p_end}
{synopt :{opth est_stat#(string)}}estimates input: requests equation statistics panel-by-panel
  {p_end}
{synopt :{opt pline}}draw line separating panels
  {p_end}
{synopt :{opth pt_set(string)}}panel titles: set font (bold, underline, neither)
  {p_end}
{synopt :{opth pt#(string)}}panel titles, panel-specific
  {p_end}
{synopt :{opth rt#(string)}}row titles, panel-specific
  {p_end}
{synopt :{opth rst##(string)}}row-spanning titles, panel-specific
  {p_end}
{synopt :{opth extra##(string)}}extra information rows, panel-specific
  {p_end}
{synopt :{opth est_means(string)}}add means of right-hand-side variables, panel-specific
  {p_end}
{synopt :{opth est_mat(string)}}add matrices, panel-specific
  {p_end}


{p 1}{bf:{ul on}Description{ul off}}{p_end}

{pstd} {cmd:mswtable} is a wrapper for {cmd:putdocx table}.  It produces a table in MSWord format.{p_end}

{pstd} As input, {cmd:mswtable} requires either:{p_end}
{p 6 9} 1. Stata matrix, identified in {cmd:mat}().{p_end}
{p 6 9} 2. Equations stored via {cmd:estimates store}, identified in {cmd:est}().{p_end}

{pstd} Source #2 can be augmented with:{p_end}
{p 6 9} 3. Means of right-hand-side variables ({cmd:est_means}).{p_end}
{p 6 9} 4. Matrix of additional values ({cmd:est_mat}).{p_end}

{pstd} Option {cmd:colwidth}() is required.  And either {cmd:mat}() OR {cmd:est}().{p_end}

{pstd} Row and column labels: the default are the row and column names in the input matrix/equations, but these can be replaced (options {cmd:ct} and {cmd:rt}).{p_end}

{pstd} {cmd:mswtable} will construct a table with multiple panels (five panels maximum).  See discussion below of multi-panel syntax.{p_end}

{pstd} The constructed table can be saved as a MSWord table (option {bf:outfile}).
Alternatively, if {bf:outfile} is {ul:not} specified but {bf:tabname} instead is specified,
the table (as named in {bf:tabname}) is available for further development and polishing via {cmd:putdocx table}.{p_end}

{pstd} {cmd:mswtable} applies the table aesthetics of the author (e.g. line spacing, justification).
Some of this is modifiable, most is not.  (Note that option {cmd:slim} eliminates lines that are inserted for aesthetics only.){p_end}


{p 1}{bf:{ul on}Options{ul off}}{p_end}

{marker comoptd}{it:{dlgtab:core options}}

{phang} {opth colw:idth(string)} specifies the width of each column, in inches.  
This includes column for row titles (first column on left). 
{cmd:colwidth} contains an array of numbers (decimals are permitted), separated by comma or space.
{cmd:colwidth} is required.{p_end}
{pmore} Examples:  {cmd:colw(1.2,0.8,0.8,1)}{p_end}
{p 19}             {cmd:colw(1.5 1 1 1 1.2)}{p_end}

{phang} {opth mat(string)} identifies the input matrix.{p_end}

{phang} {opth est(string)} identifies equations that have been stored via {cmd:estimates store}.  
The equation names are separated by comma or space.  
Note that {cmd:estimates store} can be applied after {cmd:margins} if the {cmd:post} option is specified in the {cmd:margins} command.{p_end}
{pmore} Examples:  {cmd:est(mod1 mod2 mod3 mod4)}{p_end}
{p 19}             {cmd:est(eq1,eq2,eq3)}{p_end}

{phang} {opth est_stat(string)} requests equation "statistics" (N, aic, etc).  
These are placed at the bottom of the table, following the coefficients.  
(Some are renamed, e.g. "r2_a" becomes "Adjusted R-squared".  For further renaming, insert at lines 277ff in mswtable.ado.  Also, note that statistics names can be included in row titles; see {cmd:rt} below.){p_end}
{pmore} Contents of {cmd:est_stat} are as follows:{p_end}
{p 11 16} (i){space 2}name of the statistic (Stata naming convention){p_end}
{p 11 16} (ii){space 1}number of decimal places for the statistic{p_end}
{pmore} Separate (i) and (ii) with comma or space.  Multiple statistics can be requested - separate with "!".{p_end}
{pmore} Examples:  {cmd:est_stat(N,0! r2_a,2! bic,1)}{p_end}
{p 19}             {cmd:est_stat(N 0! r2_a 2)}{p_end}

{phang} {opth est_star(string)} requests that asterisks be placed on the regression coefficients.
The asterisks are placed immediately to the right.  
"string" is a listing of p-value thresholds (maximum three), separated by comma or space.  
They {ul:must} be listed in descending order.  
In the MSWord table, the first p-value will be denoted by one asterisk, the second by two asterisks, and the third by three asterisks.  
{cmd:mswtable} does not automatically generate a footnote indicating what the asterisks represent, this must be done manually (e.g. as {cmd:note1}).{p_end}
{pmore} Examples:  {cmd:est_star(0.05,0.01,0.001)}{p_end}
{p 19}             {cmd:est_star(0.10 0.05)}{p_end}

{phang} {opth est_se(string)} requests inclusion of statistical tests of the regression coefficients.  
"string" can contain:{p_end}
{pmore} (i){space 3}"se" or "t" or "p" or "ci" or "ci()", to request:{p_end}
{p 14 19}        "se"{space 4}standard error{p_end}
{p 14 19}        "t"{space 5}t-statistic (ratio of coefficient to standard error){p_end}
{p 14 19}        "p"{space 5}p-value for t-stat (two-sided test){p_end}
{p 14 19}        "ci"{space 4}confidence interval (95%){p_end}
{p 14 19}        "ci()"{space 2}confidence interval, with p-value and size of font within parentheses{p_end}
{p 8 14} (ii){space 2}"below" or "beside" - place below or immediately to the right of the coefficient{p_end}
{p 8 14} (iii){space 1}"paren" or "noparen" - whether enclosed in parentheses (or not).  (Confidence intervals are placed in brackets instead of parentheses.){p_end}
{p 8 8} Separate with comma or space.  Any or all of the three items can be specified, in any order.{p_end}
  
{pmore} The defaults are "se", "below", and "paren".  {cmd:est_se} without arguments requests the three
defaults.  Note that "beside" is incompatible with {cmd:est_star}.{p_end}

{pmore} "ci()" is syntax for specifying, within the parentheses, p-value and size of font.  
These are numeric values.  
If <.50, the value is assumed to be p-value; default is .05.  
If larger than 4, the value is assumed to be font size; default is 2.0-point less than body-of-table font.  
One or both can be specified; if both, either order is allowed, and separate by comma or space.{p_end}

{pmore} Examples:  {cmd:est_se}{space 14}standard error, below, in parentheses{p_end}
{p 19}             {cmd:est_se(t beside)}{p_end}
{p 19}             {cmd:est_se(ci)}{space 10}95% confidence interval{p_end}
{p 19}             {cmd:est_se(ci(.10,11))}{space 2}90% confidence interval, font size 11{p_end}

{phang} {opth sdec(string)} specifies number of decimal places for each column of data
(i.e. excepting left-hand column of row titles).  Decimal places for equation statistics are specified
separately (see {cmd:est_stat} above). {cmd:sdec(string)} contains integers, separated by comma or space.  
Every column need not be represented - {cmd:mswtable} will fill in based on the last number specified.  
That is, {cmd:sdec(1)} is equivalent to {cmd:sdec(1,1,1)}, and {cmd:sdec(1 1 0)} is equivalent to {cmd:sdec(1 1 0 0 0)}.  
The default is one decimal place.{p_end}

{phang} {opth font(string)} identifies the name of the font (must be font available in MSWord) and font sizes.
Current default font is Cambria, with font sizes (in points):{p_end}
{p 11} 12.5{space 2}title{p_end}
{p 11} 12.5{space 2}subtitle{p_end}
{p 11} 12{space 4}column and row titles{p_end}
{p 11} 12{space 4}body of table{p_end}
{p 11} 10.5{space 2}notes{p_end}
{p 11 11} Fonts for statistics (N, aic, etc) and "extra" information are 1.0-point less than body-of-table font; these two settings (and other fonts) can be modified at lines 184ff in mswtable.ado.{p_end}
  
{p 8}"string" can take two forms:{p_end}
{p 11} (i){space 2}name of font only{p_end}
{p 11} (ii){space 1}name of font and font sizes{p_end}
{pmore} If (ii), then the name of font is specified followed by the five font sizes; {ul:all five} sizes must be specified and ordered as shown above.  Separate the elements by comma or space.  Some 
font names are multiple words; place these names within quotation marks.{p_end}

{pmore} Examples:  {cmd:font(Garamond,12.5,12,12,11.5,10.5)}{p_end}
{p 19}             {cmd:font("Lucida Sans")}{p_end}
{p 19}             {cmd:font(Arial 12 12 11 10 10)}{p_end}

{phang} {opth title(string)} adds a title above the table, center-justified.  
{opth subt:itle(string)} adds a subtitle (further line under the title).  
The title (and subtitle) are separated from remainder of table by one empty line.{p_end}

{phang} {opth note1(string)} . . . {opth note9(string)} adds notes to the foot of the table (maximum is nine).  
These should be text in quotes.  
A blank line can be inserted by, for example, {cmd:note3(" ")}; blank lines are allocated less height.  
(Option {cmd:slim} eliminates blank lines.){space 2}Notes 
are separated from the table by one empty line.{p_end}

{phang} {opth ct(string)} are column titles.  
Often it is convenient to construct this separately as local macro.  
Use "!" to separate elements in this string, and do {ul:not} embed quotation marks.  
Spaces between words in the title are allowed.  
Titles are applied column-by-column in sequential order, beginning with the far left column 
(column for row titles) and including columns added via {cmd:est_means} or {cmd:est_mat}.  Column
titles can be left blank by specifying successive "!" ("!!" or "! !").  Multiple
lines in each column title are indicated by using "\" as separator; maximum is three lines.  
If {cmd:ct} is not specified, default is input matrix column names.{p_end}
{pmore} Example:  {cmd:ct("`ctitles'")}{p_end}

{phang} {opth cst_set(string)} formats the font for the column-spanning titles ({cmd:cst#} and {cmd:cst1#}).  
Options are "bold", "underline" (default), and "none".{p_end}

{phang} {opth cst1(string)} . . . {opth cst10(string)} are column titles that span multiple columns.  
They are placed in a row above the main column-by-column titles and centered, and by default underlined (see {cmd:cst_set}).  
Contents of {cmd:cst#} are as follows, in this order and separated by commas or spaces:{p_end}
{p 11 17} (i){space 3}text for title, in quotes{p_end}
{p 11 17} (ii){space 2}starting column for spanning title{p_end}
{p 11 17} (iii){space 1}number of columns to be spanned{p_end}
{pmore} "starting column" refers to the data matrix; columns added for {cmd:est_means} or {cmd:est_mat} are counted, 
but row title column (1st column) and columns inserted for {cmd:est_star} or {cmd:est_se} are {ul:not} counted.  
Multiple lines in the title are indicated by using "\" as separator in the text (item (i)); maximum is two lines.{p_end}
{pmore} Examples:  {cmd:cst1("Means" 1 3)}{p_end}
{p 19}             {cmd:cst2("Demographic\Variables",2,3)}{p_end}

{phang} {opth cst11(string)} . . . {opth cst15(string)} are higher-level column-spanning titles.  
These titles are placed above {cmd:cst1}-{cmd:cst10}.  
The syntax is identical to {cmd:cst1}-{cmd:cst10}.  
{cmd:cst11}-{cmd:cst15} presume {cmd:cst1}-{cmd:cst10} has been specified.{p_end}

{phang} {opth rt(string)} are row titles.  It is
convenient to make "string" a local macro that contains the set of row titles, in order.  
The titles for each successive row {ul:must} be separated by "!", and do {ul:not} embed quotation marks.  
Spaces between words in the title are allowed.  Row
titles can be left blank by specifying successive "!" ("!!" or "! !").  Multiple
lines in each row title are indicated by using "\" as separator, maximum two lines.  Row
titles can include the requested statistics (conforming to the order in {cmd:est_stat}).  
If {cmd:rt} is not specified, default is input matrix row names.{p_end}

{phang} {opth rst_set(string)} specifies two optional features of the row spanning titles (see {cmd:rst#}):{p_end}
{p 11 16} (i){space 2}format for font: "bold", "underline", "none" (default){p_end}
{p 11 16} (ii){space 1}"indent" the rows encompassed by row spanning title by three spaces; default is no indent{p_end}
{pmore} Separate with comma or space.{p_end}
{pmore} Example:  {cmd:rst_set(bold,indent)}{p_end}

{phang} {opth rst1(string)} . . . {opth rst16(string)} are row titles for multiple rows.  
The rows might be, for example, categories of a variable (e.g. for place of residence, "rural" "small city" "large city").  
The row titles are inserted above the set of rows - text as specified, with the remainder of the row blank.  
The spanning title may be bold or underlined, or neither (default); see {cmd:rst_set}.  
Each {cmd:rst#} must consist of the following, separated by commas or spaces:{p_end}
{p 11 16} (i){space 3}text for title, in quotes (row spanning titles cannot contain multiple lines){p_end}
{p 11 16} (ii){space 2}starting row for spanning title{p_end}
{p 11 16} (iii){space 1}number of rows encompassed by spanning title{p_end}
{pmore} Note that starting row is {ul:without} taking into account inserted rows for previous row spanning titles.  
Note also that the row spanning title is inserted {ul:above} the row specified by (ii).  
Further note:  the {cmd:rst#} must be ordered top to bottom of the table.{p_end}
{pmore} Example:  {cmd:rst1("Place of Residence",4,3)}{p_end}

{phang} {opth extra1(string)} . . . {opth extra9(string)} are additional rows of information (maximum nine).  
These are added to the foot of the table, following data specified in {cmd:mat} or {cmd:est}
and also following equation statistics (if {cmd:est_stat} is requested) but prior to {cmd:note}.  
Each "string" contains column-by-column text, starting with the first column on left (row title column).
Columns inserted for {cmd:est_means} or {cmd:est_mat} are included.   
Separate the column entries with "!", and do {ul:not} embed quotation marks.  
Spaces within entries are allowed.
Cells can be left blank by specifying successive "!" ("!!" or "! !").{p_end}
{pmore} Examples:  {cmd:extra1(State fixed effects !No !No !Yes !Yes)}{p_end}
{p 19}             {cmd:extra1(State fixed effects ! ! Yes ! !Yes)}{p_end}

{phang} {opth outf:ile(string)} specifies where MSWord table is to be written.  
If not specified, then putdocx table remains open (and the table can be referred to as named in {cmd:tabname}).  
Full file specification should be provided (exact directory + file name), and within quotes.  
"replace" or "append" are options; these follow the file specification (in quotes), with comma or space as separator.  
The default is "replace".  If "append", each table is started on a new page ({cmd:putdocx} option "pagebreak").  
A further option is "landscape"; this requests landscape orientation (portrait orientation is the default).{p_end}


{marker comoptd}{it:{dlgtab:additional options}}

{phang} {opth est_means(string)} requests addition of column of mean values of the right-hand-side variables.  
"string" contains two items, in this order and separated by comma or space:{p_end}
{p 11 16} (i){space 2}"left" or "right" - whether the column of means is the far left or far right column{p_end}
{p 11 16} (ii){space 1}equation name (must be among the equation names in {cmd:est()}){p_end}
{pmore} "left" is the default for item (i), which may be omitted.{p_end}
{pmore}The following options {ul:must} account for the {cmd:est_means} column: 
{cmd:colwidth}, {cmd:sdec}, {cmd:ct}, {cmd:cst#}, {cmd:cst1#}, {cmd:extra#}{p_end}
{pmore}Examples:  {cmd:est_means(eq1)}{p_end}
{p 19}            {cmd:est_means(right,eq1)}{p_end}

{phang} {opth est_mat(string)} requests addition of a matrix.  This enables one to augment a table of 
estimation results with other numerical values.  (Requesting both {cmd:est_means} and {cmd:est_mat} 
is {ul:not} allowed.)  "string" contains two items, in this order and separated by comma or space:{p_end}
{p 11 16} (i){space 2}"left" or "right" - whether the matrix will become the far left or far right columns of the table{p_end}
{p 11 16} (ii){space 1}matrix name{p_end}
{pmore}"left" is the default for item (i), which may be omitted.
The matrix will be inserted at the top row of the table.  It may have fewer rows than the remainder of the table.
And the matrix may contain missing values (".") - {cmd:mswtable} replaces these with " ".{p_end}
{pmore}The following options {ul:must} account for the {cmd:est_mat} columns: 
{cmd:colwidth}, {cmd:sdec}, {cmd:ct}, {cmd:cst#}, {cmd:cst1#}, {cmd:extra#}{p_end}
{pmore}Examples:  {cmd:est_mat(SUM)}{p_end}
{p 19}            {cmd:est_mat(right ZZ)}{p_end}

{phang} {opth est_no(string)} singles out equations for which {cmd:est_star} and {cmd:est_se} are {ul:not} applied.  
"string" is integers, separated by comma or space, specifying columns in the equation matrix:
from the left, the first equation is "1", the second equation is "2", and so forth.
(Columns inserted due to {cmd:est_means} or {cmd:est_mat} are {ul:not} counted.)  
The default is to apply {cmd:est_star} and {cmd:est_se} to all equations.{p_end}
{pmore}Example:  {cmd:est_no(4,5)}{p_end}

{phang} {opt extra_place} reverses the placement of the {cmd:est_stat} and {cmd:extra#} rows.
The default order is {cmd:est_stat} rows followed by {cmd:extra#} rows.{p_end}

{phang} {opth tline(string)} and {opth bline(string)} control the appearance of the lines:{p_end}
{p 11 18} {cmd:tline}: at the top of table (above column titles but below title and subtitle){p_end}
{p 11 18} {cmd:bline}: at the bottom of table (immediately before any notes){p_end}
{pmore} Options are "double" (double line) and "bold" (single bold line).  
Both options {ul:cannot} be requested together - must be one or the other.  
The default is non-bold single line.{p_end}

{phang} {opt firstX} and {opt lastX} request insertion of low-height row between:{p_end}
{p 11 16} (i){space 2}first data row and next row  [{cmd:firstX}]{p_end}
{p 11 16} (ii){space 1}last data row and previous row  [{cmd:lastX}]{p_end}
{pmore} This might be appropriate if, for example, the first or last row is "Total", or 
to provide some separation for the intercept.  
In multi-panel tables, this request is carried out panel-by-panel.  
note:  option {cmd:slim} overrides these two options.

{phang} {opt slim} eliminates rows that contain no information.  
These are rows inserted only to improve visual appearance.{p_end}

{phang} {opth tabname(string)} gives a name to the table, for {cmd:putdocx} use.  
The name can be used post-{cmd:mswtable} if the table is not saved (i.e. no {cmd:outfile} option),
allowing for additions or other enhancements to the table via {cmd:putdocx table}.{p_end}


{p 1}{bf:{ul on}Examples{ul off}}{p_end}
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
     Total ";

     mswtable, mat(TAB11) 
               colw(2.1,0.8,0.8,1)
               sdec(1,1,0)
               title("Table 1.  Mean DFS and Mean IFS")
               subt("Estimates by Region")
               ct("`ctitles'") 
               cst1("Means",1,2)
               rt("`regions'") 
               lastX
               note1("Sample:  currently-in-union women ages 15-49")
               note2(" ")
               note3("DFS = Desired Family Size")
               note4("IFS = Ideal Family Size")
               outfile("$D/analysis/tab1", replace);


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

      mswtable, colwidth(2.0,1.0,0.8,0.8,0.8) 
                est(eq1 eq2 eq3 eq4) 
                est_stat(N,0! r2_a,2! bic,1)
                est_star(.05,.01,.001) 
                est_se(se,below,paren)
                title("Table 2.  Modeling DFS")
                subtitle("OLS Estimates")
                extra1(State fixed effects !No !No !Yes !Yes)
                extra2(Ridiculous model !Yes !No !Yes !No)
                note1("Significance:    * p<.05   ** p<.01   *** p<.001")
                sdec(2)
                cst("Equations",1,4)
                ct("`cols'")
                rt("`xvars'")
                outfile("$D/analysis/tab2", append);


{smcl}
{marker comoptd}{it:{dlgtab:multiple panels (max 5)}}

{phang} Note that column titles ({cmd:ct}) and decimal points ({cmd:sdec}) cannot be panel-specific - {cmd:mswtable}
assumes these two specifications are fixed across panels.{p_end}

{phang} {opth mat1(string)} . . . {opth mat5(string)} identifies the input matrices, panel-by-panel.  
The suffix indexes the panel.  
These are stacked in sequential order, hence all matrices must have the same number of columns.{p_end}

{phang} {opth est1(string)} . . . {opth est5(string)} identifies the names of equations available via {cmd:estimates store}, panel-by-panel.  
See {cmd:est} above.  
The suffix indexes the panel.  These are stacked in sequential order, hence each panel must contain the same number of equations.{p_end}
{pmore} Examples:  {cmd:est1(mod11 mod12 mod13 mod14)}{p_end}
{p 19}             {cmd:est2(mod21 mod22 mod23 mod24)}{p_end}

{phang} {opth est_stat1(string)} . . . {opth est_stat5(string)} requests equation "statistics" (N, aic, etc), with the suffix indexing the panel.  
See {cmd:est_stat} above.  
If only {cmd:est_stat} is specified, then the same set of statistics is provided for every panel (these will be panel-specific values).{p_end}

{phang} {opt pline} draws single lines separating the panels.  
The line is drawn immediately above the panel title (if any).{p_end}

{phang} {opth pt_set(string)} formats the font for the panel titles (see {cmd:pt#}).  
Options are "bold", "underline" (default), and "none".{p_end}

{phang} {opth pt1(string)} . . . {opth pt5(string)} are text labels for the panels.  
The suffix indexes the panel.  
Text should be enclosed in quotes.  
Multiple lines are {ul:not} allowed.  
In the MSWord table, each panel title is inserted as a separate row, and by default is underlined (see {cmd:pt_set}).  
Panel titles are optional: titles may be provided for all, some, or none of the panels.{p_end}

{phang} {opth rt1(string)} . . . {opth rt5(string)} identify text labels for the rows, with the suffix indexing the panel.  
See {cmd:rt} above.{p_end}

{phang} {opth rst11(string)} - {opth rst112(string)} . . . {opth rst51(string)} - {opth rst512(string)} are
panel-specific row spanning titles, maximum twelve per panel (as against sixteen in one-panel table).   
Suffixes 11-112 are for the first panel, suffixes 21-212 for the second panel, etc.  
For syntax, see {cmd:rst1} - {cmd:rst16} above.
Numbering of rows is {ul:within-panel} (i.e. the first row of each panel is 1).  
{opth rst1(string)} - {opth rst12(string)} can be specified, in which case the same row spanning titles are applied to every panel.  
Either {cmd:rst1} - {cmd:rst12}  OR  {cmd:rst11} - {cmd:rst112} must be chosen, they cannot be mixed.  
If the row spanning  titles are panel-specific, they may be specified for some but not all panels (as indicated by suffixes 11-112, 21-212, etc.){p_end}

{phang} {opth extra11(string)} - {opth extra19(string)} . . . {opth extra51(string)} - {opth extra59(string)} are additional rows of information, panel-by-panel.  
Suffixes 11-19 are for the first panel, suffixes 21-29 for the second panel, etc.  
For syntax, see {cmd:extra1} - {cmd:extra9} above. 
{opth extra1(string)} - {opth extra9(string)} can be specified, in which case one set of extra rows is
inserted at the bottom of the table ({ul:not} panel-by-panel), and option {cmd:extra_place} has no effect.{p_end}

{phang} {opth est_means(string)}.  
An equation name for {ul:every} panel must be specified, in order.
These must be consistent with the names in {cmd:est#}.
The panel-by-panel equation names follow "left" or "right", unless this is omitted ("left" is default).
Note that placement "left" or "right" is the same in every panel.{p_end}
{pmore} Examples:  {cmd:est_means(mod1 mod2 mod3)}{p_end}
{p 19}             {cmd:est_means(right,eq1_1,eq2_1,eq3_1}}{p_end}

{phang} {opth est_mat(string)}.  
The matrices must be panel-specific, and ordered from first to last panel.  The panel-by-panel
matrix names follow "left" or "right", unless this is omitted ("left" is default).
Note that the placement "left" or "right" is the same in every panel.
Also note that all {cmd:est_mat} matrices {ul:must} have the same number of columns.{p_end}
{pmore} Example:  {cmd:est_mat(right,X1,X2,X3}}{p_end}


{p 1}{bf:{ul on}Example{ul off}}{p_end}
{asis}

     mswtable, colwidth(2.0,1.0,0.8,0.8,0.8) 
               est1(eq1_1 eq1_2 eq1_3 eq1_4) 
               est2(eq2_1 eq2_2 eq2_3 eq2_4) 
               est_stat(N,0! r2_a,2! bic,1)
               est_star(.05,.01,.001) 
               est_se(t,below,paren)
               title("Table 3.  Modeling DFS")
               subtitle("OLS Estimates")
               extra11(State fixed effects !No !No !Yes !Yes)
               extra12(Ridiculous model !Yes !No !Yes !No)
               extra21(State fixed effects !No !No !Yes !Yes)
               extra22(Ridiculous model !Yes !No !Yes !No)
               note1("Significance:    * p<.05   ** p<.01   *** p<.001")
               sdec(2)
               cst1("Equations" 1 4)
               ct("`cols'")
               rt1("`xvars'") rt2("`xvars'")
               pt1("Low fertility (TFR < 4.5)")
               pt2("High fertility (TFR >= 4.5)")
               pt_set(bold)
               pline
               outfile("$D/analysis/tab3", replace);


{smcl}
{p 1}{bf:{ul on}Technical odds and ends{ul off}}{p_end}

{pstd} {it:Cell justification} (horizontal):{p_end}
{p 8 10} - row titles (first column on left) and notes are left-justified;{p_end}
{p 8 10} - title/subtitle and column-spanning titles are center-justified;{p_end}
{p 8 10} - remaining columns are right-justified: column titles, all data cells,
and row titles for the rows at the foot of the table (statistics, extra info){p_end}
{p 8 10} - except left-justification for {cmd:est_se} in the "beside" location{p_end}

{pstd} {it:Table width}:{p_end}
{pmore}{cmd:mswtable} constrains the width of the table to be the sum of the column widths ({cmd:colwidth}),
plus columns inserted for {cmd:est_star}, {cmd:est_se}, {cmd:est_means}, and {cmd:est_mat}.
Although MSWord does not always perfectly comply.  

{pstd} {cmd:est_se}{space 2}{it:formatting}:{p_end}
{pmore} {it:Decimal points}:{p_end}
{p 8 10} - standard errors: one decimal point more than the coefficients (see {cmd:sdec}){p_end}
{p 8 10} - t-statistics: two decimal points{p_end}
{p 8 10} - p-values: three decimal points{p_end}
{p 8 10} - confidence intervals: same as coefficients (see {cmd:sdec}){p_end}
{pmore} {it:Font sizes}:{p_end}
{p 8 10} - standard errors, t-statistic, p-value: 1.5-point less than body-of-table font{p_end}
{p 8 10} - confidence interval: 2.0-point less than body-of-table font (but can be adjusted in "ci()"){p_end}
{p 10 10}These two settings (and other fonts) can be modified at lines 184ff in mswtable.ado.{p_end}

{pstd} {it:fonts and row heights}:{p_end}
{pmore} Some fonts are by their nature taller (or shorter).  {cmd:mswtable} accounts for this in setting 
row heights. Specifically, default row heights are inflated for {it:Arial} and
{it:LM Roman 12}.  The same adjustment could be applied to other fonts by inserting code at lines 226ff in mswtable.ado.{p_end}

{pstd} {cmd:rt}{space 2}{it:row titles and row heights}:{p_end}
{pmore} {cmd:mswtable} is not smart about row heights.  Rows with multi-line titles are set higher,
but only those rows, resulting in non-uniform row heights if the row titles are not entirely one line or two lines.  
Keeping all row titles to one line is recommended.{p_end}

{pstd} {cmd:extra#}:{p_end}
{pmore} {cmd:extra} rows can be used for quantitative values not available in the statistics Stata provides following regression estimation, if these values are placed in macros.  
These might be, for example, mean values of the dependent variables.{p_end}


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




