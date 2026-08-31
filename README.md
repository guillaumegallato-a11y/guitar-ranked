# Guitar Ranked V3

Nouveautés :
- bouton Modifier sur les morceaux pour l'admin ;
- nombre illimité de documents PNG/JPG/WEBP/PDF par morceau ;
- sélection de plusieurs fichiers en une fois ;
- ajout de nouveaux documents plus tard sans supprimer le morceau ;
- suppression d'un document de la publication ;
- ordre des documents modifiable avec les flèches ;
- images de tablature affichées en grand sous la vidéo ;
- clic sur une image pour l'ouvrir en très grand ;
- morceaux existants conservés.

## Installation
1. Remplace le code de ton dépôt GitHub par le contenu de ce dossier (garde tes variables Vercel existantes).
2. Dans Supabase > SQL Editor, exécute `supabase-v3-documents.sql` UNE FOIS.
3. Laisse Vercel redéployer le projet, ou lance un Redeploy.
4. Recharge le site avec Ctrl+Shift+R.

## Important
Le script SQL migre automatiquement l'ancienne tablature unique vers `documents`, donc tes tablatures existantes ne sont pas censées disparaître.
