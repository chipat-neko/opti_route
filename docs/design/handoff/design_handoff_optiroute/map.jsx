// Stylized SVG map (placeholder, not a real tile map).
// w/h are CSS px; the SVG fills its container.
// stops = [{x,y,n,state}]; route = SVG d-string drawn through stops.

function MapTiles({ w = 396, h = 720, zoom = 1, pan = { x: 0, y: 0 } }) {
  // Render a generic urban-ish road network with parks, river, blocks.
  // Coordinates designed for ~400x720 then scaled.
  const T = window.TK;
  return (
    <svg width="100%" height="100%" viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="xMidYMid slice"
      style={{ display: 'block' }}>
      <defs>
        <pattern id="hatch" width="6" height="6" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
          <line x1="0" y1="0" x2="0" y2="6" stroke={T.mapStroke} strokeWidth="1" opacity="0.3"/>
        </pattern>
      </defs>
      {/* Land */}
      <rect width={w} height={h} fill={T.mapLand}/>

      {/* Water (river running diagonally bottom) */}
      <path d={`M -10 ${h*0.78} C ${w*0.25} ${h*0.7}, ${w*0.45} ${h*0.95}, ${w*0.7} ${h*0.84} S ${w+10} ${h*0.62}, ${w+10} ${h*0.6} L ${w+10} ${h+10} L -10 ${h+10} Z`}
        fill={T.mapWater}/>

      {/* Park blocks */}
      <rect x={w*0.05} y={h*0.12} width={w*0.18} height={h*0.09} rx="4" fill={T.mapPark}/>
      <rect x={w*0.62} y={h*0.32} width={w*0.22} height={h*0.13} rx="4" fill={T.mapPark}/>
      <rect x={w*0.18} y={h*0.55} width={w*0.14} height={h*0.08} rx="4" fill={T.mapPark}/>

      {/* Subtle block fills */}
      <g opacity="0.5">
        <rect x={w*0.08} y={h*0.25} width={w*0.16} height={h*0.07} fill={T.mapLandAlt}/>
        <rect x={w*0.32} y={h*0.18} width={w*0.18} height={h*0.10} fill={T.mapLandAlt}/>
        <rect x={w*0.55} y={h*0.5} width={w*0.18} height={h*0.10} fill={T.mapLandAlt}/>
        <rect x={w*0.05} y={h*0.42} width={w*0.20} height={h*0.06} fill={T.mapLandAlt}/>
        <rect x={w*0.4} y={h*0.62} width={w*0.18} height={h*0.07} fill={T.mapLandAlt}/>
      </g>

      {/* Highway (yellow) */}
      <path d={`M -5 ${h*0.4} C ${w*0.2} ${h*0.42}, ${w*0.4} ${h*0.34}, ${w*0.6} ${h*0.36} S ${w+5} ${h*0.30}, ${w+5} ${h*0.28}`}
        stroke={T.mapHwy} strokeWidth="14" fill="none" strokeLinecap="round"/>
      <path d={`M -5 ${h*0.4} C ${w*0.2} ${h*0.42}, ${w*0.4} ${h*0.34}, ${w*0.6} ${h*0.36} S ${w+5} ${h*0.30}, ${w+5} ${h*0.28}`}
        stroke="#fff" strokeWidth="11" fill="none" strokeLinecap="round"/>

      {/* Major roads */}
      <g stroke="#fff" strokeWidth="9" fill="none" strokeLinecap="round">
        <path d={`M ${w*0.15} -5 L ${w*0.15} ${h*0.78}`}/>
        <path d={`M ${w*0.5} -5 L ${w*0.5} ${h*0.85}`}/>
        <path d={`M ${w*0.82} -5 L ${w*0.82} ${h*0.55}`}/>
        <path d={`M -5 ${h*0.18} L ${w+5} ${h*0.18}`}/>
        <path d={`M -5 ${h*0.62} L ${w*0.65} ${h*0.62}`}/>
      </g>
      <g stroke={T.mapStroke} strokeWidth="10" fill="none" strokeLinecap="round" opacity="0.6">
        <path d={`M ${w*0.15} -5 L ${w*0.15} ${h*0.78}`}/>
        <path d={`M ${w*0.5} -5 L ${w*0.5} ${h*0.85}`}/>
        <path d={`M ${w*0.82} -5 L ${w*0.82} ${h*0.55}`}/>
      </g>
      <g stroke="#fff" strokeWidth="9" fill="none" strokeLinecap="round">
        <path d={`M ${w*0.15} -5 L ${w*0.15} ${h*0.78}`}/>
        <path d={`M ${w*0.5} -5 L ${w*0.5} ${h*0.85}`}/>
        <path d={`M ${w*0.82} -5 L ${w*0.82} ${h*0.55}`}/>
        <path d={`M -5 ${h*0.18} L ${w+5} ${h*0.18}`}/>
        <path d={`M -5 ${h*0.62} L ${w*0.65} ${h*0.62}`}/>
      </g>

      {/* Minor roads */}
      <g stroke="#fff" strokeWidth="5" fill="none" strokeLinecap="round">
        <path d={`M ${w*0.32} -5 L ${w*0.32} ${h*0.62}`}/>
        <path d={`M ${w*0.66} -5 L ${w*0.66} ${h*0.55}`}/>
        <path d={`M -5 ${h*0.30} L ${w*0.82} ${h*0.30}`}/>
        <path d={`M -5 ${h*0.46} L ${w*0.82} ${h*0.46}`}/>
        <path d={`M -5 ${h*0.55} L ${w*0.82} ${h*0.55}`}/>
        <path d={`M -5 ${h*0.72} L ${w*0.65} ${h*0.72}`}/>
        <path d={`M ${w*0.4} ${h*0.7} L ${w*0.55} ${h*0.85}`}/>
      </g>

      {/* Building dots */}
      <g fill={T.mapStroke} opacity="0.45">
        {[
          [0.08,0.2,4],[0.10,0.23,3],[0.20,0.26,3],[0.22,0.21,4],
          [0.36,0.24,3],[0.42,0.2,4],[0.46,0.26,3],
          [0.55,0.42,3],[0.6,0.45,4],[0.71,0.42,3],[0.74,0.48,3],
          [0.20,0.5,3],[0.28,0.52,4],[0.10,0.48,3],
          [0.4,0.66,3],[0.46,0.7,4],[0.54,0.68,3],
        ].map(([x,y,r],i) => <circle key={i} cx={w*x} cy={h*y} r={r}/>)}
      </g>

      {/* Subtle vignette to focus center */}
      <radialGradient id="vig" cx="50%" cy="50%" r="60%">
        <stop offset="60%" stopColor="rgba(0,0,0,0)"/>
        <stop offset="100%" stopColor="rgba(0,0,0,0.10)"/>
      </radialGradient>
      <rect width={w} height={h} fill="url(#vig)"/>
    </svg>
  );
}

