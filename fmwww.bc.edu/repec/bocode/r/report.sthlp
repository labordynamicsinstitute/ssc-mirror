{smcl}
{* *! version 1.0 18 Nov 2021}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "report##syntax"}{...}
{viewerjumpto "Description" "report##description"}{...}
{viewerjumpto "Options" "report##options"}{...}
{viewerjumpto "Remarks" "report##remarks"}{...}
{viewerjumpto "Examples" "report##examples"}{...}
{title:Title}
{phang}
{bf:report} {hline 2} A command to produce tables for XML

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:report}
[{help if}]
[iweight/]
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Required }

{synopt:{opt rows(string)}}  specifies the variable(s) used for the rows of the table. {p_end}

{syntab:Optional}
{synopt:{opt cols(string)}} specifies the variables used for the columns of the table.

{synopt:{opt file(string)}} specifies the filename of the file to contain the new table.

{synopt:{opt t:itle(string asis)}} specifies the text used as the title of the table.

{synopt:{opt toptions(string asis)}} specifies the additional text options used for the table.

{synopt:{opt adj:acentcolumns}} indicates that columns are placed next to each other and not nested.

{synopt:{opt adjacentrows}} indicates that rows are placed next to each other and not nested.

{synopt:{opt tableoptions(string asis)}} specifies the additional options used for the table.

{synopt:{opt usecollabels}} uses the value label to determine the values tabulated as opposed to which values are observed.

{synopt:{opt userowlabels}} uses the value label to determine the values tabulated as opposed to which values are observed.

{synopt:{opt font(string)}} specifies the font to be used in the table.

{synopt:{opt landscape}} specifies whether the table is created in landscape mode.

{synopt:{opt pagesize(string)}} specifies the page size.

{synopt:{opt row}} specifies to produce row percentages for a frequency table.

{synopt:{opt col:umn}} specifies to produce column percentages for a frequency table.

{synopt:{opt totals}} specifies to produce total columns and rows for a frequency table.

{synopt:{opt note(string)}} specifies the text to place in the table note.

{synopt:{opt nofreq}} indicates that frequency values are not included in the table.

{synopt:{opt replace}} specifies that a new file be created.

{synopt:{opt missing}} specifies that missing values will be reported separately for frequency tables and NOT summary tables.

