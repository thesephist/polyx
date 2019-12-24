# Polyx

Productivity suite written from scratch in [Ink](https://github.com/thesephist/ink) on the backend and [Torus](https://github.com/thesephist/torus) on the web.

Polyx is a project currently in progress, and aims to replace all of my day-to-day productivity software with home-grown tools I can deploy anywhere that gives me 100% control over data and deployment. I can probably cover 80% of my use cases and value with existing solutions (I'm moving to Polyx from Dropbox, Simplenote, Todoist, and Pocket), but I like building my own solutions, and these tools are designed to fit my personal workflows perfectly, so I don't have to change how I work to fit my tools.

## Applications

The Polyx suite of software currently contains six applications.

- Noct: distributed file syncing
- Ligature: notes
- Sigil: task manager
- Nought: people manager
- Ria: read-it-later service
- Fortress: service supervisor

### Noct

Noct is in many ways my Dropbox replacement and manages a set of unified filesystems across my devices. I depend on Noct to:

- Keep a directory of all of my files synchronized across machines
- Perform both manual and automated (scripted) backups and verify integrity of past backups
- Copy files across machines and networks when deploying Polyx services

Noct is designed as a client-server system, with a shared isomorphic library of filesystem abstractions between them. Noct traverses a directory recursively on a client and server to construct a "sync plan" of file uploads and downloads that will synchronize the directory on the server and client, and implements the plan. File changes are detected using SHA1 hashes as of late 2019, but given its decreasing cryptographic viability in the wild, I might switch over to SHA256.

To start a server, usually a remote or headless machine, run

```sh
noct serve <target dir>
```

With the client CLI, to query for a sync plan, run
```sh
noct plan --remote <remote addr> <sync subdir>
```
and to execute the plan, run
```sh
noct sync --remote <remote addr> <sync subdir>
```

Currently, syncing anything other than CWD as a client is not supported, but this will probably change in the future. Noct also does not sync permission bits and other filesystem-specific file metadata.

### Ligature

Ligature is where I take, keep, and archive all of my notes.

### Sigil

Sigil is a task manager and to-do list specifically designed for my workflow.

### Nought

Nought is a personal people-manager, what some people might call a contact list or CRM.

### Ria

Ria is a read-it-later service for articles on the web.

### Fortress

Fortress is a process manager / supervisor that manages deployment and monitoring of all Polyx services.

## Deploy

Polyx applications are deployed with Fortress.
