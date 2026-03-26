# 要求定義書: SnapOCR

> macOS メニューバー常駐型 OCR スクリーンキャプチャアプリ

## 1. プロジェクト概要

### 1.1 プロダクト名

**SnapOCR**

### 1.2 コンセプト

グローバルホットキー一発で画面の任意領域をキャプチャし、OCR でテキスト化してクリップボードにコピーする macOS メニューバー常駐アプリ。画像は一切保存せず、テキスト抽出に特化したユーティリティ。

### 1.3 ターゲットユーザー

- 画面上のテキストを素早くコピーしたいユーザー
- PDF や画像内のテキストを手打ちしたくないユーザー
- 同人誌・漫画・縦書きコンテンツを扱うユーザー

### 1.4 対応環境

| 項目 | 値 |
|------|-----|
| OS | macOS 26 (Tahoe) 以降 |
| アーキテクチャ | Apple Silicon (arm64) ※macOS 27 以降 Intel 非サポートのため Apple Silicon 専用 |
| 配布形態 | 直接配布（Sparkle 自動アップデート + Homebrew Cask tap + GitHub Releases） |

### 1.5 プロジェクト情報

| 項目 | 値 |
|------|-----|
| リポジトリ | `https://github.com/shiroemons/snapocr` |
| ライセンス | MIT License（オープンソース） |
| バージョニング | SemVer（MAJOR.MINOR.PATCH 形式、例: 1.0.0） |
| Bundle ID | `com.shiroemons.snapocr` |
| クラッシュレポート | なし（v1.0 ではシンプルに。必要に応じて将来導入を検討） |
| プライバシーポリシー | GitHub リポジトリの `PRIVACY.md` に簡易版を配置 |

**プライバシーポリシーの要点:**
- OCR 処理はすべてオンデバイスで完結し、外部サーバーへのデータ送信は行わない
- キャプチャ画像はメモリ上でのみ処理し、ディスクに保存しない
- OCR 履歴はローカルのアプリサンドボックス内のみに保存
- ネットワーク通信は Sparkle アップデートチェック（appcast.xml の取得）のみ
- 個人情報の収集・分析・第三者提供は一切行わない

---

## 2. 技術スタック

| レイヤー | 技術 | 選定理由 |
|----------|------|----------|
| 言語 | Swift 6.3 | macOS ネイティブ、最新の concurrency 改善（`@concurrent` 属性等）、Inline Array / Span 対応 |
| アーキテクチャ | MVVM + Service 層 | SwiftUI + `@Observable` との親和性が高い。メニューバーユーティリティの規模に適切（TCA はオーバーキル） |
| UI フレームワーク | SwiftUI (macOS 26 SDK) | Liquid Glass デザイン対応、最新 API を活用可能 |
| メニューバー | NSMenu + NSHostingView (SwiftUI ハイブリッド) | NSPopover より高速でネイティブな挙動。リッチ UI を NSMenu 内に描画 |
| OCR エンジン | Apple Vision (VNRecognizeTextRequest) | OS 標準、縦書き日本語対応、外部依存なし |
| スクリーンキャプチャ | ScreenCaptureKit | macOS 12.3+ のモダンな画面キャプチャ API |
| ホットキー | Carbon API (`RegisterEventHotKey`) | レガシーだが最も確実。アクセシビリティ権限不要、多数の実績あり |
| データ永続化 | SwiftData | macOS 26 で安定した Apple 純正 ORM。OCR 履歴の保存に最適 |
| リンター | SwiftLint (SPM Build Tool Plugin) | Swift 6 対応、Xcode ビルドフェーズ統合、CI でも利用 |
| テスト | Swift Testing (`@Test` / `@Suite` / `#expect`) | Swift 6 ツールチェーン同梱、XCTest 不要。並列実行・パラメタライズドテスト対応 |
| 自動アップデート | Sparkle 2.9+ (SPM) | macOS Tahoe 対応済み、EdDSA 署名、Sandbox 対応、Markdown リリースノート |
| CI/CD | GitHub Actions (macOS runner) | ビルド・署名・公証・appcast 生成・リリースの完全自動化 |
| パッケージ配布 | Homebrew Cask (自前 tap) | `brew install` でのインストールをサポート |
| ビルドシステム | Xcode 26.3+ / Swift Package Manager | 最新の macOS 26 SDK・agentic coding 対応 |

---

## 3. 機能要件

### 3.1 コア機能: スクリーンキャプチャ → OCR → クリップボード

#### 3.1.1 グローバルホットキー

- デフォルトキー: `⌃ + Shift + O`（OCR の O で直感的。macOS 標準・VS Code・Raycast 等と競合なし）
- アプリがフォアグラウンドでなくても動作すること
- 設定画面からカスタマイズ可能

#### 3.1.2 矩形選択キャプチャ

- ホットキー押下後、macOS 標準スクリーンショット風の矩形選択 UI を表示
- マウスドラッグで任意の矩形領域を選択
- 選択中は半透明のオーバーレイと選択範囲のハイライトを表示
- `Esc` キーでキャンセル可能
- マルチディスプレイ対応（選択開始したディスプレイ上で動作）

