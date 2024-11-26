# [DEMO] AWS CloudFormation

![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)

このプロジェクトには、CloudFormation でサーバレスアプリケーションをデプロイする
ためのテンプレートとと関連ファイルが含まれています：

- `.deploy` - CloudFormation テンプレートデプロイ用のシェルスクリプトを保存する
  ためのディレクトリ
- `.github` - GitHub のワークフローを作成するためのディレクトリ
- `.templates` - CloudFormation テンプレートを保存するためのディレクトリ
- `events` - ラムダ関数を呼び出すためのイベントを定義
- `src` - Lambda 関数のソースコードを保存するためのディレクトリ
- `tests` - アプリケーションソースコードの単体テスト（今回は使用していない）
- `template.yaml` - アプリケーションの AWS リソースを定義

## 前提条件

- AWS Account (IAM Identity Center の SSO による認証方法を推奨)
- AWS CLI

## 参考記事

- [AWS CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html)
- [AWS SAM CLI Core Commands](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/using-sam-cli-corecommands.html)
- [AWS SAM setup for Lambda, API Gateway, and DynamoDB](https://medium.com/@dwight.lindquist/aws-sam-setup-for-lambda-api-gateway-and-dynamodb-542c46f1ff76)
- [How to build the AWS SAM app for API Gateway and Lambda function](https://medium.com/@vjraghavanv/how-to-build-the-aws-sam-app-for-api-gateway-and-lambda-function-25e434ece3b1)

## デプロイメント

アプリケーションを始めてビルドしてデプロイする場合、以下の手順に従ってください。

1. AWS CLI の認証かつ設定を行う。
   1. IAM を使用する場合、`aws configure`
   2. IAM Identity Center の SSO を使用する場合、`aws configure sso`
2. `.templates`からテンプレートファイルをルートディレクトリにコピーペーストする
   。
3. `.deploy`から、持ち出したテンプレート専用のシェルスクリプトをルートディレクト
   リにコピーペーストする。
4. 持ち出したテンプレート内の定数宣言を自分の AWS アプリケーションの設定に合わせ
   る。
5. 持ち出したシェルスクリプト内の定数宣言を自分の AWS アプリケーションの設定に合
   わせる。
6. シェルスクリプトを実行する。例えば、シェルスクリプトの名前
   が`deploy.template99.sh`の場合、（Linux）ターミナル
   に`./deploy.template99.sh`を入力する。

## ローカルでビルド及びテスト

### ローカルでビルド

SAM CLI でローカル環境からアプリケーションをビルドしてテストする場合、以下のコマ
ンドを入力：

```bash
sam build --use-container
```

AWS SAM CLI は、`hello_world/requirements.txt`で定義されている依存関係をインスト
ールし、デプロイメントパッケージを作成して、`.aws-sam/build`フォルダに保存します
。

### ローカルでテスト

ローカルからのビルドが完了したら、ローカルで関数の動作がテストできます。単一の関
数をテストするには、テストイベントを使って直接呼び出します。イベントは、関数がイ
ベントソースから受け取る入力表現の JSON ドキュメントです。テストイベントは、この
プロジェクトの`events`フォルダに含まれています。

関数をローカルで実行してテストするためには、`sam local invoke`コマンドで呼び出し
ます：

```bash
sam local invoke HelloWorldFunction --event events/event.json
```

AWS SAM CLI は、アプリケーションの API を真似することもできます
。`sam local start-api`コマンドを使用して、API をローカルでポート 3000 で実行し
ます：

```bash
sam local start-api
curl http://localhost:3000/
```

AWS SAM CLI は、アプリケーションテンプレートを読み込んで、API のルートとそれらが
呼び出す関数を決定します。各関数の定義にある`Events`プロパティには、各パスのルー
トとメソッドが含まれているべきです。

```yaml
Events:
  HelloWorld:
    Type: Api
    Properties:
      Path: /hello
      Method: get
```

## アプリケーションへのリソース追加

アプリケーションテンプレートは、AWS Serverless Application Model (AWS SAM) を使
用してアプリケーションリソースを定義します。AWS SAM は AWS CloudFormation 拡張機
能であり、関数、トリガー、API など、一般的なサーバーレスアプリケーションリソース
を構成するためのよりシンプルな構文を持ちます。

[SAM の仕様](https://github.com/awslabs/serverless-application-model/blob/master/versions/2016-10-31.md)に
含まれていないリソースについては
、[AWS CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html)の
スタンダードなリソースタイプが使用できます。

## ラムダ関数ログの取得、追従、フィルタリング

デバッグをより簡単にするために、SAM CLI では`sam logs`を使用します。このコマンド
は、ログを端末に表示するだけでなく、バグを素早く見つけるに役立つ便利な機能がいく
つか備わっています。

`NOTE`: このコマンドは、SAM を使用してデプロイしたものだけでなく、すべての AWS
ラムダ関数で動作します。

```bash
sam logs -n HelloWorldFunction --stack-name "aws-sam" --tail
```

ラムダ関数ログのフィルタリングの詳細情報と例については
、[SAM CLI ドキュメント](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-logging.html)を
参照してください。

## テスト

テストは、プロジェクト内の `tests` フォルダに定義します。テストする際に、依存関
係をインストールして、テストを実行するには PIP を使用します。

```bash
pip install -r tests/requirements.txt --user

# ユニットテスト
python -m pytest tests/unit -v

# 単体テストは、最初にスタックをデプロイする必要があります。
# テストするスタックの名前を持つ環境変数 AWS_SAM_STACK_NAME を作成します。
AWS_SAM_STACK_NAME="aws-sam" python -m pytest tests/integration -v
```

## 後片付け（Clean Up）

作成したサンプルアプリケーションを削除するには、AWS CLI を使用します。プロジェク
ト名と同じ名前をスタック名に使用したとすると、次のように実行できます。

```bash
sam delete --stack-name YOUR_STACK_NAME
aws cloudformation delete-stack --stack-name YOUR_STACK_NAME --region YOUR_REGION
```

## リソース

SAM の仕様、SAM CLI、及びサーバーレスアプリケーションの概念の概要については
、[AWS SAM デベロッパーガイド](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html)を
参照してください。

次に、AWS Serverless Application Repository を使用して、"Hello World" サンプルを
超えたすぐに使用できるアプリケーションをデプロイし、作成者がアプリケーションをど
のように開発したかを学ぶことができます:
[AWS Serverless Application Repository メインページ](https://aws.amazon.com/serverless/serverlessrepo/)
