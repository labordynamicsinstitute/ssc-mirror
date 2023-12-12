{smcl}
{* *! version 1.0.0 28nov2022}
{cmd: help chesspos}
{hline}

{title:Title}

{pstd}{hi:chesspos} {hline 2} show chess position in FEN notation as a graph

{title:Syntax}

{p 4}
{cmd:chesspos} ["]<position in FEN notation>["] [, {opt b:lack} {opt name(name, ...)} {opt saving(filename, ...)} {opt nodraw}]

{title:Options}

{synoptset 20}{...}
{synopt: {opt b:lack}} turns the board to view it from Black's perspective{p_end}
{synopt: {bf:{help nodraw_option:nodraw}}} suppress display of graph
{p_end}
{synopt: {bf:{help name_option: name({it:name, ...})}}} specify name for final graph
{p_end}
{synopt: {bf:{help saving_option: saving({it:filename, ...})}}} save final graph in file
{p_end}

{title:Example}

{p 4}
{stata chesspos "rnbqkbn1/ppppp3/7r/6pp/3P1p2/3BP1B1/PPP2PPP/RN1QK1NR"}

{title:Author}

{phang} Dominik Flügel ({browse "mailto:mail@dominikfluegel.de":mail@dominikfluegel.de}) {p_end}

{title:Also see}

{psee}
Online: {browse https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation}
{p_end}