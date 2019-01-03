#' Plot results of EPPASM
#'
#' @param output model output
#' @param eppd data input to eppasm
#'
plot_15to49_draw<- function(loc, output, eppd, run.name, compare.run = '180702_numbat_combined'){
  ## Get data used in fitting model
  ## TODO: call save_data somewhere else
  data <- fread(paste0('/share/hiv/epp_input/gbd19/', run.name, '/fit_data/', loc, '.csv'))
  data <- data[agegr == '15-49']
  data[, c('agegr', 'sex') := NULL]

  ## Comparison run
  if(file.exists(paste0('/snfs1/WORK/04_epi/01_database/02_data/hiv/spectrum/summary/', compare.run, '/locations/', loc, '_spectrum_prep.csv'))){
    compare.dt <- fread(paste0('/snfs1/WORK/04_epi/01_database/02_data/hiv/spectrum/summary/', compare.run, '/locations/', loc, '_spectrum_prep.csv'))
    compare.dt <- compare.dt[age_group_id == 24 & sex_id == 3 & measure %in% c('Incidence', 'Prevalence') & metric == 'Rate']
    compare.dt <- compare.dt[,.(type = 'line', year = year_id, indicator = measure, model = ifelse(compare.run == '180702_numbat_combined', 'GBD2017', compare.run), mean, lower, upper)]
  } else{
    compare.dt <- NULL
  }
  cur.dt <- get_summary(output)
  cur.dt <- cur.dt[age_group_id == 24 & sex == 'both' & measure %in% c('Incidence', 'Prevalence') & metric == 'Rate',.(type = 'line', year, indicator = measure, model = run.name, mean, lower = NA, upper = NA)]
  
  plot.dt <- rbind(data, compare.dt, cur.dt, use.names = T)
  plot.dt[,model := factor(model)]
  color.list <- c('blue', 'red')
  names(color.list) <- c(run.name, ifelse(compare.run == '180702_numbat_combined', 'GBD2017', compare.run))
  
  pdf(paste0('/ihme/hiv/epp_output/gbd19/', run.name, "/", loc, '/', i, '.pdf'), width = 10, height = 6)
  gg <- ggplot()
    if(nrow(plot.dt[model == 'ANC Site']) > 0){
      gg <- gg + geom_point(data = plot.dt[model == 'ANC Site'], aes(x = year, y = mean, shape = 'ANC Site'), alpha = 0.2)
    }
    gg <- gg + geom_line(data = plot.dt[type == 'line'], aes(x = year, y = mean, color = model)) +
      geom_ribbon(data = plot.dt[type == 'line'], aes(x = year, ymin = lower, ymax = upper,  fill = model), alpha = 0.2) +
      facet_wrap(~indicator, scales = 'free_y') +
      theme_bw() +
      scale_fill_manual(values=color.list) + scale_colour_manual(values=color.list)  +
      xlab("Year") + ylab("Mean") + ggtitle(paste0(loc.table[ihme_loc_id == loc, plot_name], ' EPPASM Results'))
    if(nrow(plot.dt[model == 'Household Survey']) > 0){
      gg <- gg + geom_point(data = plot.dt[model == 'Household Survey'], aes(x = year, y = mean, shape = 'Household Survey'))
      gg <- gg + geom_errorbar(data = plot.dt[model == 'Household Survey'], aes(x = year, ymin = lower, ymax = upper))
    }
    
  print(gg)
  dev.off()
}

plot_15to49 <- function(loc, run.name, compare.run = '180702_numbat_combined'){
  data <- fread(paste0('/share/hiv/epp_input/gbd19/', run.name, '/fit_data/', loc, '.csv'))
  data <- data[agegr == '15-49']
  data[, c('agegr', 'sex') := NULL]
  ## Comparison run
  compare.dt <- fread(paste0('/snfs1/WORK/04_epi/01_database/02_data/hiv/spectrum/summary/', compare.run, '/locations/', loc, '_spectrum_prep.csv'))
  compare.dt <- compare.dt[age_group_id == 24 & sex_id == 3 & measure %in% c('Incidence', 'Prevalence', 'Deaths') & metric == 'Rate']
  compare.dt <- compare.dt[,.(type = 'line', year = year_id, indicator = measure, model = ifelse(compare.run == '180702_numbat_combined', 'GBD2017', compare.run), mean, lower, upper)]
  
  cur.dt <- fread(paste0('/share/hiv/epp_output/gbd19/', run.name, '/compiled/', loc, '.csv'))
  cur.dt <- get_summary(cur.dt)
  cur.dt <- cur.dt[age_group_id == 24 & sex == 'both' & measure %in% c('Incidence', 'Prevalence', 'Deaths') & metric == 'Rate',.(type = 'line', year, indicator = measure, model = run.name, mean, lower, upper)]
  
  plot.dt <- rbind(data, compare.dt, cur.dt, use.names = T)
  plot.dt[,model := factor(model)]
  color.list <- c('blue', 'red')
  names(color.list) <- c(run.name, ifelse(compare.run == '180702_numbat_combined', 'GBD2017', compare.run))
  
  pdf(paste0('/ihme/hiv/epp_output/gbd19/', run.name, '/15to49_plots/', loc, '.pdf'), width = 10, height = 6)
  gg <- ggplot()
    if(nrow(plot.dt[model == 'ANC Site']) > 0){
      gg <- gg + geom_point(data = plot.dt[model == 'ANC Site'], aes(x = year, y = mean, shape = 'ANC Site'), alpha = 0.2)
    }
    gg <- gg + geom_line(data = plot.dt[type == 'line'], aes(x = year, y = mean, color = model)) +
    geom_ribbon(data = plot.dt[type == 'line'], aes(x = year, ymin = lower, ymax = upper,  fill = model), alpha = 0.2) +
    facet_wrap(~indicator, scales = 'free_y') +
    theme_bw() +
    scale_fill_manual(values=color.list) + scale_colour_manual(values=color.list)  +
    xlab("Year") + ylab("Mean") + ggtitle(paste0(loc.table[ihme_loc_id == loc, plot_name], ' EPPASM Results'))
    if(nrow(plot.dt[model == 'Household Survey']) > 0){
      gg <- gg + geom_point(data = plot.dt[model == 'Household Survey'], aes(x = year, y = mean, shape = 'Household Survey'))
      gg <- gg + geom_errorbar(data = plot.dt[model == 'Household Survey'], aes(x = year, ymin = lower, ymax = upper))
    }

  print(gg)
  dev.off()
}

