sysuse auto
eststo: quietly regress price mpg i.foreign
eststo: quietly regress price c.mpg##i.foreign
esttab, varwidth(25)
esttab, varwidth(25) label
esttab, varwidth(25) label nobaselevels interaction(" X ")
eststo clear
