# Example — 3 minutes, before and after

Source: `2026-08-23 12-50-11-nosilence.mov`, first 3:00.070, French.
**18 cuts, 180.070s → 153.94s (32.3s removed).**

Blocks are the raw audio split on pauses > 0.30s; `src` is source time, `out` is
time in the render. Each block carries both transcripts, then every deletion made
inside it, then what survives.

**whisper** is what a normal ASR gives you — it silently deletes stutters and merges
repeated takes, because it was trained on cleaned captions. **ctc** (wav2vec2, no
language model) writes down what actually left your mouth, misspellings and all.
Most retakes below exist *only* in the ctc line. That is the whole point of the
second pass.

Rule ids:

| id | what it sees | evidence |
|---|---|---|
| `R1 verbatim restart` | phrase said twice, adjacent | whisper |
| `R2 script regression` | script alignment jumped backwards: a new take began | whisper + script |
| `D1 swallowed retake` | speech whisper transcribed as **nothing** | ctc vs whisper gap |
| `D3 restart (ctc anchor)` | phrase retried a moment later | ctc only |

Text quoted for `D1`/`D3` is ctc's spelling, so it looks misspelt on purpose.

---

## src [00:00.211 → 00:22.824]  ·  out [00:00.000 → 00:19.271]

- **whisper:** Je déteste le Fire Design. Je déteste le Fire Design. Le Magic Modern n'a plus rien à voir avec ce qu'il était et il est temps d'arrêter de se mentir. Toutes les prédictions se sont avérées vraies. Maintenant, un 7 sur 2, c'est des Univers Beyond Slope. En tant que joueur compétitif, je dois être constamment rappelé lors de toutes mes parties que Spider-Man, Avatar, Marvel et bien d'autres font maintenant partie.
- **ctc:** je déteste le fer disain je déteste le feeur disain le magique moderne na plus en avoir lexquilité et ét temps darrêter de ce montièr toute les prédictions se sont à vérivrés maintenant un cep sur deux cest de universe cest de universe bilion de slop en tant que joueur compétitif je dois être constamment rappelé lors de toutes mes parties que spadorban à vatard marvel et bien dautre font maintenant partie

**cut here:**

- ✂ **2.1s** `[00:00.200 → 00:02.300]` **D3 restart (ctc anchor)** · sim 96.0 — "je deteste le fer disain"
  <br>kept instead, from `00:02.340`: "je deteste le feeur disain le magique moderne na plus"
- ✂ **2.1s** `[00:00.211 → 00:02.312]` **R2 script regression** · sim 100.0 — "Je déteste le Fire Design."
  <br>kept instead, from `00:02.332`: "Je déteste le Fire Design. Le Magic Modern n'a plus rien à voir avec ce qu'il était et il "
- ✂ **1.0s** `[00:12.220 → 00:13.260]` **D3 restart (ctc anchor)** · sim 100.0 — "cest de universe"
  <br>kept instead, from `00:13.300`: "cest de universe bilion de slop"

**survives (ctc):** je déteste le feeur disain le magique moderne na plus en avoir lexquilité et ét temps darrêter de ce montièr toute les prédictions se sont à vérivrés maintenant un cep sur deux cest de universe bilion de slop en tant que joueur compétitif je dois être constamment rappelé lors de toutes mes parties que spadorban à vatard marvel et bien dautre font maintenant partie

## src [00:23.144 → 00:30.090]  ·  out [00:19.591 → 00:26.537]

- **whisper:** intégrante de Magic et les nouvelles cartes qui sortent ne sont pas intéressantes. J'en ai
- **ctc:** intégrantes de magique et les nouvellescartes qui sortes ne sont pas intéressantes jen ai rien à foutre que la vingtième carte qui se nobole et gagnent la partie enselo

*(untouched)*

## src [00:31.672 → 00:43.382]  ·  out [00:28.119 → 00:38.067]

- **whisper:** rien à foutre de la 20ème carte qui snowball et gagne la partie en solo si elle n'est pas gérée immédiatement. Avant, quand un adversaire jouait un Tarmogoyf, si je n'avais pas de removal en main, je pouvais prendre le temps de recevoir l'information
- **ctc:** ai réun a foutre de la vingtième carte qui snobole et gagne la partie enselo si elle nest pas géré immédiatement avant quen andversaire jouer un termogouf si je navais pas de rémouvole en main je pouvais prendre le temps je pouvais prendre le temps

**cut here:**

