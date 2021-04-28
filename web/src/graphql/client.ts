import { Client, defaultExchanges, subscriptionExchange } from '@urql/svelte'
import { devtoolsExchange } from '@urql/devtools'
import { SubscriptionClient } from 'subscriptions-transport-ws'
import { get } from 'svelte/store'
import { authToken } from '@tmaxmax/svelte-auth0'

const url = `${import.meta.env.VITE_HASURA_GRAPHQL_ENDPOINT}/v1/graphql`

const getWSEndpoint = () => {
  const endpoint = url.slice(7)

  if (endpoint[0] === '/') {
    return `wss://${endpoint.slice(1)}`
  }

  return `ws://${endpoint}`
}

const getHeaders = () => {
  const token = get(authToken)

  if (token !== '') {
    return { headers: { Authorization: token } }
  }

  return {}
}

const subscriptionClient = new SubscriptionClient(getWSEndpoint(), {
  reconnect: true,
  lazy: true,
  connectionParams: getHeaders,
})

const exchanges = [
  ...defaultExchanges,
  subscriptionExchange({
    forwardSubscription(operation) {
      return subscriptionClient.request(operation)
    },
  }),
]

if (import.meta.env.DEV) {
  exchanges.push(devtoolsExchange)
}

export default new Client({
  url,
  fetchOptions: getHeaders,
  exchanges,
})
