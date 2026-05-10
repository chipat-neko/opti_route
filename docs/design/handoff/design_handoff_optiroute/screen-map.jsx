// OptiRoute — Screen 1: Tournée en cours (carte principale)
// Map fills behind, search bar on top, bottom sheet with current stop.

const { TK, FONT_UI, FONT_MONO, Ico } = window;

// Compact reusable header overlay that sits over the map
function MapTopBar({ accent }) {
  return (
    <div style={{
      position: 'absolute', top: 12, left: 12, right: 12,
      display: 'flex', flexDirection: 'column', gap: 10,
    }}>
      {/* Search */}
      <div style={{
        height: 52, background: TK.paper, borderRadius: 26,
        boxShadow: '0 6px 20px rgba(14,20,16,0.12), 0 0 0 1px rgba(14,20,16,0.04)',
        display: 'flex', alignItems: 'center', padding: '0 6px 0 16px', gap: 10,
      }}>
        <button style={iconBtn}>{Ico.menu(22, TK.ink)}</button>
        <div style={{ flex: 1, color: TK.textMute, fontFamily: FONT_UI, fontSize: 15 }}>
          Rechercher une adresse…
        </div>
        <button style={{ ...iconBtn, background: TK.ink, color: '#fff', width: 40, height: 40 }}>
          {Ico.voice(18, '#fff')}
        </button>
      </div>

      {/* Tour status chip */}
      <div style={{
        alignSelf: 'flex-start',
        background: TK.ink, color: '#fff',
        borderRadius: 20, padding: '8px 14px 8px 10px',
        display: 'flex', alignItems: 'center', gap: 10,
        boxShadow: '0 4px 12px rgba(0,0,0,0.18)',
      }}>
        <span style={{
          width: 10, height: 10, borderRadius: 5, background: accent,
          boxShadow: `0 0 0 4px ${accent}33`,
        }}/>
        <span style={{ fontFamily: FONT_UI, fontWeight: 600, fontSize: 13 }}>Tournée #142 · en cours</span>
        <span style={{ fontFamily: FONT_MONO, fontSize: 12, opacity: 0.7, marginLeft: 4 }}>09:34</span>
      </div>
    </div>
  );
}

const iconBtn = {
  width: 40, height: 40, borderRadius: 20, border: 'none',
  background: 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center',
  cursor: 'pointer', padding: 0,
};

// Floating right column (layers, location, alerts)
function MapFabStack({ accent }) {
  const fab = (children, bg = TK.paper, fg = TK.ink) => (
    <button style={{
      width: 44, height: 44, borderRadius: 22, border: 'none', background: bg, color: fg,
      boxShadow: '0 4px 14px rgba(14,20,16,0.14), 0 0 0 1px rgba(14,20,16,0.04)',
      display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', padding: 0,
    }}>{children}</button>
  );
  return (
    <div style={{
      position: 'absolute', right: 12, top: 150, display: 'flex', flexDirection: 'column', gap: 8,
    }}>
      {fab(Ico.layers(20, TK.ink))}
      {fab(Ico.locate(20, TK.ink))}
      {fab(Ico.alert(20, TK.amber))}
    </div>
  );
}

