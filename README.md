# Provision Self-manage MongoDB with Vector Search Engine

## 1) Install MongoDB

- [Ubuntu](https://www.mongodb.com/docs/manual/administration/install-community/?linux-distribution=ubuntu&linux-package=default&operating-system=linux&search-linux=with-search-linux)
- [Red Hat Enterprise Linux, Oracle Linux, CentOS Linue](https://www.mongodb.com/docs/manual/administration/install-community/?operating-system=linux&linux-distribution=red-hat&linux-package=default&macos-installation-method=None&windows-installation-method=None&search-linux=with-search-linux&search-docker=None#std-label-community-search-deploy)

## 2) Provision MongoDB instance (mongod)

### 2.1) Generate keyfile for replica set

```
openssl rand -base64 756 > <path/to/keyfile>
chmod 400 <path/to/keyfile>
```

### 2.2) Config authentication keyfile in each `mongod.conf`

```
storage:
  dbPath: { path to data }
systemLog:
  path: { path to log file }
keyFile: {path to keyfile}
```

\*Whop! don't forget `chown mongodb:mongodb { path to data and log }` <br />
\*Also `chown mongodb:mongodb data/rs*` && `chown mongodb:mongodb data/mongot` for mongodb owner of data and log.

### 2.3) Spin up all MongoDB replica set

```
mongod --config {MongoDB config file} --fork
```

### 2.4) Access to Primary instance and sync replica set

Access to instance

```
mongosh --port {port number}
```

Sync replica set

```
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "localhost:27017" },
    { _id: 1, host: "localhost:27018" },
    { _id: 2, host: "localhost:27019" }
  ]
})
```

Check status

```
rs.status()
```

### 2.5) Create users

#### Create admin user

```
db.createUser({
  user: "admin",
  pwd: "admin",
  roles: [ { role: "root", db: "admin" } ]
})
```

#### Create user for Vector Search Engine

```
db.createUser(
   {
      user: "mongot",
      pwd: "mongot",
      roles: [ "searchCoordinator"]
   }
)
```

## 3) Spin up Vector Search Engine (mongot)

### 3.1) Download engine

```
wget https://downloads.mongodb.org/mongodb-search-community/0.55.0/mongot_community_0.55.0_linux_x86_64.tgz
```

and unzip

```
tar -zxvf mongot_community_0.55.0_linux_x86_64.tgz
```

### 3.2) Create password file

```
echo -n "{mongot_password}" > passwordFile
chmod 400 passwordFile
```

### 3.3) Configurate Vector Search Engine

In `config.default.yml`

```
syncSource:
   replicaSet:
      hostAndPort: "{___}" # Replace with the mongod host and port. localhost:27017
      username: {___} # Replace with mongod username enabled with "searchCoordinator" role.
      passwordFile: "{___}" # Replace with path to password file for the above user. /etc/mongot/secrets/passwordFile
      tls: false
storage:
   dataPath: "{___}"  # Replace with the path where you want mongot to store search data. /var/lib/mongot
server:
grpc:
   address: "localhost:27028" # Replace with the address and port for mongot listen server
   tls:
      mode: "disabled"
metrics:
   enabled: true
   address: "localhost:9946"
healthCheck:
   address: "localhost:8080"
logging:
   verbosity: INFO
```

### 3.4) Run the engine

Go to unzip directory of Mongot

```
sudo ./mongot --config config.default.yml
```

### 3.4) Check status of engine (mongot)

```
curl http://localhost:8080
```

## 4) Create vector search index

### 4.1) Go to mongosh

```
mongosh --port {port} -u {username} -p {password}
```

### 4.2) Create collection

```
db.createCollection("search_collection")
```

### 4.3) Enable vector search index

```
db.search_collection.createSearchIndex(
  "vector_index_name",  // Index name
  "vectorSearch",        // Index type
  {
    fields: [
      {
        type: "vector",
        path: "embedding",           // Field containing vector embeddings
        numDimensions: 1536,         // Dimensionality of your vectors
        similarity: "cosine"         // Similarity metric: "cosine", "euclidean", or "dotProduct"
      }
    ]
  }
)
```

Check vector search index

```
db.search_collection.aggregate([
  {
    $listSearchIndexes: {}
  }
])
```
