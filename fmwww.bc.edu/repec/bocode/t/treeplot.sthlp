{smcl}
{* 22May2022}{...}
{cmd:help treeplot}
{hline}

{title:Title}

{p2colset 5 16 21 2}{...}
{p2col :{hi:treeplot}{hline 2}}Graphing a tree in Stata{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{hi:treeplot}
{it:outcome} 
{it:features},
{cmd:type}{cmd:(}{it:tree_type}{cmd:)}
{cmd:tree_depth}{cmd:(}{it:integer}{cmd:)}
{cmd:predict}{cmd:(}{it:name}{cmd:)}
{cmd:save_graph}{cmd:(}{it:graph_name}{cmd:)}
{cmd:fig_size}{cmd:(}{it:integer}{cmd:)}
{cmd:dpi}{cmd:(}{it:integer}{cmd:)}
{cmd:h}{cmd:(}{it:name}{cmd:)}


{dlgtab:Inputs}

{phang} {it:outcome}: numerical variable (for a regression tree), or categorical variable (for a classification tree)   

{phang} {it:features}: list of numerical variables representing the features. When a feature is categorical,
please generate the categorical dummies related to this feature. As the command does not do it by default,
it is user's responsibility to generate the appropriate dummies   


{dlgtab:Description}

{pstd} {cmd:treeplot} is a command for graphing a regression or classification tree in Stata 16.
It uses the Stata/Python integration ({browse "https://www.stata.com/python/api16/Data.html":sfi}) 
capability of Stata 16 making use of the Python {browse "https://scikit-learn.org/stable/":Scikit-learn} API.

    
{dlgtab: Options}

{synoptset 32 tabbed}{...}
{synoptline}
{synopt :{opt type(tree_type)}} sets the type of tree, where {it:tree_type} is "reg" for regression and "class" for classification{p_end}
{synopt :{opt tree_depth(integer)}} sets the depth of the tree, where {it:integer} is the maximum depth{p_end}
{synopt :{opt predict(name)}} generates regression or classification predictions, with {it:name} indicating the name of the variable that will contain the predicted values{p_end}
{synopt :{opt save_graph(graph_name)}} saves the plot on the hard-disk, with {it:graph_name} the chosen name of the plot{p_end}
{synopt :{opt fig_size(integer)}} defines the size of the plot, with {it:integer} the chosen size{p_end}
{synopt :{opt dpi(integer)}} sets the quality rendering of the figure, with {it:dpi} indicating the dots per inches (that is, how many pixels the figure comprises){p_end}
{synopt :{opt h(name)}} is a generated variable identifying with a "1" the observations used to build the tree{p_end}
{synoptline}


{dlgtab:Remarks}

{phang} To run this program you need to have both Stata 16 (or later versions) and Python 
           (from version 2.7 onwards) installed. You can find information about how to install 
           Python in your machine here: https://www.python.org/downloads.
           Also, the Python Scikit-learn (and related dependencies) and the Stata Function Interface (sfi) APIs
           must be uploaded before running the command. You can find information about how to install/use
           them here (observe that the SFI API is already installed in your Stata 16 or later versions): 
           (1) Scikit-learn: https://scikit-learn.org/stable/install.html; (2) sfi: https://www.stata.com/python/api17. 

{phang} Please, remember to have the most recent up-to-date version of this program installed.


{dlgtab:Example}
{pstd}{bf:Example 1}: Plot a regression tree{p_end}
{phang2} Load initial dataset{p_end}
{phang3} {stata sysuse auto, clear}{p_end}
{phang2} Run and plot a tree regression{p_end}
{phang3} {stata treeplot price mpg rep78 headroom , type("reg") tree_depth(3) predict("pred") save_gr("graph_tree_r") fig_size(6) dpi(600) h("sample")}{p_end}

{pstd}{bf:Example 2}: Plot a classification tree{p_end}
{phang2} Load initial dataset{p_end}
{phang3} {stata webuse iris, clear}{p_end}
{phang2} Run and plot a tree classification{p_end}
{phang3} {stata treeplot iris seplen sepwid petlen petwid , type("class") tree_depth(3) predict("pred") save_gr("graph_tree_c") fig_size(6) dpi(600) h("sample")}{p_end}


{dlgtab:Reference}

{phang}
Cerulli, G. 2021. Improving econometric prediction by machine learning, {it:Applied Economics Letters}, 28, 16, 1419-1425, 2021.

{phang}
Droste, M. 2022. {it:Stata-pylearn}. Available at: https://github.com/mdroste/statapylearn.

{phang}
Gareth, J., Witten, D., Hastie, D.T., Tibshirani, R. 2013. {it:An Introduction to Statistical Learning : with Applications in R}. New York, Springer.

{phang} 
Raschka, S., Mirjalili, V. 2019. {it:Python Machine Learning}. 3rd Edition, Packt Publishing.


{dlgtab:Author}

{phang}Giovanni Cerulli{p_end}
{phang}IRCrES-CNR{p_end}
{phang}Research Institute for Sustainable Economic Growth, National Research Council of Italy{p_end}
{phang}E-mail: {browse "mailto:giovanni.cerulli@ircres.cnr.it":giovanni.cerulli@ircres.cnr.it}{p_end}


{dlgtab:Also see}

{psee}
Online: {helpb python}, {helpb c_ml_stata_cv}, {helpb r_ml_stata_cv} {helpb srtree}, {helpb sctree}, {helpb subset}
{p_end}
