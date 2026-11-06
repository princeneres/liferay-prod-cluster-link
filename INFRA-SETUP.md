# Configuração do Liferay Cluster Link (Ambiente Produção – Sem Docker)

Este documento descreve como configurar o **Liferay Cluster Link** em um **ambiente de produção**, utilizando **múltiplas máquinas (VMs)** com banco de dados e Elasticsearch compartilhados.

O objetivo é permitir a comunicação segura entre os nós do Liferay utilizando **JGroups com TCP Unicast e autenticação X.509 (RSA)**.

> **Estratégia recomendada**  
> Iniciar os nós do Liferay com o Cluster Link desabilitado, gerar o certificado no primeiro nó, distribuir o keystore e arquivo de configuração TCP.xml para os demais nós e somente então habilitar o Cluster Link em todos.

---

## Visão Geral da Arquitetura

* Múltiplos nós do Liferay (VMs ou servidores físicos)
* Banco de dados compartilhado (ex.: DB2, PostgreSQL, Oracle)
* Elasticsearch compartilhado
* Comunicação de cluster via **JGroups TCP (unicast)**
* Autenticação de cluster usando **certificado X.509 (RSA)**

Exemplo:

```
liferay-node1   10.0.0.10
liferay-node2   10.0.0.11
liferay-node3   10.0.0.12
```

---

## Pré-requisitos de Infraestrutura

### Rede
* Comunicação TCP liberada entre todos os nós
* Portas do JGroups liberadas (ex.: 7800)
* DNS funcional ou IPs fixos

### Sistema
* Java compatível com a versão do Liferay
* `keytool` disponível
* Sincronização de horário (NTP)

---

## Passo 1 — Iniciar os Nós com Cluster Link Desabilitado

Em **todos os nós do Liferay**, edite:

```
[LIFERAY_HOME]/portal-ext.properties
```

Mantenha o Cluster Link desabilitado:

```properties
# cluster.link.enabled=true
# cluster.link.channel.properties.control=/opt/liferay/unicast/tcp.xml
# cluster.link.channel.properties.transport.0=/opt/liferay/unicast/tcp.xml
# cluster.link.auth.cert.alias=liferay-cluster-cert
# cluster.link.auth.keystore.path=/opt/liferay/unicast/cluster_link_keystore.p12
```

Inicie apenas o primeiro nó:

```bash
./tomcat/bin/startup.sh
```

---

## Passo 2 — Criar Estrutura de Arquivos

Em **todos os nós**:

```bash
sudo mkdir -p /opt/liferay/unicast
sudo chown -R liferay:liferay /opt/liferay/unicast
```

---

## Passo 3 — Gerar o Certificado no Primeiro Nó

Gere um keystore próprio do ambiente. Nunca reutilize um keystore ou uma senha que tenha passado pelo Git.

```bash
export CLUSTER_KEYSTORE_PASSWORD='<senha forte, sem $ nem %>'
scripts/generate-cluster-keystore.sh /opt/liferay/unicast/cluster_link_keystore.p12 liferay-cluster-cert
```

---

## Passo 4 — Distribuir o Keystore

```bash
scp /opt/liferay/unicast/cluster_link_keystore.p12 liferay@<no-2>:/opt/liferay/unicast/
```

Em cada nó, deixe o arquivo com permissão `600` para o usuário do Liferay.

---

## Passo 5 — Configurar JGroups TCP nos Nós

Copie [`unicast/tcp.xml`](unicast/tcp.xml) para `/opt/liferay/unicast/tcp.xml` em todos os nós, trocando `IP_NO_1` e
`IP_NO_2` pelos IPs reais. **Os protocolos `AUTH` e `ASYM_ENCRYPT` são obrigatórios.** Sem eles, o cluster aceita
qualquer nó, mesmo com as propriedades do passo 6 preenchidas.

---

## Passo 6 — Habilitar o Cluster Link nos Nós

```properties
cluster.link.enabled=true
cluster.link.channel.properties.control=/opt/liferay/unicast/tcp.xml
cluster.link.channel.properties.transport.0=/opt/liferay/unicast/tcp.xml

cluster.link.auth.cert.alias=liferay-cluster-cert
cluster.link.auth.cert.password=<SENHA_DO_KEYSTORE>
cluster.link.auth.cipher.type=RSA
cluster.link.auth.keystore.password=<SENHA_DO_KEYSTORE>
cluster.link.auth.keystore.path=/opt/liferay/unicast/cluster_link_keystore.p12
cluster.link.auth.keystore.type=PKCS12
cluster.link.auth.value=<SEGREDO_COMPARTILHADO>

web.server.display.node=true
```

---

## Passo 7 — Reiniciar os Nós

```bash
./tomcat/bin/startup.sh
```

---

## Passo 8 — Validação

Nos logs, `Accepted view` deve listar todos os nós nos dois canais.

Em seguida, rode o teste negativo em uma máquina fora do cluster, conforme o [README](README.md). O resultado
nunca pode ser `RESULT JOINED`.

## Referências:

- [Configuring Cluster Link](https://learn.liferay.com/w/dxp/self-hosted-installation-and-upgrades/setting-up-liferay/clustering-for-high-availability/configuring-cluster-link#configuring-cluster-link-1)
- [Configuring Unicast over TCP](https://learn.liferay.com/w/dxp/self-hosted-installation-and-upgrades/setting-up-liferay/clustering-for-high-availability/configuring-unicast-over-tcp#unicast-configurations)
