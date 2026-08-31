# Guitar Ranked V5

Cette version conserve l'architecture Vite + React + Supabase et ajoute :
- nouveau logo Guitar Ranked ;
- page d'accueil ;
- textes modifiables directement depuis le site quand l'admin est connecté ;
- page Tablatures ;
- clic sur un morceau => défilement automatique vers sa vidéo/tablature ;
- correction du défilement horizontal mobile ;
- sauvegarde des modifications de morceaux renforcée avec message d'erreur explicite ;
- documents multiples conservés.

## Important : 2 scripts SQL
Si `supabase-v3-documents.sql` a déjà été exécuté, ne le relance pas obligatoirement.
Exécute UNE FOIS `supabase-v5-site-content.sql` dans Supabase > SQL Editor pour activer les textes modifiables.

Ensuite remplace les fichiers du repo par ceux de cette archive et laisse Vercel redéployer.
