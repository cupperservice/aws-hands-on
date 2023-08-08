# Lamda関数を使ってみる
この演習では JavaScript を使用して Lambda関数を作成します。

## 公式ドキュメント
https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/welcome.html

## JavaScript用 AWS SDK
https://docs.aws.amazon.com/ja_jp/sdk-for-javascript/v2/developer-guide/welcome.html

## Lambda関数を作成する
1. Lambda関数のコードを作成する

    `thumbnail.js` に以下のコードを記述する

    ``` JavaScript
    exports.handler = async (event, context) => {
        console.log("called thumbnail function!!!")
        console.log(event)
        console.log(context)
        return 200
    }
    ```

2. zipファイルで固める

    `zip thumbnail.zip thumbnail.js`

3. Lambda関数を作成する  
    以下のコマンドを実行し、Lambda関数を作成する

    ```
    aws lambda create-function \
    --function-name thumbnail \
    --zip-file fileb://thumbnail.zip \
    --handler thumbnail.handler \
    --runtime nodejs16.x \
    --role 自分の環境のLabRoleのARN \
    --timeout 60
    ```

    コードを修正した場合は以下のコマンドで更新する

    ```
    aws lambda update-function-code \
    --function-name thumbnail \
    --zip-file fileb://thumbnail.zip
    ```

4. awsコマンドでLambda関数を呼び出す
    ```
    aws lambda invoke \
    --function-name thumbnail \
    --log-type Tail \
    --query 'LogResult' \
    --output text \
    out \
    | base64 -d
    ```

5. 実行結果をAWS Management Consoleで確認する

## JavaScriptからLambda関数を呼び出す
1. `index.js` に以下のコードを記述する

    ``` JavaScript
    const AWS = require('aws-sdk')

    AWS.config.update({
      region: 'us-east-1'
    })

    const lambda = new AWS.Lambda()

    const param = {
      s3: {
        original: {
          bucket_name: 'your-original-bucket-name',
          key: 'name-of-image'
        },
        thumbnail: {
          bucket_name: 'your-thumbnail-bucket-name'
        }
      }
    }

    lambda.invokeAsync(
      {
        FunctionName: 'thumbnail',
        InvokeArgs: JSON.stringify(param)
      },
      (err, data) => {
        if (err) console.log(err)
        else console.log(data)
      }
    )
    ```

2. `npm init` で初期化

3. `npm install aws-sdk` でライブラリをインストール

4. 1.で作成したJavaScriptを実行する

    `node index.js`

5. 実行結果をAWS Management Consoleで確認する

## Thumbnailを作成するコードをLambdaに実装する
以下の部品から要件を満たすLambda関数を作成する

### 要件
* Lambda関数の入力パラメータ
    ``` JavaScript
    s3: {
      original: {
        bucket_name: 画像を読み込むバケット名,
        key: 読み込む画像ファイルんのキー
      },
      thumbnail: {
        bucket_name: サムネイルを保管するバケット名
      }
    }
    ```

* 処理内容  
     1. S3(original bucket)から画像を読み込む
     2. 読み込んだ画像からサムネイル画像を作成
     3. サムネイル画像をS3(thumbnail bucket)に保管

* 必要なモジュール  
    * サムネイル画像を作成するライブラリ  
    `sharp`

### 部品
#### 初期化
``` JavaScript
const AWS = require('aws-sdk')
const sharp = require('sharp')

AWS.config.update({region: 'us-east-1'})
const S3 = new AWS.S3()
```

#### S3から画像を読み込む
``` JavaScript
const downloadImage = (bucket, key) => {
  return new Promise((resolve, reject) => {
    S3.getObject({
      Bucket: bucket,
      Key: key
    }, (err, data) => {
      if (err) reject(err)
      else resolve(data.Body)
    })
  })
}
```

#### 画像からサムネイル画像を生成
``` JavaScript
const createThumbnail = (input) => {
  return sharp(input).resize(100, 100).toBuffer()
}
```

#### S3にサムネイル画像を保管する
``` JavaScript
const uploadImage = (bucket, key, input) => {
  return new Promise((resolve, reject) => {
    S3.upload({
      Bucket: bucket,
      Key: key,
      Body: input,
      ContentType: 'image/png'
    }, (err, data) => {
      if (err) reject(err)
      else resolve(data)
    })
  })
}
```

#### Lamda本体のコード

``` JavaScript
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
公式ドキュメント  
https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/configuration-layers.html

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