{synopt:{opt dropfirstrows(#)}} specifies that the first # lines are dropped.

{synopt:{opt droplastrows(#)}} specifies that the last # lines are dropped.

{synopt:{opt dropfirstcols(#)}} specify the number of columns to drop at the left side of the table to drop

{synopt:{opt droplastcols(#)}} specify the number of rows at the bottom of the table to drop

{synopt:{opt rowtotals}} specifies that additional totals are added to the inner row variable.

{synopt:{opt coltotals}} specifies to produce column totals for a frequency table.

{synopt:{opt rowsby(string)}} indicates that the summary statistics table has a subdivision on the rows, this can be used in conjuntion with cols() but not adjacentcolumns().

{synopt:{opt overall}} specifies that overall summary statistics are included in the summary statistics tables.

{synopt:{opt oldstyle}} specifies that the tables use the pre-May2021 table formats.

{synopt:{opt cellfmt(string)}} specifies additional formatting statements be added to the table.

{synopt:{opt *}}  extras{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}

{pstd}
 {cmd:report} produces a single table that can be added to an existing docx file or 
 used to create a new docx file.

{marker options}{...}
{title:Options}
{dlgtab:Main}

{phang}
{opt rows(string)}  specifies the variable(s) used for the rows of the table.

{phang}
{opt cols(string)}  specifies the variables used for the columns of the table.

{phang}
{opt file(string)} report specifies the filename of the file to contain the new table.

{phang}
{opt t:itle(string asis)}  specifies the text used as the title of the table.

{phang}
{opt toptions(string asis)}  specifies the additional text options used for the table.

{phang}
{opt adj:acentcolumns}  indicates that columns are placed next to each other and not nested.

{phang}
{opt adjacentrows}  indicates that rows are placed next to each other and not nested.

{phang}
{opt tableoptions(string asis)}  specifies the additional options used for the table.

{phang}
{opt usecollabels}  uses the value label to determine the values tabulated as opposed to which values are observed.

{phang}
{opt userowlabels}  uses the value label to determine the values tabulated as opposed to which values are observed.

{phang}
{opt font(string)}  specifies the font to be used in the table.

{phang}
{opt landscape}  specifies whether the table is created in landscape mode.

{phang}
{opt pagesize(string)}  specifies the page size.

{phang}
{opt row}  specifies to produce row percentages for a frequency table.

{phang}
{opt col:umn}  specifies to produce column percentages for a frequency table.

{phang}
{opt totals}  specifies to produce total columns and rows for a frequency table.

{phang}
{opt note(string)}  specifies the text to place in the table note.

{phang}
{opt nofreq}  indicates that frequency values are not included in the table.

{phang}
{opt replace} replace specifies that a new file be created.

{phang}
{opt missing}  specifies that missing values will be reported separately for frequency tables and NOT summary tables.

{phang}
{opt dropfirstrows(#)}  specifies that the first # lines are dropped.

{phang}
{opt droplastrows(#)}  specifies that the last # lines are dropped.

{phang}
{opt dropfirstcols(#)}  specify the number of columns to drop at the left side of the table to drop

{phang}
{opt droplastcols(#)}  specify the number of rows at the bottom of the table to drop

{phang}
{opt rowtotals}  specifies that additional totals are added to the inner row variable.

{phang}
{opt coltotals}  specifies to produce column totals for a frequency table.

{phang}
{opt rowsby(string)}  indicates that the summary statistics table has a subdivision on the rows, this can be used in conjuntion with cols() but not adjacentcolumns().

{phang}
{opt overall}  specifies that overall summary statistics are included in the summary statistics tables.

{phang}
{opt oldstyle}  specifies that the tables use the pre-May2021 table formats.

{phang}
{opt cellfmt(string)}  specifies additional formatting statements be added to the table.

{phang}
{opt *}  extras


{marker examples}{...}
{title:Examples}

First read in some data

{stata webuse citytemp2, clear} <--- this will delete your data!

The simplest table is to create a list of unique levels of a variable and places it 
in a file called test.docx (replacing it if it already exists).

{stata report,  rows(region) nofreq file(test) replace}

{p 0 0}
Then freqencies of each category and percentages can be added to the same filename test.docx (by not specifying replace)

{stata report,  rows(region) title(Frequency and row percentages) file(test) row}

{p 0 0}
Often the same sort of report can be desired for two variables, this can be done by adding in an additional variable
into the rows() option.

{stata report,  rows(region agecat)   title(2-way Freq table) file(test) row}

However, this is not the usual way of producing a frequency table and the useful one is having
region as the row variable and agecat as the column variable. To give the more familiar table.

{stata report, rows(region) cols(agecat) column totals file(test)}

Higher dimensions are allowable 

{stata report, rows(region division) cols(agecat) column totals file(test)}

which does not seem correct because region is derived from division and there are plenty of zero cells
in the table. However you could do separate tables with rows either region or division but to 
combine into one table you can use the adjacentrows option

{stata report, rows(region division) cols(agecat) column totals file(test) adjacentrows}

{p 0 0}
A table containing summary statistics can also be created with the following command. Note that you can put formating statements for each of 
the summary statistics. Also the statistics are the words used in the collapse command and any of the collapse 
statistics can be used.

{stata report, rows(tempjan, mean %5.2f | tempjan, sd  %5.2f| tempjan, count | tempjuly, mean  %5.2f| tempjuly, median  %5.2f) cols(region agecat)  font(,8) file(test)}

{p 0 0}
Rather than nesting age within region, it might be preferred to have the columns alongside each other and here we add the adjacentcolumns option

{stata report, rows(tempjan, mean %5.2f | tempjan, sd  %5.2f| tempjan, count | tempjuly, mean  %5.2f| tempjuly, median  %5.2f) cols(region agecat)  font(,8) file(test) adjacentcolumns}

Also it is possible to add the overall category alongside the column variables.

{stata report, rows(tempjan, mean %5.2f | tempjan, sd  %5.2f| tempjan, count | tempjuly, mean  %5.2f| tempjuly, median  %5.2f) cols(region agecat)  font(,8) file(test) adjacentcolumns overall}

Or perhaps you want to subdivide the rows by region and have age categories as columns, this is handled by adding a rowsby() option.

{stata report, rows(tempjan, mean %5.2f | tempjan, sd  %5.2f| tempjan, count | tempjuly, mean  %5.2f| tempjuly, median  %5.2f) cols(agecat) rowsby(region) font(,8) file(test) }

Then to produce the table in landscape because it doesn't fit well in portrait (which is the default)

{stata report, rows(heatdd, mean %5.2f | heatdd, count | heatdd, sd %5.3f | tempjan, mean %5.2f | tempjan, sd  %5.2f| tempjan, count | tempjuly, mean  %5.2f| tempjuly, median  %5.2f) cols(region agecat)  font(,8) landscape file(test2) replace}

{p 0 0}
A recent  addition to the report command is the ability to alter the formatting of any cells of the table. Many formatting statements can be
added with a | symbol in between. The first number is for specifying the rows, the second number is for specifying the columns and the third part is the text 
used in the format option.

{stata report, rows(heatdd, mean %5.2f | heatdd, count | heatdd, sd %5.3f | tempjan, mean %5.2f | tempjan, sd  %5.2f| tempjan, count) cols(region agecat) font(,8) landscape cellfmt(6,6,font(palatino, 12, red) | 5,., shading(lime))}


{p 0 0}
The next example does some frequency tables but sometimes the first row and first column are not needed to make sense
of the results. Using the dropfirstcols() and dropfirstrows() options the variable label columns can be removed. Note that these commands are not guaranteed to work because you might be dropping a column when perhaps two cells have been merged (no idea how to drop half a merged cell)

.use "http://www.stata-press.com/data/r16/nhanes2b.dta", clear
.report, rows(race agegrp region) cols(sex) totals column file(example_tables) adjacentrows  title(Table 10: Frequency table - another example.) font(,10) landscape dropfirstrows(1) dropfirstcols(1)


{pstd}

{pstd}


{title:Author}
{p}

Prof Adrian Mander, Cardiff University.

Email {browse "mailto:mandera@cardiff.ac.uk":mandera@cardiff.ac.uk}



