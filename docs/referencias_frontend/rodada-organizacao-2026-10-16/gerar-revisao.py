from pathlib import Path
import hashlib,re,json,argparse
root=Path(__file__).resolve().parents[3]
resources=Path(__file__).resolve().parent
parser=argparse.ArgumentParser()
parser.add_argument('--output-dir',required=True)
args=parser.parse_args()
base=root/'docs/referencias_frontend/rodada-tipografia-2026-10-16/hierarquia-integrada-zm.html'
assert hashlib.sha256(base.read_bytes()).hexdigest()=='01f28ece47a54fdd2f989caf351550ff5d6742b6d520799ec97b79e2b4abd071'
s=base.read_text(encoding='utf-8').replace('zm-typography','zm-organization')
s='\n'.join(line for line in s.split('\n') if '[data-reading=oriented]' not in line)
s=s.replace('id="zm-organization-demo" class="viz-carousel" aria-label="Comparação de hierarquia ZM"','id="zm-organization-demo" aria-label="Prévia integrada ZM"')
s=re.sub(r' <section data-variant="Leitura orientada"[\s\S]*?</section>\n','',s,count=1)
s=s.replace('data-variant="Leitura recuperada" aria-label="Hierarquia da referência recuperada" hidden','aria-label="Aplicativo com leitura recuperada"')
s=s.replace('class="app product desktop" data-device="desktop"','class="app product mobile" data-device="main"')
s=s.replace('vendas:\'Vendas\'','vendas:\'Negócio\'').replace('<span>Vendas</span></button>','<span>Negócio</span></button>')
s=s.replace("const filters={week:","const periods={day:{short:'Dia',when:'hoje',range:'16 de outubro',filter:'today',baskets:8,sales:86000,cost:50000,expenses:6000,incomplete:0},week:{short:'Semana',when:'nesta semana',range:'12 a 18 de outubro',filter:'week',baskets:32,sales:344000,cost:205000,expenses:45000,incomplete:1},month:{short:'Mês',when:'neste mês',range:'1 a 31 de outubro',filter:'month',baskets:42,sales:450000,cost:260000,expenses:66000,incomplete:2}};\n const filters={month:'Neste mês · 1 a 31 de outubro',week:")
s=re.sub(r" const selected=\(kind,filter\)=>[^\n]+", " const selected=(kind,filter)=>accounts.filter(a=>a.kind===kind&&balance(a)>0&&(filter==='open'||(filter==='week'?a.due>='2026-10-12'&&a.due<='2026-10-18':filter==='month'?a.due>='2026-10-01'&&a.due<='2026-10-31':group(a)===filter)));",s,count=1)
s=s.replace("['week','Semana'],['today','Hoje']","['week','Semana'],['today','Hoje'],['month','Mês']")
s=s.replace("const s=views[0]?.s||{area:'inicio'","const s=views[0]?.s||{homePeriod:'week',area:'inicio'")
s=s.replace("{area:v.s.area,stacks:","{area:v.s.area,homePeriod:v.s.homePeriod,stacks:")
s=s.replace("const validPage=(area,p)=>", "if(periods[saved.homePeriod])s.homePeriod=saved.homePeriod;const validPage=(area,p)=>")
s=s.replace("['pagar','receber','resultado']","['pagar','receber']")
s=s.replace("(area==='estoque'&&p==='produtos-atencao')","(area==='vendas'&&p==='resultado')||(area==='estoque'&&p==='produtos-atencao')")
s=s.replace("title.textContent=areas[s.area];backButton.hidden", "content.parentElement.dataset.screen=s.area;title.textContent=areas[s.area];backButton.hidden")
s=s.replace("s.area==='financeiro'&&p==='resultado'","s.area==='vendas'&&p==='resultado'")
s=s.replace("   else if(s.area==='inicio')renderHome();", "   else if(s.area==='inicio')renderHome();\n   else if(s.area==='vendas')renderBusiness();")
s=s.replace("if(action==='result'){navigate('financeiro','resultado');return;}","if(action==='result'){navigate('vendas','resultado');return;}\n   if(action==='home-period'){if(periods[b.dataset.period]){s.homePeriod=b.dataset.period;render();save();}return;}\n   if(action==='home-financial'){const kind=b.dataset.kind;s.filter[kind]=currentPeriod().filter;navigate('financeiro',kind==='pay'?'pagar':'receber');return;}")
s=s.replace("if(action==='deadline'){s.filter.pay=b.dataset.filter;navigate('financeiro','pagar');return;}","if(action==='deadline'){const kind=b.dataset.kind||'pay';s.filter[kind]=b.dataset.filter;navigate('financeiro',kind==='pay'?'pagar':'receber');return;}")
s=s.replace("prototype:'Hierarquia ZM — FE-048'","prototype:'Organização integrada ZM — FE-049'")
s=s.replace("app.querySelector('.demo-label').textContent=(oriented?'Leitura orientada':'Leitura recuperada')+' · '+(activeExample==='stress'?'Caso de teste com nome longo e quantias altas':'Dados de exemplo');","app.querySelector('.demo-label').textContent='Prévia integrada · Leitura recuperada · '+(activeExample==='stress'?'Caso de teste':'Dados de exemplo');app.closest('.stage').classList.toggle('viz-dotted-background',design.format!=='desktop');")
s=s.replace("const canonical=v=>", "const canonical=v=>")
# Function declarations below supersede only these page compositions. All domain
# demonstration flows, fields, calendar, navigation state and styles stay intact.
pages=(resources/'organizacao-pages.js').read_text(encoding='utf-8')
s=re.sub(r'^  function renderHome\(\)\{[^\n]+\n','',s,count=1,flags=re.M)
s=re.sub(r'^  function renderFinance\(\)\{[\s\S]*?\n  }\n','',s,count=1,flags=re.M)
s=re.sub(r'^  function renderResult\(\)\{[^\n]+\n','',s,count=1,flags=re.M)
s=s.replace('  function render(){',pages+'\n  function render(){',1)
css=(resources/'organizacao.css').read_text(encoding='utf-8')
s=s.replace('<script>','<style>\n'+css+'\n</style>\n<script>',1)
folder=Path(args.output_dir).resolve();folder.mkdir(parents=True,exist_ok=False)
target=folder/'organizacao-integrada-zm.html';target.write_text(s,encoding='utf-8',newline='\n')
print(json.dumps({'path':str(target),'sha256':hashlib.sha256(target.read_bytes()).hexdigest()}))
