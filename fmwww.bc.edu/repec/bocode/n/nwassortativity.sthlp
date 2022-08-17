{smcl}
{* *! version 1.1 Agust2022}{...}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwassortativity {hline 2} Computes assortativity coefficients.}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwassortativity}
[{cmd:,}
{opt NETwork()}
{opt Attribute()}
{opt Discrete}
{opt Continuous}
]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt net:work(netname)}} Indicate the network name. Can be a network, a mata matrix or a prefix designing Stata variables adjacency matrix. Required.

{synopt:{opt a:ttribute(varname)}} Indicate the node's attribute on which to compute the assortativity.  Required .

{synopt:{opt d:iscrete}} Indicates that {opt a:ttribute(varname)} is discrete.

{synopt:{opt c:ontinuous}} Indicates that {opt a:ttribute(varname)} continuous.

Either {opt d:iscrete} or {opt c:ontinuous} should be indicated.

{synoptline}
{p2colreset}{...}



{title:Description}

{pstd}
The assortativity coefficient corresponds to the preference for a network's nodes to attach to others that are similar in some way.

{pstd}
{cmd:nwassortativity} returns the assortativity coefficient of nodes based on the attribute defined in option {opt a:ttribute(varname)} 

{pstd}
For continuous attributes, the  assortativity coefficient is computed as the Pearson correlation coefficient of attributes between neighbors nodes.   

{pstd}
For discrete attributes, the assortativity coefficient is computed follwing Newman (2003) method. 


{title:Examples}

clear
webnwuse gang

nwassortativity, net(gang) at(Age) continuous
nwassortativity, net(gang) at(Birthplace) discrete


{title:Author}
Charlie Joyez, Université Côte d'Azur
charlie.joyez@univ-cotedazur.fr

{title:references}
Newman, M. E. (2003). Mixing patterns in networks. Physical review E, 67(2), 026126.
