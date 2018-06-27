# Native Demo DApp

## Running Locally

First, install the dependencies.

```bash
pod install
```

Then, configure your environment with your Bitski credentials. Open `env-vars.example.sh`, modify it with your credentials, and rename it to `env-vars.sh`.

```bash
# env-vars.sh.
export BITSKI_CLIENT_ID="<YOUR CLIENT ID>"
export BITSKI_REDIRECT_URL="<YOUR REDIRECT URL>"
export SENTRY_DSN="" # leave blank to disable Sentry
```

At this point you should be able to run the app in the simulator. This will run off our deployed instance of the contract on the Kovan test network.

## Modifying the Contract

Our dapp is powered by a Solidity contract that. To edit the contract, see the [contracts](contracts/). folder. After you make changes to the contract, you'll need to compile the contract and deploy it somewhere. Usually it makes sense to build and test on a local blockchain before deploying it publicly.

Start by installing truffle globally.

```bash
npm install -g truffle
```

Then, start truffle's development blockchain.

```bash
truffle develop
```

Once the development blockchain is running, then run the migrations in the dev console:

```bash
truffle(develop)> migrate
```

You can learn more about deploying contracts with truffle [here](http://truffleframework.com/docs/getting_started/migrations).

Once the contracts are deployed locally, you need to make some edits to the iOS project.

Open `LimitedMintableNonFungibleToken.swift` and...

1. Change `CurrentNetwork` to `nil` (or the network where your contract is deployed)
2. Confirm that your truffle server host matches `DevelopmentHost`
3. Change `contractAddress` to the address where it was deployed on this network
4. Add any additional methods you may have added to the contract to the Swift representation

At this point you should be able to interact with your modified contract locally. Sweet!

## Deploying to a real network

Once you have your dapp how you want it, you'll want to deploy it to a public blockchain somewhere. This can be achieved using a local Ethereum node, or Bitski's app wallet feature.
To use Bitski's app wallet, you'll need to request access to this feature. Once you have an app wallet, find the client id and secret.

Modify your `truffle.js` to look like `truffle.example.js`, filling in the client id and secret. Make sure not to expose these keys anywhere as they give access to your wallet.

Next, you'll want to migrate your contracts to the network you desire:

```bash
# mainnet
truffle migrate --network live

# kovan
truffle migrate --network kovan

# rinkeby
truffle migrate --network rinkeby
```

Finally, make changes within the iOS app to point to your live contract;

Open `LimitedMintableNonFungibleToken.swift` and...

1. Change `CurrentNetwork` to `.kovan`, `.rinkeby`, or `.mainnet` depending on where you deployed it
2. Change `contractAddress` to the address where it was deployed on this network
