# TotemSwap

TotemSwap est un addon World of Warcraft 1.12 (Turtle WoW) qui équipe automatiquement le totem dans la main gauche en fonction du sort lancé par le Chaman. **GCD-based** (gère les casts annulés) avec **options configurables** pour les totems prioritaires.

---

## Fonctionnalités

- **Shocks** (Earth/Flame/Frost Shock) → **Totem of Rage** ou **Totem of the Stonebreaker** (configurable)
- **Bolts** (Lightning Bolt/Chain Lightning) → **Totem of the Storm** ou **Totem of Crackling Thunder** (configurable)
- **Molten Blast** → **Totem of Eruption**
- **GCD global** (1.5s) pour tous les swaps → parfait pour les casts annulés
- **Fallback automatique** : utilise l'autre totem si le prioritaire n'est pas disponible
- Compatible ranks, bloque les swaps en vendor/bank/HV, messages optionnels

---

## Installation

1. Télécharge le zip du code de l'addon

2. Extrait tout, et renomme le dossier en `TotemSwap` 

3. Place ce dossier dans le répertoire `Interface/AddOns/` de ton client WoW.

4. Activer l’addon depuis l’écran de sélection de personnage.

---

## Commandes Slash

/ts ou /totemswap → Toggle ON/OFF
/ts on → Activer
/ts off → Désactiver
/ts spam → Toggle messages de swap

---

### Configuration des totems
/ts shock [rage/r/stonebreaker/sb/stone] → Priorité Shocks
/ts bolt [storm/s/crackling/crack/c] → Priorité Bolts

---

### Status
/ts status ou /ts gcd → État + configs + timing dernier swap

---

## Exemple de Status

Shocks: Totem of Rage | Bolts: Totem of the Storm (1.2s depuis dernier swap)

---

## Configuration Recommandée

**Pour DPS Elemental classique :**
/ts shock rage
/ts bolt storm

**Pour burst maximisé :**
/ts shock stonebreaker
/ts bolt crackling

---

## Notes

- **Slots surveillés** : Main gauche (17) + tous les sacs
- **GCD-based** : Swap uniquement quand GCD=0 (même après cast annulé)
- **Totems requis** : Au moins un des deux totems par catégorie dans les sacs/équipé
- Turtle WoW 1.12 uniquement

---

## Licence

TotemSwap est libre et gratuit pour usage personnel. Ne pas distribuer sans permission.

---

## Auteur

Développé par Frozr, adapté sur demande.

---

N’hésite pas à me faire savoir si tu souhaites des améliorations ou ajustements !