#### 3.1.3 OCR 処理

- Apple Vision Framework の `VNRecognizeTextRequest` を使用
- 認識レベル: `.accurate`（精度優先）
- 対応言語: 日本語 (`ja`) + 英語 (`en`) をデフォルト設定
- **縦書きテキスト対応**（`VNRecognizeTextRequest` の `automaticallyDetectsLanguage` を活用）
- 認識結果のテキストを適切な読み順序で結合
  - 横書き: 上→下、左→右
  - 縦書き: 右→左、上→下
- 認識信頼度が低いテキストの処理方針: そのまま含める（ユーザーが判断）

#### 3.1.4 クリップボードへのコピー

- OCR 結果をプレーンテキストとして `NSPasteboard` にコピー
- 複数行テキストは改行 (`\n`) で結合
- コピー完了時にユーザーに通知（設定による）

#### 3.1.5 キャプチャ画像の取り扱い

- **キャプチャ画像はメモリ上でのみ処理し、一切ディスクに保存しない**
- OCR 処理完了後、速やかにメモリから解放する

### 3.2 通知機能

通知方法は設定画面で切り替え可能とする。複数選択可。

| 通知方法 | 説明 | デフォルト |
|----------|------|-----------|
| macOS 通知センター | `UserNotifications` で通知。認識テキストのプレビューを表示 | ON |
| コピー完了音 | システムサウンド or カスタムサウンドを再生 | ON |
| 画面トースト | 画面右上に一時的なフローティングウィンドウで結果を表示（2〜3秒で自動消去） | OFF |
| 通知なし | 上記すべて無効 | — |

### 3.3 設定機能

#### 3.3.1 設定画面（Preferences）

メニューバーアイコンのクリック → 「設定」から開く。SwiftUI ベースの設定ウィンドウ（Liquid Glass デザイン準拠）。

| 設定項目 | 詳細 | デフォルト値 |
|----------|------|-------------|
| ホットキー | キーコンビネーションの録音・変更 UI | `⌃ + Shift + O` |
| OCR 言語 | 認識対象言語の選択（複数選択可） | 日本語 + 英語 |
| 通知方法 | 上記通知方法の ON/OFF 切替 | 通知センター: ON, 完了音: ON |
| ログイン時自動起動 | `SMAppService` による起動項目への登録 | OFF |
| OCR 履歴保存 | 履歴を保存するかどうか | ON |
| 履歴の保持件数 | 保存する履歴の最大件数 | 100 件 |

#### 3.3.2 ログイン時自動起動

- macOS 13+ の `SMAppService.mainApp` を使用
- 設定画面でトグルで ON/OFF

### 3.4 OCR 履歴機能

#### 3.4.1 履歴の保存

- 各 OCR 結果を以下の情報とともに保存:
  - 認識テキスト
  - タイムスタンプ
  - 認識言語（自動検出結果）
- キャプチャ画像は保存しない（テキストのみ）
- 保存先: アプリのサンドボックス内（SwiftData）

#### 3.4.2 履歴一覧

- メニューバーのポップオーバーまたは専用ウィンドウで一覧表示
- 各履歴項目をクリックでクリップボードに再コピー
- 検索・フィルタ機能（テキスト検索）
- 個別削除・一括削除

### 3.5 自動アップデート機能 (Sparkle)

#### 3.5.1 アップデート基盤

- Sparkle 2.9+ を Swift Package Manager で導入
- EdDSA (Ed25519) 署名によるアップデートの検証
- Apple Code Signing（Developer ID）によるノータリゼーション
- HTTPS 経由の appcast フィード配信

#### 3.5.2 アップデートの振る舞い

- アプリ起動時にバックグラウンドでアップデートチェック（デフォルト: 24時間ごと）
- 新バージョン検出時にリリースノート付きのアップデートダイアログを表示
- リリースノートは Markdown 形式で記述（Sparkle 2.9 の `.md` サポートを活用）
- ユーザーの任意でアップデートをインストール（自動インストールは設定で切替可能）
- デルタアップデート対応（変更部分のみダウンロード）

#### 3.5.3 appcast 配信

- appcast.xml を GitHub Pages でホスト（`shiroemons/appcast` リポジトリ → GitHub Pages）
- `generate_appcast` ツールで自動生成（署名・デルタパッチ含む）→ CI/CD で自動化（→ 3.9 参照）
- ベータチャンネルの提供を将来的に検討

#### 3.5.4 メニューバーからの手動チェック

- メニューバーに「アップデートを確認...」項目を配置
- 手動チェック時は結果を即座にダイアログで表示（最新版の場合もその旨を通知）

### 3.6 初回オンボーディング

#### 3.6.1 オンボーディングウィンドウ

初回起動時（または権限未設定時）にウェルカムウィンドウを表示する。ステップ形式で必要な権限をガイドし、ユーザーが迷わずセットアップを完了できるようにする。

**ステップ構成:**

