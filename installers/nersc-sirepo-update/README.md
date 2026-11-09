# How Sirepo runs agents at NERSC

There is no standing NERSC program that spawns per-user agents. The supervisor
starts each agent itself, over SSH, as the NERSC user. Nothing needs to be
running at NERSC beforehand, apart from the installed code and image from
`installers/nersc-sirepo-update`.

## Where things live

- The agent lives at NERSC. The supervisor only starts it over SSH. It runs
  as a process on a NERSC login node, as the NERSC user, in that user's
  `srdb_root`. `job_agent.pid` and `job_agent.log` are there too.
- The supervisor holds the `SbatchDriver` object, the user's credentials
  briefly, and the websocket connection from the agent. It does not run the
  agent's code.
- Compute jobs the agent submits run on NERSC compute nodes through Slurm. The
  agent stays on the login node.

## 1. Sirepo prod, supervisor side

- The supervisor (`sirepo job_supervisor`) is the only long-lived piece that
  is deployed. It holds one `SbatchDriver` per Sirepo user
  (`sirepo/job_driver/sbatch.py`).

## 2. The user supplies NERSC credentials

- When a sim needs the `sbatch` resource, the user gets the `sbatchLogin`
  modal. It collects their NERSC username and password plus OTP. These arrive
  on the op as `sbatchCredentials`.
- The driver keeps them in `_creds` and computes `_srdb_root` from the
  username.

## 3. The supervisor starts an agent on demand (`_do_agent_start`)

- It opens an SSH connection to the NERSC login host (`cfg.host`) with those
  credentials, so the session is that unix user.
- It runs a small script that does `cd <srdb_root>` and then
  `setsid $sirepo_cmd job_agent start_sbatch &`, with output appended to
  `job_agent.log`. This is the first moment any process exists at NERSC.
- `_creds` is deleted in a `finally` block right after the SSH session. The
  password is only used to start the agent.

### The command

Over SSH the supervisor runs `/bin/bash --noprofile --norc -l` (asyncssh
`create_process`) and sends this script on its stdin
(`sbatch.py`, `_do_agent_start`):

```bash
#!/bin/bash
set -euo pipefail
{_agent_start_dev()}
mkdir -p '<srdb_root>'
cd '<srdb_root>'
{self._agent_env(op)}
(/usr/bin/env; setsid <sirepo_cmd> job_agent start_sbatch) &>> job_agent.log &
disown
```

- `_agent_start_dev()`: in dev mode with a `shifter_image`, `git pull` of
  `pykern` and `sirepo` under the dev source dir. Empty in prod.
- `_agent_env(op)`: environment variable exports. `sbatch.py` overrides
  `SIREPO_SRDB_ROOT`, `SIREPO_FEATURE_CONFIG_SIM_TYPES` and a few other
  feature-config settings. The parent class adds the rest, including how the
  agent finds the supervisor.
- Last line: `/usr/bin/env` dumps the environment into the log, then
  `setsid <sirepo_cmd> job_agent start_sbatch` runs detached from the SSH
  session. `disown` keeps the shell exit from killing it.
- `<sirepo_cmd>` is the `sbatch.sirepo_cmd` config value, for example
  `/global/common/software/m1253/nagler/sirepo/.pyenv/versions/sirepo-prod/bin/sirepo`.

Before sending the script, and again a few seconds after the start, the
supervisor runs `test -e job_agent.log && tail --lines=200 job_agent.log` on
a separate SSH channel and saves the output in its own log.

## 4. The agent connects outbound to the supervisor

- `start_sbatch()` (`sirepo/pkcli/job_agent.py`) writes `job_agent.pid`
  (`host` and `pid`). If an old `job_agent.pid` exists, it first kills that
  stale agent, using `ssh <host> kill -KILL <pid>` if it was on another login
  node.
- It then calls `start()`, and `_Dispatcher` opens a websocket to the
  supervisor and stays connected. The connection goes from NERSC to the
  supervisor, so the supervisor needs no inbound path to NERSC after the SSH
  start.
- Sbatch agents are kept alive as long as possible (`_start_idle_timeout` is
  a no-op).

### Where the agent finds the supervisor

The supervisor tells the agent where it is, through environment variables in
the SSH start script. The agent has no other way to find it.

- `DriverBase._agent_env` (`sirepo/job_driver/__init__.py`) sets
  `SIREPO_PKCLI_JOB_AGENT_SUPERVISOR_URI` from the driver's
  `cfg.supervisor_uri`. It replaces the first `http` with `ws` (so `https`
  becomes `wss`) and appends `job.AGENT_URI` (`/job-agent-websocket`).
- `start()` in `sirepo/pkcli/job_agent.py` reads it as the required
  `supervisor_uri`, and `_Dispatcher.loop` calls
  `tornado.websocket.websocket_connect` on it.
- The default `supervisor_uri` is `http://<DEFAULT_IP>:<supervisor port>`,
  which only works in local dev. For NERSC it must be overridden with a URL
  that NERSC login nodes can reach. Check the rsconf for the actual value.
- Other values passed the same way, all built from `cfg.supervisor_uri`:
  - `SIREPO_PKCLI_JOB_AGENT_SIM_DB_FILE_SERVER_URI` and `..._TOKEN`
  - `SIREPO_PKCLI_JOB_AGENT_GLOBAL_RESOURCES_SERVER_URI` and `..._TOKEN`
  - `SIREPO_PKCLI_JOB_AGENT_AGENT_ID`, which identifies this agent

The NERSC login node must therefore be able to open outbound connections to
the supervisor's URL.

## 5. Ops flow over that websocket

- The supervisor sends the agent ops (run, status, ...). The agent replies on
  the same socket.
- For a compute run, the agent writes an sbatch script and submits it with
  Slurm. The job runs on a compute node under `shifter` with `shifter_image`.
  The agent tracks it with `sacct`.

## Config (rsconf `sbatch`)

| key | meaning |
| --- | --- |
| `host`, `host_key` | NERSC login host to SSH to |
| `sirepo_cmd` | `sirepo` executable run for `job_agent start_sbatch` (login-node agent). Only used in `_do_agent_start`. |
| `shifter_image` | image used for compute jobs on compute nodes |
| `srdb_root` | per-user dir; must contain `{sbatch_user}`, e.g. `/pscratch/sd/{sbatch_user:.1}/{sbatch_user}/sirepo-prod` |

## What `nersc-sirepo-update` does

It installs only the shared code, not an agent or any process:

- the shifter image (`shifterimg pull docker:radiasoft/sirepo-nersc:<channel>`)
- pyenv virtualenv `sirepo-<channel>` under a shared `root_dir`
- `pykern` and `sirepo` pip-installed at the tags matching the image
- `chmod -R a+rX` so all users can run it

So the `sirepo_cmd` path points into that shared install (for example under
`/global/common/software/...`). Each user's agent runs that shared code, but
as that user, in that user's `srdb_root`.

## Version pairing

`sirepo_cmd` determines the `pykern`/`sirepo` version of the login-node agent.
`shifter_image` determines the version used by compute jobs. The installer
pairs venv `sirepo-<channel>` with image `:<channel>`. A mismatch (for example
a `sirepo-prod` venv with a `:alpha` image) can run different versions on the
two sides.
