import type { WorkType, Role } from './types'

interface TranslationArticulation {
  singular: string
  plural: string
}

interface Translation {
  articulate: TranslationArticulation
  inarticulate: TranslationArticulation
}

type TranslationRecord<T extends string> = Record<
  string,
  Record<T, Translation>
>

export const workTypeTranslation: TranslationRecord<WorkType> = {
  ro: {
    characterization: {
      articulate: {
        singular: 'caracterizarea',
        plural: 'caracterizările',
      },
      inarticulate: {
        singular: 'caracterizare',
        plural: 'caracterizări',
      },
    },
    essay: {
      articulate: {
        singular: 'eseul',
        plural: 'eseurile',
      },
      inarticulate: {
        singular: 'eseu',
        plural: 'eseuri',
      },
    },
  },
}

export const roleTranslation: TranslationRecord<Role> = {
  ro: {
    student: {
      articulate: {
        singular: 'elevul',
        plural: 'elevii',
      },
      inarticulate: {
        singular: 'elev',
        plural: 'elevi',
      },
    },
    teacher: {
      articulate: {
        singular: 'profesorul',
        plural: 'profesorii',
      },
      inarticulate: {
        singular: 'profesor',
        plural: 'profesori',
      },
    },
  },
}