plot_age_specific <- function(loc, run.name, compare.run = '180702_numbat_combined'){
  data <- fread(paste0('/share/hiv/epp_input/gbd19/', run.name, '/fit_data/', loc, '.csv'))
  data <- data[!agegr == '15-49']
  setnames(data, 'agegr', 'age')
  
  ## Comparison run
  compare.dt <- fread(paste0('/snfs1/WORK/04_epi/01_database/02_data/hiv/spectrum/summary/', compare.run, '/locations/', loc, '_spectrum_prep.csv'))
  compare.dt <- compare.dt[!age_group_id > 21 & !age_group_id < 6 & !sex_id == 3 & measure %in% c('Incidence', 'Prevalence', 'Deaths') & metric == 'Rate']
  age.map <- fread('/share/hiv/spectrum_prepped/age_map.csv')
  compare.dt <- merge(compare.dt, age.map[,.(age_group_id,age = age_group_name_short)], by = 'age_group_id')
  compare.dt <- compare.dt[,.(age, sex = ifelse(sex_id == 1, 'male', 'female'), type = 'line', year = year_id, 
                              indicator = measure, model = ifelse(compare.run == '180702_numbat_combined', 'GBD2017', compare.run), mean, lower, upper)]
  
  cur.dt <- fread(paste0('/share/hiv/epp_output/gbd19/', run.name, '/compiled/', loc, '.csv'))
  cur.dt <- get_summary(cur.dt)
  cur.dt <- cur.dt[!age_group_id %in%c(24, 22) & !sex == 'both' & measure %in% c('Incidence', 'Prevalence', 'Deaths') & metric == 'Rate',
                   .(age, sex, type = 'line', year, indicator = measure, model = run.name, mean, lower, upper)]
  
  both.dt <- rbind(data, compare.dt, cur.dt, use.names = T)
  both.dt[,model := factor(model)]
  color.list <- c('blue', 'red')
  names(color.list) <- c(run.name, ifelse(compare.run == '180702_numbat_combined', 'GBD2017', compare.run))
  ## TODO: age_group_name rather than age?
  both.dt[,age := factor(age, levels=paste0(seq(5, 80, 5)))]
  
  for(c.indicator in c('Incidence', 'Prevalence', 'Deaths')){
    pdf(paste0('/ihme/hiv/epp_output/gbd19/', run.name, '/age_specific_plots/', c.indicator, '/', loc, '.pdf'), width = 10, height = 6)
    for(c.sex in c('male', 'female')){
      plot.dt <- both.dt[sex == c.sex & indicator == c.indicator]
      gg <- ggplot()
      if(nrow(plot.dt[model == 'ANC Site']) > 0){
        gg <- gg + geom_point(data = plot.dt[model == 'ANC Site'], aes(x = year, y = mean, shape = 'ANC Site'), alpha = 0.2)
      }
      gg <- gg + geom_line(data = plot.dt[type == 'line'], aes(x = year, y = mean, color = model)) +
        geom_ribbon(data = plot.dt[type == 'line'], aes(x = year, ymin = lower, ymax = upper,  fill = model), alpha = 0.2) +
        facet_wrap(~age, scales = 'free_y') +
        theme_bw() +
        scale_fill_manual(values=color.list) + scale_colour_manual(values=color.list)  +
        xlab("Year") + ylab("Mean") + ggtitle(paste0(loc.table[ihme_loc_id == loc, plot_name], ' EPPASM Results'))
      if(nrow(plot.dt[model == 'Household Survey']) > 0){
        gg <- gg + geom_point(data = plot.dt[model == 'Household Survey'], aes(x = year, y = mean, shape = 'Household Survey'))
        gg <- gg + geom_errorbar(data = plot.dt[model == 'Household Survey'], aes(x = year, ymin = lower, ymax = upper))
      }
      
      print(gg)
    }
    dev.off()
  }
}