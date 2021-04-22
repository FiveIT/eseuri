module.exports = async (client, scope, audience, context, cb) => {
  const accessToken = { scope }
  const { HASURA_GRAPHQL_ENDPOINT, HASURA_GRAPHQL_ADMIN_SECRET } = context.webtask.secrets
  const util = require('util')
  const request = require('request')
  const post = util.promisify(request.post)
  const query = `
    mutation($auth0ID: String!, $email: citext!) {
      insert_users_one(object: {auth0_id: $auth0ID, email: $email}) {
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
    auth0ID: `auth0|${Math.random().toString(16).substring(7)}`,
    email: `dummy.${Math.random().toString(32).substring(7)}@example.com`,
  }

  function assertData(body) {
    console.dir({ body }, { depth: null })

    if ('errors' in body) {
      throw new Error(body.errors.map(e => e.message).join('\n\n'))
    }
  }

  try {
    const { body } = await post({
      url,
      headers,
      json: { query, variables },
    })

    assertData(body)

    const { id, role, updated_at } = body.data.insert_users_one

    if (updated_at === null) {
      const query = `
        mutation($firstName: Int!, $lastName: Int!, $schoolID: Int!) {
          update_users(where: {}, _set: {first_name: $firstName, last_name: $lastName, school_id: $schoolID}) {
            affected_rows
          }
        }
      `
      const variables = {
        firstName: 'Dummy',
        lastName: 'Michael',
        schoolID: (Math.random() * 1000) | 0,
      }
      const headers = {
        'X-Hasura-Role': role,
        'X-Hasura-User-Id': `${id}`,
        'X-Hasura-Admin-Secret': HASURA_GRAPHQL_ADMIN_SECRET,
      }

      const { body } = await post({
        url,
        headers,
        json: { query, variables },
      })

      assertData(body)
    }

    accessToken['https://hasura.io/jwt/claims'] = {
      'X-Hasura-Default-Role': role,
      'X-Hasura-Allowed-Roles': ['anonymous', role],
      'X-Hasura-User-Id': `${id}`,
    }
    accessToken['https://eseuri.com'] = {
      hasCompletedRegistration: true,
    }
    accessToken.scope.push('extra')

    cb(null, accessToken)
  } catch (err) {
    console.error(err)
    callback(err)
  }
}
