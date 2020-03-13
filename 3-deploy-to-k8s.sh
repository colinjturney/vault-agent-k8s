#!/bin/bash

# To be run on host

cat <<EOF > vault-agent-config.hcl
# Uncomment this to have Agent run once (e.g. when running as an initContainer)
#exit_after_auth = true
pid_file = "/home/vault/pidfile"

auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes"
        config = {
            role = "example"
        }
    }

    sink "file" {
        config = {
            path = "/home/vault/.vault-token"
        }
    }
}

template {
  destination = "/etc/secrets/index.html"
  contents = <<EOH
  <html>
  <body>
  <p>Some secrets:</p>
  {{- with secret "secret/myapp/config" }}
  <ul>
  <li><pre>username: {{ .Data.username }}</pre></li>
  <li><pre>password: {{ .Data.password }}</pre></li>
  </ul>
  {{ end }}
  </body>
  </html>
  EOH
}

EOF

# Create a ConfigMap, example-vault-agent-config
kubectl create configmap example-vault-agent-config --from-file=vault-agent-config.hcl

# Get this host's IP. Massive hack, using virtualbox forwarded port. Must be better ways of doing this

export VAULT_SERVER_ADDR=http://$(minikube ssh "route -n | grep ^0.0.0.0 | awk '{ print \$2 }'" | sed -e 's/[[:space:]]*$//'):8282

cat <<EOF > pod-spec.yml
---
apiVersion: v1
kind: Pod
metadata:
  name: vault-agent-example
spec:
  serviceAccountName: vault-auth
  restartPolicy: Never

  volumes:
    - name: vault-token
      emptyDir:
        medium: Memory

    - name: config
      configMap:
        name: example-vault-agent-config
        items:
          - key: vault-agent-config.hcl
            path: vault-agent-config.hcl

    - name: shared-data
      emptyDir: {}

  containers:
    # Vault container
    - name: vault-agent-auth
      image: vault

      volumeMounts:
        - name: config
          mountPath: /etc/vault
        - name: vault-token
          mountPath: /home/vault
        - name: shared-data
          mountPath: /etc/secrets

      # Assumes Vault is running on a Vagrant VM with forwarded port on localhost:8282 as configured in VagrantFile.
      env:
        - name: VAULT_ADDR
          value: "${VAULT_SERVER_ADDR}"

      # Run the Vault agent
      args:
        [
          "agent",
          "-config=/etc/vault/vault-agent-config.hcl",
          #"-log-level=debug",
        ]
    - name: nginx-container
      image: nginx

      ports:
        - containerPort: 80

      volumeMounts:
        - name: shared-data
          mountPath: /usr/share/nginx/html
EOF

kubectl apply -f pod-spec.yml
