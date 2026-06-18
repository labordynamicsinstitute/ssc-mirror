{smcl}
{* 15jun2026}{...}
{hi:help addlegend}{...}
{right:{browse "https://github.com/benjann/addlegend/"}}
{hline}

{title:Title}

{pstd}{hi:addlegend} {hline 2} Utility to add a custom legend to a twoway graph


{title:Syntax}

{p 8 15 2}
    {cmd:addlegend} [{it:graphname}] [{it:{help numlist}}]
    [{cmd:,} {it:{help addlegend##opts:options}} ]
    {cmd::} {it:keylist}

{p 8 15 2}
    {cmd:_mklegend} [{it:graphname}] [{it:{help numlist}}]
    [{cmd:,} {it:{help addlegend##opts:options}} ]
    {cmd::} {it:keylist}

{pstd}
    where {it:keylist} is

{p 8 15 2}
    {it:key} [ {cmd:||} {it:key} [...]]

{pstd}
    and {it:key} is

{p 8 15 2}
    [{it:symboldef}]
    {cmd:"}{it:text}{cmd:"} [{cmd:"}{it:text}{cmd:"} [...]]
    [{cmd:,} {it:{help addlegend##sopts:symopts}}
    {it:{help addlegend##topts:txtopts}} ]

{pstd}
    and {it:symboldef} is {cmd:-} or

{p 8 15 2}
    {cmd:(}{it:symlist} [{cmd:,} {it:{help addlegend##sopts:symopts}}]{cmd:)}
    [{cmd:(}{it:symlist} [{cmd:,} {it:{help addlegend##sopts:symopts}}]{cmd:)} [...]]

{pstd}
    and {it:symlist} is

{p 8 15 2}
    [{it:symbol} [{it:symbol} [...]]]

{pstd}
    and {it:symbol} is

{p2colset 9 22 22 2}{...}
{p2col : {it:{help symbolstyle}}}marker
    {p_end}
{p2col : {opt line}}line
    {p_end}
{p2col : {opt rline}}double line
    {p_end}
{p2col : {opt area}}area
    {p_end}
{p2col : {opt bar}}bar
    {p_end}
{p2col : {opt cap}}capped line; can also type {cmd:rcap}
    {p_end}
{p2col : {opt capsym}}line capped with symbols; can also type {cmd:rcapsym}
    {p_end}


{synoptset 23 tabbed}{...}
{marker opts}{synopthdr:options}
{synoptline}
{syntab :{it:{help addlegend##options:Main}}}
{synopt :{opt lskip(#)}}baseline skip between legend keys
    {p_end}
{synopt :{cmdab:fr:ame}[{cmd:(}{it:{help addlegend##frame:subopts}}{cmd:)}]}draw
    frame around legend
    {p_end}
{synopt :{opth m:argin(marginstyle)}}reset margin of graph region
    {p_end}
{synopt :{opt nodraw}}do not update graph window
    {p_end}

{marker sopts}{...}
{syntab :{it:{help addlegend##symopts:symopts}}}
{synopt :{opt y(#)} or {opt Y(#)}}vertical position of legend key, in percent or units of Y-axis
    {p_end}
{synopt :{opt x(#)} or {opt X(#)}}horizontal position of legend key, in percent or units of X-axis
    {p_end}
{synopt :{opt h(#)} or {opt H(#)}}height of key's symbol, in percent or units of Y-axis
    {p_end}
{synopt :{opt w(#)} or {opt W(#)}}width of key's symbol, in percent or units of X-axis
    {p_end}
{synopt :{it:{help marker_options}}}options affecting look of markers
    {p_end}
{synopt :{it:{help line_options}}}options affecting look of lines
    {p_end}
{synopt :{it:{help area_options}}}options affecting look of areas
    {p_end}

{marker topts}{...}
{syntab :{it:{help addlegend##txtopts:txtopts}}}
{synopt :{opt ty(#)} or {opt TY(#)}}vertical position of text, relative to symbol, in percent or units
    {p_end}
{synopt :{opt tx(#)} or {opt TX(#)}}horizontal position of text, relative to symbol, in percent or units
    {p_end}
{synopt :{opt tw(#)} or {opt TW(#)}}with of text, in percent or units; only relevant for {cmd:frame()}
    {p_end}
{synopt :{opth t:ext(textbox_options)}}options affecting look of text
    {p_end}
{synoptline}


{title:Description}

{pstd}
    {cmd:addlegend} creates a custom legend and adds it to an existing
    {helpb twoway} graph, thereby removing the legend created by Stata's
    {helpb legend_option:legend()} option. In contrast to the
    {helpb legend_option:legend()} option, {cmd:addlegend} can combine multiple
    symbols in a single legend key and the keys can be freely positioned on the
    plot. {cmd:addlegend} requires the {helpb addplot} command
    ({browse "https://doi.org/10.1177/1536867X1501500308":Jann 2015}) to be
    installed on the system; type {cmd:ssc install addplot} to install
    {helpb addplot}.

{pstd}
    Argument {it:graphname} selects the memory graph to be affected. The default
    is to use the current (topmost) graph. Argument {it:{help numlist}}
    selects the subgraph(s) to be affected if the graph has been created using
    {helpb graph combine} or the {help by_option:{bf:by()}} option. The default
    is to modify all {helpb twoway} subgraphs found in the graph.

{pstd}
    {cmd:addlegend} uses the dimensions of the axes of the selected graph (or
    the first selected subgraph) to determine the position and size of the
    legend. Use options
    {helpb addlegend##symopts:y()},
    {helpb addlegend##symopts:x()},
    {helpb addlegend##symopts:h()},
    {helpb addlegend##symopts:w()},
    {helpb addlegend##txtopts:ty()},
    {helpb addlegend##txtopts:tx()}, and
    {helpb addlegend##txtopts:tw()}
    (as well as similar suboptions within the {helpb addlegend##frame:frame()} option)
    to override the default behavior. These options come in two flavors,
    lower case and upper case. Use the lower-case variant, e.g. {cmd:y()},
    to specify a setting in percent of the range of the relevant axis; use the
    upper-case variant, e.g. {cmd:Y()}, to specify a setting in original units
    of the axis. If both are specified, the upper-case variant takes precedence
    over the lower-case variant.

{pstd}
    Options can be specified at different levels, at the global level, at the
    level of a legend key, or at the level of a key's symbol. Upper-level
    settings are used as defaults for lower-level settings, and options
    specified a lower level take precedence over options specified at an upper
    level (ignoring case; for example, {cmd:y()} specified at a lower level
    takes precedence over {cmd:Y()} specified at an upper level). Furthermore,
    if specified at the level of a legend key, options
    {helpb addlegend##symopts:y()},
    {helpb addlegend##symopts:x()},
    {helpb addlegend##symopts:h()},
    {helpb addlegend##symopts:w()},
    {helpb addlegend##txtopts:ty()},
    {helpb addlegend##txtopts:tx()}, and
    {helpb addlegend##txtopts:tw()}
    are sticky in the sense that they change the default settings for
    subsequent keys. This is not true for options specified at the
    level of a key's symbol, which are non-sticky and only affect the current
    symbol. Finally, if both {helpb addlegend##symopts:y()} and
    {helpb addlegend##symopts:Y()} are omitted at the level of a legend key,
    the vertical position the key is determined as {it:y} - {it:lskip} *
    {it:h}, where {it:y} and {it:h} are the position and symbol height of the
    previous key and {it:lskip} is the baselineskip as set by option
    {helpb addlegend##lskip:lskip()}.

{pstd}
    Command {cmd:_mklegend} is the engine behind {cmd:addlegend}. It analyses
    the selected graph, creates the code of the custom legend (a set of
    {helpb twoway scatteri} commands), and stores it in macro
    {cmd:r(legend)}. {cmd:addlegend} then applies {helpb addplot} to add the
    contents of {cmd:r(legend)} to the selected graph.

{marker options}{...}
{title:Options}

{dlgtab:Main}

{marker lskip}{...}
{phang}
    {opt lskip(#)} sets the baseline skip between legend keys as a factor of
    the symbol height; the default is {cmd:lskip(1.5)}. Option {cmd:lskip()} has no
    effect on legend keys that are positioned explicitly by the
    {helpb addlegend##symopts:y()} option.

{marker frame}{...}
{phang}
    {cmd:frame}[{cmd:(}{it:subopts}{cmd:)}] draws a frame around the legend. The
    size and position of the frame will be determined automatically, but you will
    most likely have to adjust its width using suboption {cmd:w()} (or by setting
    the text width using option {helpb addlegend##txtopts:tw()}). Furthermore, you
    may want to adjust the padding (inner margin of the frame) using suboptions {cmd:ym()} and
    {cmd:xm()}. {it:subopts} are as follows.

{phang2}
    {opt ym(#)} and {opt YM(#)} set the vertical padding (margin at top
    and bottom between legend keys and frame) that is applied unless the frame
    is positioned manually using {cmd:y()} and {cmd:h()}. The default is
    {cmd:ym(2.5)}. {cmd:YM()} takes precedence over {cmd:ym()}.

{phang2}
    {opt xm(#)} and {opt XM(#)} set the default horizontal padding (margin at left
    and right between legend keys and frame) that is applied unless the frame
    is positioned manually using {cmd:x()} and {cmd:w()}. The default is
    {cmd:xm(2)}. {cmd:XM()} takes precedence over {cmd:xm()}.

{phang2}
    {opt y(#)} and {opt Y(#)} set the position of the top edge of the frame, in percent
    of the range of the Y-axis or in units of the Y-axis, respectively. {cmd:Y()}
    takes precedence over {cmd:y()}. Together, {cmd:y()} and {cmd:x()} determine the
    position of the upper-left corner of the frame.

{phang2}
    {opt x(#)} and {opt X(#)} set the position of the left edge of the frame,
    in percent of the range of the X-axis or in units of the X-axis,
    respectively. {cmd:X()} takes precedence over {cmd:x()}.

{phang2}
    {opt h(#)} and {opt H(#)} set the height of the frame, in percent of the
    range of the Y-axis or in units of the Y-axis, respectively. {cmd:H()}
    takes precedence over {cmd:h()}.

{phang2}
    {opt w(#)} and {opt W(#)} set the width of the frame, in percent of the
    range of the X-axis or in units of the X-axis, respectively. {cmd:W()}
    takes precedence over {cmd:w()}.

{phang2}
    {it:area_options} are options affecting the look of the fill and outline
    of the frame; see help {it:{help area_options}}. By default, options
    {cmd:lstyle(foreground)} and {cmd:fcolor(white)} will be applied. For
    example, type {cmd:fcolor(none)} for a frame without fill.

{marker margin}{...}
{phang}
    {opt margin(marginstyle)} resets the margin of the graph region; see help
    {it:{help marginstyle}}. This is useful if you want to place the legend in
    the margin of the graph instead of in the plot region. {cmd:margin()} has
    no effect if specified with {cmd:_mklegend}.

{phang}
    {opt nodraw} causes the graph data to be modified without updating the
    display in the graph window. Use {helpb graph display}
    to view the modified graph after applying {cmd:addlegend} with option
    {cmd:nodraw}. {cmd:nodraw} has no effect if specified with {cmd:_mklegend}.

{marker symopts}{...}
{dlgtab:symopts}

{phang}
    {opt y(#)} and {opt Y(#)} set the vertical position of the (first) legend
    key (i.e., the midpoint of the vertical space allocated for the key's
    symbol), in percent of the range of the Y-axis or in units of the Y-axis,
    respectively. The default is {cmd:x(95)}. {cmd:Y()} takes precedence over
    {cmd:y()}.

{pmore}
    Specifying {cmd:y()} or {cmd:Y()} only sets the position of the current
    (first) key. The positions of subsequent keys are determined as
    {it:y} - {it:lskip} * {it:h}, where
    {it:y} and {it:h} are the position and symbol height of the previous key
    and {it:lskip} is the baselineskip as set by option
    {helpb addlegend##lskip:lskip()}.

{phang}
    {opt x(#)} and {opt X(#)} set the horizontal position of the legend key
    (i.e., the left edge of the space allocated for the key's symbol, or the
    right edge if the key's width is negative), in percent of the range of the
    X-axis or in units of the X-axis, respectively. The default is
    {cmd:x(2)}. {cmd:X()} takes precedence over {cmd:y()}.

{phang}
    {opt h(#)} and {opt H(#)} set the height to be allocated for the legend
    key's symbol, in percent of the range of the Y-axis or in units of the
    Y-axis, respectively. The default is {cmd:h(5)}. {cmd:H()} takes precedence
    over {cmd:h()}.

{phang}
    {opt w(#)} and {opt W(#)} set the width to be allocated for the legend
    key's symbol, in percent of the range of the X-axis or in units of the
    X-axis, respectively. The default is {cmd:w(5)}. {cmd:W()} takes precedence
    over {cmd:w()}.

{phang}
    {it:marker_options} are options affecting the look of the markers included
    in the legend key's symbol; see help {it:{help marker_options}}. If omitted,
    option {cmd:pstyle()} will be set automatically based on the order of the
    key.

{phang}
    {it:line_options} are options affecting the look of the lines included
    in the legend key's symbol; see help {it:{help line_options}}.

{phang}
    {it:area_options} are options affecting the look of the areas included
    in the legend key's symbol; see help {it:{help area_options}}.

{marker txtopts}{...}
{dlgtab:txtopts}

{phang}
    {opt ty(#)} and {opt TY(#)} set the vertical offset of the text, relative
    to the position of the key's symbol, in percent of the range of the Y-axis
    or in units of the Y-axis, respectively. The default is
    {cmd:ty(0)}. {cmd:TY()} takes precedence over {cmd:ty()}.

{phang}
    {opt tx(#)} and {opt TX(#)} set the horizontal offset of the text, relative
    to the position of the key's symbol, in percent of the range of the X-axis
    or in units of the X-axis, respectively. The default is to set the offset
    to the width of the key's symbol plus 1 percent of the width of the
    X-axis. {cmd:TX()} takes precedence over {cmd:tx()}.

{phang}
    {opt tw(#)} and {opt TW(#)} set the with of the text, in percent of the
    range of the Y-axis or in units of the Y-axis, respectively. The default is
    {cmd:tw(20)}. This setting only affects how
    {helpb addlegend##frame:frame()} determines the size of the frame; it is
    irrelevant if {helpb addlegend##frame:frame()} is omitted. {cmd:TW()} takes
    precedence over {cmd:tw()}.

{phang}
    {opt text(textbox_options)} specifies options affecting look of the text,
    such as its size, color, or justification; see help
    {it:{help textbox_options}}. If omitted, options {cmd:placement()} and
    {cmd:justification()} are set automatically depending on the sign of
    {cmd:tx()}.


{title:Examples}

{dlgtab:Composite symbols}

{pstd}
    The following example illustrates how to create a composite symbol.

        . {stata sysuse auto}
{p 8 12 2}
    . {stata twoway (sc mpg turn, msize(large) ms(Oh)) (sc mpg turn, msize(large) ms(X) pstyle(p1)) (lfit mpg turn, pstyle(p2))}
    {p_end}
{p 8 12 2}
    . {stata `"addlegend, X(45) frame: (Oh X, msize(large)) "Mileage (mpg)" || (line) "Fitted values""'}
    {p_end}

{pstd}
    Option {cmd:X(45)} has been used to shift the legend to the right of the
    graph (the left edge of the space allocated for the keys' symbols is positioned
    at X = 45). By default, the legend is placed in the top-left corner.

{dlgtab:Custom positioning of legend keys}

{pstd}
    The following example illustrates how the legend keys can be placed in different
    locations on the plot.

        . {stata sysuse auto}
{p 8 12 2}
    . {stata twoway (hist weight if foreign==0, psty(p1bar) color(%50)) (hist weight if foreign==1, psty(p2bar) color(%50))}
    {p_end}
{p 8 12 2}
    . {stata `"addlegend, lskip(0) color(%50): (bar) "Domestic", X(4840) W(-300) || (bar) "Foreign", X(1760) W(300)"'}
    {p_end}

{pstd}
    Note how setting the symbol width to a negative value changes the default
    placement of the key's text.

{dlgtab:Headings}

{pstd}
    To create a heading that is aligned with the keys' symbols, type

        {cmd:"}{it:text}{cmd:"} [{cmd:"}{it:text}{cmd:"} [...]]

{pstd}
    Alternatively, to create a heading that is aligned with the
    keys' texts, type

        {cmd:-} {cmd:"}{it:text}{cmd:"} [{cmd:"}{it:text}{cmd:"} [...]]

{pstd}
    The following example illustrates the difference.

        . {stata sysuse uslifeexp}
{p 8 12 2}
    . {stata twoway (connect le_f le_m year)}
    {p_end}
{p 8 12 2}
    . {stata `"addlegend: "Heading aligned with symbol" || (line) () "female" || - "Heading aligned with text" || (line) () "male""'}
    {p_end}

{dlgtab:Placing the legend outside of the plot region}

{pstd}
    If you want to place the legend outside of the plot region, use the
    {helpb addlegend##margin:margin()} option to make sure that there is enough
    space for the legend in the graph's margin.

        . {stata sysuse auto}
{p 8 12 2}
    . {stata twoway (sc mpg turn, msize(large) ms(Oh)) (sc mpg turn, msize(large) ms(X) pstyle(p1)) (lfit mpg turn, pstyle(p2))}
    {p_end}
{p 8 12 2}
    . {stata `"addlegend, x(105) margin(r=40): (Oh X, msize(large)) "Mileage (mpg)" || (line) "Fitted values""'}
    {p_end}

{dlgtab:Add legend to subgraph}

{pstd}
    In case of a graph that contains multiple subgraphs, specify {cmd:addlegend} {it:#}
    to add the legend to subgraph {it:#} (by default, the legend is added to all
    subgraphs).

        . {stata sysuse auto}
{p 8 12 2}
    . {stata scatter mpg trunk weight, legend(off) name(weight, replace) nodraw}
    {p_end}
{p 8 12 2}
    . {stata scatter mpg trunk price, legend(off) name(price, replace) nodraw}
    {p_end}
{p 8 12 2}
    . {stata graph combine weight price}
    {p_end}
{p 8 12 2}
    . {stata `"addlegend 2, x(60) tw(35) frame: () "Mileage per gallon" || () "Trunk space""'}
    {p_end}

{pstd}
    Note that specifying a key's symbol as {cmd:()} selects the plot's default
    marker symbol.

{dlgtab:Use of _mklegend}

{pstd}
    {cmd:addlegend} is implemented as a wrapper for {cmd:_mklegend} followed by
    {helpb addplot}. In some cases you might want to apply {cmd:_mklegend}
    manually instad of using {cmd:addlegend}. Note that {cmd:_mklegend} stores
    the legend's code in macro {cmd:r(legend)}.

{pstd}
    For example, {cmd:addlegend} always removes the legend created by Stata's
    {cmd:legend()} option. The following example illustrates how you could
    create a graph that includes both types of legends.

        . {stata sysuse auto}
{p 8 12 2}
    . {stata twoway (sc mpg turn) (lfit mpg turn)}
    {p_end}
{p 8 12 2}
    . {stata `"_mklegend, x(60): () "Observations" || (line) "Linear fit""'}
    {p_end}
{p 8 12 2}
    . {stata `"addplot: `r(legend)', norescaling legend(order(1 "Mileage (mpg)" 2 "Fitted values"))"'}
    {p_end}

{pstd}
    Rather than using {helpb addplot} you can also include the code generated by
    {cmd:_mklegend} directly in a {helpb twoway} command:

        . {stata sysuse auto}
{p 8 12 2}
    . {stata twoway (sc mpg turn) (lfit mpg turn), nodraw}
    {p_end}
{p 8 12 2}
    . {stata `"_mklegend, x(80) frame: () "Observations" || (line) "Linear fit""'}
    {p_end}
{p 8 12 2}
    . {stata twoway (sc mpg turn) (lfit mpg turn) `r(legend)', legend(off)}
    {p_end}

{pstd}
    A further option is to include the legend's code in an
    {helpb addplot_option:addplot()} option:

        . {stata sysuse auto}
{p 8 12 2}
    . {stata lpoly weight length, degree(1) ci nodraw}
    {p_end}
{p 8 12 2}
    . {stata `"_mklegend, tw(25) frame: () "data" || (area, astyle(ci)) (line) "lopoly fit and 95% CI""'}
    {p_end}
{p 8 12 2}
    . {stata lpoly weight length, degree(1) ci legend(off) addplot(`r(legend)')}
    {p_end}


{title:Returned results}

{pstd} Scalars:

{p2colset 5 20 20 2}{...}
{p2col : {cmd:r(Ymin)}}minimum of the graph's Y axis{p_end}
{p2col : {cmd:r(Ymax)}}maximum of the graph's Y axis{p_end}
{p2col : {cmd:r(Xmin)}}minimum of the graph's X axis{p_end}
{p2col : {cmd:r(Xmax)}}maximum of the graph's X axis{p_end}
{p2col : {cmd:r(lskip)}}value of option {cmd:lskip()}{p_end}
{p2col : {cmd:r(y)}}(initial) value of option {cmd:y()}{p_end}
{p2col : {cmd:r(x)}}(initial) value of option {cmd:x()}{p_end}
{p2col : {cmd:r(h)}}(initial) value of option {cmd:h()}{p_end}
{p2col : {cmd:r(w)}}(initial) value of option {cmd:w()}{p_end}
{p2col : {cmd:r(ty)}}(initial) value of option {cmd:ty()}{p_end}
{p2col : {cmd:r(tx)}}(initial) value of option {cmd:tx()}{p_end}
{p2col : {cmd:r(tw)}}(initial) value of option {cmd:tw()}{p_end}
{p2col : {cmd:r(Y)}}(initial) value of option {cmd:Y()}{p_end}
{p2col : {cmd:r(X)}}(initial) value of option {cmd:X()}{p_end}
{p2col : {cmd:r(H)}}(initial) value of option {cmd:H()}{p_end}
{p2col : {cmd:r(W)}}(initial) value of option {cmd:W()}{p_end}
{p2col : {cmd:r(TY)}}(initial) value of option {cmd:TY()}{p_end}
{p2col : {cmd:r(TX)}}(initial) value of option {cmd:TX()}{p_end}
{p2col : {cmd:r(TW)}}(initial) value of option {cmd:TW()}{p_end}
{p2col : {cmd:r(fr_y)}}value of option {cmd:y()} in {cmd:frame()}{p_end}
{p2col : {cmd:r(fr_x)}}value of option {cmd:x()} in {cmd:frame()}{p_end}
{p2col : {cmd:r(fr_h)}}value of option {cmd:h()} in {cmd:frame()}{p_end}
{p2col : {cmd:r(fr_w)}}value of option {cmd:w()} in {cmd:frame()}{p_end}
{p2col : {cmd:r(fr_ym)}}value of option {cmd:ym()} in {cmd:frame()}{p_end}
{p2col : {cmd:r(fr_xm)}}value of option {cmd:xm()} in {cmd:frame()}{p_end}
{p2col : {cmd:r(fr_Y)}}value of option {cmd:Y()} in {cmd:frame()}{p_end}
{p2col : {cmd:r(fr_X)}}value of option {cmd:X()} in {cmd:frame()}{p_end}
{p2col : {cmd:r(fr_H)}}value of option {cmd:H()} in {cmd:frame()}{p_end}
{p2col : {cmd:r(fr_W)}}value of option {cmd:W()} in {cmd:frame()}{p_end}
{p2col : {cmd:r(fr_YM)}}value of option {cmd:YM()} in {cmd:frame()}{p_end}
{p2col : {cmd:r(fr_XM)}}value of option {cmd:XM()} in {cmd:frame()}{p_end}

{pstd} Macros:

{p2col : {cmd:r(legend)}}code that generates the legend
    {p_end}


{title:References}

{phang}
    Jann, B. 2015. A note on adding objects to an existing twoway graph. The Stata Journal
    15(3): 751-755. {browse "https://doi.org/10.1177/1536867X1501500308"}
    {p_end}


{title:Author}

{pstd}
    Ben Jann, University of Bern, ben.jann@unibe.ch

{pstd}
    Thanks for citing this software as follows:

{pmore}
    Jann, B. 2026. addlegend: Stata utility to add a custom legend to a twoway graph. Available from
    {browse "https://github.com/benjann/addlegend/"}.


{title:Also see}

{psee}
    Online:  help for
    {helpb graph twoway}, {helpb addplot} (from SSC)
