# Hands-on with Amazon EKS!

In this repository you will find all the assets required for the course `Hands On With Amazon EKS`, by A Cloud Guru, a Pluralsight Company.

## Prerequisites (AWS CloudShell and similar)

The chapter scripts need **helm** and **eksctl**. These are not installed by default in AWS CloudShell. From the repo root, run once:

```bash
./scripts-by-chapter/install-prerequisites.sh
export PATH="$HOME/bin:$PATH"
```

Then run the chapter scripts as usual (e.g. `./scripts-by-chapter/chapter-2.sh`). If you see `helm: command not found` or `eksctl: command not found`, run the installer and ensure `$HOME/bin` is in your `PATH`. If you get **Permission denied** when running the installer, run: `chmod +x scripts-by-chapter/install-prerequisites.sh` first.

## Bookstore application

This solution has been built for for explaining all the concepts in this course. It is complete enough for covering a real case of microservices running on EKS and integrating with other AWS Services.

> You can find in [here](_docs/api.md) the documentation of the APIs.
