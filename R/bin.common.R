#' @import ggplot2
#' @import grid
#' @useDynLib binnr

#' @export
bin <- function(x, y, name, min.iv, min.cnt, max.bin, mono, exceptions){
  UseMethod("bin", x)
}

#' @export
bin.factory <- function(x, ...) {
  UseMethod("bin.factory")
}

#' @export
is.bin <- function(x) {
  inherits(x, "bin")
}

woe <- function(cnts, y) {
  if (length(cnts) == 0) return(matrix(nrow=0, ncol=2))
  ytot <- table(factor(y, levels=c(0,1)))
  pct0 <- cnts[,1]/ytot[1]
  pct1 <- cnts[,2]/ytot[2]
  woe <- log(pct1/pct0)
  woe[is.infinite(woe) | is.na(woe)] <- 0
  woe
}

cnts <- function(x, y) {
  tbl <- table(x, factor(y, levels=c(0,1)), useNA='ifany')
  if (sum(tbl) == 0) return(matrix(nrow = 0, ncol=2))
  out <- matrix(tbl, ncol=2)
  rownames(out) <- rownames(tbl)
  out
}

#' @export
as.data.frame.bin <- function(x, row.names = NULL, optional = FALSE, ...) {
  # create filters excluding NAs
  cnts <- do.call(rbind, x$core$counts)
  f <- !is.na(rownames(cnts)) # NAs aren't used for certain calculations
  tots <- apply(matrix(cnts[f,], ncol=2), 2, sum)
  
  # create pieces for output data.frame
  pcts <- t(apply(cnts, 1, '/',  tots))
  cnts <- cbind(cnts, apply(cnts, 1, sum))
  woe <- na.omit(unlist(x$core$values))
  ivs <- woe * (pcts[,2] - pcts[,1])
  prob <- cnts[,2] / cnts[,3]
  pcts[!f,] <- 0 # keep counts, but set NA pcts to zero
  out <- cbind(cnts, pcts, prob, woe, ivs)
  
  # row and column labels
  colnames(out) <- c("#0","#1","N","%0","%1","P(1)","WoE","IV")
  rownames(out)[f] <- sprintf("%2d. %s", seq(1, nrow(out[f,,drop=F])),
                              rownames(out[f,,drop=F]))
  rownames(out)[is.na(rownames(out))] <- "Missing"
  
  # total row
  total <- apply(out, 2, sum)
  total["P(1)"] <- total["#1"] / total["N"]
  
  # output
  out <- as.data.frame(rbind(out, Total=total))
  out
}

#' @export
print.bin <- function(x, ...) {
  out <- as.data.frame(x)
  iv <- out['Total', 'IV']
  fmts <- c(rep("%d",3), rep("%1.3f", 4), "%0.5f")
  
  for (i in seq_along(out)) { out[,i] <- sprintf(fmts[i], out[,i]) }
  
  status <- ifelse(x$skip, " *** DROPPED ***", "")
  cat(sprintf("\nIV: %0.5f | Variable: %s%s\n", iv, x$name, status))
  print(out)
  
  #print(as.data.frame.bin(x))
}

#' @export
`!=.bin` <- function(e1, e2) {
  # TODO: add bounds checking for NAs
  y <- e1$data$y
  zero <- unlist.matrix(e1, 1, e2)
  ones <- unlist.matrix(e1, 2, e2)
  counts <- mapply(cbind, zero, ones, SIMPLIFY = F)
  
  tots <- matrix(apply(rbind(counts$var, counts$exc), 2, sum), ncol=2)
  
  values <- e1$core$values
  values$var <- log((counts$var[,2]/tots[,2])/(counts$var[,1]/tots[,1]))
  values$exc <- log((counts$exc[,2]/tots[,2])/(counts$exc[,1]/tots[,1]))
  values <- lapply(values, function(x) {x[is.nan(x)] <- 0; x})
  b <- e1
  b$core$counts <- counts
  b$core$values <- values
  b$history <- e1
  b
}

unlist.matrix <- function(b, i, e2) {
  skeleton <- lapply(b$core$counts, function(x) x[,i])
  flesh <- unlist(skeleton)
  flesh[e2] <- 0
  relist(flesh, skeleton)
}

#' @export
reset <- function(b) {
  do.call(bin, c(list(x=b$data$x, y=b$data$y, name=b$name), b$opts))
}

#' @export
undo <- function(x) {
  if (is.null(x$history)) return(x)
  return(x$history)
}