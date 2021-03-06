Require Import MyTacs HoTT.
Require Import Peano nat_lemmas equivalence cech_nerve colimit colimit2.

Set Implicit Arguments.

Context `{fs : Funext}.
Context `{ua : Univalence}.


(* Squash *)
Notation sq A := (@tr -1 A).  

(* We want to prove that [Trunc -1 A] is the colimit of the Cech nerve of [sq: A -> Trunc -1 A]. *)

Section Prod_diagram.
  
  (* We prove here that we can use the real diagram A×...×A -> ... -> A×A -> A instead of the Cech nerve of sq with irrelevant second compenents *)

  Lemma ishprop_pullback_sq_pr2
        (A : Type)
        (i : nat)
        (x : ∃ P : A ∧ hProduct A i, char_hPullback (sq A) i P)
  : IsHProp
      (char_hPullback (sq A) i x.1).
    induction i; simpl.
    apply true_ishprop.
    refine (trunc_prod). simpl in *.
    exact (IHi (snd x.1; snd x.2)).
  Qed.

  Definition prod_diag (A:Type) : diagram Cech_nerve_graph.
    refine (Build_diagram _ _ _).
    - simpl. intro i. exact (hProduct A (S i)).
    - simpl. intros i j [f q]. destruct f. intros x.
      exact (forget_hProduct A (S j) x q).
  Defined.

  Definition CN_sq_cocone {A Q: Type} (C: cocone (prod_diag A) Q)
  : cocone (Cech_nerve_diagram (sq A)) Q.
    refine (exist _ _ _); simpl.
    - intros i X. apply (C.1 i). exact X.1.
    - intros i j [f [k Hk]] x; destruct f; simpl.
      exact (C.2 (j.+1) j (idpath,(k;Hk)) x.1).
  Defined.
  
  Lemma inhab_pullback_sq_pr2 (A:Type) (i:nat)
  : forall x:A*(hProduct A i), char_hPullback (sq A) i x.
    intro x.
    induction i. exact tt. simpl.
    refine (pair _ _).
    apply path_ishprop.
    apply IHi.
  Qed.

  Lemma colim_prod_diag_CN_sq (A:Type) Q (C : cocone (prod_diag A) Q)
  : is_colimit C -> is_colimit (CN_sq_cocone C).
    intros H.
    refine (transport_is_colimit _ _ _ _ _ _ _ _ _ _ _ _ H); simpl.
    - intro i. refine (equiv_adjointify _ _ _ _).
      + intros x. exists x. apply inhab_pullback_sq_pr2.
      + exact pr1.
      + intros x. apply path_sigma' with idpath.
        simpl. refine (path_ishprop _ _). apply ishprop_pullback_sq_pr2.
      + intros x. reflexivity.
    - intros i j [f [q Hq]]; destruct f; simpl.
      intro x; reflexivity.
    - reflexivity.
    - simpl.
      apply path_forall; intro i.
      apply path_forall; intro j.
      apply path_forall; intros [f [q Hq]]; destruct f.
      apply path_forall; intro x. simpl. hott_simpl.
      unfold path_sigma'.
      pose (p := @pr1_path_sigma). unfold pr1_path in p. rewrite p.
      rewrite ap_1. rewrite concat_p1. reflexivity.
  Qed.

End Prod_diagram.



