Require Import List.
Require Import MSets.
Require Import String.

Require Import Lib.ExampleGrammars.
Require Import Lib.Grammar.
Require Import Lib.Lemmas.
Require Import Lib.Tactics.
Require Import Lib.Utils.

Require Import LL1.Lemmas.
Require Import LL1.ParseTable.

Import ListNotations.

Ltac crush' :=
  repeat match goal with
         (* inversions *)
         | H : _ :: _ = _ :: _ |- _ => inv H
         | H : isNT (T _) = true |- _ => inv H
         | H : InA _ _ _ |- _ => inv H
         | H : NT _ = NT _ |- _ => inv H
         | H : In _ _ |- _ => inv H
         | H : (String _ _, _) = (String _ _, _) |- _ => inv H
         | H : [] = _ ++ _ :: _ |- _ => apply app_cons_not_nil in H; inv H
         | H : _ ++ _ :: _ = [] |- _ => symmetry in H
         | H : _ = [] ++ _ :: _ |- _ => inv H
         | H : _ :: _ = (_ :: _) ++ _ |- _ => inv H
         | H : (_, _) = (_, _) |- _ => inv H
         | H : nullable_sym _ (T _) |- _ => inv H
         | H : nullable_gamma _ (_ :: _) |- _ => inv H
         | H : first_sym _ _ (T _) |- _ => inv H
         | H : first_sym _ _ (NT _) |- _ => inv H
         | H : first_gamma _ _ (_ :: _) |- _ => inv H
         | H : first_gamma _ _ [] |- _ => inv H
         | H : SymbolMap.In _ (SymbolMap.add _ _ _) |- _ =>
           apply SymbolMapFacts.add_in_iff in H; inv H
         | H : SymbolMap.In _ (SymbolMap.empty _) |- _ =>
           apply SymbolMapFacts.empty_in_iff in H; inv H
         | H : NtMap.In _ (NtMap.add _ _ _) |- _ =>
           apply NtMapFacts.add_in_iff in H; inv H
         | H : LaMap.In _ (LaMap.add _ _ _) |- _ =>
           apply LaMapFacts.add_in_iff in H; inv H
         | H : LaMap.In _ (LaMap.empty _) |- _ =>
           apply LaMapFacts.empty_in_iff in H; inv H
         | H : SymbolMap.find (NT _) _ = Some _ |- _ =>
           inv H
         | H : NtMap.find O _ = Some _ |- _ => inv H
         | H : NtMap.find (S _)%nat _ = Some _ |- _ => inv H
         | H : LaMap.find (LA _) _ = Some _ |- _ =>
           inv H
         | H : LaSet.In _ _ |- _ => inv H
         | H : SymbolSet.In _ _ |- _ => inv H
         | H : NtMap.In _ (NtMap.empty _) |- _ =>
           apply NtMapFacts.empty_in_iff in H; inv H
         (* goals *)
         | |- In _ _ => repeat (try (left; reflexivity); right)
         | |- nullable_gamma _ _ => constructor
         | |- first_sym _ _ _ => constructor
         | |- SymbolMap.find (NT _) _ = _ => auto
         | |- LaSet.In _ _ =>
           repeat (try (apply InA_cons_hd; reflexivity); apply InA_cons_tl)
         | |- SymbolSet.In _ _ =>
           repeat (try (apply InA_cons_hd; reflexivity); apply InA_cons_tl)
         | |- Utils.isNT (NT _) = true => auto
         | |- first_gamma _ (LA ?s) (T ?s :: _) \/ _ =>
           left; apply FirstGamma with (gpre := nil)
         | |- lookahead_for (LA _) _ _ _ => unfold lookahead_for
         (* simplifications *)
         | H : _ /\ _ |- _ => destruct H
         | |- ~_ => unfold not; intros
         | |- _ /\ _ => split
         end; simpl in *; auto.

Ltac crush :=
  match goal with
  | H : InA _ ?la _ |- first_sym _ ?la _  => inv H; crush'
  | H : _ :: _ = ?pre ++ ?y :: _ |- _ => destruct pre; crush'
  | H : ?pre ++ ?y :: _ = _ :: _ |- _ => destruct pre; crush'
  | _ => crush'
  end.