| ステップ | 内容 | 詳細 |
|----------|------|------|
| 1. ようこそ | アプリの紹介 | アプリアイコン、プロダクト名、簡単な説明（「ホットキーで画面のテキストを瞬時にコピー」） |
| 2. 画面収録権限 | 権限の付与 | なぜ必要かを説明 → 「システム設定を開く」ボタンでシステム設定の該当ページへ遷移 → 権限状態をリアルタイムで監視し、有効化されたらチェックマーク ✅ を表示 |
| 3. ホットキー設定 | デフォルトキーの確認・変更 | デフォルト `⌃ + Shift + O` を表示。必要であればその場でカスタマイズ可能 |
| 4. 完了 | セットアップ完了 | 「使い方: ホットキーを押して範囲を選択するだけ」の簡易ガイドを表示。「始める」ボタンでウィンドウを閉じ、メニューバー常駐へ移行 |

#### 3.6.2 権限状態の監視

- `CGPreflightScreenCaptureAccess()` で画面収録権限の有効/無効をチェック
- オンボーディング中はポーリング（1秒間隔）で権限状態を監視し、ユーザーがシステム設定で許可した瞬間にUIへ反映
- 権限が有効になるまで「次へ」ボタンは非活性（ただし「スキップ」リンクで先に進むことも可能）

#### 3.6.3 オンボーディングの再表示条件

- 初回起動時に必ず表示
- 権限が未付与のまま前回スキップされた場合、次回起動時にも再表示
- 設定画面の「一般」タブから手動で再表示可能（「オンボーディングを再表示」ボタン）

### 3.7 権限ステータス管理

#### 3.7.1 メニューバーアイコンの警告表示

- 画面収録権限が無効の場合、メニューバーアイコンに **警告バッジ（⚠️）** を重畳表示
- アイコン自体を変更するか、小さな黄色の警告ドットを付与する形式（要デザイン検討）
- 権限が有効な場合は通常アイコンを表示

#### 3.7.2 メニューバーポップオーバーの警告バナー

- 権限未付与の場合、メニューバーポップオーバーの最上部に警告バナーを表示:
  - 警告アイコン（⚠️）+ 「画面収録の権限が必要です」メッセージ
  - 「設定を開く」ボタン → システム設定の画面収録ページへ遷移
- ホットキー押下時に権限がない場合も、トーストまたはアラートで権限が必要な旨を通知

#### 3.7.3 設定画面での権限ステータス表示

設定画面の「一般」タブに権限ステータスセクションを設ける:

| 権限 | 表示 | アクション |
|------|------|-----------|
| 画面収録 | ✅ 有効 / ⚠️ 無効 | 「システム設定を開く」ボタン |

- 権限状態はタブ表示時に毎回チェック（`CGPreflightScreenCaptureAccess()`）
- 無効時は赤/黄の警告テキストと共にシステム設定への導線を表示
- 有効時は緑のチェックマークとともに「有効」と表示

### 3.8 Homebrew Cask 配布

#### 3.8.1 自前 tap リポジトリ

- 既存の `shiroemons/homebrew-tap` リポジトリを使用（複数アプリの Cask を一元管理）
- `Casks/` ディレクトリに Cask 定義ファイルを配置
- ユーザーは以下のコマンドでインストール可能:

```
brew tap shiroemons/tap
brew install --cask snapocr
```

#### 3.8.2 Cask 定義ファイル

```ruby
cask "snapocr" do
  version "1.0.0"
  sha256 "..."

  url "https://github.com/shiroemons/snapocr/releases/download/v#{version}/SnapOCR-#{version}.dmg"
  name "SnapOCR"
  desc "OCR screen text via global hotkey and copy to clipboard"
  homepage "https://github.com/shiroemons/snapocr"

  depends_on macos: ">= :tahoe"

  app "SnapOCR.app"

  zap trash: [
    "~/Library/Application Support/SnapOCR",
    "~/Library/Preferences/com.shiroemons.snapocr.plist",
    "~/Library/Caches/com.shiroemons.snapocr",
  ]
end
```

#### 3.8.3 Cask 要件への対応

- Homebrew 5.0 より Cask の codesigning + notarization が必須（2026年9月以降未対応 Cask は削除）
- Developer ID 署名 + Apple ノータリゼーションは必須要件として対応済み（→ 3.9 CI/CD で自動化）
- DMG 形式で配布（`/Applications` シンボリックリンク付き）

### 3.9 CI/CD パイプライン (GitHub Actions)

#### 3.9.1 リポジトリ構成

```
shiroemons/snapocr          ← メインアプリリポジトリ
shiroemons/homebrew-tap     ← Homebrew tap リポジトリ（複数アプリ共用）
shiroemons/appcast          ← appcast.xml ホスティング（GitHub Pages、複数アプリ共用。DMG は各アプリの GitHub Releases に配置）
```

`homebrew-tap` と `appcast` は SnapOCR 専用ではなく、今後の別アプリでも共用する汎用リポジトリとして運用する。

**appcast リポジトリのディレクトリ構成:**
```
shiroemons/appcast/
├── snapocr/
│   └── appcast.xml
├── (将来の別アプリ)/
│   └── appcast.xml
└── index.html              ← GitHub Pages ルート（省略可）
```

