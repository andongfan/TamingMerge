Require Import LibTactics.
Require Import Metalib.Metatheory.

Require Import
        syntax_ott
        rules_inf
        Infrastructure
        Key_Properties
        Subtyping_inversion
        Deterministic
        Typing.

Require Import List. Import ListNotations.
Require Import Arith Omega.
Require Import Strings.String.



(* requires sub Top A -> toplike A *)
Lemma TypedReduce_trans : forall v v1 v2 A B,
    value v -> TypedReduce v A v1 -> TypedReduce v1 B v2 -> TypedReduce v B v2.
Proof.
  introv Val Red1 Red2.
  lets Lc: value_lc Val.
  gen B v2.
  induction* Red1;
    introv Red2.
  - (* v1 = v_top *)
    remember e_top.
    induction* Red2;
      try solve [inversion Heqe].
  - (* v1 = abs e B *)
    inductions Red2;
      try solve [constructor*].
    apply TReduce_arrow; auto.
    auto_sub.
  - (* v = v1,,v2 v1'~->v0 *)
    inverts* Val.
    inverts* Lc.
    induction Red2;
      eauto.
  - (* v = v1,,v2 v2'~->v0 *)
    inverts* Val.
    inverts* Lc.
    induction Red2;
      eauto.
  - (* and *)
    gen v0.
    induction B0; introv Red2;
      try solve [inverts* Red2];
      try solve [inversion Ord].
Qed.

Lemma consistent_afterTR : forall v A B C v1 v2, value v -> Typing nil v Inf C -> TypedReduce v A v1 -> TypedReduce v B v2 -> consistencySpec v1 v2.
Proof.
  intros v A B C v1 v2 Val Typ Red1 Red2.
  unfold consistencySpec.
  intros D v1' v2' Red1' Red2'.
  forwards*: TypedReduce_trans Red1 Red1'.
  forwards*: TypedReduce_trans Red2 Red2'.
  forwards*: TypedReduce_unique H H0.
Qed.

Lemma TypedReduce_prv_value: forall v A v',
    value v -> TypedReduce v A v' -> value v'.
Proof.
  intros v A v' Val Red.
  induction* Red.
  -
    apply value_anno.
    inverts* H.
  - inverts* Val.
  - inverts* Val.
Qed.

Hint Immediate TypedReduce_prv_value : core.

Lemma TypedReduce_preservation: forall v v' A,
    value v -> TypedReduce v A v'-> Typing nil v Chk A
    -> exists B, Typing nil v' Inf B /\ subsub B A.
Proof with auto.
  introv Val Red Typ'.
  lets (C & Typ & Sub): Typing_chk2inf Typ'.
  clear Typ' Sub. gen C.
  induction Red; intros;
    try solve [inverts* Typ].
  - (* top *)
    exists*.
    apply toplike_super_top in H1.
    eauto.
  - (* absv *)
    inverts Typ.
    exists*. split.
    eapply Typ_abs.
    intros.
    applys~ Typing_chk_sub.
    auto_sub.
  - (* mergel *)
    inverts Val.
    inverts Typ;
      forwards*: IHRed.
  - (* merger *)
    inverts Val.
    inverts Typ;
      forwards*: IHRed.
  - (* merge_and *)
    forwards* (?&?&?): IHRed1 Val Typ.
    forwards* (?&?&?): IHRed2 Val Typ.
    lets Con: consistent_afterTR Val Typ Red1 Red2.
    exists. split.
    applys* Typ_mergev.
    eauto.
Qed.

Lemma preservation_subsub : forall e e' dir A,
    Typing nil e dir A ->
    step e e' ->
    exists C, Typing nil e' dir C /\ subsub C A.
Proof.
  introv Typ. gen e'.
  lets Typ' : Typ.
  inductions Typ;
    try solve [introv J; inverts* J]; introv J.
  - Case "typing_app".
    inverts* J.
    + (* top *)
      inverts Typ1. inverts* H.
    + (* e_absv A0 . e : A0->B0  v *)
      inverts Typ1. inverts H.
      exists B. split*.
      constructor.
      forwards* (?&Typ_v'&Sub): TypedReduce_preservation H5.
      pick_fresh y.
      forwards~ Typ_chk: H8 y.
      rewrite_env(nil++[(y,A)]++nil) in Typ_chk.
      forwards~ (?&?&?): Typing_subst_2 Typ_chk Typ_v'.
      eapply Typing_chk_sub.
      rewrite* (@subst_exp_intro y).
      apply~ subsub2sub.
    + forwards* (?&?&?): IHTyp1.
      forwards* (?&C'&?&?&?): arrTyp_subsub H H1.
      exists C'. split*.
      applys* Typ_app.
      applys~ Typing_chk_sub Typ2.
    +
      forwards* (?&?&?): IHTyp2.
      apply subsub2sub in H1.
      forwards*: Typing_chk_sub H0 H1.
  - Case "Typ_merge".
    inverts* J.
    + forwards~ (?&?&?): IHTyp1 H4.
      exists (t_and x B). split*.
      apply~ Typ_merge.
      forwards*: subsub_disjoint_l H1 H.
    + forwards~ (?&?&?): IHTyp2 H4.
      exists (t_and A x). split*.
      apply~ Typ_merge.
      forwards*: subsub_disjoint_r H1 H.
  - Case "typing_anno".
    inverts J.
    + forwards*: TypedReduce_prv_value e e'.
      inverts* Typ'.
      forwards*: TypedReduce_preservation H3.
    + forwards* (?&?&?): IHTyp.
      exists A. split*.
      apply Typ_anno.
      apply subsub2sub in H0.
      forwards*: Typing_chk_sub H H0.
  - Case "typing_fix".
    inverts J.
    exists A. split*.
    eapply Typ_anno.
    pick_fresh x.
    rewrite* (@subst_exp_intro x).
    forwards~ Typ_chk: H.
    rewrite_env(nil++[(x,A)]++nil) in Typ_chk.
    lets~ (?&?&?): Typing_subst_2 Typ_chk Typ'.
    apply subsub2sub in H2.
    forwards*: Typing_chk_sub H2.
  - Case "typing_mergev".
    inverts J.
    + inverts H0.
      forwards*: step_not_value H5 H6.
    + inverts H0.
      forwards*: step_not_value H7 H6.
  - Case "Typ_sub".
    forwards* (?&?&?): IHTyp.
    exists B. split*.
    apply subsub2sub in H1.
    assert (S: sub x B) by auto_sub.
    forwards*: Typ_sub H0 S.
Qed.


Theorem preservation : forall e e' dir A,
    Typing nil e dir A ->
    step e e' ->
    Typing nil e' Chk A.
Proof.
  intros e e' dir A H H0.
  lets* (?&?&?): preservation_subsub H H0.
  apply subsub2sub in H2.
  destruct dir.
  - sapply* Typ_sub.
  - sapply* Typing_chk_sub.
Qed.


(* Progress *)
Lemma TypedReduce_progress: forall v A,
    value v -> Typing [] v Chk A -> exists v', TypedReduce v A v'.
Proof.
  intros v A Val TypC.
  lets* (B&Typ&Sub): Typing_chk2inf TypC. clear TypC. gen v B.
  induction A; intros v Val.
  - inductions Val; intros; inverts Typ; try solve [inverts Sub].
    + exists*.
    + lets Lc1: value_lc Val1.
      lets Lc2: value_lc Val2.
      inverts Sub.
      forwards* (?&?): IHVal1 H5.
      forwards* (?&?): IHVal2 H5.
    + lets Lc1: value_lc Val1.
      lets Lc2: value_lc Val2.
      inverts Sub.
      forwards* (?&?): IHVal1 H7.
      forwards* (?&?): IHVal2 H7.
  - lets Lc: value_lc Val.
    intros. exists. apply~ TReduce_top.
  - lets Lc: value_lc Val.
    intros.
    destruct (toplike_decidable A2).
    + exists. apply~ TReduce_top.
    + inductions Typ; try solve [inverts Val].
      * exfalso. apply H0.
        apply toplike_super_top in Sub.
        inverts* Sub.
      * inverts Sub.
        exfalso. apply H0.
        apply~ toplike_super_top.
      * clear H0.
        inverts Val. inverts Lc.
        lets* S1: sub_inversion_arrow_l Sub.
        lets* S2: sub_inversion_arrow_r Sub.
      * inverts Val. inverts Lc.
        lets* [?|?]: sub_inversion_andl_arrr Sub.
        ** forwards* (?&?): IHTyp1.
        ** forwards* (?&?): IHTyp2.
      * inverts Val. inverts Lc.
        lets* [S | S]: sub_inversion_andl_arrr Sub.
        ** forwards* [? ?]: IHTyp1 S.
        ** forwards* [? ?]: IHTyp2 S.
  - intros.
    destruct~ (IHA1 _ Val _ Typ).
    auto_sub.
    destruct~ (IHA2 _ Val _ Typ).
    auto_sub.
    exists*.
Qed.

Theorem progress : forall e dir A,
    Typing nil e dir A ->
    value e \/ exists e', step e e' .
Proof. (*
  intro e.
  induction e; intros T Typ; inverts Typ; *)
  introv Typ.
  lets Typ': Typ.
  inductions Typ;
    lets Lc  : Typing_regular_1 Typ';
    try solve [inverts Heqflg];
    subst;
    try solve [left*];
    try solve [right*].
  - Case "var".
    invert H0.
  - Case "app".
    right. inverts Lc.
    lets* [Val1 | [e1' Red1]]: IHTyp1.
    lets* [Val2 | [e2' Red2]]: IHTyp2.
    inverts* Typ1;
      try solve [ inverts Val1 ].
    all: inverts H.
    + SCase "e_app (e_absv _ _) v2".
      lets* (v2' & Tyr): TypedReduce_progress Typ2.
  - Case "merge".
    inverts Lc.
    destruct~ IHTyp1 as [ Val1 | [t1' Red1]];
      destruct~ IHTyp2 as [ Val2 | [t2' Red2]];
      subst.
    + SCase "e_merge v1 e2".
      inverts* Typ1.
    + SCase "e_merge e1 v2".
      inverts* Typ2.
    + SCase "e_merge e1 e2".
      inverts* Typ2.
  - Case "anno".
    right. inverts Lc.
    destruct~ IHTyp as [? | (?&?)].
    +
      lets* (v1' & Tyr) : TypedReduce_progress H.
    + exists*.
  - Case "subsumption".
    destruct~ IHTyp.
Qed.


(* Type Safety *)
Theorem preservation_multi_step : forall e e' dir A,
    Typing nil e dir A ->
    e ->* e' ->
    exists C, Typing nil e' dir C /\ subsub C A.
Proof.
  introv Typ Red.
  gen A. induction* Red.
  intros.
  lets* (?&?&?): preservation_subsub Typ H.
  forwards* (?&?&?): IHRed H0.
  exists x0. split*.
  forwards*: subsub_trans H3 H1.
Qed.


Theorem type_safety : forall e e' dir A,
    Typing nil e dir A ->
    e ->* e' ->
    value e' \/ exists e'', step e' e''.
Proof.
  introv Typ Red. gen A.
  induction Red; intros.
  lets*: progress Typ.
  lets* (?&?&?): preservation_subsub Typ H.
Qed.
