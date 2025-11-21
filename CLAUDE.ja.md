# CLAUDE.md - Tesla Fleet API用AIアシスタントガイド

このドキュメントは、Tesla Fleet API Dartパッケージで作業するAIアシスタント向けの包括的なガイダンスを提供します。コードベース構造、開発ワークフロー、規約、ベストプラクティスについて説明します。

## プロジェクト概要

**パッケージ名**: `tesla_fleet_api`
**バージョン**: 1.0.0
**言語**: Dart
**SDK**: >= 3.0.0 < 4.0.0
**リポジトリ**: https://github.com/cutmail/tesla_fleet_api
**ライセンス**: MIT

### 目的

Tesla Fleet APIと連携するための包括的なDartパッケージで、以下の機能を提供します：
- 車両管理と制御（ロック/アンロック、空調、充電）
- エネルギー製品の監視と制御（ソーラー、Powerwall）
- 充電セッション履歴と請求書
- パートナーアカウント管理
- 複数地域のサポート（北米/アジア太平洋、ヨーロッパ/中東/アフリカ、中国）
- OAuth 2.0認証（認可コードフローとクライアントクレデンシャルフロー）

## コードベース構造

```
tesla_fleet_api/
├── lib/
│   ├── tesla_fleet_api.dart        # メインエントリポイント（すべての公開APIをエクスポート）
│   └── src/
│       ├── auth/
│       │   └── tesla_auth.dart     # OAuth 2.0認証（235行）
│       ├── endpoints/
│       │   ├── charging_endpoints.dart    # 充電履歴/セッション（73行）
│       │   ├── energy_endpoints.dart      # エネルギー製品（124行）
│       │   ├── partner_endpoints.dart     # パートナー管理（53行）
│       │   └── vehicle_endpoints.dart     # 車両操作（233行）
│       ├── exceptions/
│       │   └── tesla_exceptions.dart      # 例外階層
│       ├── models/
│       │   ├── charging_models.dart       # 充電データモデル
│       │   ├── common_models.dart         # 共有モデル（ApiResponse、Locationなど）
│       │   ├── energy_models.dart         # エネルギー製品モデル
│       │   ├── models.dart                # バレルファイル（すべてのモデルをエクスポート）
│       │   ├── partner_models.dart        # パートナー/ユーザーモデル
│       │   └── vehicle_models.dart        # 車両データモデル（約437行）
│       └── tesla_fleet_client.dart        # コアHTTPクライアント（152行）
├── test/
│   ├── tesla_fleet_api_test.dart   # メインテストスイート（317行）
│   └── mocks/
│       ├── mock_http_client.dart   # テスト用モックHTTPクライアント
│       └── mock_tesla_auth.dart    # モック認証
├── example/
│   └── example.dart                # インタラクティブなサンプルアプリ（500行以上）
├── pubspec.yaml                    # 依存関係とメタデータ
├── README.md                       # ユーザー向けドキュメント
├── CHANGELOG.md                    # バージョン履歴
└── LICENSE                         # MITライセンス
```

### コード行数合計
- **コア実装** (`lib/src`): 約1,471行
- **テスト**: 317行 + モック
- **サンプル**: 500行以上

## アーキテクチャと設計パターン

### 1. レイヤードアーキテクチャ

```
┌─────────────────────────────────────────┐
│   プレゼンテーション層 (example.dart)   │
├─────────────────────────────────────────┤
│   API層（エンドポイント）               │
│   - VehicleEndpoints                    │
│   - EnergyEndpoints                     │
│   - ChargingEndpoints                   │
│   - PartnerEndpoints                    │
├─────────────────────────────────────────┤
│   ビジネスロジック（TeslaFleetClient）  │
│   - HTTPルーティング                    │
│   - レスポンス処理                      │
│   - エラー処理                          │
├─────────────────────────────────────────┤
│   認証層（TeslaAuth）                   │
│   - トークン管理                        │
│   - 自動更新（有効期限の300秒前）       │
│   - OAuth 2.0フロー                     │
├─────────────────────────────────────────┤
│   データ層（モデル）                    │
│   - JSONシリアライゼーション            │
│   - 型安全なデータ構造                  │
├─────────────────────────────────────────┤
│   エラー層（例外）                      │
│   - TeslaAuthException                  │
│   - TeslaApiException                   │
│   - TeslaRateLimitException             │
│   - TeslaVehicleException               │
└─────────────────────────────────────────┘
```

