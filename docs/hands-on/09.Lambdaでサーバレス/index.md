# Lamda関数を使ってみる
このハンズオンでは JavaScript を使用して Lambda 関数を作成する方法を学習します。

まずは単にログを出すだけの Lambda 関数を作成し、その後に S3 に保管した画像を読み込んでサムネイル画像を作成する Lambda 関数を作成します。  
また、S3 のトリガーを使用して Lambda 関数を実行する方法も学習します。

## 前提条件
このハンズオンでは Node.js v18 を使用します。  
[Cloud9](https://aws.amazon.com/jp/cloud9/) は、Node.js がインストールされており、ブラウザのみで利用することができるため便利です。

## 公式ドキュメント
* [Lambda](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/welcome.html)
* [JavaScript用 AWS SDK](https://docs.aws.amazon.com/ja_jp/sdk-for-javascript/v2/developer-guide/welcome.html)

## 最初の Lambda 関数を作成する
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
--runtime nodejs18.x \
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

### Lambda 関数を実行する
作成した Lambda 関数を aws コマンドを使用して実行します。

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

### Lambda 関数を削除する
作成した Lambda 関数を削除します。

```bash
aws lambda delete-function \
--function-name thumbnail
```

## Thumbnail を作成する Lambda 関数を作成する
S3 のバケットに保管した画像を Lambda 関数で読み込み、サムネイル画像を作成して別の S3 バケットに保管する Lambda 関数を作成します。

![](./img/thumbnail-1.png)

サムネイル画像は、[sharp](https://github.com/lovell/sharp) というモジュールを使用して作成します。

Lambda 関数を実行するロールは前述の手順で作成したロールを使用します。

### 事前準備
S3 に以下の2つのバケットを作成します。

* オリジナル画像を保管するバケット
* サムネイル画像を保管するバケット
    * バケット名はオリジナル画像を保管するバケット名-thumbnail とします。

### 処理内容
Lambda関数の処理内容は以下とします。

1. S3(original bucket)から画像を読み込む
2. 読み込んだ画像からサムネイル画像を作成
3. サムネイル画像をS3(thumbnail bucket)に保管

### sharp を用意して Layer に登録する
Lambda 関数のサイズを小さくするために sharp を Layer に登録します。

Lambda 関数に使用する外部モジュールを含めることもできますが、Lambda 関数のサイズが大きくなるため、Layer を使用して外部モジュールを登録することが推奨されています。

[公式ドキュメント](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/configuration-layers.html)

ディレクトリ `nodejs` を作成して以下の手順で sharp を Layer に登録します。

#### プロジェクトを初期化する
`nodejs` に移動しプロジェクトを初期化します。  
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

#### sharp をインストールする
以下のコマンドで sharp をインストールします。

```
npm install sharp
```

上記コマンドを実行すると `node_modules` というディレクトリが作成され、その中に sharp がインストールされます。

また、package.json には aws-sdk が dependencies として追加されます。

```javascript
"dependencies": {
  "sharp": "^0.32.5",
}
```

#### Layer を登録する
作成した `nodejs` ディレクトリを zip で固めます。

```bash
zip -r sharp.zip nodejs/node_modules
```

次に以下のコマンドで Layer を登録します。

```bash
aws lambda publish-layer-version \
--layer-name sharp \
--description "sharp module" \
--zip-file fileb://sharp.zip \
--compatible-runtimes nodejs18.x \
--compatible-architectures "x86_64" 
```

上記コマンドを実行すると以下のような結果が表示されます。

```bash
{
    "Content": {
        "Location": "https://prod-iad-c1-djusa-layers.s3.us-east-1.amazonaws.com/snapshots/148125964078/sharp-8e61aa31-1716-408b-8874-fd31a4d56278?versionId=CZWF1Jv8mSHSO2ZCPrZmo8aAO2jHtAQA&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEDkaCXVzLWVhc3QtMSJHMEUCIB8qkqKp2LmIFVhCgqyvCyPnjf35HubnKWUpxGjldlGWAiEA30KYOlLYu2f%2B1krkYPs31Lq1NraSFPHbwNu%2FaMU%2B52kquwUIIRAEGgw0NzkyMzMwMjUzNzkiDJ1zAbtl74xlSrBmwiqYBZZKy4qr5nv883lJUo%2FoZwAgHbywkB2pAU8JvNJyIvHoyhQKT1VH8RKMQL6AU4ENIAxTWkjkqlX3lMkHPkB40IpVQQsGTVcuzs%2FbI1lYuAkSk4%2FCDoX486smm%2BuN2I7MdgyikhcD4GqAwFc7jlD7Cvt0xlt6qlpYY1caZO1mlI7GQuh8R6M8W4ykOvGnpTZ5udLt%2BuseKAEsE4Xb%2B%2Fx40c1KgItAZf1%2BWn60Fz4dvJ%2FP988Tns4lbn%2B84db5CF%2FHNYnx7a1lMmoKeGTWLoLICGFAf9xnbz3ntMhmHg4RpiVBvIyzSfKnIQLx24IP95gqRbCKPKo6dOIeuMoAmEuGC7tNVfae1JflL4FJSU16RYgCQVJMDsx86sbN%2FUnVPXudc74lQTDHOz7pPQqE6oyfhEs308Uf%2BOlZY%2F5QfEaAdKr4JUH0htaA9IIrbGjMgtYAIs%2Bwyq31hlM8eLPsr54zt%2BhwkisUpotlfjalzkiT6w%2Bx2OrR7Mx%2FPl2UVf0HiqgIQ5hvCreykiRnfXmG2P%2FxZb7bv4NYSBWTa6QFUdEJV59OQjXx7ZrS3iNEtQeJovasZCGM0ynG7M%2FFKkUTjGONQSNqnk7XYADkUDtlAEmoBWMpqs6b5jD9oMTeLio%2FLMXC%2BxWrSsi13EosIW7TC9O095fkZ%2F8MtkBR951%2FAoivJSYeGCXZTpkEj4tcREEMPB%2BM8KXZZ35QuGVy1ZciPeWN7gZEOnRQ53QBKJkXXeLw3lcaevXqVMNdp95synoGMCvOkX0oOId2n2zF0mu6doHOAQysn0ch5yQbhU0EHN0ArxQjl0eXJFhvi6RqD6buX6lsSeb7i9tSuJWt4X5Fh9IxPo%2B2cXBtu9DE%2BRClRPCQnSJBjal5Tp8oKHQw0v6DqAY6sQGZkhLELwuNQW9DndrihinO0Z72WgyFaBDLN9ZOyXQ0s97HcU2XOx2i5KEsi8%2B9PDwDXJTZiHmuCP4YFHckKQiKCX35fDP%2BachAIxaFzB47v64JJdUJqymKFnQAtXoUQD0iEhfW0emuaErL1zZhNH2Sx9CVOmg9XhbdpgNYWmiToUOYvbEdV42NQkkVHTWppbY5hohOzTRDMEFfCp1qqRC7XbssbqAFiI0aR3D8mmZxlCQ%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20230913T011710Z&X-Amz-SignedHeaders=host&X-Amz-Expires=600&X-Amz-Credential=ASIAW7FEDUVR4SIHLDW7%2F20230913%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Signature=ba8becb5cc0e55295e63304a37deeb0f0ebe3aa853afd981337f34ce4ef5073b",
        "CodeSha256": "mmGphBPkCFgeol4yhFFJXGNOX+IiEUjtlkSgHSaF+c0=",
        "CodeSize": 7853969
    },
    "LayerArn": "arn:aws:lambda:us-east-1:148125964078:layer:sharp",
    "LayerVersionArn": "arn:aws:lambda:us-east-1:148125964078:layer:sharp:1",
    "Description": "sharp module",
    "CreatedDate": "2023-09-13T01:17:15.998+0000",
    "Version": 1,
    "CompatibleRuntimes": [
        "nodejs18.x"
    ],
    "CompatibleArchitectures": [
        "x86_64"
    ]
}
```

`LayerVersionArn` は後ほど Lambda 関数を作成する際に使用するためメモしておきます。

### Lambda 関数を作成する
Lambda 関数を作成する手順は以下の通りです。

#### Lambda 関数のプロジェクトを作成する
ディレクトリを作成して `npm init` でプロジェクトを初期化します。

ESModule を使用するために `package.json` に以下の内容を追記します。

```json
"type": "module"
```

```json
"dependencies": {
  "sharp": "^0.32.5"
}
```

`package.json` の内容は以下のようになります。

```json
{
  "name": "thumbnail",
  "type": "module",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "sharp": "^0.32.5"
  },
  "author": "",
  "license": "ISC"
}
```

#### Lambda 関数のコードを作成する
上記で作成したディレクトリの下に `thumbnail.js` というファイルを作成します。  
作成したファイルに以下のコードを記述します。

```javascript
import { S3Client, GetObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3"
import sharp from "sharp"

const region = process.env.AWS_REGION

// S3クライアントを作成
const s3client = new S3Client({ region: region })

// 画像をダウンロードする関数
const downloadImage = async (bucket, key) => {
  return await s3client.send(new GetObjectCommand({
    Bucket: bucket,
    Key: key
  }))
}

// サムネイルを作成する関数
const createThumbnail = async (input) => {
  return await sharp(input).resize(100, 100).toBuffer()
}

// 画像をアップロードする関数
const uploadImage = async (bucket, key, input) => {
  return await s3client.send(new PutObjectCommand({
    Bucket: bucket,
    Key: key,
    Body: input,
    ContentType: 'image/png'
  }))
}

// Lambda 関数のエントリポイント
export const handler = async (event, context) => {
  console.log("start create thumbnail function!!!")
  console.log(`region=${region}`)

  // イベントからオリジナル画像のバケット名とキーを取得
  const originalBucket = event.Records[0].s3.bucket.name
  const srcKey = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, " "))

  // サムネイル画像のバケット名を作成
  const thumbnailBucket = `${originalBucket}-thumbnail`

  const image = await downloadImage(
    originalBucket,
    srcKey
  )
  console.log('downloaded original image')

  const buffer = Buffer.concat(await image.Body.toArray())
  const thumbnail = await createThumbnail(buffer)
  console.log('created thumbnail')

  const result = await uploadImage(
    thumbnailBucket,
    srcKey,
    thumbnail
  )
  console.log('uploaded thumbnail')

  console.log('finished create thumbnail function!!!')
  return result
}
```

#### Lambda 関数を登録する
作成した Lambda 関数のコードを zip で固めます。

```bash
zip thumbnail.zip thumbnail.js package.json
```

次に zip で固めた Lambda 関数を登録します。

Layer に登録した sharp の `登録した Layer の Version ARN` は前述の手順でメモしておいたものを使用します。

```bash
aws lambda create-function \
--function-name thumbnail \
--zip-file fileb://thumbnail.zip \
--handler thumbnail.handler \
--runtime nodejs18.x \
--role 作成したロールの ARN \
--layers "登録した Layer の Version ARN" \
--timeout 60
```

AWS management console で Lambda サービスから Functions を確認すると以下のように作成した Lambda 関数が確認できます。

![](./img/thumbnail-2.png)

Function name の thumbnail をクリックすると作成した Lambda 関数の詳細を確認できます。

![](./img/thumbnail-3.png)

画面を下までスクロールして Layers を確認すると登録した Layer が確認できます。

![](./img/thumbnail-4.png)

#### ロールに S3 のアクセス権限を付与する
以下の内容で `my-s3-policy.json` を作成します。

```text
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::オリジナル画像のバケット/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::サムネイル画像のバケット/*"
        }
    ]
}
```

以下のコマンドで IAM ポリシーを作成します。

```bash
aws iam create-policy \
--policy-name my-s3-policy \
--policy-document file://my-s3-policy.json
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

#### Lambda関数を実行する
S3 のバケットにオリジナル画像をアップロードして Lambda 関数が実行されるか確認します。

```bash
aws lambda invoke \
--function-name thumbnail \
--log-type Tail \
--payload "$(echo '{
  "Records": [
    {
      "s3": {
        "bucket": {
          "name": "オリジナル画像の S3 バケット名"
        },
        "object": {
          "key": "オリジナル画像のキー"
        }
      }
    }
  ]
}' | base64)" \
out \
--output text \
--query 'LogResult' \
| base64 -d
```

上記コマンドを実行すると以下のように表示されます。
```
START RequestId: 2be64433-02f8-4762-8cbd-d0d3e6575e9e Version: $LATEST
2023-09-17T02:00:08.040Z        2be64433-02f8-4762-8cbd-d0d3e6575e9e    INFO    start create thumbnail function!!!
2023-09-17T02:00:08.040Z        2be64433-02f8-4762-8cbd-d0d3e6575e9e    INFO    region=us-east-1
2023-09-17T02:00:08.169Z        2be64433-02f8-4762-8cbd-d0d3e6575e9e    INFO    downloaded original image
2023-09-17T02:00:08.468Z        2be64433-02f8-4762-8cbd-d0d3e6575e9e    INFO    created thumbnail
2023-09-17T02:00:08.620Z        2be64433-02f8-4762-8cbd-d0d3e6575e9e    INFO    uploaded thumbnail
2023-09-17T02:00:08.620Z        2be64433-02f8-4762-8cbd-d0d3e6575e9e    INFO    finished create thumbnail function!!!
END RequestId: 2be64433-02f8-4762-8cbd-d0d3e6575e9e
REPORT RequestId: 2be64433-02f8-4762-8cbd-d0d3e6575e9e  Duration: 582.31 ms     Billed Duration: 583 ms Memory Size: 128 MB     Max Memory Used: 118 MB
```

### S3 のトリガーを使用して Lambda 関数を実行する
S3 にはバケット内で発生した特定のイベント（例: オブジェクトの作成、更新、削除など）に対して、AWSサービスやLambda 関数などのリソースを自動的に起動するメカニズムがあります。これを S3 のトリガーと呼びます。

この機能を使用して S3 のバケットに画像をアップロードした際に 作成した Lambda 関数を実行するようにします。

#### Lambda 関数への実行権限を付与する
Lambda 関数を実行するために S3 から Lambda 関数を実行する権限を付与します。

権限を付与するには以下のコマンドを実行します。

* "S3 のバケット名" はオリジナル画像を保管する S3 のバケット名に置き換えてください。
* "アカウント ID" は自身の AWS のアカウント ID に置き換えてください。

```bash
aws lambda add-permission \
--function-name thumbnail \
--principal s3.amazonaws.com \
--statement-id s3invoke \
--action "lambda:InvokeFunction" \
--source-arn arn:aws:s3:::S3 のバケット名 \
--source-account アカウント ID
```

#### S3 のトリガーを作成する
S3 のバケットに画像をアップロードした際に Lambda 関数を実行するように S3 のトリガーを作成します。

以下の JSON を `notification.json` というファイル名で作成します。

* Lambda 関数の ARNは Lambda 関数を作成した際に表示された ARN に置き換えてください。

```
{
"LambdaFunctionConfigurations": [
    {
      "Id": "CreateThumbnailEventConfiguration",
      "LambdaFunctionArn": "Lambda 関数の ARN",
      "Events": [ "s3:ObjectCreated:Put" ]
    }
  ]
}
```

次に以下のコマンドを実行して S3 のトリガーを作成します。  
"S3 のバケット名" はオリジナル画像を保管する S3 のバケット名に置き換えてください。

```
aws s3api put-bucket-notification-configuration \
--bucket S3 のバケット名 \
--notification-configuration file://notification.json
```

![](./img/triger-1.png)

#### S3 バケットに画像をアップロードする
S3 バケットに画像をアップロードして Lambda 関数が実行されるか確認します。

以下は aws コマンドを使用して画像をアップロードする例です。

* S3 のバケット名はオリジナル画像を保管する S3 のバケット名に置き換えてください。

```bash
aws s3 cp img.jpg s3://S3 のバケット名
```

AWS management console でオリジナル画像を保管する S3 バケットに移動して画像がアップロードされているか確認します。

![](./img/triger-2.png)

AWS management console でサムネイル画像を保管する S3 バケットにサムネイル画像が作成されているか確認します。

以下の例では画像のサイズが 79.5 KB から 3.3 KB にリサイズされた画像がオリジナル画像と同じキーで作成されています。

![](./img/triger-3.png)
