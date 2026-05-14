"""
Genere un HTML interactif a partir de docs/checklist-tests-*.md.

Usage : python scripts/generate_checklist_html.py

Le HTML genere :
- Persiste l'etat des cases (V / X / ?) dans localStorage
- Bouton "Exporter X" qui copie un resume des items en erreur
- Bouton "PDF" qui ouvre window.print() pour sauvegarder en PDF
- Bouton "Reset" pour repartir de zero
"""
import re
import html
from pathlib import Path

SRC = Path("docs/checklist-tests-2026-05-14.md")
OUT = Path("docs/checklist-tests-interactif.html")


def parse_md_to_html(md_text: str) -> tuple[str, int]:
    """Parse le markdown en blocks HTML. Retourne (html_body, total_items)."""
    lines = md_text.split("\n")
    body = []
    item_id = 0
    in_paragraph = []
    in_codeblock = False

    def flush_paragraph():
        if in_paragraph:
            txt = " ".join(in_paragraph).strip()
            if txt:
                body.append(f'<p class="meta">{html.escape(txt)}</p>')
            in_paragraph.clear()

    for line in lines:
        stripped = line.strip()
        # Code fence
        if stripped.startswith("```"):
            flush_paragraph()
            in_codeblock = not in_codeblock
            body.append("</pre>" if not in_codeblock else "<pre>")
            continue
        if in_codeblock:
            body.append(html.escape(line))
            continue
        # Heading 1
        if line.startswith("# "):
            flush_paragraph()
            body.append(f'<h1>{html.escape(line[2:].strip())}</h1>')
            continue
        # Heading 2
        if line.startswith("## "):
            flush_paragraph()
            body.append(f'<h2 class="section">{html.escape(line[3:].strip())}</h2>')
            continue
        # Heading 3
        if line.startswith("### "):
            flush_paragraph()
            body.append(f'<h3 class="subsection">{html.escape(line[4:].strip())}</h3>')
            continue
        # Heading 4
        if line.startswith("#### "):
            flush_paragraph()
            body.append(f'<h4>{html.escape(line[5:].strip())}</h4>')
            continue
        # Item checkbox
        m = re.match(r"^- \[ \]\s+(.*)$", line)
        if m:
            flush_paragraph()
            item_id += 1
            # Garder les `code` inline
            text = m.group(1)
            # Remplacer **gras** par <strong>
            text = re.sub(r"\*\*(.+?)\*\*", lambda x: f"<strong>{html.escape(x.group(1))}</strong>", text)
            # Remplacer `code` par <code>
            text = re.sub(r"`([^`]+)`", lambda x: f"<code>{html.escape(x.group(1))}</code>", text)
            body.append(
                f'<div class="item" data-id="{item_id}">'
                f'<button class="status" data-state="none" '
                f'onclick="cycle(this)" type="button" '
                f'aria-label="Statut du test"></button>'
                f'<span class="text">{text}</span></div>'
            )
            continue
        # Bullet sub-item (indented)
        if re.match(r"^  [-*]\s+", line):
            flush_paragraph()
            sub = re.sub(r"^\s+[-*]\s+", "", line)
            body.append(f'<div class="sub-item">{html.escape(sub)}</div>')
            continue
        # HR
        if stripped == "---":
            flush_paragraph()
            body.append("<hr/>")
            continue
        # Empty line = end paragraph
        if not stripped:
            flush_paragraph()
            continue
        # Default : paragraphe
        in_paragraph.append(stripped)

    flush_paragraph()
    return "\n".join(body), item_id


def main():
    md_text = SRC.read_text(encoding="utf-8")
    body, total = parse_md_to_html(md_text)

    html_doc = HTML_TEMPLATE.replace("{{CONTENT}}", body).replace("{{TOTAL}}", str(total))
    OUT.write_text(html_doc, encoding="utf-8", newline="\n")
    print(f"Generated {OUT} with {total} items")


