# 注意

これは個人的に使っている gem です。ノーサポート、ノー後方互換性なのでもし使いたい人がいたら fork をおすすめします。

# all_lint — **1 つの YAML**で複数リンターを最小実行

**目的**：複数リンターを「設定ファイル 1 枚 + コマンド 1 個」で順番に実行するだけ。
**非目的**：Git 連携・差分検出・環境変数注入・高度な分岐など一切なし。

- 設定は **glob** と **command** のみ
- 実行は **順次のみ**（並列なし）
- `glob` に 1 件もマッチしなければ **そのリンターはスキップ**（空実行なし）
- CLI は **2 モード**のみ

  1. `all_lint run` → 設定の `glob` で**全ファイル探索**
  2. `all_lint run <files...>` → 引数で受けた**指定ファイルのみ**を対象（`glob` でさらに絞り込み）

---

## インストール

プロジェクトローカル推奨:

```rb
# Gemfile
gem "all_lint", "~> 0.1"
```

```bash
bundle install
```

または

```bash
gem install all_lint
```

---

## 使い方（クイック）

1. ルートに **`.all_lint.yml`** を作成

```yml
linters:
  rubocop:
    glob: ["**/*.rb", "**/*.rake"]
    command: "bundle exec rubocop ${filter_files}"

  eslint:
    glob: ["**/*.{js,jsx,ts,tsx}"]
    command: "npx eslint ${filter_files}"
```

2. 実行

```bash
# 全ファイルから glob で探索して順次実行
all_lint run

# 変更のあったファイルなど任意に指定して、その中から glob で絞り込んで実行
all_lint run app/models/user.rb frontend/src/App.tsx
```

---

## 設定ファイル仕様（`.all_lint.yml`）

### ルートキー

- `linters`（必須）: linter 名（任意キー）ごとの設定

### `linters.*` の項目

- `glob`（必須）

  - 文字列 or 文字列配列。`Dir.glob` 互換。
  - 例: `"**/*.rb"` / `["**/*.rb", "**/*.rake"]`

- `command`（必須）

  - 実行コマンド。`${filter_files}` を含めると、対象ファイル群（スペース区切り）を展開して渡す。
  - 例: `"bundle exec rubocop ${filter_files}"`

> **重要**：`glob` の結果が **空** の場合、そのリンターは **実行しません**（`command` は呼びません）。
> `${filter_files}` が空文字になることは**ありません**。

---

## CLI

```
all_lint run [<file>...]
```

- 引数 **なし**：設定の `glob` に従い、プロジェクト全体から対象ファイルを収集して実行
- 引数 **あり**：**渡されたファイル列のみ**を母集団とし、各 linter の `glob` で**さらに絞り込んで**実行
  （= `glob ∩ 渡されたファイル` が空ならそのリンターはスキップ）

> 実行順は **設定記述順**。並列実行はしません。

---

## 変数展開

- `${filter_files}`：そのリンターで最終的に決定した**対象ファイルの配列**をスペース区切りで展開

  - macOS/Linux 前提。パスに空白がある場合は各自で回避（推奨：空白を含むパスを使わない / OS 標準の制約に従う）。

---

## 振る舞い（仕様の要点）

1. 設定ファイルが読めない／不正な場合は即時エラー終了
2. 各リンターごとに対象ファイルを決める

   - 引数があれば**引数のファイル群**を起点に `glob` で絞り込み
   - 引数がなければ**リポジトリ全体**を起点に `glob` で探索

3. 対象が**1 件以上**ある場合のみ `command` を実行
4. いずれかのリンターの `command` が非 0 を返したら **全体の終了コードは非 0**
5. ログは

   - 実行する前に `==> [linter名] <command...>` を 1 行出す
   - 各 linter の標準出力・標準エラーはそのまま中継

---

## 終了コード

- **0**：すべて成功（または全部スキップ）
- **1**：少なくとも 1 つのリンターが失敗
- **2**：設定ファイルエラー・CLI エラー など実行前の不備

---

## 例

### 最小構成

```yml
linters:
  rubocop:
    glob: ["*.rb", "*.rake"]
    command: "rubocop ${filter_files}"

  eslint:
    glob: "*.js"
    command: "eslint ${filter_files}"
```

```bash
# 例1: 全体対象
all_lint run

# 例2: 任意ファイルのみ
all_lint run Rakefile scripts/setup.rb app.js
```

### TypeScript を含める

```yml
linters:
  eslint:
    glob: ["**/*.{js,jsx,ts,tsx}"]
    command: "pnpm eslint ${filter_files}"
```

---

## サポート環境

- Ruby **>= 3.1**
- macOS / Linux
- 各リンターはプロジェクト側でインストールしておくこと（`bundle exec` や `npx` 等で呼び出し）

---

## 非対応（明示）

- 並列実行、キャッシュ、差分検出、Git 連携、`options` セクション、環境変数注入、作業ディレクトリ変更、除外設定、バッチ分割、Windows 対応

> 必要になったら別ツールで補完、もしくは将来の拡張として検討してください。

---

## Try it（ローカル実行）

1. インストール

```bash
bundle install
```

2. 最小設定を書く

```yaml
# .all_lint.yml
linters:
  echo:
    glob: ["**/*.rb"]
    command: "bash -lc 'echo RUN ${filter_files}'"
```

3. ダミーファイルを用意

```bash
echo '# a' > a.rb
echo '# b' > b.txt
```

4. 実行

```bash
bundle exec exe/all_lint run
bundle exec exe/all_lint run a.rb b.txt
```
