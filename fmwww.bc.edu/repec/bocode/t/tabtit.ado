*! version 2.10 06June2014 M. Araar Abdelkrim & M. Paolo verme
/*************************************************************************/
/* SUBSIM: Subsidy Simulation Stata Toolkit  (Version 2.1)               */
/*************************************************************************/
/* Conceived by Dr. Araar Abdelkrim[1] and Dr. Paolo Verme[2]            */
/* World Bank Group (2012-2014)		                                 */
/* 									 */
/* [1] email : aabd@ecn.ulaval.ca                                        */
/* [1] Phone : 1 418 656 7507                                            */
/*									 */
/* [2] email : pverme@worldbank.org                                      */
/*************************************************************************/



#delimit ;
capture program drop tabtit;
program define tabtit, rclass sortpreserve;
version 9.2;
args ntab lan;
local	tabtit_11_fr	=	"Tableau 1.1: Population et dépenses	"	;

local	tabtit_21_fr	=	"Tableau 2.1: Dépense totale (monnaie)	"	;
local	tabtit_22_fr	=	"Tableau 2.2: Dépenses par ménage (monnaie)	"	;
local	tabtit_23_fr	=	"Tableau 2.3: Dépenses per capita (monnaie)	"	;
local	tabtit_24_fr	=	"Tableau 2.4: Quantités consommées des produits subventionnés (en quantité)"	;
local	tabtit_25_fr	=	"Tableau 2.5: Quantités consommées per capita des produits subventionnés  (en quantité) "	;

local	tabtit_31_fr	=	"Tableau 3.1: Structure des dépenses sur les produits subventionnés (en %)	"	;
local	tabtit_32_fr	=	"Tableau 3.2: Dépense sur les produits subventionnés par rapport aux dépenses totales (en %) "	;
local	tabtit_33_fr	=	"Tableau 3.3: Le total des bénéfices via les subsides (en monnaie)"	;
local	tabtit_34_fr	=	"Tableau 3.4: Les bénéfices per capita via les subsides (en monnaie)"	;
local	tabtit_35_fr	=	"Tableau 3.5: Les parts des bénéfices via les subsides (en %)"	;
local	tabtit_36_fr	=	"Tableau 3.6: Les bénéfices per capita via les subsides (en monnaie) : dépenses > 0"	;

local	tabtit_41_fr	=	"Tableau 4.1: Le total des impacts sur le bien-être de la population (en monnaie)";		
local	tabtit_42_fr	=	"Tableau 4.2: L'impact sur le bien-être per capita (en monnaie)";
local	tabtit_43_fr	=	"Tableau 4.3: L'impact sur le bien-être (en %)";
local	tabtit_44_fr	=	"Tableau 4.4: L'impact total sur les quantités consommées (en quantité)";                              
local	tabtit_45_fr	=	"Tableau 4.5: L'impact total sur les quantités consommées per capita (en quantité)";	
local	tabtit_46_fr	=	"Tableau 4.6: L'impact de la réforme sur les recettes de l'état (en monnaie)";
local	tabtit_47_fr	=	"Tableau 4.7: Reformes et taux de pauvreté";	
local	tabtit_48_fr	=	"Tableau 4.8: Reformes et carence moyenne de pauvreté";
local	tabtit_49_fr	=	"Tableau 4.9: Réformes et l'inégalité de Gini"; 


local	tabtit_11_en	=	"Table 1.1: Population and expenditures	(in currency)"	;

local	tabtit_21_en	=	"Table 2.1: Expenditures (in currency)	"	;
local	tabtit_22_en	=	"Table 2.2: Expenditures per household (in currency)	"	;
local	tabtit_23_en	=	"Table 2.3: Expenditures per capita (in currency)	"	;
local	tabtit_24_en	=	"Table 2.4: Quantities consumed of subsidized products (in quantity) "	;
local	tabtit_25_en	=	"Table 2.5: Per capita consumed quantities of subsidized products (in quantity) "	;

local	tabtit_31_en	=	"Table 3.1: Structure of expenditure on subsidized products (in %)"	;
local	tabtit_32_en	=	"Table 3.2: Expenditure on subsidized products over the total expenditures (in %)	"	;
local	tabtit_33_en	=	"Table 3.3: The total benefits through subsidies (in currency)"	;
local	tabtit_34_en	=	"Table 3.4: The per capita benefit through subsidies (in currency)"	;
local	tabtit_35_en	=	"Table 3.5: The share of benefits through subsidies (in %)"	;
local	tabtit_36_en	=	"Table 3.6: The per capita benefit through subsidies (in currency): expenditures > 0"	;

local	tabtit_41_en	=	"Table 4.1: The total impact on the population well-being (in currency)";		
local	tabtit_42_en	=	"Table 4.2: The impact on the per capita well-being (in currency)";	
local	tabtit_43_en	=	"Table 4.3: The impact on  well-being (in %)";	
local	tabtit_44_en	=	"Table 4.4: The total impact on consumed quantities (in quantity)";                              
local	tabtit_45_en	=	"Table 4.5: The impact on the per capita consumed quantities (in quantity)";
local	tabtit_46_en	=	"Table 4.6: The impact of the reform on the government revenue (in currency)";
local	tabtit_47_en	=	"Table 4.7: The reform and the poverty headcount";	
local	tabtit_48_en	=	"Table 4.8: The reform and the poverty gap";
local	tabtit_49_en	=	"Table 4.9: The reform and the Gini inequality";


return local tabtit `tabtit_`ntab'_`lan'';
end;


