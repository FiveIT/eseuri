# Template

Pentru a utiliza acest template, folosește [Docker][1] și [Visual Studio Code][2] cu extensia [Remote Containers][3].

Dacă ești pe Windows, va trebui să instalezi înainte de toate [Windows Subsystem for Linux 2][4]. Este important să clonezi repository-ul pe filesystem-ul WSL-ului, altfel configurarea nu va funcționa cum trebuie!

După clonare, rulează scriptul `config_credentials` în WSL, fără a deschide proiectul în VSCode, respectiv container:

```sh
./config_credentials
```

și urmărește instrucțiunile de pe ecran. Dacă ți se cere să introduci ceva, fie introduci opțiunea cu literă mare (dacă ai de ales dintre `(y/N)`, scrii `N`), fie nu scrii nimic (dacă nu ți se prezintă o alegere). Când te întreabă de proiectul Google Cloud pe care dorești să îl selectezi, scrii numărul corespunzător proiectului nostru (ți se va preciza numele acestuia).

Urmărește apoi pașii precizați în [README-ul de pe frontend] pentru a finaliza configurarea.

## Comenzi utile

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

[1]: https://www.docker.com/
[2]: https://code.visualstudio.com/
[3]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers
[4]: https://docs.microsoft.com/en-us/windows/wsl/install-win10
[readme-ul de pe frontend]: web/README.md
