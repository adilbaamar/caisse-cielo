# Caisse Cielo — app iPhone (Tap to Pay)

Enveloppe native de https://caisse.cielomontreal.ca avec Stripe Terminal « Tap to Pay sur iPhone ».
Compilée par GitHub Actions (macOS), signée en développement (iPhones enregistrés chez Apple), installée directement depuis une page web (GitHub Pages) — pas de TestFlight, pas d'App Store.

## Déjà fait (compte Apple 9HG344VX7Z)
- App ID `ca.cielomontreal.caisse` avec Tap to Pay on iPhone activé (autorisation Apple accordée, dossier 23231462)
- Certificat « Apple Development: Adil Baamar » (expire 2027-10-30)
- Profil « Caisse Cielo Dev » (iPhone comptoir Cielo), expire 2027-10-31 — lu automatiquement au build

## Secrets GitHub (Settings → Secrets and variables → Actions)
- `P12_BASE64` — certificat + clé privée (fourni par Claude)
- `P12_PASSWORD` — son mot de passe

## Build et installation
`git push` sur `main` (ou Actions → Run workflow) → ~10 min → page d'installation :
`https://<compte>.github.io/<repo>/` à ouvrir dans Safari sur l'iPhone enregistré → « Installer l'app ».

## Ajouter un iPhone
1. Sur l'iPhone : https://caisse.cielomontreal.ca/udid → Installer (envoie l'UDID).
2. developer.apple.com → Devices → + (coller l'UDID) ; Profiles → « Caisse Cielo Dev » → Edit → cocher l'appareil → Save → Download.
3. Déposer le nouveau profil dans Supabase (`pos_fichiers`, nom `Caisse_Cielo_Dev.mobileprovision`) et relancer le workflow.

## Pont web ↔ natif
`cielo-tap.js` expose `window.CieloTap` ; la caisse affiche alors le mode « Carte · Tap to Pay ».
Serveur : `/.netlify/functions/terminal` (token, intent, confirm, location).
