set_jrh_lexer;;
open Lib;;
open Fusion;;
open Tactics;;
open Equal;;
open Theorem_fingerprint;;

module Parse : sig
  val parse : string -> tactic
end =
struct
  type data = string * int
  type env = thm list
  let empty (s, i) = i >= String.length s
  let str_of_data (d : data) = Printf.sprintf ":%d" (snd d)
  exception Pop_failure
  let pop (s, i) w =
    let ls, lw = String.length s, String.length w in
    if i + lw <= ls && String.sub s i lw = w && (
      i + lw = ls || s.[i + lw] = ' ')
    then (s, i + lw + 1) else raise Pop_failure
  let pop_word (s, i) =
    let j = try
      String.index_from s i ' '
    with Not_found -> String.length s in
    (String.sub s i (j-i), (s, j+1))

  type 'a parser = env -> data -> 'a * data
  let apply abp ap (e : env) (d : data) =
    let (ab, d1) = abp e d in let (a, d2) = ap e d1 in (ab a, d2)
  let const a (e : env) (d : data) = (a, d)
  let fail d want got = failwith (
    Printf.sprintf "Parse failure at %s: expected %s but found %s"
    (str_of_data d) want got)
  let check_end d want =
    if empty d then fail d want "end of input" else ()
  let fn v c = c (const v)
  let applyc abp ap c = c (apply abp ap)

  let listparser ap (e : env) (d : data) =
    let rec get_a l d1 =
      let a, d2 = ap e d1 in
      let l1, (w, d3) = a::l, pop_word d2 in
      if w = "]" then
        (List.rev l1, d3)
      else if w = ";" then
        get_a l1 d3
      else fail d2 "] or ;" w in
    let w, d1 = pop_word d in
    if w = "[" then
      try
        let d2 = pop d1 "]" in ([], d2)
      with Pop_failure -> get_a [] d1
    else fail d "[" w

  let add_new h k v =
    try
      let _ = Hashtbl.find h k in
      failwith ("Key '"^k^"' already exists")
    with Not_found -> Hashtbl.add h k v
  let keyword_parser typename =
    let h = Hashtbl.create 1000 in
    let add_word (p, w) = add_new h w (p I) in
    let add_words = List.iter add_word in
    let parse e d =
      check_end d typename;
      let (w, d1) = pop_word d in
      try
        let p = Hashtbl.find h w in (p e d1)
      with Not_found -> fail d typename w in
    (parse, add_words)

  let (thp : thm parser), add_th = keyword_parser "thm"
  let (tcp : tactic parser), add_tc = keyword_parser "tactic"
  let (convp : conv parser), add_conv = keyword_parser "conv"
  let (convfnp : (conv -> conv) parser), add_convfn = keyword_parser "convfn"

  let (intp : int parser) = fun e d ->
    check_end d "int";
    let (w, d1) = pop_word d in
    (int_of_string w, d1)
  let (tmp : term parser) =
    let delim = '`' in
    fun e (s, i) ->
      check_end (s, i) "term";
      if s.[i] != delim then
        fail (s, i) "`" (String.sub s i 1)
      else
        let j = try
          String.index_from s (i+1) delim
        with Not_found ->
          fail (s, i) "matching `" "end of input" in
        let tm = String.sub s (i+1) (j-i-1) in
        (Parser.decode_term tm, (s, j+2))

  let th p = applyc p thp
  let thl p c = applyc p (listparser thp) c
  let conv p c = applyc p convp c
  let convfn p c = applyc p convfnp c
  let convfnl p c = applyc p (listparser convfnp) c
  let tm p c = applyc p tmp c
  let tmtm p c = applyc p (fn (curry I) tm tm I) c
  let n p c = applyc p intp c
  let assum (e : env) (d : data) = (List.nth e, d)

  let () = add_th [
    n assum, "ASSUM";
  ]

  let () = add_tc [
    fn ABS_TAC, "ABS_TAC";
    fn ACCEPT_TAC th, "ACCEPT_TAC";
    fn ANTS_TAC, "ANTS_TAC";
    fn Ints.ARITH_TAC, "ARITH_TAC";
    fn Meson.ASM_MESON_TAC thl, "ASM_MESON_TAC";
    fn Metis.ASM_METIS_TAC thl, "ASM_METIS_TAC";
    fn Ind_defs.BACKCHAIN_TAC th, "BACKCHAIN_TAC";
    fn CHEAT_TAC, "CHEAT_TAC";
    fn CHOOSE_TAC th, "CHOOSE_TAC";
    fn CONJ_TAC, "CONJ_TAC";
    fn CONTR_TAC th, "CONTR_TAC";
    fn (CONV_TAC " ") conv, "CONV_TAC";
    fn DISCH_TAC, "DISCH_TAC";
    fn DISJ1_TAC, "DISJ1_TAC";
    fn DISJ2_TAC, "DISJ2_TAC";
    fn DISJ_CASES_TAC th, "DISJ_CASES_TAC";
    fn EQ_TAC, "EQ_TAC";
    fn EXISTS_TAC tm, "EXISTS_TAC";
    fn GEN_TAC, "GEN_TAC";
    fn (Simp.GEN_REWRITE_TAC " ") convfn thl, "GEN_REWRITE_TAC";
    fn Itab.ITAUT_TAC, "ITAUT_TAC";
    fn MATCH_ACCEPT_TAC th, "MATCH_ACCEPT_TAC";
    fn MATCH_MP_TAC th, "MATCH_MP_TAC";
    fn Meson.MESON_TAC thl, "MESON_TAC";
    fn MK_COMB_TAC, "MK_COMB_TAC";
    fn MP_TAC th, "MP_TAC";
    fn Simp.ONCE_REWRITE_TAC thl, "ONCE_REWRITE_TAC";
    fn Simp.PURE_ONCE_REWRITE_TAC thl, "PURE_ONCE_REWRITE_TAC";
    fn Simp.PURE_REWRITE_TAC thl, "PURE_REWRITE_TAC";
    fn RAW_CONJUNCTS_TAC th, "RAW_CONJUNCTS_TAC";
    fn RAW_POP_ALL_TAC, "RAW_POP_ALL_TAC";
    fn RAW_POP_TAC n, "RAW_POP_TAC";
    fn RAW_SUBGOAL_TAC tm, "RAW_SUBGOAL_TAC";
    fn Calc_rat.REAL_ARITH_TAC, "REAL_ARITH_TAC";
    fn Reals.REAL_ARITH_TAC, "REAL_ARITH_TAC2";
    fn REFL_TAC, "REFL_TAC";
    fn Simp.REWRITE_TAC thl, "REWRITE_TAC";
    fn Simp.SIMP_TAC thl, "SIMP_TAC";
    fn SPEC_TAC tmtm, "SPEC_TAC";
    fn SUBST1_TAC th, "SUBST1_TAC";
    fn TRANS_TAC th tm, "TRANS_TAC";
    fn UNDISCH_TAC tm, "UNDISCH_TAC";
    fn X_CHOOSE_TAC tm th, "X_CHOOSE_TAC";
    fn X_GEN_TAC tm, "X_GEN_TAC";
  ]
  let () = add_conv [
    fn BETA_CONV, "BETA_CONV";
    fn Class.CONTRAPOS_CONV, "CONTRAPOS_CONV";
    fn Pair.GEN_BETA_CONV, "GEN_BETA_CONV";
    fn Calc_num.NUM_REDUCE_CONV, "NUM_REDUCE_CONV";
    fn Calc_rat.REAL_RAT_REDUCE_CONV, "REAL_RAT_REDUCE_CONV";
    fn SYM_CONV, "SYM_CONV";
    fn I convfn conv, "APPLY";
  ]
  let composel (l : (conv -> conv) list) = List.fold_left (o) I l
  let () = add_convfn [
    fn BINDER_CONV, "BINDER_CONV";
    fn BINOP_CONV, "BINOP_CONV";
    fn LAND_CONV, "LAND_CONV";
    fn ONCE_DEPTH_CONV, "ONCE_DEPTH_CONV";
    fn RAND_CONV, "RAND_CONV";
    fn RATOR_CONV, "RATOR_CONV";
    fn REDEPTH_CONV, "REDEPTH_CONV";
    fn TOP_DEPTH_CONV, "TOP_DEPTH_CONV";
    fn composel convfnl, "COMPOSE";
  ]

  let parse s = ASSUM_LIST (fun thl ->
    let (tc, d) = tcp thl (s, 0) in
    if empty d then tc else
      let (s1, i) = d in
      let remainder = String.sub s1 i (String.length s1 - i) in
      fail d "end of input" remainder)

  let () = add_th [fn Theorem_fingerprint.thm_of_index n, "THM"]

  (* A named theorem can be referred to by name in a tactic parameter *)
  let name_thm name theorem = add_th [fn theorem, name]
end
include Parse
