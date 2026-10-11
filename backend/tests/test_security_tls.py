from pathlib import Path
from cryptography import x509
from app.core.security import (
    generate_self_signed_cert,
    get_cert_fingerprint,
    hash_token,
    generate_device_token,
    generate_pin_code,
    constant_time_compare,
)

def test_generate_self_signed_cert(tmp_path: Path):
    cert_path = tmp_path / "test.crt"
    key_path = tmp_path / "test.key"

    fingerprint, cert_pem = generate_self_signed_cert(
        cert_path,
        key_path,
        san_ips=["192.168.1.100"],
        san_dns=["zm-servidor.local"],
    )

    assert cert_path.exists()
    assert key_path.exists()
    assert len(fingerprint.split(":")) == 32

    # Verify cert properties with cryptography
    cert = x509.load_pem_x509_certificate(cert_pem.encode("utf-8"))
    assert cert.subject.get_attributes_for_oid(x509.NameOID.ORGANIZATION_NAME)[0].value == "ZM Cesta Basica"

    # Verify fingerprint calculation consistency
    computed_fp = get_cert_fingerprint(cert_path)
    assert computed_fp == fingerprint

def test_token_hashing_and_verification():
    token1 = generate_device_token()
    token2 = generate_device_token()
    assert token1 != token2

    hash1 = hash_token(token1)
    hash2 = hash_token(token2)
    assert hash1 != hash2
    assert len(hash1) == 64 # SHA-256 hex digest length
    assert hash_token(token1) == hash1

def test_pin_generation():
    pin = generate_pin_code(6)
    assert len(pin) == 6
    assert pin.isdigit()

def test_constant_time_compare():
    assert constant_time_compare("secret_token_123", "secret_token_123") is True
    assert constant_time_compare("secret_token_123", "wrong_token_456") is False
