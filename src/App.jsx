import React, { useEffect, useMemo, useState } from 'react'
import { createClient } from '@supabase/supabase-js'
import { Search, Plus, Lock, Upload, Download, Trash2, X, Guitar, Play, FileText, ShieldCheck, LogOut, ChevronDown, ChevronRight, Cloud, AlertTriangle, Pencil, Save, ArrowUp, ArrowDown, ExternalLink } from 'lucide-react'
import bronze1 from './assets/icons/bronze-1.png'
import bronze2 from './assets/icons/bronze-2.png'
import bronze3 from './assets/icons/bronze-3.png'
import argent1 from './assets/icons/argent-1.png'
import argent2 from './assets/icons/argent-2.png'
import argent3 from './assets/icons/argent-3.png'
import or1 from './assets/icons/or-1.png'
import or2 from './assets/icons/or-2.png'
import or3 from './assets/icons/or-3.png'
import platine1 from './assets/icons/platine-1.png'
import platine2 from './assets/icons/platine-2.png'
import platine3 from './assets/icons/platine-3.png'
import diamant1 from './assets/icons/diamant-1.png'
import diamant2 from './assets/icons/diamant-2.png'
import diamant3 from './assets/icons/diamant-3.png'
import guitarHero from './assets/icons/guitar-hero.png'

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY
const supabase = SUPABASE_URL && SUPABASE_ANON_KEY ? createClient(SUPABASE_URL, SUPABASE_ANON_KEY) : null
const BUCKET = 'tabs'

const levels = [
  { id: 'bronze-1', group: 'bronze', groupName: 'Bronze', label: 'Bronze 1', color: '#c47a37', icon: bronze1 },
  { id: 'bronze-2', group: 'bronze', groupName: 'Bronze', label: 'Bronze 2', color: '#c47a37', icon: bronze2 },
  { id: 'bronze-3', group: 'bronze', groupName: 'Bronze', label: 'Bronze 3', color: '#c47a37', icon: bronze3 },
  { id: 'argent-1', group: 'argent', groupName: 'Argent', label: 'Argent 1', color: '#d6d9df', icon: argent1 },
  { id: 'argent-2', group: 'argent', groupName: 'Argent', label: 'Argent 2', color: '#d6d9df', icon: argent2 },
  { id: 'argent-3', group: 'argent', groupName: 'Argent', label: 'Argent 3', color: '#d6d9df', icon: argent3 },
  { id: 'or-1', group: 'or', groupName: 'Or', label: 'Or 1', color: '#f4b62a', icon: or1 },
  { id: 'or-2', group: 'or', groupName: 'Or', label: 'Or 2', color: '#f4b62a', icon: or2 },
  { id: 'or-3', group: 'or', groupName: 'Or', label: 'Or 3', color: '#f4b62a', icon: or3 },
  { id: 'platine-1', group: 'platine', groupName: 'Platine', label: 'Platine 1', color: '#69e7ee', icon: platine1 },
  { id: 'platine-2', group: 'platine', groupName: 'Platine', label: 'Platine 2', color: '#69e7ee', icon: platine2 },
  { id: 'platine-3', group: 'platine', groupName: 'Platine', label: 'Platine 3', color: '#69e7ee', icon: platine3 },
  { id: 'diamant-1', group: 'diamant', groupName: 'Diamant', label: 'Diamant 1', color: '#7a8dff', icon: diamant1 },
  { id: 'diamant-2', group: 'diamant', groupName: 'Diamant', label: 'Diamant 2', color: '#7a8dff', icon: diamant2 },
  { id: 'diamant-3', group: 'diamant', groupName: 'Diamant', label: 'Diamant 3', color: '#7a8dff', icon: diamant3 },
  { id: 'guitar-hero', group: 'guitar-hero', groupName: 'Guitar Hero', label: 'Guitar Hero', color: '#c655ff', icon: guitarHero },
]

