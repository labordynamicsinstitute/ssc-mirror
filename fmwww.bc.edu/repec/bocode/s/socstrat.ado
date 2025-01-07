*! version 1.1 NS-SEC Full Construction
program define socstrat
    version 10.0
    syntax , socstatus(varlist min=2 max=2) generate(name) [float] version(str) strat(str) [nolabel]

    * Parse variable list
    local soc : word 1 of `socstatus'
    local status : word 2 of `socstatus'

    * Check if variables exist and are numeric
    foreach var in `soc' `status' {
        capture confirm numeric variable `var'
        if _rc {
            di as error "Variable `var' is missing or not numeric."
            exit
        }
    }
	
	if "`strat'" == "nssec" {
	
	*
	* define if
	marksample touse
	quietly count if `touse'
	if `r(N)'==0 {
		error 2000
	}
	* confirm 4-digit
	
	* recode SOC 90
	if "`version'" == "90" {
		if (`soc'>=100 & `soc'<=999) | (`soc'==.) {
			
			qui {
    * Define nssec based on specified variables
gen `generate' = .

foreach soc_code in 100 101 150 151 152 153 154 155 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 102 {
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3)
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 103 132 270 271 293 311 330 394 395 613 {
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 110 122 124 125 126 170 190 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 4)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 5, 6, 7)
}

foreach soc_code in 111 112 131 139 140 142 160 171 172 173 174 175 176 177 178 179 199 733 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 113 121 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 4)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 5, 6, 7)
}

foreach soc_code in 120 {
	replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3)
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}
	
foreach soc_code in 121 123 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 4)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 3, 5, 6, 7)
}

foreach soc_code in 127 130 239 302 310 345 381 386 410 411 412 420 421 430 450 451 452 459 490 491 523 526 529 592 598 640 641 650 790 864  {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 141 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 4)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 5, 6, 7)
}

foreach soc_code in 169 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 4)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 5, 6, 7)
}

foreach soc_code in 190 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 4)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 5, 6, 7)
}

foreach soc_code in 191 209 210 211 212 213 214 215 216 218 219 220 223 224 230 232 240 241 242 250 251 252 253 260 261 262 290 291 292 320 331 348 362 364 703 {
	replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 200 201 202 221 {
	replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 6, 7)
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 4)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 5)
}

foreach soc_code in 217 218 222 231 233 234 235 300 301 303 304 309 312 332 341 342 343 344 347 360 363 371 380 384 385 387 390 391 392 396 700 701 702 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 313 {
	replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 6)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
}

foreach soc_code in 340 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 3, 4, 5, 6, 7)
}

foreach soc_code in 346 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 4, 5)
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 6)
	replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 7)
}

foreach soc_code in 349 393 440 460 461 462 504 505 509 510 511 512 513 514 519 531 533 535 536 544 556 557 572 595 596 643 644 651 652 661 670 671 672 690 699 720 721 722 730 792 800 801 802 809 821 822 823 824 825 829 830 831 832 833 834 839 840 841 842 843 844 850 851 880 886 887 891 893 894 897 901 904 923 924 940 941 950 952 953 954 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 350 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 2)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 3)
	replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 361 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 2, 3, 5, 6, 7)
	replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 4)
}

foreach soc_code in 370 620 899 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 4, 5, 6)
	replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 7)
}

foreach soc_code in 382 383 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 4, 5, 6)
	replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 7)
}

foreach soc_code in 399 710  {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 4)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 2, 3, 5, 6, 7)
}

foreach soc_code in 400 401 600 601 610 611 612 642  {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 6)
	replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 7)
}

foreach soc_code in 441 931  {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 4, 5)
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 6)
	replace `generate' = 8 if `soc' == `soc_code' & inlist(`status', 7)
}

foreach soc_code in 463 515 516 517 518 520 521 522 524 525 532 540 541 542 543 560 561 563 569 573 580 593 594 599 631 810 820 826 860 861 869 870 871 881 882 883 884 890 892 898 922  {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 500 501 502 503 506 507 530 534 537 550 551 552 553 554 555 559 562 570 571 579 581 582 590 591 597 619 621 622 659 660 673 731 732 791 811 812 813 814 859 862 863 872 873 874 875 885 889 895 902 903 910 911 912 913 919 920 921 929 930 932 933 934 951 955 956 957 958 959 990 999  {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 8 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 615  {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 4, 5)
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 6)
	replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 7)
}

foreach soc_code in 630  {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 8 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 691  {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 4, 5)
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 6)
	replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 7)
}

