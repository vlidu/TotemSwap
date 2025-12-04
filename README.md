# TotemSwap

TotemSwap est un addon World of Warcraft 1.12 (Turtle WoW) qui équipe automatiquement le totem dans la main gauche en fonction du sort lancé par le Chaman. Il facilite la rotation en évitant les changements manuels d’items.

---

## Fonctionnalités

- Équipe **Totem of Rage** lors du lancement de :
  - Earth Shock
  - Flame Shock
  - Frost Shock

- Équipe **Totem of the Storm** lors du lancement de :
  - Lightning Bolt
  - Chain Lightning

- Équipe **Totem of Eruption** lors du lancement de :
  - Molten Blast

- Gestion des cooldowns et délais d’équipement pour ne pas spammer les swaps inutilement :
  - 6 secondes pour les shocks et Chain Lightning
  - 1.8 secondes pour Lightning Bolt
  - GCD throttle pour Molten Blast

- Compatible avec les ranks de sorts (basé sur 1.12).

- Bloque les swaps lors d’interactions avec les marchands, banque, hôtel des ventes, etc.

- Option de messages de debug activables/désactivables.

---

## Installation

1. Télécharge le zip du code de l'addon

2. Extrait tout, et renomme le dossier en `TotemSwap` 

3. Place ce dossier dans le répertoire `Interface/AddOns/` de ton client WoW.

4. Activer l’addon depuis l’écran de sélection de personnage.

---

## Commandes Slash

- `/ts` ou `/totemswap` : active/désactive l’addon.
- `/ts on` : active l’addon.
- `/ts off` : désactive l’addon.
- `/ts spam` : active/désactive les messages de swap.
- `/ts status` : affiche l’état actuel de l’addon.

---

## Notes

- Assure-toi d’avoir les totems (`Totem of Rage`, `Totem of the Storm`, `Totem of Eruption`) soit équipés, soit dans ton inventaire.
- L’addon équipe uniquement les totems dans la main gauche (slot 17).
- Conçu pour Turtle WoW 1.12, peut nécessiter ajustements pour d’autres versions.

---

## Licence

TotemSwap est libre et gratuit pour usage personnel. Ne pas distribuer sans permission.

---

## Auteur

Développé par Frozr, adapté sur demande.

---

N’hésite pas à me faire savoir si tu souhaites des améliorations ou ajustements !
