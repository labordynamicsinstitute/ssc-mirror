* chesspuzzle
* Version 1.1
* 06/12/2022
* Dominik Flügel

program define chesspuzzle
version 14


* Load Puzzles
local puzzle1 = "Henry_Buckle                NN                            London                      1840  r2qkb1r/pp2nppp/3p4/2pNN1B1/2BnP3/3P4/PPP2PPP/R2bK2R       White      Nf6+       gxf6       Bxf7#      Knight     Pawn       Bishop     "
local puzzle2 = "Louis_Paulsen               Blachy                        New_York                    1857  1rb4r/pkPp3p/1b1P3n/1Q6/N3Pp2/8/P1P3PP/7K                  White      Qd5+       Ka6        cxb8=N#    Queen      King       Pawn       "
local puzzle3 = "Paul_Morphy                 Duke_Isouard                  Paris                       1858  4kb1r/p2n1ppp/4q3/4p1B1/4P3/1Q6/PPP2PPP/2KR4               White      Qb8+       Nxb8       Rd8#       Queen      Knight     Rook       "
local puzzle4 = "Johannes_Zukertort          Adolf_Anderssen               Breslau                     1865  r1b2k1r/ppp1bppp/8/1B1Q4/5q2/2P5/PPP2PPP/R3R1K1            White      Qd8+       Bxd8       Re8#       Queen      Bishop     Rook       "
local puzzle5 = "Gustav_Neumann              Carl_Mayet                    Berlin                      1866  5rkr/pp2Rp2/1b1p1Pb1/3P2Q1/2n3P1/2p5/P4P2/4R1K1            White      Qxg6+      fxg6       Rg7#       Queen      Pawn       Rook       "
local puzzle6 = "Joseph_Blackburne           Martin                        England                     1876  1r1kr3/Nbppn1pp/1b6/8/6Q1/3B1P2/Pq3P1P/3RR1K1              White      Qxd7+      Kxd7       Bb5#       Queen      King       Bishop     "
local puzzle7 = "Wilfried_Paulsen            Adolf_Anderssen               Frankfurt                   1878  5rk1/1p1q2bp/p2pN1p1/2pP2Bn/2P3P1/1P6/P4QKP/5R2            White      Qxf8+      Bxf8       Rxf8#      Queen      Bishop     Rook       "
local puzzle8 = "Joseph_Blackburne           Smith                         Simul                       1882  r1nk3r/2b2ppp/p3b3/3NN3/Q2P3q/B2B4/P4PPP/4R1K1             White      Qd7+       Bxd7       Nxf7#      Queen      Bishop     Knight     "
local puzzle9 = "Wilhelm_Steinitz            David_Sands                   New_York                    1887  r4br1/3b1kpp/1q1P4/1pp1RP1N/p7/6Q1/PPB3PP/2KR4             White      Qg6+       hxg6       fxg6#      Queen      Pawn       Pawn       "
local puzzle10 = "Wilhelm_Steinitz            Albert_Hodges                 New_York                    1891  r1b2k1r/ppppq3/5N1p/4P2Q/4PP2/1B6/PP5P/n2K2R1              White      Qxh6+      Rxh6       Rg8#       Queen      Rook       Rook       "
local puzzle11 = "Siegbert_Tarrasch           Fiedler                       Nuremberg                   1892  r2q1b1r/1pN1n1pp/p1n3k1/4Pb2/2BP4/8/PPP3PP/R1BQ1RK1        White      Qg4+       Bxg4       Bf7#       Queen      Bishop     Bishop     "
local puzzle12 = "Harry_Pillsbury             Lyons_Rodgers                 New_York                    1893  3q2r1/4n2k/p1p1rBpp/PpPpPp2/1P3P1Q/2P3R1/7P/1R5K           White      Qxh6+      Kxh6       Rh3#       Queen      King       Rook       "
local puzzle13 = "Siegbert_Tarrasch           Max_Kurschner                 Nuremberg                   1893  r2qk2r/pb4pp/1n2Pb2/2B2Q2/p1p5/2P5/2B2PPP/RN2R1K1          White      Qg6+       hxg6       Bxg6#      Queen      Pawn       Bishop     "
local puzzle14 = "James_Mason                 Georg_Marco                   Leipzig                     1894  6k1/pp4p1/2p5/2bp4/8/P5Pb/1P3rrP/2BRRN1K                   Black      Rg1+       Kxg1       Rxf1#      Rook       King       Rook       "
local puzzle15 = "Frank_Teed                  Eugene_Delmar                 New_York                    1896  rnbqkbn1/ppppp3/7r/6pp/3P1p2/3BP1B1/PPP2PPP/RN1QK1NR       White      Qxh5+      Rxh5       Bg6#       Queen      Rook       Bishop     "
local puzzle16 = "Wilhelm_Steinitz            Herbert_Trenchard             Vienna                      1898  r2qrb2/p1pn1Qp1/1p4Nk/4PR2/3n4/7N/P5PP/R6K                 White      Ne7        Nxf5       Qg6#       Knight     Knight     Queen      "
local puzzle17 = "James_Mason                 Emanuel_Lasker                London                      1899  8/2r5/1k5p/1pp4P/8/K2P4/PR2QB2/2q5                         Black      Qc3+       Rb3        Ra7#       Queen      Rook       Rook       "
local puzzle18 = "Aaron_Nimzowitsch           Gustav_Neumann                Riga                        1899  r1b3nr/ppqk1Bbp/2pp4/4P1B1/3n4/3P4/PPP2QPP/R4RK1           White      Qf5+       Nxf5       e6#        Queen      Knight     Pawn       "
local puzzle19 = "Harry_Pillsbury             Samuel_Tinsley                London                      1899  3k1r1r/pb3p2/1p4p1/1B2B3/3qn3/6QP/P4RP1/2R3K1              White      Bf6+       Qxf6       Qc7#       Bishop     Queen      Queen      "
local puzzle20 = "Ryder                       NN                            Leipzig                     1899  rn2kb1r/1pQbpppp/1p6/qp1N4/6n1/8/PPP3PP/2KR2NR             White      Qc8+       Bxc8       Nc7#       Queen      Bishop     Knight     "
local puzzle21 = "Pulitzer                    George_Marco                  Vienna                      1900  r2k2nr/pp1b1Q1p/2n4b/3N4/3q4/3P4/PPP3PP/4RR1K              White      Re8+       Bxe8       Qc7#       Rook       Bishop     Queen      "
local puzzle22 = "Arturo_Reggio               Georg_Marco                   Monte_Carlo                 1902  7k/1p4p1/p4b1p/3N3P/2p5/2rb4/PP2r3/K2R2R1                  Black      Rc1+       Rxc1       Bxb2#      Rook       Rook       Bishop     "
local puzzle23 = "Emanuel_Lasker              NN                            Manchester                  1903  r2q2nr/5p1p/p1Bp3b/1p1NkP2/3pP1p1/2PP2P1/PP5P/R1Bb1RK1     White      Bf4+       Bxf4       gxf4#      Bishop     Bishop     Pawn       "
local puzzle24 = "Schwartz                    Samsonov                      Heidelberg                  1908  r2q1k1r/ppp1bB1p/2np4/6N1/3PP1bP/8/PPP5/RNB2RK1            White      Ne6+       Bxe6       Bh6#       Knight     Bishop     Bishop     "
local puzzle25 = "George_Rotlevi              Hugo_Suchting                 Carlsbad                    1911  6k1/1p1r1pp1/p1r3b1/3pPqB1/2pP4/Q1P4R/P3P2K/6R1            White      Qf8+       Kxf8       Rh8#       Queen      King       Rook       "
local puzzle26 = "Alexander_Flamberg          Oldrich_Duras                 Opatija                     1912  r1b3k1/ppp3pp/8/3pB3/1P1P4/3K1P2/PP1n1q1P/R2Q3R            Black      Bf5+       Kc3        Qe3#       Bishop     King       Queen      "
local puzzle27 = "Emanuel_Lasker              Fritz_Englund                 Scheveningen                1913  2kr1b1r/pp3ppp/2p1b2q/4B3/4Q3/2PB2R1/PPP2PPP/3R2K1         White      Qxc6+      bxc6       Ba6#       Queen      Pawn       Bishop     "
local puzzle28 = "Richard_Teichmann           NN                            Berlin                      1914  rn2kb1r/pp3ppp/4p1qn/1p4B1/2B5/3P2QP/PPP2PP1/R3K2R         White      Qxb8+      Rxb8       Bxb5#      Queen      Rook       Bishop     "
local puzzle29 = "Charles_Watson              NN                            Melbourne                   1916  rnb2b1r/p3kBp1/3pNn1p/2pQN3/1p2PP2/4B3/Pq5P/4K3            White      Qxd6+      Kxd6       Bxc5#      Queen      King       Bishop     "
local puzzle30 = "Brunnemer                   Patton                        USA                         1920  r1b1k2r/ppQ1q2n/2p2p2/P3p2p/N3P1pP/1B4P1/1PP2P2/3R1NK1     White      Rd8+       Qxd8       Qf7#       Rook       Queen      Queen      "
local puzzle31 = "Gerard_Oskam                Max_Euwe                      Amsterdam                   1920  r6k/pp4pp/1b1P4/8/1n4Q1/2N1RP2/PPq3p1/1RB1K3               Black      Nd3+       Rxd3       Bf2#       Knight     Rook       Bishop     "
local puzzle32 = "Saviely_Tartakower          Richard_Reti                  Vienna                      1920  8/1r5p/kpQ3p1/p3rp2/P6P/8/4bPPK/1R6                        White      Rxb6+      Rxb6       Qa8#       Rook       Rook       Queen      "
local puzzle33 = "Sery                        Z_Vecsey                      Brunn                       1921  r1b2rk1/2p2ppp/p7/1p6/3P3q/1BP3bP/PP3QP1/RNB1R1K1          White      Qxf7+      Rxf7       Re8#       Queen      Rook       Rook       "
local puzzle34 = "Johann_Berger               P_Froehlich                   Graz                        1922  r2qkb1r/2p1nppp/p2p4/np1NN3/4P3/1BP5/PP1P1PPP/R1B1K2R      White      Nf6+       gxf6       Bxf7#      Knight     Pawn       Bishop     "
local puzzle35 = "Probst                      Lowig                         Bad_Oeynhausen              1922  rnbkn2r/pppp1Qpp/5b2/3NN3/3Pp3/8/PPP1KP1P/R1B4q            White      Qe7+       Bxe7       Nf7#       Queen      Bishop     Knight     "
local puzzle36 = "Lajos_Steiner               Albert_Becker                 Vienna                      1923  4rk2/2pQn2p/p4p2/1p2pN1P/4q3/2P3R1/5PPK/8                  White      Rg8+       Kf7        Nh6#       Rook       King       Knight     "
local puzzle37 = "Max_Euwe                    A_Van_Mindeno                 Netherlands                 1927  r1b2rk1/pp3ppp/3p4/3Q1nq1/2B1R3/8/PP3PPP/R5K1              White      Qxf7+      Rxf7       Re8#       Queen      Rook       Rook       "
local puzzle38 = "Monterinas                  Max_Euwe                      Amsterdam                   1927  7r/p3ppk1/3p4/2p1P1Kp/2Pb4/3P1QPq/PP5P/R6R                 Black      Be3+       Qxe3       Qg4#       Bishop     Queen      Queen      "
local puzzle39 = "Ilya_Rabinovich             Grigori_Levenfish             Moscow                      1927  rn2kb1r/ppp1pppp/8/8/4q3/3P1N1b/PPP1BPnP/RNBQ1K1R          Black      Nh4+       Ke1        Nxf3#      Knight     King       Knight     "
local puzzle40 = "Springe                     Dietmar_Gebhard               Munich                      1927  r1b1kb1r/pp1n1pp1/1qp1p2p/6B1/2PPQ3/3B1N2/P4PPP/R4RK1      White      Qxe6+      fxe6       Bg6#       Queen      Pawn       Bishop     "
local puzzle41 = "Milan_Vidmar_Sr             Max_Euwe                      Carlsbad                    1929  6k1/5p2/1p5p/p4Np1/5q2/Q6P/PPr5/3R3K                       White      Qf8+       Kxf8       Rd8#       Queen      King       Rook       "
local puzzle42 = "William_Winter              Jacob_Gemzoe                  Folkestone                  1933  r3q3/ppp3k1/3p3R/5b2/2PR3Q/2P1PrP1/P7/4K3                  White      Qf6+       Kg8        Rh8#       Queen      King       Rook       "
local puzzle43 = "Nicolas_Ticoulat            Andor_Lilienthal              Sitges                      1934  r3k2r/1Bp2ppp/8/4q1b1/pP1n4/P1KP3P/1BP5/R2Q3R              Black      Nb5+       Kc4        Nd6#       Knight     King       Knight     "
local puzzle44 = "Arthur_Dake                 Timothy_Cranston              Warsaw                      1935  r1bq2rk/pp3pbp/2p1p1pQ/7P/3P4/2PB1N2/PP3PPR/2KR4           White      Qxh7+      Kxh7       hxg6#      Queen      King       Pawn       "
local puzzle45 = "Marcos_Luckis               Moshe_Czerniak                Warsaw                      1935  k1n3rr/Pp3p2/3q4/3N4/3Pp2p/1Q2P1p1/3B1PP1/R4RK1            White      Qxb7+      Kxb7       a8=Q#      Queen      King       Pawn       "
local puzzle46 = "Cherubino_Staldi            Uulberg                       Munich                      1936  8/1p3k2/4p1rp/p3Pp1Q/3qnP2/1P6/P6P/2R2R1K                  Black      Qg1+       Rxg1       Nf2#       Queen      Rook       Knight     "
local puzzle47 = "Boris_Kostic                Paul_Keres                    Stockholm                   1937  r1bq3r/ppp1b1kp/2n3p1/3B3Q/3p4/8/PPP2PPP/RNB2RK1           White      Bh6+       Kf6        Qg5#       Bishop     King       Queen      "
local puzzle48 = "Alexander_Alekhine          Fahardo                       Montevideo                  1939  4r3/pbpn2n1/1p1prp1k/8/2PP2PB/P5N1/2B2R1P/R5K1             White      Rxf6+      Nxf6       g5#        Rook       Knight     Pawn       "
local puzzle49 = "Vladimir_Petrov             H_Cordova                     Buenos_Aires                1939  1q5r/1b1r1p1k/2p1pPpb/p1Pp4/3B1P1Q/1P4P1/P4KB1/2RR4        White      Qxh6+      Kxh6       Rh1#       Queen      King       Rook       "
local puzzle50 = "Isaias_Pleci                Lucius_Endzelins              Buenos_Aires                1939  r4R2/1b2n1pp/p2Np1k1/1pn5/4pP1P/8/PPP1B1P1/2K4R            White      h5+        Kh6        Nf7#       Pawn       King       Knight     "
local puzzle51 = "Heinz_Helms                 Oscar_Tenner                  New_York                    1942  r1bqk2r/bppp1ppp/8/PB2N3/3n4/B7/2PPQnPP/RN2K2R             White      Nxd7+      Nxe2       Nf6#       Knight     Knight     Knight     "
local puzzle52 = "Boris_Ratner                Alexander_Konstantinopolsky   Moscow                      1945  1r4k1/3b2pp/1b1pP2r/pp1P4/4q3/8/PP4RP/2Q2R1K               Black      Rxh2+      Kxh2       Qh4#       Rook       King       Queen      "
local puzzle53 = "Enrico_Paoli                Jan_Foltys                    Trencianske_Teplice         1949  8/2k2p2/2b3p1/P1p1Np2/1p3b2/1P1K4/5r2/R3R3                 Black      Bb5+       Nc4        Rd2#       Bishop     Knight     Rook       "
local puzzle54 = "Arthur_Bisguier             J._Penrose                    Southsea                    1950  r4r1k/2qb3p/p2p1p2/1pnPN3/2p1Pn2/2P1N3/PPB1QPR1/6RK        White      Rg8+       Rxg8       Nf7#       Rook       Rook       Knight     "
local puzzle55 = "Pal_Benko                   Erno_Gereben                  Budapest                    1954  1r2q3/1R6/3p1kp1/1ppBp1b1/p3Pp2/2PP4/PP3P2/5K1Q            White      Qh8+       Qxh8       Rf7#       Queen      Queen      Rook       "
local puzzle56 = "Bennsdorf                   G_Krepp                       corr.                       1954  r3kb1r/pb6/2p2p1p/1p2pq2/2pQ3p/2N2B2/PP3PPP/3RR1K1         White      Bh5+       Qxh5       Qd7#       Bishop     Queen      Queen      "
local puzzle57 = "Miguel_Najdorf              Rodolfo_Kalkstein             Montevideo                  1954  4r3/2q1rpk1/p3bN1p/2p3p1/4QP2/2N4P/PP4P1/5RK1              White      Qh7+       Kxf6       Ne4#       Queen      King       Knight     "
local puzzle58 = "Ratmir_Kholmov              Y_Kliavinsh                   Vilnius                     1955  r5rk/pp1np1bn/2pp2q1/3P1bN1/2P1N2Q/1P6/PB2PPBP/3R1RK1      White      Qxh7+      Qxh7       Nf7#       Queen      Queen      Knight     "
local puzzle59 = "Octav_Troianescu            Cedendemberel_Lhagvasuren     Ulan_Bator                  1956  rn1qkb1r/4p2p/2p2nN1/p4p1Q/PpBP4/8/1P3PPP/R1B1K2R          White      Ne5+       Nxh5       Bf7#       Knight     Knight     Bishop     "
local puzzle60 = "Posch                       Derr                          Vienna                      1958  r1b2rk1/ppppbpp1/7p/4R3/6Qq/2BB4/PPP2PPP/R5K1              White      Qxg7+      Kxg7       Rg5#       Queen      King       Rook       "
local puzzle61 = "Mikhail_Tal                 Pal_Benko                     Bled                        1959  1r3k2/2n1p1b1/3p2QR/p1pq1pN1/bp6/7P/2P2PP1/4RBK1           White      Rh8+       Bxh8       Nh7#       Rook       Bishop     Knight     "
local puzzle62 = "Mark_Taimanov               Erich_Eliskases               Buenos_Aires                1960  5b2/1p3rpk/p1b3Rp/4B1RQ/3P1p1P/7q/5P2/6K1                  White      Rxh6+      gxh6       Qg6#       Rook       Pawn       Queen      "
local puzzle63 = "Boris_Spassky               Boris_Vladimirov              Baku                        1961  r2Rnk1r/1p2q1b1/7p/6pQ/4Ppb1/1BP5/PP3BPP/2K4R              White      Qxe8+      Qxe8       Bc5#       Queen      Queen      Bishop     "
local puzzle64 = "J_Golemo                    S_Sulek                       corr.                       1962  r2qr2k/pp1b3p/2nQ4/2pB1p1P/3n1PpR/2NP2P1/PPP5/2K1R1N1      White      Rxe8+      Bxe8       Qf8#       Rook       Bishop     Queen      "
local puzzle65 = "Dragoljub_Velimirovic       Dragoljub_Ciric               Belgrade                    1963  4r3/p2r1p1k/3q1Bpp/4P3/1PppR3/P5P1/5P1P/2Q3K1              White      Qxh6+      Kxh6       Rh4#       Queen      King       Rook       "
local puzzle66 = "Albin_Planinec              Milan_Matulovic               Novi_Sad                    1965  r3n1rk/q3NQ1p/p2pbP2/1p4p1/1P1pP1P1/3R4/P1P4P/3B2K1        White      Qxh7+      Kxh7       Rh3#       Queen      King       Rook       "
local puzzle67 = "Vlastimil_Hort              Bent_Larsen                   Sousse                      1967  8/2r2pk1/3p2p1/3Pb3/2P1P2K/6r1/1R2B3/1R6                   Black      Kh6        c5         g5#        King       Pawn       Pawn       "
local puzzle68 = "Wlodzimierz_Schmidt         Heinz_Liebert                 Polanica_Zdroj              1967  8/8/p3p3/3b1pR1/1B3P1k/8/4r1PK/8                           White      Be1+       Rxe1       g3#        Bishop     Rook       Pawn       "
local puzzle69 = "Tigran_Petrosian            Dragoslav_Tomic               Vinkovci                    1970  Q7/2r2rpk/2p4p/7N/3PpN2/1p2P3/1K4R1/5q2                    White      Rxg7+      Rxg7       Nf6#       Rook       Rook       Knight     "
local puzzle70 = "Samuel_Reshevsky            Yasuji_Matsumoto              Siegen                      1970  r3rknQ/1p1R1pb1/p3pqBB/2p5/8/6P1/PPP2P1P/4R1K1             White      Qxg7+      Qxg7       Rxf7#      Queen      Queen      Rook       "
local puzzle71 = "Anatoly_Karpov              Henrique_Mecking              Hastings                    1971  4rr2/1p5R/3p1p2/p2Bp3/P2bPkP1/1P5R/1P2K3/8                 White      Rg7        Bxb2       Rf3#       Rook       Bishop     Rook       "
local puzzle72 = "Walter_Browne               Coskun_Kulur                  Skopje                      1972  r4kr1/pbNn1q1p/1p6/2p2BPQ/5B2/8/P6P/b4RK1                  White      Bd6+       Qe7        Ne6#       Bishop     Queen      Knight     "
local puzzle73 = "Rafael_Vaganian             Viktor_Korchnoi               Moscow                      1975  6rk/6pp/5p2/p7/P2Q1N2/4P1P1/2r2n1P/6K1                     White      Ng6+       hxg6       Qh4#       Knight     Pawn       Queen      "
local puzzle74 = "Larry_Christiansen          Paul_Van_Der_Sterren          Amsterdam                   1978  1n6/p3q2p/2pNk3/1pP1p3/1P2P2Q/2P3P1/6K1/8                  White      Qh3+       Kf6        Qh6#       Queen      King       Queen      "
local puzzle75 = "Dragoljub_Janosevic         Tigran_Petrosian              Lone_Pine                   1978  6rk/p3p2p/1p2Pp2/2p2P2/2P1nBr1/1P6/P6P/3R1R1K              Black      Rg1+       Rxg1       Nf2#       Rook       Rook       Knight     "
local puzzle76 = "Malina_Boskovic             Michael_Rohde                 New_York                    1979  3rk3/1p3p2/2p5/7P/1P1qpp1R/P5P1/2Q5/3BK3                   Black      Qg1+       Ke2        f3#        Queen      King       Pawn       "
local puzzle77 = "Bent_Larsen                 Zoltan_Ribli                  Riga                        1979  2QR4/6b1/1p4pk/7p/5n1P/4rq2/5P2/5BK1                       White      Rh8+       Bxh8       Qxh8#      Rook       Bishop     Queen      "
local puzzle78 = "Raymond_Keene               C_Van_Baarle                  Berlin                      1980  r3q1k1/5p2/3P2pQ/Ppp5/1pnbN2R/8/1P4PP/5R1K                 White      Rf6        Bxf6       Nxf6#      Rook       Bishop     Knight     "
local puzzle79 = "Dragoslav_Andric            Luigi_Santolini               Caorle                      1981  5b2/R4p1p/1r2kp2/1p2pN2/2r1P3/P1P3P1/1PK4P/3R4             White      Re7+       Bxe7       Ng7#       Rook       Bishop     Knight     "
local puzzle80 = "Jeremy_Silman               Ozdal_Barkan                  Palo_Alto                   1981  r3q1r1/1p2bNkp/p3n3/2PN1B1Q/PP1P1p2/7P/5PP1/6K1            White      Qh6+       Kxf7       Bxe6#      Queen      King       Bishop     "
local puzzle81 = "Vlastimil_Hort              Alex_Dunne                    Lucerne                     1982  1r2q2k/4N2p/3p1Pp1/2p1n1P1/2P5/p2P2KQ/P3R3/8               White      Qxh7+      Kxh7       Rh2#       Queen      King       Rook       "
local puzzle82 = "Boris_Spassky               Arnulf_Westermeier            Germany                     1982  5R2/4r1r1/1p4k1/p1pB2Bp/P1P4K/2P1p3/1P6/8                  White      Rf6+       Kh7        Rh6#       Rook       King       Rook       "
local puzzle83 = "Werner_Hobusch              Liebscher                     corr.                       1984  2bq1rk1/r1p1b1pn/p2pP1Np/1p1B1Q2/4P3/2P4P/PP3PP1/R1B1R1K1  White      Qf7+       Rxf7       exf7#      Queen      Rook       Pawn       "
local puzzle84 = "Ian_Rogers                  Zlatko_Klaric                 Nouro                       1984  1nbk1b1r/1r6/p2P2pp/1B2PpN1/2p2P2/2P1B3/7P/R3K2R           White      Bb6+       Rxb6       Nf7#       Bishop     Rook       Knight     "
local puzzle85 = "Arthur_Bisguier             Sergey_Kudrin                 Philadelphia                1985  3r2k1/p1p2p2/bp2p1nQ/4PB1P/2pr3q/6R1/PP3PP1/3R2K1          White      Rxg6+      fxg6       Bxe6#      Rook       Pawn       Bishop     "
local puzzle86 = "Sergey_Smagin               Viktor_Kupreichik             Minsk                       1985  6k1/3r3p/p1q3pP/1p1p4/3Q4/4R1P1/P4PK1/8                    White      Qh8+       Kxh8       Re8#       Queen      King       Rook       "
local puzzle87 = "Abraham_Szlern              David_Colhoun                 Toowoomba                   1986  2k4r/ppp5/4bqp1/3p2Q1/6n1/2NB3P/PPP2bP1/R1B2R1K            Black      Rxh3+      gxh3       Qf3#       Rook       Pawn       Queen      "
local puzzle88 = "Nick_De_Firmian             Edward_Formanek               Philadelphia                1987  r2r3k/b1qn2pp/1p2Bp2/2p2P2/PP1pQ3/7R/1B3PPP/5RK1           White      Rxh7+      Kxh7       Qh4#       Rook       King       Queen      "
local puzzle89 = "Viktor_Korchnoi             Lev_Gutman                    Wijk_aan_Zee                1987  8/1p3Qb1/p5pk/P1p1p1p1/1P2P1P1/2P1N2n/5P1P/4qB1K           White      Nf5+       gxf5       Qh5#       Knight     Pawn       Queen      "
local puzzle90 = "Alexey_Kuzmin               Evgeny_Vladimirov             Tashkent                    1987  3rrk2/2p2pR1/p4n2/1p1PpP2/2p2q1P/3P1BQ1/PPP5/6RK           White      Rxf7+      Kxf7       Qg7#       Rook       King       Queen      "
local puzzle91 = "Michael_Adams               Luis_Comas_Fabrego            Adelaide                    1988  r4kr1/1b2R1n1/pq4p1/4Q3/1p4P1/5P2/PPP4P/1K2R3              White      Rf7+       Kxf7       Qe7#       Rook       King       Queen      "
local puzzle92 = "Vassily_Ivanchuk            Bozidar_Ivanovic              New_York                    1988  3n4/1R6/p5k1/2B5/1P3PK1/r7/8/8                             White      f5+        Kf6        Bd4#       Pawn       King       Bishop     "
local puzzle93 = "Nona_Gaprindashvili         Eliska_Richtrova              Wuppertal                   1990  1r3rk1/1pnnq1bR/p1pp2B1/P2P1p2/1PP1pP2/2B3P1/5PK1/2Q4R     White      Rh8+       Bxh8       Rxh8#      Rook       Bishop     Rook       "
local puzzle94 = "Ram_Ofek                    Gregory_Kaidanov              London                      1990  b3r1k1/5ppp/p2p4/p4qN1/Q2b4/6R1/5PPP/5RK1                  Black      Qxf2+      Rxf2       Re1#       Queen      Rook       Rook       "
local puzzle95 = "Leonid_Shamkovich           Anatoly_Trubman               USA                         1990  5r1k/pp1n1p1p/5n1Q/3p1pN1/3P4/1P4RP/P1r1qPP1/R5K1          White      Qxf8+      Nxf8       Nxf7#      Queen      Knight     Knight     "
local puzzle96 = "Arthur_Bisguier             Fabian_Geisler                New_York                    1991  5k2/p3Rr2/1p4pp/q4p2/1nbQ1P2/6P1/5N1P/3R2K1                White      Re8+       Kxe8       Qd8#       Rook       King       Queen      "
local puzzle97 = "Larry_Christiansen          John_Nunn                     Vienna                      1991  4rk2/pp2N1bQ/5p2/8/2q5/P7/3r2PP/4RR1K                      White      Rxf6+      Bxf6       Ng6#       Rook       Bishop     Knight     "
local puzzle98 = "Hermann_Heslenfeld          Robert_Wade                   Bad_Woerishofen             1991  r4rk1/4bp2/1Bppq1p1/4p1n1/2P1Pn2/3P2N1/P2Q1PBK/1R5R        Black      Qh3+       Bxh3       Nf3#       Queen      Bishop     Knight     "
local puzzle99 = "Gregory_Kaidanov            Eric-Thierry_Petit            Torcy                       1991  2q1r3/4pR2/3rQ1pk/p1pnN2p/Pn5B/8/1P4PP/3R3K                White      Nf3        Qxe6       Bg5#       Knight     Queen      Bishop     "
local puzzle100 = "Grigory_Serper              Alexei_Shirov                 Moscow                      1991  q2br1k1/1b4pp/3Bp3/p6n/1p3R2/3B1N2/PP2QPPP/6K1             White      Qxe6+      Rxe6       Rf8#       Queen      Rook       Rook       "
local puzzle101 = "Almira_Skripchenko          Ralph_Zimmer                  Bad_Mondorf                 1991  5r1k/p2n1p1p/5P1N/1p1p4/2pP3P/8/PP4RK/8                    White      Rg8+       Rxg8       Nxf7#      Rook       Rook       Knight     "
local puzzle102 = "Michael_Adams               Eric_Lobron                   Brussels                    1992  8/7p/5pk1/3n2pq/3N1nR1/1P3P2/P6P/4QK2                      White      Qe8+       Kg7        Nf5#       Queen      King       Knight     "
local puzzle103 = "Hoang_Thanh_Tran            Alina_Calota                  Duisburg                    1992  2Q5/pp2rk1p/3p2pq/2bP1r2/5RR1/1P2P3/PB3P1P/7K              White      Rxf5+      gxf5       Qg8#       Rook       Pawn       Queen      "
local puzzle104 = "Cristina_Iosif              Almira_Skripchenko            Rumania                     1992  4r1k1/pQ3pp1/7p/4q3/4r3/P7/1P2nPPP/2BR1R1K                 Black      Qxh2+      Kxh2       Rh4#       Queen      King       Rook       "
local puzzle105 = "Dmitri_Reinderman           Harmen_Jonkman                Nijmegen                    1992  3R1rk1/1pp2pp1/1p6/8/8/P7/1q4BP/3Q2K1                      White      Rxf8+      Kh7        Qh5#       Rook       King       Queen      "
local puzzle106 = "Josh_Waitzkin               Luis_Hoyos-Millan             New_York                    1992  6k1/5p2/p3bRpQ/4q3/2r3P1/6NP/P1p2R1K/1r6                   White      Rxg6+      fxg6       Rf8#       Rook       Pawn       Rook       "
local puzzle107 = "Esa_Auvinen                 Harri_Hytonen                 Helsinki                    1993  rnb1k2r/pp3ppp/1qp2B2/2bPp3/4P3/2N5/PPP3PP/R2QKBNR         Black      Bf2+       Kd2        Qe3#       Bishop     King       Queen      "
local puzzle108 = "R_Baudry                    Olivier_Tardif                Massy                       1993  r2r4/pp2ppkp/2P3p1/q1p5/4PQ2/2P2b2/P4PPP/2R1KB1R           Black      Qxc3+      Rxc3       Rd1#       Queen      Rook       Rook       "
local puzzle109 = "Saidali_Iuldachev           I_Dgumaev                     Tashkent                    1993  8/8/2N1P3/1P6/4Q3/4b2K/4k3/4q3                             White      Nd4+       Kd1        Qc2#       Knight     King       Queen      "
local puzzle110 = "Andreas_Bartsch             Waldemar_Grom                 Velden                      1994  1b2r1k1/3n2p1/p3p2p/1p3r2/3PNp1q/3BnP1P/PP1BQP1K/R6R       Black      Qxh3+      Kxh3       Rh5#       Queen      King       Rook       "
local puzzle111 = "Luke_McShane                Aiden_Leech                   London                      1994  5b2/q4r1p/p3k1p1/2pNppP1/1P6/3Q1P1P/P7/1K1R4               White      Nf4+       exf4       Qe2#       Knight     Pawn       Queen      "
local puzzle112 = "Werni_Rodel                 James_Sherwin                 Switzerland                 1994  8/2p5/Q4pk1/p1Pp4/5n2/PP3PK1/2q4N/8                        Black      Qg2+       Kxf4       Qg5#       Queen      King       Queen      "
local puzzle113 = "Yury_Shulman                Ilia_Botvinnik                Minsk                       1994  r3nr1k/1b2Nppp/pn6/q3p1P1/P1p4Q/R7/1P2PP1P/2B2RK1          White      Qxh7+      Kxh7       Rh3#       Queen      King       Rook       "
local puzzle114 = "Eugene_Levin                Walter_Shipman                Concord                     1995  r1b3nr/ppp1kB1p/3p4/8/3PPBnb/1Q3p2/PPP2q2/RN4RK            Black      Qh2+       Bxh2       Nf2#       Queen      Bishop     Knight     "
local puzzle115 = "J_Liger                     Alexander_Scetinin            Cappelle_la_Grande          1995  q5k1/5rb1/r6p/1Np1n1p1/3p1Pn1/1N4P1/PP5P/R1BQRK2           Black      Qh1+       Ke2        Qg2#       Queen      King       Queen      "
local puzzle116 = "Petr_Virostko               Levon_Aronian                 Verdun                      1995  8/2P2pk1/3Q4/4pq2/7p/6pP/2r3P1/6RK                         Black      Qxh3+      gxh3       Rh2#       Queen      Pawn       Rook       "
local puzzle117 = "Claudia_Amura               Carlos_Bulcourf               Villa_Ballester             1996  8/p1R3p1/4p1kn/3p3N/3Pr2P/6P1/PP3K2/8                      White      Rxg7+      Kxh5       Rg5#       Rook       King       Rook       "
local puzzle118 = "Ronald_Bancod               Richard_Forster               Weilburg                    1996  r1b1k2r/1p2bppp/p3q3/1p2p1B1/8/3Q1N2/PPP2PPP/3R1RK1        White      Qd8+       Bxd8       Rxd8#      Queen      Bishop     Rook       "
local puzzle119 = "Ferenc_Berkes               Diana_Nemeth                  Hungary                     1996  rn2k2r/pp2b2p/2p1Q1p1/5B2/1q3B2/8/PPP3PP/3RR2K             White      Rd8+       Kxd8       Qc8#       Rook       King       Queen      "
local puzzle120 = "Georgios_Efthimiou          V_Siametis                    Mitilini                    1996  r1b1k2r/pp3ppp/2n1p3/6B1/2p1q3/Q7/PP2PPPP/3RKB1R           White      Rd8+       Nxd8       Qe7#       Rook       Knight     Queen      "
local puzzle121 = "Jindrich_Kuba               David_Kanovsky                Svetla_nad_Sazavou          1996  2k4r/1pp1n1pp/p1pr1pb1/4p3/Nq2P1P1/1P1PKN1P/2P1QP2/3R3R    Black      Nd5+       exd5       Qf4#       Knight     Pawn       Queen      "
local puzzle122 = "Judit_Polgar                E._Bareev                     Kremlin_PCA_Rapid           1996  5k1r/4npp1/p3p2p/3nP2P/3P3Q/3N4/qB2KPP1/2R5                White      Rc8+       Nxc8       Qd8#       Rook       Knight     Queen      "
local puzzle123 = "Anatoly_Karpov              Bidjukova                     Voronezh                    1997  2r5/2R5/3npkpp/3bN3/p4PP1/4K3/P1B4P/8                      White      g5+        hxg5       Ng4#       Pawn       Pawn       Knight     "
local puzzle124 = "Anatoly_Karpov              Piotr_Mickiewicz              Koszalin                    1997  5r1r/1p6/p1p2p2/2P1bPpk/4R3/6PP/P2B2K1/3R4                 White      Rh4+       gxh4       g4#        Rook       Pawn       Pawn       "
local puzzle125 = "Alexander_Riazantsev        Artem_Iljin                   St._Petersburg              1997  5qrk/5p1n/pp3p1Q/2pPp3/2P1P1rN/2P4R/P5P1/2B3K1             White      Ng6+       R4xg6      Qxh7#      Knight     Rook       Queen      "
local puzzle126 = "Jonathan_Rowson             John_Richardson               Staffordshire               1997  3rk2r/p1qn1pp1/1p2pb1p/7P/2Pp4/B1P1QP2/P1B1KP2/3R3R        White      Qxe6+      fxe6       Bg6#       Queen      Pawn       Bishop     "
local puzzle127 = "Boris_Spassky               G_Gilquin                     Bastia                      1997  r3kb1r/q5pp/p1p1Bnn1/1p2Q3/8/2N2PBP/PPP5/2KRR3             White      Bf7+       Kxf7       Qe6#       Bishop     King       Queen      "
local puzzle128 = "Lazaro_Bruzon               Thomas_Willemze               Marina_d'Or                 1998  rq3rk1/3n1pp1/pb4n1/3N2P1/1pB1QP2/4B3/PP6/2KR3R            White      Ne7+       Nxe7       Qh7#       Knight     Knight     Queen      "
local puzzle129 = "Emil_Sutovsky               Bogdan_Grabarczyk             Koszalin                    1998  3q2r1/p2b1k2/1pnBp1N1/3p1pQP/6P1/5R2/2r2P2/4RK2            White      Nh8+       Rxh8       Qg6#       Knight     Rook       Queen      "
local puzzle130 = "Veselin_Topalov             Garry_Kasparov                Sofia                       1998  8/p4pk1/6p1/3R4/3nqN1P/2Q3P1/5P2/3r1BK1                    Black      Rxf1+      Kxf1       Qh1#       Rook       King       Queen      "
local puzzle131 = "Etienne_Bacrot              Laurent_Fressinet             Besancon                    1999  2r5/3nbkp1/2q1p1p1/1p1n2P1/3P4/2p1P1NQ/1P1B1P2/1B4KR       White      Bxg6+      Kxg6       Qh5#       Bishop     King       Queen      "
local puzzle132 = "Ludwig_Deutsch              B_Zambo                       Zalakaros                   1999  r1bq1rkb/ppp2n1p/5n2/4p1NN/5pQ1/1BP5/PP3PPP/R1B1K2R        White      Nxf7+      Nxg4       Nh6#       Knight     Knight     Knight     "
local puzzle133 = "Maia_Chiburdanidze          Roman_Slobodjan               Lippstadt                   2000  4r3/1b2r2p/p2p2k1/P1pP1R1N/3b4/1P1B3P/3n2P1/5R1K           White      Re5+       Ne4        Rf6#       Rook       Knight     Rook       "
local puzzle134 = "Nana_Dzagnidze              Tsiala_Kasoshvili             Tbilisi                     2000  2b3k1/1p5p/2p1n1pQ/3qB3/3P4/3B3P/r5P1/5RK1                 White      Rf8+       Nxf8       Qg7#       Rook       Knight     Queen      "
local puzzle135 = "Gadir_Guseinov              Ernesto_Fernandez_Romero      Aviles                      2000  3rk2r/1pR2p2/b2BpPp1/p2p4/8/1P6/P4PPP/4R1K1                White      Rxe6+      fxe6       f7#        Rook       Pawn       Pawn       "
local puzzle136 = "Luke_McShane                Bart_Michiels                 Brussels                    2000  4nr1k/1bq3pp/5p2/1p2pNQ1/3pP3/1B1P3R/1PP3PP/6K1            White      Rxh7+      Kxh7       Qh5#       Rook       King       Queen      "
local puzzle137 = "Valentina_Golubenko         Kerttu_Oja                    Narva                       2001  r1bk1r2/pp1n2pp/3NQ3/1P6/8/2n2PB1/q1B3PP/3R1RK1            White      Nxb7+      Bxb7       Qxd7#      Knight     Bishop     Queen      "
local puzzle138 = "Boris_Grachev               Sergey_Chapar                 Chalkidiki                  2001  1rb2k2/pp3ppQ/7q/2p1n1N1/2p5/2N5/P3BP1P/K2R4               White      Qg8+       Ke7        Qd8#       Queen      King       Queen      "
local puzzle139 = "Katya_Lahno                 Sofia_Shepeleva               Kramatorsk                  2001  4r3/5p1k/2p1nBpp/q2p4/P1bP4/2P1R2Q/2B2PPP/6K1              White      Qxh6+      Kxh6       Rh3#       Queen      King       Rook       "
local puzzle140 = "Iokhan_Doukhine             Nadezhda_Kosintseva           Vladimir                    2002  2r3k1/6pp/4pp2/3bp3/1Pq5/3R1P2/r1PQ2PP/1K1RN3              Black      Ra1+       Kb2        Qa2#       Rook       King       Queen      "
local puzzle141 = "Axel_Bachmann               Vladimir_Galakhov             Internet                    2003  6R1/5r1k/p6b/1pB1p2q/1P6/5rQP/5P1K/6R1                     White      Rh8+       Kxh8       Qg8#       Rook       King       Queen      "
local puzzle142 = "Magnus_Carlsen              Helgi_Gretarsson              Rethymnon                   2003  r5q1/pp1b1kr1/2p2p2/2Q5/2PpB3/1P4NP/P4P2/4RK2              White      Bg6+       Kxg6       Qh5#       Bishop     King       Queen      "
local puzzle143 = "Surya_Ganguly               M_R_Venkatesh                 Calicut                     2003  2r1kb1r/p2b1ppp/3p4/Q2Np1B1/4P2P/8/PP4P1/4KB1n             White      Qd8+       Rxd8       Nc7#       Queen      Rook       Knight     "
local puzzle144 = "Jon_Hammer                  Magnus_Carlsen                Halkidiki                   2003  5rk1/ppp2pbp/3p2p1/1q6/4r1P1/1NP1B3/PP2nPP1/R2QR2K         Black      Qh5+       gxh5       Rh4#       Queen      Pawn       Rook       "
local puzzle145 = "Michel_Jadoul               Gordon_Plomp                  Belgium                     2003  r2q1bk1/5n1p/2p3pP/p7/3Br3/1P3PQR/P5P1/2KR4                White      Qxg6+      hxg6       h7#        Queen      Pawn       Pawn       "
local puzzle146 = "Gennadij_Sagalchik          Hikaru_Nakamura               Buenos_Aires                2003  2b5/k2n1p2/p2q4/5R1B/2p4P/P1b5/KPQ1R3/6r1                  Black      Qxa3+      Kxa3       Ra1#       Queen      King       Rook       "
local puzzle147 = "Zhu_Chen                    Ioannis_Papaioannou           Gerani                      2003  4Q3/r4ppk/3p3p/4pPbB/2P1P3/1q5P/6P1/3R3K                   White      Bg6+       fxg6       fxg6#      Bishop     Pawn       Pawn       "
local puzzle148 = "Nana_Dzagnidze              Inga_Charkhalashvili          Tbilisi                     2004  rn5r/p4pp1/3n3p/qB1k4/3P4/4P3/PP2NPPP/R4K1R                White      Nf4+       Ke4        Bd3#       Knight     King       Bishop     "
local puzzle149 = "Radomir_Hacik               Jozef_Dlhy                    Slovakia                    2004  r2r2k1/pp2bppp/2p1p3/4qb1P/8/1BP1BQ2/PP3PP1/2KR3R          Black      Qxc3+      bxc3       Ba3#       Queen      Pawn       Bishop     "
local puzzle150 = "Alexandra_Kosteniuk         Tatiana_Shumiakina            Kazan                       2004  5R2/6k1/3K4/p6r/1p1NB3/1P4r1/8/8                           White      Ne6+       Kh6        Rh8#       Knight     King       Rook       "
local puzzle151 = "Bathuyag_Mongontuul         Garcia_Vicente                Calvia                      2004  5r2/1qp2pp1/bnpk3p/4NQ2/2P5/1P5P/5PP1/4R1K1                White      Nxf7+      Rxf7       c5#        Knight     Rook       Pawn       "
local puzzle152 = "Vladimir_Potkin             Aleksandra_Dimitrijevic       Internet                    2004  3nk1r1/1pq4p/p3PQpB/5p2/2r5/8/P4PPP/3RR1K1                 White      Rxd8+      Qxd8       Qf7#       Rook       Queen      Queen      "
local puzzle153 = "Tuuli_Vahtra                Valentina_Golubenko           Tartu                       2004  5rk1/5ppp/pq6/1r3n2/2Q2P2/1P1N4/P1P1R1PP/4R2K              Black      Ng3+       hxg3       Rh5#       Knight     Pawn       Rook       "
local puzzle154 = "M_Calzetta                  K_White                       Gibraltar                   2005  1k3r2/4R1Q1/p2q1r2/8/2p1Bb2/5R2/pP5P/K7                    White      Re8+       Rxe8       Qb7#       Rook       Rook       Queen      "
local puzzle155 = "Marianna_Kalinina           Mariya_Muzychuk               Evpatoria                   2005  2k1r2r/ppp3p1/3b4/3pq2b/7p/2NP1P2/PPP2Q1P/R5RK             Black      Bxf3+      Rg2        Qxh2#      Bishop     Rook       Queen      "
local puzzle156 = "Natalia_Zhukova             Nadezhda_Kosintseva           Elista                      2005  3k4/1p3Bp1/p5r1/2b5/P3P1N1/5Pp1/1P1r4/2R4K                 Black      Rh2+       Nxh2       g2#        Rook       Knight     Pawn       "
local puzzle157 = "Camilla_Baginskaite         Ana-Cristina_Calotescu        Turin                       2006  6k1/1r4np/pp1p1R1B/2pP2p1/P1P5/1n5P/6P1/4R2K               White      Re8+       Nxe8       Rf8#       Rook       Knight     Rook       "
local puzzle158 = "Elina_Danielian             Michail_Brodsky               Cappelle_la_Grande          2006  8/p2q1p1k/4pQp1/1p1b2Bp/7P/8/5PP1/6K1                      White      Bh6        Kxh6       Qh8#       Bishop     King       Queen      "
local puzzle159 = "Kaido_Kulaots               Felix_Levin                   Gausdal                     2006  r7/6R1/ppkqrn1B/2pp3p/P6n/2N5/8/1Q1R1K2                    White      Qb5+       axb5       axb5#      Queen      Pawn       Pawn       "
local puzzle160 = "Iweta_Radziewicz            Katharina_Bacler              Germany                     2006  r2q1k1r/3bnp2/p1n1pNp1/3pP1Qp/Pp1P4/2PB4/5PPP/R1B2RK1      White      Qh6+       Rxh6       Bxh6#      Queen      Rook       Bishop     "
local puzzle161 = "James_Sherwin               Joshua_Hall                   Bristol                     2006  6rk/1r2pR1p/3pP1pB/2p1p3/P6Q/P1q3P1/7P/5BK1                White      Rxh7+      Kxh7       Bf8#       Rook       King       Bishop     "
local puzzle162 = "Radoslaw_Wojtaszek          Darcy_Lima                    Turin                       2006  1r2Rr2/3P1p1k/5Rpp/qp6/2pQ4/7P/5PPK/8                      White      Rxf7+      Rxf7       Qh8#       Rook       Rook       Queen      "
local puzzle163 = "Sergei_Zhigalko             Boguslaw_Major                Warsaw                      2006  r4rk1/5Rbp/p1qN2p1/P1n1P3/8/1Q3N1P/5PP1/5RK1               White      Rxf8+      Kxf8       Qf7#       Rook       King       Queen      "
local puzzle164 = "Yuriy_Kuzubov               Alexander_Van_Beek            Gibraltar                   2007  7R/3r4/8/3pkp1p/5N1P/b3PK2/5P2/8                           White      Rh6        Re7        Nd3#       Rook       Rook       Knight     "
local puzzle165 = "Robert_Wade                 Colin_Horton                  Gibraltar                   2007  8/1R3p2/3rk2p/p2p2p1/P2P2P1/3B1PN1/5K1P/r7                 White      Bf5+       Kf6        Nh5#       Bishop     King       Knight     "
local puzzle166 = "Evgeny_Agrest               Axel_Smith                    Malme                       2008  8/5prk/p5rb/P3N2R/1p1PQ2p/7P/1P3RPq/5K2                    White      Rxh6+      Kg8        Qa8#       Rook       King       Queen      "
local puzzle167 = "James_Berry                 Alexander_Gorbunov            Tulsa                       2008  rqb2bk1/3n2pr/p1pp2Qp/1p6/3BP2N/2N4P/PPP3P1/2KR3R          White      Qe6+       Kh8        Ng6#       Queen      King       Knight     "
local puzzle168 = "Jon_Hammer                  Shakil_Abu_Sufian             Dresden                     2008  1Q6/r3R2p/k2p2pP/p1q5/Pp4P1/5P2/1PP3K1/8                   White      Rxa7+      Qxa7       Qb5#       Rook       Queen      Queen      "
local puzzle169 = "Einora_Juciute              Alan_Barton                   Hastings                    2008  N5k1/5p2/6p1/6Pp/4bb1P/P5r1/7K/2R3R1                       Black      Rg2+       Kh3        Rh2#       Rook       King       Rook       "
local puzzle170 = "Stephen_Lukey               solomon_Celis                 Dresden                     2008  3R4/3Q1p2/q1rn2kp/4p3/4P3/2N3P1/5P1P/6K1                   White      Qg4+       Kf6        Nd5#       Queen      King       Knight     "
local puzzle171 = "Rainer_Polzin               Alexander_Motylev             Germany                     2008  6R1/2k2P2/1n5r/3p1p2/3P3b/1QP2p1q/3R4/6K1                  Black      Qh1+       Kxh1       Bf2#       Queen      King       Bishop     "
local puzzle172 = "Eltaj_Safarli               Bela_Khotenashvili            Baku                        2008  5r2/7p/3R4/p3pk2/1p2N2p/1P2BP2/6PK/4r3                     White      g4+        hxg3+      Nxg3#      Pawn       Pawn       Knight     "
local puzzle173 = "Alexei_Shirov               Dmitry_Andreikin              Sochi                       2008  7r/3kbp1p/1Q3R2/3p3q/p2P3B/1P5K/P6P/8                      White      Qc6+       Kd8        Rd6#       Queen      King       Rook       "
local puzzle174 = "Sanan_Sjugirov              Maxim_Matlakov                St._Petersburg              2008  r4r1k/p2p3p/bp1Np3/4P3/2P2nR1/3B1q2/P1PQ4/2K3R1            White      Rg8+       Rxg8       Nf7#       Rook       Rook       Knight     "
local puzzle175 = "Sanan_Sjugirov              Alexander_Tjurin              Moscow                      2008  1r3b2/1bp2pkp/p1q4N/1p1n1pBn/8/2P3QP/PPB2PP1/4R1K1         White      Bf6+       Kxf6       Ng8#       Bishop     King       Knight     "
local puzzle176 = "Peter_Svidler               Vassily_Ivanchuk              Moscow                      2008  8/k1p1q3/Pp5Q/4p3/2P1P2p/3P4/4K3/8                         White      Qc6        Kxa6       Qa8#       Queen      King       Queen      "
local puzzle177 = "Dmitry_Bocharov             Dmitry_Svetushkin             Budva                       2009  8/pp2k3/7r/2P1p1p1/4P3/5pq1/2R3N1/1R3BK1                   Black      f2+        Rxf2       Qh2#       Pawn       Rook       Queen      "
local puzzle178 = "Zahar_Efimenko              Dimitri_Reinderman            Wijk_aan_Zee                2009  7k/p5b1/1p4Bp/2q1p1p1/1P1n1r2/P2Q2N1/6P1/3R2K1             Black      Ne2+       Kh2        Rh4#       Knight     King       Rook       "
local puzzle179 = "Alexander_Grischuk          Baadur_Jobava                 Khanty_Mansyisk             2009  8/p4q2/6k1/1p3rP1/3Q4/8/PPP5/K6R                           White      Rh6+       Kxg5       Qh4#       Rook       King       Queen      "
local puzzle180 = "Arne_Hagesaether            Raymond_Cannon                Hastings                    2009  2r3k1/1p3ppp/p3p3/7P/P4P2/1R2QbP1/6q1/1B2K3                Black      Rc1+       Qxc1       Qe2#       Rook       Queen      Queen      "
local puzzle181 = "Maxim_Rodshtein             Ian_Nepomniachtchi            Natanya                     2009  6r1/p6k/Bp3n1r/2pP1P2/P4q1P/2P2Q2/5K2/2R2R2                Black      Ne4+       Ke1        Qd2#       Knight     King       Queen      "
local puzzle182 = "Iryna_Zenyuk                Sabina-Francesca_Foisor       Saint_Louis                 2009  8/8/8/5P2/R2p1N2/4n1r1/PP6/5k1K                            Black      Ng4        Ng2        Rh3#       Knight     Knight     Rook       "
local puzzle183 = "Vladimir_Akopian            Vadim_Zvjaginsev              Rijeka                      2010  r7/4k1Pp/2n1p2P/q2pp1N1/1p4P1/1P6/P4R2/1K1R4               White      Rf7+       Kd6        Ne4#       Rook       King       Knight     "
local puzzle184 = "Aleksandar_Berelovich       Francisco_Vallejo_Pons        Germany                     2010  2Q5/1p3p2/3b1k1p/3Pp3/4B1R1/4q1P1/r4PK1/8                  White      Qd8+       Be7        Qh8#       Queen      Bishop     Queen      "
local puzzle185 = "Mekhri_Geldyeva             Marvorii_Nasriddinzoda        Khanty_Mansyisk             2010  8/5Qpk/p1R4p/P2p4/6P1/2rq4/5PPK/8                          White      Rxh6+      Kxh6       Qh5#       Rook       King       Queen      "
local puzzle186 = "Suradj_Hanoeman             Rodolfo_Varron_Abelgas        Khanty_Mansyisk             2010  3n1k2/5p2/2p1bb2/1p2pN1q/1P2P3/2P3Q1/5PB1/3R2K1            White      Qg7+       Bxg7       Rxd8#      Queen      Bishop     Rook       "
local puzzle187 = "David_Howell                Tomasz_Warakomski             Germany                     2010  rnR5/p3p1kp/4p1pn/bpP5/5BP1/5N1P/2P2P2/2K5                 White      Be5+       Kf7        Ng5#       Bishop     King       Knight     "
local puzzle188 = "Badr-Eddine_Khelfallah      Euler_da_Costa_Moreira        Khanty_Mansyisk             2010  6rk/6p1/4R2p/p2pP2b/5Q2/2P2PB1/1q4PK/8                     White      Rxh6+      gxh6       Qxh6#      Rook       Pawn       Queen      "
local puzzle189 = "Li_Xueyi                    Ju_Wenjun                     Shanghai                    2010  1Q6/8/3p1pk1/2pP4/1p3K2/5R2/5qP1/4r3                       Black      Re4+       Kxe4       Qd4#       Rook       King       Queen      "
local puzzle190 = "Liem_Le_Quang               Phemelo_Khetho                Khanty_Mansyisk             2010  r4r1k/pp5p/n5p1/1q2Np1n/1Pb5/6P1/PQ2PPBP/1RB3K1            White      Nf7+       Kg8        Nh6#       Knight     King       Knight     "
local puzzle191 = "Katrina_Skinke              Silvia_Collas                 Khanty_Mansyisk             2010  7k/p1p2bp1/3q1N1p/4rP2/4pQ2/2P4R/P2r2PP/4R2K               White      Rxh6+      gxh6       Qxh6#      Rook       Pawn       Queen      "
local puzzle192 = "Wesley_So                   Anish_Giri                    Wijk_aan_Zee                2010  7k/2p3pp/p7/1p1p4/PP2pr2/B1P3qP/4N1B1/R1Qn2K1              Black      Rf1+       Kxf1       Qf2#       Rook       King       Queen      "
local puzzle193 = "Tanja_Butschek              Julia_Krasnopeyeva            Germany                     2011  r1b2k2/1p1p1r1B/n4p2/p1qPp3/2P4N/4P1R1/PPQ3PP/R5K1         White      Rg8+       Ke7        Nf5#       Rook       King       Knight     "
local puzzle194 = "Vladimir_Fedoseev           Tomi_Nyback                   Tallinn                     2012  8/8/2K2b2/2N2k2/1p4R1/1B3n1P/3r1P2/8                       White      Be6+       Ke5        Re4#       Bishop     King       Rook       "
local puzzle195 = "Nana_Dzagnidze              Gulnar_Mammadova              Gaziantep                   2012  5R2/R5pp/2b1p1k1/5n2/p1r2PK1/8/7P/8                        Black      h5+        Kh3        Rc3#       Pawn       King       Rook       "
local puzzle196 = "Mukhit_Ismailov             Pavel_Potapov                 Tashkent                    2012  8/3R3p/2b4k/p1p1B1p1/2n2PB1/3p1P2/P7/6K1                   White      Bg7+       Kg6        f5#        Bishop     King       Pawn       "
local puzzle197 = "Aleksej_Aleksandrov         Misraddin_Iskandarov          Nakhchivan                  2012  6k1/1p5p/3P3r/4p3/2N1PBpb/PPr5/3R1P1K/5b1R                 Black      Bxf2+      Bxh6       Rh3#       Bishop     Bishop     Rook       "
local puzzle198 = "Aleksa_Strikovic            Jasem_Alhuwar                 Paris                       2012  8/4n2k/b1Pp2p1/3Ppp1p/p2qP3/3B1P2/Q2NK1PP/3R4              Black      Bxd3+      Ke1        Qe3#       Bishop     King       Queen      "
local puzzle199 = "David_Howell                Aljoscha_Feuerstack           Germany                     2012  k2r4/ppRn2p1/6p1/1P3p2/3p1B2/6P1/P4PBP/4n1K1               White      Bxb7+      Kb8        Rxd7#      Bishop     King       Rook       "
local puzzle200 = "Alexander_Motylev           David_Baramidze               Germany                     2012  4rk2/1bq2p1Q/3p1bp1/1p1n2N1/4PB2/2Pp3P/1P1N4/5RK1          White      Bxd6+      Qe7        Qxf7#      Bishop     Queen      Queen      "
local puzzle201 = "Teodora_Rogozenco           Marina_Gabriel                Germany                     2012  8/R7/pp1b2kp/1b1B1p2/5P1P/5KP1/P7/8                        White      h5+        Kxh5       Bf7#       Pawn       King       Bishop     "
local puzzle202 = "Hendrik_Kues                Twan_Burg                     Germany                     2012  2b3k1/6p1/p2bp2r/1p1p4/3Np1B1/1PP1PRq1/P1R3P1/3Q2K1        Black      Rh1+       Kxh1       Qh2#       Rook       King       Queen      "
local puzzle203 = "Pavel_Tregubov              Krishnan_Sasikiran            Moscow                      2013  6k1/p2p2p1/8/3np1N1/1P5R/3q2P1/5RKP/8                      White      Rh8+       Kxh8       Rf8#       Rook       King       Rook       "
local puzzle204 = "Danny_Raznikov              Zdenko_Kozul                  Skopje                      2013  2r3k1/3b2b1/5pp1/3P4/pB2P3/2NnqN2/1P2B2Q/5K1R              Black      Bh3+       Qg2        Qf2#       Bishop     Queen      Queen      "
local puzzle205 = "Martin_Zumsande             Rainer_Polzin                 Germany                     2013  n3r1k1/Q4R1p/p5pb/1p2p1N1/1q2P3/1P4PB/2P3KP/8              White      Rf8+       Qxf8       Qxh7#      Rook       Queen      Queen      "
local puzzle206 = "Michal_Olszewski            Mladen_Palac                  Bratto                      2013  2r5/2k4p/1p2pp2/1P2qp2/8/Q5P1/4PP1P/R5K1                   White      Qe7+       Kb8        Qa7#       Queen      King       Queen      "
local puzzle207 = "Gudmundur_Kjartansson       Sergey_Fedorchuk              Legnica                     2013  6k1/4q1b1/p1p1p1Q1/1r4N1/4p3/1P5R/5P2/7K                   White      Rh8+       Kxh8       Qh7#       Rook       King       Queen      "
local puzzle208 = "Jan_Musialkiewicz           Elina_Danielian               Legnica                     2013  5rk1/pb2npp1/1pq4p/5p2/5B2/1B6/P2RQ1PP/2r1R2K              Black      Qxg2+      Qxg2       Rxe1#      Queen      Queen      Rook       "
local puzzle209 = "Miodrag_Perunovic           Alexey_Kislinsky              Legnica                     2013  6k1/2R1Qpb1/3Bp1p1/1p2n2p/3q4/1P5P/2N2PPK/r7               Black      Qf4+       g3         Qxf2#      Queen      Pawn       Queen      "
local puzzle210 = "Antonios_Xylogiannopoulos   Alexandru_Manea               Legnica                     2013  6k1/pp3p2/2p2np1/2P1pbqp/P3P3/2N2nP1/2Pr1P2/1RQ1RB1K       Black      Qxg3       fxg3       Rh2#       Queen      Pawn       Rook       "
local puzzle211 = "Vlad-Cristian_Jianu         Burak_Firat                   Legnica                     2013  6k1/p2rR1p1/1p1r1p1R/3P4/4QPq1/1P6/P5PK/8                  White      Rh8+       Kxh8       Re8#       Rook       King       Rook       "
local puzzle212 = "Hichem_Hamdouchi            Samy_Shoker                   Haguenau                    2013  7R/1bpkp3/p2pp3/3P4/4B1q1/2Q5/4NrP1/3K4                    White      Qc6+       Bxc6       dxc6#      Queen      Bishop     Pawn       "
local puzzle213 = "Sasa_Martinovic             Vitezslav_Rasik               Meissen                     2013  1r3r1k/qp5p/3N4/3p2Q1/p6P/P7/1b6/1KR3R1                    White      Qg8+       Rxg8       Nf7#       Queen      Rook       Knight     "
local puzzle214 = "Alexander_Areshchenko       Sergei_Zhigalko               Kiev                        2013  r3k2r/p3bpp1/2q1p1b1/1ppPP1B1/3n3P/5NR1/PP2NP2/K1QR4       Black      Nb3+       axb3       Qa6#       Knight     Pawn       Queen      "
local puzzle215 = "Aleksei_Pridorozhni         Yuriy_Kuzubov                 Voronezh                    2013  1r5k/3b3p/3p3b/2qPp3/Pnp4P/Q1N5/8/K5RR                     Black      Nc2+       Ka2        Qxa3#      Knight     King       Queen      "
local puzzle216 = "Tigran_Kotanjian            Tigran_L._Petrosian           Jermuk                      2013  1k1r4/pp5R/2p5/P5p1/7b/4Pq2/1PQ2P2/3NK3                    Black      Rxd1+      Qxd1       Qxf2#      Rook       Queen      Queen      "
local puzzle217 = "Maria_Kursova               Tijana_Blagojevic             Belgrade                    2013  1r3k2/4R3/1p4Pp/p1pN1p2/2Pn1K2/1P6/1P6/8                   White      g7+        Kg8        Nf6#       Pawn       King       Knight     "
local puzzle218 = "Olena_Martynkova            Deimante_Daulyte              Belgrade                    2013  5bk1/R4p1p/6p1/8/3p2K1/1Q4P1/1P3P1q/2r5                    Black      Qh5+       Kf4        Qf5#       Queen      King       Queen      "
local puzzle219 = "Ekaterini_Pavlidou          Bojana_Bejatovic              Belgrade                    2013  3rr2k/pp1b2b1/4q1pp/2Pp1p2/3B4/1P2QNP1/P6P/R4RK1           White      Qxh6+      Kg8        Qxg7#      Queen      King       Queen      "
local puzzle220 = "Cristina_Adela_Foisor       Maja_Velickovski-Kostic       Belgrade                    2013  3r2k1/6pp/1nQ1R3/3r4/3N2q1/6N1/n4PPP/4R1K1                 White      Re8+       Kf7        R1e7#      Rook       King       Rook       "
local puzzle221 = "Ana_Srebrnic                Laura_Rogule                  Belgrade                    2013  5bk1/6p1/5PQ1/pp4Pp/2p4P/P2r4/1PK5/8                       White      f7+        Kh8        Qxh5#      Pawn       King       Queen      "


