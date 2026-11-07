# Liferay Cluster Link com TCP unicast e autenticação

Modelo em Docker de um cluster Liferay 7.4 com dois nós, banco e Elasticsearch compartilhados, usando
JGroups por TCP com **autenticação X.509 e mensagens cifradas**.

> Uma pilha JGroups sem os protocolos `AUTH` e `ASYM_ENCRYPT` aceita qualquer nó que alcance a porta e
> ignora as propriedades `cluster.link.auth.*`. Esse é o cenário da CVE-2025-62250.

## Subir o ambiente

```bash
cp .env.example .env
```

Troque os valores em `.env`. Carregue-os e gere o keystore uma única vez:

```bash
set -a; . ./.env; set +a
scripts/generate-cluster-keystore.sh secrets/cluster_link_keystore.p12 liferay-cluster-cert
```

```bash
mkdir -p local/modules
docker compose up -d
```

O primeiro boot cria o schema, então o `liferay-node2` só sobe depois que o `liferay-node1` estiver saudável.

Em uma máquina só, use o laboratório, que tem heaps menores e um Elasticsearch:

```bash
docker compose -f docker-compose.yml -f docker-compose.lab.yml up -d
```

## Validar

Nos logs dos dois nós, `Accepted view` deve listar os 2 membros nos canais de controle e transporte.

Teste negativo, com o nome real da rede do Compose:

```bash
security-tests/check-unauthorized-node.sh <projeto>_liferay-network "$PWD/security-tests/stacks/tcp-insecure.xml"
```

| Resultado | Significado |
| --- | --- |
| `RESULT ALONE` ou `RESULT REJECTED` | Cluster protegido |
| `RESULT JOINED` | **Cluster aceitou um nó sem credencial** |

Para ver o cenário vulnerável, use `JGROUPS_STACK=/opt/liferay/unicast-insecure/tcp-insecure.xml` no laboratório.

## Regras

- Use **IPs** em `initial_hosts`. Um nome que não resolve no boot faz o canal falhar e o portal responder 500.
- O keystore, as senhas e o `.env` nunca vão para o Git.
- Nós com pilhas diferentes não se comunicam: a troca exige parar todos.
- A pasta de documentos é compartilhada entre os nós. O Nginx usa `ip_hash` para manter o usuário no mesmo nó.

Para servidores sem Docker, veja [INFRA-SETUP.md](INFRA-SETUP.md).
