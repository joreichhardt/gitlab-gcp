# gitlab-gcp

GitLab CE auf GCP Compute Engine — persönliche Instanz unter `https://gitlab.hannesalbeiro.com`.

## Architektur

```
Packer → golden image (gitlab-base)
           ↓
Terraform → VM (e2-medium) + static IP + DNS + 50GB Datendisk
           ↓
Startup script → Docker Compose (GitLab CE + GitLab Runner)
```

- **Boot disk:** 10 GB (OS + Docker-Binaries)
- **Datendisk:** 50 GB `pd-standard`, gemountet unter `/srv/gitlab` — enthält alle GitLab-Daten, Docker-Layer und Runner-Konfiguration
- **SSL:** Let's Encrypt, verwaltet von GitLab intern
- **SSH:** Port 2222 (Host-SSH bleibt auf 22)

## Voraussetzungen

- `gcloud` eingeloggt mit Zugriff auf `project-84ddd43d-e408-4cb9-8cb`
- Packer, Terraform, Ansible installiert

## Packer — Image bauen

```bash
cd packer
packer init .
packer build gitlab-base.pkr.hcl
```

Erzeugt Image `gitlab-base-<timestamp>` in der Familie `gitlab-base` und schreibt den Namen automatisch in `terraform/terraform.tfvars`.

## Terraform — Infrastruktur deployen

```bash
cd terraform
terraform init
terraform apply
```

Nach dem Apply ~5 Minuten warten, dann:

```bash
# Root-Passwort auslesen
gcloud compute ssh gitlab -- docker exec gitlab cat /etc/gitlab/initial_root_password
```

Login unter `https://gitlab.hannesalbeiro.com`, Passwort sofort ändern.

## GitLab Runner registrieren

```bash
gcloud compute ssh gitlab -- docker exec -it gitlab-runner gitlab-runner register
```

- URL: `https://gitlab.hannesalbeiro.com`
- Token: GitLab UI → Settings → CI/CD → Runners

## Variablen

| Variable | Default | Beschreibung |
|---|---|---|
| `project_id` | `project-84ddd43d-...` | GCP-Projekt |
| `region` / `zone` | `europe-west3` / `-c` | Region und Zone |
| `domain_name` | `hannesalbeiro.com` | Root-Domain |
| `gitlab_base_image` | `` (leer) | Konkretes Image; leer = neuestes aus Familie |
| `enable_snapshots` | `false` | Tägliche Disk-Snapshots (7 Tage Retention) |

## Snapshots aktivieren

```hcl
# terraform/terraform.tfvars
enable_snapshots = true
```

## Terraform State

GCS-Bucket: `project-84ddd43d-e408-4cb9-8cb-k3s-tf-state`, Prefix: `terraform/state/gitlab`
