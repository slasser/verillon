Require Import List.
Require Import Omega.
Require Import String.
Require Import Lib.Grammar.
Require Import Lib.ParseTree.
Require Import Lib.Tactics.
Require Import Lib.Utils.
Require Import LL1.Derivation.
Require Import LL1.Parser.
Require Import LL1.ParseTable.
Require Import LL1.ParseTableGen.
Import ListNotations.

Lemma p2_eq_body :
  forall tbl sym input vis a,
    p2 tbl sym input vis a = 
  match (sym, input) with
  | (T _, nil) => inl (Reject "input exhausted" input)
  | (T y, token :: input') =>
    if string_dec y token then
      inr (Leaf y, input')
    else
      inl (Reject "token mismatch" input)
  | (NT x, _) =>
    match ptlk_dec x (peek input) tbl with
    | inl _ => inl (Reject "lookup failure" input)
    | inr (exist _ gamma Hlk) =>
      match List.in_dec NT_as_DT.eq_dec x vis with
      | left _ => inl (LeftRec x vis input)
      | right Hnin => 
        match pf2 tbl gamma input (x :: vis) (hole1 _ _ _ _  _ _ _ a Hlk Hnin) with
        | inl pfail => inl pfail
        | inr (sts, input') =>
          inr (Node x sts, input')
        end
      end
    end
  end.
Proof.
  intros; simpl; destruct a; cr.
Qed.

Lemma pf2_eq_body :
  forall tbl gamma input vis a,
    pf2 tbl gamma input vis a =
    match gamma as g return gamma = g -> _  with
    | nil => fun _ => inr (nil, input)
    | sym :: gamma' => fun Hg => 
                         match p2 tbl sym input vis (hole2 _ _ _ _ _ a) with
                         | inl pfail => inl pfail
                         | inr (lSib, input') =>
                           match Compare_dec.lt_dec (List.length input') (List.length input) with
                           | left Hlt =>
                             match pf2 tbl gamma' input' [] (hole3 _ _ _ _ _ _ _ a Hlt) with
                             | inl pfail => inl pfail
                             | inr (rSibs, input'') =>
                               inr (lSib :: rSibs, input'')
                             end
                           | right Hnlt =>
                             match pf2 tbl gamma' input vis (hole4 _ _ _ _ _ _ a Hg) with
                             | inl pfail => inl pfail
                             | inr (rSibs, input'') =>
                               inr (lSib :: rSibs, input'')
                             end
                           end
                         end
    end eq_refl.
Proof.
  intros; simpl; destruct a; cr.
Qed.

Lemma p2_t_ret_leaf :
  forall tbl
         input rem
         vis
         y
         (a : Acc triple_lt (meas tbl input vis (F_arg (T y))))
         tr,
    p2 tbl (T y) input vis a = inr (tr, rem)
    -> isLeaf tr = true.
Proof.
  intros; destruct a; cr; tc.
  inv H; auto.
Qed.

Lemma p2_nt_ret_node :
  forall tbl
         input rem
         vis
         x
         (a : Acc triple_lt (meas tbl input vis (F_arg (NT x))))
         tr,
    p2 tbl (NT x) input vis a = inr (tr, rem)
    -> isNode tr = true.
Proof.
  intros; destruct a; cr; tc.
  inv H; auto.
Qed.

Lemma input_length_invariant :
  forall (g   : grammar)
         (tbl : parse_table),
    parse_table_for tbl g
    -> forall (tr        : tree)
              (sym       : symbol)
              (input rem : list terminal)
              (vis       : list nonterminal)
              (a : Acc triple_lt (meas tbl input vis (F_arg sym))),
      p2 tbl sym input vis a = inr (tr, rem)
      -> List.length rem < List.length input
         \/ rem = input.
Proof.
  intros g tbl Htbl tr.
  induction tr as [ s
                  | s f IHpf
                  |
                  | tr IHp f IHpf ]
                    using tree_nested_ind with
      
      (Q := fun f =>
              forall (gamma : list symbol)
                     (input rem : list string)
                     (vis : list nonterminal)
                     (a   : Acc triple_lt (meas tbl input vis (G_arg gamma))),
                pf2 tbl gamma input vis a = inr (f, rem)
                -> List.length rem < List.length input
                   \/ rem = input); intros; destruct a.

  - destruct sym as [y | x].
    + cr; tc.
      inv H; auto.
    + apply p2_nt_ret_node in H; inv H.

  - destruct sym as [y | x].
    + apply p2_t_ret_leaf in H; inv H.
    + step; tc.
      step.
      step; tc.
      step_eq Hpf; tc.
      step.
      inv H.
      apply IHpf in Hpf; auto.

  - cr; tc.
    inv H; auto.

  - step; tc.
    step_eq Hp; tc.
    step.
    step.
    + step_eq Hpf; tc.
      step.
      inv H.
      apply IHp in Hp; clear IHp.
      apply IHpf in Hpf; clear IHpf.
      destruct Hpf.
      * left; omega.
      * subst; auto.
    + step_eq Hpf; tc.
      step.
      inv H.
      apply IHpf in Hpf; clear IHpf; auto.
Qed.

Lemma p2_sound' :
  forall (g   : grammar)
         (tbl : parse_table),
    parse_table_for tbl g
    -> forall (tr        : tree)
              (sym       : symbol)
              (input rem : list terminal)
              (vis       : list nonterminal)
              (a : Acc triple_lt (meas tbl input vis (F_arg sym))),
      p2 tbl sym input vis a = inr (tr, rem)
      -> exists word,
        word ++ rem = input
        /\ (@sym_derives_prefix g) sym word tr rem.
Proof.
  intros g tbl Htbl tr.
  induction tr as [ s
                  | s f IHpf
                  |
                  | tr IHp f IHpf ]
                    using tree_nested_ind with

      (Q := fun f =>
              forall (gamma : list symbol)
                     (input rem : list string)
                     (vis : list nonterminal)
                     (a   : Acc triple_lt (meas tbl input vis (G_arg gamma))),
                pf2 tbl gamma input vis a = inr (f, rem)
                -> exists word,
                  word ++ rem = input
                  /\ gamma_derives_prefix gamma word f rem); intros; destruct a.

  - destruct sym as [y | x].
    + rewrite p2_eq_body in H.
      step; tc.
      step_eq Hbeq; tc.
      inv H.
      eexists; split.
      * rewrite cons_app_singleton; auto.
      * constructor; auto.
    + apply p2_nt_ret_node in H; inv H.

  - destruct sym as [y | x].
    + apply p2_t_ret_leaf in H; inv H.
    + simpl in H.
      destruct (ptlk_dec x (peek input) tbl) as [| e]; tc.
      destruct e as [gamma Hlk].
      step; tc.
      step_eq Hpf; tc.
      step.
      inv H.
      apply IHpf in Hpf; clear IHpf.
      destruct Hpf as [word [Happ Hg]]; subst.
      eexists; split; eauto.
      apply Htbl in Hlk; destruct Hlk.
      econstructor; eauto.

  - rewrite pf2_eq_body in H.
    cr; tc.
    inv H.
    exists nil; split; auto.
    constructor.

  - rewrite pf2_eq_body in H.
    step; tc.
    step_eq Hp; tc.
    step.
    step.
    + step_eq Hpf; tc.
      step.
      inv H.
      apply IHp in Hp; clear IHp.
      apply IHpf in Hpf; clear IHpf.
      destruct Hp  as [wpre [Happ Hs]]; subst.
      destruct Hpf as [wsuf [Happ Hg]]; subst.
      exists (wpre ++ wsuf); split.
      * rewrite app_assoc; auto.
      * constructor; auto.
    + pose proof Hp as Hp'.
      eapply input_length_invariant in Hp'; eauto.
      destruct Hp'; try contradiction.
      subst.
      step_eq Hpf; tc.
      step.
      inv H.
      apply IHp in Hp; clear IHp.
      apply IHpf in Hpf; clear IHpf.
      destruct Hp as [wpre [Happ Hs]].
      apply l_ident_eq_nil in Happ; subst.
      destruct Hpf as [wsuf [Happ Hg]]; subst.
      exists ([] ++ wsuf); split; auto.
      constructor; auto.
Qed.

Lemma p2_sound :
  forall (g   : grammar)
         (tbl : parse_table),
    parse_table_for tbl g
    -> forall (tr        : tree)
              (sym       : symbol)
              (word rem  : list terminal)
              (vis       : list nonterminal)
              (a : Acc triple_lt (meas tbl (word ++ rem) vis (F_arg sym))),
      p2 tbl sym (word ++ rem) vis a = inr (tr, rem)
      -> (@sym_derives_prefix g) sym word tr rem.
Proof.
  intros g tbl Htbl tr sym word rem vis a Hp.
  pose proof Hp as Hp'.
  eapply p2_sound' in Hp; eauto.
  destruct Hp as [word' [Happ Hder]].
  apply app_inv_tail in Happ.
  subst; auto.
Qed.

