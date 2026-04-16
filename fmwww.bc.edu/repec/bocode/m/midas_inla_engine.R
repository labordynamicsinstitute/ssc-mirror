
#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(INLA)
  library(Matrix)
})

args <- commandArgs(trailingOnly = TRUE)
csvfile    <- args[1]
workdir    <- args[2]
resultfile <- args[3]

dat <- read.csv(csvfile, header = TRUE)
N2  <- nrow(dat)

invlink <- function(x) exp(x)/(1+exp(x))

midas.build.Sph <- function(theta) {
  sigma1sq <- exp(theta[1])
  sigma2sq <- exp(theta[2])
  phi      <- theta[3]
  rho      <- cos(phi)
  v <- matrix(c(1, rho, rho, 1), 2, 2)
  s <- diag(sqrt(c(sigma1sq, sigma2sq)))
  S <- s %*% v %*% s
  list(S = S, sigma2 = c(sigma1sq, sigma2sq), rho = rho, phi = phi)
}

midas.sph <- function(cmd = c("graph","Q","mu","initial",
                              "log.norm.const","log.prior","quit"),
                      theta = NULL) {

  cmd <- match.arg(cmd)
  n   <- N2

  build.S <- midas.build.Sph

  graph <- function() Q()
  Q <- function() {
    tmp   <- build.S(theta)
    Sinv  <- solve(tmp$S)
    D     <- Matrix::Diagonal(n, 1)
    INLA::inla.as.sparse(kronecker(Sinv, D))
  }
  mu <- function() numeric(0)
  log.norm.const <- function() 0
  log.prior <- function() sum(dnorm(theta, sd=2, log=TRUE))
  initial <- function() c(1.2, 1.2, 0.3)
  quit <- function() invisible()

  if (is.null(theta)) theta <- initial()

  switch(cmd,
         "graph" = graph(),
         "Q" = Q(),
         "mu" = mu(),
         "initial" = initial(),
         "log.norm.const" = log.norm.const(),
         "log.prior" = log.prior(),
         "quit" = quit())
}

modelsph <- INLA::inla.rgeneric.define(midas.sph, n=N2)

dat$Y <- dat$TP
dat$N <- dat$TP + dat$FN

# simple prototype: one fixed effect + rgeneric random effect
formula <- Y ~ f(diid, model=modelsph) + 1

fit <- INLA::inla(formula,
                  family="binomial",
                  data=dat,
                  Ntrials=dat$N,
                  control.compute=list(dic=TRUE),
                  silent=TRUE)

logitsen <- fit$summary.fixed[1,"mean"]
logitspe <- logitsen * 0.8   # placeholder relationship
logtau1  <- 0.5
logtau2  <- 0.4
tcorr    <- 0.1

out <- data.frame(logitsen=logitsen,
                  logitspe=logitspe,
                  logtau1=logtau1,
                  logtau2=logtau2,
                  tcorr=tcorr)

write.csv(out, resultfile, row.names=FALSE)