DMG ファイルは各アプリの GitHub Releases に配置する。appcast.xml 内の `<enclosure url="...">` は GitHub Releases の DMG URL を参照する:
```
https://github.com/shiroemons/snapocr/releases/download/v1.0.0/SnapOCR-1.0.0.dmg
```

**homebrew-tap リポジトリのディレクトリ構成:**
```
shiroemons/homebrew-tap/
├── Casks/
│   ├── snapocr.rb
│   └── (将来の別アプリ).rb
└── README.md
```

#### 3.9.2 リリースワークフロー（release.yml）

GitHub Release のタグ作成（`v*.*.*`）をトリガーに、以下を完全自動化:

**ステップ:**

| # | 処理 | 詳細 |
|---|------|------|
| 1 | 依存インストール | `create-dmg`, `jq`, Sparkle CLI ツール |
| 2 | 一時キーチェーン作成 | Developer ID `.p12` 証明書をインポート |
| 3 | ビルド | `xcodebuild` で Release ビルド（arm64） |
| 4 | コード署名 | Sparkle XPC Services → フレームワーク → アプリ本体の順に署名。`--options runtime` + エンタイトルメント付き |
| 5 | 署名検証 | `codesign --verify --deep --strict` |
| 6 | ノータリゼーション | `xcrun notarytool submit --wait` → `xcrun stapler staple` |
| 7 | DMG 作成 | `create-dmg` でインストーラー DMG を生成、DMG 自体もノータリゼーション + ステープル |
| 8 | Sparkle 署名 | `sign_update` で DMG を EdDSA 署名 |
| 9 | appcast 生成 | `generate_appcast` でデルタアップデート + appcast.xml 生成。リリースノートは GitHub Release body から Markdown で取得 |
| 10 | GitHub Release アップロード | DMG + デルタアップデートファイルを GitHub Release Assets に添付 |
| 11 | appcast デプロイ | appcast.xml を `shiroemons/appcast` リポジトリの `snapocr/` ディレクトリに push → GitHub Pages で配信（DMG の URL は GitHub Releases を参照） |
| 12 | Homebrew tap 更新 | `shiroemons/homebrew-tap` の `Casks/snapocr.rb` を新バージョン + SHA256 で自動更新 PR 作成 |

#### 3.9.3 GitHub Secrets

| Secret 名 | 用途 |
|-----------|------|
| `DEVELOPER_ID_P12` | Developer ID Application 証明書（base64 エンコード） |
| `DEVELOPER_ID_P12_PASSWORD` | .p12 ファイルのパスワード |
| `APPLE_ID` | Apple ID メールアドレス（ノータリゼーション用） |
| `APPLE_APP_PASSWORD` | Apple ID のアプリ用パスワード |
| `APPLE_TEAM_ID` | Apple Developer Team ID |
| `SPARKLE_PRIVATE_KEY` | Sparkle EdDSA 秘密鍵（`generate_keys` で生成） |
| `DEPLOY_KEY` | `shiroemons/appcast` リポジトリへの push 用 SSH デプロイキー |
| `HOMEBREW_TAP_TOKEN` | `shiroemons/homebrew-tap` リポジトリの Cask 定義更新用 GitHub PAT |

#### 3.9.4 CI ワークフロー（ci.yml）

PR / push 時に実行する品質保証ワークフロー:

- **SwiftLint**: SPM Build Tool Plugin として統合。ビルド時に自動実行 + CI でも `swift package plugin lint` で実行。violation があれば CI を fail
- **ビルド確認**: `xcodebuild build` で Release / Debug 両構成のビルドを検証
- **テスト実行**: `xcodebuild test` で Swift Testing ベースのテストを実行（`--parallel-testing-enabled YES`）
- macOS runner: `macos-15`（Xcode 26.3+ プリインストール）

#### 3.9.5 リリース手順（開発者向け）

1. `Info.plist` のバージョン番号をバンプ（`CFBundleShortVersionString` + `CFBundleVersion`）
2. GitHub で Release を作成（タグ: `v1.0.0` 形式、Release notes を Markdown で記述）
3. GitHub Actions が自動で全ステップを実行
4. 完了後: Sparkle 経由で既存ユーザーにアップデート通知 + Homebrew tap が更新 + GitHub Release に DMG + デルタアップデート添付

---

### 3.10 コード品質: SwiftLint

#### 3.10.1 導入方式

- Swift Package Manager の **Build Tool Plugin** として導入（Xcode ビルド時に自動実行）
- `Package.swift` に `SwiftLintPlugin` を追加し、各ターゲットに `.plugin(name: "SwiftLintBuildToolPlugin")` を設定
- CI でも同一ルールで lint を実行（→ 3.9.4 参照）

#### 3.10.2 設定ファイル（.swiftlint.yml）

プロジェクトルートに `.swiftlint.yml` を配置:

- デフォルトルールをベースに、プロジェクトに合わせてカスタマイズ
- `disabled_rules`: 過度に厳しいルールを無効化（必要に応じて）
- `opt_in_rules`: `sorted_imports`, `unused_import`, `vertical_whitespace_closing_braces` 等を有効化
- `excluded`: ビルド成果物、SPM の `.build/` ディレクトリを除外
- `line_length`: warning 120 / error 160
- `function_body_length`: warning 50 / error 100
- Swift 6 の concurrency 関連ルールを有効化

