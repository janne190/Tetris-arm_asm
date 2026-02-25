# Tetris — ARM Assembly

> **Huom:** Projekti on kesken. Katso [Puuttuvat ominaisuudet](#puuttuvat-ominaisuudet)-osio.

Tetris-toteutus kirjoitettuna ARMv7-kokoonpanokielellä (ARM Assembly), jota suoritetaan [Unicorn Engine](https://www.unicorn-engine.org/) -emulaattorissa Python-ajurilla.

---

## Sisällysluettelo

- [Yleiskuvaus](#yleiskuvaus)
- [Arkkitehtuuri](#arkkitehtuuri)
- [Ominaisuudet](#ominaisuudet)
- [Puuttuvat ominaisuudet](#puuttuvat-ominaisuudet)
- [Vaatimukset](#vaatimukset)
- [Asennus ja käynnistys](#asennus-ja-käynnistys)
- [Ohjaus](#ohjaus)
- [Muistikartta](#muistikartta)
- [Tiedostorakenne](#tiedostorakenne)

---

## Yleiskuvaus

Projektin tavoitteena on toteuttaa toimiva Tetris-peli puhtaasti ARMv7-kokoonpanokielellä. Peli ajetaan Python-skriptin käynnistämässä ARM-emulaattorissa, joka emuloi yksinkertaista retrokonsoliympäristöä VRAM-näyttöpuskurilla ja muistikartoitetulla I/O:lla.

Pelilauta on klassinen **10 × 20** ruudukko. Kaikki seitsemän standarditetrominoa (I, J, L, O, S, T, Z) on määritelty tietolomakkeina.

---

## Arkkitehtuuri

```
┌─────────────────────────────────────────┐
│           tetris_runner.py              │
│  (Python + Unicorn Engine -ajuri)       │
│                                         │
│  ┌──────────┐   ┌──────────────────┐   │
│  │  Syöte   │   │  Näyttörenderöinti│   │
│  │  (Win32  │   │  (ANSI-terminaali)│   │
│  │  VK API) │   └──────────────────┘   │
│  └────┬─────┘            ▲             │
│       │ MMIO-kirjoitus    │ VRAM-luku   │
│  ┌────▼──────────────────┴──────────┐  │
│  │      Unicorn ARM-emulaattori     │  │
│  │  ┌───────────────────────────┐   │  │
│  │  │        main.s             │   │  │
│  │  │   (ARMv7 Assembly -peli)  │   │  │
│  │  └───────────────────────────┘   │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Muisti- ja I/O-malli

| Alue | Osoite | Kuvaus |
|------|--------|--------|
| Koodi (ROM) | `0x10000` | ARM-konekoodibinääri |
| RAM | `0x20000` | Pinokehys, pelitila, tetromino-data |
| Pelitila | `0x20100` | Pelitilan muuttujat |
| Matriisi | `0x20200` | Pelilauta (10 × 20 tavua) |
| Tetromino-määrittelyt | `0x20300` | 7 palaa × 4 tavua (rivi-bittimaski) |
| VRAM | `0x30000` | Näyttöpuskuri (40 × 20 merkkiä) |
| MMIO | `0x40000` | Painonäppäinten tila |
| RNG-portti | `0x40004` | Satunnaisluku (Python kirjoittaa) |
| VSYNC-portti | `0x40008` | ARM kirjoittaa `1` kun kuva on valmis |

### Pelitilan muuttujat (RAM `0x20100`)

| Offset | Kuvaus |
|--------|--------|
| `+0x100` | Alustusmerkkibitti |
| `+0x104` | Nykyinen pala: X-koordinaatti |
| `+0x108` | Nykyinen pala: Y-koordinaatti |
| `+0x10C` | Nykyinen palatyyppi (0–6) |
| `+0x110` | Pisteet |
| `+0x114` | Gravitaatiolaskuri |
| `+0x118` | Peli ohi -lippu |

---

## Ominaisuudet

- [x] Kaikki 7 standarditetrominoa (I, J, L, O, S, T, Z)
- [x] 10 × 20 pelilauta
- [x] Palojen putoaminen (gravitaatio)
- [x] Siirtyminen vasemmalle ja oikealle
- [x] Nopea pudotus (soft drop)
- [x] Täyden rivin tunnistus ja poistaminen
- [x] Rivien siirtäminen alaspäin poistetun rivin jälkeen
- [x] Törmäystarkistus (seinät, lattia, lukitut palat)
- [x] Pisteytys (100 pistettä per poistettu rivi)
- [x] Pisteiden näyttäminen (4-numeroinen, maks. 9999)
- [x] Peli ohi -tunnistus ja "GAME OVER" -teksti
- [x] VSYNC-mekanismi sulavaan renderöintiin
- [x] Tekstipohjainen terminaalinäyttö (ANSI-ohjaussekvenssit)
- [x] Palojen kääntäminen
---

## Puuttuvat ominaisuudet

> Nämä ominaisuudet **eivät ole vielä toteutettu**:
- [ ] Seuraavan palan esikatselu
- [ ] Tasojen eteneminen (peli nopeutuu pisteiden karttuessa)
- [ ] Tuhottujen rivien laskuri näytöllä
- [ ] Ennätyspisteytys
- [ ] Pelitaustan värit / ASCII-taide
- [ ] Uudelleenaloitus ilman ohjelman käynnistämistä uudelleen

---

## Vaatimukset

- **Windows** (syötesilmukka käyttää Win32 `GetAsyncKeyState` -API:a)
- **Python 3.8+**
- **unicorn** Python-kirjasto

```
pip install unicorn
```

> Python-paketti `unicorn` sisältää valmiiksi käännetyn Unicorn Engine -kirjaston,
> eikä erillisiä C-kirjastoja tarvita.

---

## Asennus ja käynnistys

1. Kloonaa tai lataa repositorio:
   ```
   git clone https://github.com/janne190/Tetris-arm_asm.git
   cd Tetris-arm_asm
   ```

2. Asenna riippuvuus:
   ```
   pip install unicorn
   ```

3. Käynnistä peli:
   ```
   python tetris_runner.py
   ```

> Ajuriskripti sisältää ARM-binäärin valmiiksi käännettynä hex-merkkijonona.
> Erillistä kääntäjää (esim. `arm-none-eabi-as`) ei tarvita pelin ajamiseen.
> `main.s` on lähdekooditiedosto, josta binääri on tuotettu.

---

## Ohjaus

| Näppäin | Toiminto |
|---------|----------|
| `A` tai `←` | Siirrä palaa vasemmalle |
| `D` tai `→` | Siirrä palaa oikealle |
| `S` tai `↓` | Nopea pudotus (soft drop) |
| `W` tai `↑` | *(ei käytössä — kääntö tulossa)* |
| `Q` | Lopeta peli |

---

## Tiedostorakenne

```
Tetris-arm_asm/
├── main.s              # Pelin lähdekoodi ARMv7-kokoonpanokielellä
├── tetris_runner.py    # Python-ajuri (Unicorn Engine + terminaalinäyttö)
└── README.md           # Tämä tiedosto
```

---

## Lisenssi

Tämä projekti on julkaistu ilman erillistä lisenssiä. Kaikki oikeudet pidätetään.
