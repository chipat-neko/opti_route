// Design tokens for OptiRoute
const TK = {
  // Surfaces
  cream: '#F5F3EE',
  creamSoft: '#EFEAE0',
  paper: '#FFFFFF',
  ink: '#0E1410',
  inkSoft: '#1A211C',
  inkLine: '#E3DED1',
  // Brand
  emerald: '#0E7C5A',
  emeraldDark: '#0A5C43',
  emeraldSoft: '#D5EBE0',
  lime: '#B8F24A',
  limeDark: '#86C72A',
  amber: '#F2A341',
  red: '#D9483B',
  // Map
  mapLand: '#EAE6DD',
  mapLandAlt: '#E0DAC9',
  mapWater: '#C4D8E5',
  mapPark: '#D6E2C7',
  mapRoad: '#FFFFFF',
  mapHwy: '#F8DCA0',
  mapStroke: '#D4CCB8',
  // Text
  text: '#0E1410',
  textMute: '#5C6660',
  textFaint: '#8A9089',
  // Misc
  divider: 'rgba(14,20,16,0.08)',
};

const FONT_UI = '"Manrope", system-ui, sans-serif';
const FONT_MONO = '"JetBrains Mono", ui-monospace, monospace';

// ─── Generic icons (24px) ─────────────────────────────────────
const Ico = {
  pin: (s = 16, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M12 22s8-7.6 8-13a8 8 0 1 0-16 0c0 5.4 8 13 8 13Z" stroke={c} strokeWidth="1.7" strokeLinejoin="round"/>
      <circle cx="12" cy="9" r="2.5" stroke={c} strokeWidth="1.7"/>
    </svg>
  ),
  search: (s = 18, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <circle cx="11" cy="11" r="6.5" stroke={c} strokeWidth="1.8"/>
      <path d="m20 20-4-4" stroke={c} strokeWidth="1.8" strokeLinecap="round"/>
    </svg>
  ),
  plus: (s = 18, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M12 5v14M5 12h14" stroke={c} strokeWidth="2" strokeLinecap="round"/>
    </svg>
  ),
  arrow: (s = 18, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M5 12h14m-5-5 5 5-5 5" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  back: (s = 22, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M19 12H5m5-5-5 5 5 5" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  menu: (s = 22, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M4 7h16M4 12h16M4 17h10" stroke={c} strokeWidth="1.8" strokeLinecap="round"/>
    </svg>
  ),
  close: (s = 18, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="m6 6 12 12M18 6 6 18" stroke={c} strokeWidth="1.8" strokeLinecap="round"/>
    </svg>
  ),
  voice: (s = 18, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <rect x="9" y="3" width="6" height="12" rx="3" stroke={c} strokeWidth="1.7"/>
      <path d="M5 11a7 7 0 0 0 14 0M12 18v3" stroke={c} strokeWidth="1.7" strokeLinecap="round"/>
    </svg>
  ),
  scan: (s = 18, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M4 8V5a1 1 0 0 1 1-1h3M16 4h3a1 1 0 0 1 1 1v3M20 16v3a1 1 0 0 1-1 1h-3M8 20H5a1 1 0 0 1-1-1v-3" stroke={c} strokeWidth="1.7" strokeLinecap="round"/>
      <path d="M4 12h16" stroke={c} strokeWidth="1.7" strokeLinecap="round"/>
    </svg>
  ),
  photo: (s = 18, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <rect x="3" y="6" width="18" height="14" rx="2" stroke={c} strokeWidth="1.7"/>
      <circle cx="12" cy="13" r="3.5" stroke={c} strokeWidth="1.7"/>
      <path d="M8 6V5a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v1" stroke={c} strokeWidth="1.7"/>
    </svg>
  ),
  paste: (s = 18, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <rect x="6" y="4" width="12" height="17" rx="2" stroke={c} strokeWidth="1.7"/>
      <rect x="9" y="2" width="6" height="3" rx="1" stroke={c} strokeWidth="1.7" fill="#fff"/>
    </svg>
  ),
  bolt: (s = 18, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M13 2 4 14h7l-1 8 9-12h-7l1-8Z" stroke={c} strokeWidth="1.7" strokeLinejoin="round" fill="none"/>
    </svg>
  ),
  check: (s = 18, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="m5 12 5 5L20 7" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  clock: (s = 16, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="9" stroke={c} strokeWidth="1.7"/>
      <path d="M12 7v5l3 2" stroke={c} strokeWidth="1.7" strokeLinecap="round"/>
    </svg>
  ),
  truck: (s = 18, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <rect x="2" y="7" width="11" height="9" rx="1" stroke={c} strokeWidth="1.7"/>
      <path d="M13 10h4l3 3v3h-7z" stroke={c} strokeWidth="1.7" strokeLinejoin="round"/>
      <circle cx="7" cy="18" r="2" stroke={c} strokeWidth="1.7"/>
      <circle cx="17" cy="18" r="2" stroke={c} strokeWidth="1.7"/>
    </svg>
  ),
  layers: (s = 18, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M12 3 3 8l9 5 9-5-9-5Z" stroke={c} strokeWidth="1.7" strokeLinejoin="round"/>
      <path d="m3 13 9 5 9-5M3 18l9 5 9-5" stroke={c} strokeWidth="1.7" strokeLinejoin="round"/>
    </svg>
  ),
  locate: (s = 18, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="3" stroke={c} strokeWidth="1.7"/>
      <circle cx="12" cy="12" r="8" stroke={c} strokeWidth="1.7"/>
      <path d="M12 1v3M12 20v3M1 12h3M20 12h3" stroke={c} strokeWidth="1.7" strokeLinecap="round"/>
    </svg>
  ),
  alert: (s = 18, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M12 3 2 20h20L12 3Z" stroke={c} strokeWidth="1.7" strokeLinejoin="round"/>
      <path d="M12 10v4M12 17v.5" stroke={c} strokeWidth="1.8" strokeLinecap="round"/>
    </svg>
  ),
  pkg: (s = 18, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="m12 3 9 4.5v9L12 21l-9-4.5v-9L12 3Z" stroke={c} strokeWidth="1.7" strokeLinejoin="round"/>
      <path d="M3 7.5 12 12l9-4.5M12 12v9M7.5 5.25l9 4.5" stroke={c} strokeWidth="1.7" strokeLinejoin="round"/>
    </svg>
  ),
  phone: (s = 16, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A15 15 0 0 1 3 6a2 2 0 0 1 2-2Z" stroke={c} strokeWidth="1.7" strokeLinejoin="round"/>
    </svg>
  ),
  signature: (s = 18, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M3 17c4 0 5-10 8-10s2 8 5 8c1.5 0 2.5-1 3-2" stroke={c} strokeWidth="1.7" strokeLinecap="round"/>
      <path d="M3 21h18" stroke={c} strokeWidth="1.7" strokeLinecap="round"/>
    </svg>
  ),
  drag: (s = 16, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <circle cx="9" cy="6" r="1.4" fill={c}/><circle cx="15" cy="6" r="1.4" fill={c}/>
      <circle cx="9" cy="12" r="1.4" fill={c}/><circle cx="15" cy="12" r="1.4" fill={c}/>
      <circle cx="9" cy="18" r="1.4" fill={c}/><circle cx="15" cy="18" r="1.4" fill={c}/>
    </svg>
  ),
  filter: (s = 18, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M3 5h18l-7 9v6l-4-2v-4L3 5Z" stroke={c} strokeWidth="1.7" strokeLinejoin="round"/>
    </svg>
  ),
  star: (s = 14, c = 'currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c}>
      <path d="m12 2 3 7 7.5.6-5.7 4.9 1.7 7.5L12 18l-6.5 4 1.7-7.5L1.5 9.6 9 9l3-7Z"/>
    </svg>
  ),
};

window.TK = TK; window.FONT_UI = FONT_UI; window.FONT_MONO = FONT_MONO; window.Ico = Ico;