### 2. 依存性注入

- **TeslaFleetClient**は`TeslaAuth`インスタンスとオプションの`http.Client`を受け入れます
- モック依存関係を使用したテストを容易にします
- 関心事の明確な分離

### 3. エンドポイントパターン

各エンドポイントクラス：
- `TeslaFleetClient`への参照を保持
- メソッドは強く型付けされたモデルオブジェクトを返します
- `ApiResponse<T>`ラッパーを介した一貫したエラー処理
- RESTful APIマッピング

### 4. JSONシリアライゼーション戦略

- `json_annotation`パッケージと`@JsonSerializable`を使用
- `FieldRename.snake`による自動snake_caseフィールド名変換
- `*.g.dart`ファイルに生成されるコード（`build_runner`経由）
- ファクトリコンストラクタ：`fromJson(Map<String, dynamic> json)`
- シリアライゼーションメソッド：`toJson() -> Map<String, dynamic>`

## 主要ファイルとその役割

### コアクライアント: `lib/src/tesla_fleet_client.dart`

**主要クラス**: `TeslaFleetClient`

**責任**:
- HTTPリクエストのオーケストレーション
- 自動トークン取得と挿入
- レスポンス解析とエラー処理
- エンドポイントグループの遅延初期化

**主要メソッド**:
- `get()`, `post()`, `put()`, `delete()` - HTTP操作
- `_makeRequest()` - コアリクエストハンドラー
- `_handleResponse()` - エラー変換を含むレスポンス処理

**プロパティ**:
- `vehicles` → `VehicleEndpoints`
- `energy` → `EnergyEndpoints`
- `charging` → `ChargingEndpoints`
- `partner` → `PartnerEndpoints`

**エラー処理フロー**:
```dart
HTTPレスポンス
    ├─ 429 → TeslaRateLimitException（retryAfter Durationあり）
    ├─ 4xx/5xx → TeslaApiException（statusCode、messageあり）
    └─ 200-299 → JSONを解析、または無効なコンテンツの場合は例外をスロー
```

### 認証: `lib/src/auth/tesla_auth.dart`

**主要クラス**: `TeslaAuth`

**コンストラクタパラメータ**:
- `clientId` - 必須のOAuthクライアントID
- `clientSecret` - 必須のOAuthシークレット
- `privateKey` - オプションのJWT署名キー
- `region` - `northAmericaAsiaPacific`（デフォルト）、`europeMiddleEastAfrica`、`china`
- `redirectUri` - 認可コードフローに必要
- `baseUrl` - 地域によって自動決定（オーバーライド可能）
- `authUrl` - 地域によって自動決定（オーバーライド可能）

**トークン管理**:
- 有効期限追跡付きのメモリ内キャッシュ
- 有効期限の300秒前に自動更新
- `getAccessToken()`を介したスレッドセーフなトークン取得

**地域別エンドポイント**:
| 地域 | APIベースURL | 認証URL |
|------|-------------|---------|
| 北米/アジア太平洋 | `https://fleet-api.prd.na.vn.cloud.tesla.com` | `https://fleet-auth.prd.vn.cloud.tesla.com` |
| ヨーロッパ/中東/アフリカ | `https://fleet-api.prd.eu.vn.cloud.tesla.com` | `https://fleet-auth.prd.eu.vn.cloud.tesla.com` |
| 中国 | `https://fleet-api.prd.cn.vn.cloud.tesla.cn` | `https://fleet-auth.prd.cn.vn.cloud.tesla.cn` |

**認証フロー**:
1. **認可コードフロー**（個人車両アクセス用）
   - `redirectUri`が必要
   - ブラウザ経由のユーザー認証
   - フルスコープアクセスが利用可能

2. **クライアントクレデンシャルフロー**（ビジネスアプリケーション用）
   - ユーザー認証不要
   - 限定的なスコープ（通常は`vehicle_device_data`のみ）
   - 自動トークン取得

### 例外階層: `lib/src/exceptions/tesla_exceptions.dart`

```dart
TeslaException（抽象基底クラス）
├── TeslaAuthException         // 認証失敗、無効な資格情報
├── TeslaApiException          // 一般的なAPIエラー（statusCodeを含む）
├── TeslaRateLimitException    // HTTP 429（retryAfter Durationを含む）
└── TeslaVehicleException      // 車両固有のエラー（vehicleIdを含む）
```

