{smcl}
{* *! version 5.0.0  15fev2020}{...}

{title:Map}

{pstd}
{hi:map} {hline 2} maps all the unique levels of a variable or list of variables to values specified in a dictionary list.

{marker syntax}{...}
{title:Syntax}

{pstd}
  {cmd:map} {help varlist:{it:varlist}}{cmd:,}
  {bf:{ul:dict}ionary(}{help frame}{bf:)}
  [{bf:{ul:v}alues(}{help varname}{bf:)}]
  
{title:Description}

{pstd}
The {it:map} command maps all the unique levels of a variable or list of variables (the keys)
to their associated values (the values).
A dictionary list lists and pairs the keys and values together.
This dictionary can be specified in any frame other than the active one.

{pstd}
Some general remarks:

{pstd}
- All the keys must be unique but multiple keys can be paired with the same values.{break}
- All the variables to match should be either strings or integers.


{title:General options}

{pstd}
{bf:{ul:dict}ionary(}{help frame}{bf:)}: specifies the frame containing the dictionary. {it: This option is required.}

{pstd}
{bf:{ul:v}alues(}{help varname}{bf:)}: selects the variable in the dictionary frame containing the values to be returned. {it:dict automatically detects this variable if all variables in the dictionary except one are used as keys.}
{it: Specify this option only if that is not the case.}

{title:Example}

{pstd}
Consider the database:

      id    geo     time    value
    {hline 32}
       1     AT     2017     0.72
       2     AT     2018     0.73
       3     AT     2019     0.74
       4     BE     2017     0.63
       5     BE     2018     0.65
       6     BE     2019     0.65
       7     DE     2017     0.75
       8     DE     2018     0.76
       9     DE     2019     0.77
       .      .        .        .
      45     UK     2019     0.75
    {hline 32}

{pstd}
And the following dictionary in frame {it:country_list}:

      geo               name
    {hline 27}
       AT            Austria
       BE            Belgium
       DE            Germany
        .                  .
       UK     United Kingdom
    {hline 27}

   {cmd: map geo, dictionary(country_list)}

      id    geo             name     time    value
    {hline 49}
       1     AT          Austria     2017     0.72
       2     AT          Austria     2018     0.73
       3     AT          Austria     2019     0.74
       4     BE          Belgium     2017     0.63
       5     BE          Belgium     2018     0.65
       6     BE          Belgium     2019     0.65
       7     DE          Germany     2017     0.75
       8     DE          Germany     2018     0.76
       9     DE          Germany     2019     0.77
       .      .                .        .        .
      45     UK   United Kingdom     2019     0.75
    {hline 49}


{title:Author}

{pstd}
{it:Daniel Alves Fernandes}{break}
European University Institute

{pstd}
daniel.fernandes@eui.eu

