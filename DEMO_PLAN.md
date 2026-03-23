# Modern Treasury Demo — Teams & Workspaces

---

## Pourquoi cette structure

L'objectif est de montrer que Forest n'est pas juste un outil — c'est une plateforme où chaque rôle a sa propre réalité. Même record, vues différentes, actions différentes. La séparation des tâches est dans l'outil, pas dans une procédure Word.

---

## 3 Teams

### Team "Out of the Box"

Aucune customisation. Collections brutes exposées par l'agent ActiveRecord, rien d'autre.

Utilisée 30 secondes au début de la démo : _"Voilà votre DB brute."_ Puis switch vers Operations — le contraste fait le travail.

### Team "Operations" (L1 Ops + TAM)

Le quotidien des ops analysts et TAMs. Vues simplifiées, pas de full TX history, pas de Sardine JSON brut. Smart Fields visibles (`tier`, `days_held`, `sla_status`, `sardine_risk_score`).

Actions disponibles : Send RFI, Enable Payments.
Actions non disponibles : Release Payment, Block Payment, Suspend Entity.

### Team "Compliance"

Vue enrichie. Full transaction history, Sardine data complet, entity graph, Decision details, Evaluation records.

Actions disponibles : tout — Approve, Release, Block, Suspend Entity, Send RFI.

---

## Workspaces par team

| #   | Operations           | Compliance           |
| --- | -------------------- | -------------------- |
| 1   | Welcome & Demo Guide | Welcome & Demo Guide |
| 2   | Architecture & Tech  | Architecture & Tech  |
| 3   | Held Payments        | Compliance Queue     |
| 4   | Onboarding           | Entity 360           |
| 5   | Entity 360           | —                    |

---

## Détail de chaque workspace

### Welcome & Demo Guide

**Présent dans : Operations, Compliance**

Plan cliquable de la démo. Liens directs vers chaque workspace. Contexte du cas hero (Corner Coffee LLC, $45k wire, HIGH risk). Sert de téléprompter pendant la présentation — si tu perds le fil, tu reviens ici et tu retrouves ta place.

Composants : Text components (sections du plan), Link components (liens vers chaque workspace et records clés), Field component (compteur live Held Payments).

---

### Architecture & Tech

**Présent dans : Operations, Compliance**

Répond aux questions techniques de MT avant même qu'elles soient posées. Contenu identique dans les deux teams — présent dans les deux pour ne pas avoir à switcher de team pendant la démo.

Contenu suggéré :

- Schéma d'intégration (Ruby agent → Aurora Postgres → Forest UI)
- "Votre data ne quitte pas votre VPC" — hybrid model expliqué
- ORM-first : Forest lit via ActiveRecord, pas de copie, pas de sync, pas de drift
- Schema evolution : republier le schema Forest, aucun impact sur votre codebase
- Webhook flow : Sardine → Flow (holds payment) → Forest lit via ORM → case visible immédiatement
- Réponses aux questions récurrentes : champ-level access, hybrid read ORM / write API, performance

---

### Held Payments

**Présent dans : Operations uniquement**

Le workspace hero. Utilisé pour le cas Corner Coffee de bout en bout.

Layout :

- Gauche : liste des Transfers en `status = held`, triée par montant desc puis `held_at` asc. Colonnes : entity name, `amount_display`, `sla_status` (badge coloré), `days_held`.
- Droite (sourced du Transfer sélectionné) : panneaux Entity, Payment, Risk, KYB (Airtable/Persona), CRM (Salesforce).
- Bas droite : boutons Send RFI et Release Payment (ce dernier déclenche l'approval gate si amount > $10k ou risk_rating = high).

Moment clé : quand Release Payment déclenche l'approval gate, le cas apparaît dans la Compliance Queue. C'est le point de transition entre les deux teams.

---

### Compliance Queue

**Présent dans : Compliance uniquement**

Vue du Compliance officer. Point d'arrivée après le switch de team.

Layout :

- Gauche : Inbox component — approvals en attente (Release Payment, Block Payment, Suspend Entity).
- Droite (sourced de l'approval sélectionné) : même case Corner Coffee, mais panneaux enrichis — full TX history (90 jours), Sardine data JSON complet, entity graph C1→C2, reasoning de l'opérateur L1, Decision details Persona.
- Bas droite : boutons Approve / Reject.

Moment clé : même record que dans Held Payments, mais la vue est différente et les actions sont différentes. Le RBAC devient concret sans explication.

---

### Onboarding

**Présent dans : Operations uniquement**

Second scénario si le temps le permet. Fresh Beans Co — KYB done, UBO docs manquants.

Layout :

- Gauche : liste des LegalEntities en `status = pending`, triée par `created_at` asc (FIFO).
- Droite : panneau KYB (Airtable) avec `docs_collected` vs `docs_missing` en évidence, statut UBOs, bouton Send RFI pré-filtré sur `template_type = ubo_documentation`.

Moment clé : Time to First Transaction — chaque jour de délai ici est du revenu bloqué pour MT et pour leur client.

---

### Entity 360

**Présent dans : Operations et Compliance**

Vue de recherche ad hoc. Utile pour Support, TAMs, et pour répondre à une question inbound pendant la démo.

Layout :

- Search component sur LegalEntity (par name, external_id, public_id).
- Field components : tier, status, risk_rating, kyb_status, programme.
- Collection Relationship : children (sub-entities C2).
- Collection Relationship : transfers récents (via account).
- Collection Relationship : decisions (KYB history).
- Collection Relationship : persona_inquiries (Airtable).

Différence Operations vs Compliance : en Compliance, les champs Decision.details et Verification\_\_Sardine.data sont visibles. En Operations, seuls les Smart Fields résumés (`sardine_risk_score`, `kyb_status`) sont affichés.

---

## Le moment clé de la démo

Switch de la team Operations à la team Compliance sur le **même case Corner Coffee**.

- En Operations : panneau Risk = score + reason (Smart Fields). Bouton Release Payment présent mais déclenche une approval gate.
- En Compliance : panneau Risk = Sardine JSON complet. Full TX history visible. Reasoning de l'opérateur affiché. Bouton Approve disponible.

Même record. Deux vues. Deux niveaux de pouvoir. C'est ça le RBAC — pas un slide, pas une explication, une démonstration.
