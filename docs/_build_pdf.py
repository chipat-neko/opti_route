"""Convertit chaque .md du dossier en .pdf via fpdf2.

Usage :
  python _build_pdf.py            # convertit tous les .md du dossier
  python _build_pdf.py plan_cb    # convertit uniquement plan_cb.md

Avant : on passait par Edge headless avec --print-to-pdf, mais c'etait
fragile (tronquage a 1 page selon les versions, faux succes silencieux
quand subprocess Python). Maintenant on genere directement avec fpdf2
(pur Python, deterministe, pas de navigateur).

Si les .ttf Manrope + JetBrainsMono sont presents dans `_fonts/`,
on les utilise pour respecter la typographie de l'app (cf
`docs/design/handoff/`). Sinon fallback Helvetica/Courier (les
caracteres unicode sont alors strippes en ASCII).
"""
import re
import sys
import unicodedata
from pathlib import Path

from fpdf import FPDF

HERE = Path(__file__).parent
FONTS_DIR = HERE / "_fonts"

# ─── Detection des fonts custom de l'app ─────────────────────────────
# Manrope (variable wght axis, fpdf2 prend l'instance default ~400 + fait
# du synthetic bold pour le style="B"). JetBrains Mono pour le code.
MANROPE_PATH = FONTS_DIR / "Manrope-Variable.ttf"
JETBRAINS_REG = FONTS_DIR / "JetBrainsMono-Regular.ttf"
JETBRAINS_BOLD = FONTS_DIR / "JetBrainsMono-Bold.ttf"
HAS_CUSTOM_FONTS = (
    MANROPE_PATH.exists() and JETBRAINS_REG.exists() and JETBRAINS_BOLD.exists()
)

FONT_BODY = "Manrope" if HAS_CUSTOM_FONTS else "Helvetica"
FONT_MONO = "JetBrainsMono" if HAS_CUSTOM_FONTS else "Courier"


# ─── Couleurs (palette de l'app si custom fonts, sinon ancien CSS) ──
if HAS_CUSTOM_FONTS:
    # Palette opti_route (cf app/lib/theme/app_tokens.dart).
    COLOR_BG = (245, 243, 238)      # cream #F5F3EE (background page de garde)
    COLOR_H1 = (14, 124, 90)        # emerald #0E7C5A
    COLOR_H2 = (14, 124, 90)
    COLOR_H3 = (14, 20, 16)         # ink #0E1410
    COLOR_TEXT = (14, 20, 16)       # ink
    COLOR_MUTE = (92, 102, 96)      # textMute #5C6660
    COLOR_BORDER = (227, 222, 209)  # inkLine #E3DED1
    COLOR_TABLE_HEAD = (213, 235, 224)  # emeraldSoft #D5EBE0
    COLOR_CODE_BG = (239, 234, 224)  # creamSoft #EFEAE0
    COLOR_ACCENT = (184, 242, 74)   # lime #B8F24A (pour highlights)
else:
    COLOR_BG = (255, 255, 255)
    COLOR_H1 = (44, 82, 130)
    COLOR_H2 = (44, 82, 130)
    COLOR_H3 = (45, 55, 72)
    COLOR_TEXT = (34, 34, 34)
    COLOR_MUTE = (74, 85, 104)
    COLOR_BORDER = (203, 213, 224)
    COLOR_TABLE_HEAD = (237, 242, 247)
    COLOR_CODE_BG = (241, 243, 245)
    COLOR_ACCENT = (44, 82, 130)


def _strip_accents(s: str) -> str:
    """fpdf2 avec polices builtin (Helvetica) supporte mal l'UTF-8 hors
    Latin-1. On normalise les accents et caracteres speciaux courants.

    Si on a charge Manrope (Unicode complet), on bypasse ce strip et on
    laisse les accents tels quels -- le rendu est correct.
    """
    if HAS_CUSTOM_FONTS:
        # Manrope gere l'Unicode. Cleanup minimal des emojis non couverts
        # par la fonte (drapeaux de couleur, etc.) qui resteraient en
        # placeholder de toute facon.
        for ch in ("\U0001f7e2", "\U0001f7e1", "\U0001f535", "\U0001f534"):
            s = s.replace(ch, "*")
        return s
    # Remplacement explicite des caracteres qui passent mal en Latin-1.
    s = s.replace("’", "'")  # ’
    s = s.replace("‘", "'")
    s = s.replace("“", '"')
    s = s.replace("”", '"')
    s = s.replace("—", "--")  # em dash
    s = s.replace("–", "-")   # en dash
    s = s.replace("…", "...")
    s = s.replace(" ", " ")   # nbsp
    s = s.replace("→", "->")  # →
    s = s.replace("←", "<-")
    s = s.replace("✓", "v")   # ✓
    s = s.replace("✗", "x")   # ✗
    s = s.replace("→", "->")
    s = s.replace("↑", "^")
    s = s.replace("↓", "v")
    s = s.replace("•", "*")   # •
    s = s.replace("·", "*")   # ·
    s = s.replace("●", "*")
    # Symboles unicode de couleur (rond plein) -> texte
    for ch in ("\U0001f7e2", "\U0001f7e1", "\U0001f535", "\U0001f534"):
        s = s.replace(ch, "*")
    # Etoiles
    s = s.replace("★", "*").replace("☆", "*")
    # Tout ce qui n'est pas Latin-1 -> approximation NFD puis dropping
    out = []
    for ch in s:
        if ord(ch) < 0x100:
            out.append(ch)
        else:
            decomp = unicodedata.normalize("NFKD", ch)
            ascii_part = "".join(c for c in decomp if ord(c) < 0x80)
            out.append(ascii_part if ascii_part else "?")
    return "".join(out)


