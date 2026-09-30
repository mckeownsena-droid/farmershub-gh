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
        if collection == 'crops':
            fields['farm_id'] = {'stringValue': 'beta_query_fixture'}
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
        for operation, payload in (
            ('PATCH', {'fields': {'user_id': {'stringValue': other['localId']}}}),
            ('DELETE', None),
        ):
            try:
                request(url, payload, other['idToken'], operation)
                raise AssertionError(f'Cross-account {operation} allowed for {collection}')
            except urllib.error.HTTPError as exc:
                if exc.code != 403:
                    raise
        try:
            request(url, {'fields': {'user_id': {'stringValue': other['localId']}}}, owner['idToken'], 'PATCH')
            raise AssertionError(f'Ownership transfer allowed for {collection}')
        except urllib.error.HTTPError as exc:
            if exc.code != 403:
                raise
        if collection == 'crops':
            query = {'structuredQuery': {'from': [{'collectionId': 'crops'}], 'where': {
                'compositeFilter': {'op': 'AND', 'filters': [
                    {'fieldFilter': {'field': {'fieldPath': 'user_id'}, 'op': 'EQUAL', 'value': {'stringValue': owner['localId']}}},
                    {'fieldFilter': {'field': {'fieldPath': 'farm_id'}, 'op': 'EQUAL', 'value': {'stringValue': 'beta_query_fixture'}}},
                ]}}}}
            rows = request(base + ':runQuery', query, owner['idToken'], 'POST')
            assert any(row.get('document', {}).get('name', '').endswith('/' + doc_id) for row in rows)
            print('Crop owner/farm compound query passed.')
        print(f'{collection}: owner write/read, cross-account read/write/delete rejection and ownership preservation passed')
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
