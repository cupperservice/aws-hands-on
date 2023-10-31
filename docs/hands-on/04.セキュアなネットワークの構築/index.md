# セキュアなネットワークの構築
セキュアなネットワークを構築し、その上に [Growi](https://docs.growi.org/) を構築する。

---
## Growi とは
Markdown でドキュメントを書くことができる Wiki ツールです。

---
## この課題で作成するシステムの構成
![](./img/s2.png)

---
## 環境の初期化
CloudFormation を使用して環境を初期化する。

初期化後の環境は以下のようになる。
![](./img/s1.png)

CloudShell を起動する

以下のコマンドを実行して、CloudFormation のテンプレートファイル(template.yaml) を CloudShell 上にダウンロードする

```bash
curl -sL https://raw.githubusercontent.com/cupperservice/aws-hands-on/main/docs/hands-on/04.%E3%82%BB%E3%82%AD%E3%83%A5%E3%82%A2%E3%81%AA%E3%83%8D%E3%83%83%E3%83%88%E3%83%AF%E3%83%BC%E3%82%AF%E3%81%AE%E6%A7%8B%E7%AF%89/cfn/template.yaml -o template.yaml
```

以下のコマンドを実行して環境を初期化する
```
aws cloudformation create-stack \
--stack-name initialize \
--template-body file://template.yaml
```
---
## 環境を構築する
### EC2 インスタンスを用意する
以下の 3つの EC2 インスタンスを用意する

* Web サーバ
* Application サーバ
* MongoDB サーバ

#### __Web サーバを用意する__
Web サーバ用のセキュリティグループを作成する

以下の項目を入力する

|Item               |Value             |
|:------------------|:-----------------|
|Security group name|web security group|
|Description        |for web server    |
|VPC                |MyVPC             |

Inbound Roles に以下の2つのルールを追加

|Type  |Port|Source                |
|:-----|:---|:---------------------|
|SSH   |22  |bastion security group|
|HTTP  |80  |AnywhereIPv4          |

EC2 インスタンスを作成する

以下の項目を入力する

|Item               |Value            |
|:------------------|:----------------|
|Name               |web              |
|AMI                |Amazon Linux 2023|
|Instance type      |t2.micro         |
|Key pair           |vockey           |

Network Settings で [Edit] を押して以下を設定する

|Item                      |Value             |
|:-------------------------|:-----------------|
|VPC                       |MyVPC             |
|Subnet                    |Public-subnet1    |
|Auto-assign public IP     |Enable            |
|Firewall (security groups)|web security group|

#### __Application サーバを用意する__
Application サーバ用のセキュリティグループを作成する

以下の項目を入力する

|Name               |Value                     |
|:------------------|:-------------------------|
|Security group name|application security group|
|Description        |for application server    |
|VPC                |MyVPC                     |

Inbound Roles に以下の2つのルールを追加

|Type        |Port| Source               |
|:-----------|:---|:---------------------|
|SSH         |22  |bastion security group|
|Custom TCP  |3000|web security group    |

EC2 インスタンスを作成する

以下の項目を入力する

|Item               |Value            |
|:------------------|:----------------|
|Name               |application      |
|AMI                |Ubuntu           |
|Instance type      |t2.large         |
|Key pair           |vockey           |

Network Settings で [Edit] を押して以下を設定する

|Item                      |Value                     |
|:-------------------------|:-------------------------|
|VPC                       |MyVPC                     |
|Subnet                    |Private-subnet1           |
|Auto-assign public IP     |Disable                   |
|Firewall (security groups)|application security group|

#### __MongoDB サーバを用意する__
MongoDB サーバ用のセキュリティグループを作成する

以下の項目を入力する

|Item               |Value                 |
|:------------------|:---------------------|
|Security group name|mongodb security group|
|Description        |for mongodb server    |
|VPC                |MyVPC                 |

Inbound Roles に以下の2つのルールを追加

|Type      |Port |Source                    |
|:---------|:----|:-------------------------|
|SSH       |22   |bastion security group    |
|Custom TCP|27017|application security group|

EC2 インスタンスを作成する

以下の項目を入力する

|Item               |Value         |
|:------------------|:-------------|
|Name               |mongodb       |
|AMI                |Amazon Linux 2|
|Instance type      |t2.micro      |
|Key pair           |vockey        |

Network Settings で [Edit] を押して以下を設定する

|Item                      |Value                 |
|:-------------------------|:---------------------|
|VPC                       |MyVPC                 |
|Subnet                    |Private-subnet1       |
|Auto-assign public IP     |Disable               |
|Firewall (security groups)|mongodb security group|

---
## MongoDB サーバを構築する
CloudShell から mongodb サーバの EC2 インスタンスに SSH で接続する

### MongoDB をインストールする
以下のコマンドを実行して、`mongodb-org-6.0.repo` を mongodb サーバ上の `/etc/yum.repos.d/mongodb-org-6.0.repo` に保管する

```bash
sudo curl -sL https://raw.githubusercontent.com/cupperservice/aws-hands-on/main/docs/hands-on/04.%E3%82%BB%E3%82%AD%E3%83%A5%E3%82%A2%E3%81%AA%E3%83%8D%E3%83%83%E3%83%88%E3%83%AF%E3%83%BC%E3%82%AF%E3%81%AE%E6%A7%8B%E7%AF%89/conf/mongodb/mongodb-org-6.0.repo -o /etc/yum.repos.d/mongodb-org-6.0.repo
```

MongoDB をインストールする

```bash
sudo yum install -y mongodb-org
```

インストール結果を確認する

```
mongod --version
```

以下のように表示されればOK

```
mongod --version
db version v6.0.7
Build Info: {
  "version": "6.0.7",
  "gitVersion": "202ad4fda2618c652e35f5981ef2f903d8dd1f1a",
  "openSSLVersion": "OpenSSL 1.0.2k-fips  26 Jan 2017",
  "modules": [],
  "allocator": "tcmalloc",
  "environment": {
    "distmod": "amazon2",
    "distarch": "x86_64",
    "target_arch": "x86_64"
  }
}
```

MongoDB を起動する

```
sudo systemctl start mongod
```

自動起動を有効にする

```
sudo systemctl enable mongod
```

### MongoDB をリモートからアクセスできるようにする
MongoDB の設定ファイルを編集する  
リモートから MongoDB にアクセスできるように設定ファイルを変更する

```
sudo vi /etc/mongod.conf
```

`bindIp` の値を mongodb の EC2 インスタンスの Private IP アドレスに変更する

変更前

```text
# network interfaces
net:
  port: 27017
  bindIp: 127.0.0.1  # Enter 0.0.0.0,:: to bind to all IPv4 and IPv6 addresses or, alternatively, use the net.bindIpAll setting.
```

変更後

```text
# network interfaces
net:
  port: 27017
  bindIp: mongodb EC2 インスタンスの Private IP
```

MongoDB を再起動する

```
sudo systemctl restart mongod
```

以下のコマンドを実行して MongoDB に接続できることを確認する

```
mongosh --host mongodb EC2 インスタンスの Private IP アドレス
```

以下のように MongoDB shell が起動すればOK

```
mongosh --host 10.0.30.46
Current Mongosh Log ID: 64a532a9a3cb3b62677c402e
Connecting to:          mongodb://10.0.30.46:27017/?directConnection=trueappName=mongosh+1.10.1
Using MongoDB:          6.0.7
Using Mongosh:          1.10.1
For mongosh info see: https://docs.mongodb.com/mongodb-shell/
------
  The server generated these startup warnings when booting
  2023-07-05T09:04:13.226+00:00: Access control is not enabled for the database. Read and write access to data and configuration is unrestricted
   2023-07-05T09:04:13.226+00:00: vm.max_map_count is too low
------
test>
```

MongoDB shell を抜ける

```
quit
```

---
## Application サーバを構築する
CloudShell から application サーバの EC2 インスタンスに SSH で接続する

### 必要なパッケージをインストールする
nodejs をインストールする  
以下のコマンドを実行して nodejs 関連のパッケージをインストールする

* リポジトリを設定
```bash
curl -sL https://deb.nodesource.com/setup_14.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
```

* nodejs をインストール
    
```bash
sudo apt-get install nodejs
```

* yarn をインストール

```bash
sudo npm install -g yarn
```

* インストール結果を確認  

以下のように表示されればOK

```bash
node -v
v14.21.3
```
```bash
yarn -v
1.22.19
```

### growi をセットアップする

* インストール先ディレクトリを作成

```bash
sudo mkdir /opt
```

* インストール先ディレクトリのオーナーを変更
```bash
sudo chown ubuntu /opt
```

* インストール先ディレクトリに移動
```bash
cd /opt
```

* growi を github から取得

```bash
git clone https://github.com/weseek/growi.git
```

* 使用する growi のバージョンを指定
```bash
cd growi
git checkout -b v4.5.8 refs/tags/v4.5.8
```

* 必要なパッケージをインストール
```bash
npm install lerna bootstrap
npx lerna bootstrap
```

growi の起動設定をセットアップ

以下のコマンドを実行して、growi の定義ファイルを application サーバ上の `/opt/growi/growi.conf` に保管する

```bash
curl -sL https://raw.githubusercontent.com/cupperservice/aws-hands-on/main/docs/hands-on/04.%E3%82%BB%E3%82%AD%E3%83%A5%E3%82%A2%E3%81%AA%E3%83%8D%E3%83%83%E3%83%88%E3%83%AF%E3%83%BC%E3%82%AF%E3%81%AE%E6%A7%8B%E7%AF%89/conf/growi/growi.conf -o /opt/growi/growi.conf
```

`/opt/growi/growi.conf` を編集  
`<mongodb>` の部分を mongodb サーバの Private IP アドレスに変更する

* 変更前
      
```
MONGO_URI="mongodb://<mongodb>:27017/growi"
```

* 変更後

```
MONGO_URI="mongodb://10.0.30.210:27017/growi"
```

以下のコマンドを実行して、growi を起動するためのユニットファイルを application サーバ上の `/etc/systemd/system/growi.service` に保管する

```bash
sudo curl -sL https://raw.githubusercontent.com/cupperservice/aws-hands-on/main/docs/hands-on/04.%E3%82%BB%E3%82%AD%E3%83%A5%E3%82%A2%E3%81%AA%E3%83%8D%E3%83%83%E3%83%88%E3%83%AF%E3%83%BC%E3%82%AF%E3%81%AE%E6%A7%8B%E7%AF%89/conf/growi/growi.service -o /etc/systemd/system/growi.service
```

定義を `systemd` に認識させる

```bash
sudo systemctl daemon-reload
```

growi を起動
```bash
sudo systemctl start growi
```

起動結果を確認
```bash
sudo journalctl -f -u growi
```

以下のように表示されればOK
```text
Jul 08 00:03:51 ip-10-0-30-92 npm[2806]: > growi@4.5.8 start /opt/growi
Jul 08 00:03:51 ip-10-0-30-92 npm[2806]: > yarn app:server
Jul 08 00:03:51 ip-10-0-30-92 npm[3684]: yarn run v1.22.19
Jul 08 00:03:51 ip-10-0-30-92 npm[3684]: $ yarn lerna run server --scope@growi/app
Jul 08 00:03:51 ip-10-0-30-92 npm[3696]: $ /opt/growi/node_modules/.binlerna run server --scope @growi/app
Jul 08 00:03:52 ip-10-0-30-92 npm[3708]: lerna notice cli v4.0.0
Jul 08 00:03:52 ip-10-0-30-92 npm[3708]: lerna notice filter including"@growi/app"
Jul 08 00:03:52 ip-10-0-30-92 npm[3708]: lerna info filter [ '@growi/app' ]
Jul 08 00:03:52 ip-10-0-30-92 npm[3708]: lerna info Executing command in 1package: "yarn run server"
```

growi の自動起動を設定
```bash
sudo systemctl enable growi
```

---
## Web サーバを構築する
### Nginx をインストールする
web サーバに CloudShell から SSH で接続する

nginx をインストールする
```bash
sudo dnf install nginx -y
```

nginx を起動する
```bash
sudo systemctl start nginx
```

nginx の自動起動を有効にする
```
sudo systemctl enable nginx
```

Web ブラウザから web サーバの Public IP アドレスにアクセスして nginx が動作していることを確認する

以下のように表示されればOK
![](./img/nginx.png)

### リバースプロキシの設定
以下のコマンドを実行して、リバースプロキシ用の定義ファイル を web サーバ上の `/etc/nginx/conf.d/growi.conf` に保管する

```bash
sudo curl -sL https://raw.githubusercontent.com/cupperservice/aws-hands-on/main/docs/hands-on/04.%E3%82%BB%E3%82%AD%E3%83%A5%E3%82%A2%E3%81%AA%E3%83%8D%E3%83%83%E3%83%88%E3%83%AF%E3%83%BC%E3%82%AF%E3%81%AE%E6%A7%8B%E7%AF%89/conf/nginx/growi.conf -o /etc/nginx/conf.d/growi.conf
```

リバースプロキシの定義ファイルを編集  
    vi で編集する例  
    `sudo vi /etc/nginx/conf.d/growi.conf`

`<application>`の部分を Application サーバの Private IPv4 address に変更する

* 編集前
```text
upstream growi {
    server <application>:3000;
}
```

* 編集後の例
```text
upstream growi {
    server 10.0.10.200:3000;
}
```

`server_name`を探して、`<server>` を Web サーバの Public IPv4 address に変更する

* 編集前
```
server {
    listen 80;
    server_name <server>;
```

* 編集後の例
```
server {
    listen 80;
    server_name 54.175.66.232;
```

以下のコマンドを実行して Nginx を再起動する  
```bash
sudo systemctl restart nginx
```

## Growi が動作することを確認
Web ブラウザから web サーバの Public IP アドレスにアクセスして以下のように表示されればOK

![](./img/growi.png)
