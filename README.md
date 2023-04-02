# Bondly (Smart Contract for King of Devs Hackathon)

Buenos Aires - Argentina

## Introduction

The backend for the Bondly app is composed by two blocks:

1. The `OrganizationVault` smart contract.
2. The **Cedalio** database.

In order to relate the information between the two backends we are using the `id`s in UUID created by Cedalio. An example looks:

```graphql
{
  "id": "207760f2-fdd3-4397-80cc-a51093ccbf18"
}
```


Complile the schema

```sh
cedalio compile --schema-file data/schema.graphql
```

Run a local hardhat node. The configuration force mining 1 block per second.

```sh
npx hardhat node --config ./hardhat.config.js
```

Deploy.

```sh
cedalio deploy --fresh --schema-file data/schema.graphql --network hardhat


cedalio serve --schema-name schema
```


```graphql
mutation {
  createUser(user: {
  	firstName: "hello4",
  	lastName: "world4",
  	emails: ["hello4@world.com"],
  	age: 24
  }) {
    txHash
    user {
      id
      lastName
    }
  }
}


query {
  allUsers {
    id
    lastName
  }
}


query {
  userById(id: "06bfacbc-5e13-4c7c-a103-12666fcb9df4") {
    firstName
    lastName
    age
  }
}


```