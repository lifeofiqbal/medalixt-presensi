<img width="228" height="179" alt="image" src="https://github.com/user-attachments/assets/23937e46-c15f-4e1c-bc63-f84ae996d679" />
<img width="350" height="145" alt="image" src="https://github.com/user-attachments/assets/03519997-c2e8-4abf-86bd-25cc19815057" />
<img width="272" height="83" alt="image" src="https://github.com/user-attachments/assets/e1de01d8-fc6f-4ad8-9d02-cf70cc1743c9" />




# medalixt_presensi

Resource presensi & playtime tracker untuk **QBX Core** (FiveM).

---

## Fitur

| Fitur | Keterangan |
|---|---|
| **Overhead ID Tag** | Tekan `Z` untuk menampilkan Server ID di atas kepala player |
| **Job Tag** | Label pekerjaan (warna custom per job) muncul di atas ID |
| **\[NEW\] Indicator** | Jika total playtime < threshold (default 24 jam), tampil `[NEW]` di depan ID |
| **Pencatatan Login/Logout** | Sistem hanya catat waktu login & logout — **tidak ada loop pencatat terus-menerus** |
| **Command `/playtime`** | Player bisa cek total jam main sendiri |
| **Command `/cekpresensi [id]`** | Admin cek playtime player lain |

---

## Dependensi

```
qbx_core
ox_lib
oxmysql
```

---

## Instalasi

1. Copy folder `medalixt_presensi` ke `resources/[qbx]/`
2. Tambahkan ke `server.cfg`:
   ```
   ensure medalixt_presensi
   ```
3. Database table akan **otomatis dibuat** saat resource start. Atau jalankan manual:
   ```
   sql/medalixt_presensi.sql
   ```

---

## Konfigurasi (`shared/config.lua`)

```lua
Config.Key = 44                  -- Tombol untuk tampilkan ID tag (44 = Z)
Config.Cooldown = 2000           -- Cooldown (ms) setelah tekan tombol
Config.TagDuration = 5000        -- Berapa lama tag tampil (ms)
Config.NewPlayerThreshold = 1440 -- Batas playtime [NEW] dalam MENIT (1440 = 24 jam)
```

### Custom Job Tags

```lua
Config.JobTags = {
    ['police']    = { label = 'POLICE',    color = '#4fc3f7' },
    ['ambulance'] = { label = 'MEDIC',     color = '#ef5350' },
    ['developer'] = { label = 'DEVELOPER', color = '#66bb6a' },
    ['racer']     = { label = 'RACER',     color = '#ef5350' },
    -- tambah job lain sesuai kebutuhan...
}
```

---

## Cara Kerja Pencatatan Waktu

```
Player login  ─► INSERT row (login_time = NOW(), logout_time = NULL)
Player logout ─► UPDATE row (logout_time = NOW(), session_minutes = durasi)
```

> **Tidak ada loop** — pencatatan hanya terjadi pada event `PlayerLoaded` dan `playerDropped / OnPlayerUnload`.
> Cara kerjanya identik dengan sistem TxAdmin.

---

## Database Schema

```sql
CREATE TABLE `medalixt_presensi` (
    `id`              INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid`       VARCHAR(50)  NOT NULL,
    `name`            VARCHAR(100) NOT NULL DEFAULT '',
    `login_time`      DATETIME     NOT NULL,
    `logout_time`     DATETIME     DEFAULT NULL,
    `session_minutes` INT          DEFAULT NULL
);
```

---

## Commands

| Command | Akses | Fungsi |
|---|---|---|
| `/playtime` | Semua player | Lihat total jam main sendiri |
| `/cekpresensi [serverid]` | Admin (`group.admin`) | Cek playtime player lain |

---

## Struktur File

```
medalixt_presensi/
├── fxmanifest.lua
├── shared/
│   └── config.lua
├── client/
│   └── main.lua
├── server/
│   └── main.lua
└── sql/
    └── medalixt_presensi.sql
```