**各例外の使用タイミング**:
- **TeslaAuthException**: トークン更新失敗、OAuthエラー、無効な資格情報
- **TeslaApiException**: HTTP 4xx/5xxエラー（429を除く）、無効なJSONレスポンス
- **TeslaRateLimitException**: HTTP 429のみ、`retry-after`ヘッダーを抽出
- **TeslaVehicleException**: 車両固有のエラー（スリープ、オフライン、コマンド失敗）

### モデル: `lib/src/models/`

**共通モデル** (`common_models.dart`):
```dart
ApiResponse<T> {
  T? response;              // 成功データ
  String? error;            // エラーコード
  List<String>? errorDescription;
  bool? errorAndMessages;
}

Location { double? latitude; double? longitude; }
CommandResponse { bool result; String? reason; }
```

**車両モデル** (`vehicle_models.dart` - 約437行):
- `Vehicle` - 基本車両情報（id、vin、displayName、state、tokens）
- `VehicleData` - 完全なスナップショット（Vehicleを拡張 + すべての状態データ）
- `DriveState` - 位置、速度、方位、パワー
- `ClimateState` - 温度、HVAC、シートヒーター（25以上のフィールド）
- `ChargeState` - バッテリー、充電、航続距離（40以上のフィールド）
- `GuiSettings` - 表示設定（単位、時刻形式）
- `VehicleState` - ロック状態、走行距離計、ドア/ウィンドウ（28フィールド）
- `VehicleConfig` - 車両タイプ、色、機能（26フィールド）

**エネルギーモデル** (`energy_models.dart`):
- `EnergyProduct` - 製品情報（energySiteId、siteName、components）
- `EnergyLiveStatus` - リアルタイム電力フロー（solar、battery、grid、load）
- `EnergyHistory` - 時系列データを含む履歴エネルギーデータ

**充電モデル** (`charging_models.dart`):
- `ChargingSession` - セッション詳細（32フィールド：エネルギー、コスト、位置、SOC）
- `ChargingInvoice` - 請求書データ（Base64コンテンツ）

**パートナーモデル** (`partner_models.dart`):
- `PartnerAccount` - publicKey、domain
- `User` - email、fullName、profileImageUrl

## 開発ワークフロー

### 開発環境のセットアップ

```bash
# リポジトリをクローン
git clone https://github.com/cutmail/tesla_fleet_api.git
cd tesla_fleet_api

# 依存関係をインストール
dart pub get

# JSONシリアライゼーションコードを生成
dart run build_runner build

# テストを実行
dart test

# サンプルを実行（Tesla認証情報が必要）
dart run example/example.dart
```

### コード生成ワークフロー

このパッケージはJSONシリアライゼーションに**コード生成**を使用します。モデルを追加または変更する場合：

1. **`@JsonSerializable()`アノテーションを付けてモデルクラスを追加/変更**
2. **必要なパッケージをインポート**:
   ```dart
   import 'package:json_annotation/json_annotation.dart';
   part 'your_model.g.dart';
   ```
3. **アノテーション付きでモデルを定義**:
   ```dart
   @JsonSerializable(fieldRename: FieldRename.snake)
   class YourModel {
     final String someField;
     final int? optionalField;

     YourModel({required this.someField, this.optionalField});

     factory YourModel.fromJson(Map<String, dynamic> json) =>
         _$YourModelFromJson(json);

     Map<String, dynamic> toJson() => _$YourModelToJson(this);
   }
   ```
4. **コード生成を実行**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
5. **生成された`*.g.dart`ファイルを確認**

### テストワークフロー

**テストの実行**:
```bash
# すべてのテストを実行
dart test

# 特定のテストファイルを実行
dart test test/tesla_fleet_api_test.dart

# カバレッジ付きで実行
dart test --coverage=coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
```

**テスト構造**（AAAパターン）:
```dart
test('テストの説明', () {
  // Arrange（準備）
  final mockClient = MockHttpClient();
  final auth = MockTeslaAuth();
  final client = TeslaFleetClient(auth: auth, httpClient: mockClient);

  mockClient.setResponse(
    statusCode: 200,
    body: '{"response": {...}}',
  );

  // Act（実行）
  final result = await client.vehicles.list();

  // Assert（検証）
  expect(result.length, greaterThan(0));
  expect(mockClient.lastRequest?.url.path, '/api/1/vehicles');
});
```