const groups = [
  { id: 'bronze', name: 'Bronze', icon: bronze3, color: '#c47a37' },
  { id: 'argent', name: 'Argent', icon: argent3, color: '#d6d9df' },
  { id: 'or', name: 'Or', icon: or3, color: '#f4b62a' },
  { id: 'platine', name: 'Platine', icon: platine3, color: '#69e7ee' },
  { id: 'diamant', name: 'Diamant', icon: diamant3, color: '#7a8dff' },
  { id: 'guitar-hero', name: 'Guitar Hero', icon: guitarHero, color: '#c655ff' },
]

function getLevel(id) { return levels.find(l => l.id === id) || levels[0] }
function youtubeToEmbed(url) {
  if (!url) return ''
  if (url.includes('/embed/')) return url
  const watch = url.match(/[?&]v=([^&]+)/)
  if (watch?.[1]) return `https://www.youtube.com/embed/${watch[1]}`
  const short = url.match(/youtu\.be\/([^?&]+)/)
  if (short?.[1]) return `https://www.youtube.com/embed/${short[1]}`
  return url
}
function blankForm(){ return { title:'', artist:'', level:'bronze-1', youtube:'', description:'', documents:[], newFiles:[] } }
function normalizeDocuments(value){ return Array.isArray(value) ? value.filter(Boolean) : [] }
function formFromSong(song){ return { title: song.title || '', artist: song.artist || '', level: song.level || 'bronze-1', youtube: song.youtube || '', description: song.description || '', documents: normalizeDocuments(song.documents), newFiles: [] } }
function normalizeSong(row){
  let documents = normalizeDocuments(row.documents)
  if (!documents.length && row.tab_url) documents = [{ id:`legacy-${row.id}`, name:row.tab_name || 'Tablature', url:row.tab_url, type:row.tab_type || '', path:'' }]
  return { id: row.id, title: row.title || '', artist: row.artist || '', level: row.level || 'bronze-1', youtube: row.youtube || '', description: row.description || '', documents }
}
function dbSong(song){ return { title: song.title, artist: song.artist, level: song.level, youtube: song.youtube, description: song.description, documents: song.documents } }
function safeFileName(name){ return name.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-zA-Z0-9._-]/g, '-') }
function isImage(doc){ return doc?.type?.startsWith('image/') || /\.(png|jpe?g|webp)$/i.test(doc?.name || doc?.url || '') }
function isPdf(doc){ return doc?.type === 'application/pdf' || /\.pdf($|\?)/i.test(doc?.name || doc?.url || '') }