- ✂ **1.7s** `[00:40.900 → 00:42.620]` **D3 restart (ctc anchor)** · sim 87.1 — "main je pouvais prendre le temps"
  <br>kept instead, from `00:42.660`: "je pouvais prendre le temps de recevoir linformation respira u bon coup"

**survives (ctc):** ai réun a foutre de la vingtième carte qui snobole et gagne la partie enselo si elle nest pas géré immédiatement avant quen andversaire jouer un termogouf si je navais pas de rémouvole en je pouvais prendre le temps

## src [00:45.304 → 01:01.929]  ·  out [00:39.989 → 00:53.013]

- **whisper:** respirer un bon coup et essayer de concocter un plan de jeu sur deux ou trois tours pour naviguer la partie autour de ce thermogoyf. Tu pouvais vraiment utiliser tes points de vie comme une ressource alors que maintenant si tu fais face à un bilbo, un ragavan ou une psychic frog tu pries
- **ctc:** respira u bon coup et essayer de concocter un plan de jeu sur deux au trois tours pour naviguer la partie autour de ce tharmogoufhe u pouvait vraiment utiliser ces points de vue comme une ressource alors que maintenant cest ty fait face à un bile beau un ragavan ou une sa ékique frogue tu prixe juste pour piocher un rimvol le plura turix juse pour

**cut here:**

- ✂ **3.3s** `[00:58.820 → 01:02.100]` **D3 restart (ctc anchor)** · sim 85.4 — "tu prixe juste pour piocher un rimvol le plura turix juse pour"
  <br>kept instead, from `01:02.140`: "picher tupri juste pour picher un rivol le plus rapidement possible aussinon avoir un com "
- ✂ **1.2s** `[01:01.940 → 01:03.120]` **D1 swallowed retake** · sim 82.4 — "pour picher tupri"
  <br>kept instead, from `01:03.170`: "juste pour piocher un rimball le plus rapidement"

**survives (ctc):** respira u bon coup et essayer de concocter un plan de jeu sur deux au trois tours pour naviguer la partie autour de ce tharmogoufhe u pouvait vraiment utiliser ces points de vue comme une ressource alors que maintenant cest ty fait face à un bile beau un ragavan ou une sa ékique frogue

## src [01:03.170 → 01:17.097]  ·  out [00:53.063 → 01:06.990]

- **whisper:** juste pour piocher un rimball le plus rapidement possible ou sinon avoir un combo kill dans les deux prochains tours ou alors en dernier recours avoir son propre snowball qui est encore plus puissant. Pour que vous compreniez bien comment je catégorise et compare les périodes actuelles de magique
- **ctc:** juste pour picher un rivol le plus rapidement possible aussinon avoir un com bokil dans les deux prochains tours ou alors en darnier recours avoir son propre snobole qui a encore plus puissant pour que vous comprendez bien comment je catégorise et compart les périodes actueles de magique avec

**cut here:**

- ✂ **0.9s** `[01:17.140 → 01:18.040]` **D1 swallowed retake** · sim 75.0 — "avec sest"
  <br>kept instead, from `01:18.079`: "avec ce qui s'est passé précédemment. Voici comment"

**survives (ctc):** juste pour picher un rivol le plus rapidement possible aussinon avoir un com bokil dans les deux prochains tours ou alors en darnier recours avoir son propre snobole qui a encore plus puissant pour que vous comprendez bien comment je catégorise et compart les périodes actueles de magique

## src [01:18.079 → 01:26.830]  ·  out [01:07.072 → 01:14.681]

- **whisper:** avec ce qui s'est passé précédemment. Voici comment je catégorise les différentes ères de magie. La première période, c'est la période old school qui commence de 1993 et qui va jusqu'en 1995. Au niveau
- **ctc:** avec ce qui sest passé précédemment voici comment je catégorise les différentes zeres de magi la première période cest la période holscoul qui commencet de mille neuf cent quatre vingt treize et qui

**cut here:**

- ✂ **0.9s** `[01:17.140 → 01:18.040]` **D1 swallowed retake** · sim 75.0 — "avec sest"
  <br>kept instead, from `01:18.079`: "avec ce qui s'est passé précédemment. Voici comment"
- ✂ **1.6s** `[01:25.700 → 01:27.260]` **D3 restart (ctc anchor)** · sim 87.9 — "de mille neuf cent quatre vingt treize et qui valent"
  <br>kept instead, from `01:27.280`: "jusquen mille nuf cent quatre vingt quianze au niveau des cept sa"
- ✂ **0.3s** `[01:26.509 → 01:26.830]` **R1 verbatim restart** · sim 100.0 — "Au niveau"
  <br>kept instead, from `01:28.692`: "Au niveau"

