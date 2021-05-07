export type { BlobPropsInput } from '$/components'

export type Role = 'student' | 'teacher'

export type Theme = 'white' | 'default'

export type WorkType = 'essay' | 'characterization'

export type UserRevision = 'yours' | 'anybody'

export function isWorkType(s: string): s is WorkType {
  return s === 'essay' || s === 'characterization'
}

export function isNonNullable<T>(v: T): v is NonNullable<T> {
  return v != null
}

export type Status = 'InLucru' | 'InAsteptare' | 'Aprobate' | 'Respinse' | 'InRevizuire'

export type AssociateStatus = 'Incoming' | 'Accepted' | 'Rejected' | 'Pending'

export function whoseUnrevWork(s: string): s is UserRevision {
  return s === 'yours' || s === 'anybody'
}

export interface WorkSummary {
  readonly name: string
  readonly url: string
  readonly creator: string
  readonly type: WorkType
  readonly work_count: number
}

export type Nullable<T> = T | null | undefined
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

export interface Associate {
  readonly status: AssociateStatus
  readonly name: string
  readonly email: string
  readonly school: string
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

export interface UserStatus {
  id: number
  isRegistered: boolean
  role: Role
}

export type NotificationStatus = 'success' | 'error' | 'info'

export interface Notification {
  status: NotificationStatus
  /**
   * The headline of the notification. It is a short summary
   * of the reason the notification appeared.
   */
  message: string
  /**
   * More details about the cause of the notification. It is
   * shown when the notification box is hovered over.
   */
  explanation?: string
}

export interface FullNamer {
  first_name: string
  middle_name: string | null
  last_name: string
}

export type Timeout = ReturnType<typeof setTimeout>
