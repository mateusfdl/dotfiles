{ pkgs, ... }:
let
  argocdManifest = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/argoproj/argo-cd/v2.14.11/manifests/install.yaml";
    sha256 = "sha256-n9MxdHbdrTCZVLf5nb9TcSs2EfD8cTOQtff9xotTbi8=";
  };

  argocdNamespace = pkgs.writeText "argocd-namespace.yaml" ''
    apiVersion: v1
    kind: Namespace
    metadata:
      name: argocd
  '';

  argocdServerPatch = ''
    {"spec": {"type": "NodePort", "ports": [{"name": "http", "port": 80, "targetPort": 8080, "nodePort": 30080, "protocol": "TCP"}, {"name": "https", "port": 443, "targetPort": 8080, "nodePort": 30443, "protocol": "TCP"}]}}
  '';

  deployKeyPath = "/etc/argocd/deploy-key";

  argocdApp = pkgs.writeText "argocd-minio-app.yaml" ''
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: minio
      namespace: argocd
      labels:
        app.kubernetes.io/part-of: homelab-argo
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: default
      source:
        repoURL: git@github.com:mateusfdl/homelab-argo.git
        targetRevision: HEAD
        path: services/minio
      destination:
        server: https://kubernetes.default.svc
        namespace: minio
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  '';
in
{
  systemd.services.argocd-install = {
    description = "Install ArgoCD into k3s";
    wantedBy = [ "multi-user.target" ];
    after = [ "k3s.service" ];
    requires = [ "k3s.service" ];
    path = [ pkgs.kubectl pkgs.kubernetes-helm ];
    environment.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "10s";
    };
    script = ''
      for i in $(seq 1 60); do
        if kubectl cluster-info > /dev/null 2>&1; then
          break
        fi
        echo "Waiting for k3s API server... ($i/60)"
        sleep 5
      done

      if ! kubectl cluster-info > /dev/null 2>&1; then
        echo "k3s API server did not become ready in time"
        exit 1
      fi

      kubectl apply -f ${argocdNamespace}
      kubectl apply -n argocd -f ${argocdManifest}
      kubectl patch svc argocd-server -n argocd --type=merge -p '${argocdServerPatch}'

      if [ -f ${deployKeyPath} ]; then
        kubectl create secret generic homelab-argo-repo \
          --namespace=argocd \
          --from-literal=type=git \
          --from-literal=url=git@github.com:mateusfdl/homelab-argo.git \
          --from-file=sshPrivateKey=${deployKeyPath} \
          --dry-run=client -o yaml \
          | kubectl label --local -f - argocd.argoproj.io/secret-type=repository --dry-run=client -o yaml \
          | kubectl apply -f -
      else
        echo "WARNING: Deploy key not found at ${deployKeyPath}, skipping repo registration"
      fi

      kubectl rollout status deployment/argocd-server -n argocd --timeout=120s

      kubectl apply -f ${argocdApp}
    '';
  };

  networking.firewall.allowedTCPPorts = [ 30443 ];

  environment.systemPackages = with pkgs; [ argocd ];
}
