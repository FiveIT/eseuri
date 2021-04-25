import '@tepez/auth0-rules-types'
import { IAuth0RuleCallback, IAuth0RuleContext, IAuth0RuleUser } from '@tepez/auth0-rules-types'
import * as request from 'request'
import * as util from 'util'

type Role = 'student' | 'teacher'

interface User {
  id: number
  role: Role
  updated_at: string | null
}

interface Error {
  extensions: {
    path: string
    code: string
  }
  message: string
}

interface Errors {
  errors: Error[]
}

type QueryKey = string
type QueryValue = Record<string, any> | null

interface Data<K extends QueryKey, V extends QueryValue> {
  data: {
    [key in K]: V
  }
}

interface Response<K extends QueryKey, V extends QueryValue> extends request.Response {
  body: Errors | Data<K, V>
}

type ResponseInsert = Response<'insert_users_one', User>

async function callback(user: IAuth0RuleUser<{}, {}>, context: IAuth0RuleContext, callback: IAuth0RuleCallback<{}, {}>) {
  const { HASURA_GRAPHQL_ENDPOINT, HASURA_GRAPHQL_ADMIN_SECRET } = configuration as any
  const post = util.promisify(request.post)
  const insertUserQuery = `
    mutation insertUser($firstName: String, $lastName: String, $email: citext!, $auth0ID: String!) {
      insert_users_one(object: {first_name: $firstName, last_name: $lastName, email: $email, auth0_id: $auth0ID}) {
        id
        role
        updated_at
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
    lastName: user.family_name || null,
    email: user.email,
    auth0ID: user.user_id,
  }

  function assertData<K extends QueryKey, V extends QueryValue>(body: Response<K, V>['body']): asserts body is Data<K, V> {
    console.dir({ body }, { depth: null })

    if ('errors' in body) {
      throw new Error(body.errors.map(e => e.message).join('\n\n'))
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

    const { id, role, updated_at } = body.data.insert_users_one

    context.accessToken['https://hasura.io/jwt/claims'] = {
      'X-Hasura-Default-Role': role,
      'X-Hasura-Allowed-Roles': ['anonymous', role],
      'X-Hasura-User-Id': `${id}`,
    }
    context.accessToken['https://eseuri.com'] = {
      hasCompletedRegistration: updated_at !== null,
    }

    callback(null, user, context)
  } catch (err) {
    console.error(err)
    callback(err)
  }
}