class _Renderer(FPDF):
    """Rendu PDF de base : marges A4 + chargement des fontes custom.

    Les modes "presentation" (page de garde stylee + footer pagine
    + header de section) sont actives via `--mode=pitch <md>` en ligne
    de commande, ou en passant `mode='pitch'` au constructeur.
    """

    def __init__(self, mode: str = "report", title: str | None = None,
                 subtitle: str | None = None, cover_logo: Path | None = None):
        super().__init__(format="A4")
        # Plus de header repete -> on peut redescendre le top margin.
        top = 20 if mode == "pitch" else 18
        self.set_margins(left=18, top=top, right=18)
        self.set_auto_page_break(auto=True, margin=22 if mode == "pitch" else 18)
        self._mode = mode  # 'report' (default) ou 'pitch'
        self._title = title or ""
        self._subtitle = subtitle or ""
        self._cover_logo = cover_logo
        self._current_section = ""
        self._cover_done = False
        if HAS_CUSTOM_FONTS:
            # Manrope variable font : fpdf2 charge l'instance default
            # (poids ~400). Le style="B" donnera un synthetic bold (fpdf2
            # epaissit les glyphes). Visuellement OK pour un rapport.
            self.add_font("Manrope", "", str(MANROPE_PATH))
            self.add_font("Manrope", "B", str(MANROPE_PATH))
            self.add_font("Manrope", "I", str(MANROPE_PATH))
            self.add_font("Manrope", "BI", str(MANROPE_PATH))
            self.add_font("JetBrainsMono", "", str(JETBRAINS_REG))
            self.add_font("JetBrainsMono", "B", str(JETBRAINS_BOLD))

    # ─── Hooks fpdf2 (header / footer) ──────────────────────────────
    def header(self):
        # Volontairement vide : pas de header repete en haut de chaque
        # page (cf. retour CALOTE Noah). La pagination seule reste en
        # footer pour la navigation.
        return

    def footer(self):
        if self._mode != "pitch" or self.page_no() == 1:
            return
        self.set_y(-12)
        self._font(8)
        self._color(COLOR_MUTE)
        self.cell(0, 5,
                  _strip_accents(f"opti_route  ·  page {self.page_no()}"),
                  align="C")

    # ─── Page de garde mode pitch ───────────────────────────────────
    def render_cover(self):
        """Page de garde plein cadre, fond cream et titre emerald.

        On desactive l'auto_page_break pendant le rendu pour que le
        footer cover (date + auteur) ne declenche pas une page 2 vide
        en cassant accidentellement le bottom margin.
        """
        if self._cover_done:
            return
        self.set_auto_page_break(False)
        self.add_page()
        # Fond cream qui couvre toute la page.
        self.set_fill_color(*COLOR_BG)
        self.rect(0, 0, self.w, self.h, "F")

        # Bandeau lime en haut a gauche
        self.set_fill_color(*COLOR_ACCENT)
        self.rect(0, 0, 48, 6, "F")

        # Logo si dispo
        if self._cover_logo and self._cover_logo.exists():
            try:
                self.image(str(self._cover_logo), x=16, y=24, w=28)
            except Exception:
                pass

        # Titre principal
        self.set_y(60)
        self.set_x(self.l_margin)
        self._font(36, bold=True)
        self._color(COLOR_H1)
        self.multi_cell(0, 12, _strip_accents(self._title or "opti_route"),
                        new_x="LMARGIN", new_y="NEXT")
        self.ln(2)

        # Sous-titre
        if self._subtitle:
            self._font(13)
            self._color(COLOR_TEXT)
            self.multi_cell(0, 6, _strip_accents(self._subtitle),
                            new_x="LMARGIN", new_y="NEXT")
            self.ln(8)

        # Filet decoratif
        self.set_draw_color(*COLOR_H1)
        self.set_line_width(0.8)
        y_line = self.get_y() + 2
        self.line(self.l_margin, y_line,
                  self.l_margin + 60, y_line)

        # Footer page de garde : date + auteur
        from datetime import date
        self.set_y(self.h - 30)
        self._font(9)
        self._color(COLOR_MUTE)
        self.set_x(self.l_margin)
        self.cell(0, 5,
                  _strip_accents(f"Rapport interne · {date.today().isoformat()}"),
                  new_x="LMARGIN", new_y="NEXT")
        self.cell(0, 5, _strip_accents("Auteur : CALOTE Noah"),
                  new_x="LMARGIN", new_y="NEXT")

        # Reactive l'auto_page_break pour les pages suivantes (margin
        # bottom 22 mm pour reserver l'espace footer pagine).
        self.set_auto_page_break(True, margin=22)
        self._cover_done = True

    def set_section(self, section: str):
        """Met a jour le titre de section affiche dans le header."""
        self._current_section = section

    # Helpers de format
    def _font(self, size: float, bold: bool = False, italic: bool = False):
        style = ""
        if bold:
            style += "B"
        if italic:
            style += "I"
        self.set_font(FONT_BODY, style, size=size)

    def _color(self, rgb):
        self.set_text_color(*rgb)

    def render_inline(self, text: str, base_size: float = 10.5):
        """Rendu d'une ligne avec gestion basique de **gras**, *italique*,
        et `code`. Utilise multi_cell pour le wrapping.
        """
        text = _strip_accents(text)
        # Token simple : on splite sur les marqueurs et on alterne.
        parts = re.split(r"(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`)", text)
        # Si pas de markup -> direct.
        if all(not p.startswith(("**", "*", "`")) for p in parts):
            self._font(base_size)
            self._color(COLOR_TEXT)
            self.multi_cell(0, base_size * 0.55, text, new_x="LMARGIN", new_y="NEXT")
            return
        # Mixed : on traite token par token.
        # multi_cell ne supporte pas le mixage easy ; on simule en
        # decoupant les lignes a la main et en ecrivant token par token.
        # Approche simplifiee : on perd le wrapping fin, mais pour notre
        # contenu c'est OK.
        self._font(base_size)
        self._color(COLOR_TEXT)
        line = ""
        for part in parts:
            if part.startswith("**") and part.endswith("**"):
                # Flush ce qu'on a, puis ecrit en gras.
                if line:
                    self._font(base_size)
                    self.write(base_size * 0.55, line)
                    line = ""
                self._font(base_size, bold=True)
                self.write(base_size * 0.55, part[2:-2])
                self._font(base_size)
            elif part.startswith("*") and part.endswith("*") and len(part) > 1:
                if line:
                    self._font(base_size)
                    self.write(base_size * 0.55, line)
                    line = ""
                self._font(base_size, italic=True)
                self.write(base_size * 0.55, part[1:-1])
                self._font(base_size)
            elif part.startswith("`") and part.endswith("`"):
                if line:
                    self._font(base_size)
                    self.write(base_size * 0.55, line)
                    line = ""
                # Code inline : juste en mono-equivalent
                self.set_font(FONT_MONO, "", base_size - 0.5)
                self.write(base_size * 0.55, part[1:-1])
                self._font(base_size)
            else:
                line += part
        if line:
            self._font(base_size)
            self.write(base_size * 0.55, line)
        self.ln(base_size * 0.7)

    def render_h1(self, text: str):
        if self.get_y() > 30:
            self.ln(4)
        self._font(20, bold=True)
        self._color(COLOR_H1)
        self.multi_cell(0, 10, _strip_accents(text), new_x="LMARGIN", new_y="NEXT")
        # Trait sous le H1
        self.set_draw_color(*COLOR_H1)
        self.set_line_width(0.6)
        y = self.get_y()
        self.line(self.l_margin, y, self.w - self.r_margin, y)
        self.ln(4)

    def render_h2(self, text: str):
        # En mode pitch : on met a jour le header de section, et on
        # bascule sur nouvelle page UNIQUEMENT si le reste de la page
        # courante est trop petit (sinon trous blancs).
        if self._mode == "pitch" and self._cover_done:
            self._current_section = text
            # Force nouvelle page si on a moins de 60mm restants
            # (un H2 + au moins quelques lignes ne tiennent pas).
            remaining = (self.h - self.b_margin) - self.get_y()
            if remaining < 60:
                self.add_page()
            else:
                self.ln(8)
        else:
            self.ln(6)
        self._font(16, bold=True)
        self._color(COLOR_H2)
        self.multi_cell(0, 8, _strip_accents(text), new_x="LMARGIN", new_y="NEXT")
        self.set_draw_color(*COLOR_BORDER)
        self.set_line_width(0.3)
        y = self.get_y() + 0.5
        self.line(self.l_margin, y, self.w - self.r_margin, y)
        self.ln(4)

    def render_h3(self, text: str):
        self.ln(3)
        self._font(11.5, bold=True)
        self._color(COLOR_H3)
        self.multi_cell(0, 6, _strip_accents(text), new_x="LMARGIN", new_y="NEXT")
        self.ln(1)

    def render_bullet(self, text: str):
        body_size = 11.5 if self._mode == "pitch" else 10.5
        lh = 6 if self._mode == "pitch" else 5
        self._font(body_size)
        self._color(COLOR_TEXT)
        x_start = self.get_x()
        self.cell(5, lh, "*", new_x="RIGHT", new_y="TOP")
        self.set_x(x_start + 5)
        self.multi_cell(0, lh, _strip_accents(text), new_x="LMARGIN", new_y="NEXT")
        self.ln(0.5)

    def render_paragraph(self, text: str):
        body_size = 11.5 if self._mode == "pitch" else 10.5
        lh = 6 if self._mode == "pitch" else 5
        self._font(body_size)
        self._color(COLOR_TEXT)
        self.multi_cell(0, lh, _strip_accents(text), new_x="LMARGIN", new_y="NEXT")
        self.ln(2.5 if self._mode == "pitch" else 1.5)

    def render_italic(self, text: str):
        self._font(9.5, italic=True)
        self._color(COLOR_MUTE)
        self.multi_cell(0, 4.5, _strip_accents(text), new_x="LMARGIN", new_y="NEXT")
        self.ln(2)

    def render_table(self, rows: list[list[str]]):
        if not rows:
            return
        # Sanitize
        rows = [[_strip_accents(c) for c in r] for r in rows]
        ncols = max(len(r) for r in rows)
        usable_w = self.w - self.l_margin - self.r_margin
        col_w = usable_w / ncols

        # Header (1ere ligne) puis body, en ignorant la ligne de separators
        # (`|---|---|`).
        header = rows[0]
        body = [r for r in rows[1:] if not all(re.match(r"^-+$", c.strip()) or c.strip().startswith(":-") for c in r)]

        # Calcul de la hauteur de ligne : on prend la max selon le nb de wraps
        def line_height(row, font_size):
            self._font(font_size)
            max_h = 5
            for cell in row:
                # Estimation : la fonction `multi_cell` peut wrap. On
                # compte en mesurant la largeur du texte vs col_w.
                lines = self.multi_cell(
                    col_w, 5, cell, new_x="LMARGIN", new_y="NEXT",
                    dry_run=True, output="LINES",
                )
                h = max(1, len(lines)) * 5
                if h > max_h:
                    max_h = h
            return max_h

        # Header
        h = line_height(header, 9.5)
        self.set_fill_color(*COLOR_TABLE_HEAD)
        self.set_draw_color(*COLOR_BORDER)
        self._font(9.5, bold=True)
        self._color(COLOR_H3)
        y_start = self.get_y()
        x_start = self.l_margin
        for i, cell in enumerate(header):
            x = x_start + i * col_w
            self.set_xy(x, y_start)
            self.multi_cell(col_w, 5, cell, border=1, fill=True)
        self.set_xy(x_start, y_start + h)

        # Body
        self._font(9.5)
        self._color(COLOR_TEXT)
        for row in body:
            # Pad row si moins de cols que header
            while len(row) < ncols:
                row.append("")
            h = line_height(row, 9.5)
            y_row = self.get_y()
            if y_row + h > self.h - self.b_margin:
                self.add_page()
                y_row = self.get_y()
            for i, cell in enumerate(row):
                x = x_start + i * col_w
                self.set_xy(x, y_row)
                self.multi_cell(col_w, 5, cell, border=1)
            self.set_xy(x_start, y_row + h)
        self.ln(3)