**survives (ctc):** avec ce qui sest passé précédemment voici comment je catégorise les différentes zeres de magi la première période cest la période holscoul qui commencet

## src [01:28.692 → 01:52.936]  ·  out [01:16.125 → 01:37.747]

- **whisper:** Au niveau des sets, ça va de Alpha à The Dark. Et clairement, comme vous pouvez le constater, je n'ai pas joué à Magic pendant cette période, je n'étais même pas né. Mais d'après de ce que je comprends, et du peu que j'ai joué de ce format, c'est vraiment la période de bêta test, les tout débuts de Magic, où le jeu n'avait pas encore pu se former une identité. D'où l'explication de tous les effets un peu voies. La seconde période, c'est le Prémoderne de 1995 à 2003. Ça va
- **ctc:** au niveau des cept sa vate de halpha azodark et clairement comme vous pouvez e constater je nai pas joué àn matchipendant cette période je nétais même panate mais daprèsmais daprès de ce que ju mais daprès de ce que je comprends et du peu que jai joué de ce format cest vraiment la période de betatest les tout e début de magiques où le jeu navait pas encore pu se former une identité doù lexplication das tous les effets un peu voir la seconde période cest le prix moderne de mille neuf cent quatre vingt quinze

**cut here:**

- ✂ **1.8s** `[01:36.460 → 01:38.300]` **D3 restart (ctc anchor)** · sim 85.2 — "dapresmais dapres de ce que ju"
  <br>kept instead, from `01:38.340`: "mais dapres de ce que je comprends et du peu que jai"
- ✂ **3.4s** `[01:52.696 → 01:56.140]` **R2 script regression** · sim 96.2 — "Ça va de la quatrième édition de Scourge,"
  <br>kept instead, from `01:56.160`: "ça va de la quatrième édition à Scourge. Et pour moi, c'est vraiment la période où le jeu "

**survives (ctc):** au niveau des cept sa vate de halpha azodark et clairement comme vous pouvez e constater je nai pas joué àn matchipendant cette période je nétais même panate mais mais daprès de ce que je comprends et du peu que jai joué de ce format cest vraiment la période de betatest les tout e début de magiques où le jeu navait pas encore pu se former une identité doù lexplication das tous les effets un peu voir la seconde période cest le prix moderne de mille neuf cent

## src [01:53.577 → 02:10.457]  ·  out [01:37.747 → 01:49.489]

- **whisper:** de la quatrième édition de Scourge, ça va de la quatrième édition à Scourge. Et pour moi, c'est vraiment la période où le jeu a fini de mûrir et a cristallisé une identité bien distincte des autres périodes. Que ce soit avec le cadre, que ce soit avec le frame de la carte ou les arts...
- **ctc:** à deu mille trois çea va la quatrième édition de scours çea va la quatrième édétion à se courge et pour moi ces vrons la période où le jeu a fini de murir et à cristliseret à cristalie une identité bien distincte des autres période que ce soit avec le cadre que ce soit avec le freim de la carte où les artes

**cut here:**

- ✂ **3.4s** `[01:52.696 → 01:56.140]` **R2 script regression** · sim 96.2 — "Ça va de la quatrième édition de Scourge,"
  <br>kept instead, from `01:56.160`: "ça va de la quatrième édition à Scourge. Et pour moi, c'est vraiment la période où le jeu "
- ✂ **1.8s** `[01:53.820 → 01:55.600]` **D3 restart (ctc anchor)** · sim 86.6 — "trois cea va la quatrieme edition de"
  <br>kept instead, from `01:55.640`: "scours cea va la quatrieme edetion a se courge et pour moi"
- ✂ **1.3s** `[02:06.500 → 02:07.820]` **D3 restart (ctc anchor)** · sim 88.0 — "que ce soit avec le cadre"
  <br>kept instead, from `02:07.840`: "que ce soit avec le freim de la carte ou les artes"
- ✂ **1.3s** `[02:06.533 → 02:07.854]` **R2 script regression** · sim 89.4 — "Que ce soit avec le cadre,"
  <br>kept instead, from `02:07.874`: "que ce soit avec le frame de la carte ou les arts... ou le type d'art qui représente,"
- ✂ **0.8s** `[02:09.280 → 02:10.100]` **D3 restart (ctc anchor)** · sim 87.0 — "carte ou les"
  <br>kept instead, from `02:10.180`: "artes ou le type dartes qui"
