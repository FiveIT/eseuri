export type { BlobPropsInput } from './components/blob/internal/store'

export type Role = 'student' | 'teacher'

export type Theme = 'white' | 'default'

export type WorkType = 'essay' | 'characterization'

export type UserRevision = 'yours' | 'anybody'

export function isWorkType(s: string): s is WorkType {
  return s === 'essay' || s === 'characterization'
}

export type Status =
  | 'InLucru'
  | 'InAsteptare'
  | 'Aprobate'
  | 'Respinse'
  | 'InRevizuire'
export function whoseUnrevWork(s: string): s is UserRevision {
  return s === 'yours' || s === 'anybody'
}

export interface Work {
  readonly name: string
  readonly creator: string
  readonly type: WorkType
  readonly work_count: number
}
export interface Bookmark {
  readonly type: string
  readonly bookmarkname: string
  readonly subject: string
  readonly time: string
}
export interface Lucrari {
  readonly status: Status
  readonly type: string
  readonly teacher: string
  readonly subject: string
  readonly time: string
}
export interface UnrevisedWork {
  readonly users_all: {
    readonly first_name: string
    readonly middle_name: string
    readonly last_name: string
  }
  readonly teacher: string
  readonly essay: {
    readonly title: {
      readonly name: string
      readonly author: {
        readonly first_name: string
        readonly middle_name: string
        readonly last_name: string
      }
    }
  }
  readonly characterization: {
    readonly character: {
      readonly name: string
      readonly title: {
        readonly name: string
      }
    }
  }
}
