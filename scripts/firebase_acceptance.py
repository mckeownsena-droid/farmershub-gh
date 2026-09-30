"""Check deployed beta Auth/Firestore using temporary accounts and records.

Never prints credentials. Deletes records and accounts in a finally block.
"""
import json
import secrets
import urllib.error
import urllib.request
from pathlib import Path

root = Path(__file__).resolve().parents[1]
config = json.loads((root / 'android/app/google-services.json').read_text())
client = next(c for c in config['client'] if c['client_info']['android_client_info']['package_name'] == 'com.mycompany.farmershubghmvp')
api_key = client['api_key'][0]['current_key']
project = config['project_info']['project_id']
base = f'https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents'
accounts = []
records = []

def request(url, data=None, token=None, method=None):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    req = urllib.request.Request(url, data=None if data is None else json.dumps(data).encode(), headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=40) as response:
        return json.load(response)

def signup():
    account = request(f'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={api_key}', {
        'email': f'farmershub-beta-check-{secrets.token_hex(8)}@example.com',
        'password': secrets.token_urlsafe(24), 'returnSecureToken': True,
    })
    accounts.append(account)
    return account

try:
    owner = signup()
    other = signup()
    for collection in ('farms', 'crops', 'transactions'):
        doc_id = 'beta_acceptance_' + secrets.token_hex(8)
        url = f'{base}/{collection}/{doc_id}'
        fields = {'user_id': {'stringValue': owner['localId']}, 'name': {'stringValue': 'Temporary beta verification'}}
        if collection == 'transactions':
            fields.update({'type': {'stringValue': 'Expense'}, 'amount': {'doubleValue': 100}})
        request(url, {'fields': fields}, owner['idToken'], 'PATCH')
        records.append((url, owner['idToken']))
        result = request(url, token=owner['idToken'])
        assert result['fields']['user_id']['stringValue'] == owner['localId']
        try:
            request(url, token=other['idToken'])
            raise AssertionError(f'Cross-account read allowed for {collection}')
        except urllib.error.HTTPError as exc:
            if exc.code != 403:
                raise
        print(f'{collection}: owner write/read and cross-account rejection passed')
    print('Deployed Firebase beta acceptance passed.')
finally:
    failures = 0
    for url, token in reversed(records):
        try:
            request(url, token=token, method='DELETE')
        except Exception:
            failures += 1
    for account in accounts:
        try:
            request(f'https://identitytoolkit.googleapis.com/v1/accounts:delete?key={api_key}', {'idToken': account['idToken']})
        except Exception:
            failures += 1
    print(f'Temporary data cleanup: {"passed" if failures == 0 else str(failures) + " failures"}')
