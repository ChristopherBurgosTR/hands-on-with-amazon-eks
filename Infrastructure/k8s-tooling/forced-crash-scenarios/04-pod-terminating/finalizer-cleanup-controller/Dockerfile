# Finalizer cleanup controller: Python + kubectl so the controller can list (Python client) and patch (kubectl merge-patch).
FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && curl -sSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x /usr/local/bin/kubectl \
    && apt-get purge -y curl \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY controller.py .

# Uses in-cluster config when run in Kubernetes; set KUBECONFIG when run outside.
ENTRYPOINT ["python", "-u", "controller.py"]