(* Tests use Grammar 3.12, shown here:

     Z -> d
     Z -> X Y Z
     Y -> []
     Y -> c
     X -> Y
     X -> a

 *)

(* Tests of NULLABLE set definitions *)

(* Correct NULLABLE set for g312:

   {X, Y}                              

 *)

Definition mkSymbolSet (ys : list symbol) :=
  fold_right SymbolSet.add SymbolSet.empty ys.

Definition g312NullableSet := mkSymbolSet [NT X; NT Y].

Example Y_nullable :
  (@nullable_sym g312) (NT Y).
Proof.
  eapply NullableSym with (ys := []); crush.
Qed.

Hint Resolve Y_nullable.

Example X_nullable :
  (@nullable_sym g312) (NT X).
Proof.
  eapply NullableSym with (ys := [NT Y]); crush.
Qed.

Hint Resolve X_nullable.

Example Z_not_nullable :
  forall sym,
    (@nullable_sym g312) sym
    -> sym <> NT Z.
Proof.
  unfold not; intros.
  revert H0.
  induction H using nullable_sym_mutual_ind with
      (P := fun sym (pf : nullable_sym g312 sym) =>
              sym = NT Z -> False)
      (P0 := fun gamma (pf : nullable_gamma g312 gamma) =>
               In (NT Z) gamma -> False); intros; crush.
Qed.

Hint Resolve Z_not_nullable.

Example g312NullableSetCorrect :
  nullable_set_for g312NullableSet g312.
Proof.
  unfold nullable_set_for.
  split.
  - unfold nullable_set_sound; intros.
    unfold g312NullableSet in *; simpl in *.
    crush.
  - unfold nullable_set_complete; intros.
    unfold g312NullableSet; simpl.
    inv H.
    crush.
    exfalso.
    eapply Z_not_nullable; eauto.
Qed.

(* Tests of FIRST set definitions *)

(* FIRST sets for each nonterminal in Grammar 3.12 *)
Definition cSet   := LaSet.singleton (LA "c").
Definition acSet  := LaSet.add (LA "a") cSet.
Definition acdSet := LaSet.add (LA "d") acSet.

Definition mkSymbolMap (pairs : list (symbol * LaSet.t)) :=
  fold_right (fun pr m => match pr with
                          | (sym, se) => SymbolMap.add sym se m
                          end)
             (SymbolMap.empty LaSet.t)
             pairs.

(* Correct FIRST set for Grammar 3.12 *)
Definition g312FirstMap :=
  mkSymbolMap [(NT X, acSet); (NT Y, cSet); (NT Z, acdSet)].

Example c_in_First_Y :
  (@first_sym g312) (LA "c") (NT Y).
Proof.
  apply FirstNT with (gpre := nil) (y := T "c") (gsuf := nil); crush.
Qed.

Hint Resolve c_in_First_Y.

Example a_in_First_X :
  (@first_sym g312) (LA "a") (NT X).
Proof.
  apply FirstNT with (gpre := nil) (y := T "a") (gsuf := nil) ; crush.
Qed.

Hint Resolve a_in_First_X.

Example c_in_First_X :
  (@first_sym g312) (LA "c") (NT X).
Proof.
  apply FirstNT with (gpre := nil) (y := NT Y) (gsuf := nil); crush.
Qed.

Hint Resolve c_in_First_X.

Example d_not_in_First_Y :
  ~(@first_sym g312) (LA "d") (NT Y).
Proof.
  repeat crush.
Qed.

Example d_not_in_First_X :
  ~(@first_sym g312) (LA "d") (NT X).
Proof.
  repeat crush.
Qed.

Example a_in_First_Z :
  (@first_sym g312) (LA "a") (NT Z).
Proof.
  apply FirstNT with (gpre := nil) (y := NT X) (gsuf := [NT Y; NT Z]); crush.
Qed.

Hint Resolve a_in_First_Z.

Example c_in_First_Z :
  (@first_sym g312) (LA "c") (NT Z).
Proof.
  apply FirstNT with (gpre := [NT X]) (y := NT Y) (gsuf := [NT Z]); crush.
Qed.

Hint Resolve c_in_First_Z.
  