def parse_md_to_pdf(md_text: str, pdf_path: Path, mode: str = "report"):
    """Parse un Markdown et produit un PDF.

    En mode 'pitch', extrait le titre (1er H1) et le sous-titre (1ere
    ligne italique) pour la page de garde, puis chaque H2 = nouvelle
    page deck-style avec header.
    """
    title = ""
    subtitle = ""
    logo = (HERE / "_assets" / "logo-512.png")
    if not logo.exists():
        logo = None

    lines = md_text.split("\n")

    if mode == "pitch":
        # Scan rapide : 1er H1 = titre, 1ere ligne italique apres = sous-titre.
        for ln in lines:
            s = ln.strip()
            if not title and s.startswith("# "):
                title = s[2:].strip()
            elif title and not subtitle and s.startswith("*") and s.endswith("*") and len(s) >= 3:
                subtitle = s.strip("*").strip()
                break
            elif title and s and not s.startswith("#"):
                # Si on tombe sur autre chose qu'un italique apres le H1,
                # on s'arrete : pas de sous-titre.
                break

    pdf = _Renderer(mode=mode, title=title, subtitle=subtitle, cover_logo=logo)
    if mode == "pitch":
        pdf.render_cover()
        pdf.add_page()
    else:
        pdf.add_page()

    # Skip le 1er H1 et 1ere ligne italique (deja consommes en cover) en
    # mode pitch.
    consumed_title = False
    consumed_subtitle = False
    i = 0
    while i < len(lines):
        line = lines[i].rstrip()

        if mode == "pitch" and not consumed_title and line.strip().startswith("# "):
            consumed_title = True
            i += 1
            continue
        if (mode == "pitch" and consumed_title and not consumed_subtitle
                and line.strip().startswith("*") and line.strip().endswith("*")
                and len(line.strip()) >= 3):
            consumed_subtitle = True
            i += 1
            continue

        if not line.strip():
            i += 1
            continue

        # Code fence : on ignore le marker mais on rend le contenu en
        # monospace en bloc.
        if line.startswith("```"):
            block = []
            i += 1
            while i < len(lines) and not lines[i].startswith("```"):
                block.append(lines[i])
                i += 1
            i += 1  # skip closing ```
            pdf.set_font(FONT_MONO, "", 8.5)
            pdf.set_text_color(*COLOR_TEXT)
            pdf.set_fill_color(*COLOR_CODE_BG)
            for bl in block:
                pdf.multi_cell(
                    0, 4, _strip_accents(bl),
                    new_x="LMARGIN", new_y="NEXT", fill=True,
                )
            pdf.ln(2)
            continue

        # Tables : detecter `| col | col |` puis les lignes consecutives.
        if line.startswith("|") and "|" in line[1:]:
            rows = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                cells = [c.strip() for c in lines[i].strip().strip("|").split("|")]
                rows.append(cells)
                i += 1
            pdf.render_table(rows)
            continue

        if line.startswith("# "):
            pdf.render_h1(line[2:])
        elif line.startswith("## "):
            pdf.render_h2(line[3:])
        elif line.startswith("### "):
            pdf.render_h3(line[4:])
        elif line.startswith("- ") or line.startswith("* "):
            pdf.render_bullet(line[2:])
        elif line.startswith("---") and len(line.strip("-").strip()) == 0:
            pdf.ln(2)
            pdf.set_draw_color(*COLOR_BORDER)
            pdf.set_line_width(0.3)
            y = pdf.get_y()
            pdf.line(pdf.l_margin, y, pdf.w - pdf.r_margin, y)
            pdf.ln(3)
        elif line.startswith("*") and line.endswith("*") and line.count("*") == 2:
            pdf.render_italic(line.strip("*"))
        elif line.startswith(">"):
            # Blockquote : juste un paragraphe en italique pour rester
            # simple.
            pdf.render_italic(line.lstrip(">").strip())
        else:
            pdf.render_paragraph(line)

        i += 1

    pdf.output(str(pdf_path))


def convert_one(md_path: Path, mode: str = "report") -> int:
    pdf_path = md_path.with_suffix(".pdf")
    md_text = md_path.read_text(encoding="utf-8")
    parse_md_to_pdf(md_text, pdf_path, mode=mode)
    print(f"PDF genere : {pdf_path}  (mode={mode})")
    return 0


def main() -> int:
    args = sys.argv[1:]
    mode = "report"
    cleaned = []
    for a in args:
        if a == "--pitch":
            mode = "pitch"
        else:
            cleaned.append(a)
    args = cleaned

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
        # Filtre les .md "internes" qui ne doivent pas etre PDF-ises.
        targets = [t for t in targets if not t.name.startswith("_")]
        if not targets:
            print("Aucun .md trouve dans le dossier.")
            return 1

    for md in targets:
        rc = convert_one(md, mode=mode)
        if rc != 0:
            return rc
    return 0


if __name__ == "__main__":
    sys.exit(main())
