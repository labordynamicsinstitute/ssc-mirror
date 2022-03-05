*!  defaxislab.ado 	Version 1.0		RL Kaufman 	09/29/2016

***  	1.0 Create 3-5 rounded label values.  Called by BARYHAT, SCATYHAT, CONTYHAT
***

program defaxislab, rclass
version 14.2
args vmin vmax ninc
qui {
loc yy = abs(`vmax')
loc ylabmax = 0
if `yy' > 0 {
	loc p10 = int(log10(`yy'))-1-1
	loc ylabmax = round(`yy'+.5*(10^(`p10')),10^(`p10'+1))*sign(`vmax')
	if `yy' < 1 {
		loc pyy=int(log10(`yy'))*2
		loc y1=`yy'*(10^(-`pyy'+1))
		loc p10=int(log10(`y1'))-1-1
		loc y2 =round(`y1'+ .5*(10^(`p10')),10^(`p10'+1))*sign(`vmax')
		loc ylabmax= `y2'*(10^(`pyy'-1))
	}
}
loc yy = abs(`vmin')
loc ylabmin = 0
if `yy' > 0 {
	loc p10 = int(log10(`yy'))-1-1
	loc ylabmin = round(`yy'+.5*(10^(`p10')),10^(`p10'+1))*sign(`vmin')
	if `yy' < 1 {
		loc pyy=int(log10(`yy'))*2
		loc y1=`yy'*(10^(-`pyy'+1))
		loc p10=int(log10(`y1'))-1-1
		loc y2 =round(`y1'+ .5*(10^(`p10')),10^(`p10'+1))*sign(`vmin')
		loc ylabmin= `y2'*(10^(`pyy'-1))
	}
}

loc yy = (`ylabmax' - `ylabmin')/`ninc' 
loc p10 = int(log10(`yy'))-1-1
loc ylabinc = round(`yy',10^(`p10'+1))
if `yy' < 1 {
	loc pyy=int(log10(`yy'))*2
	loc y1=`yy'*(10^(-`pyy'+1))
	loc p10=int(log10(`y1'))-1-1
	loc y2 =round(`y1'+ .5*(10^(`p10')),10^(`p10'+1))
	loc ylabinc= `y2'*(10^(`pyy'-1))
}
loc ylabmax2 = `ninc'*`ylabinc'+`ylabmin' 
if (`ylabmax2' - `vmax')/`ylabinc' > .5 {
	loc ylabmax= `vmax'  
	loc yy = (`ylabmax' - `ylabmin')/`=`ninc'+1' 
	loc p10 = int(log10(`yy'))-1-1
	loc ylabinc = round(`yy',10^(`p10'+1))
	if `yy' < 1 {
		loc pyy=int(log10(`yy'))*2
		loc y1=`yy'*(10^(-`pyy'+1))
		loc p10=int(log10(`y1'))-1-1
		loc y2 =round(`y1'+ .5*(10^(`p10')),10^(`p10'+1))
		loc ylabinc= `y2'*(10^(`pyy'-1))
	}
loc ylabmax2 = `=`ninc'+1'*`ylabinc'+`ylabmin' 
}
if (`ylabmax2' - `ylabmax')/`ylabinc' < -.5 loc ylabmax2 = `ninc'*`ylabinc'+`ylabmin' 
}
loc labvals "`ylabmin'(`ylabinc')`ylabmax2'"
return loc labvals = "`labvals'"
end
