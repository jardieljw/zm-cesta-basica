from pathlib import Path
import argparse
import hashlib
import json

resources = Path(__file__).resolve().parent
root = resources.parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--output-dir', required=True)
parser.add_argument('--replace-draft', action='store_true')
args = parser.parse_args()
source = root / 'docs/referencias_frontend/rodada-organizacao-2026-10-16/organizacao-integrada-zm.html'
assert hashlib.sha256(source.read_bytes()).hexdigest() == '613beab1e444448ba69c46dc26fbc4ab1072661915c1aa695a8f6b53314a6a6d'
text = source.read_text(encoding='utf-8').replace('zm-organization', 'zm-finish')

def once(old, new):
    global text
    assert text.count(old) == 1, (old[:100], text.count(old))
    text = text.replace(old, new, 1)

once("const design={appearance:", "const design={material:'glass',appearance:")
once("for(const v of views){v.app.style.colorScheme", "for(const v of views){v.app.dataset.material=design.material;v.app.style.colorScheme")
once("if(saved.design){const d=saved.design;", "if(saved.design){const d=saved.design;if(['glass','solid'].includes(d.material))design.material=d.material;")
once("prototype:'Organização integrada ZM — FE-049'", "prototype:'Acabamento integrado ZM — FE-052'")
once("t.addSelect(design,'format'", "t.addSelect(design,'material',{label:'Material da prévia',options:[{label:'Vidro suave',value:'glass'},{label:'Sólido',value:'solid'}]});t.addSelect(design,'format'")
start = text.index('  function renderList(kind){')
end = text.index('  function renderAccount(a){', start)
text = text[:start] + (resources / 'lista-financeira.js').read_text(encoding='utf-8') + '\n' + text[end:]
once("if(action==='filter'){s.filter[b.dataset.kind]=b.dataset.filter;render();save();return;}", "if(action==='filter'){s.filter[b.dataset.kind]=b.dataset.filter;render();content.querySelector('.finish-filter>summary')?.focus();save();return;}")
css = (resources / 'acabamento.css').read_text(encoding='utf-8')
once('<script>', '<style>\n' + css + '\n</style>\n<script>')
folder = Path(args.output_dir).resolve()
folder.mkdir(parents=True, exist_ok=True)
target = folder / 'acabamento-integrado-zm.html'
if target.exists() and not args.replace_draft:
    raise SystemExit('Refusing to replace an existing source. Use a new folder for reproduction.')
target.write_text(text, encoding='utf-8', newline='\n')
print(json.dumps({'path': str(target), 'sha256': hashlib.sha256(target.read_bytes()).hexdigest()}))