// Bottom sheet with the next stop card
function NextStopSheet({ accent }) {
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      background: TK.paper, borderTopLeftRadius: 28, borderTopRightRadius: 28,
      padding: '12px 18px 22px',
      boxShadow: '0 -10px 40px rgba(14,20,16,0.10)',
      fontFamily: FONT_UI,
    }}>
      {/* Drag handle */}
      <div style={{
        width: 38, height: 4, borderRadius: 2, background: TK.inkLine,
        margin: '0 auto 14px',
      }}/>

      {/* Progress strip */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <span style={{ fontFamily: FONT_MONO, fontSize: 12, color: TK.textMute, fontWeight: 600 }}>
          07/24
        </span>
        <div style={{ flex: 1, height: 6, borderRadius: 3, background: TK.inkLine, overflow: 'hidden' }}>
          <div style={{ width: '29%', height: '100%', background: accent, borderRadius: 3 }}/>
        </div>
        <span style={{ fontFamily: FONT_MONO, fontSize: 12, color: TK.textMute }}>17 restants</span>
      </div>

      {/* Stop heading */}
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, marginBottom: 14 }}>
        <div style={{
          width: 40, height: 40, borderRadius: 12, background: TK.ink, color: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: FONT_MONO, fontWeight: 700, fontSize: 16, flexShrink: 0,
        }}>07</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 11, color: TK.textMute, fontWeight: 600, letterSpacing: 0.6, textTransform: 'uppercase' }}>
            Prochain arrêt · dans 4 min
          </div>
          <div style={{ fontSize: 18, fontWeight: 700, color: TK.ink, lineHeight: 1.25, marginTop: 2 }}>
            14 rue du Faubourg Saint-Antoine
          </div>
          <div style={{ fontSize: 13, color: TK.textMute, marginTop: 2 }}>
            75011 Paris · Bât. B, code 4521A
          </div>
        </div>
      </div>

      {/* Recipient / package row */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        background: TK.creamSoft, borderRadius: 14, padding: '10px 12px', marginBottom: 14,
      }}>
        <div style={{
          width: 32, height: 32, borderRadius: 16, background: TK.paper, display: 'flex',
          alignItems: 'center', justifyContent: 'center',
        }}>{Ico.pkg(16, TK.ink)}</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: TK.ink }}>M. Lefèvre · 2 colis</div>
          <div style={{ fontSize: 12, color: TK.textMute, fontFamily: FONT_MONO }}>FR-83920441 · FR-83920442</div>
        </div>
        <button style={{
          width: 32, height: 32, borderRadius: 16, border: 'none', background: TK.paper,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>{Ico.phone(16, TK.ink)}</button>
      </div>

      {/* CTA row */}
      <div style={{ display: 'flex', gap: 8 }}>
        <button style={{
          flex: 1, height: 52, borderRadius: 26, border: `1.5px solid ${TK.ink}`,
          background: TK.paper, color: TK.ink, fontWeight: 700, fontSize: 15,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>Détails</button>
        <button style={{
          flex: 2, height: 52, borderRadius: 26, border: 'none',
          background: TK.ink, color: accent, fontWeight: 700, fontSize: 15,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
          fontFamily: FONT_UI,
        }}>
          Démarrer la navigation {Ico.arrow(16, accent)}
        </button>
      </div>
    </div>
  );
}

function Screen_Map({ accent = TK.lime }) {
  // 412x828 = device content area for default Android frame (892 - 40 status - 24 nav)
  const W = 396, H = 828;
  const stops = [
    { x: 0.18, y: 0.20, n: '✓', state: 'done' },
    { x: 0.36, y: 0.28, n: '✓', state: 'done' },
    { x: 0.42, y: 0.40, n: '✓', state: 'done' },
    { x: 0.55, y: 0.34, n: '✓', state: 'done' },
    { x: 0.66, y: 0.42, n: '✓', state: 'done' },
    { x: 0.50, y: 0.52, n: '✓', state: 'done' },
    { x: 0.55, y: 0.62, n: '7', state: 'active' },
    { x: 0.32, y: 0.62, n: '8', state: 'pending' },
    { x: 0.20, y: 0.55, n: '9', state: 'pending' },
    { x: 0.78, y: 0.50, n: '10', state: 'pending' },
  ];
  const route = stops.map(s => ({ x: s.x, y: s.y }));

  return (
    <div style={{ position: 'relative', width: '100%', height: '100%', background: TK.mapLand, overflow: 'hidden' }}>
      <svg width="100%" height="100%" viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="xMidYMid slice"
        style={{ position: 'absolute', inset: 0 }}>
        <foreignObject x="0" y="0" width={W} height={H}>
          <div style={{ width: '100%', height: '100%' }}>
            <window.MapTiles w={W} h={H}/>
          </div>
        </foreignObject>
        <window.RouteLine w={W} h={H} pts={route} accent={accent}/>
        {stops.map((s, i) => <window.Pin key={i} w={W} h={H} {...s} />)}
        <window.VehicleMark w={W} h={H} x={0.55} y={0.62} heading={-30}/>
      </svg>

      <MapTopBar accent={accent}/>
      <MapFabStack accent={accent}/>
      <NextStopSheet accent={accent}/>
    </div>
  );
}

window.Screen_Map = Screen_Map;