**モッククラス**:
- `MockTeslaAuth` - 固定トークンを返し、実際のOAuth呼び出しは行わない
- `MockHttpClient` - レスポンスの設定が可能、最後のリクエストを追跡

### 新しいエンドポイントの追加

1. **`lib/src/models/`にモデルクラスを定義**（`@JsonSerializable()`付き）
2. **JSONコードを生成**: `dart run build_runner build`
3. **`lib/src/endpoints/`にエンドポイントクラスを作成**
4. **`TeslaFleetClient`にエンドポイントプロパティを追加**
5. **バレルファイルからエクスポート**（`lib/src/endpoints/endpoints.dart`）
6. **`test/tesla_fleet_api_test.dart`にテストを記述**
7. **README.mdのドキュメントを更新**

**エンドポイントクラスの例**:
```dart
class NewEndpoints {
  final TeslaFleetClient _client;

  NewEndpoints(this._client);

  Future<YourModel> getSomething(String id) async {
    final response = await _client.get('/api/1/your_endpoint/$id');
    final apiResponse = ApiResponse<YourModel>.fromJson(
      response,
      (json) => YourModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.response!;
  }

  Future<CommandResponse> doSomething(String id, Map<String, dynamic> params) async {
    final response = await _client.post(
      '/api/1/your_endpoint/$id/action',
      body: params,
    );
    return CommandResponse.fromJson(response['response']);
  }
}
```

### Gitワークフロー

**ブランチ戦略**:
- メインブランチ: `main`（またはgit statusで指定されたもの）
- 機能ブランチ: AIアシスタント作業用の`claude/claude-md-<session-id>`
- 常にmainから機能ブランチを作成

**コミットガイドライン**:
- 従来型コミットを使用: `feat:`、`fix:`、`docs:`、`test:`、`refactor:`
- 説明的かつ簡潔に
- 該当する場合は課題番号を参照

**現在の作業ブランチ**:
```
claude/claude-md-mi83mhh6gv55b3ot-011hitHoWykkeYCDd4abPVkC
```

**重要なGitルール**:
- 常に`git push -u origin <branch-name>`でプッシュ
- ブランチは`claude/`で始まり、一致するセッションIDで終わる必要があります
- ネットワーク障害時は指数バックオフで最大4回リトライ（2秒、4秒、8秒、16秒）

## コーディング規約

### 命名規約

| タイプ | 規約 | 例 |
|--------|------|-----|
| クラス | PascalCase | `TeslaFleetClient`、`VehicleEndpoints` |
| メソッド | camelCase | `getVehicleData()`、`startCharging()` |
| 変数 | camelCase | `vehicleId`、`energySiteId` |
| 定数 | camelCase | `baseUrl`、`authUrl` |
| JSONフィールド | snake_case | `vehicle_id`、`charge_state`（自動変換） |
| プライベートフィールド | _プレフィックス | `_client`、`_auth`、`_httpClient` |
| 列挙型 | PascalCase | N/A（文字列を使用） |

### コードスタイル

**推奨**:
- Null安全性: Nullable型には`?`を使用、可能な限り`!`を避ける
- 2つ以上のパラメータを持つメソッドには名前付きパラメータを使用
- 可能な限りfinal変数を使用
- 明示的な戻り値の型
- `.then()`よりasync/awaitを優先

**避けるべき**:
- Nullチェックなしの強制アンラップ（`!`）
- 深くネストされたコード（最大3-4レベル）
- マジックナンバー（名前付き定数を使用）
- 汎用的な`Exception`のキャッチ（特定の型を使用）

**良いコードの例**:
```dart
Future<VehicleData> getVehicleData(String vehicleId) async {
  final response = await _client.get('/api/1/vehicles/$vehicleId/vehicle_data');
  final apiResponse = ApiResponse<VehicleData>.fromJson(
    response,
    (json) => VehicleData.fromJson(json as Map<String, dynamic>),
  );

  if (apiResponse.response == null) {
    throw TeslaApiException(
      'No vehicle data returned for vehicle: $vehicleId',
    );
  }

  return apiResponse.response!;
}
```

### エラー処理パターン

**常に**:
1. 特定の例外タイプを使用
2. エラーメッセージにコンテキストを含める（車両ID、エンドポイントなど）
3. HTTP 429は`TeslaRateLimitException`で個別に処理
4. データにアクセスする前にレスポンスを検証