#### 3.10.3 運用ルール

- CI で SwiftLint violation（warning 含む）がある場合は **ビルド失敗** とする（`--strict` モード）
- `swiftlint --fix` による自動修正を開発者ローカルで推奨（PR 前に実行）
- 新規ルール追加時はチームで合意の上、段階的に導入

### 3.11 テスト戦略: Swift Testing

#### 3.11.1 フレームワーク

- **Swift Testing** を使用（Swift 6 ツールチェーン同梱、追加依存不要）
- XCTest は使用しない（新規プロジェクトのため Swift Testing に統一）
- `@Test` / `@Suite` / `#expect` / `#require` マクロを活用

#### 3.11.2 テスト構成

| テスト対象 | テスト内容 | 方式 |
|-----------|-----------|------|
| OCR テキスト処理 | 読み順ソート（横書き・縦書き）、テキスト結合ロジック | `@Test` + パラメタライズドテスト |
| 設定管理 | UserDefaults / SwiftData の読み書き、デフォルト値 | `@Suite` でグループ化 |
| クリップボード | `NSPasteboard` へのコピー処理 | `@Test` |
| 履歴管理 | SwiftData CRUD、件数制限、検索 | `@Suite(.serialized)` で直列実行 |
| Sparkle 設定 | appcast URL、EdDSA 公開鍵の妥当性 | `@Test` |
| ホットキー | キーコンビネーションの登録・解除・競合チェック | `@Test` |

#### 3.11.3 テスト方針

- テストはデフォルトで **並列実行**（Swift Testing の標準動作）
- 状態を共有するテストは `@Suite(.serialized)` で直列化
- `#expect` でアサーション（式の左右両辺が自動キャプチャされ、失敗時の診断が明確）
- `#require` でテスト前提条件のバリデーション（失敗時は即テスト中断）
- `@Test(.enabled(if:))` で環境依存テストの条件付き実行
- パラメタライズドテストで OCR 言語・テキスト方向の組み合わせを網羅

#### 3.11.4 テスト対象外（v1.0 時点）

- UI テスト（Swift Testing は現時点で UI テスト未サポート。必要に応じて XCUITest で補完）
- パフォーマンステスト（Swift Testing 未サポート。必要に応じて XCTest `measure {}` で補完）

---

## 4. 非機能要件

### 4.1 パフォーマンス

| 項目 | 目標値 |
|------|--------|
| ホットキーから選択 UI 表示まで | 200ms 以内 |
| 選択完了から OCR 結果コピーまで | 1 秒以内（一般的なテキスト量） |
| メモリ使用量（待機時） | 50MB 以下 |
| CPU 使用率（待機時） | ほぼ 0% |

### 4.2 セキュリティ・プライバシー

- スクリーンキャプチャには **画面収録権限** が必要（`CGPreflightScreenCaptureAccess` / `CGRequestScreenCaptureAccess`）
- 初回起動時にオンボーディングウィンドウで権限設定をガイド（→ 3.6 参照）
- アプリ動作中も権限状態を定期監視し、無効時は警告を表示（→ 3.7 参照）
- キャプチャ画像は一切ディスク保存しない
- OCR 処理はすべてオンデバイスで完結（ネットワーク通信なし）
- アップデートチェック時のみ HTTPS で appcast サーバーに接続（Sparkle による EdDSA + Code Signing 検証）
- 履歴データはアプリサンドボックス内のみに保存

### 4.3 アクセシビリティ

- VoiceOver 対応（設定画面・履歴一覧）
- キーボードナビゲーション対応

### 4.4 ローカライゼーション

- v1.0 から **日本語 + 英語** の2言語に対応
- Xcode の String Catalog (`.xcstrings`) を使用（Xcode 15+ の標準ローカライズ管理）
- デフォルト言語: 日本語（`ja`）、英語（`en`）をサポート
- 対象: UI テキスト（メニュー、設定画面、オンボーディング、通知、警告バナー、トースト等）
- macOS のシステム言語設定に自動追従
- `LocalizedStringKey` / `String(localized:)` を使用し、ハードコードされた文字列を排除

---

## 5. 画面構成

### 5.1 メニューバーパネル

メニューバーアイコンをクリックすると、NSMenu + NSHostingView によるリッチなパネルを表示する。NSPopover ではなく NSMenu ベースを採用し、クリック即表示・外側クリックで自動消去のネイティブな挙動を実現する（参考: CleanShot X, Paste, BetterDisplay 等のモダンアプリ）。

**アイコン:** SF Symbols の `text.viewfinder`（または専用アイコン）を template image として設定。ライト/ダークモード自動対応。

#### 5.1.1 パネルレイアウト

パネル幅は約 320pt。セクションごとに視覚的に区切り、情報密度とアクセスのしやすさを両立する。

