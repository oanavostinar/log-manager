Proiectul urmareste crearea unei aplicatii care ofera utilizatorului instrumente pentru centralizarea, filtrarea si analiza logurilor de sistem si aplicatii pe distributii Linux. Scriptul este scris in Bash si este compatibil atat cu Ubuntu/Linux Mint, cat si cu Fedora. La rulare, acesta detecteaza automat distributia si extrage logurile corespunzatoare.

In directorul loguri_centralizate sunt salvate toate fisierele de log colectate de la sistem: loguri de sistem (syslog/messages), autentificari (auth.log), sesiuni (wtmp), instalari de pachete (apt/dnf), loguri de server web (apache2, nginx) si export complet al jurnalului (journalctl).

Aplicatia permite utilizatorului sa filtreze logurile dupa cuvant cheie, data sau nivel de severitate (error, warning). De asemenea, ofera o sectiune speciala de detectare automata a problemelor de securitate, precum autentificari esuate, utilizare de sudo, sau instalarea unor anumite unelte (ex: nmap, gcc, nc).

Afisarea rezultatelor se face direct in terminal cu un meniu interactiv pentru o usoara interactiune a utilizatorului cu aplicatia
