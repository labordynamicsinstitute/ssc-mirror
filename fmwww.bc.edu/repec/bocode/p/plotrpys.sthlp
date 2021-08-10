{smcl}
{* 2017-07-19 Lutz Bornmann}{...}
{title:Title}
{p2colset 5 14 23 2}{...}

{p2col:{cmd:plotrpys} {hline 2} uses CSV export from CRExplorer ({browse "http://www.crexplorer.net/"}) and plots a spectrogram}

{p2colreset}{...}
{title:General syntax}

{p 4 18 10}
{cmdab:plotrpys}
{opt , color(col|mono)}
[{startyr(year) incre(numeric) endyr(year)}]


{marker overview}
{title:Overview}

{pstd}
{cmd:plotrpys} uses CSV export from CRExplorer ({browse "http://www.crexplorer.net/"}) and plots a spectrogram. After import of the CSV file in Stata, the command needs three variables in this order: (1) cited references year, (2) cited references counts, and (3) deviation from the median. The command demands the specification whether the user requires colored or monochrome spectrograms.
{p_end}

{marker options}
{title:Options}
{p2colset 5 12 13 0}
{synopt:{opt color(col|mono)}} specifies whether the plot is colored or monochrome.

{synopt:{opt startyr(year)}} specifies the first year on the x-axis.

{synopt:{opt endyr(year)}} specifies the last year on the x-axis.

{synopt:{opt incre(numeric)}} specifies the increments in years on the x-axis.

{marker examples}
{title:Examples}

{pstd}
{cmd: . plotrpys year ncr median5, color(col)}
{p_end}

{pstd}
{cmd: . plotrpys year ncr median5, color(mono) startyr(1600) incre(50) endyr(1980)}
{p_end}


{title:Author}

{phang}Lutz Bornmann, Max Planck Society, Munich{break}
bornmann@gv.mpg.de{p_end}