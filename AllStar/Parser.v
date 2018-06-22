Require Import List MSets MSetDecide String.
Require Import Grammar ParseTree Subparser Lib.Utils.
Import ListNotations.
  

Fixpoint parse' (g : grammar)
                (sym : symbol)
                (input : list string)
                (stack : list symbol)
                (fuel : nat) :
                (option tree * list string) :=
  match fuel with
  | O => (None, input)
  | S n => 
    match (sym, input) with
    | (T _, nil) => (None, input)
    | (T y, token :: input') =>
      match beqSym (T y) (T token) with
      | false => (None, input)
      | true => (Some (Leaf y), input')
      end
    | (NT x, _) =>
      match adaptivePredict g x input stack with
      | Fail => (None, input)
      | Conflict _ => (None, input) (* do something else *)
      | Choice gamma => 
        match parseForest g gamma input stack n with
        | (None, _) => (None, input)
        | (Some sts, input') =>
          (Some (Node x sts), input')
        end
      end
    end
  end
with parseForest (g : grammar)
                 (gamma : list symbol)
                 (input : list string)
                 (stack : list symbol)
                 (fuel : nat) :
                 (option (list tree) * list string) :=
       match fuel with
       | O => (None, input)
       | S n =>
         match gamma with
         | nil => (Some nil, input)
         | sym :: gamma' =>
           match parse' g sym input (gamma' ++ stack) n with
           | (None, _) => (None, input)
           | (Some lSib, input') =>
             match parseForest g gamma' input' stack n with
             | (None, _) => (None, input)
             | (Some rSibs, input'') =>
               (Some (lSib :: rSibs), input'')
             end
           end
         end
       end.

Definition parse (g : grammar)
                 (sym : symbol)
                 (input : list string)
                 (fuel : nat) :
  (option tree * list string) :=
  parse' g sym input nil fuel.
