// OptiRoute — Screen 3: Ajouter des arrêts (multi-méthodes)
const { TK, FONT_UI, FONT_MONO, Ico } = window;

function MethodCard({ icon, title, sub, accent, big = false, dark = false }) {
  return (
    <div style={{
      borderRadius: 18, padding: big ? '18px' : '14px',
      background: dark ? TK.ink : TK.paper,
      color: dark ? '#fff' : TK.ink,
      border: dark ? 'none' : `1px solid ${TK.divider}`,
      display: 'flex', flexDirection: 'column', gap: big ? 18 : 10,
      minHeight: big ? 120 : 96,
      position: 'relative', overflow: 'hidden',
    }}>
      <div style={{
        width: 38, height: 38, borderRadius: 12,
        background: dark ? accent : TK.creamSoft,
        color: dark ? TK.ink : TK.ink,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>{icon}</div>
      <div>
        <div style={{ fontSize: big ? 16 : 14, fontWeight: 700, lineHeight: 1.2 }}>{title}</div>
        <div style={{ fontSize: 11.5, color: dark ? '#cbd1cd' : TK.textMute, marginTop: 4, lineHeight: 1.3 }}>{sub}</div>
      </div>
    </div>
  );
}

function PendingChip({ addr, sub, accent }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '10px 12px', background: TK.paper, borderRadius: 12,
      border: `1px solid ${TK.divider}`,
    }}>
      <div style={{
        width: 28, height: 28, borderRadius: 9, background: TK.creamSoft,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>{Ico.pin(14, TK.ink)}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: TK.ink, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{addr}</div>
        <div style={{ fontSize: 11, color: TK.textMute, fontFamily: FONT_MONO, marginTop: 1 }}>{sub}</div>
      </div>
      <button style={{
        width: 26, height: 26, borderRadius: 13, border: 'none',
        background: TK.creamSoft, display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>{Ico.close(14, TK.ink)}</button>
    </div>
  );
}

function Screen_Add({ accent = TK.lime }) {
  return (
    <div style={{ width: '100%', height: '100%', background: TK.cream, fontFamily: FONT_UI, display: 'flex', flexDirection: 'column' }}>
      {/* Header */}
      <div style={{ padding: '18px 18px 8px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button style={{ width: 36, height: 36, border: 'none', background: 'transparent', padding: 0 }}>
          {Ico.close(22, TK.ink)}
        </button>
        <div style={{ fontSize: 11, color: TK.textMute, letterSpacing: 0.6, fontWeight: 600, textTransform: 'uppercase' }}>
          Tournée #142
        </div>
        <div style={{ width: 36 }}/>
      </div>

      <div style={{ padding: '4px 18px 12px' }}>
        <div style={{ fontSize: 28, fontWeight: 800, color: TK.ink, letterSpacing: -0.6, lineHeight: 1.1 }}>
          Ajouter des arrêts
        </div>
        <div style={{ fontSize: 13.5, color: TK.textMute, marginTop: 6, lineHeight: 1.4 }}>
          Tape, dicte, scanne une étiquette ou colle une liste — on s'occupe du reste.
        </div>
      </div>

      {/* Search */}
      <div style={{ padding: '0 18px 14px' }}>
        <div style={{
          height: 56, background: TK.paper, borderRadius: 16,
          border: `1.5px solid ${TK.ink}`,
          display: 'flex', alignItems: 'center', padding: '0 8px 0 16px', gap: 10,
        }}>
          {Ico.search(20, TK.ink)}
          <div style={{ flex: 1, color: TK.text, fontSize: 15 }}>
            14 rue du Faubour<span style={{
              display: 'inline-block', width: 1.5, height: 18, background: TK.ink,
              verticalAlign: 'middle', marginLeft: 1, animation: 'caret 1s steps(2) infinite',
            }}/>
          </div>
          <button style={{
            width: 40, height: 40, borderRadius: 12, border: 'none',
            background: accent, display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>{Ico.voice(18, TK.ink)}</button>
        </div>
        {/* Suggestion */}
        <div style={{
          marginTop: 8, padding: '12px 14px', background: TK.paper, borderRadius: 12,
          border: `1px solid ${TK.divider}`, display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <div style={{
            width: 28, height: 28, borderRadius: 9, background: accent,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>{Ico.pin(14, TK.ink)}</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13.5, fontWeight: 600, color: TK.ink }}>
              <strong>14 rue du Faubourg</strong> Saint-Antoine
            </div>
            <div style={{ fontSize: 11.5, color: TK.textMute }}>75011 Paris · 2.1 km</div>
          </div>
          <span style={{
            padding: '4px 8px', borderRadius: 6, background: TK.creamSoft, fontSize: 10.5, fontWeight: 700, color: TK.ink,
          }}>↵</span>
        </div>
      </div>

      {/* Methods grid */}
      <div style={{ padding: '0 18px 16px' }}>
        <div style={{ fontSize: 11, color: TK.textMute, fontWeight: 600, letterSpacing: 0.6, textTransform: 'uppercase', marginBottom: 10 }}>
          Ou ajoutez en lot
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          <MethodCard icon={Ico.scan(20, TK.ink)} title="Scanner étiquette" sub="OCR · code-barres · QR" accent={accent} dark/>
          <MethodCard icon={Ico.photo(20, TK.ink)} title="Photo bordereau" sub="Détecte les adresses" accent={accent}/>
          <MethodCard icon={Ico.paste(20, TK.ink)} title="Coller une liste" sub="CSV, texte, e-mail" accent={accent}/>
          <MethodCard icon={Ico.voice(20, TK.ink)} title="Dicter" sub='"Ajoute 14 Faubourg..."' accent={accent}/>
        </div>
      </div>

      {/* Pending stops */}
      <div style={{ padding: '4px 18px 12px', flex: 1, overflow: 'auto' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 10 }}>
          <div style={{ fontSize: 11, color: TK.textMute, fontWeight: 600, letterSpacing: 0.6, textTransform: 'uppercase' }}>
            En attente · 3
          </div>
          <span style={{ fontSize: 12, color: TK.emerald, fontWeight: 600 }}>Tout effacer</span>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <PendingChip addr="22 rue Oberkampf, Paris" sub="75011 · M. Sow" accent={accent}/>
          <PendingChip addr="3 bd Voltaire, Paris" sub="75011 · Café des Arts" accent={accent}/>
          <PendingChip addr="91 rue de Charonne, Paris" sub="75011 · code 8842B" accent={accent}/>
        </div>
      </div>

      {/* Bottom CTA */}
      <div style={{
        background: TK.paper, padding: '14px 18px 16px', borderTop: `1px solid ${TK.divider}`,
        display: 'flex', gap: 10, alignItems: 'center',
      }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 11, color: TK.textMute, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase' }}>3 nouveaux arrêts</div>
          <div style={{ fontSize: 14, fontWeight: 700, color: TK.ink, fontFamily: FONT_MONO }}>+5.2 km estimé</div>
        </div>
        <button style={{
          height: 52, padding: '0 22px', borderRadius: 26, border: 'none',
          background: TK.ink, color: accent, fontWeight: 700, fontSize: 14,
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          {Ico.bolt(18, accent)} Optimiser & insérer
        </button>
      </div>
      <style>{`@keyframes caret { 0%, 100% { opacity: 1 } 50% { opacity: 0 } }`}</style>
    </div>
  );
}

window.Screen_Add = Screen_Add;
