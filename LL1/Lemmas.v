Require Import List.
Require Import Lib.Grammar.
Require Import Lib.ParseTree.
Require Import Lib.Tactics.
Require Import LL1.Derivation.
Require Import LL1.Parser.
Require Import LL1.ParseTable.
Import ListNotations.

(* New version *)
Lemma eof_first_sym :
  forall g la sym,
    first_sym g la sym
    -> la = EOF
    -> False.
Proof.
  induction 1; intros; auto.
  inv H.
Qed.

Lemma eof_first_gamma :
  forall g la gamma,
    first_gamma g la gamma
    -> la = EOF
    -> False.
Proof.
  intros.
  inv H.
  eapply eof_first_sym; eauto.
Qed.

(* Old version *)
(*
Lemma eof_fgamma :
  forall g la gamma,
    (@first_gamma g) la gamma
    -> la = EOF
    -> False.
Proof.
  intros g la gamma H.
  induction H using first_gamma_mutual_ind with
      (P := fun la x gamma (pf : first_prod la x gamma) =>
              la = EOF -> False)
      (P0 := fun la gamma (pf : first_gamma la gamma) =>
               la = EOF -> False)
      (P1 := fun la sym (pf : first_sym la sym) =>
               la = EOF -> False); intros.
  - apply IHfirst_gamma; trivial.
  - apply IHfirst_gamma; trivial.
  - apply IHfirst_gamma; trivial. 
  - inv H.
  - apply IHfirst_gamma; trivial.
Qed.
*)

Lemma nullable_middle_sym :
  forall g xs ys sym,
    (@nullable_gamma g) (xs ++ sym :: ys)
    -> (@nullable_sym g) sym.
Proof.
  induction xs; intros.
  - simpl in H.
    inv H.
    auto.
  - eapply IHxs.
    inv H.
    eauto.
Qed.

Lemma gamma_with_terminal_not_nullable :
  forall g xs y zs,
    (@nullable_gamma g) (xs ++ T y :: zs)
    -> False.
Proof.
  induction xs; intros.
  - simpl in H.
    inv H.
    inv H2.
  - destruct a.
    + inv H.
      inv H2.
    + inv H.
      eapply IHxs; eauto.
Qed.

Lemma nullable_split :
  forall g xs ys,
    (@nullable_gamma g) (xs ++ ys)
    -> (@nullable_gamma g) ys.
Proof.
  induction xs; intros.
  - auto.
  - inv H.
    eapply IHxs; eauto.
Qed.

(* New version, without mutual induction *)
Lemma no_first_follow_conflicts :
  forall tbl g,
    parse_table_for tbl g
    -> forall la sym,
      first_sym g la sym
      -> nullable_sym g sym
      -> follow_sym g la sym
      -> False.
Proof.
  intros tbl g Htbl la sym Hfi.
  induction Hfi; intros.
  - inv H.
  - inv H1.
    assert (ys = gpre ++ y :: gsuf).
    { destruct Htbl as [Hmin Hcom].
      assert (Hlk : lookahead_for g la x (gpre ++ y :: gsuf)).
      { unfold lookahead_for.
        split; auto.
        left.
        econstructor; eauto. }
      assert (Hlk' : lookahead_for g la x ys).
      { unfold lookahead_for.
        split; auto. }
      unfold pt_complete in Hcom.
      apply Hcom in Hlk.
      apply Hcom in Hlk'.
      destruct Hlk as [m [Hs Hl]].
      destruct Hlk' as [m' [Hs' Hl']].
      congruence. }
    subst.
    eapply IHHfi.
    + apply nullable_middle_sym in H5; auto.
    + destruct y.
      * apply gamma_with_terminal_not_nullable in H5; inv H5.
      * eapply FollowLeft; eauto.
        assert (NT n :: gsuf = [NT n] ++ gsuf) by auto.
        rewrite H1 in H5.
        rewrite app_assoc in H5.
        apply nullable_split in H5.
        auto.
Qed.

