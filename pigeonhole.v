(*
MIT License

Copyright (c) 2014 Jean-Marie Madiot, ENS Lyon

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*)

Require Import Lia.

(* We can know if there is some [i] such that [f i = k] if we restrict the search space. *)
Lemma bounded_lookup f (k:nat) m : {i | i < m /\ f i = k} + ~ exists i, i < m /\ f i = k.
Proof.
  induction m. now right; intros [i [L _]]; inversion L.
  destruct IHm as [[i Hi]|N]. now left; exists i; lia.
  assert (D:{f m = k} + {f m <> k}) by eauto with *. destruct D. now subst; eauto.
  right; intros [i Hi]. assert (D:i = m \/ i < m) by lia; intuition eauto. now subst; eauto.
Defined.

Theorem pigeonhole :
  forall m n, m < n -> forall f, (forall i, f i < m) ->
    { i : nat & { j : nat | i < j < n /\ f i = f j } }.
Proof.
  (* It is enough to prove the special case when [n = 1 + m] *)
  cut (forall n f, (forall i, f i < n) ->  { i : _ & ((i < S n) * { j | j < i /\ f i = f j })%type }).
    intros; destruct (H (n-1) f) as [i [Li [j [Lj Hij]]]]; eauto. intros i; specialize (H1 i); lia.
    exists j, i; intuition lia.
  
  (* We do an induction on n (the base cases, for 1 and 2, are easy) *)
  destruct n. intros f L; specialize (L 0); exfalso; inversion L.
  induction n; intros f B. now pose proof conj (B 0) (B 1); exists 1; intuition; exists 0; intuition lia.
  
  (* If, for some i, [f i = f m] then it is easy: *)
  destruct (bounded_lookup f (f (S (S n))) (S (S n))) as [[i Hi]|J].
    now exists (S (S n)); intuition; eauto.

  (* Otherwise to apply the induction, we build a function g from f "stripped" from [f m] *)
  assert (Eg: { g : nat -> nat |
    (forall a, a < S (S n) -> f a < f (S (S n)) -> g a = f a) /\
    (forall a, a < S (S n) -> f a > f (S (S n)) -> g a = f a - 1) /\
    (forall a, g a < S n)}).
    set (g := fun a => if Compare_dec.lt_dec a (S (S n))
      then if Compare_dec.lt_dec (f a) (f (S (S n))) then f a else f a - 1
      else 0); exists g.
    split; [|split]; intro a; intros; unfold g;
    destruct (Compare_dec.lt_dec a (S (S n))); destruct (Compare_dec.lt_dec (f a) (f (S (S n)))); lia || auto.
      now specialize (B (S (S n))); lia.
      now specialize (B a); lia.
  destruct Eg as [g [g1 [g2 g3]]].
  
  (* We can now apply the induction on g which get us a collision for g: *)
  destruct (IHn g) as [i [Li [j [Lj E]]]]. now intros a; eauto.
  
  (* Finally we get, from the collision on g, a collision on f: *)
  exists i; intuition eauto; exists j; intuition eauto.
  assert (D: forall a, f a = f (S (S n)) \/ f a < f (S (S n)) \/  f a > f (S (S n))) by (intro;lia).
  assert (j < S (S n)) by lia.
  destruct (D i), (D j); intuition eauto; try solve [exfalso; eapply J; eauto].
    rewrite (g1 i) in E; eauto. now rewrite (g1 j) in E; eauto.
    rewrite (g1 i) in E; eauto. rewrite (g2 j) in E; eauto. lia.
    rewrite (g2 i) in E; eauto. rewrite (g1 j) in E; eauto. lia.
    rewrite (g2 i) in E; eauto. rewrite (g2 j) in E; eauto. lia.
Defined.

(* underlying functional *)
Definition find m n (L:m < n) f (H:forall i, f i < m) :=
  let p := pigeonhole m n L f H in (projT1 p, proj1_sig (projT2 p)).
