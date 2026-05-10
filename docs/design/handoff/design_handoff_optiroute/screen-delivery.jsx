// OptiRoute — Screen 6: Détail arrêt (1 client, N feuilles d'expéditeurs)
// Pas de signature/preuve dans l'app (gérée hors-app via feuilles + appli boîte).
// Juste deux boutons : Livré / Échec.

const { TK, FONT_UI, FONT_MONO, Ico } = window;

function SheetCard({ idx, sender, refCode, contact, packages, weight, accent, active = false }) {
  return (
    <div style={{
      background: TK.paper, borderRadius: 16,
      border: active ? `1.5px solid ${TK.ink}` : `1px solid ${TK.divider}`,
      boxShadow: active ? '0 6px 20px rgba(14,20,16,0.08)' : 'none',
      overflow: 'hidden',
    }}>
      {/* Sheet header strip — looks like a paper sheet tab */}
      <div style={{
        background: active ? TK.ink : TK.creamSoft,
        color: active ? accent : TK.textMute,
        padding: '8px 14px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        fontSize: 11, fontWeight: 700, letterSpacing: 0.6, textTransform: 'uppercase',
      }}>
        <span style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
            width: 18, height: 22, borderRadius: 3,
            background: active ? accent : TK.paper,
            color: TK.ink, fontFamily: FONT_MONO, fontSize: 11, fontWeight: 700,
          }}>{idx}</span>
          Feuille · expéditeur {idx}/3
        </span>
        <span style={{ fontFamily: FONT_MONO, color: active ? '#cbd1cd' : TK.textMute }}>{refCode}</span>
      </div>

      {/* Body */}
      <div style={{ padding: '14px 16px 16px' }}>
        <div style={{ fontSize: 11, color: TK.textMute, fontWeight: 600, letterSpacing: 0.6, textTransform: 'uppercase' }}>
          Expéditeur
        </div>
        <div style={{ fontSize: 16, fontWeight: 700, color: TK.ink, lineHeight: 1.25, marginTop: 2 }}>
          {sender}
        </div>

        {/* Stats row */}
        <div style={{
          marginTop: 12, display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8,
        }}>
          <div style={{
            background: TK.creamSoft, borderRadius: 10, padding: '10px 12px',
          }}>
            <div style={{ fontFamily: FONT_MONO, fontSize: 18, fontWeight: 700, color: TK.ink, lineHeight: 1, letterSpacing: -0.3 }}>
              {packages}
            </div>
            <div style={{ fontSize: 10.5, color: TK.textMute, marginTop: 4, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase' }}>
              {packages > 1 ? 'Colis' : 'Colis'}
            </div>
          </div>
          <div style={{
            background: TK.creamSoft, borderRadius: 10, padding: '10px 12px',
          }}>
            <div style={{ fontFamily: FONT_MONO, fontSize: 18, fontWeight: 700, color: TK.ink, lineHeight: 1, letterSpacing: -0.3 }}>
              {weight}<span style={{ fontSize: 11, color: TK.textMute, marginLeft: 2, fontWeight: 500 }}>kg</span>
            </div>
            <div style={{ fontSize: 10.5, color: TK.textMute, marginTop: 4, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase' }}>
              Poids
            </div>
          </div>
          <div style={{
            background: contact ? TK.creamSoft : 'transparent',
            border: contact ? 'none' : `1px dashed ${TK.inkLine}`,
            borderRadius: 10, padding: '10px 12px',
          }}>
            <div style={{
              fontFamily: FONT_MONO, fontSize: contact ? 13 : 13, fontWeight: 700,
              color: contact ? TK.ink : TK.textFaint, lineHeight: 1.1,
              whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
            }}>
              {contact || '—'}
            </div>
            <div style={{ fontSize: 10.5, color: TK.textMute, marginTop: 4, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase' }}>
              Contact
            </div>
          </div>
        </div>

        {/* Status pill */}
        <div style={{ marginTop: 12, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          {active ? (
            <span style={{
              fontSize: 10.5, fontWeight: 700, padding: '4px 9px', borderRadius: 6,
              background: TK.ink, color: accent, letterSpacing: 0.4, textTransform: 'uppercase',
            }}>En cours</span>
          ) : (
            <span style={{
              fontSize: 10.5, fontWeight: 700, padding: '4px 9px', borderRadius: 6,
              background: TK.creamSoft, color: TK.textMute, letterSpacing: 0.4, textTransform: 'uppercase',
            }}>À faire</span>
          )}
        </div>
      </div>
    </div>
  );
}

function Screen_Delivery({ accent = TK.lime }) {
  return (
    <div style={{ width: '100%', height: '100%', background: TK.cream, fontFamily: FONT_UI, display: 'flex', flexDirection: 'column' }}>
      {/* Hero map snippet */}
      <div style={{ position: 'relative', height: 160, background: TK.mapLand, overflow: 'hidden', flexShrink: 0 }}>
        <svg width="100%" height="100%" viewBox="0 0 396 160" preserveAspectRatio="xMidYMid slice">
          <rect width="396" height="160" fill={TK.mapLand}/>
          <g stroke="#fff" strokeWidth="9" fill="none" strokeLinecap="round">
            <path d="M -5 80 L 405 80"/>
            <path d="M 130 -5 L 130 165"/>
            <path d="M 280 -5 L 280 165"/>
          </g>
          <g stroke="#fff" strokeWidth="5" fill="none" strokeLinecap="round">
            <path d="M -5 35 L 405 35"/>
            <path d="M -5 125 L 405 125"/>
          </g>
          <g fill={TK.mapStroke} opacity="0.5">
            {[[40,18],[60,28],[200,46],[210,52],[330,60],[80,108],[220,118]].map(([x,y],i) => <circle key={i} cx={x} cy={y} r="3"/>)}
          </g>
          <path d="M 30 150 Q 100 120 130 80 T 198 80" stroke={TK.ink} strokeWidth="8" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          <path d="M 30 150 Q 100 120 130 80 T 198 80" stroke={accent} strokeWidth="5" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          <g transform="translate(198 80)">
            <circle r="22" fill={accent} opacity="0.3"/>
            <path d="M0 -22 C -10 -22 -16 -14 -16 -6 C -16 4 -8 12 0 22 C 8 12 16 4 16 -6 C 16 -14 10 -22 0 -22 Z"
              fill={TK.ink} stroke={TK.ink} strokeWidth="2"/>
            <text x="0" y="-2" textAnchor="middle" fontFamily={FONT_MONO} fontWeight="700" fontSize="12" fill={accent}>7</text>
          </g>
        </svg>
        <button style={{
          position: 'absolute', top: 14, left: 14,
          width: 40, height: 40, borderRadius: 20, border: 'none',
          background: TK.paper, display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 4px 12px rgba(0,0,0,0.10)',
        }}>{Ico.back(20, TK.ink)}</button>
        <div style={{
          position: 'absolute', top: 14, right: 14, padding: '6px 10px',
          background: TK.ink, color: '#fff', borderRadius: 8, fontSize: 11, fontWeight: 700,
          letterSpacing: 0.6, textTransform: 'uppercase',
        }}>Arrêt 07/24</div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '0 18px 16px' }}>
        {/* Address card */}
        <div style={{
          marginTop: -28, padding: '16px 18px', background: TK.paper, borderRadius: 18,
          boxShadow: '0 6px 20px rgba(14,20,16,0.08)', border: `1px solid ${TK.divider}`,
        }}>
          <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 10 }}>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 11, color: TK.textMute, fontWeight: 600, letterSpacing: 0.6, textTransform: 'uppercase' }}>
                Client
              </div>
              <div style={{ fontSize: 20, fontWeight: 800, color: TK.ink, letterSpacing: -0.3, lineHeight: 1.2, marginTop: 4 }}>
                14 rue du Faubourg<br/>Saint-Antoine
              </div>
              <div style={{ fontSize: 13, color: TK.textMute, marginTop: 6 }}>
                75011 Paris · Bât. B · 3<sup>e</sup> ét. · gauche
              </div>
            </div>
            <div style={{
              width: 50, height: 50, borderRadius: 14, background: TK.ink, color: '#fff',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: FONT_MONO, fontWeight: 700, fontSize: 18, flexShrink: 0,
            }}>07</div>
          </div>

          {/* Code chip */}
          <div style={{
            marginTop: 12, padding: '8px 12px', background: accent, borderRadius: 10,
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{ fontSize: 11, fontWeight: 700, color: TK.ink, letterSpacing: 0.6, textTransform: 'uppercase', flex: 1 }}>
              Code accès
            </div>
            <div style={{ fontFamily: FONT_MONO, fontSize: 16, fontWeight: 800, color: TK.ink, letterSpacing: 1 }}>
              4521A
            </div>
          </div>
        </div>

        {/* Sheets header — sum across all sheets */}
        <div style={{
          marginTop: 18, display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 10,
        }}>
          <div>
            <div style={{ fontSize: 11, color: TK.textMute, fontWeight: 600, letterSpacing: 0.6, textTransform: 'uppercase' }}>
              Feuilles à livrer
            </div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 4 }}>
              <span style={{ fontFamily: FONT_MONO, fontSize: 22, fontWeight: 800, color: TK.ink, letterSpacing: -0.5, lineHeight: 1 }}>
                3
              </span>
              <span style={{ fontSize: 12, color: TK.textMute }}>expéditeurs</span>
              <span style={{ color: TK.textFaint, margin: '0 2px' }}>·</span>
              <span style={{ fontFamily: FONT_MONO, fontSize: 14, fontWeight: 700, color: TK.ink }}>6</span>
              <span style={{ fontSize: 12, color: TK.textMute }}>colis</span>
              <span style={{ color: TK.textFaint, margin: '0 2px' }}>·</span>
              <span style={{ fontFamily: FONT_MONO, fontSize: 14, fontWeight: 700, color: TK.ink }}>7.2</span>
              <span style={{ fontSize: 12, color: TK.textMute }}>kg</span>
            </div>
          </div>
        </div>

        {/* List of sheets */}
        <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <SheetCard
            idx="1" sender="Chronopost · La Poste"
            refCode="REF · 83920441"
            contact="M. Lefèvre"
            packages={2} weight="2.0" accent={accent} active
          />
          <SheetCard
            idx="2" sender="DPD France"
            refCode="REF · DPD-771-093"
            contact={null}
            packages={3} weight="4.6" accent={accent}
          />
          <SheetCard
            idx="3" sender="Colis Privé"
            refCode="REF · CP-44128"
            contact="Mme Aubry"
            packages={1} weight="0.6" accent={accent}
          />
        </div>

        {/* Note */}
        <div style={{ marginTop: 14, padding: '12px 14px', background: TK.paper, borderRadius: 12, border: `1px dashed ${TK.inkLine}` }}>
          <div style={{ fontSize: 11, color: TK.textMute, fontWeight: 600, letterSpacing: 0.6, textTransform: 'uppercase', marginBottom: 4 }}>
            Consigne du livreur
          </div>
          <div style={{ fontSize: 13, color: TK.ink, lineHeight: 1.4 }}>
            Sonner deux fois. En cas d'absence, déposer chez la gardienne (Bât. A).
          </div>
        </div>
      </div>

      {/* Two clear actions: Livré / Échec */}
      <div style={{
        background: TK.paper, padding: '12px 14px 14px', borderTop: `1px solid ${TK.divider}`,
        display: 'flex', gap: 10, alignItems: 'stretch',
      }}>
        <button style={{
          flex: 1, height: 60, borderRadius: 16, border: `1.5px solid ${TK.red}`,
          background: TK.paper, color: TK.red, fontWeight: 700, fontSize: 15,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
          fontFamily: FONT_UI,
        }}>
          {Ico.close(20, TK.red)} Échec
        </button>
        <button style={{
          flex: 1.6, height: 60, borderRadius: 16, border: 'none',
          background: TK.emerald, color: '#fff', fontWeight: 800, fontSize: 16,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
          fontFamily: FONT_UI, letterSpacing: 0.2,
          boxShadow: '0 6px 18px rgba(14,124,90,0.30)',
        }}>
          {Ico.check(22, '#fff')} Livré
        </button>
      </div>
    </div>
  );
}

window.Screen_Delivery = Screen_Delivery;
