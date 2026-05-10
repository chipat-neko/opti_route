// OptiRoute — Screen 5: Navigation guidée (style turn-by-turn)
const { TK, FONT_UI, FONT_MONO, Ico } = window;

// Big maneuver icon
function Maneuver({ kind = 'right', accent }) {
  // Simple stylised arrow on a road
  return (
    <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
      <path d="M32 56 V36 a8 8 0 0 1 8 -8 H50" stroke="#fff" strokeWidth="10" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M32 56 V36 a8 8 0 0 1 8 -8 H50" stroke={accent} strokeWidth="6" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="m44 22 8 6 -8 6" stroke={accent} strokeWidth="6" strokeLinecap="round" strokeLinejoin="round" fill="none"/>
    </svg>
  );
}

function Screen_Navigation({ accent = TK.lime }) {
  const W = 396, H = 828;
  // Single road forward perspective (active route)
  const route = [
    { x: 0.5, y: 0.95 }, { x: 0.5, y: 0.78 }, { x: 0.5, y: 0.62 },
    { x: 0.62, y: 0.50 }, { x: 0.78, y: 0.42 }, { x: 0.85, y: 0.30 },
  ];

  return (
    <div style={{
      position: 'relative', width: '100%', height: '100%',
      background: '#0E1410', fontFamily: FONT_UI, overflow: 'hidden',
    }}>
      {/* Map (dark) */}
      <svg width="100%" height="100%" viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="xMidYMid slice"
        style={{ position: 'absolute', inset: 0 }}>
        <defs>
          <linearGradient id="navfade" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor="#0E1410" stopOpacity="0.9"/>
            <stop offset="0.4" stopColor="#0E1410" stopOpacity="0"/>
            <stop offset="1" stopColor="#0E1410" stopOpacity="0.9"/>
          </linearGradient>
        </defs>
        {/* Land dark */}
        <rect width={W} height={H} fill="#1B2520"/>
        {/* River */}
        <path d={`M -10 ${H*0.15} C ${W*0.3} ${H*0.10}, ${W*0.5} ${H*0.20}, ${W*0.7} ${H*0.14} S ${W+10} ${H*0.05}, ${W+10} ${H*0.04} L ${W+10} -10 L -10 -10 Z`}
          fill="#13313F"/>
        {/* Building blocks subtle */}
        <g fill="#243029" opacity="0.7">
          {[
            [0.05,0.55,0.15,0.10],[0.22,0.50,0.10,0.08],[0.05,0.70,0.18,0.13],
            [0.78,0.55,0.18,0.13],[0.30,0.85,0.14,0.10],[0.62,0.78,0.16,0.13],
            [0.10,0.32,0.10,0.06],[0.78,0.20,0.18,0.07],
          ].map(([x,y,w,h],i) => <rect key={i} x={W*x} y={H*y} width={W*w} height={H*h} rx="3"/>)}
        </g>
        {/* Roads in dark gray */}
        <g stroke="#3A4540" strokeWidth="22" fill="none" strokeLinecap="round">
          <path d={`M ${W*0.5} ${H+5} L ${W*0.5} ${H*0.62}`}/>
          <path d={`M ${W*0.5} ${H*0.62} L ${W+5} ${H*0.30}`}/>
          <path d={`M -5 ${H*0.45} L ${W+5} ${H*0.45}`}/>
          <path d={`M -5 ${H*0.78} L ${W+5} ${H*0.78}`}/>
          <path d={`M ${W*0.18} ${H+5} L ${W*0.18} -5`}/>
          <path d={`M ${W*0.85} ${H+5} L ${W*0.85} -5`}/>
        </g>
        <g stroke="#5A6862" strokeWidth="2" fill="none" strokeDasharray="4 8" strokeLinecap="round">
          <path d={`M ${W*0.5} ${H+5} L ${W*0.5} ${H*0.62}`}/>
          <path d={`M -5 ${H*0.45} L ${W+5} ${H*0.45}`}/>
        </g>

        {/* Route highlight */}
        <window.RouteLine w={W} h={H} pts={route} accent={accent}/>

        {/* Vehicle */}
        <window.VehicleMark w={W} h={H} x={0.5} y={0.78} heading={0}/>

        {/* Destination pin */}
        <g transform={`translate(${W*0.85} ${H*0.30})`}>
          <circle r="22" fill={accent} opacity="0.25"/>
          <path d="M0 -22 C -10 -22 -16 -14 -16 -6 C -16 4 -8 12 0 22 C 8 12 16 4 16 -6 C 16 -14 10 -22 0 -22 Z"
            fill={accent} stroke={TK.ink} strokeWidth="2"/>
          <text x="0" y="-2" textAnchor="middle" fontFamily={FONT_MONO} fontWeight="700" fontSize="12" fill={TK.ink}>7</text>
        </g>

        {/* Top fade */}
        <rect width={W} height={H} fill="url(#navfade)"/>
      </svg>

      {/* Top maneuver card */}
      <div style={{
        position: 'absolute', top: 12, left: 12, right: 12,
        background: TK.ink, color: '#fff', borderRadius: 22,
        padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 14,
        boxShadow: '0 8px 28px rgba(0,0,0,0.40)',
        border: `1px solid #2A332E`,
      }}>
        <Maneuver kind="right" accent={accent}/>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{
            display: 'flex', alignItems: 'baseline', gap: 6,
            fontFamily: FONT_MONO, fontWeight: 700, color: accent,
          }}>
            <span style={{ fontSize: 36, letterSpacing: -1.5, lineHeight: 1 }}>120</span>
            <span style={{ fontSize: 14, color: '#cbd1cd' }}>m</span>
          </div>
          <div style={{ fontSize: 14.5, fontWeight: 600, color: '#fff', marginTop: 2, lineHeight: 1.25 }}>
            Tournez à droite sur
          </div>
          <div style={{ fontSize: 14.5, fontWeight: 700, color: '#fff', lineHeight: 1.25 }}>
            rue du Faubourg St-Antoine
          </div>
        </div>
      </div>

      {/* Then-do hint */}
      <div style={{
        position: 'absolute', top: 144, left: 12,
        background: 'rgba(14,20,16,0.85)', color: '#cbd1cd', borderRadius: 14,
        padding: '8px 12px', fontSize: 12.5, display: 'flex', alignItems: 'center', gap: 8,
        backdropFilter: 'blur(8px)',
      }}>
        <span style={{ color: accent, fontWeight: 700 }}>puis</span>
        <span style={{ display: 'inline-flex', transform: 'rotate(-90deg)' }}>{Ico.arrow(14, '#fff')}</span>
        <span>continuer 400 m</span>
      </div>

      {/* Speed limit */}
      <div style={{
        position: 'absolute', top: 144, right: 12,
        width: 56, height: 56, borderRadius: 28, background: '#fff',
        border: '4px solid #D9483B',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: FONT_MONO, fontWeight: 800, fontSize: 18, color: TK.ink,
        boxShadow: '0 4px 12px rgba(0,0,0,0.3)',
      }}>50</div>

      {/* Hazard report (Waze-style alerts but original) */}
      <div style={{
        position: 'absolute', top: 220, left: 12,
        background: TK.amber, color: TK.ink, borderRadius: 14,
        padding: '10px 12px 10px 10px', display: 'flex', alignItems: 'center', gap: 10,
        boxShadow: '0 4px 14px rgba(242,163,65,0.35)',
        maxWidth: 240,
      }}>
        <div style={{
          width: 30, height: 30, borderRadius: 9, background: TK.ink,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>{Ico.alert(16, TK.amber)}</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 12.5, fontWeight: 700 }}>Travaux signalés · 800 m</div>
          <div style={{ fontSize: 11, opacity: 0.7 }}>Voie de droite fermée</div>
        </div>
      </div>

      {/* Bottom HUD */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0,
        padding: '0 12px 12px',
      }}>
        {/* ETA bar */}
        <div style={{
          background: TK.paper, borderRadius: 22,
          padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 14,
          boxShadow: '0 -4px 30px rgba(0,0,0,0.30)',
        }}>
          <div>
            <div style={{ fontFamily: FONT_MONO, fontSize: 26, fontWeight: 700, color: TK.ink, letterSpacing: -0.5, lineHeight: 1 }}>
              09:38
            </div>
            <div style={{ fontSize: 10.5, color: TK.textMute, letterSpacing: 0.6, fontWeight: 600, textTransform: 'uppercase', marginTop: 4 }}>
              Arrivée
            </div>
          </div>
          <div style={{ width: 1, height: 36, background: TK.divider }}/>
          <div>
            <div style={{ fontFamily: FONT_MONO, fontSize: 18, fontWeight: 700, color: TK.ink, lineHeight: 1 }}>4 min</div>
            <div style={{ fontSize: 10.5, color: TK.textMute, letterSpacing: 0.6, fontWeight: 600, textTransform: 'uppercase', marginTop: 4 }}>
              Restant
            </div>
          </div>
          <div style={{ width: 1, height: 36, background: TK.divider }}/>
          <div>
            <div style={{ fontFamily: FONT_MONO, fontSize: 18, fontWeight: 700, color: TK.ink, lineHeight: 1 }}>0.4 km</div>
            <div style={{ fontSize: 10.5, color: TK.textMute, letterSpacing: 0.6, fontWeight: 600, textTransform: 'uppercase', marginTop: 4 }}>
              Distance
            </div>
          </div>
          <div style={{ flex: 1 }}/>
          <button style={{
            width: 44, height: 44, borderRadius: 22, border: 'none', background: TK.red, color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="#fff"><rect x="6" y="6" width="12" height="12" rx="2"/></svg>
          </button>
        </div>

        {/* Quick actions row */}
        <div style={{ display: 'flex', gap: 8, marginTop: 8, justifyContent: 'space-between' }}>
          {[
            { ic: Ico.alert(16, '#fff'), l: 'Signaler' },
            { ic: Ico.voice(16, '#fff'), l: 'Mute' },
            { ic: Ico.layers(16, '#fff'), l: '2D' },
            { ic: Ico.pkg(16, '#fff'), l: 'Détails' },
          ].map((a,i) => (
            <button key={i} style={{
              flex: 1, height: 38, borderRadius: 19, border: 'none',
              background: 'rgba(14,20,16,0.85)', color: '#fff',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
              fontSize: 12, fontWeight: 600, backdropFilter: 'blur(8px)',
            }}>
              {a.ic} {a.l}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

window.Screen_Navigation = Screen_Navigation;
