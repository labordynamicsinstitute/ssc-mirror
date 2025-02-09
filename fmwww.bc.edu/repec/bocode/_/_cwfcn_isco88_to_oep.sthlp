{smcl}
{* version 1.0.0  06feb2025  Ben Jann}{...}
{hi:isco88_to_oep()} {hline 2} Translate 4-digit ISCO-88 to OEP scores

{title:Syntax}

        {cmd:isco88_to_oep(}{varname}{cmd:)}

{pstd}
    where {it:varname} contains 4-digit ISCO-88 codes.

{title:Description}

{pstd}
    {helpb crosswalk} table translating 4-digit ISCO-88 codes to OEP scores
    (Occupational Earning Potential; Oesch et al. 2024).

{title:Source}

{pstd}
    File {bf:isco88-4_to_oep.xlsx} provided by Oesch (2025), supplemented (where
    possible) by 4-digit variants of the mappings in {bf:isco88-3_to_oep.xlsx},
    {bf:isco88-2_to_oep.xlsx}, and {bf:isco88-1_to_oep.xlsx} .

{title:References}

{phang}
    Oesch, Daniel, Oliver Lipps, Roujman Shahbazian, Erik Bihagen,
    Katy Morris. 2024. Occupational Earning Potential. A new measure of social
    hierarchy applied to Europe. European Commission, Seville,
    {browse "https://publications.jrc.ec.europa.eu/repository/handle/JRC139883":JRC139883}.
    {p_end}
{phang}
    Oesch, Daniel, Oliver Lipps, Roujman Shahbazian, Erik Bihagen,
    Katy Morris. 2025. Occupational Earning Potential (OEP) Scale. OSF,
    DOI:{browse "https://doi.org/10.17605/OSF.IO/PR89U":10.17605/OSF.IO/PR89U}. 
    {p_end}
{hline}
{asis}
0000 69
0100 63
0110 71
1000 78
1100 81
1110 90
1120 83
1130 94
1140 79
1141 79
1142 79
1143 76
1200 81
1210 93
1220 75
1221 67
1222 76
1223 72
1224 61
1225 31
1226 64
1227 87
1228 56
1229 78
1230 85
1231 87
1232 84
1233 85
1234 81
1235 77
1236 90
1237 91
1239 84
1300 55
1310 49
1311 49
1312 64
1313 67
1314 47
1315 38
1316 55
1317 68
1318 46
1319 61
2000 73
2100 80
2110 78
2111 79
2112 73
2113 79
2114 77
2120 84
2121 91
2122 70
2130 80
2131 78
2132 73
2139 77
2140 80
2141 71
2142 80
2143 84
2144 82
2145 81
2146 81
2147 86
2148 71
2149 80
2200 78
2210 70
2211 70
2212 78
2213 70
2220 88
2221 93
2222 79
2223 79
2224 78
2229 59
2230 55
2300 65
2310 77
2320 68
2330 57
2331 58
2332 38
2340 65
2350 61
2351 65
2352 74
2359 56
2400 71
2410 75
2411 79
2412 62
2419 78
2420 87
2421 90
2422 92
2429 78
2430 51
2431 52
2432 50
2440 58
2441 84
2442 64
2443 69
2444 53
2445 67
2446 54
2450 65
2451 68
2452 46
2453 60
2454 35
2455 58
2460 61
2470 70
3000 55
3100 62
3110 62
3111 54
3112 64
3113 72
3114 66
3115 67
3116 72
3117 82
3118 50
3119 63
3120 67
3121 71
3122 54
3130 53
3131 43
3132 45
3133 58
3139 53
3140 85
3141 75
3142 65
3143 91
3144 82
3145 83
3150 53
3151 58
3152 53
3200 46
3210 49
3211 49
3212 53
3213 49
3220 40
3221 43
3222 55
3223 42
3224 37
3225 29
3226 46
3227 26
3228 31
3229 43
3230 42
3231 42
3232 56
3240 19
3241 19
3300 43
3320 32
3330 41
3340 47
3400 55
3410 63
3411 90
3412 66
3413 66
3414 51
3415 67
3416 64
3417 61
3418 63
3419 59
3420 57
3421 72
3422 49
3423 56
3429 59
3430 52
3431 45
3432 50
3433 59
3434 61
3439 68
3440 56
3441 60
3442 58
3443 46
3444 65
3449 54
3450 71
3460 39
3470 49
3471 49
3472 54
3473 26
3474 22
3475 48
3480 44
4000 37
4100 38
4110 34
4111 35
4112 33
4113 24
4115 35
4120 46
4121 39
4122 52
4130 38
4131 31
4132 49
4133 46
4140 35
4141 33
4142 37
4143 40
4144 35
4190 35
4200 34
4210 36
4211 32
4212 31
4213 34
4214 49
4215 36
4220 25
4221 28
4222 24
4223 29
5000 21
5100 22
5110 41
5111 43
5112 45
5113 18
5120 17
5121 20
5122 21
5123 12
5130 18
5131 13
5132 20
5133 17
5139 22
5140 16
5141 13
5142 7
5143 39
5149 23
5150 47
5152 47
5160 57
5161 64
5162 67
5163 52
5169 40
5200 21
5210 24
5220 21
5230 14
6000 21
6100 21
6110 22
6111 24
6112 20
6113 21
6114 22
6120 16
6121 20
6122 26
6123 16
6124 8
6129 13
6130 24
6140 32
6141 32
6150 33
6151 42
6152 41
6153 29
6154 30
6200 21
6210 21
7000 44
7100 44
7110 53
7111 57
7112 70
7113 34
7120 42
7121 34
7122 46
7123 41
7124 38
7129 44
7130 48
7131 38
7132 34
7133 32
7134 41
7135 41
7136 51
7137 53
7139 31
7140 34
7141 35
7142 35
7143 32
7200 49
7210 42
7211 35
7212 40
7213 44
7214 45
7215 42
7216 56
7220 48
7221 42
7222 54
7223 46
7224 41
7230 49
7231 41
7232 59
7233 53
7240 52
7241 53
7242 50
7243 52
7244 49
7245 59
7300 40
7310 40
7311 41
7312 32
7313 26
7320 30
7321 41
7322 32
7323 28
7324 28
7330 24
7331 32
7332 17
7340 44
7341 45
7343 52
7344 44
7345 38
7346 35
7400 27
7410 25
7411 27
7412 22
7413 35
7414 28
7415 44
7416 17
7420 34
7421 41
7422 32
7423 35
7424 21
7430 22
7431 22
7432 30
7433 16
7434 20
7435 26
7436 19
7437 30
7440 21
7441 30
7442 20
8000 38
8100 50
8110 72
8111 72
8112 75
8113 67
8120 46
8121 61
8122 53
8123 58
8124 47
8130 30
8131 25
8139 31
8140 39
8141 32
8142 75
8143 55
8150 54
8151 54
8152 54
8155 47
8159 58
8160 57
8161 65
8162 52
8163 52
8170 52
8200 31
8210 44
8211 41
8212 49
8220 40
8221 46
8222 53
8223 35
8224 25
8229 30
8230 32
8231 33
8232 31
8240 33
8250 37
8251 51
8252 39
8253 35
8260 15
8261 30
8262 30
8263 15
8264 15
8265 15
8266 17
8269 35
8270 28
8271 24
8272 36
8273 47
8274 29
8275 28
8276 39
8277 49
8278 43
8279 45
8280 32
8281 41
8282 27
8283 31
8284 27
8285 37
8286 28
8290 28
8300 39
8310 65
8311 69
8312 58
8320 37
8321 49
8322 26
8323 38
8324 40
8330 39
8331 37
8332 46
8333 51
8334 32
8340 52
9000 21
9100 18
9110 20
9111 11
9112 20
9113 21
9120 17
9130 11
9131 12
9132 11
9133 14
9140 29
9141 30
9142 17
9150 25
9151 24
9152 22
9153 27
9160 26
9161 29
9162 23
9200 14
9210 14
9211 15
9212 14
9213 14
9300 26
9310 34
9311 49
9312 40
9313 28
9320 21
9321 21
9322 18
9330 32
9331 52
9332 50
9333 33
