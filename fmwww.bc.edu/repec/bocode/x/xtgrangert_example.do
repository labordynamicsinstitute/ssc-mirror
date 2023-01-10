xtset cert time
xtgrangert roa inefficiency quality, maxlags(4) het
xtgrangert roa inefficiency, maxlags(4) het
xtgrangert roa quality, maxlags(4) het
xtgrangert roa inefficiency quality, maxlags(4) het sum, if cluster==2 & time>20
xtgrangert roa inefficiency quality, bootstrap
xtgrangert roa inefficiency quality, bootstrap(200, seed(123))
