import { status, fromQuery } from '$/lib'
import client from '$/graphql/client'
import { TEACHER_ASSOCIATIONS } from '$/graphql/queries'

import { from, of, concat } from 'rxjs'
import { map, switchMap, catchError } from 'rxjs/operators'

export const getRequestedTeachers = () =>
  concat(
    of(undefined),
    from(status()).pipe(
      switchMap(({ role }) =>
        role === 'student'
          ? fromQuery(client, TEACHER_ASSOCIATIONS).pipe(map(v => v.teacher_student_associations))
          : of([])
      ),
      catchError(() => of(null))
    )
  )
