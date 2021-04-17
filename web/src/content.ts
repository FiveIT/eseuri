import type { Work, WorkType } from './types'

interface TranslationArticulation {
  singular: string
  plural: string
}

interface Translation {
  articulate: TranslationArticulation
  inarticulate: TranslationArticulation
}

export const workTypeTranslation: Record<
  string,
  Record<WorkType, Translation>
> = {
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

export default (JSON.parse(`[
  {
    "name": "Nechifor Lipan",
    "creator": "Baltagul",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Vitoria Lipan",
    "creator": "Baltagul",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Ana",
    "creator": "Ion",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Florica",
    "creator": "Ion",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "George Bulbuc",
    "creator": "Ion",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Ion",
    "creator": "Ion",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Titu Herdelea",
    "creator": "Ion",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Vasile Baciu",
    "creator": "Ion",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Gavrilescu",
    "creator": "La țigănci",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Allan",
    "creator": "Maitreyi",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Ghiță",
    "creator": "Moara cu noroc",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Lică Sămădăul",
    "creator": "Moara cu noroc",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Catrina",
    "creator": "Moromeții",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Moromete",
    "creator": "Moromeții",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Niculae Moromete",
    "creator": "Moromeții",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Agamemnon Dandanache",
    "creator": "O scrisoare pierdută",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Farfuridi",
    "creator": "O scrisoare pierdută",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Ghită Pristanda",
    "creator": "O scrisoare pierdută",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Nae Cațavencu",
    "creator": "O scrisoare pierdută",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Ștefan Tipătescu",
    "creator": "O scrisoare pierdută",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Zoe Trahanache",
    "creator": "O scrisoare pierdută",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Andrei Pietraru",
    "creator": "Suflete tari",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Ela",
    "creator": "Ultima noapte de dragoste, întâia noapte de război",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Ștefan Gheorghidiu",
    "creator": "Ultima noapte de dragoste, întâia noapte de război",
    "type": "characterization",
    "work_count": 0
  },
  {
    "name": "Act venețian",
    "creator": "Camil Petrescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Jocul ielelor",
    "creator": "Camil Petrescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Patul lui Procust",
    "creator": "Camil Petrescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Suflete tari",
    "creator": "Camil Petrescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Ultima noapte de dragoste, întâia noapte de război",
    "creator": "Camil Petrescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Alexandru Lăpușneanu",
    "creator": "Costache Negruzzi",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Lacustră",
    "creator": "George Bacovia",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Plumb",
    "creator": "George Bacovia",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Sonet",
    "creator": "George Bacovia",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Beitul Ioanide",
    "creator": "George Călinescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Enigma Otiliei",
    "creator": "George Călinescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Moartea lui Fulger",
    "creator": "George Coșbuc",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Umbra lui Mircea la Cozia",
    "creator": "Grigore Alexandrescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Mara",
    "creator": "Ioan Slavici",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Moara cu noroc",
    "creator": "Ioan Slavici",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Joc secund",
    "creator": "Ion Barbu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Riga Crypto și lapona Enigel",
    "creator": "Ion Barbu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Povestea lui Harap-Alb",
    "creator": "Ion Creangă",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "La hanul lui Mânjoală",
    "creator": "Ion Luca Caragiale",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "O scrisoare pierdută",
    "creator": "Ion Luca Caragiale",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Aci sosi de vremuri",
    "creator": "Ion Pillat",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Ora fântânilor",
    "creator": "Ion Vinea",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Ion",
    "creator": "Liviu Rebreanu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Pădurea spânzuraților",
    "creator": "Liviu Rebreanu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Dați-mi un trup, voi munților",
    "creator": "Lucian Blaga",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Eu nu strivesc corola de minuni a lumii",
    "creator": "Lucian Blaga",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Izvorul nopții",
    "creator": "Lucian Blaga",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Meșterul Manole",
    "creator": "Lucian Blaga",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Cel mai iubit dintre pământeni",
    "creator": "Marin Preda",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Moromeții",
    "creator": "Marin Preda",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Iona",
    "creator": "Marin Sorescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Floare albastră",
    "creator": "Mihai Eminescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Glossă",
    "creator": "Mihai Eminescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Luceafărul",
    "creator": "Mihai Eminescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Odă",
    "creator": "Mihai Eminescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Sărmanul Dionis",
    "creator": "Mihai Eminescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Scrisoarea I",
    "creator": "Mihai Eminescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Baltagul",
    "creator": "Mihail Sadoveanu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Creanga de aur",
    "creator": "Mihail Sadoveanu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Hanul Ancuței",
    "creator": "Mihail Sadoveanu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "La țigănci",
    "creator": "Mircea Eliade",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Maitreyi",
    "creator": "Mircea Eliade",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Nuntă în cer",
    "creator": "Mircea Eliade",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Zmeura de câmpie",
    "creator": "Mircea Nedelciu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Cântec",
    "creator": "Nichita Stănescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Către Galateea",
    "creator": "Nichita Stănescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "În dulcele stil clasic",
    "creator": "Nichita Stănescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Leoaică tânără, iubirea",
    "creator": "Nichita Stănescu",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "De demult",
    "creator": "Octavian Goga",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Rugăciune",
    "creator": "Octavian Goga",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Flori de mucigai",
    "creator": "Tudor Arghezi",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Psalmul III - Tare sunt singur, Doamne, și pieziș!...",
    "creator": "Tudor Arghezi",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Psalmul VI - Te drămuiesc în zgomot și-n tăcere...",
    "creator": "Tudor Arghezi",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Testament",
    "creator": "Tudor Arghezi",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "Malul Siretului",
    "creator": "Vasile Alecsandri",
    "type": "essay",
    "work_count": 0
  },
  {
    "name": "În grădina Ghetsemani",
    "creator": "Vasile Voiculescu",
    "type": "essay",
    "work_count": 0
  }
]`) as Work[]).map(work => ({
  ...work,
  work_count: (Math.random() * 10000) | 0,
}))
