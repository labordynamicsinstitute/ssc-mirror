{smcl}
{* *! version 1.0 July 21, 2021}{...}
{cmd:help sblsf}
{hline}

{pstd}

{title:Title}

{p2colset 5 14 16 2}{...}
{ p2col:{hi:sblsf} {hline 2}}sblsf allows users to easily browse and access the posts of  {browse "https://www.statalist.org/forums/forum/general-stata-discussion/general":The Stata Forums} in the stata window, including the title of the post, the number of visits and the number of replies.{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 4 8 2}
{cmd:sblsf}
[{cmd:,}
{cmdab:p:age(int)}
{cmdab:sort(string)} 
{cmdab:c:ls} 
{cmdab:g:ap} 
{cmdab:l:ine}
{cmdab:m:link}
{cmdab:w:echat}
]

{p 2 8 2}

{synoptset 10}{...}
{synopthdr:Options}
{synoptline}
{synopt:{cmdab:p:age(int)}}
Select the number of pages to browse The Stata Forums. The default is the first page.
{p_end}
{synopt:{cmdab:sort(str)}}
The order of The Stata Forums. Including sort(title), sort(last), sort(start), sort(like), sort(replie), sort(member). See {browse "https://www.statalist.org/forums/forum/general-stata-discussion/general":The Stata Forums}
{p_end}
{synopt:{cmdab:c:ls}}
Display the The Stata Forums after clearing the Results window
{p_end}
{synopt:{cmdab:s:tyle}}
The display style and color of The Stata Forums posts,s(3) represents black, s(1) represents blue, s(2) represents red, and the default is s(3)
{p_end}
{synopt:{cmdab:g:ap}}
Leave a space between different posts
{p_end}
{synopt:{cmdab:l:ine}}
There is a horizontal line between different posts
{p_end}
{synopt:{cmdab:m:link}}
Generate the data of the forum post link in the form of Markdown. The function is mainly used to display Stata posts in the blog
{p_end}
{synopt:{cmdab:w:echat}}
Generate the data of the forum post link in the form of Title+Url. The function is mainly used in other social software to share and exchange stata posts with peers, such as WeChat and WhatsApp.
{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}{cmd:sblsf} sblsf allows users to easily browse and access the posts of  {browse "https://www.statalist.org/forums/forum/general-stata-discussion/general":The Stata Forums} in the stata window, including the title of the post, the number of visits and the number of replies.

{title:Examples} 

{pstd}Browse posts on The Stata Forums homepage.{p_end}
{phang}{stata "sblsf" : . sblsf}{p_end}

{pstd}The Stata forum posts are displayed in blue style{p_end}
{phang}{stata "sblsf,s(1)" : . sblsf,s(1)}{p_end}

{pstd}The Stata forum posts are displayed in red style{p_end}
{phang}{stata "sblsf,s(2)" : . sblsf,s(2)}{p_end}

{pstd}Display the The Stata Forums after clearing the Results window {p_end}
{phang}{stata "sblsf,cls" : . sblsf,cls}{p_end}

{pstd}Leave a space between different posts{p_end}
{phang}{stata "sblsf,gap" : . sblsf,gap}{p_end}

{pstd}There is a horizontal line between different posts{p_end}
{phang}{stata "sblsf,line" : . sblsf,line}{p_end}

{pstd}Show posts on page 10 of The Stata Forums. {p_end}
{phang}{stata "sblsf,page(10)" : . sblsf,page(10)}{p_end}

{pstd}Sort by the number of replies to posts on the stata forum.{p_end} 
{phang}{stata "sblsf,sort(replie)" : . sblsf,sort(replie)}{p_end}

{phang} Generate the data of the forum post link in the form of Title+Url{p_end}
{phang}{stata "sblsf,w" : . sblsf,w}{p_end}

{phang} Generate the data of the forum post link in the form of Markdown.{p_end}
{phang}{stata "sblsf,m" : . sblsf,m}{p_end}

{title:Author}

{phang}
{cmd:Song Bolin(松柏林)} Shenzhen University, China. {cmd:wechat}：songbl_stata{break}
{p_end}

{title:Other Commands}
{pstd}

{synoptset 30 }{...}
{synopt:{help songbl} (if installed)} {stata ssc install songbl} (to install){p_end}
{synopt:{help sbldo } (if installed)} {stata ssc install sbldo } (to install){p_end}
{synopt:{help cngdf } (if installed)} {stata ssc install cngdf } (to install){p_end}
{p2colreset}{...}

