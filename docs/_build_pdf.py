"""Convertit chaque .md du dossier en .pdf via markdown -> HTML -> Edge headless.

Usage :
  python _build_pdf.py            # convertit tous les .md du dossier
  python _build_pdf.py plan_cb    # convertit uniquement plan_cb.md
"""
import subprocess
import sys
from pathlib import Path

import markdown

HERE = Path(__file__).parent

CSS = """
@page { size: A4; margin: 18mm 16mm; }
body {
    font-family: 'Segoe UI', 'Helvetica Neue', Arial, sans-serif;
    font-size: 10.5pt;
    line-height: 1.5;
    color: #222;
    max-width: none;
}
h1 { font-size: 22pt; border-bottom: 2px solid #2c5282; padding-bottom: 6px; color: #2c5282; }
h2 { font-size: 15pt; margin-top: 22px; color: #2c5282; border-bottom: 1px solid #cbd5e0; padding-bottom: 3px; }
h3 { font-size: 12pt; color: #2d3748; }
code { background: #f1f3f5; padding: 1px 5px; border-radius: 3px; font-size: 9.5pt; }
pre { background: #f7fafc; border: 1px solid #e2e8f0; padding: 10px; border-radius: 4px; overflow-x: auto; font-size: 9pt; }
pre code { background: transparent; padding: 0; }
table { border-collapse: collapse; width: 100%; margin: 10px 0; font-size: 9.5pt; }
th, td { border: 1px solid #cbd5e0; padding: 6px 8px; text-align: left; vertical-align: top; }
th { background: #edf2f7; font-weight: 600; }
hr { border: none; border-top: 1px solid #cbd5e0; margin: 18px 0; }
blockquote { border-left: 3px solid #2c5282; margin: 10px 0; padding-left: 12px; color: #4a5568; }
ul, ol { padding-left: 22px; }
a { color: #2c5282; text-decoration: none; }
strong { color: #1a202c; }
"""

EDGE_CANDIDATES = [
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
]


def find_edge() -> str:
    for path in EDGE_CANDIDATES:
        if Path(path).exists():
            return path
    raise FileNotFoundError("Microsoft Edge non trouve. Installe Edge ou adapte le script.")


def md_to_html(md_text: str) -> str:
    body = markdown.markdown(
        md_text,
        extensions=["tables", "fenced_code", "toc", "sane_lists"],
    )
    return f"""<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<title>Plan opti_route</title>
<style>{CSS}</style>
</head>
<body>
{body}
</body>
</html>
"""


def convert_one(md_path: Path, edge: str) -> int:
    pdf_path = md_path.with_suffix(".pdf")
    html_path = md_path.with_name(f"_{md_path.stem}_temp.html")

    md_text = md_path.read_text(encoding="utf-8")
    html_path.write_text(md_to_html(md_text), encoding="utf-8")

    cmd = [
        edge,
        "--headless=new",
        "--disable-gpu",
        f"--print-to-pdf={pdf_path}",
        "--no-pdf-header-footer",
        html_path.as_uri(),
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    html_path.unlink(missing_ok=True)
    if proc.returncode != 0:
        print(f"Echec sur {md_path.name}")
        print("Edge stdout:", proc.stdout)
        print("Edge stderr:", proc.stderr)
        return proc.returncode

    print(f"PDF genere : {pdf_path}")
    return 0


def main() -> int:
    edge = find_edge()
    args = sys.argv[1:]
    if args:
        targets = []
        for arg in args:
            p = HERE / (arg if arg.endswith(".md") else f"{arg}.md")
            if not p.exists():
                print(f"Introuvable : {p}")
                return 1
            targets.append(p)
    else:
        targets = sorted(HERE.glob("*.md"))
        if not targets:
            print("Aucun .md trouve dans le dossier.")
            return 1

    for md in targets:
        rc = convert_one(md, edge)
        if rc != 0:
            return rc
    return 0


if __name__ == "__main__":
    sys.exit(main())
