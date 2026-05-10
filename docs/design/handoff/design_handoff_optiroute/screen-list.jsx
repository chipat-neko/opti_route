// OptiRoute — Screen 2: Liste des arrêts (tournée du jour)
// Header with stats, segmented filter, drag-reorderable list of stops.

const { TK, FONT_UI, FONT_MONO, Ico } = window;

function StatTile({ label, value, unit, accent, mono = true }) {
  return (
    <div style={{ flex: 1, minWidth: 0 }}>
      <div style={{
        fontFamily: mono ? FONT_MONO : FONT_UI,
        fontSize: 26, fontWeight: 700, color: TK.ink,
        letterSpacing: -0.5, lineHeight: 1,
      }}>
        {value}
        {unit && <span style={{ fontSize: 13, color: TK.textMute, marginLeft: 3, fontWeight: 500 }}>{unit}</span>}
      </div>
      <div style={{ fontSize: 11, color: TK.textMute, marginTop: 6, letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 600 }}>
        {label}
      </div>
    </div>
  );
}

function StopRow({ n, addr, sub, time, dist, state, tags = [], accent }) {
  const stateMeta = {
    done:    { bg: TK.emerald, fg: '#fff', label: '✓' },
    active:  { bg: TK.ink, fg: accent, label: n },
    pending: { bg: TK.paper, fg: TK.ink, label: n, border: TK.ink },
    fail:    { bg: TK.red, fg: '#fff', label: '!' },
  }[state];
  return (
    <div style={{
      display: 'flex', alignItems: 'flex-start', gap: 12,
      padding: '14px 18px', borderBottom: `1px solid ${TK.divider}`,
      background: state === 'active' ? '#FFFDF4' : 'transparent',
      position: 'relative',
    }}>
      {state === 'active' && (
        <div style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: 3, background: accent }}/>
      )}
      {/* Drag */}
      <div style={{ paddingTop: 8, color: TK.textFaint, flexShrink: 0 }}>{Ico.drag(16, TK.textFaint)}</div>
      {/* Pin chip */}
      <div style={{
        width: 36, height: 36, borderRadius: 10,
        background: stateMeta.bg, color: stateMeta.fg,
        border: stateMeta.border ? `1.5px solid ${stateMeta.border}` : 'none',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: FONT_MONO, fontWeight: 700, fontSize: 14, flexShrink: 0,
      }}>{stateMeta.label}</div>
      {/* Body */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: 15, fontWeight: 600, color: state === 'done' ? TK.textMute : TK.ink,
          textDecoration: state === 'done' ? 'line-through' : 'none',
          lineHeight: 1.3,
        }}>
          {addr}
        </div>
        <div style={{ fontSize: 12, color: TK.textMute, marginTop: 2, fontFamily: FONT_MONO }}>
          {sub}
        </div>
        {tags.length > 0 && (
          <div style={{ display: 'flex', gap: 5, marginTop: 8, flexWrap: 'wrap' }}>
            {tags.map((t, i) => (
              <span key={i} style={{
                fontSize: 10.5, fontWeight: 700, padding: '3px 8px', borderRadius: 6,
                background: t.bg || TK.creamSoft, color: t.fg || TK.ink,
                letterSpacing: 0.4, textTransform: 'uppercase',
              }}>{t.label}</span>
            ))}
          </div>
        )}
      </div>
      {/* Right meta */}
      <div style={{ textAlign: 'right', flexShrink: 0 }}>
        <div style={{ fontFamily: FONT_MONO, fontSize: 13, fontWeight: 700, color: TK.ink }}>{time}</div>
        <div style={{ fontFamily: FONT_MONO, fontSize: 11, color: TK.textMute, marginTop: 2 }}>{dist}</div>
      </div>
    </div>
  );
}

function SegFilter({ active, accent }) {
  const tabs = ['Tous · 24', 'À faire · 17', 'Faits · 6', 'Échec · 1'];
  return (
    <div style={{
      display: 'flex', gap: 6, padding: '0 18px 14px',
      overflow: 'hidden',
    }}>
      {tabs.map((t, i) => (
        <div key={i} style={{
          padding: '8px 12px', borderRadius: 18,
          background: i === active ? TK.ink : 'transparent',
          color: i === active ? '#fff' : TK.textMute,
          border: i === active ? 'none' : `1px solid ${TK.inkLine}`,
          fontSize: 12, fontWeight: 600, fontFamily: FONT_UI, whiteSpace: 'nowrap',
        }}>{t}</div>
      ))}
    </div>
  );
}

