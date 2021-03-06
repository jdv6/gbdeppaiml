### Setup
rm(list=ls())
windows <- Sys.info()[1][["sysname"]]=="Windows"
root <- ifelse(windows,"J:/","/home/j/")
user <- ifelse(windows, Sys.getenv("USERNAME"), Sys.getenv("USER"))
code.dir <- paste0(ifelse(windows, "H:", paste0("/homes/", user)), "/gbdeppaiml/")
## Packages
library(data.table); library(mvtnorm); library(survey); library(ggplot2); library(plyr)

## Arguments
args <- commandArgs(trailingOnly = TRUE)
print(args)
if(length(args) > 0) {
  run.name <- args[1]
  loc <- args[2]
  stop.year <- as.integer(args[3])
  i <- as.integer(Sys.getenv("SGE_TASK_ID"))
  paediatric <- as.logical(args[4])
} else {
	run.name <- "190318_group2"
	loc <- "NLD"
	stop.year <- 2019
	i <- 1
	paediatric <- FALSE
}

run.table <- fread('/share/hiv/epp_input/gbd19/eppasm_run_table.csv')
c.args <- run.table[run_name==run.name]
### Arguments
## Some arguments are likely to stay constant across runs, others we're more likely to test different options.
## The arguments that are more likely to vary are pulled from the eppasm run table
start.year <- 1970
trans.params.sub <- TRUE
pop.sub <- TRUE
art.sub <- TRUE
prev.sub <- TRUE
sexincrr.sub <- TRUE
plot.draw <- FALSE
anc.sub <- c.args[['anc_sub']]
anc.backcast <- c.args[['anc_backcast']]
age.prev <- c.args[['age_prev']]
popadjust <- c.args[['popadjust']]
anc.rt <- c.args[['anc_rt']]
epp.mod <- c.args[['epp_mod']]

### Paths
out.dir <- paste0('/ihme/hiv/epp_output/gbd19/', run.name, "/", loc)

### Functions
library(mortdb, lib = "/home/j/WORK/02_mortality/shared/r")
setwd(paste0(ifelse(windows, "H:", paste0("/homes/", user)), "/eppasm/"))
devtools::load_all()
setwd(code.dir)
devtools::load_all()

### Tables
loc.table <- fread(paste0('/share/hiv/epp_input/gbd19/', run.name, '/location_table.csv'))

### Code
## Read in spectrum object, sub in GBD parameters
dt <- read_spec_object(loc, i, start.year, stop.year, trans.params.sub, 
                       pop.sub, anc.sub, anc.backcast, prev.sub, art.sub, sexincrr.sub, popadjust, age.prev, paediatric, anc.rt)

if(epp.mod == 'rspline'){attr(dt, 'specfp')$equil.rprior <- TRUE}
if(age.prev == TRUE){attr(dt, 'specfp')$fitincrr <- 'linincrr'}

## Fit model
fit <- fitmod(dt, eppmod = epp.mod, B0=1e2, B=1e2, number_k  = 50)

## When fitting, the random-walk based models only simulate through the end of the
## data period. The `extend_projection()` function extends the random walk for r(t)
## through the end of the projection period.
if(epp.mod == 'rhybrid'){
  fit <- extend_projection(fit, proj_years = stop.year - start.year + 1)
}

## Simulate model for all resamples, choose a random draw, get gbd outputs
result <- gbd_sim_mod(fit, VERSION = 'R')
data.path <- paste0('/share/hiv/epp_input/gbd19/', run.name, '/fit_data/', loc, '.csv')
if(!file.exists(data.path)){
  save_data(loc, attr(dt, 'eppd'), run.name)
}
output.dt <- get_gbd_outputs(result, attr(dt, 'specfp'), paediatric = paediatric)
output.dt[,run_num := i]

## Write output to csv
dir.create(out.dir, showWarnings = FALSE)
write.csv(output.dt, paste0(out.dir, '/', i, '.csv'), row.names = F)

## under-1 splits
if(paediatric){
  split.dt <- get_under1_splits(result, attr(dt, 'specfp'))
  split.dt[,run_num := i]
  write.csv(split.dt, paste0(out.dir, '/under_1_splits_', i, '.csv' ), row.names = F)
}

## Write out theta for plotting posterior
param <- data.table(theta = attr(result, 'theta'))
write.csv(param, paste0(out.dir,'/theta_', i, '.csv'), row.names = F)

if(plot.draw){
  plot_15to49_draw(loc, output.dt, attr(dt, 'eppd'), run.name)
}