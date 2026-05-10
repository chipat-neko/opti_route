// OptiRoute — Screen 4: Optimiser la tournée (avant/après)
const { TK, FONT_UI, FONT_MONO, Ico } = window;

function MiniMap({ w, h, route, accent, label, color = TK.textFaint, badge }) {
  const T = TK;
  return (
    <div style={{
      flex: 1, background: T.mapLand, borderRadius: 16, overflow: 'hidden',
      position: 'relative', border: `1px solid ${T.inkLine}`,
    }}>
      <svg width="100%" height="100%" viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="xMidYMid slice">
        {/* Soft grid */}
        <g stroke={T.mapStroke} strokeWidth="1" opacity="0.4">
          {[0.2,0.4,0.6,0.8].map(t => (
            <line key={'h'+t} x1="0" y1={h*t} x2={w} y2={h*t}/>
          ))}
          {[0.2,0.4,0.6,0.8].map(t => (
            <line key={'v'+t} x1={w*t} y1="0" x2={w*t} y2={h}/>
          ))}
        </g>
        {/* Roads simplified */}
        <g stroke="#fff" strokeWidth="6" fill="none" strokeLinecap="round">
          <path d={`M -5 ${h*0.35} L ${w+5} ${h*0.35}`}/>
          <path d={`M ${w*0.4} -5 L ${w*0.4} ${h+5}`}/>
          <path d={`M ${w*0.75} -5 L ${w*0.75} ${h+5}`}/>
          <path d={`M -5 ${h*0.7} L ${w+5} ${h*0.7}`}/>
        </g>
        {/* Route */}
        <window.RouteLine w={w} h={h} pts={route} accent={color} withGlow={false}/>
        {/* Stops */}
        {route.map((p, i) => (
          <g key={i} transform={`translate(${w*p.x} ${h*p.y})`}>
            <circle r="6" fill={T.paper} stroke={T.ink} strokeWidth="1.5"/>
            <text x="0" y="3" textAnchor="middle" fontFamily={window.FONT_MONO} fontSize="8" fontWeight="700" fill={T.ink}>{i+1}</text>
          </g>
        ))}
      </svg>
      {/* Label */}
      <div style={{
        position: 'absolute', top: 10, left: 10, padding: '4px 8px',
        background: T.paper, borderRadius: 6, fontSize: 10.5, fontWeight: 700,
        letterSpacing: 0.6, textTransform: 'uppercase', color: T.ink,
        boxShadow: '0 1px 4px rgba(0,0,0,0.08)',
      }}>{label}</div>
      {/* Badge */}
      {badge && (
        <div style={{
          position: 'absolute', bottom: 10, right: 10, padding: '4px 8px',
          background: T.ink, color: accent, borderRadius: 6,
          fontSize: 11, fontWeight: 700, fontFamily: FONT_MONO,
        }}>{badge}</div>
      )}
    </div>
  );
}

function CompareRow({ label, before, after, delta, deltaGood = true }) {
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: '1fr auto auto auto', gap: 12,
      alignItems: 'center', padding: '12px 0',
      borderBottom: `1px solid ${TK.divider}`,
    }}>
      <div style={{ fontSize: 13, color: TK.textMute, fontWeight: 500 }}>{label}</div>
      <div style={{
        fontFamily: FONT_MONO, fontSize: 14, color: TK.textFaint,
        textDecoration: 'line-through', fontWeight: 600,
      }}>{before}</div>
      <div style={{ fontFamily: FONT_MONO, fontSize: 16, color: TK.ink, fontWeight: 700 }}>{after}</div>
      <div style={{
        fontFamily: FONT_MONO, fontSize: 11, fontWeight: 700,
        color: deltaGood ? TK.emerald : TK.red,
        background: deltaGood ? TK.emeraldSoft : '#FFE2DD',
        padding: '3px 7px', borderRadius: 6, minWidth: 48, textAlign: 'center',
      }}>{delta}</div>
    </div>
  );
}

