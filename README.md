# Polyx

Productivity suite written from scratch in [Ink](https://github.com/thesephist/ink) on the backend, and Ink (with [September](https://github.com/thesephist/september)) and [Torus](https://github.com/thesephist/torus) on the web.

Polyx is a project currently in progress, and aims to replace all of my day-to-day productivity software with home-grown tools I can deploy anywhere that gives me 100% control over data and deployment. I can probably cover 80% of my use cases and value with existing solutions (I'm moving to Polyx from Dropbox, Simplenote, Todoist, and Pocket), but I like building my own solutions, and these tools are designed to fit my personal workflows perfectly, so I don't have to change how I work to fit my tools.

I've written at length about my approach to tools and workflows [on my blog](https://thesephist.com/posts/tools/).

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
noct serve <sync root dir>
```

With the client CLI, to query for a sync plan, run
```sh
noct plan --remote <remote addr> <sync root dir>
```
and to execute the plan, run
```sh
noct sync --remote <remote addr> <sync root dir>
```

- The remote is optional, and when not given, will default to `https://noct.thesephist.com`.
- Noct does not sync permission bits and other filesystem-specific file metadata.
- Currently, there is no way to sync a sub-directory of the target root directory, because my workflow never needs it. If this changes in the future, we may introduce a `--part` flag to sync a sub-path in a partial sync.

### Ligature

Ligature is where I take, keep, and archive all of my notes. I use Ligature notes to:

- Keep track of [long-term goals](https://linus.zone/goalpost)
- Take notes while reading and browsing the web
- Keep track of interesting conversations I have
- Jot down ideas for projects, blog posts, and traveling
- Remembering anything that doens't fit into a to-do list or a Google Doc

Ligature is designed to be a minimal, easy-to-use graphical web interface to a directory of Markdown-style text files I use as my notes. I prefer to keep my data storage as simple and portable as possible, and encode more complex data in notation within the notes, to keep the notes portable between different devices, setups, and workflows. Ligature simply reads, updates, and manages the text files for me through the web interface, and is blind to any special notation or structure within those files, except for using the first line of each file as the "title" of the note.

To start the server, run

```sh
ligature serve --db <path to notes folder>
```

The `--db` configuration is optional (defaults to CWD) and points the server to the directory containing plain-text note files. The directory is expected to only contain those files, and nothing else.

Ligature is temporarily running as an systemd service, until Fortress is ready for production.

### Sigil

Sigil is a task manager and to-do list specifically designed for my workflow. I've used basically every popular task manager out there from Things to Wunderlist, Trello, Apple Reminders, and even pen-and-paper. Most recently, I used Todoist, which has fit my workflow best. Since 2015, I've used Todoist as my full-time and only task manager. But even that doesn't exactly cater to the way I want to work. So Sigil is designed for me, and nobody else, to fit my existing workflow. This mean Sigil has some quirks as a consequence of how I organize tasks.

- Tasks have no notion of reminders or due dates (I use neither), but instead have granular priorities.
- There are no notion of "projects" or "categories" of tasks that are separate lists. Tasks may be tagged, but they all exist in one singular list.
- Tasks and comments underneath tasks are plain text or simple markup.
- The flow is optimized for fast entry of ideas into the database, and then efficient triaging and organization after the fact of even very large task queues.

### Nought

Nought is a personal people-manager, what some people might call a contact list or CRM.

### Ria

Ria is a read-it-later service for articles on the web.

Ria stores all of its data in a single text file that functions as a plain text list of all saved links. Each line in the file is formatted:

```
{{ timestamp }} {{ link }} {{ description which may include #tags #like #this }}
```

At the moment, Ria will allow exact substring searches on the description. Other indexing schemes + search methods may reveal themselves later, and we may add them as I start needing them.

### Fortress

Fortress is a process manager / supervisor that manages deployment and monitoring of all Polyx services.

## Deploy

Polyx applications are deployed with Fortress.

The `conf/` directory contains a collection of configuration files and scripts I use to provision and deploy a server that runs the Fortress instance.

- `sshd_config`: SSH server configurations
- `nginx.conf`: Nginx reverse proxy configurations

### Provision

To provision a Fortress server:

1. Start up a clean Linux install with `systemd`. Fortress uses systemd as the init system to run as a daemon.
2. Add a new non-root user with `useradd <user>`
3. Make sure SSH, Nginx, and Ink are installed, and copy over any configuration files from `conf/`.
4. Create a target Noct sync directory with `mkdir ~/noctd` (`~/noctd` is the conventional noct sync directory name, but you can choose something else.)
5. Clone the Polyx source repository into `~/noctd/src`. You can do this by cloning first, then mv-ing the directory. `git clone https://github.com/thesephist/polyx; mv ~/noctd/polyx ~/noctd/src`
6. Install the Fortress systemd service file with `cp ~/noctd/src/fortress/fortress.service /etc/systemd/system/fortress.service`
7. Start up Fortress as a systemd daemon with `sudo systemctl start fortress`. If you want to ensure the service always starts on boot, also run `sudo systemctl enable fortress`.
8. Install and setup `certbot` to get and auto-renew HTTPS certs for all set-up domains.

### Extras

- Make a user a sudoer from root with `usermod -aG sudo <user>`
- Remove the default login banner with `sudo chmod -x /etc/update-motd.d/*`
- Install Go to bootstrap Ink. First, download Google's official tarball, then un-tar it to `/usr/local`. For example, for Go 1.13.5. We need to also ensure that Go's binary is in `$PATH`:
```sh
wget https://dl.google.com/go/go1.13.5.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.13.5.linux-amd64.tar.gz
echo 'PATH=$PATH:/usr/local/go/bin' >> ~/.profile # or equivalent for your shell
```
- If running Ubuntu, setting up a firewall is straightforward with `ufw`:
```sh
# default-safe configuration
sudo ufw default deny incoming
sudo ufw default allow outgoing

# allow services
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
# allow other ports with
# sudo ufw allow <port>

# enable it and check status
sudo ufw enable
sudo ufw status
```
- On Fedora / CentOS, firewall management is done with `firewall-cmd`
```sh
sudo firewall-cmd --add-service=ssh --permanent
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-service=https --permanent
sudo systemctl start firewalld
sudo chkconfig firewalld on
```