(* Old, much more complicated version, with mutual induction *)
(*
Lemma no_first_follow_conflicts :
  forall tbl g,
    parse_table_for tbl g
    -> forall la sym,
      (@first_sym g) la sym
      -> (@nullable_sym g) sym
      -> (@follow_sym g) la sym
      -> False.
Proof.
  intros tbl g Htbl la sym Hfi.
  destruct Htbl as [Hmin Hcom].
  induction Hfi using first_sym_mutual_ind with
      (P := fun la sym gamma
                (pf : (@first_prod g) la sym gamma) =>
              (@nullable_prod g) sym gamma
              -> (@follow_sym g) la sym 
              -> False)
      (P0 := fun la gammaSuf
                 (pf : (@first_gamma g) la gammaSuf) =>
               forall sym gammaPre,
                 (@first_prod g) la sym (gammaPre ++ gammaSuf)
                 -> (@nullable_prod g) sym (gammaPre ++ gammaSuf)
                 -> (@follow_sym g) la sym
                 -> False)
      (P1 := fun la sym (pf : (@first_sym g) la sym) =>
              (@nullable_sym g) sym
              -> (@follow_sym g) la sym
              -> False).

  - intros Hnu Hfo.
    eapply IHHfi; auto.
    + assert (gamma = [] ++ gamma) by auto.
      rewrite H in i.
      econstructor; eauto.
    + auto.
    + auto.

  - intros sym gammaPre Hfi' Hnu Hfo.
    eapply IHHfi.
    + inv Hnu.
      apply nullable_middle_sym in H0.
      auto.
    + destruct hd.
      * inv Hnu.
        apply gamma_with_terminal_not_nullable in H0.
        inv H0.
      * inv Hnu.
        eapply FoLeft; eauto.
        assert (NT n :: tl = [NT n] ++ tl) by auto.
        rewrite H1 in H0.
        rewrite app_assoc in H0.
        eapply nullable_split in H0.
        auto.        

  - intros sym gammaPre Hfi Hnu Hfo.
    eapply IHHfi; eauto.
    + assert (NT x :: tl = [NT x] ++ tl) by auto.
      rewrite H in Hfi.
      rewrite app_assoc in Hfi.
      eauto.
    + rewrite <- app_assoc.
      simpl.
      auto.

  - intros Hnu Hfo.
    inv Hfo.

  - intros Hnu Hfo.
    inv Hnu.
    inv H.
    assert (Hlk : (@lookahead_for g) la (NT x) gamma).
    { unfold lookahead_for.
      left.
      auto. }
    assert (Hlk' : (@lookahead_for g) la (NT x) ys).
    { unfold lookahead_for.
      right.
      split.
      { constructor; auto. }
      { constructor; auto. }}
    unfold pt_complete in Hcom.
    apply Hcom in Hlk; apply Hcom in Hlk'.
    destruct Hlk as [laMap [Hsf Hlf]].
    destruct Hlk' as [laMap' [Hsf' Hlf']].
    assert (gamma = ys) by congruence.
    subst.
    apply IHHfi.
    + constructor; auto.
    + auto.
Qed.
*)

Lemma lookahead_in_grammar :
  forall g la x gamma,
    lookahead_for g la x gamma
    -> In (x, gamma) (productions g).
Proof.
  intros.
  destruct H; auto.
Qed.

Lemma sym_derives_nil_nullable :
  forall g sym wpre f wsuf,
    (@sym_derives_prefix g) sym wpre f wsuf
    -> wpre = nil
    -> (@nullable_sym g) sym.
Proof.
  intros g sym wpre f wsuf Hder.
  induction Hder using sdp_mutual_ind with
      (P := fun sym wpre tr wsuf
                (pf : sym_derives_prefix sym wpre tr wsuf) =>
              wpre = nil
              -> nullable_sym g sym)
      (P0 := fun gamma wpre f wsuf
                 (pf : gamma_derives_prefix gamma wpre f wsuf)
             =>
               wpre = nil
               -> nullable_gamma g gamma); intros; subst.
  - inv H.
  - simpl in *.
    econstructor.
    + apply lookahead_in_grammar in l.
      eauto.
    + auto.
  - constructor.
  - apply app_eq_nil in H; destruct H; subst.
    destruct IHHder; auto.
    constructor; auto.
    econstructor; eauto.
Qed.

Lemma gamma_derives_nil_nullable :
  forall g gamma wpre f wsuf,
    (@gamma_derives_prefix g) gamma wpre f wsuf
    -> wpre = nil
    -> (@nullable_gamma g) gamma.
Proof.
  intros g gamma wpre f wsuf Hder.
  induction Hder using gdp_mutual_ind with
      (P := fun sym wpre tr wsuf
                (pf : sym_derives_prefix sym wpre tr wsuf) =>
              wpre = nil
              -> nullable_sym g sym)
      (P0 := fun gamma wpre f wsuf
                 (pf : gamma_derives_prefix gamma wpre f wsuf)
             =>
               wpre = nil
               -> nullable_gamma g gamma); intros; subst.
  - inv H.
  - simpl in *.
    econstructor.
    + apply lookahead_in_grammar in l.
      eauto.
    + auto.
  - constructor.
  - apply app_eq_nil in H; destruct H; subst.
    destruct hdRoot as [y | x].
    + inv s.
    + econstructor; eauto.