Example d_in_First_Z :
  (@first_sym g312) (LA "d") (NT Z).
Proof.
  apply FirstNT with (gpre := nil) (y := T "d") (gsuf := nil); crush.
Qed.

Hint Resolve d_in_First_Z.

Example g312FirstMapCorrect :
  first_map_for g312FirstMap g312.
Proof with crush.
  unfold g312FirstMap.
  unfold first_map_for; split.
  - unfold first_map_sound; intros.
    simpl in H.
    copy_and_find_In H...
  - unfold first_map_complete; intros.
    revert H.
    induction H0; intros...
    + crush; exists acdSet...
    + crush.
      * crush... exists acdSet...
      * crush... exists acdSet...
      * crush... exists acdSet...
    + crush... exists cSet...
    + crush... exists acSet...
    + crush... exists acSet...
Qed.

Definition g312FirstMapPlus :=
  mkSymbolMap [(NT X, acdSet); (* d shouldn't be in there! *)
               (NT Y, cSet);
               (NT Z, acdSet)].  

Example nonMinimalFirstMapIncorrect :
  ~first_map_for g312FirstMapPlus g312.
Proof with crush.
  crush.
  unfold first_map_for in H.
  destruct H as [Hsou _].
  unfold first_map_sound in Hsou.
  specialize Hsou with (x := NT X)
                       (xFirst := acdSet)
                       (la := LA "d").
  assert (H : ~(@first_sym g312) (LA "d") (NT X)) by repeat crush.
  apply H.
  apply Hsou...
Qed.

Definition Xc_grammar :=
  {| productions := [(X, [NT X; T "c"]);
                     (X, [])];
     start := X |}.

Definition Xc_first_map :=
  mkSymbolMap [(NT X, cSet)].

Example Xc_first_correct :
  first_map_for Xc_first_map Xc_grammar.
Proof with crush.
  unfold first_map_for; split.
  - unfold first_map_sound; intros.
    unfold Xc_first_map in *; simpl in *.
    copy_and_find_In H...
    apply FirstNT with (gpre := [NT X]) (y := T "c") (gsuf := nil)...
    apply NullableSym with (ys := [])...
  - unfold first_map_complete; intros.
    revert H.
    induction H0; intros...
    crush...
    exists cSet...
Qed.

(* tests of FOLLOW definitions *)

Definition xFollow := LaSet.add EOF acdSet.
Definition yFollow := LaSet.add EOF acdSet.

(* Correct FOLLOW set for Grammar 3.12 *)
Definition g312FollowMap :=
  mkSymbolMap [(NT X, xFollow); (NT Y, yFollow)].

Example what's_in_xFirst :
  forall la,
    first_sym g312 la (NT X)
    -> LaSet.In la acSet.
Proof.
  intros.
  pose proof g312FirstMapCorrect as Hc.
  unfold first_map_for in Hc.
  destruct Hc as [_ Hcom].
  unfold first_map_complete in Hcom.
  apply Hcom in H; auto.
  destruct H as [xFirst [Hs Hf]].
  inv Hs.
  auto.
Qed.

Example what's_in_yFirst :
  forall la,
    first_sym g312 la (NT Y)
    -> LaSet.In la cSet.
Proof.
  intros.
  pose proof g312FirstMapCorrect as Hc.
  unfold first_map_for in Hc.
  destruct Hc as [_ Hcom].
  unfold first_map_complete in Hcom.
  apply Hcom in H; auto.
  destruct H as [yFirst [Hs Hf]].
  inv Hs.
  auto.
Qed.

Example what's_in_zFirst :
  forall la,
    first_sym g312 la (NT Z)
    -> LaSet.In la acdSet.
Proof.
  intros.
  pose proof g312FirstMapCorrect as Hc.
  unfold first_map_for in Hc.
  destruct Hc as [_ Hcom].
  unfold first_map_complete in Hcom.
  apply Hcom in H; auto.
  destruct H as [zFirst [Hs Hf]].
  inv Hs.
  auto.
Qed.

Example c_in_Follow_X :
  follow_sym g312 (LA "c") (NT X).
Proof.
  apply FollowRight with (x1 := Z) 
                         (gpre := nil) 
                         (gsuf := [NT Y; NT Z]); crush.
  apply FirstGamma with (gpre := nil)
                        (y := NT Y); crush.
Qed.

Hint Resolve c_in_Follow_X.

Example a_in_Follow_X :
  follow_sym g312 (LA "a") (NT X).
Proof.
  apply FollowRight with (x1 := Z)
                         (gpre := nil)
                         (gsuf := [NT Y; NT Z]); crush.
  apply FirstGamma with (gpre := [NT Y]); crush.
Qed.

Hint Resolve a_in_Follow_X.

Example d_in_Follow_X :
  follow_sym g312 (LA "d") (NT X).
Proof.
  apply FollowRight with (x1 := Z)
                         (gpre := nil)
                         (gsuf := [NT Y; NT Z]); crush.
  apply FirstGamma with (gpre := [NT Y]); crush.
Qed.

Hint Resolve d_in_Follow_X.

Example c_in_Follow_Y :
  follow_sym g312 (LA "c") (NT Y).
Proof.
  apply FollowRight with (x1 := Z)
                         (gpre := [NT X])
                         (gsuf := [NT Z]); crush.
  apply FirstGamma with (gpre := nil); crush.
Qed.

Hint Resolve c_in_Follow_Y.

Example a_in_Follow_Y :
  follow_sym g312 (LA "a") (NT Y).
Proof.
  apply FollowRight with (x1 := Z)
                         (gpre := [NT X])
                         (gsuf := [NT Z]); crush.
  apply FirstGamma with (gpre := nil); crush.
Qed.

Hint Resolve a_in_Follow_Y.

Example d_in_Follow_Y :
  follow_sym g312 (LA "d") (NT Y).
Proof.
  apply FollowRight with (x1 := Z)
                         (gpre := [NT X])
                         (gsuf := [NT Z]); crush.
  apply FirstGamma with (gpre := nil); crush.
Qed.
  
Hint Resolve d_in_Follow_Y.

Example finiteFollowCorrect :
  follow_map_for g312FollowMap g312.
Proof with crush.
  unfold follow_map_for. split.
  - unfold follow_map_sound; intros.
    unfold g312FollowMap in *; simpl in *.
    copy_and_find_In H...
  - unfold follow_map_complete; intros.
    induction H.
    + inv H...
      * exfalso. 
        eapply Z_not_nullable; eauto. 
      * exists yFollow...
      * exists xFollow...
    + crush; try solve [crush]...
      * crush.
        -- inv H.
           apply what's_in_yFirst in H3...
           exists xFollow...
        -- crush...
           ++ inv H2.
              apply what's_in_zFirst in H3.
              exists yFollow...
           ++ crush.
      * crush.
        -- crush.
           ++ inv H.
              apply what's_in_zFirst in H3.
              exists yFollow...
           ++ crush.
        -- crush.
    + crush; try solve [crush].
      destruct IHfollow_sym as [zFollow [Hs Hl]]...
Qed. 

(* The next tests use Grammar 3.11, shown here:

   S -> if E then S else S
   S -> begin S L
   S -> print E

   L -> end
   L -> ; S L

   E -> num = num

 *)

Example g311ParseTableCorrect :
  parse_table_for g311ParseTable g311.
Proof with crush.
  unfold parse_table_for.
  split.
  - unfold pt_sound; intros.
    unfold g311ParseTable in *.
    pose proof H as H'.
    apply ntmap_find_in in H'...
    + unfold X in *; unfold X_map in *.
      pose proof H0 as H0'.
      apply lookaheadmap_find_in in H0...
    + unfold L in *; unfold L_map in *.
      pose proof H0 as H0'.
      apply lookaheadmap_find_in in H0...
    + unfold E in *; unfold E_map in *.
      pose proof H0 as H0'.
      apply lookaheadmap_find_in in H0...
  - unfold pt_complete; intros.
    unfold lookahead_for in H; destruct H as [Hin [Hfi | Hfo]]...
    + crush... exists X_map...
    + crush... exists X_map...
    + crush... exists X_map...
    + crush... exists L_map...
    + crush... exists L_map...
    + crush... exists E_map...
Qed.

