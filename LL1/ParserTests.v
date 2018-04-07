Require Import List String.
Require Import ExampleGrammars Grammar LL1.Parser ParseTable ParseTree.
Import ListNotations.
Open Scope string_scope.

Example test1 :
  parse g311ParseTable (NT "S") g311Sentence1 100 =
  (Some g311ParseTree1, nil).
Proof. simpl. reflexivity. Qed.

(* We should be able to parse the empty input string, but
   there's no way to do this at the moment because the parser
   requires a lookahead token. I'm going to try to fix this
   by modifying the parser so that when it encounters an empty 
   input string, it checks whether the next grammar symbol is
   a special EOF symbol. *)
Definition x_y_grammar :=
  [(NT "x", [NT "y"]);
     (NT "y", [])].

Definition x_map := 
  LookaheadMap.add 
    EOF [NT "y"]
    (LookaheadMap.empty (list symbol)).

Definition y_map := 
  LookaheadMap.add 
    EOF nil
    (LookaheadMap.empty (list symbol)).

Definition x_y_parse_table :=
  StringMap.add
    "x" x_map
    (StringMap.add
       "y" y_map
       (StringMap.empty (LookaheadMap.t (list symbol)))).
                
Example x_y_test1 :
  parse x_y_parse_table (NT "x") nil 100 =
  (Some (Node "x" (Fcons (Node "y" Fnil) Fnil)), nil).
Proof. simpl. reflexivity. Qed.