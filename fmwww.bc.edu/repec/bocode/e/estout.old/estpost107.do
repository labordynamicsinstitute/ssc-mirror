webuse cure2
gen noise = uniform()>.5
estpost prtest cure noise, by(sex)
esttab, cell("b se0 z p") nomtitle nonumber
