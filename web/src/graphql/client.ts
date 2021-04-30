import {
  Client,
  dedupExchange,
  cacheExchange,
  fetchExchange,
  errorExchange,
  subscriptionExchange,
} from '@urql/svelte'
import { devtoolsExchange } from '@urql/devtools'
import { retryExchange } from '@urql/exchange-retry'
import { SubscriptionClient } from 'subscriptions-transport-ws'
import { getHeaders } from '$/lib/user'
import type { OperationDefinitionNode, FieldNode } from 'graphql'

const url = `${import.meta.env.VITE_HASURA_GRAPHQL_ENDPOINT}/v1/graphql`

const getWSEndpoint = () => {
  const endpoint = url.slice(7)

  if (endpoint[0] === '/') {
    return `wss://${endpoint.slice(1)}`
  }

  return `ws://${endpoint}`
}

const subscriptionClient = new SubscriptionClient(getWSEndpoint(), {
  reconnect: true,
  lazy: true,
  connectionParams: getHeaders,
})

const exchanges = [
  dedupExchange,
  cacheExchange,
  retryExchange({
    retryIf(errors) {
      if (errors.networkError) {
        return true
      }

      const [err] = errors.graphQLErrors
      const code = err.extensions?.code || ''

      switch (code) {
        case 'invalid-jwt':
          return true
      }

      return false
    },
  }),
  fetchExchange,
  subscriptionExchange({
    forwardSubscription(operation) {
      return subscriptionClient.request(operation)
    },
  }),
  errorExchange({
    onError(error, operation) {
      const query = operation.query.definitions.find(
        (def): def is OperationDefinitionNode =>
          def.kind === 'OperationDefinition'
      )!
      const name =
        query.name?.value ||
        (query.selectionSet.selections[0] as FieldNode).name?.value ||
        'unknown'

      console.error(`Encountered GraphQL error on operation "${name}":`, {
        error,
      })
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
