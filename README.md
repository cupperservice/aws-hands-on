# 環境構築方法
1. S3 バケット作成  

    ドキュメントを保管するバケットを作成する

2. ID プロバイダ登録
arn:aws:iam::391726422976:oidc-provider/token.actions.githubusercontent.com

3. ロール作成
arn:aws:iam::391726422976:role/aws-hands-on-kawashima-kazuh

4. CloudFront Distribution作成

4. シークレット登録

    Github に以下のシークレットを登録する

    * AWS_ROLE_ARN
    * AWS_REGION
    * BUCKET_NAME
