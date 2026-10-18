"""Audita copias locais sem alterar previas, aplicativo ou manifestos antigos."""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--visualizations", required=True, type=Path)
parser.add_argument("--recover-missing", action="store_true")
args = parser.parse_args()
audit_dir = Path(__file__).resolve().parent
repo = audit_dir.parents[2]
archive = repo / "docs/referencias_frontend"

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def relative(path):
    return path.relative_to(repo).as_posix()

manifests, copies, known_hashes = [], [], {}
for manifest in sorted(archive.rglob("manifesto*.json")):
    if audit_dir in manifest.parents:
        continue
    data = json.loads(manifest.read_text(encoding="utf-8-sig"))
    entries = data.get("arquivos", data.get("files", []))
    checked = []
    for entry in entries:
        name = entry.get("arquivo", entry.get("file"))
        path = (manifest.parent / name).resolve()
        if not path.is_relative_to(archive.resolve()):
            raise ValueError("Manifest path outside archive")
        actual = sha(path) if path.is_file() else None
        actual_bytes = path.stat().st_size if path.is_file() else None
        ok = actual == entry["sha256"] and actual_bytes == entry["bytes"]
        record = dict(path=relative(path), expected_sha256=entry["sha256"],
                      actual_sha256=actual, expected_bytes=entry["bytes"],
                      actual_bytes=actual_bytes, matches_manifest=ok)
        checked.append(record)
        copies.append(record)
        if ok:
            known_hashes.setdefault(actual, []).append(relative(path))
    manifests.append(dict(path=relative(manifest), entries=len(checked),
                          intact=sum(c["matches_manifest"] for c in checked)))

visualizations = []
for path in sorted(args.visualizations.glob("*.html")):
    digest = sha(path)
    record = dict(name=path.name, bytes=path.stat().st_size, sha256=digest,
                  historical_copies=known_hashes.get(digest, []))
    if not record["historical_copies"] and args.recover_missing:
        destination = audit_dir / "fontes-recuperadas" / path.name
        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.exists() and sha(destination) != digest:
            raise ValueError("Recovery would overwrite a different file")
        if not destination.exists():
            shutil.copy2(path, destination)
        record["recovered_copy"] = relative(destination)
        record["recovered_sha256_matches"] = sha(destination) == digest
    visualizations.append(record)

doc_names = ["ARQUITETURA_FRONTEND.md", "MEMORIA_E_PESQUISAS_FRONTEND.md",
             "PLANO_ARQUITETURA_DE_DESIGN.md", "BASE_VISUAL_FRONTEND.md",
             "TOKENS_VISUAIS_PROPOSTOS.json", "CATALOGO_COMPONENTES_FRONTEND.md",
             "PADROES_DE_MOVIMENTO_FRONTEND.md", "HIERARQUIA_E_TIPOGRAFIA_FRONTEND.md",
             "COMPOSICAO_DAS_PAGINAS_FRONTEND.md",
             "DESIGN_INTELIGENTE_E_ORIENTACAO_AO_USUARIO.md",
             "REGRAS_DE_INFORMACAO_UTIL_FRONTEND.md"]
documents = []
for name in doc_names:
    path = repo / "docs" / name
    text = path.read_text(encoding="utf-8-sig")
    state = subprocess.run(["git", "status", "--porcelain", "--", relative(path)],
                           cwd=repo, text=True, capture_output=True, check=True).stdout
    documents.append(dict(path=relative(path), bytes=path.stat().st_size,
                          sha256_at_audit=sha(path), git_status=state[:2],
                          unique_external_links=len(set(re.findall(r'https?://[^\s)>"]+', text)))))

memory = (repo / "docs/MEMORIA_E_PESQUISAS_FRONTEND.md").read_text(encoding="utf-8-sig")
decision_ids = re.findall(r"^\| (FE-\d{3}) \|", memory, re.M)
prior_ids = [f"FE-{i:03d}" for i in range(1, 45)]
old_source = archive / "mapa-navegavel-zm.html"
new_source = archive / "rodada-negocio-em-foco-2026-10-16/negocio-em-foco-zm.html"
report = dict(date="2026-10-16", generated_at_utc=datetime.now(timezone.utc).isoformat(),
    scope="Local archive, available HTML revisions, recorded decisions and declared sidebar styles. No app or preview changes.",
    historical_manifest_count=len(manifests), historical_copy_count=len(copies),
    intact_historical_copies=sum(c["matches_manifest"] for c in copies),
    historical_manifests=manifests, historical_files=copies,
    available_html_count=len(visualizations), html_inventory=visualizations,
    prior_decisions={"expected":prior_ids, "missing":[d for d in prior_ids if d not in decision_ids],
                     "duplicates":[d for d in prior_ids if decision_ids.count(d)>1]},
    documents=documents,
    sidebar={"original_source":relative(old_source), "recent_source":relative(new_source),
             "original_declared_width_px":140, "recent_declared_width_px":174,
             "original_button_radius_px":12, "recent_nav_button_radius_px":20,
             "recent_extra_brand":True,
             "finding":"Visual structure changed without alignment; historical archive does not ensure design continuity."},
    limits=["Hashes establish integrity against existing local manifests, not a complete history of every edit or transient UI state.",
            "Existing design/interaction tests did not compare sidebar appearance and destination coverage against the accepted reference.",
            "External source URLs were inventoried, not fetched or revalidated during this audit.",
            "Local files marked ?? are not committed in Git; no remote backup is certified."])
output = audit_dir / "resultado-auditoria.json"
output.write_text(json.dumps(report, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
print(json.dumps(dict(manifests=len(manifests), historical_copies=len(copies),
    intact=report["intact_historical_copies"], available_html=len(visualizations),
    recovered=[v["name"] for v in visualizations if v.get("recovered_copy")],
    missing_prior_decisions=report["prior_decisions"]["missing"],
    document_count=len(documents), untracked_documents=sum(d["git_status"]=="??" for d in documents),
    report=relative(output)), ensure_ascii=False))
if any(not c["matches_manifest"] for c in copies):
    raise SystemExit(1)
