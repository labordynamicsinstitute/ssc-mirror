{smcl}
{* January 2013}{...}
{title:Specifying the aggregation of results by subsets of items and their labels} 

{p 0 0} {cmdab:Form}:  # # # ... : label  | # # # ... : label |...


{title:Example}
If we have the following list of items:

1- Butane 
2- Petrol
3- Gas 

4- Cub Sugar 
5- Granulated Sugar
6- Powdered Sugar 

7- National Flour 
8- Free Flour 

You may want to aggregate the result for sugar and flour. This may be done by adding the option:
aggr( 4 5 6 : "Sugar" | 7 8 : "Flour" )