foreach soc_code in 719  {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 2, 3, 4, 5, 6)
	replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 7)
}

foreach soc_code in 896 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 4, 5, 6)
	replace `generate' = 8 if `soc' == `soc_code' & inlist(`status', 7)
}

foreach soc_code in 900 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 6)
}
			}

	* Define and apply value labels for employment status
    if "`nolabel'" == "" {
    label define `generate'_nssec_lbl ///
        1 "1.1 Large employers and higher managerial and administrative occupations" ///
        2 "1.2 Higher professional occupations" ///
        3 "2 Lower managerial, administrative and professional occupations" ///
        4 "3 Intermediate occupations" ///
        5 "4 Small employers and own account workers" ///
        6 "5 Lower supervisory and technical occupations" ///
        7 "6 Semi-routine occupations" ///
		8 "7 Routine occupations"
    capture label values `generate' `generate'_nssec_lbl
}
			
		}
		
				else {
			di in red "`soc' is not a 3-digit SOC1990"
		}
	}
	
	* recode SOC 00
	else if "`version'" == "00" {
			if (`soc'>=1000 & `soc'<=9999) | (`soc'==.) {
				
				qui {
		
    * Define nssec based on specified variables
gen `generate' = .

foreach soc_code in 1111 1112 1171 1172 1173 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 1113 {
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3)
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 1114 1121 1123 1134 1135 1136 1212 1231 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 4)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 5, 6, 7)
}

foreach soc_code in 1122 1141 1142 1151 1152 1161 1162 1163 1174 1183 1185 1211 1219 1221 1222 1223 1224 1225 1226 1232 1233 1234 1235 1239 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 1131 {
	replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3)
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 1132 1133 1134 1135 1136 1212 1231 5111 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 4)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 5, 6, 7)
}

foreach soc_code in 1137 1182 {
	replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3)
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 4)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 5, 6, 7)
}

foreach soc_code in 1181 1184 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 4, 5, 6, 7)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
}

foreach soc_code in 2111 2112 2113 2121 2122 2123 2124 2125 2126 2129 2131 2132 2211 2212 2213 2215 2216 2311 2313 2317 2321 2322 2329 2411 2419 2421 2422 2423 2431 2432 2434 2443 2444 3223 3512 3532 3533 3535 3551 3568 {
	replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 2127 2128 2214 2312 2314 2315 2316 2433 3111 3113 3114 3119 3121 3131 3132 3211 3212 3214 3215 3221 3222 3229 3231 3232 3411 3412 3413 3414 3415 3416 3431 3432 3433 3441 3442 3513 3531 3534 3536 3537 3539 3541 3542 3543 3544 3562 3563 3564 3567 4114 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 2319 3112 3122 3216 3218 3421 3422 3434 3449 3520 3552 4121 4122 4123 4131 4132 4134 4135 4136 4150 4211 4212 4213 4214 4215 4217 5242 5245 5249 6111 6121 6214 6215 6212 7122 7125 7129 7211 7212 8138 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 3115 4142 5113 5119 5222 5223 5224 5231 5232 5233 5241 5243 5244 5314 5421 5422 5424 5432 5493 5494 5495 5499 8114 8123 8126 8133 8143 8216 8218 8219 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 2441 2442 2451 2452 3123 3319 3511 3561 3565 3566 4111 {
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 3213 3311 3312 3313 3314 4112 4113 6112 {
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 1, 2, 6)
	replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 2, 3, 4, 5, 7)
}

foreach soc_code in 3217 3443 4133 4137 4141 4216 5112 5212 5213 5221 5234 5311 5319 5414 5434 6113 6114 6115 6123 6124 6131 6211 6222 6231 6232 6291 6292 7111 7112 7113 7121 8111 8112 8115 8116 8117 8118 8119 8121 8124 8125 8129 8131 8132 8135 8136 8141 8142 8215 8217 8221 8222 8223 9111 9112 9113 9133 9211 9219 9221 9223 9241 9249 9251 9259 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 3514 {
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 5211 5214 5215 5216 5312 5313 5315 5316 5321 5322 5323 5411 5412 5413 5419 5423 5431 5433 5491 5492 5496 6122 6139 6213 6219 6221 7123 7124 8113 8122 8134 8137 8139 8149 8211 8212 8213 8214 8229 9119 9121 9129 9131 9132 9134 9139 9141 9149 9222 9224 9225 9226 9229 9231 9232 9233 9234 9235 9239 9234 9245 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 8 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 9243 9244 {
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 1, 2, 6)
	replace `generate' = 8 if `soc' == `soc_code' & inlist(`status', 2, 3, 4, 5, 7)
}

	* Define and apply value labels for employment status
    if "`nolabel'" == "" {
    label define `generate'_nssec_lbl ///
        1 "1.1 Large employers and higher managerial and administrative occupations" ///
        2 "1.2 Higher professional occupations" ///
        3 "2 Lower managerial, administrative and professional occupations" ///
        4 "3 Intermediate occupations" ///
        5 "4 Small employers and own account workers" ///
        6 "5 Lower supervisory and technical occupations" ///
        7 "6 Semi-routine occupations" ///
		8 "7 Routine occupations"
    capture label values `generate' `generate'_nssec_lbl
}
				
			}
			
			
			
					else {
			di in red "`soc' is not a 4-digit SOC2000"
		}
	}
	}
	

	
	* recode SOC 10
	else if "`version'" == "10" {
			if (`soc'>=1000 & `soc'<=9999) | (`soc'==.) {
				
				qui {
    * Define nssec based on specified variables
gen `generate' = .

foreach soc_code in 1115 1116 1171 1172 1173 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 1121 1123 1132 1133 1134 1135 1136 1139 1251 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 4)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 5, 6, 7)
}

foreach soc_code in 1122 1150 1161 1162 1190 1211 1213 1221 1223 1224 1225 1226 1241 1242 1252 1253 1254 1255 1259 4161 4217 5111 5436 6215 7220 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 1131 1181 1184 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 4, 5, 6, 7)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
}

foreach soc_code in 2111 2112 2113 2114 2119 2121 2122 2123 2124 2126 2129 2133 2134 2135 2136 2142 2150 2211 2212 2213 2215 2216 2223 2311 2317 2318 2412 2413 2419 2421 2423 2424 2425 2426 2431 2432 2434 2443 2444 2463 3512 3532 3533 3535 3545 {
	replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 2127 2137 2139 2141 2214 2217 2218 2219 2221 2222 2229 2231 2232 2312 2314 2315 2316 2429 2433 2435 2436 2449 2461 2462 2471 2472 2473 3111 3113 3114 3116 3119 3121 3131 3132 3219 3231 3233 3234 3235 3239 3219 3319 3411 3412 3413 3414 3415 3416 3441 3442 3513 3531 3534 3536 3537 3538 3539 3541 3542 3543 3544 3546 3562 3563 3564 3565 3567 4114 4124 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 2319 3112 3122 3216 3217 3218 3417 3421 3422 3520 3550 4135 4211 4212 4213 4214 4215 6121 6125 6141 6212 6214 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 3115 5119 5222 5223 5224 5231 5232 5235 5237 5241 5244 5314 5330 5421 5422 5423 5432 5434 5449 7214 8114 8123 8126 8133 8143 8233 8234 8239 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 2442 2451 2452 3511 3551 3561 4162 5250 7130 {
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 3213 3311 3312 3313 3314 4112 4113 6142 {
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 1, 2, 6)
	replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 3, 4, 5, 7)
}

foreach soc_code in 3315 {
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 1, 2, 6)
	replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 3, 4, 5, 7)
}

foreach soc_code in 3443 4216 5112 5113 5114 5414 5435 6123 6126 6131 6132 6143 6144 6146 6148 6211 6219 6222 7111 7112 7113 7114 7215 8111 8112 8115 8116 8117 8118 8119 8121 8124 8125 8127 8129 8131 8132 8135 8141 8142 8215 8221 8222 8223 8232 9111 9112 9211 9219 9241 9249 9271 9272 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 6)

}

foreach soc_code in 4121 4122 4123 4129 4131 4132 4134 4138 4151 4159 5242 5245 5249 7115 7122 7125 7129 7211 7219 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 4133 5212 5213 5221 5225 5234 5311 5319 6145 6231 6232 7121 7213 9251 9259 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 5211 5214 5215 5216 5236 5312 5313 5315 5316 5321 5322 5323 7123 7124 9231 9232 9233{
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 8 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 5411 5412 5413 5419 5433 5431 5441 5442 5443 6122 6139 6147 6221 8113 8122 8134 8137 8139 8149 8211 8212 8213 8214 8229 9119 9120 9132 9134 9139 9234 9235 9236 9239 9242 9244 9260 9273 9274 9275 9279 {
	replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
	replace `generate' = 8 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 6230 {
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3)
	replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 4, 5)
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 6, 7)
}