function Screen_Optimize({ accent = TK.lime }) {
  const W = 200, H = 220;
  // Messy zigzag (initial order)
  const before = [
    {x:0.15,y:0.15},{x:0.78,y:0.22},{x:0.30,y:0.45},{x:0.85,y:0.55},
    {x:0.20,y:0.70},{x:0.65,y:0.78},{x:0.50,y:0.30},{x:0.40,y:0.85},
  ];
  // Optimised loop
  const after = [
    {x:0.15,y:0.15},{x:0.50,y:0.18},{x:0.78,y:0.22},{x:0.85,y:0.55},
    {x:0.65,y:0.78},{x:0.40,y:0.85},{x:0.20,y:0.70},{x:0.30,y:0.45},
  ];

  return (
    <div style={{ width: '100%', height: '100%', background: TK.cream, fontFamily: FONT_UI, display: 'flex', flexDirection: 'column' }}>
      {/* Header */}
      <div style={{ padding: '18px 18px 10px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button style={{ width: 36, height: 36, border: 'none', background: 'transparent', padding: 0 }}>
          {Ico.back(22, TK.ink)}
        </button>
        <div style={{ fontSize: 11, color: TK.textMute, letterSpacing: 0.6, fontWeight: 600, textTransform: 'uppercase' }}>
          Étape 2 / 3
        </div>
        <button style={{ width: 36, height: 36, border: 'none', background: 'transparent', padding: 0, fontSize: 13, color: TK.ink, fontWeight: 600 }}>
          Aide
        </button>
      </div>

      <div style={{ padding: '4px 18px 14px' }}>
        <div style={{ fontSize: 28, fontWeight: 800, color: TK.ink, letterSpacing: -0.6, lineHeight: 1.05 }}>
          Itinéraire optimisé
        </div>
        <div style={{ fontSize: 13.5, color: TK.textMute, marginTop: 6, lineHeight: 1.4 }}>
          Comparons l'ordre initial à la séquence calculée.
        </div>
      </div>

      {/* Comparison maps */}
      <div style={{ padding: '0 18px 14px', display: 'flex', gap: 10, height: 240 }}>
        <MiniMap w={W} h={H} route={before} accent={accent} label="Avant" color={TK.textFaint}/>
        <MiniMap w={W} h={H} route={after} accent={accent} label="Après" color={accent} badge="−24%"/>
      </div>

      {/* Hero gain */}
      <div style={{
        margin: '0 18px 14px', padding: '14px 16px',
        background: TK.ink, color: '#fff', borderRadius: 16,
        display: 'flex', alignItems: 'center', gap: 14,
      }}>
        <div style={{
          width: 46, height: 46, borderRadius: 14, background: accent, color: TK.ink,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>{Ico.bolt(22, TK.ink)}</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 11, color: '#cbd1cd', letterSpacing: 0.6, fontWeight: 600, textTransform: 'uppercase' }}>
            Gain estimé
          </div>
          <div style={{
            fontFamily: FONT_MONO, fontSize: 26, fontWeight: 700, letterSpacing: -0.5,
            display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 2,
          }}>
            −47<span style={{ fontSize: 14, color: '#cbd1cd' }}>min</span>
            <span style={{ fontSize: 14, color: accent }}>·</span>
            −12.4<span style={{ fontSize: 14, color: '#cbd1cd' }}>km</span>
          </div>
        </div>
      </div>

      {/* Detail compare */}
      <div style={{ padding: '0 18px', flex: 1, overflow: 'auto' }}>
        <div style={{
          padding: '0 16px', background: TK.paper, borderRadius: 16, border: `1px solid ${TK.divider}`,
        }}>
          <CompareRow label="Distance totale" before="50.8 km" after="38.4 km" delta="−24%"/>
          <CompareRow label="Durée estimée" before="3h28" after="2h41" delta="−23%"/>
          <CompareRow label="Demi-tours" before="6" after="1" delta="−83%"/>
          <CompareRow label="Carburant" before="6.3 L" after="4.7 L" delta="−1.6 L"/>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr auto auto auto', gap: 12, alignItems: 'center', padding: '12px 0' }}>
            <div style={{ fontSize: 13, color: TK.textMute }}>CO₂</div>
            <div style={{ fontFamily: FONT_MONO, fontSize: 14, color: TK.textFaint, textDecoration: 'line-through', fontWeight: 600 }}>14.2 kg</div>
            <div style={{ fontFamily: FONT_MONO, fontSize: 16, color: TK.ink, fontWeight: 700 }}>10.5 kg</div>
            <div style={{ fontFamily: FONT_MONO, fontSize: 11, fontWeight: 700, color: TK.emerald, background: TK.emeraldSoft, padding: '3px 7px', borderRadius: 6, minWidth: 48, textAlign: 'center' }}>−26%</div>
          </div>
        </div>

        {/* Constraints */}
        <div style={{ marginTop: 14 }}>
          <div style={{ fontSize: 11, color: TK.textMute, fontWeight: 600, letterSpacing: 0.6, textTransform: 'uppercase', marginBottom: 10 }}>
            Contraintes appliquées
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
            {[
              ['Avant 11h · 3 arrêts', TK.amber+'33', '#7A4F0E'],
              ['Fragile en haut', TK.creamSoft, TK.ink],
              ['Sens unique', TK.creamSoft, TK.ink],
              ['Éviter A86', TK.creamSoft, TK.ink],
              ['Retour dépôt 12:30', TK.emeraldSoft, TK.emeraldDark],
            ].map(([t,bg,fg],i) => (
              <span key={i} style={{
                fontSize: 11.5, fontWeight: 600, padding: '6px 10px', borderRadius: 16,
                background: bg, color: fg,
              }}>{t}</span>
            ))}
          </div>
        </div>
      </div>

      {/* Bottom actions */}
      <div style={{
        background: TK.paper, padding: '14px 18px 16px', borderTop: `1px solid ${TK.divider}`,
        display: 'flex', gap: 10, alignItems: 'center',
      }}>
        <button style={{
          flex: 1, height: 52, borderRadius: 26, border: `1.5px solid ${TK.ink}`,
          background: TK.paper, color: TK.ink, fontWeight: 700, fontSize: 14,
        }}>Réajuster</button>
        <button style={{
          flex: 2, height: 52, borderRadius: 26, border: 'none',
          background: TK.ink, color: accent, fontWeight: 700, fontSize: 14,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
        }}>
          {Ico.check(18, accent)} Appliquer cet ordre
        </button>
      </div>
    </div>
  );
}

window.Screen_Optimize = Screen_Optimize;
