# Data Dictionary — ETL Insentif

> Kamus data untuk seluruh source file ETL Insentif.
> Lokasi source: `data/` di folder project.
> Lokasi output: `output/`.

---

## 1. `data/ZSDCONUN 23112025 -30042026.xlsx`

**Sheet**: `ZSDCONUN` · **Baris**: 188.766 · **Kolom**: 22 · **Peran**: Fakta transaksi SAP (sales order / billing)

| # | Nama Kolom | Tipe Data | Nullable | Fungsi |
|---|------------|-----------|----------|--------|
| 1 | `TYPE` | string | Tidak | Tipe dokumen (selalu `Converted`) |
| 2 | `CUSTOMER#` | string/int | Tidak | Kode unik customer — **join key** ke `master c05` |
| 3 | `NAME1` | string | Tidak | Nama customer |
| 4 | `NAME2` | string | Ya | Nama tambahan customer |
| 5 | `CUST GRP` | string | Ya | Grup customer |
| 6 | `SALES GRP` | string | Ya | Grup sales |
| 7 | `SDO` | string | Tidak | Nama SDO (Sales Development Officer) — **row key pivot** |
| 8 | `DOCNUM` | string/int | Tidak | Nomor dokumen SAP |
| 9 | `SO DATE` | date | Ya | Tanggal Sales Order. Catatan: di data asli banyak berisi `#VALUE!` (rusak) → **drop** saat ETL |
| 10 | `DOCDATE` | date | Tidak | Tanggal dokumen |
| 11 | `BILLINGDATE` | date | Tidak | Tanggal billing |
| 12 | `ACTUAL PGI DATE` | date | Tidak | Tanggal pengiriman aktual (Post Goods Issue) — **join key** ke `CYCLE_REKAP` |
| 13 | `ITEM#` | string | Tidak | Nomor item |
| 14 | `MATERIAL` | string | Tidak | Kode material (SKU) — **join key** ke `skuu6` |
| 15 | `DESCRIPTION` | string | Tidak | Deskripsi material |
| 16 | `ITEM CAT` | string | Ya | Item category (umumnya `TAN`) |
| 17 | `PLANT` | string | Ya | Kode plant |
| 18 | `STORELOC` | string | Ya | Kode storage location |
| 19 | `QUANTITY` | int | Tidak | Jumlah unit terjual |
| 20 | `SO AMOUNT` | float | Tidak | Nilai Sales Order (sebelum diskon) |
| 21 | `DISCOUNT` | float | Tidak | Nilai diskon |
| 22 | `NET VALUE` | float | Tidak | Nilai bersih (setelah diskon, **sebelum PPN**) — dasar hitung `netvalue2` |

---

## 2. `data/CYCLE_REKAP_1.0.xlsx`

**Sheet**: `Sheet2` · **Baris**: 90 · **Kolom**: 4 (yang dipakai) · **Peran**: Master cycle + rentang tanggal

| # | Nama Kolom | Tipe Data | Fungsi |
|---|------------|-----------|--------|
| 1 | `Cycle` | string | Kode cycle format `C0X26` (contoh `C0126` = cycle 01 tahun 2026) — **join key** ke kolom `CYCLE` hasil ETL |
| 2 | `Start Date` | date | Tanggal mulai cycle |
| 3 | `End Date` | date | Tanggal akhir cycle |
| 4 | (kolom E) `Cycle` | string | Duplikat dari kolom B (diabaikan saat ETL) |

**Cara pakai**: mencocokkan `ZSDCONUN.ACTUAL PGI DATE` ke range `Start Date – End Date` → `Cycle`.

---

## 3. `data/skuu6.xlsx`

**Sheet dipakai**: `LIST SKU` · **Baris**: 687 · **Kolom**: ~70 (yang dipakai 6) · **Peran**: Master SKU untuk mapping Brand, PG, SUB-PG

> Sheet `MASTERDATA`, `SNI`, `Sheet1` ada tetapi **tidak digunakan** di ETL ini.

