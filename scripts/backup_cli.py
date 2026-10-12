#!/usr/bin/env python3
"""
CLI Utilitário para Gestão e Automação de Backups Quentes do SQLite
ZM Cesta Básica — Fase 9: Auditoria, Robustez, Backup e Instalação

Uso:
    python backup_cli.py create [--tag TAG] [--dest DEST]
    python backup_cli.py list
    python backup_cli.py restore --file FILE [--target TARGET]
    python backup_cli.py verify [--file FILE]
    python backup_cli.py cleanup [--keep N]
"""

import sys
import os
import argparse
from pathlib import Path

# Configura encoding UTF-8 com line buffering no console do Windows
if sys.platform == "win32":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace", line_buffering=True)
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8", errors="replace", line_buffering=True)

# Adiciona o diretorio backend ao PYTHONPATH
BACKEND_DIR = Path(__file__).resolve().parent.parent / "backend"
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

try:
    from app.core.config import settings
    from app.core.backup import (
        create_backup,
        restore_backup,
        list_backups,
        check_sqlite_integrity,
        BackupError,
    )
except ImportError as e:
    print(f"Erro ao importar módulos do backend: {e}")
    sys.exit(1)


def resolve_backup_path(file_str: str) -> Path:
    """
    Resolve o caminho do arquivo de backup aceitando:
    1. Caminho relativo ou absoluto que já existe no sistema de arquivos
    2. Nome de arquivo localizado no diretório padrão de backups (settings.BACKUP_DIR)
    3. Caminho padrão fallback
    """
    p = Path(file_str)
    if p.exists():
        return p.resolve()
    in_backup_dir = settings.BACKUP_DIR / file_str
    if in_backup_dir.exists():
        return in_backup_dir.resolve()
    if not p.is_absolute():
        return (settings.BACKUP_DIR / p).resolve()
    return p.resolve()


def cmd_create(args):
    print(f"[*] Iniciando backup quente atômico (Tag: {args.tag})...")
    dest_path = Path(args.dest) if args.dest else None
    try:
        res = create_backup(destination_path=dest_path, tag=args.tag)
        print("[+] Backup concluído com sucesso!")
        print(f"    Arquivo:   {res['backup_filename']}")
        print(f"    Caminho:   {res['backup_path']}")
        print(f"    Tamanho:   {res['size_bytes']:,} bytes")
        print(f"    Data UTC:  {res['created_at']}")
        print(f"    Integridade SQLite: {'OK' if res['integrity_ok'] else 'FALHA'}")
        return 0
    except Exception as e:
        print(f"[-] Erro ao criar backup: {e}", file=sys.stderr)
        return 1


def cmd_list(args):
    print("[*] Listando backups disponíveis no servidor:")
    try:
        backups = list_backups()
        if not backups:
            print("    Nenhum backup encontrado no diretório padrão.")
            return 0

        print(f"{'Arquivo':<45} | {'Tamanho':<12} | {'Data Modificação':<25}")
        print("-" * 88)
        for b in backups:
            size_str = f"{b['size_bytes']:,} B"
            print(f"{b['filename']:<45} | {size_str:<12} | {b['modified_at']:<25}")
        print("-" * 88)
        print(f"Total: {len(backups)} arquivo(s) de backup.")
        return 0
    except Exception as e:
        print(f"[-] Erro ao listar backups: {e}", file=sys.stderr)
        return 1


def cmd_restore(args):
    backup_file = resolve_backup_path(args.file)
    target_file = Path(args.target).resolve() if args.target else None

    print(f"[*] ATENÇÃO: Restaurando base de dados a partir de: {backup_file}")
    if target_file:
        print(f"    Destino customizado: {target_file}")
    else:
        print(f"    Destino oficial:     {settings.DATABASE_PATH}")

    try:
        res = restore_backup(backup_path=backup_file, target_path=target_file)
        print("[+] Restauração concluída com sucesso e integridade 100% verificada!")
        print(f"    Origem:    {res['restored_from']}")
        print(f"    Destino:   {res['target_path']}")
        print(f"    Timestamp: {res['restored_at']}")
        return 0
    except Exception as e:
        print(f"[-] Erro crítico na restauração: {e}", file=sys.stderr)
        return 1


def cmd_verify(args):
    target = resolve_backup_path(args.file) if args.file else settings.DATABASE_PATH
    print(f"[*] Verificando integridade SQLite de: {target}")
    if not target.exists():
        print(f"[-] Arquivo não encontrado: {target}", file=sys.stderr)
        return 1

    ok = check_sqlite_integrity(target)
    if ok:
        print(f"[+] Integridade OK: {target.name} passou no PRAGMA integrity_check.")
        return 0
    else:
        print(f"[-] CORRUPÇÃO DETECTADA: {target.name} falhou na integridade SQLite!", file=sys.stderr)
        return 1


def cmd_cleanup(args):
    keep = args.keep
    print(f"[*] Executando limpeza de backups antigos (mantendo os {keep} mais recentes)...")
    backups = list_backups()
    if len(backups) <= keep:
        print(f"[+] Nenhum backup para remover. Total atual: {len(backups)} (limite: {keep}).")
        return 0

    to_remove = backups[keep:]
    removed_count = 0
    for b in to_remove:
        p = Path(b["path"])
        try:
            p.unlink()
            removed_count += 1
            print(f"    [-] Removido: {b['filename']}")
        except Exception as e:
            print(f"    [!] Erro ao remover {b['filename']}: {e}")

    print(f"[+] Limpeza concluída: {removed_count} backup(s) antigo(s) removido(s).")
    return 0


def main():
    parser = argparse.ArgumentParser(description="Utilitário de Linha de Comando para Backup do ZM Cesta Básica")
    subparsers = parser.add_subparsers(dest="command", help="Comando a executar")

    # create
    p_create = subparsers.add_parser("create", help="Cria um backup quente atômico")
    p_create.add_argument("--tag", default="manual", help="Tag identificadora no nome do arquivo (ex: diario, manual)")
    p_create.add_argument("--dest", default=None, help="Caminho de destino customizado para o arquivo .db")

    # list
    subparsers.add_parser("list", help="Lista todos os backups existentes")

    # restore
    p_restore = subparsers.add_parser("restore", help="Restaura a base a partir de um arquivo de backup")
    p_restore.add_argument("--file", required=True, help="Nome ou caminho do arquivo .db de backup")
    p_restore.add_argument("--target", default=None, help="Caminho do arquivo de destino (opcional)")

    # verify
    p_verify = subparsers.add_parser("verify", help="Executa PRAGMA integrity_check na base")
    p_verify.add_argument("--file", default=None, help="Arquivo a verificar (padrão: banco de produção)")

    # cleanup
    p_cleanup = subparsers.add_parser("cleanup", help="Remove backups antigos mantendo N mais recentes")
    p_cleanup.add_argument("--keep", type=int, default=30, help="Quantidade de backups mais recentes a manter")

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    cmds = {
        "create": cmd_create,
        "list": cmd_list,
        "restore": cmd_restore,
        "verify": cmd_verify,
        "cleanup": cmd_cleanup,
    }
    sys.exit(cmds[args.command](args))


if __name__ == "__main__":
    main()
