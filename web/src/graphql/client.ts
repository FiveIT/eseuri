import type { ClientOptions } from '@urql/svelte'
import { defaultExchanges, subscriptionExchange } from '@urql/svelte'
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

const getHeaders = () => ({ headers: { Authorization: get(authToken) } })

const subscriptionClient = new SubscriptionClient(getWSEndpoint(), {
  reconnect: true,
  connectionParams: getHeaders,
})

const opts: ClientOptions = {
  url,
  fetchOptions: getHeaders,
  exchanges: [
    ...defaultExchanges,
    subscriptionExchange({
      forwardSubscription(operation) {
        return subscriptionClient.request(operation)
      },
    }),
  ],
}

export default opts
