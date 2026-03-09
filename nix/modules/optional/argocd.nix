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

  deployKeyPath = "/etc/argocd/deploy-key";

  argocdApps =
    map
      (
        app:
        pkgs.writeText "argocd-${app}-app.yaml" ''
          apiVersion: argoproj.io/v1alpha1
          kind: Application
          metadata:
            name: ${app}
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
              path: services/${app}
            destination:
              server: https://kubernetes.default.svc
              namespace: ${app}
            syncPolicy:
              automated:
                prune: true
                selfHeal: true
              syncOptions:
                - CreateNamespace=true
        ''
      )
      [
        "minio"
        "vaultwarden"
        "uptime-kuma"
        "adguard-home"
      ];

  certManagerApp = pkgs.writeText "argocd-cert-manager-app.yaml" ''
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: cert-manager
      namespace: argocd
      labels:
        app.kubernetes.io/part-of: homelab-argo
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: default
      sources:
        - repoURL: https://charts.jetstack.io
          chart: cert-manager
          targetRevision: v1.14.4
          helm:
            valuesObject:
              installCRDs: true
              resources:
                requests:
                  cpu: 10m
                  memory: 32Mi
                limits:
                  cpu: 100m
                  memory: 128Mi
        - repoURL: git@github.com:mateusfdl/homelab-argo.git
          targetRevision: HEAD
          path: services/cert-manager
      destination:
        server: https://kubernetes.default.svc
        namespace: cert-manager
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
          - ServerSideApply=true
  '';

  argocdIngress = pkgs.writeText "argocd-ingress.yaml" ''
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: argocd-server
      namespace: argocd
      annotations:
        cert-manager.io/cluster-issuer: letsencrypt-prod
        traefik.ingress.kubernetes.io/router.entrypoints: websecure
    spec:
      ingressClassName: traefik
      tls:
        - hosts:
            - argocd.matheusfdl.dev
          secretName: argocd-server-tls
      rules:
        - host: argocd.matheusfdl.dev
          http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: argocd-server
                    port:
                      number: 80
  '';

  giteaApp = pkgs.writeText "argocd-gitea-app.yaml" ''
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: gitea
      namespace: argocd
      labels:
        app.kubernetes.io/part-of: homelab-argo
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: default
      sources:
        - repoURL: https://dl.gitea.com/charts/
          chart: gitea
          targetRevision: 12.5.0
          helm:
            valueFiles:
              - $values/services/gitea/values.yaml
        - repoURL: git@github.com:mateusfdl/homelab-argo.git
          targetRevision: HEAD
          ref: values
      destination:
        server: https://kubernetes.default.svc
        namespace: gitea
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  '';

  redisApp = pkgs.writeText "argocd-redis-app.yaml" ''
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: redis
      namespace: argocd
      labels:
        app.kubernetes.io/part-of: homelab-argo
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: default
      sources:
        - repoURL: https://charts.bitnami.com/bitnami
          chart: redis
          targetRevision: 25.3.2
          helm:
            valueFiles:
              - $values/services/redis/values.yaml
        - repoURL: git@github.com:mateusfdl/homelab-argo.git
          targetRevision: HEAD
          ref: values
        - repoURL: git@github.com:mateusfdl/homelab-argo.git
          targetRevision: HEAD
          path: services/redis
      destination:
        server: https://kubernetes.default.svc
        namespace: redis
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  '';

  traefikApp = pkgs.writeText "argocd-traefik-app.yaml" ''
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: traefik
      namespace: argocd
      labels:
        app.kubernetes.io/part-of: homelab-argo
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: default
      sources:
        - repoURL: https://traefik.github.io/charts
          chart: traefik
          targetRevision: 26.1.0
          helm:
            valueFiles:
              - $values/services/traefik/values.yaml
        - repoURL: git@github.com:mateusfdl/homelab-argo.git
          targetRevision: HEAD
          ref: values
      destination:
        server: https://kubernetes.default.svc
        namespace: traefik
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
    path = [
      pkgs.kubectl
      pkgs.kubernetes-helm
      pkgs.gnugrep
    ];
    environment.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "10s";
    };
    script = ''
      for i in $(seq 1 60); do
        kubectl cluster-info > /dev/null 2>&1 && break
        sleep 5
      done

      kubectl cluster-info > /dev/null 2>&1 || exit 1

      kubectl apply -f ${argocdNamespace}
      kubectl apply -n argocd -f ${argocdManifest}

      kubectl rollout status deployment/argocd-server -n argocd --timeout=120s

      CURRENT_ARGS=$(kubectl get deployment argocd-server -n argocd -o jsonpath='{.spec.template.spec.containers[0].args}')
      if ! echo "$CURRENT_ARGS" | grep -q -- '--insecure'; then
        kubectl patch deployment argocd-server -n argocd --type=json \
          -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--insecure"}]'
      fi

      if [ -f ${deployKeyPath} ]; then
        kubectl create secret generic homelab-argo-repo \
          --namespace=argocd \
          --from-literal=type=git \
          --from-literal=url=git@github.com:mateusfdl/homelab-argo.git \
          --from-file=sshPrivateKey=${deployKeyPath} \
          --dry-run=client -o yaml \
          | kubectl label --local -f - argocd.argoproj.io/secret-type=repository --dry-run=client -o yaml \
          | kubectl apply -f -
      fi

      ${builtins.concatStringsSep "\n      " (map (app: "kubectl apply -f ${app}") argocdApps)}

      kubectl apply -f ${certManagerApp}
      kubectl apply -f ${traefikApp}
      kubectl apply -f ${giteaApp}
      kubectl apply -f ${redisApp}

      for i in $(seq 1 60); do
        HEALTH=$(kubectl get application cert-manager -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null)
        SYNC=$(kubectl get application cert-manager -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null)
        [ "$HEALTH" = "Healthy" ] && [ "$SYNC" = "Synced" ] && break
        sleep 10
      done

      for i in $(seq 1 60); do
        HEALTH=$(kubectl get application traefik -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null)
        SYNC=$(kubectl get application traefik -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null)
        [ "$HEALTH" = "Healthy" ] && [ "$SYNC" = "Synced" ] && break
        sleep 10
      done

      kubectl apply -f ${argocdIngress}
    '';
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
    30022 # Gitea SSH
  ];

  environment.systemPackages = with pkgs; [ argocd ];
}
