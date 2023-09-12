# Lamda関数を使ってみる
このハンズオンでは JavaScript を使用して Lambda 関数を作成します。

## 前提条件
このハンズオンでは Node.js v16 以降を使用します。  
[Cloud9](https://aws.amazon.com/jp/cloud9/) は、Node.js v16.x がインストールされており、ブラウザのみで利用することができるため便利です。

## 公式ドキュメント
* [Lambda](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/welcome.html)
* [JavaScript用 AWS SDK](https://docs.aws.amazon.com/ja_jp/sdk-for-javascript/v2/developer-guide/welcome.html)

## Lambda 関数を作成する
以下の手順で Lambda 関数を作成します。

1. Lambda 関数を実行するロールを作成する
2. Lambda 関数のコードを作成する
3. Lambda 関数のコードを zip で固める
4. Lambda 関数を作成する

### Lambda 関数を実行するロールを作成する
Lambda 関数を実行する際に付与する IAM ロールを作成します。  
作成した IAM ロールは Lambda 関数を作成する際に指定します。

以下の内容で `my-assume-role-policy.json` を作成します。  
以下の定義は Lambda サービスにロールを引き受ける権限を付与します。

```text
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "lambda.amazonaws.com"
                ]
            }
        }
    ]
}
```

IAM ロールは以下のコマンドで作成します。  

```bash
aws iam create-role \
--role-name my-lambda-role \
--assume-role-policy-document file://my-assume-role-policy.json
```

以下の内容で `my-lambda-policy.json` を作成します。  
以下の定義は Lambda 関数のログを CloudWatch Logs に出力する権限を付与します。

```text
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        }
    ]
}
```

以下のコマンドで IAM ポリシーを作成します。

```bash
aws iam create-policy \
--policy-name my-lambda-policy \
--policy-document file://my-lambda-policy.json
```

作成したポリシーをロールにアタッチします。  
「作成したポリシーの ARN」は作成した自信の IAM ポリシーの ARN に置き換えてください。

```bash
aws iam attach-role-policy \
--role-name my-lambda-role \
--policy-arn 作成したポリシーの ARN
```

AWS management console で IAM サービスから Role を確認すると以下のように作成したロールが確認できます。

![](./img/ima-role-1.png)

### Lambda 関数のコードを作成する

適当なディレクトリを作成してファイルを作成します。  
ファイル名は `thumbnail.js` とします。

作成したファイルに以下のコードを記述します。

以下はログを出力するだけの Lambda 関数のコードです。

``` JavaScript
exports.handler = async (event, context) => {
    console.log("called thumbnail function!!!")
    console.log(event)
    console.log(context)
    return 200
}
```

### Lambda 関数のコードを zip で固める
以下のコマンドを実行して作成した Lambda 関数のコードを zip で固めます。

```bash
zip thumbnail.zip thumbnail.js
```

### Lambda関数を作成する  
以下のコマンドを実行し、Lambda関数を作成します。

「作成したロールの ARN」 は「Lambda 関数を実行するロールを作成する」で作成したロールの ARNで置き換えてください。

```bash
aws lambda create-function \
--function-name thumbnail \
--zip-file fileb://thumbnail.zip \
--handler thumbnail.handler \
--runtime nodejs16.x \
--role 作成したロールの ARN \
--timeout 60
```

AWS management console で Lambda サービスから Functions を確認すると以下のように作成した Lambda 関数が確認できます。

![](./img/lambda-1.png)

Function name をクリックすると作成した Lambda 関数の詳細を確認できます。

![](./img/lambda-2.png)

作成した Lambda 関数のコードを修正する場合は、修正したコードを zip で固め直して `aws lambda update-function-code` コマンドで更新します。

```bash
aws lambda update-function-code \
--function-name thumbnail \
--zip-file fileb://thumbnail.zip
```

## Lambda 関数を実行する
作成した Lambda 関数を aws コマンドと AWS SDK の 2つの方法で実行します。

### aws コマンドで実行する
aws コマンドを使用して Lambda 関数を実行します。

```bash
aws lambda invoke \
--function-name thumbnail \
--invocation-type RequestResponse \
--log-type Tail \
--query 'LogResult' \
--output text \
response | base64 -d
```

コマンドを実行すると以下のように表示されます。
```text
2023-08-21T06:11:23.750Z        2a9f2a96-ed23-404f-9f8e-bc2e83bf63f4    INFO    {}
2023-08-21T06:11:23.750Z        2a9f2a96-ed23-404f-9f8e-bc2e83bf63f4    INFO    called thumbnail function!!!
START RequestId: 2a9f2a96-ed23-404f-9f8e-bc2e83bf63f4 Version: $LATEST
2023-08-21T06:11:23.751Z        2a9f2a96-ed23-404f-9f8e-bc2e83bf63f4    INFO    {
  callbackWaitsForEmptyEventLoop: [Getter/Setter],
  succeed: [Function (anonymous)],
  fail: [Function (anonymous)],
  done: [Function (anonymous)],
  functionVersion: '$LATEST',
  functionName: 'thumbnail',
  memoryLimitInMB: '128',
  logGroupName: '/aws/lambda/thumbnail',
  logStreamName: '2023/08/21/[$LATEST]13805f3aa0f6430cb996f0aa01fc649e',
  clientContext: undefined,
  identity: undefined,
  invokedFunctionArn: 'arn:aws:lambda:ap-northeast-1:391726422976:function:thumbnail',
  awsRequestId: '2a9f2a96-ed23-404f-9f8e-bc2e83bf63f4',
  getRemainingTimeInMillis: [Function: getRemainingTimeInMillis]
}
END RequestId: 2a9f2a96-ed23-404f-9f8e-bc2e83bf63f4
REPORT RequestId: 2a9f2a96-ed23-404f-9f8e-bc2e83bf63f4  Duration: 9.69 ms       Billed Duration: 10 ms        Memory Size: 128 MB     Max Memory Used: 58 MB
```

実行結果を AWS Management Console で確認しましょう。

CloudWatch サービスに移動して左のメニューから Log groups を選択します。
![](./img/cw-1.png)

Log groups で `/aws/lambda/thumnail` を選択すると Log group の詳細情報が確認できます。
![](./img/cw-2.png)

Log stream を選択すると Lambda 関数が出力したログの内容が確認できます。
![](./img/cw-3.png)

### JavaScript で Lambda 関数を実行する
JavaScript で書かれたプログラムから Lambda 関数を実行してみます。

#### nodejs のプロジェクトの用意
適当なディレクトリを作成してプロジェクトを初期化します。  
プロジェクトの初期化は `npm init` コマンドで行います。

コマンドを実行すると package name や version などの質問が表示されますので適当に入力してください。  
このハンズオンではすべてデフォルト値で作成しても大丈夫です。

```bash
package name: (test) 
version: (1.0.0) 
description: 
entry point: (index.js) 
test command: 
git repository: 
keywords: 
author: 
license: (ISC) 
```

最後に表示される質問に `yes` と入力すると `package.json` が作成されプロジェクトの初期化が完了します。

```bash
About to write to /home/ec2-user/environment/test/package.json:

{
  "name": "test",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "ISC"
}

Is this OK? (yes) yes
```

#### AWS SDK for JavaScript をインストールする
Lambda 関数を実行するために AWS SDK for JavaScript をインストールします。

作成したプロジェクトのディレクトリの下で以下のコマンドを実行します。

```bash
npm install @aws-sdk/client-lambda
```

上記コマンドを実行すると `node_modules` というディレクトリが作成され、その中に AWS SDK for JavaScript がインストールされます。

また、package.json には aws-sdk が dependencies として追加されます。

```javascript
"dependencies": {
  "@aws-sdk/client-lambda": "^3.409.0",
}
```

#### ESModule を使用する
ESModule を使用するために `package.json` に以下の内容を追加します。

```javascript
"type": "module"
```

package.json の内容は以下のようになります。

```javascript
{
  "name": "test",
  "version": "1.0.0",
  "description": "",
  "type": "module",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "MIT",
  "dependencies": {
    "@aws-sdk/client-lambda": "^3.409.0"
  }
}
```

#### Lambda 関数を実行するコードを作成する
プロジェクトの下に `index.js` というファイルを作成し以下のコードを記述します。

``` JavaScript
import { LambdaClient, InvokeCommand } from "@aws-sdk/client-lambda"

const lambda = new LambdaClient({ region: "us-east-1" })

const command = new InvokeCommand({
  FunctionName: "thumbnail",
  Payload: JSON.stringify({
    first_name: "Taro",
    last_name: "Yamada"
  }),
  LogType: "Tail",
})

lambda.send(command)
  .then((result) => {
    const payload = Buffer.from(result.Payload).toString()
    console.log(`payload=${payload}`)

    const logs = Buffer.from(result.LogResult, "base64").toString()
    console.log("===== logs =====")
    console.log(logs)
  })
```

#### 作成したJavaScriptを実行する
以下のコマンドを実行して Lambda 関数を実行します。

```bash
node index.js
```

Lambda 関数の実行に成功すると以下のように Lambda 関数の実行結果とログの内容が表示されます。

```bash
payload=200
===== logs =====
START RequestId: 5f89864a-675f-44a2-80a3-0883d5750d5a Version: $LATEST
2023-09-10T06:13:23.086Z        5f89864a-675f-44a2-80a3-0883d5750d5a    INFO    called thumbnail function!!!
2023-09-10T06:13:23.087Z        5f89864a-675f-44a2-80a3-0883d5750d5a    INFO    { first_name: 'Taro', last_name: 'Yamada' }
2023-09-10T06:13:23.089Z        5f89864a-675f-44a2-80a3-0883d5750d5a    INFO    {
  callbackWaitsForEmptyEventLoop: [Getter/Setter],
  succeed: [Function (anonymous)],
  fail: [Function (anonymous)],
  done: [Function (anonymous)],
  functionVersion: '$LATEST',
  functionName: 'thumbnail',
  memoryLimitInMB: '128',
  logGroupName: '/aws/lambda/thumbnail',
  logStreamName: '2023/09/10/[$LATEST]17f820f0cd0f49fdab35ff1ccc411a45',
  clientContext: undefined,
  identity: undefined,
  invokedFunctionArn: 'arn:aws:lambda:us-east-1:148125964078:function:thumbnail',
  awsRequestId: '5f89864a-675f-44a2-80a3-0883d5750d5a',
  getRemainingTimeInMillis: [Function: getRemainingTimeInMillis]
}
END RequestId: 5f89864a-675f-44a2-80a3-0883d5750d5a
REPORT RequestId: 5f89864a-675f-44a2-80a3-0883d5750d5a  Duration: 56.64 ms      Billed Duration: 57 ms  Memory Size: 128 MB     Max Memory Used: 57 MB  Init Duration: 149.90 ms
```

## Thumbnailを作成するコードをLambdaに実装する
S3 のバケットに保管した画像を Lambda 関数で読み込み、サムネイル画像を作成して別の S3 バケットに保管する Lambda 関数を作成します。

### 事前準備
S3 に以下のバケットを作成します。

* オリジナル画像を保管するバケット
* サムネイル画像を保管するバケット

### Lambda 関数の仕様
#### Lambda関数の入力パラメータ
Lambda関数の入力パラメータは以下のようになります。

```javascript
s3: {
  original: {
    bucket_name: 画像を読み込むバケット名,
    key: 読み込む画像ファイルのキー
  },
  thumbnail: {
    bucket_name: サムネイルを保管するバケット名
  }
}
```

#### 処理内容
Lambda関数の処理内容は以下のようになります。

1. S3(original bucket)から画像を読み込む
2. 読み込んだ画像からサムネイル画像を作成
3. サムネイル画像をS3(thumbnail bucket)に保管

#### 画像を変換するために使用するモジュール  
Lambda 関数の処理で画像を変換するために以下のモジュールを使用します。

* sharp

### Lambda関数のプロジェクトを作成する
[nodejsのプロジェクトの用意](#nodejs) と同じ手順でプロジェクトを作成します。

### 関数を実装する
ディレクトリを作成して `thumbnail.js` というファイルを作成します。  
作成したファイルに以下のコードを記述します。

```javascript
import { S3Client, GetObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3"
import sharp from "sharp"

// S3クライアントを作成
const s3client = new S3Client({ region: "us-east-1" })

// 画像をダウンロードする
const downloadImage = async (bucket, key) => {
  const image = await s3client.send(new GetObjectCommand({
    Bucket: bucket,
    Key: key
  }))
}

// サムネイルを作成する
const createThumbnail = (input) => {
  return sharp(input).resize(100, 100).toBuffer()
}

// 画像をアップロードする
const uploadImage = (bucket, key, input) => {
  s3client.send(new PutObjectCommand({
    Bucket: bucket,
    Key: key,
    Body: input,
    ContentType: 'image/png'
  }))
}

// Lambda関数のエントリポイント
exports.handler = async (event, context) => {
  console.log("start create thumbnail function!!!")
  const image = await downloadImage(
    event.s3.original.bucket_name,
    event.s3.original.key
  )

  const thumbnail = await createThumbnail(image)

  const result = await uploadImage(
    event.s3.thumbnail.bucket_name,
    event.s3.original.key,
    thumbnail)

  console.log('finished create thumbnail function!!!')
  return result
}
```

### sharpをLayerに登録する
Lambda関数のサイズを小さくするためにsharpをLayerに登録します。

[公式ドキュメント](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/configuration-layers.html)

1. ディレクトリ `nodejs` を作成する

2. [package.json](./nodejs/package.json) を `nodejs` の下にコピー

3. layerをダウンロード

    `nodejs` の下で `npm install` を実行する

4. zipで固める

    `zip -r sharp.zip nodejs/node_modules`

5. layerを登録する

```
aws lambda publish-layer-version \
--layer-name sharp \
--description "sharp module" \
--zip-file fileb://sharp.zip \
--compatible-runtimes nodejs16.x \
--compatible-architectures "x86_64" 
```

6. lambda関数にLayerを関連付ける

```
aws lambda update-function-configuration \
--layers "layerのVersion ARN" \
--function-name thumbnail
```

### Lambda関数を実行する

```    
aws lambda invoke \
--function-name thumbnail \
--log-type Tail \
--payload "$(echo '{
"s3":{
  "original":{
    "bucket_name":"オリジナル画像のバケット",
    "key":"画像オブジェクトのKey"
  },
  "thumbnail":{
    "bucket_name":"サムネイル画像のバケット"
    }
  }
}' | base64)" \
out \
--output text \
--query 'LogResult' \
| base64 -d
```
