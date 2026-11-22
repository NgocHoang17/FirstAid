"""Create a PostgreSQL custom dump and verify restoration in a new scratch DB."""
import json
import os
from datetime import datetime, timezone
from pathlib import Path
import subprocess
import uuid

import psycopg
from psycopg import sql

ROOT = Path(__file__).resolve().parents[1]
LOCAL = ROOT / '.local'


def main():
    config = json.loads((LOCAL/'credentials.json').read_text(encoding='utf-8'))
    bin_dir = ROOT/'.local-tools/postgresql-16.16/pgsql/bin'
    destination = LOCAL/'backups'
    destination.mkdir(exist_ok=True)
    archive = destination/(datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S-') + uuid.uuid4().hex[:8]+'.dump')
    temp = archive.with_suffix('.partial')
    login = dict(host='127.0.0.1', port=config['database_port'], user=config['database_user'],
                 password=config['database_password'])
    env = {**os.environ,'PGHOST':login['host'],'PGPORT':str(login['port']),
           'PGUSER':login['user'],'PGPASSWORD':login['password']}
    subprocess.run([str(bin_dir/'pg_dump.exe'),'-Fc','-f',str(temp),config['database_name']],env=env,check=True)
    temp.replace(archive)
    scratch = 'firstaid_restore_'+uuid.uuid4().hex
    with psycopg.connect(**login, dbname='postgres', autocommit=True) as admin:
        admin.execute(sql.SQL('CREATE DATABASE {}').format(sql.Identifier(scratch)))
        try:
            subprocess.run([str(bin_dir/'pg_restore.exe'),'--exit-on-error','--no-owner','--no-privileges',
                            '-d',scratch,str(archive)],env=env,check=True)
            with psycopg.connect(**login, dbname=scratch) as restored:
                for table in ['articles','sources','media_assets']:
                    count=restored.execute(sql.SQL('SELECT count(*) FROM {}').format(sql.Identifier(table))).fetchone()[0]
                    print(table,count)
        finally:
            admin.execute(sql.SQL('DROP DATABASE {}').format(sql.Identifier(scratch)))
    print('Verified archive:',archive)


if __name__ == '__main__':
    main()