foreach soc_code in 6240 {
	replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3)
	replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 4, 5)
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 6, 7)
}

foreach soc_code in 8231 {
	replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}


				}

	* Define and apply value labels for employment status
    if "`nolabel'" == "" {
    label define `generate'_nssec_lbl ///
        1 "1.1 Large employers and higher managerial and administrative occupations" ///
        2 "1.2 Higher professional occupations" ///
        3 "2 Lower managerial, administrative and professional occupations" ///
        4 "3 Intermediate occupations" ///
        5 "4 Small employers and own account workers" ///
        6 "5 Lower supervisory and technical occupations" ///
        7 "6 Semi-routine occupations" ///
		8 "7 Routine occupations"
    capture label values `generate' `generate'_nssec_lbl
}
			}
					else  {
			di in red "`soc' is not a 4-digit SOC2010"
	}
	}
	
		* recode SOC 20
	else if "`version'" == "20" {
			if (`soc'>=1000 & `soc'<=9999) | (`soc'==.) {
				
				qui {
					
    * Define nssec based on specified variables
gen `generate' = .

foreach soc_code in 1111 {
    replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 5, 6, 7)
}

foreach soc_code in 1112 1116 1161 1162 1163  {
    replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 1171 1172  {
    replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 4, 5, 6, 7)
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
}

foreach soc_code in 1140 1211 1212 1222 1223 1224 1225 1231 1232 1233 1241 1242 1243 1252 1253 1254 1255 1256 1257 4141 4143 5111 5436 6250 {
    replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 1121 1122 1123 1131 1132 1133 1134 1135 1136 1137 1139 1150 1221 1251 1258 1259 {
    replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 4)
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 5, 6, 7)
}

foreach soc_code in 2111 2112 2113 2114 2115 2119 2121 2122 2123 2124 2127 2129 2131 2132 2133 2134 2135 2151 2152 2161 2162 2211 2212 2223 2224 2225 2226 2240 2253 2311 2321 2322 2323 2411 2412 2421 2422 2423 2431 2432 2433 2434 2439 2440 2451 2452 2453 2454 2462 2483 2491 2493 3531 3556  {
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 2125 2126 2136 2137 2139 2141 2142 2221 2222 2229 2231 2232 2233 2234 2235 2236 2237 2251 2252 2254 2256 2259 2312 2313 2314 2315 2316 2324 2329 2419 2435 2455 2463 2464 2469 2481 2482 2492 2494 3111 3113 3114 3120 3131 3132 3133 3221 3222 3223 3224 3229 3319 3411 3412 3413 3414 3415 3416 3431 3511 3512 3532 3533 3534 3541 3542 3543 3544 3549 3551 3552 3554 3555 3557 3571 3572 3573 3574 3581 3582 4124 {
    replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 2461 2471 2472 3311 3312 3313 3314 3560 4111 4112 4142 5250 7220 {
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 2317 2319 3112 3115 3116 3119 3211 3212 3213 3214 3219 3231 3232 3240 3417 3421 3422 3429 3432 3520 3553 4113 4121 4122 4123 4132 4134 4135 4152 4211 4212 4213 4214 4215 6111 6112 6131 6212 6213 6214 {
    replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 2255 3311 3312 3313 3314 4111 4112 6132 {
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 1, 2, 6)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 3, 4, 5, 7)
}

foreach soc_code in 3433 4133 4216 4217 5112 5413 5435 6113 6117 6121 6133 6134 6138 6211 6219 6222 7113 7114 7214 8120 8133 8151 8152 8159 8215 8221 8232 9111 9112 9219 9231 9262 {
    replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
    replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 4129 4131 4136 4151 4159 5234 5242 5244 5245 5246 5249 7115 7122 7125 7129 7211 7219 {
    replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 5113 5114 5119 5222 5223 5224 5231 5232 5236 5241 5243 5315 5421 5422 5432 5434 5449 6136 7213 8113 8132 8134 8143 8153 8233 8234 8239 {
    replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 5211 5221 5225 5233 5311 5319 6135 6231 6232 7111 7112 7121 7212 8114 8115 8135 8139 8141 8142 9241 9249 {
    replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
    replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 5212 5213 5214 5235 5312 5313 5314 5316 5317 5321 5322 5323 7123 7124 8111 8112 8119 8131 8146 9221 9222 9223 9229 9252 9253 9259 9263 9264 9265 9266 {
    replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
    replace `generate' = 8 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 5330 9261 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3)
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 5411 5412 5419 5423 5431 5433 5441 5442 5443 6114 6116 6129 6137 6221 6312 6321 8144 8145 8149 8211 8212 8213 8214 8219 8222 8229 9119 9121 9129 9131 9132 9139 9211 9224 9225 9226 9232 9233 9267 9269 {
    replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
    replace `generate' = 8 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 6240 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 4, 5)
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 6, 7)
}

foreach soc_code in 6311 {
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 6)
    replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
}

foreach soc_code in 7131 {
    replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1)
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 4, 5)
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 6)
    replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 7)
}

foreach soc_code in 7132 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 8160 8231 9251 {
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

					
				}
			}
			
	* Define and apply value labels for employment status
    if "`nolabel'" == "" {
    label define `generate'_nssec_lbl ///
        1 "1.1 Large employers and higher managerial and administrative occupations" ///
        2 "1.2 Higher professional occupations" ///
        3 "2 Lower managerial, administrative and professional occupations" ///
        4 "3 Intermediate occupations" ///
        5 "4 Small employers and own account workers" ///
        6 "5 Lower supervisory and technical occupations" ///
        7 "6 Semi-routine occupations" ///
		8 "7 Routine occupations"
    capture label values `generate' `generate'_nssec_lbl
}

	}
	
	
		else {
		di in red "No such SOC available"
	}

    * Display success message
    di in red "NS-SEC variable constructed successfully."
	}
	
		else if "`strat'" == "rgsc" {
			
	*
	* define if
	marksample touse
	quietly count if `touse'
	if `r(N)'==0 {
		error 2000
	}
	* confirm 4-digit
	
	* recode SOC 90
	if "`version'" == "90" {
		if (`soc'>=100 & `soc'<=999) | (`soc'==.) {
			
			qui {
    * Define rgsc based on specified variables
gen `generate' = .
			
foreach soc_code in 100 200 201 202 209 210 211 212 213 214 215 216 217 218 219 220 221 223 224 230 232 240 241 242 250 252 253 260 261 262 290 291 292 {
    replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 101 102 103 111 113 120 121 122 123 124 125 126 127 130 131 132 139 140 141 142 152 153 154 155 160 169 170 171 173 175 177 179 190 191 199 231 233 234 235 239 251 270 271 293 300 301 302 303 304 309 311 312 313 320 330 331 332 340 341 342 343 344 345 346 347 348 349 350 360 361 362 363 364 370 371 380 381 382 383 384 385 390 391 392 394 395 396 399 613 {
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 110 {
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 4, 5)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 112 {
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 3, 4)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 7)
}

foreach soc_code in 172 174 176 178 {
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 1, 2, 3)
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 4, 5)
}

foreach soc_code in 310 386 {
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 6, 7)
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 4, 5)
}

foreach soc_code in 387 710 719 791 {
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 7)
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 4, 5)
}

foreach soc_code in 393 {
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 2, 3, 7)
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 5)
}

foreach soc_code in 400 401 410 411 412 420 421 430 440 450 451 452 459 460 461 463 490 491 610 611 640 643 651 700 701 702 703 720 721 722 733 790 792 {
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 441 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 5, 6)
}

foreach soc_code in 462 {
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 5)
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 500 502 504 506 507 515 516 517 518 520 521 522 525 526 529 530 532 533 534 535 536 537 540 541 542 543 550 551 552 554 555 556 557 559 560 561 562 563 569 570 571 572 573 579 580 590 591 592 593 598 810 822 832 842 872 885 897 {
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 6, 7)
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 5)
}

foreach soc_code in 510 514 519 523 524 531 581 582 597 630 642 650 660 670 671 800 821 823 824 830 831 834 839 861 864 870 871 881 882 883 884 886 887 889 891 894 920 932 999 {
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 594 699 833 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 4, 5, 6)
}

foreach soc_code in 553 513 512 511 814 829 840 843 850 862 880 895 924 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 544 509 505 503 501 596 599 661 811 812 813 820 825 841 869 896 898 899 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 5, 6)
}
	
foreach soc_code in 595 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 612 614 {
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 6)
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 7)
}

foreach soc_code in 615 619 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 7)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 620 {
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 6, 7)
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 4, 5)
}

foreach soc_code in 621 622 659 844 851 859 860 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 3, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 631 {
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 7)
}

foreach soc_code in 641 644 672 802 826 863 890 893 910 922 940 950 951 953 {
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 7)
}

foreach soc_code in 652 913 954 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 673 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 4, 5)
}

foreach soc_code in 690 691 {
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 1, 2, 3)
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 4, 5)
}

foreach soc_code in 730 732 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 7)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 5)
}

foreach soc_code in 731 {
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 7)
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 4, 5)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 801 {
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 6, 7)
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 5)
}

foreach soc_code in 809 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 5, 6)
}

foreach soc_code in 873 874 {
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 7)
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 5)
}

foreach soc_code in 875 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 3, 7)
}

foreach soc_code in 892 {
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 5)
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 900 901 902 904 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 903 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 5, 6)
}

foreach soc_code in 911 912 {
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
    replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 7)
}

foreach soc_code in 919 {
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 7)
}

foreach soc_code in 921 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 2, 3, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 923 {
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 2, 3, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 929 930 {
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 931 956 958 {
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 5, 6)
}

foreach soc_code in 931 952 955 {
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 7)
}

foreach soc_code in 932 {
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 957 990 {
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 2, 3, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 959 {
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 4, 5, 6)
}
			
		}
		}

	* Define and apply value labels for employment status
    if "`nolabel'" == "" {
    label define `generate'_rgsc_lbl ///
        1 "1 Professional occupations" ///
        2 "2 Managerial and Technical occupations" ///
        3 "3NM Skilled Non-Manual occupations" ///
        4 "3M Skilled Manual occupations" ///
        5 "4 Partly-skilled occupations" ///
        6 "5 Unskilled occupations" ///
        7 "6 Armed Forces" 
    capture label values `generate' `generate'_rgsc_lbl
}

    * Display success message
    di in red "RGSC variable constructed successfully."

				else {
			di in red "`soc' is not a 3-digit SOC1990"
		}

	}
	
	* recode SOC 00
	else if "`version'" == "00" {
			if (`soc'>=1000 & `soc'<=9999) | (`soc'==.) {
				
				qui {
		
    * Define rgsc based on specified variables
gen `generate' = .

foreach soc_code in 1111 2111 2112 2113 2121 2122 2123 2124 2125 2126 2127 2128 2129 2211 2212 2213 2214 2215 2216 2311 2313 2317 2321 2322 2329 2411 2419 2421 2423 2431 2432 2434 2444 3551 {
    replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 1112 1113 1114 1122 1123 1131 1132 1133 1134 1135 1136 1137 1141 1142 1151 1152 1161 1162 1163 1172 1173 1174 1181 1182 1183 1184 1185 1211 1212 1219 1221 1222 1223 1224 1225 1226 1231 1232 1233 1234 1235 1239 2131 2132 2312 2314 2315 2316 2319 2422 2433 2441 2442 2443 2451 2452 3111 3112 3113 3114 3115 3119 3121 3123 3131 3132 3211 3212 3214 3215 3216 3217 3218 3221 3222 3223 3229 3231 3232 3411 3412 3413 3414 3415 3416 3421 3422 3431 3432 3433 3443 3511 3512 3513 3514 3520 3531 3532 3533 3534 3535 3536 3537 3539 3541 3543 3544 3561 3562 3563 3564 3565 3566 3567 3568 4111 4114 4121 6111 6113 6114 6131 {
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 1121 {
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 6, 7)
}

foreach soc_code in 1171 3311 {
    replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 3122 3312 3313 3314 3434 3441 3442 3449 3542 4112 4113 4122 4123 4131 4132 4133 4134 4135 4136 4137 4142 4150 4211 4212 4213 4215 4216 4217 5496 7111 7112 7113 7122 7125 7129 7211 7212 8215 9219 {
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 3213 5211 5212 5213 5214 5215 5216 5221 5222 5223 5224 5231 5232 5233 5234 5241 5242 5243 5244 5245 5249 5311 5312 5314 5315 5319 5321 5322 5323 5411 5412 5413 5414 5419 5421 5422 5423 5424 5432 5434 5491 5492 5493 5494 5495 6112 6121 6213 6214 6215 6231 6291 6292 7123 8112 8115 8117 8118 8121 8122 8136 8138 8211 8212 8213 8214 8216 8219 8221 8222 8229 9133 {
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 3319 3552 4141 7121 7124 9241 9242 9243 9249 9251 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 7)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 5113 5119 5313 5316 5499 6122 6123 6124 6139 6211 6219 6232 8111 8113 8114 8116 8119 8123 8124 8125 8129 8131 8132 8133 8134 8135 8137 8139 8141 8143 8149 8217 8223 9111 9112 9119 9134 9149 9211 9221 9222 9223 9224 9225 9226 9229 9234 9235 9239 9259 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 4214 6212 {
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 5111 5431 5433 6221 {
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 5112 {
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3)
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 6115 6222 9244 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 8126 8142 8218 9121 9129 9131 9132 9139 9141 9231 9232 9233 9245 {
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
}

		}
			}
	* Define and apply value labels for employment status
    if "`nolabel'" == "" {
    label define `generate'_rgsc_lbl ///
        1 "1 Professional occupations" ///
        2 "2 Managerial and Technical occupations" ///
        3 "3NM Skilled Non-Manual occupations" ///
        4 "3M Skilled Manual occupations" ///
        5 "4 Partly-skilled occupations" ///
        6 "5 Unskilled occupations" ///
        7 "6 Armed Forces" 

    capture label values `generate' `generate'_rgsc_lbl
}

    * Display success message
    di in red "RGSC variable constructed successfully."

				else {
			di in red "`soc' is not a 4-digit SOC2000"
		}

	}
	
	* recode SOC 10
	else if "`version'" == "10" {
			if (`soc'>=1000 & `soc'<=9999) | (`soc'==.) {
				
				qui {
		
    * Define rgsc based on specified variables
gen `generate' = .

foreach soc_code in 1115 1116 1122 1123 1131 1132 1133 1134 1135 1136 1139 1150 1161 1162 1172 1173 1181 1184 1190 1211 1213 1221 1223 1224 1225 1226 1241 1242 1251 1252 1253 1254 1255 1259 2133 2134 2135 2136 2137 2139 2150 2217 2218 2219 2221 2222 2223 2229 2231 2232 2312 2314 2315 2316 2319 2424 2429 2433 2435 2436 2442 2443 2449 2451 2452 2462 2463 2471 2472 2473 3111 3112 3113 3114 3115 3119 3121 3131 3132 3216 3217 3218 3219 3231 3233 3234 3235 3239 3411 3412 3413 3414 3415 3416 3421 3422 3443 3511 3512 3513 3520 3531 3532 3533 3534 3535 3536 3537 3538 3539 3541 3543 3545 3546 3561 3562 3563 3564 3565 3567 4114 4121 4138 4161 5436 6131 6141 6143 6144  {
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 1121 3544 7220 {
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 6, 7)
}

foreach soc_code in 4214 6212 {
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 1171 3311 {
    replace `generate' = 7 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 2111 2112 2113 2114 2119 2121 2122 2123 2124 2126 2127 2129 2141 2142 2211 2212 2213 2214 2215 2216 2311 2317 2318 2412 2413 2419 2421 2423 2425 2426 2431 2432 2434 2444 2461 3116 {
    replace `generate' = 1 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 3122 3312 3313 3314 3417 3441 3442 3542 4112 4113 4122 4123 4124 4129 4131 4132 4133 4134 4135 4151 4159 4162 4211 4212 4213 4215 4216 4217 5443 7111 7112 7113 7114 7115 7122 7125 7129 7130 7211 7214 7215 7219 8215 9219 {
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 3213 5211 5212 5213 5214 5215 5216 5221 5222 5223 5224 5225 5231 5232 5234 5235 5236 5237 5241 5242 5244 5245 5249 5250 5311 5312 5314 5315 5319 5321 5322 5323 5330 5411 5412 5413 5414 5419 5421 5422 5423 5424 5432 5434 5435 5441 5442 6121 6132 6142 6147 6214 6215 6219 6231 7123 8112 8115 8117 8118 8121 8122 8127 8211 8212 8213 8214 8221 8222 8229 8231 8234 8239  {
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 3315 3550 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 7)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 3319 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 7)
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 4, 5)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 5112 {
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3)
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 4, 5, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 5113 5114 5119 5449 6122 6123 6125 6126 6139 6146 6211 6222 8111 8113 8114 8116 8119 8123 8124 8125 8129 8131 8132 8133 8134 8135 8137 8139 8141 8143 8149 8223 8232 9111 9112 9119 9134 9211 9234 9244 9271 9272 9273 9274 9275 9279 9260 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 5313 5316 6145 6232 7121 7124 7213 9239 9251 9259 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 6132 6148 {
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 6, 7)
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 4, 5)
}

foreach soc_code in 9241 9249 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 7)
    replace `generate' = 3 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 5111 5431 5433 6221 {
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 1, 2, 3)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 4, 5, 6, 7)
}

foreach soc_code in 6240 {
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 6, 7)
    replace `generate' = 2 if `soc' == `soc_code' & inlist(`status', 4, 5)
}

foreach soc_code in 8126 8142 8233 9120 9132 9139 9236 9242 {
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
}

foreach soc_code in 9231 9232 9233 {
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 1, 2, 3, 4, 5, 6, 7)
}

foreach soc_code in 9235 {
    replace `generate' = 5 if `soc' == `soc_code' & inlist(`status', 1, 2)
    replace `generate' = 6 if `soc' == `soc_code' & inlist(`status', 3, 4, 5, 7)
    replace `generate' = 4 if `soc' == `soc_code' & inlist(`status', 6)
}



		}
			}
	* Define and apply value labels for employment status
    if "`nolabel'" == "" {
    label define `generate'_rgsc_lbl ///
        1 "1 Professional occupations" ///
        2 "2 Managerial and Technical occupations" ///
        3 "3NM Skilled Non-Manual occupations" ///
        4 "3M Skilled Manual occupations" ///
        5 "4 Partly-skilled occupations" ///
        6 "5 Unskilled occupations" ///
        7 "6 Armed Forces" 

    capture label values `generate' `generate'_rgsc_lbl
}

    * Display success message
    di in red "RGSC variable constructed successfully."

				else {
			di in red "`soc' is not a 4-digit SOC2010"
		}

	}
	
	* recode SOC 00
	else if "`version'" == "20" {
		di in red "SOC 2020 Version not Availible for RGSC"
	}
	
					else {
		di in red "No such SOC available"
	}
	}
	
end
