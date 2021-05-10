import { gql } from '@urql/svelte'

import type { WorkType, WorkSummary, Nullable, FullNamer } from '$/lib'

type QueryData<Name extends string, Data> = Nullable<
  {
    // eslint-disable-next-line no-unused-vars
    [key in Name]: Data
  }
>

interface Typename {
  __typename: string
}

type Query<Name extends string, Data = Typename, Vars = object> = {
  vars: Vars
  data: QueryData<Name, Data>
}

export type Data<T> = T extends Query<infer Name, infer Data, unknown>
  ? QueryData<Name, Data>
  : never

export type Vars<T> = T extends Query<string, unknown, infer Vars> ? Vars : never

const WORK_SUMMARY = gql`
  fragment WorkSummary on work_summaries {
    name
    url
    creator
    type
    work_count
  }
`

interface WorkSummariesVars {
  type: WorkType
}

export type WorkSummaries = Query<'work_summaries', WorkSummary[], WorkSummariesVars>

export const WORK_SUMMARIES = gql<Data<WorkSummaries>, Vars<WorkSummaries>>`
  ${WORK_SUMMARY}
  query getWorkSummaries($type: String!) {
    work_summaries(
      where: { type: { _eq: $type } }
      order_by: [{ work_count: desc }, { name: asc }]
    ) {
      ...WorkSummary
    }
  }
`

interface SearchWorkSummariesVars extends WorkSummariesVars {
  query: string
}

export type SearchWorkSummaries = Query<
  'find_work_summaries',
  WorkSummary[],
  SearchWorkSummariesVars
>

export const SEARCH_WORK_SUMMARIES = gql<Data<SearchWorkSummaries>, Vars<SearchWorkSummaries>>`
  ${WORK_SUMMARY}
  query searchWorkSummaries($query: String!, $type: String) {
    find_work_summaries(args: { query: $query, worktype: $type, fuzziness: 2 }) {
      ...WorkSummary
    }
  }
`

interface RegisterUserVars {
  firstName: string
  middleName: string | null
  lastName: string
  schoolID: number
}

export type RegisterUser = Query<'update_users', { affected_rows: number }, RegisterUserVars>

export const REGISTER_USER = gql<Data<RegisterUser>, Vars<RegisterUser>>`
  mutation registerUser(
    $firstName: String!
    $middleName: String
    $lastName: String!
    $schoolID: Int!
  ) {
    update_users(
      where: {}
      _set: {
        first_name: $firstName
        middle_name: $middleName
        last_name: $lastName
        school_id: $schoolID
      }
    ) {
      affected_rows
    }
  }
`

export type UserUpdatedAt = Query<'users', [{ updated_at: string | null }]>

export const USER_UPDATED_AT = gql<Data<UserUpdatedAt>, Vars<UserUpdatedAt>>`
  query userUpdatedAt {
    users(where: {}) {
      updated_at
    }
  }
`

interface ID<T extends string | number = number> {
  id: T
}

interface Namer {
  name: string
}

type Subject = ID & Namer

export type Titles = Query<'titles', Subject[]>

export const TITLES = gql<Data<Titles>, Vars<Titles>>`
  query getTitles {
    titles {
      id
      name
    }
  }
`

export type Characters = Query<'characters', Subject[]>

export const CHARACTERS = gql<Data<Characters>, Vars<Characters>>`
  query getCharacters {
    characters {
      id
      name
    }
  }
`

type SubjectIDFromURL = Query<
  'work_summaries',
  [ID & Namer & { work_count: number }] | [],
  { url: string }
>

export const SUBJECT_ID_FROM_URL = gql<Data<SubjectIDFromURL>, Vars<SubjectIDFromURL>>`
  query getSubjectIDFromURL($url: String!) {
    work_summaries(where: { url: { _eq: $url } }) {
      name
      id
      work_count
    }
  }
`

export namespace Relay {
  export type ID = string
  export type IDObject = { id: ID }

  export type Cursor = string | null

  export interface PageInfo {
    startCursor: Cursor
    endCursor: Cursor
    hasNextPage: boolean
    hasPreviousPage: boolean
  }

  type Edge<Data, hasCursor> = hasCursor extends true
    ? {
        cursor: Cursor
        node: Data
      }
    : {
        node: Data
      }

  export type Data<T, hasCursor> = {
    pageInfo: PageInfo
    edges: Edge<T, hasCursor>[]
  }

  export interface CursorVars {
    before?: Cursor
    after?: Cursor
    first?: number
    last?: number
  }
}

// eslint-disable-next-line no-redeclare
export type Relay<
  Name extends string,
  Data = Typename,
  Vars = object,
  hasCursor extends boolean = false
> = Query<`${Name}_connection`, Relay.Data<Data, hasCursor>, Vars>

// eslint-disable-next-line no-redeclare
export namespace Relay {
  export type Node<Name extends string | undefined, Data = Typename, Vars = object> = Query<
    'node',
    // eslint-disable-next-line no-unused-vars
    [Name] extends [string] ? { [key in Name]: Data } : Data,
    Vars
  >
}