* Load puzzle data set 
if "$chesspuzzle_seed" == "" { // if the seed is not set, you will start with the same puzzle every time Stata is relaunched
	global chesspuzzle_seed =  clock(c(current_time), "hms") 
	set seed $chesspuzzle_seed
}

local nr = runiformint(1, 221)



* Parse puzzle infomation
* Extract from randomly drawn local
tokenize `puzzle`nr''
local white	= 	 subinstr("`1'", "_", " ", .)
local black	= 	 subinstr("`2'", "_", " ", .)
local place	=	 subinstr("`3'", "_", " ", .)
local year				= "`4'"
local pos				= "`5'"
local whotomove			= "`6'"
local move1				= "`7'"
local response1			= "`8'"
local move2				= "`9'"
local piecetomove1		= "`10'"
local piecetoresponse1	= "`11'"
local piecetomove2		= "`12'"

** Generate verbal answer
foreach x in move1 reponse1 move2 {
	local `x'_long = cond(strpos("``x''", "x"), ///
				  `"`pieceto`x'' to `=ustrregexra("``x''", ".+x", "")'"', ///
				  `"`pieceto`x'' to `=substr("``x''", 2, 2)'"')
	local `x'_long = ustrregexra("``x'_long'", "[+#]", "", .)				  
}

** Generate verbose answer
foreach x in move1 response1 move2 {
	local `x'_verbose = cond(strpos("``x''", "x"), ///
				  `"`pieceto`x'' takes on `=ustrregexra("``x''", ".+x", "")'"', ///
				  `"`pieceto`x'' to `=substr("``x''", 2, 2)'"')
	local `x'_verbose = subinstr("``x'_verbose'", "+", ", check", .)				  
	local `x'_verbose = subinstr("``x'_verbose'", "#", "", .)				  
}