function Screen_List({ accent = TK.lime }) {
  return (
    <div style={{ width: '100%', height: '100%', background: TK.cream, fontFamily: FONT_UI, display: 'flex', flexDirection: 'column' }}>
      {/* Header */}
      <div style={{ padding: '18px 18px 14px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4 }}>
          <button style={{ width: 36, height: 36, border: 'none', background: 'transparent', padding: 0 }}>
            {Ico.back(22, TK.ink)}
          </button>
          <div style={{ fontSize: 11, color: TK.textMute, letterSpacing: 0.6, fontWeight: 600, textTransform: 'uppercase' }}>
            Mardi 12 mai
          </div>
          <button style={{ width: 36, height: 36, border: 'none', background: 'transparent', padding: 0 }}>
            {Ico.filter(20, TK.ink)}
          </button>
        </div>
        <div style={{ fontSize: 28, fontWeight: 800, color: TK.ink, letterSpacing: -0.5, lineHeight: 1.1, marginTop: 6 }}>
          Tournée #142
        </div>
        <div style={{ fontSize: 13, color: TK.textMute, marginTop: 4 }}>
          Paris 11<sup>e</sup> · Centre de tri Bastille → Nation
        </div>
      </div>

      {/* Stat bar */}
      <div style={{
        margin: '0 18px 16px', padding: '14px 16px',
        background: TK.paper, borderRadius: 18,
        boxShadow: '0 1px 0 rgba(14,20,16,0.04)',
        display: 'flex', alignItems: 'center', gap: 10,
      }}>
        <StatTile label="Arrêts" value="24"/>
        <div style={{ width: 1, height: 28, background: TK.divider }}/>
        <StatTile label="Distance" value="38.4" unit="km"/>
        <div style={{ width: 1, height: 28, background: TK.divider }}/>
        <StatTile label="Restant" value="2h41" mono/>
      </div>

      {/* Optimised banner */}
      <div style={{
        margin: '0 18px 16px', padding: '12px 14px',
        background: TK.ink, color: '#fff', borderRadius: 14,
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <div style={{
          width: 34, height: 34, borderRadius: 10, background: accent, color: TK.ink,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>{Ico.bolt(18, TK.ink)}</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 13, fontWeight: 700 }}>Itinéraire optimisé</div>
          <div style={{ fontSize: 11.5, color: '#cbd1cd' }}>−12.4 km · −47 min vs. ordre initial</div>
        </div>
        <span style={{
          fontFamily: FONT_MONO, fontSize: 11, fontWeight: 700, color: accent,
          background: 'rgba(184,242,74,0.15)', padding: '4px 8px', borderRadius: 6,
          border: `1px solid ${accent}55`,
        }}>−24%</span>
      </div>

      {/* Segmented filter */}
      <SegFilter active={1} accent={accent}/>

      {/* List */}
      <div style={{ flex: 1, overflow: 'auto', background: TK.paper, borderTop: `1px solid ${TK.divider}` }}>
        <StopRow n="6" addr="32 rue de la Roquette" sub="75011 · Mme Aubry" time="09:24" dist="—" state="done" accent={accent}/>
        <StopRow n="7" addr="14 rue du Faubourg St-Antoine" sub="75011 · Bât. B · code 4521A" time="09:38" dist="0.4 km"
          state="active" tags={[{label:'2 colis'},{label:'Signature', bg: TK.ink, fg: '#fff'}]} accent={accent}/>
        <StopRow n="8" addr="6 passage Thiéré" sub="75011 · 3e étage · gauche" time="09:51" dist="0.8 km"
          state="pending" tags={[{label:'Fragile', bg:'#FFE2D6', fg:'#A04114'}]} accent={accent}/>
        <StopRow n="9" addr="89 av. Ledru-Rollin" sub="75012 · Pharmacie de la Bastille" time="10:08" dist="1.2 km"
          state="pending" tags={[{label:'Avant 11h', bg: TK.amber+'33', fg:'#7A4F0E'},{label:'Pro'}]} accent={accent}/>
        <StopRow n="10" addr="2 place de la Nation" sub="75012 · Conciergerie 24/7" time="10:24" dist="1.7 km"
          state="pending" accent={accent}/>
        <StopRow n="11" addr="44 cours de Vincennes" sub="75012 · M. Tahir" time="10:39" dist="0.9 km"
          state="pending" tags={[{label:'Contre-rembours.', bg:'#FFE2D6', fg:'#A04114'}]} accent={accent}/>
      </div>

      {/* FAB */}
      <button style={{
        position: 'absolute', right: 18, bottom: 110,
        height: 56, padding: '0 20px 0 18px', borderRadius: 28,
        background: TK.ink, color: accent, border: 'none',
        display: 'flex', alignItems: 'center', gap: 10,
        boxShadow: '0 10px 28px rgba(14,20,16,0.30)',
        fontFamily: FONT_UI, fontWeight: 700, fontSize: 14,
      }}>
        {Ico.plus(20, accent)} Ajouter un arrêt
      </button>

      {/* Bottom action bar */}
      <div style={{
        background: TK.paper, padding: '12px 18px 14px', borderTop: `1px solid ${TK.divider}`,
        display: 'flex', gap: 10, alignItems: 'center',
      }}>
        <button style={{
          width: 48, height: 48, borderRadius: 14, border: `1.5px solid ${TK.ink}`,
          background: TK.paper, display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>{Ico.bolt(20, TK.ink)}</button>
        <button style={{
          flex: 1, height: 48, borderRadius: 14, border: 'none', background: TK.ink, color: accent,
          fontWeight: 700, fontSize: 14, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>
          {Ico.truck(18, accent)} Reprendre la tournée
        </button>
      </div>
    </div>
  );
}

window.Screen_List = Screen_List;