export default function App(){
  const [songs, setSongs] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [session, setSession] = useState(null)
  const [openGroups, setOpenGroups] = useState({ bronze: true })
  const [selectedLevel, setSelectedLevel] = useState('bronze-1')
  const [selectedId, setSelectedId] = useState(null)
  const [query, setQuery] = useState('')
  const [adminOpen, setAdminOpen] = useState(false)
  const [editingSong, setEditingSong] = useState(null)
  const [form, setForm] = useState(blankForm())

  useEffect(() => {
    if (!supabase) { setLoading(false); setError('Supabase n’est pas encore configuré dans Vercel.'); return }
    supabase.auth.getSession().then(({ data }) => setSession(data.session))
    const { data: listener } = supabase.auth.onAuthStateChange((_event, nextSession) => setSession(nextSession))
    fetchSongs()
    return () => listener.subscription.unsubscribe()
  }, [])

  async function fetchSongs(){
    if (!supabase) return
    setLoading(true); setError('')
    const { data, error } = await supabase.from('songs').select('*').order('created_at', { ascending: false })
    if (error) setError(error.message)
    else setSongs((data || []).map(normalizeSong))
    setLoading(false)
  }

  const level = getLevel(selectedLevel)
  const filtered = useMemo(()=>{
    const q = query.toLowerCase().trim()
    return songs.filter(s => s.level === selectedLevel).filter(s => !q || `${s.title} ${s.artist}`.toLowerCase().includes(q))
  }, [songs, selectedLevel, query])
  const selectedSong = songs.find(s=>s.id === selectedId && s.level === selectedLevel) || filtered[0] || null

  function toggleGroup(groupId){ setOpenGroups(current => ({ ...current, [groupId]: !current[groupId] })) }
  function chooseLevel(levelId){
    const nextLevel = getLevel(levelId)
    setSelectedLevel(levelId)
    setOpenGroups(current => ({ ...current, [nextLevel.group]: true }))
    const first = songs.find(s => s.level === levelId)
    setSelectedId(first?.id || null)
  }
  function openAddModal(){ setEditingSong(null); setForm({ ...blankForm(), level: selectedLevel }); setAdminOpen(true) }
  function openEditModal(song){ setEditingSong(song); setForm(formFromSong(song)); setAdminOpen(true) }

  async function uploadFiles(files, songId){
    if (!files?.length || !supabase) return []
    const uploaded = []
    for (let index = 0; index < files.length; index++) {
      const file = files[index]
      const path = `${songId || 'new'}/${Date.now()}-${index}-${safeFileName(file.name)}`
      const { error: uploadError } = await supabase.storage.from(BUCKET).upload(path, file, { upsert: false, contentType: file.type || undefined })
      if (uploadError) throw uploadError
      const { data } = supabase.storage.from(BUCKET).getPublicUrl(path)
      uploaded.push({ id: crypto.randomUUID?.() || `${Date.now()}-${index}`, name:file.name, url:data.publicUrl, type:file.type || '', path })
    }
    return uploaded
  }

  async function saveSong(e){
    e.preventDefault()
    if (!supabase) { setError('Configure Supabase avant de publier.'); return }
    if (!form.title.trim()) return
    setError('')
    try {
      const baseSong = { title:form.title.trim(), artist:form.artist.trim(), level:form.level, youtube:youtubeToEmbed(form.youtube.trim()), description:form.description.trim(), documents:normalizeDocuments(form.documents) }
      if (editingSong) {
        const addedDocs = await uploadFiles(form.newFiles, editingSong.id)
        const nextSong = { ...baseSong, documents:[...baseSong.documents, ...addedDocs] }
        const { data, error } = await supabase.from('songs').update(dbSong(nextSong)).eq('id', editingSong.id).select('*').single()
        if (error) throw error
        const saved = normalizeSong(data)
        setSongs(current => current.map(song => song.id === saved.id ? saved : song))
        setSelectedLevel(saved.level); setSelectedId(saved.id)
      } else {
        const { data:created, error:createError } = await supabase.from('songs').insert(dbSong({ ...baseSong, documents:[] })).select('*').single()
        if (createError) throw createError
        const addedDocs = await uploadFiles(form.newFiles, created.id)
        let finalRow = created
        if (addedDocs.length) {
          const { data:updated, error:updateError } = await supabase.from('songs').update({ documents:addedDocs }).eq('id', created.id).select('*').single()
          if (updateError) throw updateError
          finalRow = updated
        }
        const saved = normalizeSong(finalRow)
        setSongs(current => [saved, ...current])
        setSelectedLevel(saved.level); setSelectedId(saved.id)
      }
      setOpenGroups(current => ({ ...current, [getLevel(baseSong.level).group]: true }))
      setForm(blankForm()); setEditingSong(null); setAdminOpen(false)
    } catch (err) { setError(err.message || 'Erreur pendant la sauvegarde.') }
  }

  async function removeSong(id){
    if (!supabase) return
    const song = songs.find(s => s.id === id)
    if (!confirm(`Supprimer “${song?.title || 'ce morceau'}” ?`)) return
    for (const doc of normalizeDocuments(song?.documents)) {
      if (doc.path) await supabase.storage.from(BUCKET).remove([doc.path])
    }
    const { error } = await supabase.from('songs').delete().eq('id', id)
    if (error) { setError(error.message); return }
    const next = songs.filter(s=>s.id!==id)
    setSongs(next)
    const first = next.find(s=>s.level===selectedLevel)
    setSelectedId(first?.id || null)
  }

  return <div className="app">
    <aside className="sidebar">
      <div className="brand"><div className="brand-mark"><Guitar size={34}/></div><div><b>GUITAR</b><span>RANKED</span></div></div>
      <nav className="tier-nav">
        {groups.map(g => {
          const groupLevels = levels.filter(l => l.group === g.id)
          const isOpen = openGroups[g.id]
          return <div className="tier-block" key={g.id}>
            <button onClick={()=>toggleGroup(g.id)} className={`tier ${isOpen?'open':''}`} style={{'--accent':g.color}}>
              <img src={g.icon} alt="" /><div className="tier-text"><strong>{g.name}</strong></div><span className="chev">{isOpen ? <ChevronDown/> : <ChevronRight/>}</span>
            </button>
            {isOpen && <div className="level-list">{groupLevels.map(l => {
              const count = songs.filter(s=>s.level===l.id).length
              return <button key={l.id} onClick={()=>chooseLevel(l.id)} className={`level-button ${selectedLevel===l.id?'active':''}`} style={{'--accent':l.color}}><img src={l.icon} alt=""/><span>{l.label}</span><small>{count}</small></button>
            })}</div>}
          </div>
        })}
      </nav>
    </aside>

    <main className="main">
      <header className="topbar"><div><h1>CLASSEMENT DES MORCEAUX</h1><p>Classement par niveau de difficulté</p></div><div className="top-actions"><span className={`cloud-status ${supabase ? 'ok' : 'ko'}`}><Cloud size={16}/>{supabase ? 'Cloud' : 'Setup'}</span><button onClick={openAddModal} className="admin-btn"><Lock size={17}/> Admin</button></div></header>
      {!supabase && <div className="notice"><AlertTriangle size={18}/> Supabase n’est pas encore relié. Ajoute les variables VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY dans Vercel.</div>}
      {error && <div className="notice error"><AlertTriangle size={18}/> {error}</div>}
      <div className="mobile-tiers">{levels.map(l=><button key={l.id} onClick={()=>chooseLevel(l.id)} className={l.id===selectedLevel?'active':''} style={{'--accent':l.color}}><img src={l.icon} alt=""/><span>{l.label}</span></button>)}</div>
      <section className="hero-card" style={{'--accent':level.color}}><div className="hero-title"><img src={level.icon} alt=""/><div><h2>{level.label}</h2><p>{level.groupName}</p><small>Les morceaux ajoutés dans cette catégorie apparaissent ici.</small></div></div></section>
      <div className="search-row"><Search size={18}/><input value={query} onChange={e=>setQuery(e.target.value)} placeholder="Rechercher un morceau ou un artiste..." /></div>
      <section className="table-card">
        <div className="table-head"><span>#</span><span>MORCEAU</span><span>ARTISTE</span><span>DIFFICULTÉ</span></div>
        {loading ? <div className="empty">Chargement des morceaux...</div> : filtered.length ? filtered.map((song, i) => {
          const lvl = getLevel(song.level)
          return <button key={song.id} onClick={()=>setSelectedId(song.id)} className={`song-row ${selectedSong?.id===song.id?'selected':''}`}><span>{i+1}</span><span className="song-title"><b>{song.title}</b></span><span>{song.artist}</span><span className="difficulty"><img src={lvl.icon} alt=""/>{lvl.label}</span></button>
        }) : <div className="empty">Aucun morceau dans {level.label}. Ajoute ton premier morceau depuis l’admin.</div>}
      </section>
      <SongDetail song={selectedSong} isAdmin={!!session} onDelete={removeSong} onEdit={openEditModal}/>
    </main>
    {adminOpen && <AdminModal session={session} onClose={()=>{setAdminOpen(false); setEditingSong(null); setForm(blankForm())}} form={form} setForm={setForm} saveSong={saveSong} refresh={fetchSongs} editingSong={editingSong}/>} 
  </div>
}