| # | Nama Kolom | Tipe Data | Fungsi |
|---|------------|-----------|--------|
| 1 | `NO` | int | Nomor urut (diabaikan) |
| 2 | `SKU Code` | string | Kode SKU — **join key** ke `ZSDCONUN.MATERIAL` |
| 3 | `Internal Code` | string | Kode internal (diabaikan) |
| 4 | `Description` | string | Deskripsi produk (diabaikan) |
| 5 | `PG` | string | Product Group — hasil → kolom ETL `PG` |
| 6 | `SUB-PG` | string | Sub Product Group — hasil → kolom ETL `SUBPG` |

**Catatan ETL**: di-dedupe `by 'SKU Code', keep='first'` sebelum merge.

---

## 4. `data/master c05.xlsx`

**Sheet**: `Sheet1` · **Baris**: 7.173 · **Kolom**: 39 (yang dipakai 2) · **Peran**: Master customer untuk mapping Chanel & SPV/ASM/RSM

| # | Nama Kolom | Tipe Data | Fungsi |
|---|------------|-----------|--------|
| 1 | `Customer Code` | string/int | Kode customer — **join key** ke `ZSDCONUN.CUSTOMER#` |
| 8 | `Chanel` | string | Channel penjualan. Nilai unik: `MODERN TRADE`, `DIRECT`, `E-COMMERCE`, `INDIRECT`, `PROJECTS`, `OTHERS` — hasil → kolom ETL `CHANNEL` |
| 13 | `SDO Update` | string | Nama SDO (update). Catatan: `SDO Name` adalah SDO asal; `SDO Update` adalah SDO update-an |
| 37 | `SPV` | string | Supervisor (hasil → kolom ETL `SPV`) |
| 38 | `ASM` | string | Area Sales Manager |
| 39 | `RSM` | string | Regional Sales Manager |

**Catatan ETL**: di-dedupe `by 'Customer Code', keep='first'` sebelum merge.

---

## 5. `data/Target Modern Update KA 15 May 2026.xlsx`

**Sheet**: `Target KA (2)` · **Baris**: 14 (7 SDO + TOTAL + kosong) · **Kolom**: 14 · **Peran**: Target penjualan SDO per cycle

| # | Nama Kolom | Tipe Data | Fungsi |
|---|------------|-----------|--------|
| 1 | `KA Update` | string | Nama SDO (KA = Key Account) — **join key** ke pivot `SDO` |
| 2 | `C01` | float | Target cycle 01 |
| 3 | `C02` | float | Target cycle 02 |
| 4 | `C03` | float | Target cycle 03 |
| 5–13 | `C04`..`C12` | float | Target cycle 04–12 |
| 14 | `TOTAL` | float | Total target setahun (informational) |

**Cara pakai (Q1)**: jumlahkan `C01 + C02 + C03` per SDO → `Target_Q1`.

---

## 6. Derived Columns (output ETL `ZSDCONUN_ETL_*.xlsx`)

Kolom tambahan yang dibuat selama transformasi:

| # | Nama Kolom | Tipe Data | Formula / Sumber | Fungsi |
|---|------------|-----------|------------------|--------|
| 23 | `NET VALUE2` | float | `NET VALUE × 1.11` | Nilai bersih setelah PPN 11% |
| 24 | `CYCLE` | string | `merge(ACTUAL PGI DATE → CYCLE_REKAP)` | Kode cycle (contoh `C0326`) |
| 25 | `BRAND` | string | `merge(MATERIAL → skuu6)` | Nama brand |
| 26 | `PG` | string | `merge(MATERIAL → skuu6)` | Product Group |
| 27 | `SUBPG` | string | `merge(MATERIAL → skuu6)` | Sub Product Group |
| 28 | `SUBPG1` | string | (sama dengan `SUBPG`, sesuai output referensi) | Alias SUBPG |
| 29 | `CHANNEL` | string | `merge(CUSTOMER# → master c05.Chanel)` | Channel penjualan |
| 30 | `REMARKS` | string | Logika: `<0`→RETUR, `<1000`→CLAIM G, `>=1000`→SALES | Klasifikasi baris |
| 31 | `CUST_TYPE` | string | (reserved, saat ini None) | Tipe customer |
| 32 | `SPV` | string | `merge(CUSTOMER# → master c05.SPV)` | Supervisor |
| 33 | `ASM` | string | `merge(CUSTOMER# → master c05.ASM)` | Area Sales Manager |
| 34 | `RSM` | string | `merge(CUSTOMER# → master c05.RSM)` | Regional Sales Manager |