interface ListSubjectsVars extends Relay.CursorVars {
  subjectID: number
  seed: `${number}`
}

type WorkIDer = { work_id: number }

export type ListSubjects<Name extends `${WorkType}s`> = Relay<
  `list_${Name}`,
  Relay.IDObject & WorkIDer,
  ListSubjectsVars,
  true
>
type ListEssays = ListSubjects<'essays'>
type ListCharacterizations = ListSubjects<'characterizations'>

export const LIST_ESSAYS = gql<Data<ListEssays>, Vars<ListEssays>>`
  query listEssays($subjectID: Int!, $seed: seed!, $after: String, $first: Int) {
    list_essays_connection(
      args: { titleid: $subjectID, seed: $seed }
      after: $after
      first: $first
    ) {
      pageInfo {
        startCursor
        endCursor
        hasNextPage
        hasPreviousPage
      }
      edges {
        cursor
        node {
          id
          work_id
        }
      }
    }
  }
`

export const LIST_CHARACTERIZATIONS = gql<Data<ListCharacterizations>, Vars<ListCharacterizations>>`
  query listCharacterizations($subjectID: Int!, $seed: seed!, $after: String, $first: Int) {
    list_characterizations_connection(
      args: { characterid: $subjectID, seed: $seed }
      after: $after
      first: $first
    ) {
      pageInfo {
        startCursor
        endCursor
        hasNextPage
        hasPreviousPage
      }
      edges {
        cursor
        node {
          id
          work_id
        }
      }
    }
  }
`

type WorkID = Relay.Node<undefined, WorkIDer, Relay.IDObject>

export const WORK_ID = gql<Data<WorkID>, Vars<WorkID>>`
  query workID($id: ID!) {
    node(id: $id) {
      ... on essays {
        work_id
      }
      ... on characterizations {
        work_id
      }
    }
  }
`

interface WorkData {
  content: string
}

type WorkContent = Relay.Node<'work', WorkData, Relay.IDObject>

export const WORK_CONTENT = gql<Data<WorkContent>, Vars<WorkContent>>`
  fragment WorkData on works {
    content
  }

  query workContent($id: ID!) {
    node(id: $id) {
      ... on essays {
        work {
          ...WorkData
        }
      }
      ... on characterizations {
        work {
          ...WorkData
        }
      }
    }
  }
`

type TeacherRequest = Query<'insert_teacher_requests_one'>

export const TEACHER_REQUEST = gql<Data<TeacherRequest>, Vars<TeacherRequest>>`
  mutation teacherRequest {
    insert_teacher_requests_one(object: {}) {
      status
    }
  }
`

interface BookmarkVars {
  workID: number
}

type Bookmark = Query<'insert_bookmarks_one', Namer, BookmarkVars & Namer>

export const BOOKMARK = gql<Data<Bookmark>, Vars<Bookmark>>`
  mutation bookmark($workID: Int!, $name: String!) {
    insert_bookmarks_one(object: { work_id: $workID, name: $name }) {
      name
    }
  }
`

type RemoveBookmark = Query<'delete_bookmarks', Typename, BookmarkVars>

export const REMOVE_BOOKMARK = gql<Data<RemoveBookmark>, Vars<RemoveBookmark>>`
  mutation removeBookmark($workID: Int!) {
    delete_bookmarks(where: { work_id: { _eq: $workID } }) {
      __typename
    }
  }
`

type IsBookmarked = Query<'bookmarks', [Namer] | [], BookmarkVars>

export const IS_BOOKMARKED = gql<Data<IsBookmarked>, Vars<IsBookmarked>>`
  query isBookmarked($workID: Int!) {
    bookmarks(where: { work_id: { _eq: $workID } }) {
      name
    }
  }
`

export type UnrevisedWork = ID & {
  status: WorkStatus
  user: FullNamer
  teacher_id: number
  updated_at: string | null
} & (
    | {
        essay: null
        characterization: {
          character: Namer & {
            title: Namer
          }
        }
      }
    | {
        characterization: null
        essay: {
          title: Namer & {
            author: FullNamer
          }
        }
      }
  )

type UnrevisedWorks = Query<'works', UnrevisedWork[], ID>

const UNREVISED_WORK_DATA_FRAGMENT = gql`
  fragment UnrevisedWorkData on works {
    status
    user {
      first_name
      last_name
      middle_name
    }
    characterization {
      character {
        name
        title {
          name
        }
      }
    }
    essay {
      title {
        name
        author {
          first_name
          middle_name
          last_name
        }
      }
    }
  }
`

export const UNREVISED_WORKS = gql<Data<UnrevisedWorks>, Vars<UnrevisedWorks>>`
  ${UNREVISED_WORK_DATA_FRAGMENT}

  subscription unrevisedWorks {
    works(
      order_by: [{ status: asc }, { created_at: desc }]
      where: { status: { _in: [pending, inReview] } }
    ) {
      id
      teacher_id
      updated_at
      ...UnrevisedWorkData
    }
  }
`

