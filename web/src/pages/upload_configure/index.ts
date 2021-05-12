import { fromQuery, isNonNullable, status } from '$/lib'
import client from '$/graphql/client'
import { TEACHER_ASSOCIATIONS } from '$/graphql/queries'

import { of, concat, defer } from 'rxjs'
import { map, switchMap, catchError, filter } from 'rxjs/operators'

export const requestedTeachers = defer(() =>
  concat(
    of(undefined),
    status.pipe(
      filter(isNonNullable),
      switchMap(({ role }) =>
        role === 'student'
          ? fromQuery(client, TEACHER_ASSOCIATIONS).pipe(map(v => v.teacher_student_associations))
          : of([])
      ),
      catchError(() => of(null))
    )
  )
)
