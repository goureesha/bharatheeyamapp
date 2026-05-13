import urllib.request
import json
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

url = 'https://api.github.com/repos/goureesha/bharatheeyamapp-v2/actions/runs?per_page=1'
req = urllib.request.Request(url)
try:
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())
        run_id = data['workflow_runs'][0]['id']
        print('Run ID: ' + str(run_id))
        jobs_url = data['workflow_runs'][0]['jobs_url']
        with urllib.request.urlopen(jobs_url) as j_res:
            j_data = json.loads(j_res.read().decode())
            for job in j_data['jobs']:
                if job['conclusion'] == 'failure':
                    print('Job failed: ' + str(job['name']))
                    log_url = 'https://api.github.com/repos/goureesha/bharatheeyamapp-v2/actions/jobs/' + str(job['id']) + '/logs'
                    print(log_url)
                    try:
                        with urllib.request.urlopen(log_url) as log_res:
                            log_text = log_res.read().decode('utf-8')
                            lines = log_text.split('\n')
                            for line in lines:
                                if 'error' in line.lower() or 'failed' in line.lower():
                                    print(line.strip())
                    except Exception as e2:
                        print('Log fetch failed', e2)
except Exception as e:
    print('Failed:', e)
