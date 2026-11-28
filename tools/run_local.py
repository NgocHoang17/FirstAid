"""Start the Node.js, PostgreSQL, RAG and Admin stack with reviewed data."""
import argparse
import hashlib
import json
import os
import secrets
import shutil
import socket
import subprocess
import sys
import time
import zipfile
from pathlib import Path
from uuid import uuid4

import httpx
import psycopg
from psycopg import sql

from build_app_data import ROOT, build, OUTPUT

LOCAL = ROOT / '.local'
STATE_FILE = LOCAL / 'services.json'
CONFIG_FILE = LOCAL / 'credentials.json'
PG_VERSION = '16.16-1'
PG_ROOT = ROOT / '.local-tools/postgresql-16.16'
PG_DATA = LOCAL / 'postgres-data'
API = 'http://127.0.0.1:8080/api/v1'
CREATE_FLAGS = subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0


def save(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')


def run(command, *, cwd=ROOT, env=None, log=None):
    if log:
        with log.open('ab') as stream:
            subprocess.run(command, cwd=cwd, env=env, stdout=stream, stderr=stream,
                           check=True, creationflags=CREATE_FLAGS)
    else:
        subprocess.run(command, cwd=cwd, env=env, check=True, creationflags=CREATE_FLAGS)


def start(command, name, *, cwd=ROOT, env=None, state):
    with (LOCAL / f'{name}.log').open('ab') as stream:
        process = subprocess.Popen(command, cwd=cwd, env=env, stdout=stream, stderr=stream,
                                   creationflags=CREATE_FLAGS)
    state[name] = process.pid
    save(STATE_FILE, state)
    return process


def listening(port):
    with socket.socket() as sock:
        return sock.connect_ex(('127.0.0.1', port)) == 0


def stop_owned_process(state, name):
    if name not in state:
        return
    result = subprocess.run(['powershell', '-NoProfile', '-Command',
        f"$p=Get-CimInstance Win32_Process -Filter 'ProcessId = {int(state[name])}'; if ($p) {{ $p.CommandLine }}"],
        capture_output=True, text=True, creationflags=CREATE_FLAGS)
    if not result.stdout.strip():
        return
    if str(ROOT).lower() not in result.stdout.lower():
        raise RuntimeError(f'Cannot identify the existing local {name} process.')
    subprocess.run(['taskkill', '/PID', str(state[name]), '/T', '/F'], check=True,
                   capture_output=True, creationflags=CREATE_FLAGS)


def wait_http(url, *, headers=None, process=None):
    deadline = time.monotonic() + 90
    with httpx.Client(trust_env=False, timeout=3) as client:
        while time.monotonic() < deadline:
            if process is not None and process.poll() is not None:
                raise RuntimeError(f'Service exited during startup. Check logs in {LOCAL}')
            try:
                response = client.get(url, headers=headers)
                if response.status_code == 200:
                    return response
            except httpx.TransportError:
                pass
            time.sleep(.5)
    raise RuntimeError(f'Service did not become ready at {url}. Check logs in {LOCAL}')


def postgres_tools():
    configured = os.environ.get('FIRSTAID_PG_BIN')
    if configured:
        return Path(configured)
    installed = sorted(Path('C:/Program Files/PostgreSQL').glob('*/bin/pg_ctl.exe'), reverse=True)
    if installed:
        return installed[0].parent
    binary = PG_ROOT / 'pgsql/bin'
    if (binary / 'pg_ctl.exe').exists():
        return binary
    PG_ROOT.mkdir(parents=True, exist_ok=True)
    archive = PG_ROOT / 'postgresql.zip'
    url = f'https://get.enterprisedb.com/postgresql/postgresql-{PG_VERSION}-windows-x64-binaries.zip'
    print('Downloading PostgreSQL portable from EDB...', flush=True)
    run(['curl.exe', '--fail', '-L', '--connect-timeout', '20', '--max-time', '240',
         '--retry', '2', '--output', str(archive), url])
    with zipfile.ZipFile(archive) as package:
        for entry in package.infolist():
            if entry.filename.startswith(('pgsql/bin/', 'pgsql/lib/', 'pgsql/share/')):
                if not (PG_ROOT / entry.filename).resolve().is_relative_to(PG_ROOT.resolve()):
                    raise ValueError('Invalid archive path')
                package.extract(entry, PG_ROOT)
    print('PostgreSQL download SHA256', hashlib.sha256(archive.read_bytes()).hexdigest(), flush=True)
    return binary


def configuration():
    LOCAL.mkdir(exist_ok=True)
    if CONFIG_FILE.exists():
        config = json.loads(CONFIG_FILE.read_text(encoding='utf-8'))
        if not config.get('session_secret'):
            config['session_secret'] = secrets.token_urlsafe(48)
            save(CONFIG_FILE, config)
        return config
    config = {'database_user': 'firstaid_local', 'database_password': secrets.token_urlsafe(32),
              'database_name': 'firstaid', 'database_port': 55432,
              'admin_username': 'firstaid_admin', 'admin_password': secrets.token_urlsafe(24),
              'internal_token': secrets.token_urlsafe(32), 'session_secret': secrets.token_urlsafe(48)}
    save(CONFIG_FILE, config)
    return config


def start_postgres(config, binary):
    if not (PG_DATA / 'PG_VERSION').exists():
        password_file = LOCAL / 'postgres-init-password.txt'
        password_file.write_text(config['database_password'], encoding='utf-8')
        try:
            run([str(binary / 'initdb.exe'), '-D', str(PG_DATA), '-U', config['database_user'],
                 '--pwfile', str(password_file), '--auth=scram-sha-256', '--encoding=UTF8', '--locale=C'],
                log=LOCAL / 'postgres-init.log')
        finally:
            password_file.unlink(missing_ok=True)
    status = subprocess.run([str(binary / 'pg_ctl.exe'), '-D', str(PG_DATA), 'status'],
                            capture_output=True, creationflags=CREATE_FLAGS)
    if status.returncode:
        if listening(config['database_port']):
            raise RuntimeError('The local database port is already occupied.')
        run([str(binary / 'pg_ctl.exe'), '-D', str(PG_DATA), '-l', str(LOCAL / 'postgres.log'),
             '-o', f"-h 127.0.0.1 -p {config['database_port']}", '-w', 'start'], log=LOCAL / 'postgres-start.log')
    params = dict(host='127.0.0.1', port=config['database_port'], user=config['database_user'],
                  password=config['database_password'])
    with psycopg.connect(dbname='postgres', autocommit=True, **params) as connection:
        if not connection.execute('SELECT 1 FROM pg_database WHERE datname=%s', (config['database_name'],)).fetchone():
            connection.execute(sql.SQL('CREATE DATABASE {}').format(sql.Identifier(config['database_name'])))
    return psycopg.conninfo.make_conninfo(dbname=config['database_name'], **params)


def stop_services(binary=None):
    state = json.loads(STATE_FILE.read_text(encoding='utf-8')) if STATE_FILE.exists() else {}
    for name in ['admin', 'ai', 'backend']:
        if name in state:
            # Only terminate processes whose executable was started from this
            # repository's local configuration. PIDs alone can be reused.
            result = subprocess.run(['powershell', '-NoProfile', '-Command',
                f"$p = Get-CimInstance Win32_Process -Filter 'ProcessId = {int(state[name])}'; "
                "$p | Select-Object ProcessId,CommandLine | ConvertTo-Json -Compress"],
                capture_output=True, text=True, creationflags=CREATE_FLAGS)
            if result.stdout.strip():
                process = json.loads(result.stdout)
                if str(ROOT).lower() in (process.get('CommandLine') or '').lower():
                    subprocess.run(['taskkill', '/PID', str(state[name]), '/T', '/F'],
                                   capture_output=True, creationflags=CREATE_FLAGS)
    if (PG_DATA / 'PG_VERSION').exists() and binary:
        subprocess.run([str(binary / 'pg_ctl.exe'), '-D', str(PG_DATA), '-m', 'fast', '-w', 'stop'],
                       capture_output=True, creationflags=CREATE_FLAGS)
    STATE_FILE.unlink(missing_ok=True)


def verify(config, seed, *, compare_seed=True, check_ai=True, region='VN-DN'):
    with httpx.Client(base_url=API, trust_env=False, timeout=15) as client:
        snapshot_response = client.get('/offline-snapshot', params={'region_code': region})
        snapshot_response.raise_for_status()
        snapshot = snapshot_response.json()['data']
        for key in ['categories', 'articles', 'sources']:
            if compare_seed and {row['id'] for row in snapshot[key]} != {row['id'] for row in seed[key]}:
                raise ValueError(f'Public {key} do not match shipped data')
            response = client.get('/' + key, params={})
            response.raise_for_status()
            public_ids = {row['id'] for row in response.json()['data']['items']}
            snapshot_ids = {row['id'] for row in snapshot[key]}
            # Public sources can include active documents not yet cited by a published article.
            matches = snapshot_ids.issubset(public_ids) if key == 'sources' else public_ids == snapshot_ids
            if not matches:
                raise ValueError(f'Public {key} list differs from snapshot')
        for key in ['articles', 'sources']:
            if snapshot[key]:
                client.get(f"/{key}/{snapshot[key][0]['id']}").raise_for_status()
        cached = client.get('/offline-snapshot', params={'region_code': region},
                            headers={'If-None-Match': snapshot_response.headers['etag']})
        assert cached.status_code == 304
        csrf = client.get('/admin/auth/csrf').json()['data']
        login = client.post('/admin/auth/login', headers={csrf['header_name']: csrf['token']},
                            json={'username': config['admin_username'], 'password': config['admin_password']})
        login.raise_for_status()
        client.get('/admin/auth/me').raise_for_status()
        assert client.post('/admin/categories', json={}).status_code == 403
        replies = []
        for message, age, expected in ([('Kiến thức sơ cứu bỏng nhiệt nhẹ', None, 'answered'),
                ('Kiến thức CPR trẻ em', 'CHILD', 'answered'),
                ('Kiến thức CPR', None, 'clarification_needed')] if compare_seed and check_ai else []):
            result = client.post('/assistant/query', json={'client_request_id': str(uuid4()),
                'message': message, 'age_group': age, 'context_mode': 'learning'})
            result.raise_for_status()
            reply = result.json()['data']
            if reply['status'] != expected:
                raise ValueError(f"Unexpected chat status {reply['status']}, expected {expected}")
            replies.append({'status': reply['status'], 'citations': len(reply['citations'])})
        csrf = client.get('/admin/auth/csrf').json()['data']
        assert client.post('/admin/auth/logout', headers={csrf['header_name']: csrf['token']}, json={}).status_code == 204
        assert client.get('/admin/auth/me').status_code == 401
    report = {'api': API, 'admin': 'http://127.0.0.1:5173',
              'counts': {key: len(snapshot[key]) for key in ['categories', 'articles', 'sources']},
              'snapshot_304': True, 'admin_login_logout': True, 'csrf_write_protection': True,
              'public_lists_match_snapshot': True, 'chat_checks': replies}
    save(LOCAL / 'verification.json', report)
    print(json.dumps(report, ensure_ascii=False, indent=2))


def main():
    global API
    parser = argparse.ArgumentParser()
    parser.add_argument('--stop', action='store_true')
    parser.add_argument('--portable-database', action='store_true', help='Use an isolated portable PostgreSQL instead of backend/.env')
    parser.add_argument('--skip-ai', action='store_true', help='Start backend and Admin without FastAPI')
    args = parser.parse_args()
    if os.name != 'nt':
        raise SystemExit('This local launcher targets Windows. Use component setup instructions on other systems.')
    config = configuration()
    if args.stop:
        binary = postgres_tools() if (PG_DATA / 'PG_VERSION').exists() else None
        stop_services(binary)
        print('Local services stopped. Database files retained.')
        return
    state = json.loads(STATE_FILE.read_text(encoding='utf-8')) if STATE_FILE.exists() else {}
    node, npm = shutil.which('node'), shutil.which('npm.cmd')
    if not node or not npm:
        raise RuntimeError('Install Node.js and npm as required by backend/package.json and admin/package.json.')
    backend_env = ROOT / 'backend/.env'
    if backend_env.exists() and not args.portable_database:
        result = subprocess.run([node, '-e', "console.log(JSON.stringify(require('node:util').parseEnv(require('node:fs').readFileSync(process.argv[1], 'utf8'))))", str(backend_env)],
                                capture_output=True, text=True, check=True, creationflags=CREATE_FLAGS)
        env = {**json.loads(result.stdout), **os.environ}
        print('Using PostgreSQL configured in backend/.env.', flush=True)
    else:
        print('Starting the isolated local database...', flush=True)
        start_postgres(config, postgres_tools())
        env = {**os.environ, 'DATABASE_URL': f"postgresql://127.0.0.1:{config['database_port']}/{config['database_name']}",
               'DB_USER': config['database_user'], 'DB_PASSWORD': config['database_password']}
    seed = build()
    OUTPUT.write_text(json.dumps(seed, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    for name, fallback in [('SESSION_SECRET', config['session_secret']),
                           ('ADMIN_SEED_USERNAME', config['admin_username']), ('ADMIN_SEED_PASSWORD', config['admin_password']),
                           ('PUBLIC_REGION', 'VN-DN'), ('EMERGENCY_NUMBER', '115'), ('PUBLIC_LOCALE', 'vi-VN'),
                           ('SESSION_COOKIE_SECURE', 'false'), ('ADMIN_ORIGIN', 'http://127.0.0.1:5173'),
                           ('AI_INTERNAL_TOKEN', config['internal_token'])]:
        env[name] = env.get(name) or fallback
    # The launcher owns the local AI endpoint and shares one token with the gateway.
    env['AI_BASE_URL'] = '' if args.skip_ai else 'http://127.0.0.1:8001'
    env['HOST'] = '0.0.0.0'
    config.update(admin_username=env['ADMIN_SEED_USERNAME'], admin_password=env['ADMIN_SEED_PASSWORD'],
                  internal_token=env['AI_INTERNAL_TOKEN'])
    save(CONFIG_FILE, config)
    port = int(env.get('PORT') or env.get('SERVER_PORT') or 8080)
    API = f'http://127.0.0.1:{port}/api/v1'
    gemini_key = env.pop('GEMINI_API_KEY', '').strip()
    admin_env = {key: value for key, value in os.environ.items() if key != 'GEMINI_API_KEY'}
    admin_env.update(API_PROXY_TARGET=f'http://127.0.0.1:{port}', VITE_DEMO='false')
    generation_file = LOCAL / 'generation.json'
    if generation_file.exists() and not args.skip_ai:
        generation = json.loads(generation_file.read_text(encoding='utf-8'))
        if generation.get('mode') not in ('extractive','grounded'):
            raise ValueError('generation.json: mode must be extractive or grounded')
        budget=float(generation.get('generation_timeout_seconds',8))
        gateway=int(generation.get('gateway_timeout_seconds',12))
        if not 1<=budget<=90 or not 5<=gateway<=100 or gateway<budget+2:
            raise ValueError('Generation budget must be below the gateway timeout')
        if generation['mode']=='grounded' and not generation.get('model','').strip():
            raise ValueError('Set the model ID before enabling grounded mode')
        provider=generation.get('provider','ollama' if 'ollama_url' in generation else 'gemini')
        if provider not in ('gemini','ollama'):
            raise ValueError('generation.json: provider must be gemini or ollama')
        key_file=LOCAL/'gemini-key.txt'
        if not gemini_key and key_file.exists():
            gemini_key=key_file.read_text(encoding='utf-8-sig').strip()
        if provider=='gemini' and generation['mode']=='grounded' and not gemini_key:
            raise ValueError('Set GEMINI_API_KEY or paste the key into .local/gemini-key.txt; never commit keys')
        env.update({'AI_GENERATION_MODE':generation['mode'],
                    'AI_GENERATION_PROVIDER':provider,
                    'AI_GEMINI_MODEL':generation.get('model','gemini-3.8-flash'),
                    'AI_OLLAMA_URL':generation.get('ollama_url','http://127.0.0.1:11434'),
                    'AI_OLLAMA_MODEL':generation.get('model',''),
                    'AI_GENERATION_TIMEOUT_SECONDS':str(budget),
                    'AI_REQUEST_TIMEOUT_SECONDS':str(gateway)})
    generation_settings={key:env.get(key,'') for key in ['AI_GENERATION_MODE','AI_GENERATION_PROVIDER','AI_GEMINI_MODEL','AI_OLLAMA_URL','AI_OLLAMA_MODEL','AI_GENERATION_TIMEOUT_SECONDS']}
    # Include key rotation without persisting the credential itself.
    generation_settings['credential_digest']=hashlib.sha256(gemini_key.encode()).hexdigest()
    generation_settings['source']=[path.read_text(encoding='utf-8') for path in sorted((ROOT/'ai/firstaid_rag').glob('*.py'))]
    generation_fingerprint=hashlib.sha256(json.dumps(generation_settings,sort_keys=True).encode()).hexdigest()
    if listening(port) and 'backend' not in state:
        raise RuntimeError(f'Port {port} belongs to another service. Stop it or configure a separate environment.')
    backend_settings = {key: env.get(key, '') for key in ['DATABASE_URL', 'DB_URL', 'DB_USER', 'DB_PASSWORD', 'SESSION_SECRET',
        'SESSION_COOKIE_SECURE', 'ADMIN_ORIGIN', 'AI_BASE_URL', 'AI_INTERNAL_TOKEN', 'AI_REQUEST_TIMEOUT_SECONDS',
        'PUBLIC_REGION', 'PUBLIC_LOCALE', 'EMERGENCY_NUMBER', 'HOST', 'PORT', 'SERVER_PORT']}
    backend_settings['source'] = [path.read_text(encoding='utf-8') for path in sorted((ROOT / 'backend/src').rglob('*.js'))]
    backend_fingerprint = hashlib.sha256(json.dumps(backend_settings, sort_keys=True).encode()).hexdigest()
    if listening(port) and state.get('backend_fingerprint') != backend_fingerprint:
        stop_owned_process(state, 'backend')
        deadline = time.monotonic() + 10
        while listening(port) and time.monotonic() < deadline:
            time.sleep(.1)
        if listening(port):
            raise RuntimeError('The previous local backend did not stop.')
    if not (ROOT / 'backend/node_modules/express').exists():
        run(['cmd.exe', '/c', 'npm.cmd', 'ci'], cwd=ROOT / 'backend', env=env, log=LOCAL / 'backend-install.log')
    print('Migrating and seeding with the Node.js backend...', flush=True)
    result = subprocess.run([node, str(ROOT / 'backend/scripts/database/seed.js')], cwd=ROOT / 'backend', env=env,
                            capture_output=True, text=True, creationflags=CREATE_FLAGS)
    with (LOCAL / 'backend-seed.log').open('a', encoding='utf-8') as stream:
        stream.write(result.stdout + result.stderr)
    if result.returncode:
        raise RuntimeError('Cannot seed backend. See .local/backend-seed.log; existing data is preserved.')
    imported = json.loads(result.stdout)
    print(json.dumps(imported))
    if not listening(port):
        print('Starting the Node.js API...', flush=True)
        process = start([node, str(ROOT / 'backend/src/server.js')], 'backend', cwd=ROOT / 'backend', env=env, state=state)
        wait_http(API + '/categories', process=process)
    state['backend_fingerprint'] = backend_fingerprint
    save(STATE_FILE, state)
    snapshot = wait_http(API + '/offline-snapshot?region_code=' + env['PUBLIC_REGION']).json()['data']
    save(LOCAL / 'server-snapshot.json', snapshot)
    if not args.skip_ai:
        sys.path.insert(0, str(ROOT / 'ai'))
        from firstaid_rag.corpus import compile_corpus, write_artifact
        corpus_path = LOCAL / 'rag-corpus.json'
        artifact = compile_corpus(snapshot)
        if listening(8001) and 'ai' in state:
            health = wait_http('http://127.0.0.1:8001/health', headers={'X-Internal-Token': config['internal_token']}).json()
            if health['corpus_version'] != artifact['corpus_version'] or state.get('ai_generation_fingerprint') != generation_fingerprint:
                # This process belongs to this local stack and uses the old artifact.
                command = ['powershell', '-NoProfile', '-Command',
                    f"$p=Get-CimInstance Win32_Process -Filter 'ProcessId = {int(state['ai'])}'; "
                    "if ($p) { $p.CommandLine }"]
                result = subprocess.run(command, capture_output=True, text=True, creationflags=CREATE_FLAGS)
                if str(ROOT).lower() not in result.stdout.lower():
                    raise RuntimeError('Cannot identify the existing local AI process.')
                subprocess.run(['taskkill', '/PID', str(state['ai']), '/T', '/F'], check=True,
                               capture_output=True, creationflags=CREATE_FLAGS)
                deadline = time.monotonic() + 5
                while listening(8001) and time.monotonic() < deadline:
                    time.sleep(.1)
        write_artifact(artifact, corpus_path)
        if not listening(8001):
            print('Starting source-grounded chat...', flush=True)
            process = start([sys.executable, '-m', 'uvicorn', 'firstaid_rag.app:create_app', '--factory',
                             '--host', '127.0.0.1', '--port', '8001', '--no-access-log', '--app-dir', str(ROOT / 'ai')],
                            'ai', cwd=ROOT / 'ai', env={**env, 'GEMINI_API_KEY': gemini_key, 'AI_INDEX_PATH': str(corpus_path),
                             'AI_PUBLIC_SNAPSHOT_URL': API + '/offline-snapshot?region_code=' + env['PUBLIC_REGION']}, state=state)
            wait_http('http://127.0.0.1:8001/health', headers={'X-Internal-Token': config['internal_token']}, process=process)
        elif 'ai' not in state:
            raise RuntimeError('Port 8001 belongs to another service.')
        state['ai_generation_fingerprint']=generation_fingerprint
        save(STATE_FILE,state)
    if not listening(5173):
        if not (ROOT / 'admin/node_modules/vite/bin/vite.js').exists():
            run(['cmd.exe', '/c', 'npm.cmd', 'ci'], cwd=ROOT / 'admin', env=admin_env, log=LOCAL / 'admin-install.log')
        node = shutil.which('node')
        process = start([node, str(ROOT / 'admin/node_modules/vite/bin/vite.js'), '--host', '127.0.0.1'],
                        'admin', cwd=ROOT / 'admin', env=admin_env, state=state)
        wait_http('http://127.0.0.1:5173', process=process)
    elif 'admin' not in state:
        raise RuntimeError('Port 5173 belongs to another service.')
    verify(config, seed, compare_seed=imported['status'] != 'preserved_existing_data', check_ai=not args.skip_ai, region=env['PUBLIC_REGION'])
    print('Admin login credentials are stored locally in .local/credentials.json')
    print('Run Flutter from mobile/: flutter run')


if __name__ == '__main__':
    main()
