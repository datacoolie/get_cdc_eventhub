Simulation scripts for generating CRUD operations against Postgres and Oracle

Prereqs:
- Python 3.10+
- Docker compose services running from repo (Postgres at localhost:5432, Oracle at localhost:1521/XEPDB1)

Install:

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r sim/requirements.txt
```

Run Postgres simulation (defaults use values from docker-compose):

```bash
python sim/postgres_sim.py --host localhost --port 5432 --user datauser --password DataPassword123 --db cdcdb
```

Run Oracle simulation (defaults use values from docker-compose):

```bash
python sim/oracle_sim.py --host localhost --port 1521 --user datauser --password DataPassword123 --service XEPDB1
```

Options:
- `--rate` operations per second (default 1)
- `--iterations` number of loop iterations (default: infinite until Ctrl+C)
