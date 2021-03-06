# R function to calculate predicted probabilities for 
# "observed" cases after a Bayesian logit or probit model ,
# following Hanmer & Kalkan (2013)
# Johannes Karreth

###########################################
# NOTE: This function is not fully tested
# Use with caution! Feedback appreciated.
###########################################

# For an explanation of predicted probabilities for "average" cases,
# see Hanmer & Kalkan (2013)
# doi: 10.1111/j.1540-5907.2012.00602.x

# model_matrix: model matrix, including intercept. Create with model.matrix(formula, data)
# mcmc_out: posterior distributions of all coefficients
#   in matrix form - can easily be created from rstan, MCMCpack, R2jags, R2OpenBUGS, etc.
# x_col: column number of the explanatory variable for which to calculate associated Pr(y = 1)
# x_range_vec: name of the vector with the range of relevant values of the 
#   explanatory variable for which to calculate associated Pr(y = 1)
# link: link function, character vector set to "logit" (default) or "probit"
# lower: lower percentile (default: 5th) for credible interval of predicted probabilities
# upper: upper percentile (default: 95th) for credible interval of predicted probabilities

# Output: a matrix with 4 columns:
# predictor: identical to x_range
# median_pp: median predicted probability at given x
# lower_pp: lower bound of credible interval of predicted probability at given x
# upper_pp: upper bound of credible interval of predicted probability at given x

MCMC_observed_probs <- function(model_matrix, mcmc_out, x_col, x_range_vec, link = "logit", lower = 0.05, upper = 0.95){
  
  X <- matrix(rep(t(model_matrix), length(x_range_vec)), 
              ncol = ncol(model_matrix), byrow = TRUE )
  X[, x_col] <- sort(rep(x_range_vec, times = nrow(X) / length(x_range_vec)))
  
  if(link == "logit"){
    logit_linpred <- t(X %*% t(mcmc_out))
    logit_pp <- exp(logit_linpred) / (1 + exp(logit_linpred)) # still seems fine
    pp <- logit_pp
  }
  
  if(link == "probit"){
    pp <- pnorm(t(X %*% t(mcmc_out)))
  }
  
  
  # emptry matrix for PPs
  pp_mat <- matrix(NA, nrow = nrow(mcmc_out), ncol = length(x_range_vec))
  
  # indices
  pp_mat_lowerindex <- 1 + (0:(length(x_range_vec) - 1) * nrow(model_matrix))
  pp_mat_upperindex <- nrow(model_matrix) + (0:(length(x_range_vec) - 1) * nrow(model_matrix))
  
  
  # fill matrix with PPs, one for each value of the predictor of interest
  for(i in 1:length(x_range_vec)){
    pp_mat[, i] <- apply(X = pp[, c(pp_mat_lowerindex[i]:pp_mat_upperindex[i])], MARGIN = 1, FUN = function(x) mean(x))
  }
  
  median_pp <- apply(X = pp_mat, MARGIN = 2, function(x) quantile(x, probs = c(0.5)))
  lower_pp <- apply(X = pp_mat, MARGIN = 2, function(x) quantile(x, probs = c(lower)))
  upper_pp <- apply(X = pp_mat, MARGIN = 2, function(x) quantile(x, probs = c(upper)))
  
  pp_dat <- data.frame(predictor = x_range_vec,
                       median_pp = median_pp,
                       lower_pp = lower_pp,
                       upper_pp = upper_pp)
  
  return(pp_dat)
}