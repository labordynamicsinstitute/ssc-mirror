*! version 1.0.0  31may2017
program define covfefe
	version 13
	
	tempfile drivel
	cap copy "https://twitter.com/realDonaldTrump" `drivel'
	if (_rc==631) {
		di as error "Despite the constant negative press you don't seem to be connected to the internet."
		exit 631
	}
	else if (_rc!=0) error _rc
	
	tempname tweets
	file open `tweets' using `drivel', text read
	
	file read `tweets' line
	while r(eof)==0 {
		if strtrim(`"`line'"')==`"<div class="js-tweet-text-container">"'{
			continue, break
		}
	
		file read `tweets' line
	}
	file read `tweets' line
	
	local foundtweet=regexm(strtrim(`"`line'"'),"^<p.*>(.*)<\/p>$")
	if `foundtweet'==1 {
		di `"Despite the constant negative press `=regexs(1)'"'
	}
	else {
		di as error "Despite the constant negative press, error parsing tweets"
		exit 2
	}
		
end