HTML_TEMPLATE = r"""<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Checklist tests opti_route — interactive</title>
<style>
  * { box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: #F5EFE2;
    color: #0E1410;
    margin: 0;
    padding: 0;
    line-height: 1.5;
  }
  .topbar {
    position: sticky;
    top: 0;
    background: #0E1410;
    color: #B8F24A;
    padding: 14px 24px;
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 12px;
    z-index: 100;
    box-shadow: 0 2px 12px rgba(0,0,0,0.18);
  }
  .topbar h1 {
    font-size: 15px;
    margin: 0;
    flex: 1 1 auto;
    min-width: 200px;
  }
  .stats {
    font-family: 'JetBrains Mono', monospace;
    font-size: 12px;
    font-weight: 700;
  }
  .stats .ok { color: #B8F24A; }
  .stats .ko { color: #F87171; }
  .stats .todo { color: #D9D2C2; }
  .btn {
    background: #B8F24A;
    color: #0E1410;
    border: none;
    border-radius: 8px;
    padding: 8px 14px;
    font-weight: 800;
    font-size: 11px;
    cursor: pointer;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    transition: transform 80ms ease;
  }
  .btn-outline {
    background: transparent;
    color: #F5EFE2;
    border: 1.5px solid #F5EFE2;
  }
  .btn:hover { transform: translateY(-1px); }
  .btn:active { transform: translateY(0); }
  main {
    max-width: 1000px;
    margin: 0 auto;
    padding: 24px 32px 80px;
  }
  h1 {
    font-size: 28px;
    font-weight: 800;
    margin: 24px 0 12px;
    letter-spacing: -0.5px;
  }
  h2.section {
    font-size: 22px;
    font-weight: 800;
    margin: 36px 0 14px;
    padding-bottom: 8px;
    border-bottom: 2px solid #0E1410;
    letter-spacing: -0.3px;
  }
  h3.subsection {
    font-size: 16px;
    font-weight: 700;
    margin: 24px 0 10px;
    color: #2a3030;
  }
  h4 {
    font-size: 14px;
    font-weight: 700;
    margin: 16px 0 6px;
    color: #444;
  }
  .meta { color: #555; font-size: 13px; margin: 8px 0; }
  hr {
    border: none;
    border-top: 1px solid #D9D2C2;
    margin: 28px 0;
  }
  .item {
    display: flex;
    align-items: flex-start;
    gap: 14px;
    padding: 10px 14px;
    margin: 6px 0;
    border-radius: 10px;
    background: white;
    border: 1px solid #E8E0CC;
    transition: background 120ms ease;
  }
  .item:hover { background: #FAF6EC; }
  .sub-item {
    margin: 4px 0 4px 56px;
    font-size: 13px;
    color: #444;
    list-style: disc;
  }
  .status {
    flex-shrink: 0;
    width: 34px;
    height: 34px;
    border-radius: 8px;
    border: 2px solid #0E1410;
    background: white;
    cursor: pointer;
    font-size: 18px;
    font-weight: 900;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 100ms ease;
    color: white;
  }
  .status[data-state="none"] { background: white; }
  .status[data-state="ok"] {
    background: #16A34A;
    border-color: #15803D;
  }
  .status[data-state="ok"]::before { content: "V"; }
  .status[data-state="ko"] {
    background: #DC2626;
    border-color: #991B1B;
  }
  .status[data-state="ko"]::before { content: "X"; }
  .item.done .text {
    color: #16A34A;
    text-decoration: line-through;
    text-decoration-color: rgba(22, 163, 74, 0.4);
  }
  .item.failed .text {
    color: #DC2626;
    font-weight: 600;
  }
  .text {
    font-size: 14px;
    line-height: 1.5;
    padding-top: 5px;
    flex: 1;
  }
  code {
    background: #F5EFE2;
    padding: 1px 5px;
    border-radius: 3px;
    font-family: 'JetBrains Mono', monospace;
    font-size: 0.88em;
  }
  pre {
    background: #0E1410;
    color: #B8F24A;
    padding: 14px;
    border-radius: 8px;
    overflow-x: auto;
    font-size: 12px;
  }
  /* Print : cacher topbar + boutons, fond blanc */
  @media print {
    .topbar { position: static; box-shadow: none; }
    .btn { display: none; }
    .stats { color: #0E1410; }
    .stats .ok { color: #15803D; }
    .stats .ko { color: #991B1B; }
    .item {
      break-inside: avoid;
      background: white !important;
      border-color: #999;
    }
    body { background: white; }
    h2.section { break-before: auto; }
  }
  /* Modal export */
  .modal-bg {
    display: none;
    position: fixed;
    inset: 0;
    background: rgba(0,0,0,0.55);
    z-index: 1000;
    align-items: center;
    justify-content: center;
    padding: 24px;
  }
  .modal-bg.visible { display: flex; }
  .modal {
    background: white;
    max-width: 760px;
    width: 100%;
    max-height: 80vh;
    border-radius: 14px;
    padding: 24px;
    display: flex;
    flex-direction: column;
    gap: 12px;
  }
  .modal h3 { margin: 0; font-size: 18px; }
  .modal p { margin: 0; font-size: 13px; color: #666; }
  .modal textarea {
    flex: 1;
    min-height: 320px;
    font-family: 'JetBrains Mono', monospace;
    font-size: 12px;
    padding: 12px;
    border: 1px solid #D9D2C2;
    border-radius: 6px;
    background: #FAF6EC;
    resize: vertical;
    white-space: pre;
  }
  .modal-actions { display: flex; gap: 8px; justify-content: flex-end; }
  .modal .btn { background: #0E1410; color: #B8F24A; }
  .modal .btn-outline {
    background: white;
    color: #0E1410;
    border: 1.5px solid #0E1410;
  }
</style>
</head>
<body>

<div class="topbar">
  <h1>Checklist opti_route v2.6 - interactive</h1>
  <div class="stats">
    <span class="todo" id="st-todo">{{TOTAL}}</span> a tester ·
    <span class="ok" id="st-ok">0</span> V ·
    <span class="ko" id="st-ko">0</span> X
  </div>
  <button class="btn" onclick="exportKO()" title="Copier le resume des items en erreur">Exporter X</button>
  <button class="btn btn-outline" onclick="window.print()" title="Imprimer en PDF via Ctrl+P">PDF</button>
  <button class="btn btn-outline" onclick="resetAll()" title="Effacer toutes les marques">Reset</button>
</div>

<main>
{{CONTENT}}
</main>

<div class="modal-bg" id="modal" onclick="if(event.target.id==='modal')closeModal()">
  <div class="modal">
    <h3>Resume des items en erreur (X)</h3>
    <p>Copie le contenu ci-dessous et renvoie-le moi (Claude) pour analyse + correction.</p>
    <textarea id="export-text" readonly></textarea>
    <div class="modal-actions">
      <button class="btn btn-outline" onclick="closeModal()">Fermer</button>
      <button class="btn" onclick="copyToClip()">Copier dans le presse-papiers</button>
    </div>
  </div>
</div>

<script>
const KEY = 'opti_route_checklist_v2';

function loadState() {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return {};
    return JSON.parse(raw);
  } catch(e) { return {}; }
}

function saveState() {
  const state = {};
  document.querySelectorAll('.item').forEach(item => {
    const id = item.dataset.id;
    const s = item.querySelector('.status').dataset.state;
    if (s !== 'none') state[id] = s;
  });
  localStorage.setItem(KEY, JSON.stringify(state));
  updateStats();
}

function updateStats() {
  const items = document.querySelectorAll('.item');
  let ok = 0, ko = 0;
  items.forEach(i => {
    const s = i.querySelector('.status').dataset.state;
    if (s === 'ok') { ok++; i.classList.add('done'); i.classList.remove('failed'); }
    else if (s === 'ko') { ko++; i.classList.add('failed'); i.classList.remove('done'); }
    else { i.classList.remove('done', 'failed'); }
  });
  document.getElementById('st-ok').textContent = ok;
  document.getElementById('st-ko').textContent = ko;
  document.getElementById('st-todo').textContent = items.length - ok - ko;
}

function cycle(btn) {
  const next = { 'none': 'ok', 'ok': 'ko', 'ko': 'none' };
  btn.dataset.state = next[btn.dataset.state];
  saveState();
}

function resetAll() {
  if (!confirm('Reset toutes les marques V/X ?')) return;
  localStorage.removeItem(KEY);
  document.querySelectorAll('.status').forEach(b => b.dataset.state = 'none');
  updateStats();
}

function exportKO() {
  const allNodes = document.querySelectorAll('main h1, main h2.section, main h3.subsection, main .item');
  const lines = [];
  let currentSection = '';
  let currentSub = '';
  let sectionAdded = false;
  let subAdded = false;

  allNodes.forEach(node => {
    if (node.tagName === 'H1') {
      lines.push('# ' + node.textContent.trim());
      lines.push('');
      return;
    }
    if (node.tagName === 'H2') {
      currentSection = node.textContent.trim();
      sectionAdded = false;
      subAdded = false;
      return;
    }
    if (node.tagName === 'H3') {
      currentSub = node.textContent.trim();
      subAdded = false;
      return;
    }
    const btn = node.querySelector('.status');
    if (btn && btn.dataset.state === 'ko') {
      if (!sectionAdded && currentSection) {
        lines.push('');
        lines.push('## ' + currentSection);
        sectionAdded = true;
      }
      if (!subAdded && currentSub) {
        lines.push('');
        lines.push('### ' + currentSub);
        subAdded = true;
      }
      lines.push('- [X] ' + node.querySelector('.text').textContent.trim());
    }
  });

  const ok = document.getElementById('st-ok').textContent;
  const ko = document.getElementById('st-ko').textContent;
  const todo = document.getElementById('st-todo').textContent;
  const total = {{TOTAL}};
  const date = new Date().toLocaleString('fr-FR');

  let out;
  if (ko === '0' && todo === '0') {
    out = `Etat checklist opti_route v2.6 (${date})\n\nTout vert ! ${ok}/${total} items V.`;
  } else if (ko === '0') {
    out = `Etat checklist opti_route v2.6 (${date})\n\n${ok}/${total} V · 0 X · ${todo}/${total} a tester encore.`;
  } else {
    const header = `Etat checklist opti_route v2.6 (${date})\n${ok}/${total} V · ${ko}/${total} X · ${todo}/${total} a tester\n\nIssues a investiguer :`;
    out = header + '\n' + lines.join('\n');
  }
  document.getElementById('export-text').value = out;
  document.getElementById('modal').classList.add('visible');
}

function closeModal() {
  document.getElementById('modal').classList.remove('visible');
}

function copyToClip() {
  const ta = document.getElementById('export-text');
  ta.select();
  ta.setSelectionRange(0, 99999);
  try {
    navigator.clipboard.writeText(ta.value).then(
      () => alert('Copie dans le presse-papiers !'),
      () => { document.execCommand('copy'); alert('Copie !'); }
    );
  } catch (e) {
    document.execCommand('copy');
    alert('Copie !');
  }
}

// Restore state on load
(function() {
  const state = loadState();
  document.querySelectorAll('.item').forEach(item => {
    const s = state[item.dataset.id];
    if (s) item.querySelector('.status').dataset.state = s;
  });
  updateStats();
})();
</script>

</body>
</html>
"""


if __name__ == "__main__":
    main()