export type UnrevisedWorkData = Omit<UnrevisedWork, 'id' | 'updated_at'> & WorkData

type UnrevisedWorkQuery = Query<'works_by_pk', UnrevisedWorkData | null, { workID: number }>

export const UNREVISED_WORK = gql<Data<UnrevisedWorkQuery>, Vars<UnrevisedWorkQuery>>`
  ${UNREVISED_WORK_DATA_FRAGMENT}

  query unrevisedWork($workID: Int!) {
    works_by_pk(id: $workID) {
      teacher_id
      content
      ...UnrevisedWorkData
    }
  }
`

export type WorkStatus = 'draft' | 'pending' | 'inReview' | 'approved' | 'rejected'

interface UpdateWorkStatusVars {
  workID: number
  status: WorkStatus
}

type UpdateWorkStatus = Query<'update_works_by_pk', Typename | null, UpdateWorkStatusVars>

export const UPDATE_WORK_STATUS = gql<Data<UpdateWorkStatus>, Vars<UpdateWorkStatus>>`
  mutation updateWorkStatus($workID: Int!, $status: work_status_enum!) {
    update_works_by_pk(pk_columns: { id: $workID }, _set: { status: $status }) {
      __typename
    }
  }
`

type County = ID<string> & Namer
type Counties = Query<'counties', County[]>

export const COUNTIES = gql<Data<Counties>, Vars<Counties>>`
  query counties {
    counties {
      id
      name
    }
  }
`

interface Emailer {
  email: string
}

interface SchoolName extends Namer {
  short_name: string
}

export type School = ID & SchoolName

type Schools = Query<'schools', School[], { countyID?: string }>

export const SCHOOLS = gql<Data<Schools>, Vars<Schools>>`
  query schools($countyID: String = "AB") {
    schools(where: { county_id: { _eq: $countyID } }) {
      id
      name
      short_name
    }
  }
`

type AssociationUser = ID &
  FullNamer &
  Emailer & {
    school: Omit<School, 'id'>
  }

const ASSOCIATION_USER_FRAGMENT = gql`
  fragment AssociationUser on users {
    id
    first_name
    middle_name
    last_name
    email
    school {
      name
      short_name
    }
  }
`

const ASSOCIATION_TEACHER_FRAGMENT = gql`
  ${ASSOCIATION_USER_FRAGMENT}

  fragment AssociationTeacher on teacher_student_associations {
    teacher {
      user {
        ...AssociationUser
      }
    }
  }
`

export type TeacherAssociationStatus = 'pending' | 'approved' | 'rejected'

type AssociationData<T extends 'teacher' | 'student'> = {
  initiatior_id: number
} & {
  // eslint-disable-next-line no-unused-vars
  [key in T]: {
    user: AssociationUser
  }
}

type Associations<T extends 'teacher' | 'student'> = Query<
  'teacher_student_associations',
  AssociationData<T>[],
  { status?: TeacherAssociationStatus }
>

export const TEACHER_ASSOCIATIONS = gql<
  Data<Associations<'teacher'>>,
  Vars<Associations<'teacher'>>
>`
  ${ASSOCIATION_TEACHER_FRAGMENT}

  query teacherAssociations($status: teacher_student_association_status_enum = approved) {
    teacher_student_associations(where: { status: { _eq: $status } }) {
      initiator_id
      ...AssociationTeacher
    }
  }
`

export const STUDENT_ASSOCIATIONS = gql<
  Data<Associations<'student'>>,
  Vars<Associations<'student'>>
>`
  ${ASSOCIATION_USER_FRAGMENT}

  query studentAssociations($status: teacher_student_association_status_enum = approved) {
    teacher_student_associations(where: { status: { _eq: $status } }) {
      initiator_id
      student {
        user {
          ...AssociationUser
        }
      }
    }
  }
`

export interface Teacher {
  user: FullNamer &
    Emailer & {
      school: Omit<School, 'id'>
    }
}

type WorksSingleData = ID & {
  created_at: string
  updated_at: string | null
  teacher: Teacher | null
} & (
    | {
        characterization: null
        essay: {
          title: Namer
        }
      }
    | {
        essay: null
        characterization: {
          character: Namer
        }
      }
  )

type Works = Query<'works', WorksSingleData[], { userID: number; status: WorkStatus }>

export const WORKS = gql<Data<Works>, Vars<Works>>`
  subscription works($userID: Int!, $status: work_status_enum!) {
    works(where: { _and: [{ user_id: { _eq: $userID } }, { status: { _eq: $status } }] }) {
      id
      created_at
      updated_at
      teacher {
        user {
          first_name
          middle_name
          last_name
          email
          school {
            name
            short_name
          }
        }
      }
      essay {
        title {
          name
        }
      }
      characterization {
        character {
          name
        }
      }
    }
  }
`
