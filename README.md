# Eseuri

## Instrucțiuni de configurare

Pentru a putea dezvolta în acest mediu, ai nevoie de [Docker][1] și [Visual Studio Code][2] cu extensia [Remote Containers][3].

Dacă ești pe Windows, va trebui să instalezi înainte de toate [Windows Subsystem for Linux 2][4]. Este important să clonezi repository-ul pe filesystem-ul WSL-ului, altfel configurarea nu va funcționa cum trebuie!

După clonare, rulează scriptul `config_credentials` în WSL, fără a deschide proiectul în VSCode, respectiv container:

```sh
./config_credentials
```

și urmărește instrucțiunile de pe ecran. Dacă ți se cere să introduci ceva, fie introduci opțiunea cu literă mare (dacă ai de ales dintre `(y/N)`, scrii `N`), fie nu scrii nimic (dacă nu ți se prezintă o alegere). Când te întreabă de proiectul Google Cloud pe care dorești să îl selectezi, scrii numărul corespunzător proiectului nostru (ți se va preciza numele acestuia).

Înainte de a deschide proiectul, creează în rădăcina acestuia un fișier `.env.local`, care va conține următoarele variabile de mediu:

```sh
# Cheia de administrator pentru instanța Hasura
HASURA_GRAPHQL_ADMIN_SECRET=
# Secretul JWT utilizat de Hasura pentru a valida și decoda token-urile de autentificare
HASURA_GRAPHQL_JWT_SECRET=
# Domeniul Auth0 utilizat pentru development, aplicație Auth0 configurată în următorii pași.
# Variabilele cu "VITE_" în față sunt vizibile pentru bundler-ul clientului web.
VITE_AUTH0_DOMAIN=
# ID-ul proiectului Auth0
VITE_AUTH0_CLIENT_ID=
# Audiența API-ului aplicației Auth0
VITE_AUTH0_AUDIENCE=
```

Dacă devcontainer-ul este deja deschis, după acești pași acesta va trebui repornit (apeși `Ctrl + Shift + P` în VSCode, scrii `rebuild` si selectezi opțiunea `Rebuild container`). Cu ajutorul instrucțiunilor de mai jos vei obține valorile variabilelor de mai sus.

Pentru a putea utiliza local Auth0 în dezvoltare și testare, este nevoie să-ți creezi un tenant propriu Auth0, care să utilizeze instanța locală Hasura. După crearea acestuia, navighează la `Applications > Applications > <numele aplicației implicite>`, unde vei atribui proprietății `Application Type` din secțiunea `Application Properties` valoarea `Single Page Application`. Apoi, din secțiunea `Basic Information`, copiezi valorile `Domain` și `Client ID` în variabilele de mediu din `.env.local` `VITE_AUTH0_DOMAIN`, respectiv `VITE_AUTH0_CLIENT_ID`.

Ca să finalizezi configurarea aplicației, trebuie să adaugi în câmpurile `Allowed Callback URLs`, `Allowed Logout URLs`, `Allowed Web Origins`, `Allowed Origins (CORS)` adresele tale locale care trebuie să poată folosi serviciul Auth0 (de exemplu, `http://localhost:3000`).

După aceea, navighezi din meniul principal la `Applications > APIs`, și copiezi proprietatea `API Audience` a API-ului creat implicit în variabila de mediu `VITE_AUTH0_AUDIENCE`.

Continuând configurarea, atribuie variabilei de mediu `HASURA_GRAPHQL_ADMIN_SECRET` o valoare arbitrară.

Pentru a obține valoarea variabilei de mediu `HASURA_GRAPHQL_JWT_SECRET`, copiază în clipboard domeniul aplicației tale Auth0, apoi, într-o pagină web, navighează la [website-ul Hasura pentru configurarea JWT][5], selectezi "Auth0" ca și provider, introduci domeniul și apeși "Generate Config". După generare, copiezi valoarea afișată, și o introduci în `.env.local` astfel:

```sh
# Este important să o înconjori cu ghilimele simple (single-quotes)
HASURA_GRAPHQL_JWT_SECRET='valoarea copiata...'
```

Proiectul Auth0 este acum configurat, însă nu poate folosi instanța locală Hasura. Pentru a configura aceasta, deschide mai întâi în VSCode devcontainer-ul.

Ca instanța Hasura să fie accesibilă dinafara sistemului tău, este nevoie să-i atribui un endpoint public. Acest lucru se poate face configurând port forwarding pe portul 8080 din router-ul tău wireless, și apoi utilizând `<adresa ta IP>:8080` pentru a te conecta la instanța Hasura, sau cu ajutorul unui serviciu ca [ngrok][7]. Metoda pe care o recomand folosește serviciul gratuit `localhost.run`[8] și SSH. Pentru a utiliza această metodă, urmează următorii pași într-un terminal local (WSL sau Linux), nu în container!

Mai întâi, [generează chei de securitate pentru SSH][9], dacă nu ai făcut-o vreodată până acum. Apoi, execută următoarea comandă, pentru a publica endpoint-ul Hasura prin localhost.run:

