{smcl}
{* version 1.0.4 25jun2011}
{cmd:help labvalch3}
{hline}

{title:Title}

{p 5}
{cmd:labvalch3} {hline 2} Change value labels

{title:Syntax}

{p 8}
{cmd:labvalch3} [{it:namelist}] {cmd:,} {it:transformation_option} 
[{it:options}]


{p 5 8}
where {it:namelist} is a list of value label names or, if {opt var:iables} 
is specified, a {varlist}

{synoptset 21 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :{it:transformation_options}}
{synopt:{opt u:pper}}change value labels to uppercased characters{p_end}
{synopt:{opt l:ower}}change value labels to lowercased characters{p_end}
{synopt:{opt pre:fix(stub)}}prefix value labels with {it:stub}{p_end}
{synopt:{opt suff:ix(stub)}}suffix value labels with {it:stub}{p_end}
{synopt:{opt sub:st(this that)}}in value labels change {it:this} to 
{it:that}{p_end}
{synopt:{opt bef:ore(before)}}remove {it:before} and any text following
{p_end}
{synopt:{opt aft:er(after)}}remove {it:after} and any text preceding{p_end}
{synopt:{opt noexc:lude}}do not remove {it:before} or {it:after}{p_end}
{synopt:{opt strfcn(strfcn())}}apply {help string_functions:string function} 
{it:strfcn()} to value labels{p_end}
{synopt:{opt sy:mbol(str)}}use symbol as placeholder in {it:strfcn()}{p_end}
{syntab:{it:selection_options}}
{synopt:{opt var:iables}}parse {it:namelist} as {varlist}{p_end}
{synopt:{opt val:id(numlist)}}change value labels associated with valid 
numbers{p_end}
{synopt:{opt inv:alid(numlist)}}do not change value labels associated with 
invalid numbers{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:labvalch3} changes value labels specified in {it:namelist}. If namelist 
is not specified, all value labels in memory are changed.

{pstd}
If more than one transformation option is specified, {cmd:labvalch3} applies 
options in the following order. Firstly value labels are changed to upper- or 
lowercased characters. Secondly, all occurrences of {it:this} are changed to 
{it:that}. Next {it:before} or {it:after} remove text. If a 
{help string_functions:string function} is specified, this function is then 
applied to the upper/lowercased, substituted value labels. Any prefix 
and/or suffix is added last.

{title:Options}

{dlgtab:Options}

{phang}
{opt upper} changes value labels to uppercased characters. May not be 
specified with {opt lower}.

{phang}
{opt lower} changes value labels to lowercased characters.  May not be 
specified with {opt upper}.

{phang}
{opt prefix(stub)} prefixes value labels with {it:stub}. May be combined 
with {opt suffix()}. Use double quotes if {it:stub} contains embedded 
spaces.

{phang}
{opt suffix(stub)} suffixes value labels with {it:stub}. May be combined 
with {opt prefix()}. Use double quotes if {it:stub} contains embedded 
spaces.

{phang}
{opt subst(this that)} substitutes all occurrences of {it:this} in value 
labels with {it:that}. Use double quotes if {it:this} or {it:that} 
contain embedded spaces. Value labels in which {it:this} is not found 
are left unchanged.

{phang}
{opt before(before)} removes {it:before} and any text following from value 
labels. Thus, value labels will be changed to contain any text preceding 
{it:before}. Value labels in which {it:before} is not found are left 
unchanged. May not be specified with {opt after}.

{phang}
{opt after(after)} removes {it:after} and any text preceding from value 
labels. Thus, value labels will be changed to contain any text following 
{it:after}. Value labels in which {it:after} is not found are left 
unchanged. May not be specified with {opt before}.

{phang}
{opt noexclude} prevents {cmd:labvalch3} from removing {it:before} or 
{it:after} from value labels. Specifying {cmd:before(e) noexclude} will 
change value label {it:Domestic} to {it:Dome}. Specifying {cmd:before(e)} 
will change value label {it:Domestic} to {it:Dom}.

{phang}
{opt strfcn(strfcn())} applies any {help string_functions:string function} 
to value labels. In {it:strfcn} use placeholder {hi:@} to refer to value 
labels. The general from of this option is 
{bf:strfcn(}{help string_functions:{it:strfcn}}{it:("@", args){bf:)}}. 

{phang}
{opt symbol(str)} use {it:str} as placeholder for value labels in 
{it:strfcn}. Default placeholder is @.

{phang}
{opt variables} specifies that {it:namelist} is a {varlist}. If {it:namelist} 
is not specified it defaults to {it:_all}, meaning all variables in the 
dataset.

{phang}
{opt valid(numlist)} changes value labels associated with numbers specified 
in {it:numlist}.

{phang}
{opt invalid(numlist)} does not change value labels associated with numbers 
specified in {it:numlist}.

{title:Examples}

	. sysuse auto
	
	{cmd:. labvalch3 origin ,suffix(" Automobile")}
	
	{cmd:. labvalch3 foreign ,variables subst("Automobile" "Car")}
	
	{cmd:. labvalch3 ,upper}
	
	{cmd:. labvalch3 ,strfcn(proper("@"))}
	
	{cmd:. labvalch3 foreign ,before(e) valid(1)}

	
{title:Acknowledgments}

{pstd}
This ado was suggested by Dimitriy V. Masterov on 
{browse "http://www.stata.com/statalist/archive/2011-05/msg00384.html":Statalist}.

{pstd}
The name {cmd:labvalch3} is in line with {cmd:labvalch} from {cmd:labutil} 
(see {stata findit labutil:labutil}) package by Nick Cox, who also originated the 
tranformation options in his (much richer) {cmd:labvarch}. Number 3 is 
chosen because of the (nice) ad hoc solution {cmd:labvalch2} by Eric Booth. 
Also, by coincidence, {cmd:labvalch3} changes the third element in 
{help label:label define} {it:lblname} # {hi:{it:label}}.


{title:Author}

{pstd}Daniel Klein, University of Bamberg, klein.daniel.81@gmail.com

{title:Also see}

{psee}
Online: {helpb label}, {help string_functions}{p_end}

{psee}
if installed: {help strrec}, {help labcd}, {help labcopy}, {help labdel}, 
{help lablog}, {help labdtch}, {help labmap}, {help labnoeq}, {help labvarch}, 
{help labvalch}, {help labmask}, {help labvalclone}, {help labeldup}, 
{help labelrename} {p_end}
