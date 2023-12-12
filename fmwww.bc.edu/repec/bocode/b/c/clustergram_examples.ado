

cap program drop clustergram_examples
program define clustergram_examples
	version 17
	if ("`1'" == "iris1"){
		clustergram_iris1
	}
	else if ("`1'" == "iris2"){
		clustergram_iris2
	}
	else if ("`1'" == "iris3"){
		clustergram_iris3
	}
	else if ("`1'" == "wclub"){
		clustergram_wclub
	}
end

///////////////////////////////////////////////////////////////////////////
program clustergram_iris1 
	version 17

	set scheme s1color
	use https://www.stata-press.com/data/r17/iris, clear
	set seed 10
	local max=5
	foreach i of numlist 1/`max' {
		cluster kmeans seplen-petwid , k(`i') L2 name("cluster`i'")
	}
	clustergram seplen-petwid, cluster(cluster1-cluster`max')  
end 

///////////////////////////////////////////////////////////////////////////
program clustergram_iris2 
	version 17

	set scheme s1color
	use https://www.stata-press.com/data/r17/iris, clear
	set seed 10
	local max=5
	foreach i of numlist 1/`max' {
		cluster kmeans seplen-petwid , k(`i') L2 name("cluster`i'")
	}
	clustergram seplen-petwid, cluster(cluster1-cluster`max') color(blue%50) fra(.1) 
end 
///////////////////////////////////////////////////////////////////////////
program clustergram_iris3
	version 17

	set scheme s1color
	use https://www.stata-press.com/data/r17/iris, clear
	set seed 10
	local max=5
	foreach i of numlist 1/`max' {
		cluster kmeans seplen-petwid , k(`i') L2 name("cluster`i'")
	}
	clustergram petlen, cluster(cluster1-cluster`max') ytitle("Average Petal Length")
end 
///////////////////////////////////////////////////////////////////////////
program clustergram_wclub 
	version 17

	set scheme s1color
	use https://www.stata-press.com/data/r17/wclub.dta, clear
	set seed 10
	local max=5
	foreach i of numlist 1/`max' {
		cluster kmeans bike-fish, k(`i') L2 name("cluster`i'")
	}
	clustergram fict, cluster(cluster1-cluster`max') ytitle(Av. Fiction Books)
end 
///////////////////////////////////////////////////////////////////////////