```sh
ssh -R 80:localhost:8080 localhost.run
```

Va apărea pe ecran, printre altele, o linie asemănătoare cu următoarea:

```sh
aeb8f6d9182aeb.localhost.run tunneled with tls termination, https://aeb8f6d9182aeb.localhost.run
```

URL-ul ce începe cu `https` este endpoint-ul public pentru Hasura. Dacă îl accesezi, se va deschide consola Hasura, care te va pune să introduci admin-secret-ul instanței. Nu este nevoie să faci acest lucru, iar de altfel nu va fi nevoie să folosești local endpoint-ul public. Endpoint-ul utilizat în container este configurat într-o variabilă de mediu numită `HASURA_GRAPHQL_ENDPOINT`, care poate fi utilizată în cod. Este necesar să păstrezi deschis SSH-ul cât timp ai nevoie de Auth0. Linkul se schimbă automat după o perioadă de timp, așa că periodic va trebui reintrodusă variabila `HASURA_GRAPHQL_ENDPOINT` în Auth0.

După ce ai obținut un endpoint public pentru instanța Hasura, în VSCode, într-un terminal din container, rulează următoarele comenzi:

```sh
cd scripts
pnpm i
pnpm build
```

Acestea vor compila regula Auth0 utilizată pentru introducerea utilizatorilor în baza de date și detectarea și atribuirea rolurilor Hasura potrivite pentru aceștia. După compilare, copiază conținutul fișierului `rule.js`, iar apoi navighează la pagina tenant-ului tău Auth0, de unde vei naviga apoi la secțiunea `Auth Pipeline > Rules`. Acolo creează o regulă nouă, numită "Hasura login", și lipește conținutul fișierului `rule.js` în secțiunea destinată codului regulii.

Salvează regula, și întoarce-te la meniul principal pentru reguli. În secțiunea "Settings", adaugă următoarele valori:

- `HASURA_GRAPHQL_ADMIN_SECRET`, cu valoarea variabilei de mediu din `.env.local` cu același nume
- `HASURA_GRAPHQL_ENDPOINT`, cu URL-ul public spre instanța ta Hasura locală obținut în pașii anteriori

Configurarea este acum finalizată, iar baza de date și Auth0 sunt funcționale în dezvoltare!

NOTĂ: Dacă nu ai cum să te ocupi individual de acest proces (nu ai acces la proiectul Auth0 al organizației și/sau nu reușești să urmezi pașii), roagă pe cineva care poate să te asiste.

De altfel, Github Actions va folosi tot timpul regula Auth0 de autentificare de pe `master`, iar dacă regula ta locală este diferită vor putea exista erori. Nu există o rezolvare evidentă a acestei probleme, așa că la un pull request va trebui schimbată manual regula utilizată de Github.

Urmează apoi pașii din [README-ul de pe frontend] pentru a finaliza configurarea, dacă ai nevoie de aplicația de client.

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

### Pentru lucrul cu baza de date și Auth0

Înainte de toate, nu uita să faci publică instanța locală Hasura!

Pentru a accesa consola Hasura, deschide o pagină în browser la adresa `http://localhost:8080`. Indiferent dacă o accesezi local sau prin endpoint-ul public, admin-secret-ul configurat de tine este necesar.

Dacă vrei să inspectezi baza de date locală PostgreSQL, te poți conecta la ea cu următorul URL de conectare (dinafara container-ului de development, de exemplu cu [Jetbrains DataGrip][6]):

```txt
postgres://postgres:sarmale@localhost:5432/postgres
```

Înlocuiește `localhost` cu `db` pentru a te conecta folosind un serviciu din container.

#### Manageriere migrări și metadate

Migrările și metadatele se află în folderul `db`.

Acestea se aplică local automat la deschiderea containerelor.

Pentru a le aplica manual:

```sh
cd /workspace/db # comenzile trebuie rulate în folderul `db`, unde se află fișierul `config.yaml`

ENDPOINT=<endpoint-ul Hasura dorit>
ADMIN_SECRET=<admin secret-ul pentru endpoint-ul respectiv>

hasura metadata apply --endpoint=$ENDPOINT --admin-secret=$ADMIN_SECRET
hasura migrate apply --database-name=default --endpoint=$ENDPOINT --admin-secret=$ADMIN_SECRET
```

Este nevoie să specifici endpoint-ul și admin-secret-ul doar pentru alte instanțe Hasura, nu pentru cea locală (de exemplu cea din producție).

[1]: https://www.docker.com/
[2]: https://code.visualstudio.com/
[3]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers
[4]: https://docs.microsoft.com/en-us/windows/wsl/install-win10
[5]: https://hasura.io/jwt-config
[6]: https://www.jetbrains.com/datagrip/
[7]: https://ngrok.com/
[8]: http://localhost.run
[9]: https://docs.gitlab.com/ee/ssh/#generate-an-ssh-key-pair
[readme-ul de pe frontend]: web/README.md
