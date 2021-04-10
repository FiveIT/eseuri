# Eseuri

## Instrucțiuni de configurare

Pentru a putea dezvolta în acest mediu, ai nevoie de [Docker][1] și [Visual Studio Code][2] cu extensia [Remote Containers][3].

Dacă ești pe Windows, va trebui să instalezi înainte de toate [Windows Subsystem for Linux 2][4]. Este important să clonezi repository-ul pe filesystem-ul WSL-ului, altfel configurarea nu va funcționa cum trebuie!

După clonare, rulează scriptul `config_credentials` în WSL, fără a deschide proiectul în VSCode, respectiv container:

```sh
./config_credentials
```

și urmărește instrucțiunile de pe ecran. Dacă ți se cere să introduci ceva, fie introduci opțiunea cu literă mare (dacă ai de ales dintre `(y/N)`, scrii `N`), fie nu scrii nimic (dacă nu ți se prezintă o alegere). Când te întreabă de proiectul Google Cloud pe care dorești să îl selectezi, scrii numărul corespunzător proiectului nostru (ți se va preciza numele acestuia).

Urmărește apoi pașii precizați în [README-ul de pe frontend] pentru a finaliza configurarea.

## Comenzi și informații utile

### Pentru dezvoltare

Rulează proiectul în development:

```sh
make -j2 dev
```

Rulează toate testele:

```sh
make -j2 test
```

Deschide dashboard-ul Cypress și proiectul, în paralel:

```sh
make -j3 e2e
```

Pentru a rula comenzile pnpm (specificate în [README-ul de pe frontend]), schimbă mai întâi directorul curent în [web](web):

```sh
cd web
```

Vezi [README-ul de pe frontend] pentru restul comenzilor.

### Pentru lucrul cu baza de date

Pentru a accesa consola Hasura, deschide o pagină în browser la adresa `http://localhost:8080`.

Dacă vrei să inspectezi baza de date locală PostgreSQL, te poți conecta la ea cu următorul URL de conectare (dinafara container-ului de development, de exemplu cu [Jetbrains DataGrip][5]):

```txt
postgres://postgres:sarmale@localhost:5432/postgres
```

Înlocuiește `localhost` cu `db` pentru a te conecta folosind un serviciu din container.

#### Manageriere migrări și metadate

Migrările și metadatele se află în folderul `db`.

Acestea se aplică local automat la deschiderea containerelor.

Pentru a le aplica manual (asupra bazei de date de producție, de exemplu, sau local, după schimbări):

```sh
cd /workspace/db # comenzile trebuie rulate în folderul `db`, unde se află fișierul `config.yaml`

ENDPOINT=<endpoint-ul Hasura dorit>
ADMIN_SECRET=<admin secret-ul pentru endpoint-ul respectiv>

hasura metadata apply --endpoint=$ENDPOINT --admin-secret=$ADMIN_SECRET
hasura migrate apply --endpoint=$ENDPOINT --admin-secret=$ADMIN_SECRET
```

Dacă endpoint-ul Hasura din producție este configurat cu o bază de date Heroku, atunci trebuie făcută temporar următoare schimbare în `db/metadata/databases.yaml`:

```diff
configuration:
  connection_info:
    database_url:
-     from_env: HASURA_GRAPHQL_DATABASE_URL
+     from_env: HEROKU_DATABASE_URL
```

Nu salvați schimbarea în Git!

[1]: https://www.docker.com/
[2]: https://code.visualstudio.com/
[3]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers
[4]: https://docs.microsoft.com/en-us/windows/wsl/install-win10
[5]: https://www.jetbrains.com/datagrip/
[readme-ul de pe frontend]: web/README.md
