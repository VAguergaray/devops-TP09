# TP09 — Kubernetes: Pods, Deployments y Services

App de notas (TP06) desplegada en Kubernetes con Postgres, backend Flask y frontend Nginx.

## Arquitectura

```
Namespace: devops-portfolio
├── Deployment: postgres (1 réplica)  ← Service ClusterIP :5432
├── Deployment: backend  (2 réplicas) ← Service "backend" ClusterIP :5000
└── Deployment: frontend (2 réplicas) ← Service NodePort :30080
```

## Recursos Kubernetes usados

| Recurso | Para qué sirve |
|---|---|
| `Namespace` | Aislar todos los recursos del proyecto |
| `Secret` | Credenciales de Postgres en base64 |
| `ConfigMap` | Variables de entorno no sensibles |
| `PersistentVolumeClaim` | Almacenamiento persistente para la DB |
| `Deployment` | Gestión declarativa de pods y réplicas |
| `Service ClusterIP` | Comunicación interna entre pods |
| `Service NodePort` | Exposición al exterior del cluster |
| `initContainer` | Esperar a que Postgres esté listo |
| `readinessProbe` | Verificar que el pod está listo para recibir tráfico |
| `livenessProbe` | Reiniciar el pod si está colgado |
| `resources` | Límites de CPU y memoria por pod |

## Deploy

```bash
bash scripts/deploy.sh
```

## Verificar

```bash
bash scripts/verificar.sh
kubectl get all -n devops-portfolio
```

La app queda disponible en `http://localhost:30080`.

## Comandos útiles

```bash
# Escalar backend a 3 réplicas
kubectl scale deployment backend --replicas=3 -n devops-portfolio

# Ver logs en tiempo real
kubectl logs -l app=backend -n devops-portfolio -f

# Entrar a un pod
kubectl exec -it <pod-name> -n devops-portfolio -- /bin/sh

# Rollback
kubectl rollout undo deployment/backend -n devops-portfolio
```

## Conceptos clave

- **Estado deseado:** Kubernetes funciona declarando lo que querés (por ejemplo, 2 réplicas del backend) y el Controller Manager se encarga de que siempre sea así, reiniciando pods que mueren o redistribuyéndolos si un nodo falla.
- **Probes (readiness y liveness):** le indican a Kubernetes cuándo un pod está listo para recibir tráfico y cuándo debe reiniciarse.
- **Resources (requests y limits):** son el contrato de cada pod con el scheduler; sin ellos no puede decidir dónde colocar los pods y el cluster se vuelve impredecible.
