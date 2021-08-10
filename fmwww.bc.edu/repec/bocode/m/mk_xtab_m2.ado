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


#delim ;
capture program drop mk_xtab_m2;
program define mk_xtab_m2, rclass;
version 9.2;
syntax anything [,  matn(string) dste(int 1) dec(int 6)
 xfil(string) xshe(string) xtit(string)  xlan(string) hsep(int 0) topnote(string)  topnote(string) note(string) ];

tokenize `namelist';
if (`dste' == 1)                  local note1 = "[-] Standard errors are in italics.";
if (`dste' == 1 & "`xlan'"=="fr") local note1 = "[-] Les erreurs types sont en format italique.";
if (`dste' == 1 & "`xlan'"=="fr") local note1 = "[-] Les erreurs types sont en format italique.";


if (`dste' ==  1)    local frm = "SCCB0 N231`dec' N232`dec'";
if (`dste' !=  1)    local frm = "SCCB0 N230`dec'";

if (`dste' ==  1)  local lst1 = rowsof(`matn')-2 ;
if (`dste' ==  0)  local lst1 = rowsof(`matn')-1;

local lst1 `lst1' 2 ;

if (`dste' == -1)  {;
 local lst1 = "";
 };



xml_taba2 

`matn',
title("`xtit'")  
lines(COL_NAMES 14 `lst1' LAST_ROW 13)  
topnote(`topnote')
notes( "`note1'" ,  "`note'")
font("Courier New" 8)
format((S2111) (`frm')) 
 newappend save(`xfil') sheet(`xshe')


;
end;