function SongDetail({song, isAdmin, onDelete, onEdit}){
  const [lightbox, setLightbox] = useState(null)
  useEffect(()=>setLightbox(null), [song?.id])
  if(!song) return <section className="detail-card empty-detail"><h2>Aucun morceau sélectionné</h2><p>Ajoute un morceau pour afficher la vidéo et les documents ici.</p></section>
  const lvl = getLevel(song.level)
  const docs = normalizeDocuments(song.documents)
  return <>
    <section className="detail-card" style={{'--accent':lvl.color}}>
      <div className="detail-left"><img className="big-badge" src={lvl.icon} alt=""/><div><h2>{song.title}</h2><p>{song.artist}</p><span className="level-chip"><img src={lvl.icon} alt=""/> {lvl.label}</span>{song.description && <small>{song.description}</small>}{isAdmin && <div className="admin-actions"><button onClick={()=>onEdit(song)} className="edit"><Pencil size={16}/> Modifier</button><button onClick={()=>onDelete(song.id)} className="delete"><Trash2 size={16}/> Supprimer</button></div>}</div></div>
      <div className="detail-mid"><h3>VIDÉO</h3>{song.youtube ? <iframe src={song.youtube} allowFullScreen /> : <div className="placeholder"><Play/>Ajoute un lien YouTube pour ce morceau.</div>}</div>
      <div className="documents-section"><div className="documents-title"><h3>DOCUMENTS / TABLATURES</h3><span>{docs.length} document{docs.length>1?'s':''}</span></div>{docs.length ? <div className="documents-stack">{docs.map((doc,index)=><DocumentView key={doc.id || `${doc.url}-${index}`} doc={doc} index={index} onZoom={setLightbox}/>)}</div> : <div className="placeholder"><FileText/>Aucun document ajouté.</div>}</div>
    </section>
    {lightbox && <div className="lightbox" role="dialog" aria-modal="true" onClick={()=>setLightbox(null)}><button className="lightbox-close" onClick={()=>setLightbox(null)}><X/></button><img src={lightbox.url} alt={lightbox.name || 'Tablature agrandie'} onClick={e=>e.stopPropagation()}/></div>}
  </>
}

