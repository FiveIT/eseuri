# Eseuri frontend

Acest proiect utilizează `pnpm`.

Instalează dependențele:

```sh
pnpm i
```

Următoarele comenzi nu sunt relevante dacă rulezi serverul de development din container, utilizând comenzile `make` precizate în README-ul din rădăcina proiectului. Dacă acesta este cazul, sari direct la [configurarea cypress](#configurarea-cypress).

Rulează serverul de development:

```sh
pnpm dev
```

Compilează fișierele pentru producție:

```sh
pnpm build
```

Servește fișierele de producție:

```sh
pnpm serve-vite
```

Formatează codul:

```sh
pnpm format
```

Testează codul:

```sh
pnpm t
```

Deschide dashboard-ul Cypress:

```sh
pnpm e2e
```

## Informații utile

Pentru a interoga backend-ul și baza de date ale aplicației, sunt disponibile următoarele variabile:

```js
import.meta.env.VITE_FUNCTIONS_URL // backend
import.meta.env.VITE_HASURA_GRAPHQL_ENDPOINT // baza de date
```

## Configurarea Cypress

Pentru a putea rula Cypress, mai trebuie făcuți următorii pași (înainte de a deschide container-ul):

- Instalează [VcXsrv](https://sourceforge.net/projects/vcxsrv/)
- Rulează programul XLaunch cu următoarele setări:
  1. Multiple windows
  1. Start no client
  1. `Native opengl` debifat, `Disable access control` bifat

## Probleme

### Variante Tailwind

Configurarea funcționează foarte bine, nu există probleme la încărcarea conținutului, reîncărcarea paginii sau la build în general.

Există totuși o particularitate la procesarea CSS: variantele Tailwind
(`hover:`, `focus:` etc.) se pot folosi numai în clase. În combinație cu
directiva `@apply` build-ul va eșua. De exemplu, următorul cod nu va
fi compilat cu succes:

```css
.elem {
  @apply bg-white border rounded;
  @apply hover:bg-red;
}
```

Pentru a obține același efect, fie scrieți stilurile în markup:

```html
<div class="elem bg-white border rounded hover:bg-red" />
```

fie regândiți codul: extrageți clasele duplicate într-un component separat, de exemplu.

### Testare cod

La momentul actual, configurarea Jest eșuează în a rula teste pe componentele Svelte. Fișierele `.js` sau `.ts` merg, în schimb.