** Generate messages
local prompt1	: display "This game was played by `white' and `black' in `place' in `year'."
local task		: display "It's mate in two and `whotomove' to move!"
local hint 		: display "I give you a hint. The `piecetomove1' strikes first."
local response	: display "Opponent responds with `response1' / `response1_verbose'."
local prompt2	: display "Try again? Type your solution into the command line."
local help		: display "(or {bf:help} if you want to get the correct answer or {bf:out} if you want to end the program)"
local correct	: display "C O R R E C T !"


* Begin prompt
dis as text "`prompt1'"
dis as text _newline "`task'"
	
*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
if "`whotomove'" == "Black" {
	chesspos `pos', black name(chesspuzzle, replace)
}
else {
	chesspos `pos', name(chesspuzzle, replace)
}
*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

display _newline(1) as text "Type your solution into to the command line below (whenever you're ready)."  _request(ans)



* Evaluate solution 1
local i = 1
while lower("$ans") != lower("`move1'") & lower("$ans") != lower("`move1_long'") {	
	if lower("$ans") == "out" {
		continue, break
	}
	if lower("$ans") != "help" & `i' == 1 {
		display _newline(1) in red "Sorry, that's not it."
		display as text "`hint'"
		display as text "Want to try again? Type your solution into the command line." _request(ans)
		local ++i
		continue
	}
	if lower("$ans") != "help" & `i' > 1 {
		display in red "Sorry, still wrong..."
		display as text "`prompt2'"
		display as text "`help'" _request(ans)
		local ++i
		continue
	}
	if lower("$ans") == "help" {
		display as text _newline "The first move is `move1' / `move1_verbose'."
		continue, break
	}

}
else {
	display _newline "`correct'"
}



* Evaluate solution 2
if lower("$ans") != "out" {
	display as text _newline(1) "`response'"
	display as text "What now?" _request(ans)

	while lower("$ans") != lower("`move2'") & lower("$ans") != lower("`move2_long'") {
		if lower("$ans") == "out" {
			continue, break
		}
		if lower("$ans") == "help" {
			display as text _newline "`whotomove' delivers mate with `move2' / `move2_verbose'."
			continue, break
		}
		display in red "Nope."
		display as text "`prompt2'" 
		display as text "`help'" _request(ans)
		
		}
		else {
			display _newline "`correct'"
		}
}	


* End Program
graph drop chesspuzzle
global ans = ""
dis as text _newline "{bf:chesspuzzle} out."

end