Qed.

(* New version *)
Lemma gamma_derives_cons_fg :
  forall g gamma word f rem,
    (@gamma_derives_prefix g) gamma word f rem
    -> forall tok toks,
      word = tok :: toks
      -> (@first_gamma g) (LA tok) gamma.
Proof.
  intros g gamma word f rem Hder.
  induction Hder using gdp_mutual_ind with
      (P := fun sym word tr rem
                (pf : sym_derives_prefix sym word tr rem) =>
              forall tok toks,
                word = tok :: toks
                -> first_sym g (LA tok) sym)
      (P0 := fun gamma word f rem
                 (pf : gamma_derives_prefix gamma word f rem)
             =>
               forall tok toks,
                 word = tok :: toks
                 -> first_gamma g (LA tok) gamma); intros; subst.
  - inv H; constructor.
  - simpl in *.
    specialize (IHHder tok toks).
    destruct IHHder; auto.
    econstructor; eauto.
    apply lookahead_in_grammar in l.
    eauto.
  - inv H.
  - destruct hdRoot.
    + inv s.
      inv H.
      eapply FirstGamma with (gpre := nil); constructor.
    + destruct wpre as [| ptok ptoks]; simpl in *.
      * subst.
        specialize (IHHder0 tok toks).
        destruct IHHder0; auto.
        eapply FirstGamma with (gpre := NT n :: gpre).
        -- constructor; auto.
           apply sym_derives_nil_nullable in s; auto.
        -- auto.
      * inv H.
        eapply FirstGamma with (gpre := nil).
        -- constructor.
        -- eapply IHHder; eauto.
Qed.

(* Old version *)
(*
Lemma gamma_derives_cons_fg :
  forall g gamma word f rem,
    (@gamma_derives_prefix g) gamma word f rem
    -> forall tok toks,
      word = tok :: toks
      -> (@first_gamma g) (LA tok) gamma.
Proof.
  intros g gamma word f rem Hder.
  induction Hder using gdp_mutual_ind with
      (P := fun sym word tr rem
                (pf : sym_derives_prefix sym word tr rem) =>
              forall tok toks,
                word = tok :: toks
                -> first_sym (LA tok) sym)
      (P0 := fun gamma word f rem
                 (pf : gamma_derives_prefix gamma word f rem)
             =>
               forall tok toks,
                 word = tok :: toks
                 -> first_gamma (LA tok) gamma); intros; subst.
  - inv H; constructor.
  - simpl in *.
    apply lookahead_in_grammar in l.
    econstructor.
    econstructor; eauto.
  - inv H.
  - destruct hdRoot.
    + inv s.
      inv H.
      constructor.
      constructor.
    + destruct wpre as [| ptok ptoks]; simpl in *.
      * eapply FiGammaTl.
        -- inv s; simpl in *.
           apply lookahead_in_grammar in H1.
           econstructor.
           econstructor; eauto.
           eapply gamma_derives_nil_nullable; eauto.
        -- eapply IHHder0; eauto.
      * inv H.
        eapply FiGammaHd.
        eapply IHHder; eauto.
Qed.
 *)

Lemma parse_t_ret_leaf :
  forall tbl y input fuel tree suffix,
    parse tbl (T y) input fuel = (Some tree, suffix) ->
    isLeaf tree = true.
Proof.
  intros. destruct fuel.
  - inv H.
  - simpl in H. destruct input.
    + inv H.
    + destruct (Utils.beqString y s).
      * inv H. reflexivity.
      * inv H.
Qed.

Lemma parse_nt_ret_node :
  forall tbl x input fuel tree suffix,
    parse tbl (NT x) input fuel = (Some tree, suffix)
    -> isNode tree = true.
Proof.
  intros. destruct fuel.
  - simpl in H. inv H.
  - simpl in H. destruct (parseTableLookup x (peek input) tbl).
    + destruct (parseForest tbl l input fuel). 
      destruct o. 
      * inv H. trivial.
      * inv H.
    + inv H. 
Qed.

Lemma tbl_entry_is_lookahead :
  forall tbl g x la gamma,
    parse_table_for tbl g
    -> parseTableLookup x la tbl = Some gamma
    -> (@lookahead_for g) la x gamma.
Proof.
  intros tbl g x la gamma Htbl Hlkp.
  destruct Htbl as [Hmin Hcom].
  unfold pt_minimal in Hmin.
  unfold parseTableLookup in Hlkp.
  destruct (StringMap.find x tbl) as [m |] eqn:Hsf.
  - eapply Hmin; eauto.
  - inv Hlkp.
Qed.
