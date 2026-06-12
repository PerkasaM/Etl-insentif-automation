# ETL Insentif - ZSDCONUN

Pipeline ETL untuk menghitung insentif SDO (Sales Development Officer) berdasarkan data penjualan dari SAP dan target yang ditetapkan.

## 📋 Daftar Isi

- [Deskripsi](#-deskripsi)
- [Alur Proses](#-alur-proses)
- [Struktur Project](#-struktur-project)
- [Quick Start](#-quick-start)
- [Business Logic](#-business-logic)
- [Konfigurasi](#-konfigurasi)
- [Troubleshooting](#-troubleshooting)

## 📋 Deskripsi

Project ini melakukan ekstraksi data dari beberapa sumber (Excel files), transformasi data (cleaning, enrichment, agregasi), dan menghasilkan output insentif per SDO untuk periode Q1 (Cycle 01-03 tahun 2026).

**Fitur utama:**
- ✅ Clean data SDO dengan mapping khusus
- ✅ Mapping cycle berdasarkan `ACTUAL PGI DATE`
- ✅ Enrichment dengan master SKU (Brand, PG, SUB-PG)
- ✅ Enrichment dengan master customer (Channel, SPV, ASM, RSM)
- ✅ Klasifikasi transaksi (SALES, RETUR, CLAIM G)
- ✅ Perhitungan insentif per cycle dan quarterly
- ✅ Output Excel dengan 2 sheet: `Achievement` dan `Insentif`

## 🔄 Alur Proses

### Diagram Alur ETL

```mermaid
flowchart TD
    Start([Start ETL]) --> Load[Load semua source data]
    
    subgraph Input [Source Data]
        ZSD[ZSDCONUN<br/>Fakta Transaksi SAP]
        CYCLE[CYCLE_REKAP<br/>Master Cycle]
        SKU[skuu6<br/>Master SKU]
        CUST[master c05<br/>Master Customer]
        TARGET[Target Modern<br/>Target SDO per Cycle]
    end
    
    Load --> ZSD & CYCLE & SKU & CUST & TARGET
    
    subgraph Transform [Transformasi Data]
        Clean[Clean ZSDCONUN<br/>- Drop invalid SO DATE<br/>- Clean SDO names<br/>- Convert dates]
        Clean --> CalcPPN[Calculate NET VALUE2<br/>= NET VALUE × 1.11]
        CalcPPN --> MapCycle[Map CYCLE<br/>Berdasarkan ACTUAL PGI DATE]
        MapCycle --> MapSKU[Map SKU Master<br/>Brand, PG, SUB-PG]
        MapSKU --> MapCust[Map Customer Master<br/>CHANNEL, SPV, ASM, RSM]
        MapCust --> Classify[Classify REMARKS<br/>SALES / RETUR / CLAIM G]
    end
    
    ZSD --> Clean
    CYCLE --> MapCycle
    SKU --> MapSKU
    CUST --> MapCust
    
    Classify --> Filter{Filter Data<br/>Untuk Achievement}
    
    subgraph Filtering [Filter Achievement]
        F1[Filter SDO<br/>Hanya di SDO_INSENTIF_LIST]
        F2[Filter REMARKS<br/>SALES atau RETUR saja]
        F3[Channel: Semua channel]
    end
    
    Filter --> F1 --> F2 --> F3
    
    F3 --> Pivot[Pivot Table<br/>SDO × CYCLE<br/>SUM NET VALUE2]
    
    subgraph Calculation [Perhitungan Insentif]
        CalcTarget[Ambil Target Q1<br/>C01 + C02 + C03]
        CalcAch[Hitung Achievement Q1<br/>Total NET VALUE2]
        CalcPct[Hitung ACH%<br/>= Ach / Target × 100]
        CalcTier[Determine Tier<br/>0.25% / 0.50% / 0.75%]
        CalcInsentif[Hitung Nilai Insentif<br/>Sesuai tier & rumus]
        CalcQuarterly[Hitung ADD Quarterly<br/>Berdasarkan ACH% Q1]
        CalcTotal[Total Insentif<br/>= Sum per cycle + ADD]
    end
    
    TARGET --> CalcTarget
    Pivot --> CalcAch
    CalcTarget --> CalcPct
    CalcAch --> CalcPct
    CalcPct --> CalcTier --> CalcInsentif
    CalcPct --> CalcQuarterly
    CalcInsentif --> CalcTotal
    CalcQuarterly --> CalcTotal
    
    subgraph Output [Output Files]
        OUT1[ZSDCONUN_ETL_*.xlsx<br/>Data lengkap hasil ETL]
        OUT2[Insentif_Q1_*.xlsx<br/>Sheet: Achievement<br/>Sheet: Insentif]
    end
    
    Classify --> OUT1
    CalcTotal --> OUT2
    Pivot --> OUT2
    
    OUT1 --> End([Selesai])
    OUT2 --> End
    
    style Input fill:#e1f5fe
    style Transform fill:#fff3e0
    style Filtering fill:#f3e5f5
    style Calculation fill:#e8f5e9
    style Output fill:#fce4ec