- ✂ **3.3s** `[02:09.696 → 02:13.039]` **R2 script regression** · sim 73.2 — "ou les arts... ou le type d'art qui représente,"
  <br>kept instead, from `02:13.079`: "ou l'esthétique des arts qui représente vraiment cette période. On peut vraiment distingue"

**survives (ctc):** çea va la quatrième édétion à se courge et pour moi ces vrons la période où le jeu a fini de murir et à cristliseret à cristalie une identité bien distincte des autres période que ce soit avec le freim de la

## src [02:11.118 → 02:39.236]  ·  out [01:49.533 → 02:13.108]

- **whisper:** ou le type d'art qui représente, ou l'esthétique des arts qui représente vraiment cette période. On peut vraiment distinguer facilement une carte de la période pré-moderne, des périodes futures, et même de la période old school. Et ça, rien qu'en lisant la carte. Et on a la plupart des archétypes iconiques de Magic qui se sont conçus durant cette période, comme Goblin, Elf, Rainmator, Artifact, Artifact Prison, White Control, Red Deck Wins, The Rock, aka Vert Noir Midrange, Storm, etc.
- **ctc:** ou le type dartes qui représente ou lestetique des artes qui reprint ou lestétique des artes qui représente vraiment cette période on peut vraiment distinguer facilement une carte de la période primoderne des périodes future et même de la période holscoul rien et cela rien quen lisont la carte et on a la plupart des arhitypes éconiques nomadgiques qui s sont conçu duant cette période comme goblan elf rénmator artefacte hartefactes prison wet de contrôle repde kwuins euroc et quiet vers noir midrenge storme etc

**cut here:**

- ✂ **3.3s** `[02:09.696 → 02:13.039]` **R2 script regression** · sim 73.2 — "ou les arts... ou le type d'art qui représente,"
  <br>kept instead, from `02:13.079`: "ou l'esthétique des arts qui représente vraiment cette période. On peut vraiment distingue"
- ✂ **2.3s** `[02:11.380 → 02:13.720]` **D3 restart (ctc anchor)** · sim 85.3 — "type dartes qui represente ou lestetique"
  <br>kept instead, from `02:13.760`: "des artes qui reprint ou lestetique des artes qui represente vraiment cette"
- ✂ **1.9s** `[02:13.760 → 02:15.620]` **D3 restart (ctc anchor)** · sim 88.9 — "des artes qui reprint ou lestetique"
  <br>kept instead, from `02:15.660`: "des artes qui represente vraiment cette periode on"

**survives (ctc):** des artes qui représente vraiment cette période on peut vraiment distinguer facilement une carte de la période primoderne des périodes future et même de la période holscoul rien et cela rien quen lisont la carte et on a la plupart des arhitypes éconiques nomadgiques qui s sont conçu duant cette période comme goblan elf rénmator artefacte hartefactes prison wet de contrôle repde kwuins euroc et quiet vers noir midrenge storme etc

## src [02:40.237 → 02:45.588]  ·  out [02:14.109 → 02:19.460]

- **whisper:** La troisième période, pour moi, c'est la période moderne, et c'est clairement la plus large. Elle commence en 2003
- **ctc:** la troisième période pour moi cest la période moderne etsait clairement la plus large elle commence en deux mille trois

*(untouched)*

## src [02:46.049 → 02:49.897]  ·  out [02:19.921 → 02:23.769]

- **whisper:** avec l'introduction de l'Afrique moderne à Miroudin, et se termine en 2019
- **ctc:** avec lintroduction de lafhrique moderne à mie roudan et ce termine en deux mille dix neuf

*(untouched)*

## src [02:50.398 → 02:59.877]  ·  out [02:24.270 → 02:33.749]

- **whisper:** avec la sortie de War of the Spark. Pour moi, c'est la période où le design de Magic est à son apogée, que ce soit au niveau des mécaniques, des sets, du lore, des plans. Pour moi, c'est la période de...
- **ctc:** avec la sortie de woire spoir pour moi cest la période où le dizanes de madgique est à son nampogée que coit au niveau des mécaniques des septs du lors des plans aque pour moi cest la période de

*(untouched)*

---

## Left in on purpose (review)

Phonetic repeats that were **not** cut. `in script` means the repetition is written
in the script, so it is rhetorical rather than a retake.

| src | score | in script | heard | echoed at |
|---|---|---|---|---|
| 00:29.640 | 0.766 | yes | ai | 00:34.640 la partie en solo si elle |
| 01:13.840 | 0.766 | yes | comment je categorise | 01:20.300 je categorise |