function DocumentView({doc,index,onZoom}){
  if(isImage(doc)) return <article className="document-card"><div className="document-head"><strong>Page {index+1}</strong><span>{doc.name}</span></div><button className="image-zoom" onClick={()=>onZoom(doc)} title="Agrandir"><img src={doc.url} alt={doc.name || `Tablature page ${index+1}`}/><span>Cliquer pour agrandir</span></button></article>
  if(isPdf(doc)) return <article className="document-card"><div className="document-head"><strong>PDF {index+1}</strong><span>{doc.name}</span></div><div className="pdf-actions"><a className="download" href={doc.url} target="_blank" rel="noreferrer"><ExternalLink size={16}/> Ouvrir le PDF</a><a className="download secondary" href={doc.url} download><Download size={16}/> Télécharger</a></div></article>
  return <article className="document-card"><div className="document-head"><strong>Document {index+1}</strong><span>{doc.name}</span></div><a className="download" href={doc.url} target="_blank" rel="noreferrer"><ExternalLink size={16}/> Ouvrir</a></article>
}

function AdminModal({session,onClose,form,setForm,saveSong,refresh,editingSong}){
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [authError, setAuthError] = useState('')
  const [busy, setBusy] = useState(false)

  async function login(e){ e.preventDefault(); setBusy(true); setAuthError(''); const { error } = await supabase.auth.signInWithPassword({ email, password }); if (error) setAuthError(error.message); setBusy(false) }
  async function logout(){ await supabase.auth.signOut(); refresh() }
  function addFiles(files){ setForm(current=>({ ...current, newFiles:[...current.newFiles, ...Array.from(files || [])] })) }
  function removeNewFile(index){ setForm(current=>({ ...current, newFiles:current.newFiles.filter((_,i)=>i!==index) })) }
  function removeExistingDoc(index){ setForm(current=>({ ...current, documents:current.documents.filter((_,i)=>i!==index) })) }
  function moveExistingDoc(index, direction){
    setForm(current=>{ const docs=[...current.documents]; const target=index+direction; if(target<0 || target>=docs.length) return current; [docs[index],docs[target]]=[docs[target],docs[index]]; return {...current,documents:docs} })
  }

  return <div className="modal-backdrop"><div className="modal"><button className="close" onClick={onClose}><X/></button><h2>{editingSong ? 'Modifier le morceau' : 'Espace admin'}</h2>
    {!supabase ? <div className="notice error"><AlertTriangle size={18}/> Configure Supabase dans Vercel avant d’utiliser l’admin.</div> : !session ? <form onSubmit={login} className="admin-login"><ShieldCheck/><p>Connecte-toi avec l’utilisateur créé dans Supabase Auth.</p><input type="email" value={email} onChange={e=>setEmail(e.target.value)} placeholder="Email admin"/><input type="password" value={password} onChange={e=>setPassword(e.target.value)} placeholder="Mot de passe"/>{authError && <p className="auth-error">{authError}</p>}<button disabled={busy} className="gold-button">{busy ? 'Connexion...' : 'Entrer'}</button></form> : <>
      <div className="backup-row"><span className="logged">Connecté</span><button onClick={logout}><LogOut size={16}/> Déconnexion</button></div>
      <form onSubmit={saveSong} className="admin-form">
        <select value={form.level} onChange={e=>setForm({...form,level:e.target.value})}>{levels.map(l=><option key={l.id} value={l.id}>{l.label}</option>)}</select>
        <input required value={form.title} onChange={e=>setForm({...form,title:e.target.value})} placeholder="Titre"/>
        <input value={form.artist} onChange={e=>setForm({...form,artist:e.target.value})} placeholder="Artiste"/>
        <input value={form.youtube} onChange={e=>setForm({...form,youtube:e.target.value})} placeholder="Lien YouTube"/>
        <textarea value={form.description} onChange={e=>setForm({...form,description:e.target.value})} placeholder="Description courte"/>

        {editingSong && form.documents.length>0 && <div className="doc-manager"><h3>Documents actuels</h3>{form.documents.map((doc,index)=><div className="doc-manager-row" key={doc.id || `${doc.url}-${index}`}><span>{index+1}. {doc.name || 'Document'}</span><div><button type="button" disabled={index===0} onClick={()=>moveExistingDoc(index,-1)} title="Monter"><ArrowUp size={15}/></button><button type="button" disabled={index===form.documents.length-1} onClick={()=>moveExistingDoc(index,1)} title="Descendre"><ArrowDown size={15}/></button><button type="button" className="danger-mini" onClick={()=>removeExistingDoc(index)} title="Retirer"><Trash2 size={15}/></button></div></div>)}</div>}

        <label className="upload"><Upload/> Ajouter un ou plusieurs documents<input type="file" multiple accept="image/png,image/jpeg,image/webp,application/pdf" onChange={e=>{addFiles(e.target.files); e.target.value=''}}/></label><p className="upload-help">Tu peux sélectionner plusieurs PNG/PDF d’un coup, puis revenir sur Modifier plus tard pour en ajouter encore.</p>
        {form.newFiles.length>0 && <div className="doc-manager"><h3>Nouveaux documents</h3>{form.newFiles.map((file,index)=><div className="doc-manager-row" key={`${file.name}-${index}`}><span>{file.name}</span><button type="button" className="danger-mini" onClick={()=>removeNewFile(index)}><Trash2 size={15}/></button></div>)}</div>}
        <p className="upload-hint">Tu peux sélectionner autant de fichiers que tu veux, puis revenir plus tard sur Modifier pour en ajouter d’autres.</p>
        <button className="gold-button">{editingSong ? <Save size={16}/> : <Plus size={16}/>} {editingSong ? 'Enregistrer les modifications' : 'Publier'}</button>
      </form>
    </>}
  </div></div>
}
