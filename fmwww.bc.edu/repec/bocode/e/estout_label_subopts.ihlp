{p 4 4 2}
The following suboptions may be used within the {cmd:mgroups()},
{cmd:mlabels()}, {cmd:collabels()}, {cmd:eqlabels()},
{cmd:varlabels()}, and {cmd:stats(, labels())} options:

{p 4 8 2}
{cmd:none} suppresses the printing of the labels or drops the
part of the table heading to which it applies.

{p 4 8 2}
{cmd:prefix(}<{it:string}>{cmd:)} specifies a common prefix to be added to each
label.

{p 4 8 2}
{cmd:suffix(}<{it:string}>{cmd:)} specifies a common suffix to be added to each
label.

{p 4 8 2}
{cmd:begin(}<{it:string}>{cmd:)} specifies a prefix to be printed at the
beginning of the part of the table to which it applies. If {cmd:begin} is
specified in {cmd:varlabels()} or {cmd:stats(,labels())}, the prefix will
be repeated for each regressor or summary statistic.

{p 4 8 2}
{cmd:end(}<{it:string}>{cmd:)} specifies a suffix to be printed at the end of the
part of the table to which it applies. If {cmd:end} is specified in
{cmd:varlabels()} or {cmd:stats(,labels())}, the suffix will be repeated
for each regressor or summary statistic.

{p 4 8 2}
{cmd:last} specifies that the last occurrence of the {cmd:end()}-suffix in
{cmd:varlabels()} or {cmd:stats(,labels())} be printed. This
is the default. Use {cmd:nolast} to suppress the last occurrence of the
suffix.

{p 4 8 2}
{cmd:span} causes labels to span columns, i.e. extends the labels across
several columns, if appropriate. This suboption is relevant only for the
{cmd:mgroups()}, {cmd:mlabels()}, {cmd:eqlabels()}, and
{cmd:collabels()} options. The {cmd:@span} string returns the number of
spanned columns if it is included in the label, prefix, or suffix. A LaTeX example:

{p 8 8 2}
{cmd:. estout ..., mlabels(, span prefix(\multicolumn{@span}{c}{) suffix(}))}

{p 4 8 2}
{cmd:erepeat(}<{it:string}>{cmd:)} specifies a string that is repeated for each
group of spanned columns at the very end of the row if the {cmd:span}
suboption is specified. This suboption is relevant only for the
{cmd:mgroups()}, {cmd:mlabels()}, {cmd:eqlabels()}, and
{cmd:collabels()} options. If the {cmd:@span} string is included in
{it:string} it will be replaced by the range of columns spanned. A LaTeX example:

{p 8 8 2}
{cmd:. estout ..., mlabels(, span erepeat(\cline{@span}))}

{p 4 8 2}
{cmd:lhs(}<{it:string}>{cmd:)} inserts {it:string} into the otherwise empty cell
in the left stub of the row of the table heading to which it applies. This
suboption is relevant only for the {cmd:mgroups()}, {cmd:mlabels()},
{cmd:eqlabels()}, and {cmd:collabels()} options.
