#!/usr/bin/env python3
import os
import sys
from pathlib import Path

import pikepdf

PASSWORDS_FILE = Path("/usr/src/paperless/scripts/passwords.txt")


def read_passwords() -> list[str]:
    if not PASSWORDS_FILE.is_file():
        return []
    lines = (line.strip() for line in PASSWORDS_FILE.read_text().splitlines())
    return [line for line in lines if line]


def main():
    path = Path(os.environ.get("DOCUMENT_WORKING_PATH", ""))
    if path.suffix.lower() != ".pdf" or not path.is_file():
        return

    for password in ["", *read_passwords()]:
        try:
            with pikepdf.open(path, password=password, allow_overwriting_input=True) as pdf:
                if pdf.is_encrypted:
                    pdf.save(path)
                    print(f"{path} was decrypted")
            return
        except pikepdf.PasswordError:
            continue
        except pikepdf.PdfError as error:
            # A damaged PDF must not block the import, so paperless gets to report it instead.
            print(f"Password removal skipped: {error}", file=sys.stderr)
            return
    print(f"None of the configured passwords unlock {path}")


main()