Section TheProof.

  Open Scope path_scope.
  Open Scope type_scope.

  (* Sketch of proof :
     Let [Q] be the colimit of [prod_diag A].
     As [Trunc -1 A] defines a cocone on [prod_diag A], we have an arrow [Q -> Trunc -1 A].
     As there is an arrow [A -> Q], it remains to show that [IsHProp Q], so that we have an arrow [Trunc -1 A -> Q] defining an equivalence ([Q] and [Trunc -1 A]) are both [HProp]). *)

  (* To show [IsHProp Q], it suffices to show that : *)
  Lemma HProp_if_snd_equiv (Q:Type)
  : IsEquiv (snd : Q*Q -> Q) -> IsHProp Q.
  Proof.
    intro H.
    apply hprop_allpath; intros u v.
    assert (X : (u,u) = (v,u)).
    { apply (@equiv_inj _ _ _ H). reflexivity. }
    exact (ap fst X).
  Qed.

  
  Variable (A:Type).
  Let D := prod_diag A.
  (* Let D' := Cech_nerve_diagram (sq A). *)
  Variable Q : Type.
  Variable C : cocone D Q.
  Variable (colimQ : is_colimit C).
  
  Let pi := @snd Q A.
  

  Lemma C2 (D' := pdt_diagram_l D Q)
  : cocone D' Q.
    refine (exist _ _ _).
    - simpl. intros i [a [x y]]. exact ((C.1 i) (pi (a,x), y)).
    - intros i j f x; destruct (fst f); simpl in *.
      exact (C.2 (j.+1) j f _).
  Defined.

  (* Using the fact that [Q ∧ Q = Q ∧ (colimit D], we have: *)
  Lemma isequiv_snd_QQ_if_isequiv_snd_QA (D' := pdt_diagram_l D Q)
  : IsEquiv (pi : Q ∧ A -> A) -> IsEquiv (snd : Q ∧ Q -> Q).
    intro H.
    specialize (colimit_product_l Q colimQ); intros colimQQ.
    set (C1 := pdt_cocone_l Q C) in *. 
    unfold is_colimit in colimQQ.
    assert (eq: @snd Q Q  = (map_to_cocone C1 Q)^-1 C2).
    { apply (equiv_inj (map_to_cocone C1 Q)).
      rewrite eisretr.
      refine (path_cocone _ _).
      + intros i x. reflexivity.
      + intros i j [f [q Hq]] x; destruct f; simpl.
        rewrite concat_p1; rewrite concat_1p.
        apply (ap_snd_path_prod (z := (fst x, C.1 j _))
                                (z' := (fst x, C.1 j.+1 (snd x)))
                                1 (C.2 j.+1 j (1, (q; Hq)) (snd x))).
      }
    rewrite eq; clear eq.
    apply (colimit_unicity colimQQ).
    refine (transport_is_colimit _ _ _ _ _ _ _ _ _ _ _ _ colimQ).
    - intros i. simpl.
      symmetry.
      transitivity ((Q ∧ A) ∧ hProduct A i).
      apply equiv_prod_assoc. apply equiv_functor_prod_r. refine (BuildEquiv _ _ _ H).
    - intros i j [f [q Hq]] x; destruct f. simpl.
      exact (ap
               (λ x : A ∧ A ∧ hProduct A j,
                      (nat_rect (λ p : nat, p <= j.+1 → A ∧ hProduct A j)
                                (λ _ : 0 <= j.+1, (fst (snd x), snd (snd x)))
                                (λ (p : nat) (_ : p <= j.+1 → A ∧ hProduct A j)
                                   (H : p.+1 <= j.+1),
                                 (fst x,
                                  forget_hProduct A j (fst (snd x), snd (snd x))
                                                  (p; le_pred p.+1 j.+1 H))) q Hq))
               (path_prod' (y' := snd x) (eisretr pi (fst x)) 1)^). 
    - reflexivity. 
    - simpl.
      apply path_forall; intro i.
      apply path_forall; intro j.
      apply path_forall; intros [f [q Hq]].
      apply path_forall; intro x.
      destruct f; simpl. hott_simpl.
      match goal with
        |[|- (ap ?X1 (ap ?X2 ?X3) @ _) @ _ = _ ] =>
         rewrite <- (ap_compose X2 X1 X3)       
      end.
      rewrite ap_V. rewrite concat_pp_p.
      apply moveR_Vp. 
      exact (concat_Ap (C.2 (j.+1) j (1,(q;Hq))) (path_prod' (eisretr pi (fst x)) 1))^. 
  Defined.

  Lemma le_1_Sn (n:nat) : 1 <= S n.
    induction n. auto.
    apply le_S. exact IHn.
  Qed.

  Lemma isequiv_snd_QA
  : IsEquiv (pi : Q ∧ A -> A).
    refine (isequiv_adjointify _ _ _ _).
    - exact (λ x, (C.1 0 (x, tt), x)).
    - intros x. reflexivity.
    - intros x. apply path_prod; [simpl|reflexivity].
      generalize x; apply ap10.
      specialize (colimit_product_r A colimQ); intros colimQA. unfold is_colimit in *.
      refine (equiv_inj (map_to_cocone (pdt_cocone_r A C) Q) _). 
      refine (path_cocone _ _).
      + intros i [[z z'] a]. simpl in *.
        induction i.
        * destruct z'; simpl.
          etransitivity; [exact (C.2 1%nat 0 (1,(1%nat; le_n 1)) (a, (z, tt))) | exact (C.2 1%nat 0 (1,(0; le_0 _)) (a, (z, tt)))^]. 
        * etransitivity; [exact (IHi (snd z')) | idtac].
          etransitivity; [idtac | exact (C.2 (i.+1) i (1,(1%nat; le_1_Sn _)) (z,z'))].
          apply ap. refine (path_prod _ _ _ _).
          reflexivity.
          destruct i; [apply path_ishprop | reflexivity].
      + intros i j [f [q Hq]] u; destruct f; simpl.
        match goal with
            |[|- ?PP @ _ = _] => assert (X : 1 = PP)
          end.
        { unfold path_prod'. simpl.
          rewrite (ap_compose pi (λ x, C.1 0 (x,tt))).
          unfold pi. rewrite ap_snd_path_prod. reflexivity. }
        destruct X; rewrite concat_1p.
        match goal with
            |[|- _ = _ @ ?PP] => assert (X : (C.2 j.+1 j (1, (q; Hq)) (fst u)) = PP)
          end.
          { unfold path_prod'. simpl.
            rewrite ap_fst_path_prod. reflexivity. }
          destruct X.

        induction j; simpl.
        * destruct u as [[u1 [u2 u]] v]. simpl in *.
          destruct u. 
          destruct (le_1_is_01 q Hq).
          symmetry in p; destruct p. simpl.
          assert (X : 1 = (path_ishprop tt tt)).
          { apply path_ishprop. }
          destruct X. simpl; rewrite concat_1p.
          assert (X : le_0 1 = Hq).
          { refine (path_ishprop _ _). apply IsHProp_le. }
          destruct X.
          apply moveR_pM.
          rewrite concat_pp_p.
          pose (C.2 1%nat 0 (1, (1%nat; le_n 1)) (v, (u1, tt))). simpl in p.
          pose ((C.2 1%nat 0 (1, (0; le_0 1)) (v, (u1, tt)))^). simpl in p0.
          shelve.
          symmetry in p; destruct p; simpl.
Admitted.



    
  
End TheProof.


Section AnotherAtempt.

  Definition delta : graph.     (* = Cech_nerve_graph *)
    refine (Build_graph nat _).
    intros i j. exact ((S j = i) /\ (nat_interval i)).
  Defined.

  Definition delta_plus: graph.
    refine (Build_graph nat _).
    intros i j. exact ((S j = i) /\ (nat_interval j)). 
  Defined.
  
  
  Definition augment_diag {A B: Type} (D: diagram delta) (π: A -> B): diagram delta_plus.
    refine (Build_diagram _ _ _).
    - intros i. destruct i. exact B. exact (D i /\ B).
    - intros i j [eq f]. destruct j.
      + destruct eq. exact snd.
      + destruct eq. intros x. exact (diagram1 D (idpath,f) (fst x), snd x).
  Defined.

  Definition augment_cocone {A B: Type} (D: diagram delta) (π: A -> B): cocone (augment_diag D π) B.
    refine (exist _ _ _).
    - intros i. destruct i. exact idmap. exact snd.
    - intros i j [eq f]; destruct eq. destruct j; reflexivity.
  Defined.

  Lemma augment_diag_colimit {A B: Type} (D: diagram delta) (π: A -> B): is_colimit (augment_cocone D π).
    intros X. refine (isequiv_adjointify _ _ _ _).
    - intros C. exact (C.1 0).
    - intros C. refine (path_cocone _ _).
      + destruct i; simpl. intros x; reflexivity.
        induction i. exact (C.2 1 0 (idpath, (0; le_0 _))).
        intros x. etransitivity; [| exact (C.2 (i.+2) (i.+1) (idpath, (0; le_0 _)) x)].
        simpl. exact (IHi (@diagram1 _ D i.+1 i (idpath, (0; le_0 i.+1)) (fst x), snd x)).
      + intros i j [eq f] x; destruct eq.
        destruct j; simpl; hott_simpl.
        * assert (eq: f = (0; le_0 0)).
          { destruct f as [k Hk].
            refine (path_sigma _ _ _ _ _).
            apply le_0_is_0. assumption.
            simpl. refine (path_ishprop _ _).
            apply IsHProp_le. }
          rewrite eq. reflexivity.
        * match goal with
            | [|- ?PP1 @ ?PP2 = ?PP3 @ ?PP4 ] => set (P1 := PP1); set (P2 := PP2); set (P3 := PP3); set (P4 := PP4)
          end. induction j; simpl in *.
          shelve. shelve.
    - intros q. funext b. reflexivity.
  Admitted.
        

  
End AnotherAtempt.