```
┌─────────────────────────────────────────┐
│  ⚠️ 画面収録の権限が必要です             │  ← 権限未付与時のみ表示
│  テキストを読み取るには権限が必要です      │    黄色背景の警告バナー
│               [システム設定を開く]        │    クリックでシステム設定へ遷移
├─────────────────────────────────────────┤
│                                         │
│  📷  テキストをキャプチャ     ⌃⇧O       │  ← メインアクション（大きめ表示）
│                                         │    クリックで即キャプチャ開始
├─────────────────────────────────────────┤
│  最近のキャプチャ                         │  ← セクションヘッダー（ミュートカラー）
│                                         │
│  📋 シロさん、お帰りなさい     12:34     │  ← 各行ホバーでハイライト
│  📋 Hello World               12:30     │    クリックでクリップボードに再コピー
│  📋 第3章 夏の終わりに         12:25     │    テキストは1行に truncate
│  📋 お問い合わせはこちら       12:20     │
│  📋 2026年3月23日（月）        12:15     │
│                                         │
│  すべての履歴を表示...                    │  ← クリックで履歴ウィンドウを開く
├─────────────────────────────────────────┤
│  ⚙️ 設定...    🔄 アップデートを確認     │  ← フッターツールバー
│                          SnapOCR v1.0   │    バージョン表示
│                              [終了]     │
└─────────────────────────────────────────┘
```

#### 5.1.2 各セクションの詳細

**警告バナー（条件付き表示）**
- 画面収録権限が未付与の場合のみ、パネル最上部に黄色/オレンジの警告バナーを表示
- SF Symbols `exclamationmark.triangle.fill` + 説明テキスト + アクションボタン
- 権限が有効な場合はバナーごと非表示（パネルがコンパクトになる）

**メインアクションエリア**
- 「テキストをキャプチャ」ボタンを目立つサイズで配置
- 設定中のホットキーをショートカットラベルとして右端に表示（例: `⌃⇧O`）
- クリックでポップオーバーを閉じ、即座に矩形選択モードに入る
- ホバー時にサブテキスト「矩形で範囲を選択 → テキストをコピー」を表示

**最近のキャプチャ（履歴プレビュー）**
- 直近 5 件の OCR 結果をリスト表示
- 各行: クリップボードアイコン + テキスト（1行 truncate, 最大約30文字）+ タイムスタンプ（相対時間 or HH:mm）
- ホバーでハイライト + ツールチップに全文プレビュー表示
- クリックでクリップボードに再コピー（コピー完了のフィードバックをインラインで表示: アイコンが一瞬 ✅ に変化）
- 履歴が空の場合: 「まだキャプチャがありません」の placeholder テキスト
- 「すべての履歴を表示...」リンクで履歴ウィンドウを開く

**フッターツールバー**
- アイコンボタンを横並びに配置（テキストではなく SF Symbols アイコン中心）
- ⚙️ `gear` → 設定ウィンドウを開く
- 🔄 `arrow.triangle.2.circlepath` → アップデートを確認
- バージョン番号をミュートカラーで右端に表示
- 「終了」ボタンは右下にテキストリンクとして控えめに配置

#### 5.1.3 メニューバーアイコンの状態

| 状態 | アイコン表示 |
|------|-------------|
| 通常（権限有効） | `text.viewfinder` (template image) |
| 権限未付与 | `text.viewfinder` + 小さな黄色ドットバッジ（⚠️） |
| キャプチャ中 | アイコンをアクティブ状態に変更（塗りつぶし or アニメーション） |
| OCR 処理中 | アイコンに小さなスピナー（Processing インジケータ） |

#### 5.1.4 実装方式

- `NSStatusItem` + `NSMenu` に `NSMenuItem` として `NSHostingView(rootView:)` を埋め込む
- NSPopover は不使用（遅延・不自然な挙動を回避）
- パネル内の SwiftUI View は `@Observable` で状態管理
- メニュー表示時に権限状態チェック・履歴データの最新取得を行う
- メニュー外クリックで自動消去（NSMenu のネイティブ挙動）

### 5.2 矩形選択オーバーレイ

- 全画面を暗転（半透明黒オーバーレイ）
- マウスドラッグで矩形選択
- 選択中の領域は元の明るさで表示（macOS スクリーンショット風）
- 選択領域のサイズ（px）をリアルタイム表示

### 5.3 オンボーディングウィンドウ

- ステップ形式のウィザード UI（SwiftUI `TabView` + ページスタイル、または独自ステッパー）
- 画面中央に表示、背景は半透明ブラー
- 各ステップに「戻る」「次へ」「スキップ」のナビゲーション

```
┌──────────────────────────────────────┐
│         [SnapOCR アイコン]            │
│                                      │
│     画面収録の権限を設定してください     │
│                                      │
│  SnapOCR が画面上のテキストを読み取る   │
│  ために、画面収録の権限が必要です。      │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  画面収録   ⚠️ 未設定           │  │
│  │  [システム設定を開く]           │  │
│  └────────────────────────────────┘  │
│                                      │
│     （スキップ）         [次へ →]     │
└──────────────────────────────────────┘
```

- 権限が有効化されると「⚠️ 未設定」→「✅ 有効」にリアルタイムで切り替わる
- 有効化後は「次へ」ボタンがアクティブになり、強調表示

### 5.4 設定ウィンドウ

