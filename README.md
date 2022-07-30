# AviUtl-Installer-pwsh
PowershellによるAviUtlの初期環境構築スクリプト

[/aviutl/セットアップ](https://scrapbox.io/aviutl/セットアップ) を自動的に行います。

追加で以下のプラグイン等をインストールします。

- [LuaJIT](https://github.com/Per-Terra/LuaJIT-Auto-Builds)
- [Aulsメモリ参照プラグイン](https://scrapbox.io/ePi5131/Aulsメモリ参照プラグイン)
- [rikkymodule&memory](https://hazumurhythm.com/wev/amazon/?script=rikkymodulea2Z)

## 特徴
- ワンライナーのコードを実行するだけで、AviUtlの初期環境構築が完了します。
- ソースコードを除くすべてのファイルを保持します。
    - 自動で接頭辞(prefix)を付けます。
    - Readmeなどを必要なときに参照できます。
- 主要な推奨設定を自動的に適用します。
    - [/aviutl/セットアップ](https://scrapbox.io/aviutl/セットアップ) で推奨される設定及び [ePi5131/私のAviUtlの構成](https://scrapbox.io/ePi5131/私のAviUtlの構成) をもとに設定を適用します。
    - 実際の変更内容はスクリプトを確認してください。

## 実行
0. PowerShell 6.2以降が必要です。
    - 最新のPowershellの入手方法は[こちら](https://docs.microsoft.com/ja-jp/powershell/scripting/install/installing-powershell-on-windows)を参照してください。
    - winget経由でインストールする場合は以下のコマンドを実行してください。
      ```bat
      winget install --id Microsoft.Powershell --source winget
      ```

1. エクスプローラーでインストール先のフォルダを開いてください。
    - ファイルは`AviUtl_yyyyMMddHHmmss`フォルダ内に展開されます。

1. アドレスバーに次のコマンドを入力し、実行してください。
    ```bat
    pwsh -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Per-Terra/AviUtl-Installer-pwsh/main/installer.ps1'))"
    ```
    > **Note**
    > エラーが出力された場合は Issue で報告してください。

1. インストールが完了したら、AviUtl が正常に起動することを確認してください。

## ToDo
- [ ] README.mdに説明画像を追加
- [ ] パッケージ情報のJSONなどへの分離
- [ ] その他のパッケージを追加
- [ ] インストールするパッケージを選択できるように
- [ ] 進捗状況の出力
- [ ] 環境構築後のアップデートに対応
- [ ] iniの並び順への対応

## 注意事項
- iniの設定項目が標準とは異なる順に並びます。
    - 実用上の問題はありません。
    - 必要に応じて一度iniファイルを削除し、自分で設定してください。

## ライセンス
[MIT License](LICENSE)に基づく
