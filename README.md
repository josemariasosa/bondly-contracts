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

## Test the smart contract

Run the contract tests.

```sh
$ npx hardhat test

  Organization Vault - King of Devs 🧠
    Deployment
      ✔ Should be deployed with the correct params. (949ms)
      ✔ Should have a correct initial setup. (200ms)
    Create, approve and reject Movements
      ✔ Should create a movement. (61ms)
      ✔ Should approve a movement. (113ms)
      ✔ Should reject a movement, but after 2nd approval, send the funds. (141ms)
      ✔ Should reject a movement altogether and return the funds to the Organization. (126ms)


  6 passing (2s)
```

## Test the database

Complile the schema.

```sh
cedalio compile --schema-file data/schema.graphql
```

Run a local hardhat node. The configuration force mining 1 block per second.

```sh
npx hardhat node --config ./hardhat.config.cedalio-node.js
```

Deploy.

```sh
cedalio deploy --fresh --schema-file data/schema.graphql --network hardhat

## IMPORTANT: The prompt will ask you to give a name to the schema.

cedalio serve --schema-name schema
```

Create the principal objects to generate an ID the users could use in the smart contract.

```graphql
# Create an Organization
mutation {
  createOrganization(organization: {
    name: "My First Organization"
  	owners: ["alice.address", "bob.address", "carl.address"]
  }) {
    txHash
    organization {
      id
    }
  }
}
```

After running the mutation, this is what you expect to see after running the query.

```graphql
{
  "data": {
    "createOrganization": {
      "organization": {
        "id": "c9dfdef5-4977-4467-80b9-82453be07ec1"
      }
    }
  }
}
```

Now, is time to create a new project.

```graphql
mutation {
  createProject(project: {
    name: "Podcast Event"
  	description: "This is an event for a Web3 podcast."
  	start_datetime: "2023-04-04"
  	end_datetime: "2023-04-04"
  	budget: 300
  	organization: "c9dfdef5-4977-4467-80b9-82453be07ec1"
  }) {
    txHash
    project {
      id
    }
  }
}
```

And last, create a new movement, to be submited to approval.

```graphql
mutation {
  createMovement(movement: {
  	title: "Pagar Pizzas"
  	description: "Las pizzas mas ricas del mundo"
  	amount: 199
  	token: "USDT"
    content: "link/to/online/content"
  	pay_to_address: "pizzaShop.address"
  	tag: "comida"
  	organization: "c9dfdef5-4977-4467-80b9-82453be07ec1"
  	project: "fe2f8dfa-0c6e-4d60-ba62-efc1c1dcd712"
  }) {
    txHash
    movement {
      id
    }
  }
}
```