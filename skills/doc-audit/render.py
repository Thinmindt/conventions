"""Render a Markdown file as GitHub shows it, diagrams included, and screenshot it.

Usage: python3 render.py FILE.md [OUT_DIR]

Writes NAME.html, NAME-first.png (the first screen) and NAME-whole.png (the whole page)
to OUT_DIR, the current directory by default, and says how many Mermaid diagrams
rendered. Needs chromium and the network: marked, mermaid and GitHub's stylesheet load
from jsDelivr at pinned versions. Exits 1 if a diagram fails or the page never renders.
"""

import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

CDN = "https://cdn.jsdelivr.net/npm"
MARKED = f"{CDN}/marked@14.1.4/marked.min.js"
MERMAID = f"{CDN}/mermaid@11.17.2/dist/mermaid.min.js"
STYLESHEET = f"{CDN}/github-markdown-css@5.9.0/github-markdown-light.css"
WIDTH = 1012
FIRST_SCREEN = 900
WAIT_MILLISECONDS = 20000
BROWSERS = ("chromium", "chromium-browser", "google-chrome")
TITLE = re.compile(r"<title>([^<]*)</title>")

PAGE = """<!doctype html>
<html><head><meta charset="utf-8"><title>LOADING</title>
<base href="{base}">
<link rel="stylesheet" href="{stylesheet}">
<style>
body {{ margin: 0; background: #fff; }}
.markdown-body {{
  box-sizing: border-box; max-width: 980px; margin: 0 auto; padding: 32px 45px;
}}
</style></head>
<body><article class="markdown-body"></article>
<script type="application/json" id="source">{source}</script>
<script src="{marked}"></script>
<script src="{mermaid}"></script>
<script>
const text = JSON.parse(document.getElementById("source").textContent);
const renderer = new marked.Renderer();
const code = renderer.code.bind(renderer);
renderer.code = (block) => block.lang === "mermaid"
  ? `<pre class="mermaid">${{block.text.replace(/</g, "&lt;")}}</pre>` : code(block);
const article = document.querySelector("article");
article.innerHTML = marked.parse(text, {{ renderer, gfm: true }});
const diagrams = document.querySelectorAll("pre.mermaid").length;
mermaid.initialize({{ startOnLoad: false, theme: "default" }});
mermaid.run({{ querySelector: ".mermaid" }})
  .then(() => {{
    document.title = `RENDERED ${{diagrams}} ${{document.body.scrollHeight}}`;
  }})
  .catch((error) => {{ document.title = `ERROR ${{error.message}}`; }});
</script></body></html>
"""


def page(markdown: Path) -> str:
    source = json.dumps(markdown.read_text()).replace("</", "<\\/")
    return PAGE.format(
        base=markdown.resolve().parent.as_uri() + "/",
        stylesheet=STYLESHEET,
        source=source,
        marked=MARKED,
        mermaid=MERMAID,
    )


def browser() -> str:
    for name in BROWSERS:
        if found := shutil.which(name):
            return found
    raise SystemExit(f"no browser found: install one of {', '.join(BROWSERS)}")


def chromium(*args: str) -> str:
    command = [
        browser(),
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--allow-file-access-from-files",
        f"--virtual-time-budget={WAIT_MILLISECONDS}",
        *args,
    ]
    return subprocess.run(command, capture_output=True, text=True, check=True).stdout


def main(args: list[str]) -> int:
    if len(args) not in (1, 2):
        print(__doc__.split("\n\n")[1], file=sys.stderr)
        return 2
    markdown = Path(args[0])
    out = Path(args[1] if len(args) > 1 else ".")
    out.mkdir(parents=True, exist_ok=True)
    html = out / f"{markdown.stem}.html"
    html.write_text(page(markdown))
    url = html.resolve().as_uri()
    title = TITLE.search(chromium("--dump-dom", url))
    state = title.group(1) if title else "LOADING"
    if not state.startswith("RENDERED"):
        print(f"{markdown}: did not render: {state}", file=sys.stderr)
        return 1
    _, diagrams, height = state.split()
    first = out / f"{markdown.stem}-first.png"
    whole = out / f"{markdown.stem}-whole.png"
    chromium(f"--window-size={WIDTH},{FIRST_SCREEN}", f"--screenshot={first}", url)
    chromium(f"--window-size={WIDTH},{int(height) + 40}", f"--screenshot={whole}", url)
    plural = "" if diagrams == "1" else "s"
    print(f"{markdown}: {diagrams} diagram{plural} rendered; {first}, {whole}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
