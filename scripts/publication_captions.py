"""Caption registry shared by Word builders after the publication revision."""
from pathlib import Path
import json
def publication_caption(stem, fallback):
    path=Path(__file__).resolve().parents[1]/'results/figure_descriptions/publication_captions.json'
    if not path.exists():return fallback
    return json.loads(path.read_text(encoding='utf8')).get(stem,fallback)
