{smcl}
{* version 1.0.1 22nov2010}
{cmd:help labvars}
{hline}

{title:Title}

{p 5}
{cmd:labvars} {hline 2} Label a list of variables

{title:Syntax}

{p 8}
{cmd:labvars} {varlist} {hi:\} [{it:"label"} [{it:"label"}]{it: ...}] [{cmd:,} {it:options}]

{synoptset 21 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt u:nique}}use last label once only{p_end}
{synopt:{opt t:est}}test that number of labels match number of variables{p_end}
{synopt:{opt e:cho}}echo the {help label variable} commands{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:labvars} attaches a list of labels to {varlist}. If no labels are specified, existing 
variable labels are removed. If fewer labels than variables are specified, the last label 
will be used as variable label for each additional variable.

{title:Options}

{dlgtab:Options}

{phang}
{opt unique} prevents {cmd:labvars} from using the last label for each additional variable,
if fewer labels are specified than varibales are in {varlist}.

{phang}
{opt test} tests that the number of labels equal the number of variables in {varlist}. If 
too few or too many labels are specified, an error message will be returned.

{phang}
{opt echo} echos the {help label variable} commands that are used.

{title:Examples}

	. sysuse auto ,clear
	(1978 Automobile Data)

	. describe make rep78 foreign

	              storage  display     value
	variable name   type   format      label      variable label
	----------------------------------------------------------------------
	make            str18  %-18s                  Make and Model
	rep78           int    %8.0g                  Repair Record 1978
	foreign         byte   %8.0g       origin     Car type

	{cmd:. labvars make rep78 foreign \ Make "Repair Record in 1978" Type}

	. describe make rep78 foreign

	              storage  display     value
	variable name   type   format      label      variable label
	---------------------------------------------------------------------
	make            str18  %-18s                  Make
	rep78           int    %8.0g                  Repair Record in 1978
	foreign         byte   %8.0g       origin     Type

	{cmd:. labvars _all \ "one label fits all"}

	. describe

	Contains data from C:\Program Files\Stata11\ado\base/a/auto.dta
	  obs:            74                          1978 Automobile Data
	 vars:            12                          13 Apr 2009 17:45
	 size:         3,478 (99.9% of memory free)   (_dta has notes)
	---------------------------------------------------------------------
	              storage  display     value
	variable name   type   format      label      variable label
	---------------------------------------------------------------------
	make            str18  %-18s                  one label fits all
	price           int    %8.0gc                 one label fits all
	[...]
	foreign         byte   %8.0g       origin     one label fits all
	----------------------------------------------------------------------
	Sorted by:  foreign
 

{title:Author}

{pstd}Daniel Klein, University of Bamberg, daniel1.klein@gmx.de

{title:Also see}

{psee}
Online: {helpb label}
{p_end}