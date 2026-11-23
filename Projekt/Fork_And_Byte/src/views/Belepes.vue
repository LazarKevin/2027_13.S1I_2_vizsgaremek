<template>
  <div class="oldal">
    <div class="tartalom">
      <div class="fejresz">
        <img src="../assets/logo.jpg" alt="Fork & Byte logó" class="logo" />
        <h1>Üdv nálunk!</h1>
        <p class="leiras">
          Írd be a foglaláskor kapott kódot, és már rendelhetsz is a telefonodról.
        </p>
      </div>
      <div class="kod-resz">
        <label for="kod">Belépőkód</label>
        <!-- v-model="kod": amit a vendég beír, az a data()-ban lévő kod változóba kerül -->
        <input
          id="kod"
          v-model="kod"
          type="text"
          maxlength="10"
          placeholder="pl. K7F2Q9"
          class="kod-mezo"
        />
        <!-- Hibaüzenet: csak akkor látszik, ha a hibaUzenet nem üres -->
        <p v-if="hibaUzenet != ''" class="hiba">{{ hibaUzenet }}</p>

        <div class="info">
          <svg
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <circle cx="12" cy="12" r="9" />
            <path d="M12 7v5l3 2" />
          </svg>
          <span>A kód a foglalás napján érvényes, és csak egyszer használható.</span>
        </div>
      </div>

      <div class="also-resz">
        <!--
          v-bind:disabled = a gomb le van tiltva, amíg a kód nem elég hosszú
          v-on:click      = kattintáskor lefut a methods-ban lévő belepes() metódus
        -->
        <button class="gomb" v-bind:disabled="!kodElegHosszu" v-on:click="belepes">
          Belépés az asztalhoz
        </button>

        <div class="segitseg">
          <strong>Nincs foglalásod?</strong>
          <span>Szólj a pincérnek: ő rögzít egy helyszíni foglalást, és ad egy kódot.</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  // data(): az oldal adatai (változói). Ha egy érték változik, a képernyő magától frissül.
  data() {
    return {
      kod: '',
      hibaUzenet: '',
    }
  },

  // computed: számolt értékek. Magától újraszámolódik, ha a kod változik.
  computed: {
    kodElegHosszu() {
      // trim() = levágja a szóközöket a szöveg elejéről és végéről
      let beirtKod = this.kod.trim()

      if (beirtKod.length >= 6) {
        return true
      } else {
        return false
      }
    },
  },

  // methods: a metódusok, amiket a HTML-ből hívunk (pl. gombnyomásra).
  methods: {
    // async = a metódus várni tud a szerver válaszára (await)
    async belepes() {
      // Az előző hibaüzenetet töröljük
      this.hibaUzenet = ''

      // A beírt kódot megtisztítjuk és nagybetűssé alakítjuk
      // trim() = levágja a szóközöket, toUpperCase() = nagybetűssé alakít
      let beirtKod = this.kod.trim()
      let nagybetusKod = beirtKod.toUpperCase()

      try {
        // Elküldjük a kódot a Laravelnek (POST kérés)
        let valasz = await fetch('http://localhost:8000/api/belepes', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Accept: 'application/json',
          },
          body: JSON.stringify({ kod: nagybetusKod }),
        })

        // A Laravel válaszát JSON-ból JavaScript objektummá alakítjuk
        let adat = await valasz.json()

        // valasz.ok = true, ha a Laravel 200-as kóddal válaszolt (minden rendben)
        if (valasz.ok) {
          // KÉSŐBB: itt lépünk át az étlapra
          alert('Sikeres belépés! Asztal: ' + adat.asztal_id)
        } else {
          // Hiba esetén a Laravel üzenetét írjuk ki
          if (adat.uzenet != undefined) {
            // A mi saját hibaüzenetünk (pl. "Nincs ilyen kód.")
            this.hibaUzenet = adat.uzenet
          } else {
            // A Laravel saját hibaüzenete (pl. ha valami rosszul van beállítva)
            this.hibaUzenet = 'Szerverhiba: ' + adat.message
          }
        }
      } catch (hiba) {
        // Ide akkor jutunk, ha a Laravel szerver nem fut, vagy nem érhető el
        this.hibaUzenet = 'Nem sikerült csatlakozni a szerverhez.'
      }
    },
  },
}
</script>

<style scoped>
/* Az egész oldal: sötétkék háttér, teljes képernyő magasság */
.oldal {
  min-height: 100vh;
  background: var(--navy);
  color: #ffffff;
  display: flex;
  justify-content: center;
}

/* A tartalom: telefonon teljes szélesség, nagy képernyőn középre igazított, max 420px */
.tartalom {
  width: 100%;
  max-width: 420px;
  min-height: 100vh;
  box-sizing: border-box;
  padding: 56px 24px 28px;
  display: flex;
  flex-direction: column;
  gap: 28px;
}

.fejresz {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 18px;
  text-align: center;
}

.logo {
  width: 132px;
  height: 132px;
  border-radius: 50%;
  object-fit: cover;
  border: 3px solid var(--arany);
}

h1 {
  margin: 0;
  font-family: 'Montserrat', sans-serif;
  font-weight: 700;
  font-size: 26px;
}

.leiras {
  margin: 0;
  font-size: 15px;
  line-height: 1.5;
  color: #d6dce6;
}

.kod-resz {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

label {
  font-size: 13px;
  font-weight: 600;
  color: #d6dce6;
}

.kod-mezo {
  height: 64px;
  box-sizing: border-box;
  padding: 0 16px;
  border: 2px solid var(--arany);
  border-radius: 14px;
  background: #ffffff;
  color: var(--navy);
  font-family: 'Montserrat', sans-serif;
  font-weight: 700;
  font-size: 30px;
  letter-spacing: 10px;
  text-align: center;
  text-transform: uppercase; /* kisbetűvel beírva is nagybetűnek látszik */
}

.kod-mezo::placeholder {
  font-size: 18px;
  letter-spacing: 2px;
  color: #9aa3b0;
  text-transform: none;
}

/* Hibaüzenet doboza */
.hiba {
  margin: 0;
  padding: 10px 12px;
  border-radius: 10px;
  background: #fbe9e1;
  color: #8e3512;
  font-size: 14px;
  font-weight: 600;
  text-align: center;
}

.info {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 12px;
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.08);
  color: #e2c48a; /* az ikon színe */
}

.info span {
  font-size: 13px;
  color: #e8ecf2;
}

/* margin-top: auto = az alsó rész lecsúszik a képernyő aljára */
.also-resz {
  margin-top: auto;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.gomb {
  height: 54px;
  border: 0;
  border-radius: 14px;
  background: var(--arany);
  color: var(--navy);
  font-family: 'Montserrat', sans-serif;
  font-weight: 800;
  font-size: 16px;
  cursor: pointer;
}

/* Letiltott állapot: halványabb, és nem kattintható */
.gomb:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.segitseg {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 14px 16px;
  border: 1px solid rgba(255, 255, 255, 0.18);
  border-radius: 12px;
  font-size: 14px;
}

.segitseg span {
  font-size: 13px;
  line-height: 1.45;
  color: #d6dce6;
}
</style>
