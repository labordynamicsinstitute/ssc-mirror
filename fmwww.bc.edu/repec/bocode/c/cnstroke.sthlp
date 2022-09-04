{smcl}
{* 01sep2022}{...}
{cmd:help cnstroke}{right: }
{hline}

{title:Title}


{phang}
{bf:cnstroke} {hline 2} Returns the stroke count of Chinese characters.
                       

{title:Syntax}

{p 8 18 2}
{cmdab:cnstroke} {it: CNW}

    where CNW is a Chinese characters


{marker description}{...}
{title:Description}

{pstd}
{cmd:cnstroke} can get the stroke count of any Chinese character, and the result is returned in r(cnstroke), as long as that is not empty.


{marker example}{...}
{title:Example}

{pstd}

{pstd}
Get the stroke count of the Chinese character "中"

{phang}
{stata `"cnstroke 中"'}
{p_end}

{pstd}
Get the stroke count of the Chinese character "国"

{phang}
{stata `"cnstroke 国"'}
{p_end}


{title:Authors}

{pstd}Yuyan Li{p_end}
{pstd}Zhongnan University of Economics and Law{p_end}
{pstd}Wuhan, China{p_end}
{pstd}y1539691364@163.com{p_end}

{pstd}Dr. Muhammad Usman{p_end}
{pstd}UE Business School, Division of Management and Administrative Sciences{p_end}
{pstd}University of Education, Lahore, Pakistan{p_end}
{pstd}m.usman@ue.edu.pk{p_end}

{pstd}Haitao Si{p_end}
{pstd}Wuhan University{p_end}
{pstd}Wuhan, China{p_end}
{pstd}sihaitao0114@163.com{p_end}