**HTTPステータスコードマッピング**:
```dart
switch (response.statusCode) {
  case 429:
    final retryAfter = Duration(
      seconds: int.parse(response.headers['retry-after'] ?? '60')
    );
    throw TeslaRateLimitException(
      'Rate limit exceeded',
      retryAfter: retryAfter,
    );
  case >= 400 && < 500:
    throw TeslaApiException(
      'Client error: ${response.body}',
      statusCode: response.statusCode,
    );
  case >= 500:
    throw TeslaApiException(
      'Server error: ${response.body}',
      statusCode: response.statusCode,
    );
}
```

### ドキュメント標準

**すべての公開APIには以下が必要**:
1. Dartdocコメント（///）
2. パラメータの説明
3. 戻り値の型の説明
4. 例外のドキュメント
5. 使用例（複雑なメソッドの場合）

**例**:
```dart
/// 特定の車両の包括的なデータを取得します。
///
/// これには、ドライブ状態、気候状態、充電状態、車両状態、
/// 車両構成、GUI設定が含まれます。
///
/// パラメータ:
///   [vehicleId] - 車両の一意識別子
///
/// 戻り値:
///   すべての車両情報を含む[VehicleData]オブジェクト
///
/// スロー:
///   [TeslaAuthException] 認証が失敗した場合
///   [TeslaApiException] APIリクエストが失敗した場合
///   [TeslaVehicleException] 車両が見つからない、または利用できない場合
///
/// 例:
/// ```dart
/// final vehicleData = await client.vehicles.getVehicleData('12345');
/// print('バッテリー: ${vehicleData.chargeState?.batteryLevel}%');
/// ```
Future<VehicleData> getVehicleData(String vehicleId) async {
  // 実装...
}
```

## 一般的なタスクとパターン

### タスク1: 新しい車両コマンドの追加

```dart
// 1. VehicleEndpointsクラスにメソッドを追加
Future<CommandResponse> yourNewCommand(
  String vehicleId, {
  required String param1,
  int? optionalParam,
}) async {
  final response = await _client.post(
    '/api/1/vehicles/$vehicleId/command/your_command',
    body: {
      'param1': param1,
      if (optionalParam != null) 'optional_param': optionalParam,
    },
  );
  return CommandResponse.fromJson(response['response']);
}

// 2. テストを追加
test('yourNewCommandが正しいリクエストを送信する', () async {
  mockClient.setResponse(
    statusCode: 200,
    body: '{"response": {"result": true}}',
  );

  final result = await client.vehicles.yourNewCommand(
    vehicleId,
    param1: 'value',
  );

  expect(result.result, isTrue);
  expect(mockClient.lastRequest?.url.path,
    '/api/1/vehicles/$vehicleId/command/your_command');
});

// 3. README.mdにドキュメント化
```

### タスク2: 新しいモデルフィールドの追加

```dart
// 1. モデルクラスにフィールドを追加
@JsonSerializable(fieldRename: FieldRename.snake)
class VehicleData {
  final String? vin;
  final ChargeState? chargeState;
  final NewField? newField;  // <- これを追加

  VehicleData({
    this.vin,
    this.chargeState,
    this.newField,  // <- これを追加
  });

  factory VehicleData.fromJson(Map<String, dynamic> json) =>
      _$VehicleDataFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleDataToJson(this);
}

// 2. コード生成を実行
// $ dart run build_runner build --delete-conflicting-outputs

// 3. 新しいフィールドを含めるようにテストを更新
```

### タスク3: レート制限の処理

```dart
// 指数バックオフの実装
Future<T> _retryWithBackoff<T>(Future<T> Function() operation) async {
  int attempts = 0;
  const maxAttempts = 4;

  while (attempts < maxAttempts) {
    try {
      return await operation();
    } on TeslaRateLimitException catch (e) {
      attempts++;
      if (attempts >= maxAttempts) rethrow;

      final delay = e.retryAfter ?? Duration(seconds: 2 << attempts);
      print('レート制限されました。$delay後に再試行します...');
      await Future.delayed(delay);
    }
  }

  throw TeslaApiException('最大リトライ回数を超えました');
}

