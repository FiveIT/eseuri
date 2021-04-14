import '@tepez/auth0-rules-types'
import { IAuth0RuleCallback, IAuth0RuleContext, IAuth0RuleUser } from '@tepez/auth0-rules-types'
import * as request from 'request'
import * as util from 'util'

type Role = 'student' | 'teacher'

interface User {
  id: number
  role: Role
}

interface Error {
  extensions: {
    path: string
    code: string
  }
  message: string
}

type QueryKey = string
type QueryValue = Record<string, any> | null

interface Data<K extends QueryKey, V extends QueryValue> {
  data: {
    [key in K]: V
  }
}

interface Response<K extends QueryKey, V extends QueryValue> extends request.Response {
  body: Data<'errors', Error[]> | Data<K, V>
}

type ResponseInsert = Response<'insert_users_one', User | null>
type ResponseSelect = Response<'users', [User]>

async function callback(user: IAuth0RuleUser<{}, {}>, context: IAuth0RuleContext, callback: IAuth0RuleCallback<{}, {}>) {
  const { HASURA_GRAPHQL_ENDPOINT, HASURA_GRAPHQL_ADMIN_SECRET } = configuration as any
  const post = util.promisify(request.post)
  const namespace = 'https://hasura.io/jwt/claims'
  const insertUserQuery = `
    mutation insertUser($firstName: String!, $middleName: String, $lastName: String!, $email: String!, $auth0ID: String!) {
      insert_users_one(object: {first_name: $firstName, middle_name: $middleName, last_name: $lastName, email: $email, role: "student", auth0_id: $auth0ID}) {
        id
        role
      }
    }
  `
  const getUserQuery = `
    query getUser($auth0ID: String!) {
      users(where: {auth0_id: {_eq: $auth0ID}}) {
        id
        role
      }
    }
  `
  const url = `${HASURA_GRAPHQL_ENDPOINT}/v1/graphql`
  const headers = {
    'X-Hasura-Admin-Secret': HASURA_GRAPHQL_ADMIN_SECRET,
    'X-Hasura-Use-Backend-Only-Permissions': 'true',
  }
  const variables = {
    firstName: user.given_name || null,
    middleName: user.nickname || null,
    lastName: user.family_name || null,
    email: user.email || null,
    auth0ID: user.user_id,
  }

  function assertData<K extends QueryKey, V extends QueryValue>(body: Response<K, V>['body']): asserts body is Data<K, V> {
    console.dir({ body }, { depth: null })

    if ('errors' in body.data) {
      throw new Error(body.data.errors.map(e => e.message).join('\n\n'))
    }
  }

  try {
    const { body }: ResponseInsert = await post({
      url,
      headers,
      json: {
        query: insertUserQuery,
        variables,
      },
    })

    assertData(body)

    let id = body.data.insert_users_one?.id
    let role = body.data.insert_users_one?.role
    let isRegistered = true
    if (typeof id === 'undefined') {
      isRegistered = false
      const { body }: ResponseSelect = await post({
        url,
        headers,
        json: {
          query: getUserQuery,
          variables: {
            auth0ID: variables.auth0ID,
          },
        },
      })

      assertData(body)
      ;({ id, role } = body.data.users[0])
    }

    if (typeof role === 'undefined') {
      throw new Error('Role is still undefined, something went terribly wrong!')
    }

    context.accessToken[namespace] = {
      'X-Hasura-Default-Role': role,
      'X-Hasura-Allowed-Roles': ['anonymous', role],
      'X-Hasura-User-Id': `${id}`,
    }
    context.accessToken['eseuri'] = {
      isRegistered,
    }

    callback(null, user, context)
  } catch (err) {
    console.error(err)
    callback(err)
  }
}
