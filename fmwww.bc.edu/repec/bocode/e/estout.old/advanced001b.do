sysuse auto
quietly logit foreign mpg weight
eststo raw
eststo or
esttab raw or, se mtitles eform(0 1)
eststo clear
