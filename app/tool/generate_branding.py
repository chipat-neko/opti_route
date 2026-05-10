"""Genere les PNG sources pour l'app icon et le splash screen.

Sortie dans `app/assets/branding/` :
- icon_source.png    -> 1024x1024, fond ink, eclair lime centre. Source
                        pour `flutter_launcher_icons` (legacy + adaptive
                        background).
- icon_foreground.png-> 1024x1024, transparent + eclair lime plus
                        grand. Source pour la couche foreground des
                        adaptive icons Android (Android 8+).
- splash_logo.png    -> 512x512, transparent + eclair lime. Affiche
                        centre au-dessus du fond cream du splash.

Couleurs alignees sur `app/lib/theme/app_tokens.dart`.

Lancement : `python tool/generate_branding.py` depuis `app/`.
A relancer si on touche au design.
"""

from __future__ import annotations

import os
from pathlib import Path

from PIL import Image, ImageDraw

# Tokens (cf. app_tokens.dart)
INK = (14, 20, 16, 255)        # #0E1410
LIME = (184, 242, 74, 255)     # #B8F24A
CREAM = (245, 243, 238, 255)   # #F5F3EE -- pas dessine, juste reference

OUTPUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "branding"


def lightning_polygon(cx: int, cy: int, height: int) -> list[tuple[int, int]]:
    """Retourne les sommets d'un eclair stylise centre sur (cx, cy),
    de hauteur `height` (du sommet au bas de la pointe).

    L'eclair est legerement asymetrique pour eviter le rendu trop
    "bouton play". Largeur ~ 0.55 * height.
    """
    h = height
    w = int(h * 0.55)

    top = cy - h // 2
    bot = cy + h // 2

    # 7 points qui forment le Z classique de l'eclair.
    return [
        (cx + int(w * 0.10), top),                                # 0: haut droite
        (cx - int(w * 0.45), cy - int(h * 0.05)),                 # 1: milieu gauche
        (cx - int(w * 0.05), cy - int(h * 0.05)),                 # 2: pli central haut
        (cx - int(w * 0.30), bot),                                # 3: bas (pointe)
        (cx + int(w * 0.45), cy + int(h * 0.05)),                 # 4: milieu droite
        (cx + int(w * 0.05), cy + int(h * 0.05)),                 # 5: pli central bas
        (cx + int(w * 0.40), top),                                # 6: retour vers le haut
    ]


def make_icon_source(size: int = 1024) -> Image.Image:
    """Icone "legacy" : fond ink avec eclair lime centre.

    Sert pour les versions Android < 8 (icone carree classique) et
    comme fond des adaptive icons sur Android 8+.
    """
    img = Image.new("RGBA", (size, size), INK)
    draw = ImageDraw.Draw(img)
    # L'eclair occupe ~60 % de la hauteur pour rester confortable
    # dans la zone "safe" (66 % du canvas pour les adaptive icons).
    points = lightning_polygon(size // 2, size // 2, int(size * 0.62))
    draw.polygon(points, fill=LIME)
    return img


def make_icon_foreground(size: int = 1024) -> Image.Image:
    """Couche foreground des adaptive icons : eclair lime sur fond
    transparent. Android compose ca au-dessus de la couche background
    (un aplat ink defini dans la config flutter_launcher_icons).

    L'eclair est plus grand ici car la zone "visible" sur les masques
    Android est plus petite que sur l'icone legacy.
    """
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    points = lightning_polygon(size // 2, size // 2, int(size * 0.55))
    draw.polygon(points, fill=LIME)
    return img


def make_splash_logo(size: int = 512) -> Image.Image:
    """Logo du splash : pastille ink ronde + eclair lime centre.

    Sera affiche par `flutter_native_splash` au centre d'un fond cream.
    On garde une pastille pour donner du contraste avec le cream.
    """
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Cercle ink occupant tout le canvas, eclair lime dedans.
    draw.ellipse((0, 0, size - 1, size - 1), fill=INK)
    points = lightning_polygon(size // 2, size // 2, int(size * 0.55))
    draw.polygon(points, fill=LIME)
    return img


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    targets = {
        "icon_source.png": make_icon_source(),
        "icon_foreground.png": make_icon_foreground(),
        "splash_logo.png": make_splash_logo(),
    }
    for name, img in targets.items():
        path = OUTPUT_DIR / name
        img.save(path, format="PNG")
        print(f"  wrote {path.relative_to(OUTPUT_DIR.parent.parent)} "
              f"({img.size[0]}x{img.size[1]})")
    print(f"\nDone. Sources written to {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
