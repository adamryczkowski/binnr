#include "R.h"
#include "stdio.h"
#include "variable.h"
#include "queue.h"
#include "xtab.h"
#include "bin.h"
 
#define RETURN_R 

// called from R and handles passing of data to and from 
SEXP bin(SEXP x, SEXP y, SEXP miniv, SEXP mincnt, SEXP maxbin, SEXP monotonicity) {
  
  double *dx = REAL(x), *dy = REAL(y);
  
  struct variable* v = variable_factory(dx, LENGTH(x));
  struct xtab* xtab = xtab_factory(v, dy); // create the xtab
  
  struct queue* q = queue_factory(); // create the queue
  struct work w = {0, xtab->size - 1}; // last index is one less than the size
  enqueue(q, w);
  
  // create a vector to store the split rows and init to zero
  size_t* breaks = calloc(xtab->size, sizeof(size_t));
  int num_bins = 1;
  
  // TODO: replace with function -- calculate totals where not missing
  double* grand_tots = get_xtab_totals(xtab, 0, xtab->size);
  
  // fille options structure
  struct opts opts;
  opts.max_bin = *INTEGER(maxbin);
  opts.min_cnt = *INTEGER(mincnt);
  opts.min_iv = *REAL(miniv);
  opts.mono = *INTEGER(monotonicity);

  // bin the variable until it's done
  while(!is_empty(q)) {
    struct work w = dequeue(q); // take work from queue
    size_t split = find_best_split(w.start, w.stop, xtab, grand_tots, opts);
    
    if ((split != -1) & (num_bins < opts.max_bin)) { // split found!
      num_bins++;
      breaks[split] = 1; // update breaks array
      struct work w1 = {w.start, split};
      struct work w2 = {split + 1, w.stop};
      enqueue(q, w1); // add work to queue
      enqueue(q, w2);
    }
  }

  // return breaks in an R object
#ifdef RETURN_R
  SEXP r_brk = PROTECT(allocVector(REALSXP, num_bins + 1));
  size_t j = 0;
  REAL(r_brk)[0] = R_NegInf;
  for(size_t i = 0; i < xtab->size; i++) {
    if (breaks[i] == 1) {
      j++;
      REAL(r_brk)[j] = xtab->values[i];
    }
  }
#endif 
  
  // Release resources
  release_variable(v);
  release_xtab(xtab);
  release_queue(q);
  free(breaks);
  
#ifdef RETURN_R 
  UNPROTECT(1);
  return r_brk;
#endif
  
  return R_NilValue;
}

size_t find_best_split(int start, int stop, struct xtab* xtab, double* grand_tot, struct opts opts) {
  
  double* tot = get_xtab_totals(xtab, start, stop + 1);
  double asc_cnts[2] = {0};
  double dsc_cnts[2] = {0};
  double best_iv = -1;
  int valid = 0;
  size_t best_split_idx = -1;

  for (size_t i = start; i <= stop; i++) {
    valid = 0;
    
    asc_cnts[0] += xtab->zero_ct[i];
    asc_cnts[1] += xtab->ones_ct[i];
    
    dsc_cnts[0] = tot[0] - asc_cnts[0];
    dsc_cnts[1] = tot[1] - asc_cnts[1];
    
    struct iv iv = calc_iv(asc_cnts, dsc_cnts, grand_tot);
    int woe_sign = (iv.asc_woe > iv.dsc_woe) ? 1 : -1;
    
    if ((asc_cnts[0] + asc_cnts[1]) < opts.min_cnt) { // minsplit
      valid = -1;
    } else if ((dsc_cnts[0] + dsc_cnts[1]) < opts.min_cnt) { // minsplit
      valid = -1;
    } else if (iv.iv < opts.min_iv) { // min iv
      valid = -1;
    } else if (isinf(iv.iv)) { // infinite iv
      valid = -1;
    } else if (opts.mono != 0) {
      if (woe_sign != opts.mono) {
        valid = -1;
      }
    }

    if ((valid != -1) & (iv.iv > best_iv)) {
      best_iv = iv.iv;
      best_split_idx = i;
    }
  }
  
  free(tot);
  return best_split_idx;
}

struct iv calc_iv(double* asc_cnts, double* dsc_cnts, double* tots) {
  struct iv iv = {0};
  iv.asc_woe = log((asc_cnts[0]/tots[0])/(asc_cnts[1]/tots[1]));
  iv.dsc_woe = log((dsc_cnts[0]/tots[0])/(dsc_cnts[1]/tots[1]));
  
  double asc_iv  = iv.asc_woe * (asc_cnts[0]/tots[0] - asc_cnts[1]/tots[1]);
  double dsc_iv  = iv.dsc_woe * (dsc_cnts[0]/tots[0] - dsc_cnts[1]/tots[1]);
  iv.iv = asc_iv + dsc_iv;
  
  return iv;
}

double calc_sv_woe(double* dx, double* dy, int size, double value, double* tots) {
  double ones_ct = 0, zero_ct = 0;
  for (size_t i = 0; i < size; i++) {
    if (dx[i] == value) {
        zero_ct += (dy[i] == 0);
        ones_ct += (dy[i] == 1);
    }
  }
  return(log((ones_ct/tots[1])/(zero_ct/tots[0])));
}