- SwiftUI の `TabView` でタブ分け:
  - **一般**: 権限ステータス（画面収録: ✅ 有効 / ⚠️ 無効 + 「システム設定を開く」）、ホットキー設定、ログイン時自動起動、「オンボーディングを再表示」ボタン
  - **OCR**: 言語選択
  - **通知**: 通知方法の切替
  - **履歴**: 保持件数設定、一括削除ボタン
  - **アップデート**: 自動チェック ON/OFF、チェック間隔、自動インストール ON/OFF

### 5.5 履歴ウィンドウ

- リスト形式で OCR 結果を時系列表示
- 各行: テキストプレビュー（1行目のみ）+ タイムスタンプ
- クリックで全文表示 + クリップボードにコピーボタン
- 上部に検索バー

---

## 6. 必要な権限 (Entitlements / 権限)

| 権限 | 用途 | 必須 |
|------|------|------|
| 画面収録 (Screen Recording) | スクリーンキャプチャ取得 | ✅ |
| アクセシビリティ (Accessibility) | Carbon API 方式では不要 | — |
| 通知 (Notifications) | 通知センターへの通知送信 | ✅ |
| ネットワーク (Outgoing Connections) | Sparkle アップデートチェック（HTTPS） | ✅ |

---

## 7. 既知の技術的課題・検討事項

### 7.1 グローバルホットキーの実装方式

Carbon API (`RegisterEventHotKey` / `UnregisterEventHotKey`) を採用する。

**選定理由:**

- アクセシビリティ権限が不要（`CGEvent` tap 方式と異なり、追加の権限リクエストが発生しない）
- macOS 26 (Tahoe) でも引き続き動作する実績がある
- Alfred、Raycast、CleanShot X 等の著名メニューバーアプリでも広く使用
- サードパーティ依存なし（OS 標準の Carbon フレームワーク）

**実装上の注意点:**

- Carbon API は C ベースのため、Swift からのブリッジコードが必要（`InstallEventHandler` / `EventHotKeyID` 等）
- ホットキーの録音 UI（設定画面でユーザーがキーを変更する部分）は別途 SwiftUI で自前実装するか、録音 UI 部分のみ軽量ライブラリを検討
- `RegisterEventHotKey` で登録したホットキーはアプリ終了時に `UnregisterEventHotKey` で解除すること
- macOS 標準ショートカットとの競合チェックを設定画面で実装

### 7.2 縦書きテキストの読み順

- `VNRecognizeTextRequest` は認識結果を `VNRecognizedTextObservation` の配列で返す
- 各 observation の `boundingBox` の座標から縦書き/横書きを推定し、適切な順序でソートする必要がある
- 縦書き判定ロジック: 各テキストブロックの幅と高さの比率で判定

### 7.3 macOS Tahoe の画面収録権限

- macOS 26 (Tahoe) では画面収録権限のポリシーが従来より厳格化されている
- `ScreenCaptureKit` の `SCContentFilter` + `SCScreenshotManager` の利用を推奨
- Liquid Glass デザインへの対応も考慮すること（SwiftUI macOS 26 SDK で自動対応）
- `CGPreflightScreenCaptureAccess()` は権限の有無を返すが、権限付与ダイアログをトリガーしない
- `CGRequestScreenCaptureAccess()` は初回のみシステムダイアログを表示。2回目以降は表示されないため、オンボーディングではシステム設定への直接遷移を案内する必要がある
- macOS 26 では権限変更後にアプリの再起動が求められるケースがあるため、オンボーディングで権限付与後にリスタート案内を表示することも検討

### 7.4 メニューバーパネルの実装方式: NSMenu vs NSPopover

- **NSPopover**: SwiftUI との統合が容易だが、表示に微妙な遅延があり、外側クリックでの消去挙動が不自然。「フローティングアプリ」のように見え、システムユーティリティらしさに欠ける
- **NSMenu + NSHostingView**: クリック即表示、外側クリックで自動消去。ネイティブなメニュー挙動でシステムに溶け込む。多くのモダンなメニューバーアプリ（CleanShot X, BetterDisplay 等）が採用
- → 推奨: **NSMenu + NSHostingView** 方式を採用。NSMenuItem の `view` プロパティに SwiftUI の `NSHostingView` を設定し、リッチな UI を NSMenu 内に描画する
- 注意: NSMenu 内の SwiftUI View では一部の SwiftUI 機能（シート、フルスクリーンカバー等）が使えないため、設定ウィンドウや履歴ウィンドウは別ウィンドウとして開く

### 7.5 App Sandbox との兼ね合い

- Mac App Store 配布の場合、App Sandbox が必須
- グローバルホットキーや画面収録との互換性を確認する必要あり
- 直接配布（Sparkle）のため App Sandbox は任意だが、セキュリティ向上のため Sandbox 化を推奨
- Sparkle 2.9 は XPC Services による Sandbox 対応済み
- ノータリゼーション（公証）は必須。Developer ID で署名 + `xcrun notarytool` で公証
- macOS 27 以降は Intel Mac 非サポートとなるため、Apple Silicon 専用ビルドで問題なし

---

## 8. マイルストーン（案）

