
set more off 
capt prog drop _all
mata: mata clear
clear all

*! freduse update to read 2024 HTML format data from FRED
*! CFB 16aug2024

prog fredusex, rclass
version 16
syntax anything(name=slist id="Series list"), data(string) [REPLACE]
capt confirm new file `data'.dta
if _rc > 0 {
	if "`replace'"=="replace" {
		rm `data'.dta
	}
}
capt confirm new file `data'.dta
if _rc > 0 {
	di as err  "File `data'.dta exists." 
	exit 498
	}
loc ns: word count `slist'
loc i 0
foreach s of loc slist {
	loc i=`i'+1
	tempname fred`i'
	frame create `fred`i''
	cwf `fred`i''
	loc sname: word `i' of `slist' 
	loc fname=upper("`sname'")
	loc fn https://fred.stlouisfed.org/data/`fname'
	qui set obs 5000
	qui g str10 daten = ""
// double required to capture all digits
	qui g double vals = .
	mata: grabd("`fn'")
	qui drop if daten==""
	rename vals `fname'
	tempfile ffred`i'
	qui save `ffred`i'', replace
}
// all series processed, now merge
use `ffred1'
if `ns' > 1 {
	forv i=2/`ns' {
		qui merge 1:1 daten using `ffred`i''
		drop _merge
	}
}
g date = date(daten,"YMD")
format date %td
g qdate = qofd(date)
format qdate %tq
g mdate = mofd(date)
format mdate %tm
sort date
order daten date qdate mdate
qui save `data', replace
di _n "`ns' series written to `data'.dta" 
end

mata:
void grabd(
	string scalar filename)
{
	string scalar ti
	st_sview(dates,.,"daten")
	st_view(values,.,"vals")
	fh=fopen(filename, "r")
	nelt = 0
	want = 0
	while ((line=fget(fh))!=J(0,0,"")) {
		if (strpos(subinstr(line,`"""',"'"),"<th scope='row'>Title")) ti=fget(fh)
		if (strpos(subinstr(line,`"""',"'"),"<th scope='row'>Series ID")) id=fget(fh)
		if (strpos(subinstr(line,`"""',"'"),"<th scope='row'>Source")) so=fget(fh)
		if (strpos(subinstr(line,`"""',"'"),"<th scope='row'>Release")) rl=fget(fh)
		if (strpos(subinstr(line,`"""',"'"),"<th scope='row'>Seasonal Adjustment")) sa=fget(fh)
		if (strpos(subinstr(line,`"""',"'"),"<th scope='row'>Frequency")) fq=fget(fh)
		if (strpos(subinstr(line,`"""',"'"),"<th scope='row'>Units")) un=fget(fh)
		if (strpos(subinstr(line,`"""',"'"),"<th scope='row'>Date Range")) dr=fget(fh)
		if (strpos(subinstr(line,`"""',"'"),"<th scope='row'>Last Updated")) lu=fget(fh)

		if (strpos(line,"VALUE")) want = 1
		if(want) {
				dtp=strpos(line,"<th scope=")
				vlp=strpos(line,"<td class=")
				if (dtp>0) {
					date=substr(line,dtp+29,10)
					nelt=nelt+1
					dates[nelt] = date
				}
				if (vlp>0) {
					vvl = substr(line,vlp+15,20)
					la=strpos(vvl,">")
					ra=strpos(vvl,"<")
					len=ra-la-1
					val = substr(vvl,la+1,len)
					values[nelt] = strtoreal(val)
				}
		}
	}
	fclose(fh)
	
	title=regexr(ti,"<td>","")
	title=strltrim(regexr(title,"</td>",""))
	sid=regexr(id,"<td>","")
	sid=strltrim(regexr(sid,"</td>",""))
	source=regexr(so,"<td>","")
	source=strltrim(regexr(source,"</td>",""))
	release=regexr(rl,"<td>","")
	release=strltrim(regexr(release,"</td>",""))	
	seasonal_adjustment=regexr(sa,"<td>","")
	seasonal_adjustment=strltrim(regexr(seasonal_adjustment,"</td>",""))
	frequency=regexr(fq,"<td>","")
	frequency=strltrim(regexr(frequency,"</td>",""))	
	units=regexr(un,"<td>","")
	units=strltrim(regexr(units,"</td>",""))
	date_range=regexr(dr,"<td>","")
	date_range=strltrim(regexr(date_range,"</td>",""))	
	last_updated=regexr(lu,"<td>","")
	last_updated=strltrim(regexr(last_updated,"</td>",""))
	" "
	printf("Title: %s\n",title)
	printf("Series ID: %s\n",sid)
	printf("Source: %s\n",source)
	printf("Release: %s\n",release)
	printf("Seasonal Adjustment: %s\n",seasonal_adjustment)
	printf("Frequency: %s\n",frequency)
	printf("Units: %s\n", units)
	printf("Date Range: %s\n",date_range)
	printf("Last Updated: %s\n",last_updated)
}
end