---

## 7. Relasi Antar Tabel (Join Keys)

```
┌──────────────────────────┐
│ ZSDCONUN                 │   ACTUAL PGI DATE ───┐
│  - CUSTOMER# ────────────┼──► master c05        │
│  - MATERIAL ─────────────┼──► skuu6             │
│  - ACTUAL PGI DATE ──────┼──► CYCLE_REKAP       │
└──────────────────────────┘   │                  │
                                ▼                  ▼
                            (CHANNEL)         (CYCLE)
                                
┌──────────────────────────┐
│ Target KA (2)            │   SDO = hasil pivot
│  rows = SDO, cols = C0X  │   join key: SDO ↔ SDO
└──────────────────────────┘
```

| Sumber | Field | Target | Field | Jenis Join |
|--------|-------|--------|-------|------------|
| ZSDCONUN | `ACTUAL PGI DATE` | CYCLE_REKAP Sheet2 | range `Start Date`–`End Date` | range-merge |
| ZSDCONUN | `MATERIAL` | skuu6 LIST SKU | `SKU Code` | left (dedupe `keep='first'`) |
| ZSDCONUN | `CUSTOMER#` | master c05 | `Customer Code` | left (dedupe `keep='first'`) |
| Pivot result | `SDO` | Target KA (2) | `KA Update` | left |

---

## 8. Output: `output/Insentif_Q1_*.xlsx`

**Sheet 1: `Achievement`** — Pivot SDO × Cycle

| Kolom | Tipe | Fungsi |
|-------|------|--------|
| `SDO` | string | Nama SDO |
| `C0126` | float | Σ netvalue2 SDO di cycle 01 |
| `C0226` | float | Σ netvalue2 SDO di cycle 02 |
| `C0326` | float | Σ netvalue2 SDO di cycle 03 |
| `Total_Q1` | float | Jumlah 3 cycle |

**Sheet 2: `Insentif`** — Perhitungan insentif Q1

| Kolom | Tipe | Fungsi |
|-------|------|--------|
| `SDO` | string | Nama SDO |
| `Target_Q1` | float | C01+C02+C03 dari Target KA |
| `Ach_Q1` | float | Σ netvalue2 Q1 (filter MODERN TRADE, SALES+RETUR) |
| `ACH_%` | float | `Ach_Q1 / Target_Q1 × 100` |
| `Tier` | string | `0.25%` / `0.50%` / `0.75%` (berdasarkan ACH%) |
| `Nilai_Insentif` | float | Nominal insentif sesuai tier |

**Rumus Nilai Insentif**:

| Tier | Syarat ACH% | Rumus |
|------|-------------|-------|
| 0.25% | 80 ≤ ACH% < 100 | `Ach_Q1 × 0.25%` |
| 0.50% | 100 ≤ ACH% < 110 | `Target_Q1 × 0.25% + (Ach_Q1 − Target_Q1) × 0.50%` |
| 0.75% | ACH% ≥ 110 | `Target_Q1 × 0.25% + (Ach_Q1 − Target_Q1) × 0.75%` |
| — | ACH% < 80 | `0` (tidak dapat insentif) |

---

## 9. Konstanta & Konfigurasi

| Item | Nilai | Keterangan |
|------|-------|------------|
| `PPN` | `1.11` | PPN 11% dikalikan ke NET VALUE → NET VALUE2 |
| `Q1_CYCLES` | `['C0126', 'C0226', 'C0326']` | Cycle untuk Q1 tahun 2026 |
| `FILTER_CHANNEL` | `'MODERN TRADE'` | Filter pivot achievement |
| `FILTER_REMARKS` | `['SALES', 'RETUR']` | Filter pivot achievement |
| `DROP_SO_DATE_INVALID` | `True` | Drop baris dengan `SO DATE = '#VALUE!'` |

---

## 10. Sumber & Versi

- `ZSDCONUN`: hasil export SAP, periode 23/11/2025 – 30/04/2026
- `CYCLE_REKAP`: versi 1.0 (legacy, berisi cycle 2019–2026)
- `skuu6`: snapshot terbaru
- `master c05`: snapshot terbaru
- `Target Modern`: update KA 15 May 2026