| フェーズ | 内容 | 成果物 |
|----------|------|--------|
| Phase 1 | プロジェクト基盤構築 + コア機能実装（SwiftLint 導入、Swift Testing セットアップ、ホットキー → キャプチャ → OCR → クリップボード） | テスト付き最小動作版 |
| Phase 2 | メニューバー UI + 設定画面 + オンボーディング + 権限ステータス管理 | 設定可能な常駐アプリ |
| Phase 3 | 通知機能（全4種 + 切替）| 通知対応版 |
| Phase 4 | OCR 履歴機能 | 履歴付き完成版 |
| Phase 5 | Sparkle 自動アップデート + ノータリゼーション + appcast 配信基盤 | 配布可能版 |
| Phase 6 | GitHub Actions CI/CD パイプライン構築（ビルド・署名・公証・appcast・リリース全自動化） | 自動リリース基盤 |
| Phase 7 | Homebrew Cask tap 構築 + Cask 自動更新 | `brew install` 対応 |
| Phase 8 | ポリッシュ（アイコン、パフォーマンス最適化、エッジケース対応） | v1.0 リリース候補 |

---

## 9. 将来的な拡張案（v2.0 以降）

- OCR 結果の自動翻訳機能
- テキスト認識後の後処理オプション（トリム、改行除去、正規表現置換等）
- Shortcuts.app 連携（ショートカットアクションの提供）
- OCR 結果を Markdown やリッチテキストとしてコピー
- 連続キャプチャモード（ホットキーを押し続けている間、複数回キャプチャ可能）
- AI ベースの高精度 OCR（オプション）
- UI の多言語対応拡充（中国語（簡体字/繁体字）、韓国語 等）
- Sparkle ベータチャンネルの提供（先行アップデートの配信）
- Homebrew 公式 homebrew-cask への PR 提出（ユーザー数が十分に増えた段階で）
- GitHub Actions でのナイトリービルド自動配信

---

## 改訂履歴

| 日付 | バージョン | 内容 |
|------|-----------|------|
| 2026-03-23 | 0.1 | 初版作成 |
| 2026-03-23 | 0.2 | 最新バージョンに更新: Swift 6.3 / Xcode 26.3+ / macOS 26 (Tahoe) / Apple Silicon 専用 / SwiftData / Liquid Glass デザイン対応 |
| 2026-03-23 | 0.3 | Sparkle 2.9+ による自動アップデート機能を追加。配布形態を直接配布に決定。アップデート設定タブ、メニュー項目、appcast 配信基盤、Phase 5 を追加 |
| 2026-03-23 | 0.4 | 初回オンボーディング（ステップ形式ウィザード）を追加。権限ステータス管理（メニューバー警告バッジ、ポップオーバー警告バナー、設定画面での権限チェック）を追加 |
| 2026-03-23 | 0.5 | メニューバーパネルをモダンアプリ参考に全面刷新。NSMenu + NSHostingView 方式を採用。リッチパネルレイアウト（警告バナー・メインアクション・履歴プレビュー・フッターツールバー）、アイコン状態管理、実装方式を詳細化 |
| 2026-03-23 | 0.6 | Homebrew Cask tap 対応（自前 tap リポジトリ + Cask 定義）と GitHub Actions CI/CD パイプライン（ビルド・署名・公証・appcast・DMG・Homebrew tap 更新の完全自動化）を追加。リポジトリ構成・Secrets 定義・リリース手順を詳細化 |
| 2026-03-23 | 0.7 | リポジトリを `shiroemons/snapocr` に統一。Bundle ID を `com.shiroemons.snapocr` に変更 |
| 2026-03-23 | 0.8 | SwiftLint（SPM Build Tool Plugin、`.swiftlint.yml` 設定、CI --strict 運用）と Swift Testing（`@Test` / `@Suite` / `#expect`、テスト構成・方針）を追加。Phase 1 にプロジェクト基盤構築を含める |
| 2026-03-23 | 0.9 | v1.0 から日本語 + 英語の2言語対応に変更。String Catalog (`.xcstrings`) 採用。Homebrew Cask desc を英語に統一 |
| 2026-03-23 | 0.10 | リポジトリ構成を汎用化: tap を `shiroemons/homebrew-tap`、appcast を `shiroemons/appcast` に変更（複数アプリ共用）。appcast はアプリごとのサブディレクトリ構成。`brew tap shiroemons/tap` に統一 |
| 2026-03-23 | 0.11 | DMG を `shiroemons/snapocr` の GitHub Releases に配置する構成に変更。appcast リポジトリには appcast.xml のみ。デルタアップデートも GitHub Releases に添付 |
| 2026-03-23 | 0.12 | グローバルホットキーを Carbon API (`RegisterEventHotKey`) に確定。アクセシビリティ権限不要。選定理由・実装注意点を詳細化。権限テーブルから Accessibility を不要に変更 |
| 2026-03-23 | 1.0 | 要求定義書ファイナライズ: アプリ名「SnapOCR」確定、MVVM アーキテクチャ採用、MIT License、デフォルトホットキー `⌃⇧O` 確定、クラッシュレポートなし、SemVer バージョニング、プライバシーポリシー方針、プロジェクト情報セクション追加 |
