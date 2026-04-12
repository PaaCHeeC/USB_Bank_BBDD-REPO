from configparser import ConfigParser
from pathlib import Path


def config(filename="src/database.ini", section="postgresql"):
    parser = ConfigParser()

    base_dir = Path(__file__).resolve().parent
    candidates = [
        Path(filename),
        base_dir / filename,
        base_dir / Path(filename).name,
        base_dir.parent / filename,
    ]

    selected = None
    for candidate in candidates:
        if candidate.exists():
            selected = candidate
            break

    if selected is None:
        raise Exception(f"No se encontró el archivo de configuración: {filename}")

    parser.read(selected)
    db = {}

    if parser.has_section(section):
        params = parser.items(section)
        for param in params:
            db[param[0]] = param[1]
    else:
        raise Exception(
            "Section {0} is not found in the {1} file.".format(section, selected)
        )

    return db
