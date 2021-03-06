Require Import List. 
Require Import String.
Import ListNotations.

Fixpoint prependToAll (sep : string) (ss : list string) : string :=
  match ss with
  | [] => ""
  | s :: ss' => sep ++ s ++ prependToAll sep ss'
  end.

Definition intersperse (sep : string) (ss : list string) : string :=
  match ss with
  | [] => ""
  | s :: ss' => s ++ prependToAll sep ss'
  end.

Fixpoint tuple (xs : list Type) : Type :=
  match xs with
  | [] => unit
  | x :: xs' => prod x (tuple xs')
  end.