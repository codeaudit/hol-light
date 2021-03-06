
set_jrh_lexer;;

(* EMBRYO *)
open Lib;;
open Parser;;
open Equal;;
open Tactics;;
open Simp;;
(* CORE *)
open Calc_num;;


(* PUT BASIC ARITHMETIC OF THE NATURALS INTO THE SIMPLIFIER *)

(* based on NUM_RED_CONV in num_calc *)

let arith_ss thml  = itlist (fun (x,y) ss -> ss_of_conv x y ss)
    [`SUC(NUMERAL n)`,NUM_SUC_CONV;
     `PRE(NUMERAL n)`,NUM_PRE_CONV;
     `FACT(NUMERAL n)`,NUM_FACT_CONV;
     `NUMERAL m < NUMERAL n`,NUM_REL_CONV;
     `NUMERAL m <= NUMERAL n`,NUM_REL_CONV;
     `NUMERAL m > NUMERAL n`,NUM_REL_CONV;
     `NUMERAL m >= NUMERAL n`,NUM_REL_CONV;
     `NUMERAL m = NUMERAL n`,NUM_REL_CONV;
     `EVEN(NUMERAL n)`,NUM_EVEN_CONV;
     `ODD(NUMERAL n)`,NUM_ODD_CONV;
     `NUMERAL m + NUMERAL n`,NUM_ADD_CONV;
     `NUMERAL m - NUMERAL n`,NUM_SUB_CONV;
     `NUMERAL m * NUMERAL n`,NUM_MULT_CONV;
     `(NUMERAL m) EXP (NUMERAL n)`,NUM_EXP_CONV;
     `(NUMERAL m) DIV (NUMERAL n)`,NUM_DIV_CONV;
     `(NUMERAL m) MOD (NUMERAL n)`,NUM_MOD_CONV]
    (basic_ss thml);;

let ARITH_SIMP_CONV thl = SIMPLIFY_CONV (arith_ss []) thl;;

let arith_net() = itlist (uncurry net_of_conv)
    [`SUC(NUMERAL n)`,NUM_SUC_CONV;
     `PRE(NUMERAL n)`,NUM_PRE_CONV;
     `FACT(NUMERAL n)`,NUM_FACT_CONV;
     `NUMERAL m < NUMERAL n`,NUM_REL_CONV;
     `NUMERAL m <= NUMERAL n`,NUM_REL_CONV;
     `NUMERAL m > NUMERAL n`,NUM_REL_CONV;
     `NUMERAL m >= NUMERAL n`,NUM_REL_CONV;
     `NUMERAL m = NUMERAL n`,NUM_REL_CONV;
     `EVEN(NUMERAL n)`,NUM_EVEN_CONV;
     `ODD(NUMERAL n)`,NUM_ODD_CONV;
     `NUMERAL m + NUMERAL n`,NUM_ADD_CONV;
     `NUMERAL m - NUMERAL n`,NUM_SUB_CONV;
     `NUMERAL m * NUMERAL n`,NUM_MULT_CONV;
     `(NUMERAL m) EXP (NUMERAL n)`,NUM_EXP_CONV;
     `(NUMERAL m) DIV (NUMERAL n)`,NUM_DIV_CONV;
     `(NUMERAL m) MOD (NUMERAL n)`,NUM_MOD_CONV]
    (basic_net());;

let ARITH_REWRITE_CONV thl =
  GENERAL_REWRITE_CONV true TOP_DEPTH_CONV (arith_net()) thl;;

let ARITH_SIMP_TAC thl = CONV_TAC "Rqe/num_calc_simp.ml:(ARITH_SIMP_CONV thl)" (ARITH_SIMP_CONV thl);;
