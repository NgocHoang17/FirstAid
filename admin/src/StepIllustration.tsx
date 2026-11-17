import type { ReactNode } from 'react';
import type { Step } from './models';

interface Diagram {
  schema_version: number;
  kind: string;
  label: string;
  caption: string;
}

// Read the mobile catalogue directly: asset keys and captions stay identical.
const files = import.meta.glob<Diagram>('../../mobile/assets/illustrations/*.json', { eager: true, import: 'default' });
export const illustrationCatalogue = Object.entries(files).map(([path, diagram]) => ({
  ...diagram,
  assetKey: path.replace('../../mobile/', ''),
})).sort((a, b) => a.label.localeCompare(b.label, 'vi'));

const line = (x1: number, y1: number, x2: number, y2: number) => <line x1={x1} y1={y1} x2={x2} y2={y2}/>;
const box = (x: number, y: number, width: number, height: number, rx = 12) => <rect x={x} y={y} width={width} height={height} rx={rx} fill="#ffffff"/>;
const circle = (cx: number, cy: number, r: number, fill = 'none') => <circle cx={cx} cy={cy} r={r} fill={fill}/>;
const plus = (x: number, y: number) => <>{line(x - 10, y, x + 10, y)}{line(x, y - 10, x, y + 10)}</>;
function arrow(x1: number, y1: number, x2: number, y2: number) {
  const angle = Math.atan2(y2 - y1, x2 - x1);
  return <>{line(x1, y1, x2, y2)}{[-.6, .6].map(delta => <g key={delta}>{line(x2, y2, x2 - 12 * Math.cos(angle + delta), y2 - 12 * Math.sin(angle + delta))}</g>)}</>;
}
const cardinal = (x: number, y: number, inner: number, outer: number) => [0, Math.PI / 2, Math.PI, Math.PI * 1.5].map(angle =>
  <g key={angle}>{line(x + inner * Math.cos(angle), y + inner * Math.sin(angle), x + outer * Math.cos(angle), y + outer * Math.sin(angle))}</g>);

// SVG equivalents of mobile's ReminderPainter, using its 320 × 114 coordinates.
// These are action reminders; they do not demonstrate anatomical technique.
const drawings: Record<string, ReactNode> = {
  phone: <>{box(123, 8, 74, 98)}{line(148, 20, 172, 20)}{circle(160, 91, 3)}{plus(160, 55)}</>,
  shield: <><path d="M160 9 L203 25 L197 66 Q188 92 160 105 Q132 92 123 66 L117 25 Z" fill="#ffffff"/>{plus(160, 52)}</>,
  observe: <><path d="M88 57 Q160 -6 232 57 Q160 120 88 57 Z"/>{circle(160, 57, 18)}</>,
  water: <>{line(76, 23, 148, 23)}{line(125, 12, 125, 23)}{line(148, 23, 148, 42)}{line(132, 42, 164, 42)}{[132, 148, 164].map(x => <g key={x}>{line(x, 53, x, 63)}{line(x, 74, x, 80)}</g>)}<path d="M81 94 Q108 80 135 94 Q161 108 188 94 Q214 80 241 94"/>{box(207, 25, 27, 47, 6)}{line(214, 17, 227, 17)}</>,
  pulse: <path d="M65 60 H117 L133 39 L147 83 L164 24 L181 60 H252"/>,
  breathing: <>{line(160, 13, 160, 44)}{[-1, 1].map(d => <path key={d} d={`M160 43 C${160 + d * 25} 18 ${160 + d * 63} 26 ${160 + d * 65} 61 C${160 + d * 68} 97 ${160 + d * 18} 104 ${160 + d * 12} 77 L${160 + d * 12} 49`}/>)}</>,
  clock: <>{circle(160, 57, 44, '#ffffff')}{line(160, 28, 160, 57)}{line(160, 57, 184, 72)}{cardinal(160, 57, 35, 40)}</>,
  pressure: <>{box(106, 65, 108, 30, 7)}{line(119, 74, 201, 74)}{arrow(145, 14, 145, 52)}{arrow(176, 14, 176, 52)}</>,
  cloth: <>{box(110, 17, 100, 80, 7)}{line(123, 34, 197, 34)}{line(123, 80, 197, 80)}{plus(160, 57)}</>,
  aed: <>{box(113, 16, 94, 84)}<path d="M164 31 L145 59 H163 L154 84 L179 50 H161 Z"/>{line(207, 49, 233, 49)}{box(235, 30, 21, 38, 5)}</>,
  sequence: <>{[92, 160, 228].map(x => <g key={x}>{circle(x, 57, 20, '#ffffff')}</g>)}{arrow(116, 57, 134, 57)}{arrow(184, 57, 202, 57)}<path d="M85 57 L91 64 L102 49 M153 57 L159 64 L170 49"/></>,
  rescue: <>{circle(157, 52, 33)}{circle(157, 52, 17)}<path d="M134 29 L145 40 M180 29 L169 40 M134 75 L145 64 M180 75 L169 64 M72 100 Q116 82 160 100 Q204 118 248 100"/></>,
  pause: <>{box(130, 24, 18, 66, 6)}{box(172, 24, 18, 66, 6)}{line(98, 104, 222, 104)}</>,
  cold: <>{[0, Math.PI / 3, Math.PI * 2 / 3].map(a => <g key={a}>{line(160 - 40 * Math.cos(a), 57 - 40 * Math.sin(a), 160 + 40 * Math.cos(a), 57 + 40 * Math.sin(a))}</g>)}{box(101, 8, 118, 98, 18)}</>,
  electric: <><path d="M167 18 L141 61 H164 L153 95 L187 49 H165 Z"/>{circle(160, 57, 49)}{line(125, 22, 195, 92)}</>,
  cooling: <>{circle(102, 38, 17)}{cardinal(102, 38, 23, 32)}{[47, 66, 85].map(y => <path key={y} d={`M151 ${y} Q177 ${y - 13} 204 ${y} Q229 ${y + 13} 252 ${y}`}/>)}</>,
  pillow: <>{box(109, 49, 102, 52, 18)}{circle(160, 44, 25, '#ffffff')}</>,
  stop: <>{circle(160, 57, 43, '#ffffff')}{line(130, 27, 190, 87)}</>,
  medical: <>{box(119, 19, 82, 88)}{plus(160, 46)}{box(148, 78, 24, 29, 2)}{line(88, 107, 232, 107)}</>,
  information: <>{box(123, 13, 74, 91, 6)}{[36, 54, 72].map(y => <g key={y}>{line(138, y, 182, y)}</g>)}</>,
};

export function StepIllustration({ step }: { step: Step }) {
  if (!step.asset_key) return null;
  const diagram = illustrationCatalogue.find(d => d.assetKey === step.asset_key);
  if (!diagram || diagram.schema_version !== 1 || !drawings[diagram.kind]) {
    return <p className="illustration-unavailable" role="status">Không tìm thấy hình đã chọn. Hãy chọn lại từ thư viện minh họa.</p>;
  }
  return <figure className="step-illustration" role="img" aria-label={`${diagram.label}. ${step.alt_text || diagram.caption}`}>
    <svg viewBox="0 0 320 114" fill="none" stroke="#005a78" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{drawings[diagram.kind]}</svg>
    <figcaption><strong>{diagram.label}</strong><span>{diagram.caption}</span></figcaption>
  </figure>;
}
