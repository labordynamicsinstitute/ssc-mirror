{smcl}
{* *! version 1.1.2  07oct2022}{...}
{viewerjumpto "Examples" "summarizeby##examples"}{...}
{title:Title}

{phang}
{bf:summarizeby} {hline 2} Extend {helpb statsby}
for {helpb summarize} with the same syntax but no ": command"

{marker examples}{...}
{title:Examples}

        {cmd:. sysuse auto, clear}

        * simple example, collect all statistics returned by summarize
        {cmd:. summarizeby, clear}

        * same example with by()
        {cmd:. summarizeby, clear by(foreign)}

        * detailed example, collect all statistics returned by summarize
        {cmd:. summarizeby, clear detail}

        * save main statistics into a DTA file
        {cmd:. summarizeby mean=r(mean) sd=r(sd) min=r(min) max=r(max), saving(stats)}

        * compare and contrast main statistics for two datasets
        {cmd:. tempfile tmpf}
        {cmd:. preserve}
        {cmd:. summarizeby mean=r(mean) sd=r(sd) if mpg > 20, saving(`tmpf')}
        {cmd:. restore}
        {cmd:. summarizeby mean=r(mean) sd=r(sd), clear}
        {cmd:. append using `tmpf', gen(id)}
        {cmd:. order id}
        {cmd:. label define dataset 0 "full" 1 "reduced"}
        {cmd:. label values id dataset}

        * export to excel
        {cmd:. export excel * using "stats.xlsx", firstrow(variables)}

{title:Author}

{pstd}
{bf:Ilya Bolotov}
{break}Prague University of Economics and Business
{break}Prague, Czech Republic
{break}{browse "mailto:ilya.bolotov@vse.cz":ilya.bolotov@vse.cz}

{pstd}
    Thanks for citing this software and my works on the topic:

{p 8 8 2}
Bolotov, I. (2020). SUMMARIZEBY: Stata module to use statsby functionality with
    summarize. Available from
    {browse "https://ideas.repec.org/c/boc/bocode/s458870.html"}.
