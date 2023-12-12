{smcl}
{* *! version 1.0.0 28nov2022}
{cmd: help chesspuzzle}
{hline}

{title:Title}

{pstd}{hi:chesspuzzle} {hline 2} Solve Chess Puzzles


{title:Syntax}

{p 4}
{cmd:chesspuzzle}

{title:Description}

{pstd}{cmd:chesspuzzle} gives you a chess position from one of over 200 historical games, along with information on the game and a prompt that gives you the task and whether white or black is to move. As of now, all puzzles are of the type "mate in two" and taken from {browse "https://wtharvey.com/":Bill Harvey's website}. 

{pstd}You have to type your answer in Algebraic notation (e.g., {bf:qxh8+}) or verbally (e.g., {bf:Queen to h8}). Don't forget the take, check and mate signs ("x", "+", "#") in Algebraic notation. Verbal notation is always the same, however. Both notations are case-insensitive, but do not tolerate unnecessary blanks. If you cannot figure it out or have to do something else, type {cmd:out} into the command line and the program will stop. If you want to learn the correct answer, type {cmd:help}.

{pstd}{cmd:chesspuzzle} comes with {cmd:{help chesspos}} to print the chess position. {p_end}


{title:Acknowledgements}

{phang}Thanks to Maik Hamjediers for helpful feedback.{p_end}

{title:Author}

{phang} Dominik Flügel ({browse "mailto:mail@dominikfluegel.de":mail@dominikfluegel.de}) {p_end}