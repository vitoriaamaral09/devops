# Cluster Kubernetes local com Kind via Terraform

## Objetivo

Este projeto provisiona, de forma totalmente automatizada via Terraform, um cluster Kubernetes local utilizando o Kind (Kubernetes in Docker), sem nenhuma etapa manual de criação do cluster (não foi utilizado `kind create cluster` em nenhum momento).

## Nome do cluster e topologia

- **Nome do cluster:** `devops`
- **Versão do Kubernetes:** v1.33.1
- **Topologia:**
  - 1 node com papel de **control-plane** (controller) — `devops-control-plane`
  - 2 nodes com papel de **worker** — `devops-worker` e `devops-worker2`

Confirmado via `kubectl get nodes -o wide`:

| NAME                 | STATUS | ROLES         | VERSION | INTERNAL-IP |
|----------------------|--------|---------------|---------|-------------|
| devops-control-plane | Ready  | control-plane | v1.33.1 | 172.18.0.7  |
| devops-worker        | Ready  | \<none\>      | v1.33.1 | 172.18.0.8  |
| devops-worker2       | Ready  | \<none\>      | v1.33.1 | 172.18.0.5  |

A topologia é definida diretamente no arquivo `main.tf`, através do bloco `kind_config`, usando o provider Terraform `tehcyx/kind`, que internamente cria os nodes como containers Docker (imagem `kindest/node`).

## Como foi provisionado

Todo o processo foi feito via `terraform init` e `terraform apply`, utilizando o provider `tehcyx/kind`. Nenhum comando `kind create cluster` foi executado manualmente — o próprio Terraform, através do provider, cria os containers Docker que representam os nodes do cluster, com base na especificação declarada no `main.tf`.

## Componentes provisionados

Ao criar o cluster, o Kind provisiona os seguintes componentes principais:

1. **Node control-plane (devops-control-plane)**
   Container Docker que executa os componentes de gerenciamento do Kubernetes:
   - `kube-apiserver`: expõe a API do Kubernetes (porta 6443), é o ponto de entrada para todos os comandos `kubectl`.
   - `kube-scheduler`: decide em qual node um novo Pod deve rodar, com base em recursos disponíveis e restrições.
   - `kube-controller-manager`: executa os "controllers" que mantêm o estado desejado do cluster (ex.: garantir que o número de réplicas de um Deployment esteja correto).
   - `etcd`: banco de dados chave-valor que armazena todo o estado do cluster (configurações, objetos, secrets, etc.).

2. **Nodes worker (devops-worker, devops-worker2)**
   Containers Docker responsáveis por executar as cargas de trabalho (Pods) do cluster:
   - `kubelet`: agente que roda em cada node e garante que os containers descritos nos Pods estejam de fato em execução.
   - `kube-proxy`: gerencia as regras de rede em cada node, permitindo a comunicação entre Pods e Services.
   - `containerd`: runtime de containers responsável por efetivamente executar os containers dos Pods.

3. **Rede do cluster (kindnet / CNI)**
   O Kind instala um plugin de rede (CNI) chamado `kindnet`, responsável por atribuir IPs aos Pods e permitir a comunicação entre eles, entre nodes diferentes. Roda como DaemonSet, um pod por node.

4. **CoreDNS**
   Serviço de DNS interno do cluster (visível em `kubectl cluster-info`), que permite que Pods e Services se encontrem por nome (ex.: `meu-servico.default.svc.cluster.local`) em vez de precisar saber o IP.

5. **kube-proxy e Services**
   Componente que implementa as regras de roteamento de rede para os `Services` do Kubernetes, permitindo balanceamento de carga simples entre Pods.

6. **Storage Provisioner local (local-path-provisioner)**
   Componente adicional instalado pelo Kind por padrão, que permite a criação de `PersistentVolumes` usando o disco local dos nodes, útil para testes com armazenamento persistente.

## Como reproduzir

```bash
cd terraform-kind-devops
terraform init
terraform apply -auto-approve

# Configurar o kubectl para usar o cluster criado
export KUBECONFIG=$(terraform output -raw kubeconfig_path)

# Verificar os nodes
kubectl get nodes -o wide

# Verificar informações do cluster
kubectl cluster-info
```

## Como destruir o cluster

```bash
terraform destroy -auto-approve
```

## Evidências

As evidências de criação do cluster (prints de `kubectl get nodes -o wide` e `kubectl cluster-info`, mostrando os 3 nodes `Ready` com a topologia correta e o control plane/CoreDNS ativos) estão na pasta `evidencias/` deste pacote.
