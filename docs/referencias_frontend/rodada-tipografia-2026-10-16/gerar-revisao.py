from pathlib import Path
import json, hashlib, argparse

workspace=Path(__file__).resolve().parents[3]
parser=argparse.ArgumentParser()
parser.add_argument('--output-dir',required=True,help='New directory; historical outputs are never replaced')
args=parser.parse_args()
resources=Path(__file__).resolve().parent
old=workspace/'docs/referencias_frontend/rodada-recuperacao-integrada-2026-10-16/mapa-integrado-recuperado-zm.html'
folder=Path(args.output_dir).resolve()
folder.mkdir(parents=True,exist_ok=False)
source=old.read_text(encoding='utf-8')
assert hashlib.sha256(old.read_bytes()).hexdigest()=='e3c688890506c3cf37a83793d811d9eb26f3c6b4b8b6aaa92a2f8fe597b57375'
source=source.replace('zm-recovery','zm-typography')
source=source.replace('aria-label="Mapa integrado recuperado ZM"','aria-label="Comparação de hierarquia ZM"')
source=source.replace('data-variant="No celular" aria-label="Proposta no celular"','data-variant="Leitura orientada" aria-label="Hierarquia proposta"')
source=source.replace('data-variant="No computador" aria-label="Proposta no computador"','data-variant="Leitura recuperada" aria-label="Hierarquia da referência recuperada"')
source=source.replace('data-device="mobile" aria-label="Navegação no celular"','data-device="mobile" data-reading="oriented" aria-label="Leitura orientada"')
source=source.replace('data-device="desktop" aria-label="Navegação no computador"','data-device="desktop" data-reading="recovered" aria-label="Leitura recuperada"')
source=source.replace("motion:'standard'};","motion:'standard',format:'mobile',textScale:'100',example:'everyday'};")
source=source.replace(" const canonical=v=>",(resources/'tipografia.js').read_text(encoding='utf-8')+"\n const canonical=v=>")
source=source.replace("  const s={area:'inicio'","  const s=views[0]?.s||{area:'inicio'")
source=source.replace("v.app.querySelectorAll('[data-pref]').forEach(input=>input.value=design[input.dataset.pref]);}\n }","v.app.querySelectorAll('[data-pref]').forEach(input=>input.value=design[input.dataset.pref]);}\n  applyReading();\n }")
assert '  applyReading();' in source
source=source.replace("const d=saved.design;if(['chat'", "const d=saved.design;if(['mobile','desktop'].includes(d.format))design.format=d.format;if(['100','150','200'].includes(d.textScale))design.textScale=d.textScale;if(['everyday','stress'].includes(d.example))design.example=d.example;changeReadingExample();if(['chat'")
source=source.replace(" for(const v of views)v.render();restore(initial);", " for(const v of views)v.render();restore(initial);\n for(const name of ['click','input','change'])root.addEventListener(name,event=>{const app=event.composedPath().find(e=>e?.classList?.contains('app'));if(!app)return;for(const v of views)if(v.app!==app)v.render();applyReading();});")
source=source.replace("onChange:()=>{applyDesign();save();}","onChange:()=>{changeReadingExample();applyDesign();fitStage();save();}")
source=source.replace("t.addSelect(design,'motion'", "t.addSelect(design,'format',{label:'Formato da prévia',options:[{label:'Celular',value:'mobile'},{label:'Computador',value:'desktop'}]});t.addSelect(design,'textScale',{label:'Texto do conteúdo',options:[{label:'100%',value:'100'},{label:'150%',value:'150'},{label:'200%',value:'200'}]});t.addSelect(design,'example',{label:'Caso de leitura (reinicia exemplo)',options:[{label:'Cotidiano',value:'everyday'},{label:'Nome longo e quantias altas',value:'stress'}]});t.addSelect(design,'motion'")
source=source.replace("prototype:'Mapa integrado recuperado ZM'","prototype:'Hierarquia ZM — FE-048'")
css=(resources/'tipografia.css').read_text(encoding='utf-8')
# Both comparisons stay usable in deliberately extreme scenarios. At ordinary
# 100% the recovered reading retains its original typography and composition.
safety=css[css.index('#zm-typography-demo .app[data-reading=oriented] .two'):css.index('@media(max-width:550px)')]
safety=safety.replace('[data-reading=oriented]','[data-reading=recovered][data-adapted=true]')
source=source.replace('<script>','<style>\n'+css+'\n'+safety+'\n</style>\n<script>',1)
source=source.replace("if(width!==lastWidth){stageHeight=1030;lastWidth=width;}","const stageKey=width+'|'+design.format+'|'+design.textScale+'|'+design.example;if(stageKey!==lastWidth){stageHeight=1030;lastWidth=stageKey;}")
target=folder/'hierarquia-integrada-zm.html'
target.write_text(source,encoding='utf-8',newline='\n')
print(json.dumps({'source':str(target),'bytes':target.stat().st_size,'sha256':hashlib.sha256(target.read_bytes()).hexdigest()}))