// 使用法
final vehicles = await _retryWithBackoff(() => client.vehicles.list());
```

### タスク4: スリープ中の車両の起動

```dart
Future<VehicleData> getVehicleDataWithWakeup(String vehicleId) async {
  final vehicles = await client.vehicles.list();
  final vehicle = vehicles.firstWhere((v) => v.id.toString() == vehicleId);

  if (vehicle.state == 'asleep' || vehicle.state == 'offline') {
    print('車両は${vehicle.state}です、起動中...');
    await client.vehicles.wakeUp(vehicleId);

    // 車両がオンラインになるまでポーリング（最大30秒）
    for (int i = 0; i < 6; i++) {
      await Future.delayed(Duration(seconds: 5));
      final updatedVehicles = await client.vehicles.list();
      final updatedVehicle = updatedVehicles.firstWhere(
        (v) => v.id.toString() == vehicleId
      );

      if (updatedVehicle.state == 'online') {
        print('車両はオンラインになりました');
        break;
      }
    }
  }

  return await client.vehicles.getVehicleData(vehicleId);
}
```

## テスト戦略

### ユニットテスト
- HTTPクライアントと認証をモック
- すべてのエンドポイントメソッドをテスト
- リクエストパスとパラメータを検証
- エラー処理パスをテスト
- JSON解析を検証

### 統合テスト
- 実際の認証情報でテスト（ユニットテストとは別）
- 安全なエンドポイントのみを使用（データ取得、車両制御なし）
- トークン更新フローをテスト
- 複数地域のサポートをテスト

### テストカバレッジ目標
- **モデル**: 100%（すべてのfromJson/toJson）
- **エンドポイント**: >90%（すべての公開メソッド）
- **クライアント**: >90%（リクエスト/レスポンス処理）
- **認証**: >80%（トークン管理）
- **例外**: 100%（シンプルなクラス）

### テストパターンの例

```dart
group('VehicleEndpoints', () {
  late MockHttpClient mockClient;
  late MockTeslaAuth auth;
  late TeslaFleetClient client;

  setUp(() {
    mockClient = MockHttpClient();
    auth = MockTeslaAuth();
    client = TeslaFleetClient(auth: auth, httpClient: mockClient);
  });

  test('listは成功時に車両を返す', () async {
    mockClient.setResponse(
      statusCode: 200,
      body: '''
        {
          "response": [
            {"id": 123, "vin": "ABC123", "display_name": "My Tesla"}
          ]
        }
      ''',
    );

    final vehicles = await client.vehicles.list();

    expect(vehicles, hasLength(1));
    expect(vehicles.first.vin, equals('ABC123'));
    expect(mockClient.lastRequest?.url.path, equals('/api/1/vehicles'));
  });

  test('listはAPIエラー時に例外をスロー', () async {
    mockClient.setResponse(statusCode: 500, body: 'Server error');

    expect(
      () => client.vehicles.list(),
      throwsA(isA<TeslaApiException>()),
    );
  });
});
```

## 重要な考慮事項

### セキュリティ
- **認証情報をバージョン管理にコミットしない**
- 機密データには環境変数を使用
- サンプルファイルにはプレースホルダーを使用（`YOUR_CLIENT_ID_HERE`）
- ドキュメントで車両制御の安全性について警告

### APIレート制限
- Teslaはレート制限を実施（正確な制限は公開されていません）
- 常に`TeslaRateLimitException`を処理
- 指数バックオフを実装
- 可能な場合はデータのキャッシュを検討

### 車両状態
- **online**: 車両は起動しており応答可能
- **asleep**: 車両はスリープ中（低電力モード）
- **offline**: 車両はオフライン（接続なし）

**ベストプラクティス**: コマンドを送信する前に常に車両を起動

### スコープ要件

| スコープ | アクセス |
|---------|---------|
| `openid` | 基本的なOpenID Connect |
| `offline_access` | リフレッシュトークン |
| `user_data` | ユーザープロファイル（`/api/1/users/me`） |
| `vehicle_device_data` | 車両データ取得 |
| `vehicle_cmds` | 車両制御コマンド |
| `vehicle_charging_cmds` | 充電制御 + 履歴 |
| `energy_device_data` | エネルギー製品データ |
| `energy_cmds` | エネルギー製品制御 |

### 一般的なエラーコード

| HTTPコード | 意味 | アクション |
|-----------|------|----------|
| 401 | 未認証 | トークンを更新または再認証 |
| 403 | 禁止 | スコープを確認、パートナー登録が必要な場合あり |
| 404 | 見つかりません | 車両/リソースIDを確認 |
| 412 | 前提条件失敗 | 車両が利用不可、起動を試みる |
| 429 | レート制限 | バックオフを実装、`retry-after`を尊重 |
| 500 | サーバーエラー | 指数バックオフでリトライ |

## トラブルシューティングガイド

### 問題: HTTP 412エラー
**原因**: 車両がスリープ中または利用不可
**解決策**: 最初に`wakeUp(vehicleId)`を呼び出し、5-10秒待つ

### 問題: スコープの欠落
**原因**: アプリケーションに必要なOAuthスコープがない
**解決策**: developer.tesla.comでアプリ構成を更新

### 問題: 登録が必要
**原因**: 初回のAPIアクセスにはパートナー登録が必要
**解決策**: `client.partner.registerPartner(domain)`を呼び出し、30秒待つ

### 問題: 無効なJSONレスポンス
**原因**: APIが予期しない形式またはエラーを返した
**解決策**: APIドキュメントを確認、レスポンス構造を検証

### 問題: トークン更新の失敗
**原因**: リフレッシュトークンの期限切れまたは無効
**解決策**: 認可コードフローを使用して再認証

## 依存関係

### ランタイム依存関係
- `http: ^1.1.0` - APIリクエスト用のHTTPクライアント
- `crypto: ^3.0.3` - 暗号化機能（JWT署名）
- `jwt_decode: ^0.3.1` - JWTトークン解析
- `json_annotation: ^4.8.1` - JSONシリアライゼーションアノテーション

### 開発依存関係
- `test: ^1.24.0` - テストフレームワーク
- `build_runner: ^2.4.7` - コード生成ランナー
- `json_serializable: ^6.7.1` - JSONコードジェネレータ
- `lints: ^6.0.0` - Dartリンティングルール

### 依存関係の更新

```bash
# 古いパッケージを確認
dart pub outdated

