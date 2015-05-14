# -*- coding: utf-8 -*-

# = Google Chrome Bookmark(NETSCAPE-Bookmark-file-1) to DB(SQLITE3)
#
# Author:: Yasuo Kominami
# License:: Public domain (unlike other files)
# Support:: http://northern-cross.info/
# Version:: 0.2
#
# 
require 'bookmark_bk'
require 'bookmark_bk_parser'

# NETSCAPE-Bookmark-file-1形式のブックマークファイルを解析し、DL、DTタグ
# で表されるフォルダに分類されるAタグの内容(URLと説明)を取り出し、Sqlite3
# のデータベースに格納します。

# = Bk class
#
# このクラスはBookmarkファイルを解析するクラス、モジュールのグループと、
# 解析結果をデータベース(Sqlite3)に格納するクラス、モジュールのグループ
# の両方のクラス、モジュールを内部に持つ。
class Bk
  # == Bk::Bkutil module
  #
  # このモジュールは、
  # モジュール内で情報を持ち、利用するためにクラスを用いる
  # そのクラスはモジュール内に隠蔽する
  # 
  # クラスメソッドでそのクラスのインスタンスを1個生成し、インスタンスに情報を持たせる
  # クラスメソッドは、インスタンスの生成、管理、割り当てを行う
  # インスタンスにはクラス変数を介してアクセスする
  # モジュールに対するインタフェースは、クラスメソッドのみとする
  # モジュールからもインスタンスに直接アクセスできない
  module Bkutil

    # === Bk::Bkutil::X
    # このクラスは、
    # 
    class X
      attr_accessor :category

      # @return [X] Bk::Bkutil::Xインスタンス
      def initialize( )
        @hs = {}
        @category = {}
      end

      # 以下はインスタンスメソッド定義

      # @param [String] name キー
      # @param [String] str キーに対応する正規表現（正規表現は文字列で表現）
      def add( name , str )
        unless @hs[name]
          esc_str = Regexp.escape(str)
          re = Regexp.new(str)
          @hs[name] = { 
            :str => str, 
            :esc_str => esc_str,
            :re => re
          }
        end
      end

      # @param [String] name キー
      # @return [String] キーに対応する値
      def get( name )
        @hs[name]
      end

      # @param [String] name 親カテゴリ
      # @param [String] str 子カテゴリ
      def add_category( name , str )
        @category[name] ||= []
        @category[name] << str
      end
      
      # @param [String] name 
      # @return [Array] 親カテゴリ名に属する子カテゴリの配列
      def get_category( name )
        @category[name]
      end
      
      # 以下はクラスメソッド定義

      # @param [String] name 親カテゴリ
      # @param [String] str 子カテゴリ
      def X.setup( name , str )
        @@v ||= X.new()
        @@v.add( name , str )
      end

      # @param [String] name 
      # @return [String] 
      def X.get( name )
        @@v.get( name )
      end
      
      def X.category
        @@v.category
      end
      
      def X.get_category( name )
        @@v.get_category( name )
      end
      
      def X.add_category( name , str )
        @@v.add_category( name , str )
      end
      
      def X.output_category
        @@v.add_category( name , str )
      end
    end

    # モジュール

    # @param [String] name 
    def Bkutil.add_category( name , str )
      X.add_category( name , str )
    end
    
    def Bkutil.output_category
      X.category.each do |k,v| 
        puts "* #{k}"
        puts v.join(" ")
      end
    end
    
    def Bkutil.setup( name , str )
      X.setup( name , str )
    end
    
    def Bkutil.attr_analyze( line )
      line.split(/\s+/).inject({}){ |m, item| 
        if item
          if /([^=]+)="([^"]+)"/ =~ item
            m[$1] = $2
          end
        end
        m
      }
    end
    
    def Bkutil.analyze( cname , line )
      nl = {}
      name = ""
      l = line.gsub("¥t", "")
      hs = X.get(cname)
      if hs[:re] =~ l
        nl = Bkutil.attr_analyze( $1 )
        name = $2
      end
      [nl , name]
    end
  end

  class Bookmark
    attr_reader :header, :body

    include Bkutil
    
    def initialize
      Dl.setup
      Dt.setup
      
      @header = Header.new
      @body = Body.new
    end

    def print
      @body.print
    end

    def print_folder
      @body.print_folder
    end

    def print_category
      @body.print_category
    end

    def collect_category_x
      @body.collect_category_x
    end

    def add_bm( &block )
      @body.add_bm( &block )
    end
  end

  module BmOp
    def add_bm( &block )
      if block_given?
        if @dls
          @dls.each do |x|
            x.add_bm(&block)
          end
        end
        if @dts
          @dts.each do |x| 
            x.add_bm(&block)
          end
        end
      end
    end
  end
  
  module ItemPrint
    def print_n2(level, name, dts , dls)
      puts (" "*level) + name if name

      if dts
        dts.each do |x| 
          x.print_n2(level + 1, x.name, x.dts, x.dls )
        end
      end
      if dls
        dls.each do |x| 
          x.print_n2(level + 1 , x.name , x.dts , x.dls )
        end
      end
    end
    
    def print_x(level)
      puts (" "*level) + @name if @name

      if @dts
        @dts.each do |x| 
          x.print_x(level + 1)
        end
      end
      if @dls
        @dls.each do |x| 
          x.print_x(level + 1)
        end
      end
    end

    def print_folder(level)
      puts (" "*level) + @name if @name

      if @dls
        @dls.each do |x| 
          x.print_folder(level + 1)
        end
      end
    end

    def print_category
      puts @category if @category

      if @dls
        @dls.each do |x| 
          x.print_category
        end
      end
    end
  end

  module CategoryOp
    include Bkutil
    
    def collect_category
      Bkutil.add_category( @name , @category )
      
      if @dls
        @dls.each do |x| 
          x.collect_category
        end
      end
    end
  end

  class Header
    attr_accessor :lines

    def initialize
      @lines = Array.new
    end
  end
  
  class Body
    attr_accessor :dts, :dls , :category

    include Bkutil
    include ItemPrint
    include CategoryOp
    include BmOp
    
    def initialize
      @dts = Array.new
      @dls = Array.new
      @category = ""
    end

    def collect_category_x
      collect_category
      Bkutil.output_category
    end
  end

  class Dl
    attr_accessor :name, :dls, :dts, :parent, :attr, :category

    include Bkutil
    include ItemPrint
    include CategoryOp
    include BmOp

    def Dl.setup
      Bkutil.setup( "Dl" , "<DT><H3 ([^>]+)>([^<]+)</H3>" )
    end
    
    def initialize(line, cursor)
      @attr , name = Bkutil.analyze( "Dl" , line )

      @dls = Array.new
      @dts = Array.new
      @name = name
      @parent = cursor
      @category = [@parent.category , @name].join('/')
    end

  end
  
  class Dt 
    attr_accessor :url, :name, :parent , :category

    include Bkutil
    include ItemPrint
    include BmOp

    def Dt.setup
      Bkutil.setup( "Dt" , %q!<DT><A (.+")>([^<]+)</A>! )
    end

    def initialize(line, cursor)
      @attr , name = Bkutil.analyze( "Dt" , line )

      @url = @attr["HREF"]
      @name = name
      @parent = cursor
      @category = @parent.category

      @url ||= %Q!!
      @name ||= %Q!!
      @category ||= %Q!!
    end

    def add_bm( &block )
      yield(@name, @url, @category)
    end

  end
end

