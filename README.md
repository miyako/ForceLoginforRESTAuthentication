# 4DにおけるREST認証の強制ログイン

Force Login for REST Authentication in 4D: Japanese edition.

4Dの「強制ログイン（Force Login）」モードは、RESTサービスへのアクセスにサインインを必須とし、権限が割り当てられるまでライセンスを消費しないゲストセッションから始まる仕組みです。本テクニカルノートでは、レガシーなREST認証設定からの移行方法、`ds.authentify()`関数の実装方法、ライセンス消費のタイミング、そして`roles.json`による権限とパーミッションの定義を説明します。付属のデモは、4Dユーザーグループで認証し、`Company`データクラスに対する参照・作成・更新・削除のRESTリクエストを権限ごとに試せるRESTサーバーです。

The note explains how to migrate from legacy REST authentication to Force Login, how to write `ds.authentify()`, when a license is consumed, and how to define privileges and permissions in `roles.json`. The demo is a REST server for trying each request in the note (authentication, read, create, update, delete) against the `Company` dataclass.

## Download

| | |
|---|---|
| PDF (Japanese) | [25-10_ForceLoginforRESTAuthentication_ja.pdf](https://github.com/miyako/ForceLoginforRESTAuthentication/releases/latest/download/25-10_ForceLoginforRESTAuthentication_ja.pdf) |
| 4D demo | [ForceLoginforRESTAuthentication.zip](https://github.com/miyako/ForceLoginforRESTAuthentication/releases/latest/download/ForceLoginforRESTAuthentication.zip) |
| Original (English) | `document/25-10_ForceLoginforRESTAuthentication.pdf` |

## Demo

- 4D version: 4D 20 R6 or later (Force Login mode). Compile-checked with tool4d 21 R3.
- Open `demo/ForceLoginforRESTAuthentication/Project/ForceLoginforRESTAuthentication.4DProject`.
- The REST server and the web server start with the project (default port, `http://localhost/rest/...`), with `forceLogin: true` in `Project/Sources/roles.json`.
- The demo has no forms or UI strings, so it is not localised. Send the requests from Postman or any HTTP client, as in the note.
- Authentication uses the 4D user `John`, a member of the `RestAccess` group (`Settings/directory.json`).

### Demo data

The zip contains no data file, so the `Company` table starts empty. To add records, either run the project method `addCompany` (adds one sample company), or authenticate and create records with REST as shown in the section 「新しいCompanyレコードの作成」. Primary keys depend on the records you create, so adjust examples such as `Company(1)` accordingly.

## Differences from the original

- fig-03 (Structure Settings > Web > Web Features) is replaced with a screenshot of the Japanese 4D interface. The other screenshots (Postman, Qodly Studio, the 4D code editor) are kept in English; Qodly Studio is English-only.
- The code for options A and B is given with valid 4D line breaks; the original PDF wraps these statements mid-line.
- The permission-actions table and the `roles.json` syntax table were rebuilt from the original layout.
- The demo fixes two bugs in the original project: `authentify()` now tests its `$credentiels` parameter instead of an undefined variable, and `getCompanyByName()` declares its `Collection` return type. An unused test method was removed.

## Editing and rebuilding

The PDF is generated from plain-text sources. Edit them and run `make`.

| File | What |
|---|---|
| `src/ja.md` | Translated body text. **Don't touch code blocks** (`make check` verifies them). |
| `figures/fig-NN.ja.txt` | Text drawn in figure NN. Line N corresponds to line N of `fig-NN.en.txt`: an identical line keeps the original, an empty line erases it. (Not used in this edition: all figures are screenshots.) |
| `figures/layout/fig-NN.json` | Per-label overrides for size, weight, alignment and position; `"replace"` uses a ready-made image (fig-03 uses `fig-03-ja.png`) |
| `glossary.md` | Terminology |

```sh
make            # check → figures → build/25-10_ForceLoginforRESTAuthentication_ja.pdf
make check      # code blocks unchanged, figure references complete
make review     # contact sheets of the figures (build/contact-N.png)
make release-assets
```

Requirements: Python 3, Google Chrome, CJK fonts, and Tesseract (only needed for re-extraction).
See the [localisation template](https://github.com/miyako/4d-technote-localisation-template) for the full workflow.

## Credits

- Original: Abir HSAINI, Technical Services Engineer, 4D Inc. (Technical Note 25-10)
- Produced with [4d-technote-localisation-template](https://github.com/miyako/4d-technote-localisation-template) and GitHub Copilot.
