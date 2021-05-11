import type { WorkType, Role, Bookmark, Lucrari, Associate } from '$/lib'

interface TranslationArticulation {
  singular: string
  plural: string
}

interface Translation {
  articulate: TranslationArticulation
  inarticulate: TranslationArticulation
}

type TranslationRecord<T extends string> = Record<string, Record<T, Translation>>

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

export const bookmarks: Bookmark[] = JSON.parse(`[
  {
    "type": "Eseu",
    "bookmarkname": "Aberatii",
    "subject": "Ion",
    "time": "12:55 21 Aprilie 2021"
  },
  {
    "type": "Eseu",
    "bookmarkname": "Koko",
    "subject": "Ion",
    "time": "12:55 21 Aprilie 2021"
  },
  {
    "type": "Eseu",
    "bookmarkname": "Koko",
    "subject": "Ion",
    "time": "12:55 21 Aprilie 2021"
  },
  {
    "type": "Eseu",
    "bookmarkname": "Kokvcavavcao",
    "subject": "vav",
    "time": "12:55 21 Aprilie 2021"
  }
]`)

export const asociates: Associate[] = JSON.parse(`[
  {
    "status": "Pending",
    "name": "Mircea Ioan Andreescu",
    "email": "mioan.a@gmail.com",
    "school": "Col Nat „M. Eminescu” Iasi"
  },
  {
    "status": "Accepted",
    "name": "Mircea Ioan Andreescu",
    "email": "mioan.a@gmail.com",
    "school": "Col Nat „M. Eminescu” Iasi"
  },  
  {
    "status": "Incoming",
    "name": "Mircea Ioan Andreescu",
    "email": "mioan.a@gmail.com",
    "school": "Col Nat „M. Eminescu” Iasi"
  },
  {
    "status": "Accepted",
    "name": "Mircea Ioan Andreescu",
    "email": "mioan.a@gmail.com",
    "school": "Col Nat „M. Eminescu” Iasi"
  },
  {
    "status": "Rejected",
    "name": "Mircea Ioan Andreescu",
    "email": "mioan.a@gmail.com",
    "school": "Col Nat „M. Eminescu” Iasi"
  },
  {
    "status": "Accepted",
    "name": "Mircea Ioan Andreescu",
    "email": "mioan.a@gmail.com",
    "school": "Col Nat „M. Eminescu” Iasi"
  }

]`)

export const lucrari: Lucrari[] = JSON.parse(`[
  {
    "status": "Respinse",
    "type": "Eseu",
    "teacher": "Mos Martin",
    "subject": "Ion",
    "time": "12:55 21 Aprilie 2021"
  },
  {
    "status": "Aprobate",
    "type": "Eseu",
    "teacher": "Mos Martin",
    "subject": "Ion",
    "time": "12:55 21 Aprilie 2021"
  },
  {
    "status": "Respinse",
    "type": "Eseu",
    "teacher": "Mos Martin",
    "subject": "Ion",
    "time": "12:55 21 Aprilie 2021"
  },
  {
    "status": "Respinse",
    "type": "Eseu",
    "teacher": "Mos Martin",
    "subject": "vav",
    "time": "12:55 21 Aprilie 2021"
  }
]`)