# 依存関係を更新
dart pub upgrade

# 特定のパッケージを更新
dart pub upgrade http

# 更新後、テストを実行
dart test
```

## バージョン履歴

### v1.0.0（2024-06-14）
- 初回リリース
- 完全なTesla Fleet API実装
- 複数地域のサポート
- OAuth 2.0認証（両フロー）
- 包括的なテストスイート
- インタラクティブなサンプルアプリケーション

## リソース

### 公式ドキュメント
- **Tesla Fleet API**: https://developer.tesla.com/docs/fleet-api
- **Tesla開発者ポータル**: https://developer.tesla.com

### パッケージリソース
- **リポジトリ**: https://github.com/cutmail/tesla_fleet_api
- **課題**: https://github.com/cutmail/tesla_fleet_api/issues
- **pub.dev**: https://pub.dev/packages/tesla_fleet_api（公開時）

### Dartリソース
- **Dartドキュメント**: https://dart.dev/guides
- **JSONシリアライゼーション**: https://docs.flutter.dev/data-and-backend/json
- **テスト**: https://dart.dev/guides/testing

## クイックリファレンス

### 必須コマンド

```bash
# セットアップ
dart pub get
dart run build_runner build

# 開発
dart run build_runner watch          # 変更時に自動再生成
dart analyze                         # 静的解析
dart format lib/ test/ example/      # コードのフォーマット

# テスト
dart test
dart test --coverage=coverage

# サンプルの実行
dart run example/example.dart
```

### 主要なAPIパターン

```dart
// クライアントの初期化
final auth = TeslaAuth(
  clientId: 'YOUR_CLIENT_ID',
  clientSecret: 'YOUR_CLIENT_SECRET',
  region: 'northAmericaAsiaPacific',
);
final client = TeslaFleetClient(auth: auth);

// 車両を取得
final vehicles = await client.vehicles.list();

// 車両データを取得
final data = await client.vehicles.getVehicleData(vehicleId);

// コマンドを送信
final result = await client.vehicles.honkHorn(vehicleId);

// エネルギーステータス
final status = await client.energy.getLiveStatus(energySiteId);

// 充電履歴
final sessions = await client.charging.getChargingHistory(vin: vin);

// エラー処理
try {
  await client.vehicles.list();
} on TeslaRateLimitException catch (e) {
  await Future.delayed(e.retryAfter);
} on TeslaAuthException catch (e) {
  // 再認証
} on TeslaApiException catch (e) {
  print('APIエラー: ${e.statusCode} - ${e.message}');
}
```

---

**最終更新**: 2024-11-21
**対象**: tesla_fleet_api Dartパッケージで作業するAIアシスタント
**管理者**: プロジェクト貢献者
