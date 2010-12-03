gmap - A short read mapping tool on Sun Grid Engine (ver 0.3.0)
===============================================================

概要
----

gmapはSun Grid Engineを使ってDNAマッピング処理などを手軽に自動分散処理するためのツールです．
TopHat，Bowtie，SOAP2に対応しています．

ダウンロード ＆ インストール
------------

gmapは以下のGitHubリポジトリで公開されています．
ページ右側の"Downloads"をクリックしてプログラムの圧縮ファイル(tar.gzかzip)をダウンロードし，適当なディレクトリに展開してください．  
[https://github.com/mickey24/gmap](https://github.com/mickey24/gmap)

また，gmapを利用するには以下のツールが必要です．
各ツールはSun Grid Engineでジョブを実行する各クラスタの同じディレクトリにインストールされている必要があります．

* Sun Grid Engine
* Ruby (1.9.1以降)
* TopHat
* Bowtie
* SOAP2
* SAM Tools

設定ファイル .gmap
------------------

gmapを利用するには，あらかじめ.gmapファイルをホームディレクトリ以下に用意しておく必要があります．
以下に.gmapファイルの例を示します．

    ruby_path      : /path/to/ruby
    qsub_path      : /path/to/qsub
    
    tophat_path    : /path/to/tophat
    bowtie_path    : /path/to/bowtie
    soap2_path     : /path/to/soap
    samtools_path  : /path/to/samtools
    
    jobname_prefix : m
    queue          : node.q
    threads        : 2
    output_dir     : /path/to/result_dir
    
    genome_config:
     mouse:
      genome_path : /path/to/genome/mouse/%s
      chrnum      : 1-19,X,Y
    
    project_config:
     default:
      tophat    : "--solexa-quals -r 200 --mate-std-dev 50"
      bowtie    : "-X 250 -I 150"
      soap2     : "-x 250 -m 150"
     SRP000198:
      tophat    : "--solexa-quals -r 200 --mate-std-dev 50"
      bowtie    : "-X 250 -I 150"
      soap2     : "-x 250 -m 150"

### 基本設定 (required)

* tophat_path  
  TopHatの実行可能ファイルのpathを指定します．
* bowtie_path  
  Bowtieの実行可能ファイルのpathを指定します．
* soap2_path  
  SOAP2の実行可能ファイルのpathを指定します．
* samtools_path  
  SAM Toolsの実行可能ファイルのpathを指定します．
* ruby_path  
  rubyコマンドのpathを指定します．
* qsub_path  
  qsubコマンドのpathを指定します．
* jobname_prefix  
  ジョブ名のprefixを指定します．Sun Grid Engineに投入されるジョブ名は"#{jobname_prefix}#{染色体番号}"の形式になります．
* queue  
  ジョブを投入するデフォルトのキューを指定します．
* threads  
  ジョブで使うスレッド数を指定します． 各ジョブは指定したスレッド数だけSun Grid EngineのCPUを使用します．
* output_dir  
  出力先ディレクトリを指定します．

### genome_configの設定

genome_configのセクションにはマッピング先となるreference genomeの名前とそのbowtie indexのpath，および染色体番号を記述する必要があります．

#### genome_configの各reference genomeごとの設定 (required)

* genome_path  
  genomeのbowtie indexのpathを指定します．bowtie indexのpathの染色体番号以下を%sで置き換えたものを指定する必要があります．
* chrnum  
  genomeの染色体番号を指定します．カンマ区切りで複数の染色体の指定，ハイフンで範囲指定が可能です．e.g. 1-19,X,Y

### project_configの設定

project_configのセクションには各ツールの実行時に指定したい引数をマッピングするreadsのSRPごとに記述します．
マッピングするshort readsのファイルの絶対pathが"SRPxxx/SRXxxx/SRRxxx.fastq"のような階層構造を含む場合，gmapは該当するSRPのproject_configを使ってジョブを起動します．
該当するproject_configがない場合はproject_configのdefaultセクションの設定が使われます．
defaultの設定は必ず記述しておく必要があります．

#### project_configの各SRPごとの設定 (required)

* tophat  
  TopHatに渡す引数を指定します．
* bowtie  
  Bowtieに渡す引数を指定します．
* soap2  
  SOAP2に渡す引数を指定します．

使い方
------

    /path/to/gmap_dir/bin/gmap -t tool -g genome_name [other_options] /path/to/SRPxxx/SRXxxx/SRRxxx.fastq

### コマンドライン引数 (required)

* -t tool  
  マッピング処理に使うツールの名前を指定します．以下のツールが指定可能です．
  - tophat
  - bowtie
  - soap2
* -g genome_name  
  マッピング先のreference genome名を指定します．
  reference genome名は.gmapのgenome_configで設定した名前を指定することができます．
* /path/to/SRPxxx/SRXxxx/SRRxxx.fastq  
  マッピングするshort readsのfastq/fastaファイルを指定します．
  "〜\_1.fastq"のような名前のファイルを指定すると，自動的に同じディレクトリにある"〜\_2.fastq"をmate pairとして扱います．

### コマンドライン引数 (optional)

* -h  
  helpを表示して終了します．
* -n  
  マッピング先の染色体番号を指定します(省略時は.gmapの設定を利用)．
* -o  
  出力先ディレクトリを指定します(省略時は.gmapの設定を利用)．

詳細な仕様
----------

* マッピングに使ったツール名がtool，マッピングするshort readのfastqファイルのpathが"SRPxxx/SRXxxx/SRRxxx.fastq"のようになっている場合，
  出力先ディレクトリは"output_dir/SRPxxx/SRXxxx/SRRxxx/tool"となります．
  出力先ディレクトリ以下に各染色体ごとの出力が作成されます．
* "出力先ディレクトリ/qsub\_logs"以下にgmapでsubmitされたジョブの動作ログが出力されます．
  この動作ログを確認することで，ジョブが正しく動作しているかどうかをチェックすることができます．

更新履歴
--------

2010/12/02 v0.3.0
  - info: 最初の公開版．

「「
