{smcl}
{* 1may2013}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "tlist" "tlist"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:tlisthead} {hline 2} Set up super-headers for {cmd:tlist}

{title:Syntax}

{pmore}{cmdab:tlisthead} {it:row}  [{cmd:,} {opt a:cross(delimiter)} {opt u:p(delimiter)} {opt b:egin} {opt di:splay}]

{pstd}where {it:row} is:

{pmore}{it:heading} [{it:delimiter} {it:heading}] [...]

{pstd}and where {it:delimiter} can be:

{pmore}{cmd:\} or {cmd:|} or one of the delimiters specified in {opt a:cross()} or {opt u:p()}

{pstd}{bf:[+]} Note that spaces around {it:delimters} are considered part of the relevant {it:headings}.


{title:Description}

{pstd}{cmd:tlisthead} iteratively sets up super-headings (and/or headings) for {help tlist}:

{phang2}o-{space 2}The first time {cmd:tlisthead} is invoked, it sets up a single {it:row} of headers.{p_end}
{phang2}o-{space 2}On each subsequent ivocation, it adds another {it:row} below the others.{break}(But see below for starting over){p_end}
{phang2}o-{space 2}The final placement of data columns below the headers is determined by {cmd:tlist}.{p_end}

{pstd}There are two possible delimiters to use, {bf:across} and {bf:up}. By default, {bf:across} is {cmd:\} and {bf:up} is {cmd:|}, but they can be set in the options.

{phang2}o-{space 2}Both {bf:across} and {bf:up} separate one {it:heading} from the next within a {it:row}.{p_end}
{phang2}o-{space 2}{bf:up} also aligns with a delimiter in the previous (higher) {it:row}.{p_end}
{pmore2}Any rows beyond the first {it:must} include exactly one {bf:up} for each delmiter in the previous row.{p_end}

{pstd}{cmd:tlisthead} will 'start over' with the single specified {it:row}:

{phang2}1){space 2}When using the {opt b:egin} option{p_end}
{phang2}2){space 2}When there are NO {bf:up} delimiters, and that doesn't match the previous row.


{title:Options}

{phang}{opt a:cross(delimiter)} specifies an {bf:across} delimiter to use instead of the default {cmd:\}

{phang}{opt u:p(delimiter)} specifies an {bf:up} delimiter to use instead of the default {cmd:|}

{phang}{opt b:egin} replaces any existing headings with the specified single {it:row}.

{phang}{opt di:splay} shows the entire table of headings, as it would be used in a subsequent {cmd:tlist}.


{title:Example}

{space 4}{cmd:tlisthead a\ b \c}
{space 4}{cmd:tlisthead a1\a2 | b1 | c1\c2\c3}
{space 4}{cmd:tlist v1 v2 | v3 | v4 v5 | v6 | v7 | v8}

{pstd}Result:

{space 4}          {txt:a}     {txt: {c 124} }    {txt:b}    {txt: {c 124} }       {txt:c}       {txt: {c 124} }
{space 4}{txt:                 {c 124}           {c 124}                 {c 124}}
{space 4}     {txt:a1}   {txt: {c 124} }{txt:a2 }{txt: {c 124} }   {txt: b1 }  {txt: {c 124} }{txt: c1}{txt: {c 124} }{txt:c2} {txt: {c 124} } {txt:c3}{txt: {c 124} }
{space 4}{txt:           {c 124}     {c 124}           {c 124}     {c 124}     {c 124}     {c 124}}
{space 4} {txt:v1} {txt: {c 124} }{txt:v2} {txt: {c 124} }{txt:v3} {txt: {c 124} }{txt:v4} {txt: {c 124} }{txt:v5} {txt: {c 124} }{txt:v6} {txt: {c 124} }{txt:v7} {txt: {c 124} } {txt:v8}{txt: {c 124} }
{space 4}{txt:{hline 5}{c +}{hline 5}{c +}{hline 5}{c +}{hline 5}{c +}{hline 5}{c +}{hline 5}{c +}{hline 5}{c +}{hline 5}{c RT}}
{space 4} {res:v11}{txt: {c 124} }{res:v21}{txt: {c 124} }{res:v31}{txt: {c 124} }{res:v41}{txt: {c 124} }{res:v51}{txt: {c 124} }{res:v61}{txt: {c 124} }{res:v71}{txt: {c 124} }{res:v81}{txt: {c 124} }
{space 4} {res:v12}{txt: {c 124} }{res:v22}{txt: {c 124} }{res:v32}{txt: {c 124} }{res:v42}{txt: {c 124} }{res:v52}{txt: {c 124} }{res:v62}{txt: {c 124} }{res:v72}{txt: {c 124} }{res:v82}{txt: {c 124} }

