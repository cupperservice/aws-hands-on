# EC2 で DB サーバを起動する
EC2 インスタンスを使用して DB サーバを起動する。  
DB サーバは、[MariaDB](https://mariadb.org/)を使用する。

---
## この課題で作成するシステムの構成
EC2 を利用して2種類のデータベース, MariaDB(RDB)を起動します。  
また、SSH ポートフォーワーディングを利用して DB サーバに接続します。

![](./img/s1.png)

---
## SSH ポートフォーワーディング
任意のポートへの通信を別のホストを経由して別のサーバのポートに転送する。

---
## 事前準備
### CloudShell を起動する

### CloudFormation のテンプレートファイルを CloudShell 上にダウンロードする
以下のコマンドを実行して、template.yaml を CloudShell 上にダウンロードする

```bash
curl https://raw.githubusercontent.com/cupperservice/aws-hands-on/main/docs/hands-on/02.EC2%E3%81%A7DB%E3%82%B5%E3%83%BC%E3%83%90%E3%82%92%E8%B5%B7%E5%8B%95%E3%81%99%E3%82%8B/cfn/template.yaml -o template.yaml
```

### 環境を初期化 (bastion サーバを作成する)
VPC サービスから VPC と Subnet の ID を確認して以下の VPC ID, Subnet ID に置き換えて実行

```bash
VPC_ID=VPC ID
SUBNET_ID=Subnet ID
```

CloudFormation の Stack を作成

```bash
aws cloudformation create-stack \
--stack-name initialize \
--template-body file://template.yaml \
--parameters ParameterKey=VPC,ParameterValue="$VPC_ID" \
ParameterKey=Subnet,ParameterValue="$SUBNET_ID"
```
---
## MariaDB サーバ用の EC2 インスタンスを用意する
### MariaDB サーバ用のセキュリティグループを作成する
* VPC サービスに移動
* 左のメニューから Security groups を選択
* [Create Security Group] を押す
* 以下の項目を入力
    * Security group name: db security group
    * Description: for db server
    * VPC: default
* [Add Rule] を押して Inbound rules を追加
    * Type: SSH
    * Source: bastion security gotup
* [Add Rule] を押して Inbound rules を追加
    * Type: Custom TCP
    * Port range: 3306
    * Source: bastion security group
* [Create security group] を押す

### EC2 インスタンスを作成する
* EC2 サービスに移動
* 左のメニューから instances を選択
* [Launch instances] を押す
* Name: Maria DB Server
* AMI: Amazon Linux 2023 を使用する
* Key pair: vockey を使用する
* Network Settings で [Edit] を押す
    * Auto-assign public IP: Enable を選択する
* Firewall (security groups): 1.で作成したセキュリティグループを選択する
* [Launch instance] を押す

---
## Maria DB をインストールする
### CloudShell から Bastion サーバに SSH で接続する
    
```bash
IP=Bastion サーバの Public IP

eval $(ssh-agent)
ssh-add labsuser.pem
ssh -A ec2-user@"$IP"
```

### Bastion サーバから MariaDB サーバに SSH で接続する

```bash
IP=MariaDB サーバの Private IP

ssh ec2-user@"$IP"
```

### パッケージを最新に更新する  
```bash
sudo dnf update -y
```

### mariadb をインストール
  
```bash
sudo dnf install mariadb105-server
```

### インストール結果の確認  
以下のコマンドを実行してインストーすされたことを確認する

```bash
dnf info mariadb105
```

インストールが成功している場合は以下のように表示される

```bash
Amazon Linux 2023repository                                                                                                                                                       27 MB/s |  14MB     00:00    
Amazon Linux 2023 Kernel Livepatchrepository                                                                                                                                     522 kB/s | 156 kB     00:00    
Installed Packages
Name         : mariadb105
Epoch        : 3
Version      : 10.5.18
Release      : 1.amzn2023.0.1
Architecture : x86_64
Size         : 18 M
Source       : mariadb105-10.5.18-1.amzn2023.0.1.src.rpm
Repository   : @System
From repo    : amazonlinux
Summary      : A very fast and robust SQL database server
URL          : http://mariadb.org
License      : GPLv2 and LGPLv2
Description  : MariaDB is a community developed fork from MySQL - a multi-user,multi-threaded
            : SQL database server. It is a client/server implementation consisting of
            : a server daemon (mariadbd) and many different client programs and libraries.
            : The base package contains the standard MariaDB/MySQL client programs and
            : utilities.
```

### DB サーバを起動  
以下のコマンドを実行して DB サーバを起動する

```bash
sudo systemctl start mariadb
```

### mariadb をセキュアな状態に設定  
以下のコマンドを実行して mariadb のセキュリティを向上させる

```bash
sudo mysql_secure_installation
```

コマンドを実行すると各設定についてどのように処理するかを尋ねられるので以下のように入力する

``` bash
 * Enter current password for root: 空 Enter
 * Switch to unix_socket authentication: 空 Enter
 * Change the root password? [Y/n] : Y を選択
   * root のパスワードを入力 (同じパスワードを2回)
 * Remove anonymous users? [Y/n] : Y を選択
 * Disallow root login remotely? [Y/n] : Y を選択
 * Remove test database and access to it? [Y/n] : Y を選択
 * Reload privilege tables now? [Y/n] : Y を選択
```

### 自動起動を有効化  
以下のコマンドを実行して EC2 を再起動したときに自動的に mariadb を起動するようにする

```bash
sudo systemctl enable mariadb
```

---
## MariaDB にリモートから接続できるようにする。
MariaDB はデフォルトではリモートから接続することができない。  
リモートで接続できるようにセットアップする。
### MariaDB サーバに SSH で接続する
CloudShell から Bastion サーバに接続する
```
IP=Bastion サーバの Public IP
eval $(ssh-agent)
ssh-add labsuser.pem
ssh -A ec2-user@"$IP"
```

Bastion サーバから MariaDB サーバに接続する
```
IP=MariaDB サーバの Private IP
ssh ec2-user@"$DB_IP"
```

### MariaDB の定義ファイルを編集する  
リモートから接続できるように以下の定義ファイルを編集する

ファイル: /etc/my.cnf.d/mariadb-server.cnf

修正内容

修正前

```
#
# Allow server to accept connections on all interfaces.
#
#bind-address=0.0.0.0
```

修正後

```
#
# Allow server to accept connections on all interfaces.
#
bind-address=0.0.0.0
```

### MariaDB を再起動する  
以下のコマンドを実行して mariadb を再起動する

```bash
sudo systemctl restart mariadb
```

### MariaDB に接続する  
`mysql -uroot -p` を実行すると `Enter password:` と表示されるので[mariadb をセキュアな状態に設定](#7-mariadb)で設定したパスワードを入力する

### データベースとデータベースに接続するユーザーを作成

データベースを作成  

```
create database `wordpress-db`;
```

データベースに接続するためのユーザーを作成  

```
create user 'hjuser'@'%' identified by 'password00';
```
    * ユーザーID: hjuser
    * パスワード: password00
    
作成したユーザーにデータベース (wordpress-db) へのアクセス権限を付与  

```
grant all privileges on `wordpress-db`.* to 'hjuser'@'%';
```

変更を有効にする  

```
flush privileges;
```

### MariaDB サーバ, Bastion サーバから抜ける
quit -> exit -> exit で CloudShell まで戻る

---
## CloudShell から MariaDB に接続する
### CloudShell から MariaDB に SSH トンネリングを作成する

```
BASTION_IP=Bastion サーバの Public IP
DB_IP=MariaDB サーバの Private IP
eval $(ssh-agent)
ssh-add labsuser.pem
ssh -A -N -L3306:"$DB_IP":3306 ec2-user@"$BASTION_IP"
```

### 新しいタブを開く  
Actions -> New tab を選択

### MariaDB に接続する

```
mysql -h127.0.0.1 -uhjuser -p wordpress-db
```
