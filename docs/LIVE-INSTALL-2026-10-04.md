# Personal Retail installation — October 4, 2026

The user explicitly requested readiness verification, full AddOns and WTF backups, and installation of ConsolePort Forever plus all current dependencies, without editing WTF. The guarded installer completed successfully at **13:52:51 America/Toronto**. WoW was closed throughout; this session did not launch the game or wait for the user's test results.

- Installed candidate: `2.0.0-candidate.1`, StoreSchema 3, configuration revision 11.
- Tested/pushed pack source: `e7937e1e2972dcdc123cd7ab853fa9d75866918a`.
- Pack SHA-256: `992321ed50e64b0b209320a278ab74c142ae06396b92ade03dcdd5cf579ffe7f`.
- Selected executable root: `C:\Program Files (x86)\World of Warcraft\_retail_`.
- Canonical addon root: `C:\Users\luisr\OneDrive\Documents\03 Gaming\World of Warcraft\_retail_\Interface\AddOns`.
- Verified full backup: `C:\Users\luisr\WoW-Backups\ConsolePort-Forever\20261004T174409Z-cb96bcd5f5f6`.
- Backup contains all **3,677** prior addon files and **296** canonical WTF files, including fallback/cache files; all **42** character junctions are recorded in `snapshot.json` and preserved in the live tree.
- Parked original addon folders remain at `C:\Users\luisr\OneDrive\Documents\03 Gaming\World of Warcraft\_retail_\Interface\.cpf-stage-20261004T174409Z-cb96bcd5f5f6\previous`.
- Operation receipt: `install-receipt.json` in the backup directory; SHA-256 `cedfc40acba51a4534c5cf756dc83bf5373813ee2871f78a49b550f039c03e59`.

Preflight reran all **32** runtime/source suites and **21** tooling tests successfully. All **18** cached official packages verified, and today's official stable-release check matched the lock, including ConsolePort **3.3.5**. The three CurseForge latest Retail listings were separately inspected: DynamicCam 2.21.1, Immersion ExtraFade 1.18.0 and SharedMedia_Causese 7.6. No newer package required compatibility work or pack regeneration. The stale README readiness text was corrected.

Read-only preview passed before execution. The installer then copied and hash-verified both complete folders before staging and promotion. It installed **40** current addon folders and reversibly retired `DBM-Azeroth` and `DBM-Test-Vanilla`, whose latest official metadata excludes Retail. Whole prior folders and both backups remain available. Final readback verified exact installed pack files, unrelated addon preservation, and unchanged WTF bytes/directory/link topology. No WTF file or addon-enable list was edited.

The candidate is ready for actual Retail testing; full behavior parity is not certified. Independent exact ring/Circle/cancellation/loot-hold/cinematic-hold gates, learned class/pet activation, missing LM_B2 icon, unaudited scrolling and real secure/combat/taint/rendering/persistence acceptance remain as documented in [ACCEPTANCE.md](ACCEPTANCE.md). Baseline controls remain where proof is unsupported.

Open Retail manually. Start with `/cpf status`, review the offered configuration outside combat/Edit Mode, and choose Reload after accepting. If the review is absent, `/cpf install` opens it. Use `/cpf diagnose` and the single acceptance checklist to record any failure. Dependencies can perform their native migrations on login; this disk installation itself made no configuration writes. Retain the operation backup and parked originals. Restore/recovery choices remain documented in [INSTALLATION.md](INSTALLATION.md).
