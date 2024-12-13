************************************
*!Author: Zumin Shi
*!Contact: zumin.shi@gmail.com
*!Date: 12 December 2024
*!Version: 2.00
************************************

********************************************************************
*The program download data from NHANES website
*the basic syntax is getnhs year filename
*example getnhs 2001 MCQ
*it will download MCQ data (medical history questionnaire data)
*********************************************************************

capture program drop getnhs
program getnhs      //Version of getnhs.ado
version 16      //stata version 16
*syntax args first second  

if `1'==1999 | `1'==2000 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/1999/DataFiles/"
if `1'==1999 | `1'==2000 local cycle ""

if `1'==2001 | `1'==2002 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2001/DataFiles/"
if `1'==2001 | `1'==2002 local cycle "_B"

if `1'==2003 | `1'==2004 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2003/DataFiles/"
if `1'==2003 | `1'==2004 local cycle "_C"

if `1'==2005 | `1'==2006 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2005/DataFiles/"
if `1'==2005 | `1'==2006 local cycle "_D"

if `1'==2007 | `1'==2008 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2007/DataFiles/"
if `1'==2007 | `1'==2008 local cycle "_E"

if `1'==2009 | `1'==2010 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2009/DataFiles/"
if `1'==2009 | `1'==2010 local cycle "_F"

if `1'==2011 | `1'==2012 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2011/DataFiles/"
if `1'==2011 | `1'==2012 local cycle "_G"

if `1'==2013 | `1'==2014 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2013/DataFiles/"
if `1'==2013 | `1'==2014 local cycle "_H"

if `1'==2015 | `1'==2016 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2015/DataFiles/"
if `1'==2015 | `1'==2016 local cycle "_I"

if `1'==2017 | `1'==2018 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/"
if `1'==2017 | `1'==2018 local cycle "_J"

if `1'==2019 | `1'==2020 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/"
if `1'==2019 | `1'==2020 local cycle ""

if `1'==2021 | `1'==2022 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/"
if `1'==2021 | `1'==2022 local cycle "_L"

if `1'==2023 | `1'==2024 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2023/DataFiles/"
if `1'==2023 | `1'==2024 local cycle "_M"

if `1'==2025 | `1'==2026 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2025/DataFiles/"
if `1'==2025 | `1'==2026 local cycle "_N"

if `1'==2027 | `1'==2028 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2027/DataFiles/"
if `1'==2027 | `1'==2028 local cycle "_O"

if `1'==2029 | `1'==2030 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2029/DataFiles/"
if `1'==2029 | `1'==2030 local cycle "_P"

if `1'==2031 | `1'==2032 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2031/DataFiles/"
if `1'==2031 | `1'==2032 local cycle "_Q"

if `1'==2033 | `1'==2034 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2033/DataFiles/"
if `1'==2033 | `1'==2034 local cycle "_R"

if `1'==2035 | `1'==2036 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2035/DataFiles/"
if `1'==2035 | `1'==2036 local cycle "_S"

if `1'==2037 | `1'==2038 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2037/DataFiles/"
if `1'==2037 | `1'==2038 local cycle "_T"

if `1'==2039 | `1'==2040 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2039/DataFiles/"
if `1'==2039 | `1'==2040 local cycle "_U"

if `1'==2041 | `1'==2042 local path "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2041/DataFiles/"
if `1'==2041 | `1'==2042 local cycle "_U"


import sasxport5  `path'`2'`cycle'.XPT
sort seqn
compress
cap erase `2'`cycle'.dta
save `2'`cycle'
end
