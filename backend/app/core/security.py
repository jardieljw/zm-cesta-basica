import os
import socket
import hashlib
import secrets
import datetime
from pathlib import Path
from typing import Tuple, List, Optional
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
import ipaddress

def get_local_ip() -> str:
    """Detect the active local LAN IP address."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Does not actually establish connection, but selects outbound network interface
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = "127.0.0.1"
    finally:
        s.close()
    return ip

def generate_self_signed_cert(
    cert_path: Path,
    key_path: Path,
    san_ips: Optional[List[str]] = None,
    san_dns: Optional[List[str]] = None,
    validity_days: int = 3650
) -> Tuple[str, str]:
    """
    Generates a self-signed TLS certificate with SAN for local HTTPS communication.
    Returns (fingerprint_sha256, cert_pem_str).
    """
    cert_path.parent.mkdir(parents=True, exist_ok=True)
    key_path.parent.mkdir(parents=True, exist_ok=True)

    if cert_path.exists() and key_path.exists():
        cert_data = cert_path.read_bytes()
        cert = x509.load_pem_x509_certificate(cert_data)
        fingerprint = cert.fingerprint(hashes.SHA256()).hex().upper()
        formatted_fingerprint = ":".join(fingerprint[i:i+2] for i in range(0, len(fingerprint), 2))
        return formatted_fingerprint, cert_data.decode("utf-8")

    key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
    )

    subject = issuer = x509.Name([
        x509.NameAttribute(NameOID.COUNTRY_NAME, "BR"),
        x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, "SP"),
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, "ZM Cesta Basica"),
        x509.NameAttribute(NameOID.COMMON_NAME, "ZM Cestas Servidor Local"),
    ])

    alt_names: List[x509.GeneralName] = [
        x509.DNSName("localhost"),
        x509.IPAddress(ipaddress.IPv4Address("127.0.0.1")),
    ]

    local_ip = get_local_ip()
    if local_ip != "127.0.0.1":
        alt_names.append(x509.IPAddress(ipaddress.IPv4Address(local_ip)))

    if san_ips:
        for ip in san_ips:
            try:
                alt_names.append(x509.IPAddress(ipaddress.IPv4Address(ip)))
            except Exception:
                pass

    if san_dns:
        for dns in san_dns:
            alt_names.append(x509.DNSName(dns))

    now = datetime.datetime.now(datetime.timezone.utc)
    cert = (
        x509.CertificateBuilder()
        .subject_name(subject)
        .issuer_name(issuer)
        .public_key(key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(now - datetime.timedelta(days=1))
        .not_valid_after(now + datetime.timedelta(days=validity_days))
        .add_extension(
            x509.SubjectAlternativeName(alt_names),
            critical=False,
        )
        .sign(key, hashes.SHA256())
    )

    cert_bytes = cert.public_bytes(serialization.Encoding.PEM)
    key_bytes = key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.TraditionalOpenSSL,
        encryption_algorithm=serialization.NoEncryption(),
    )

    cert_path.write_bytes(cert_bytes)
    key_path.write_bytes(key_bytes)

    fingerprint = cert.fingerprint(hashes.SHA256()).hex().upper()
    formatted_fingerprint = ":".join(fingerprint[i:i+2] for i in range(0, len(fingerprint), 2))
    return formatted_fingerprint, cert_bytes.decode("utf-8")

def get_cert_fingerprint(cert_path: Path) -> str:
    """Reads certificate from disk and computes SHA-256 fingerprint."""
    cert_data = cert_path.read_bytes()
    cert = x509.load_pem_x509_certificate(cert_data)
    fingerprint = cert.fingerprint(hashes.SHA256()).hex().upper()
    return ":".join(fingerprint[i:i+2] for i in range(0, len(fingerprint), 2))

def hash_token(raw_token: str) -> str:
    """Computes SHA-256 hex digest for storage and lookup."""
    return hashlib.sha256(raw_token.encode("utf-8")).hexdigest()

def generate_device_token() -> str:
    """Generates a cryptographically strong individual device bearer token."""
    return secrets.token_urlsafe(32)

def generate_pin_code(length: int = 6) -> str:
    """Generates an ephemeral numeric pairing PIN."""
    return "".join(secrets.choice("0123456789") for _ in range(length))

def constant_time_compare(val1: str, val2: str) -> bool:
    """Timing-attack resistant string comparison."""
    return secrets.compare_digest(val1, val2)