// Route polyline drawn over MapTiles. `pts` are %-of-canvas coords.
function RouteLine({ w, h, pts, accent, dashed = false, withGlow = true }) {
  if (!pts || pts.length < 2) return null;
  const T = window.TK;
  const c = accent || T.lime;
  const d = pts.reduce((acc, p, i) => {
    const x = w * p.x, y = h * p.y;
    if (i === 0) return `M ${x} ${y}`;
    const prev = pts[i-1];
    const px = w*prev.x, py = h*prev.y;
    const cx = (px + x) / 2, cy = (py + y) / 2;
    return `${acc} Q ${px} ${py} ${cx} ${cy} T ${x} ${y}`;
  }, '');
  return (
    <g>
      {withGlow && (
        <path d={d} stroke={c} strokeWidth="14" fill="none" opacity="0.18" strokeLinecap="round" strokeLinejoin="round"/>
      )}
      <path d={d} stroke={T.ink} strokeWidth="8" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
      <path d={d} stroke={c} strokeWidth="5" fill="none"
        strokeLinecap="round" strokeLinejoin="round"
        strokeDasharray={dashed ? '4 8' : 'none'}/>
    </g>
  );
}

// A pin marker at a relative %-coord
function Pin({ w, h, x, y, n, state = 'pending', tag }) {
  const T = window.TK;
  const cx = w * x, cy = h * y;
  const stateColor = {
    done: T.emerald,
    active: T.ink,
    pending: T.paper,
    fail: T.red,
  }[state] || T.paper;
  const textColor = (state === 'pending') ? T.ink : '#fff';
  return (
    <g transform={`translate(${cx} ${cy})`}>
      {state === 'active' && (
        <circle r="22" fill={T.lime} opacity="0.35">
          <animate attributeName="r" values="18;28;18" dur="2s" repeatCount="indefinite"/>
          <animate attributeName="opacity" values="0.5;0.1;0.5" dur="2s" repeatCount="indefinite"/>
        </circle>
      )}
      <path d="M0 -22 C -10 -22 -16 -14 -16 -6 C -16 4 -8 12 0 22 C 8 12 16 4 16 -6 C 16 -14 10 -22 0 -22 Z"
        fill={stateColor} stroke={T.ink} strokeWidth="2"/>
      <text x="0" y="-2" textAnchor="middle" fontFamily={window.FONT_MONO} fontWeight="700" fontSize="12" fill={textColor}>
        {n}
      </text>
      {tag && (
        <g transform="translate(18 -18)">
          <rect x="0" y="0" width={tag.length*7+10} height="16" rx="8" fill={T.ink}/>
          <text x={5} y={11.5} fontFamily={window.FONT_MONO} fontSize="10" fill="#fff">{tag}</text>
        </g>
      )}
    </g>
  );
}

// User vehicle marker (chevron in a disc)
function VehicleMark({ w, h, x, y, heading = 0 }) {
  const T = window.TK;
  return (
    <g transform={`translate(${w*x} ${h*y})`}>
      <circle r="20" fill={T.ink} opacity="0.10"/>
      <circle r="14" fill={T.lime}/>
      <circle r="14" fill="none" stroke={T.ink} strokeWidth="2"/>
      <g transform={`rotate(${heading})`}>
        <path d="M 0 -7 L 6 5 L 0 2 L -6 5 Z" fill={T.ink}/>
      </g>
    </g>
  );
}

window.MapTiles = MapTiles; window.RouteLine = RouteLine; window.Pin = Pin; window.VehicleMark = VehicleMark;
