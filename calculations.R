
dist_f <- function(a1, a2){
  return(abs( (a1 - a2) / 100 ))
}

w_f <- function(d, c) {
  return(1/c - d)
}

w_f_t <- function(d, c) {
  return(c*sum(w_f(d,c))/length(d))
}