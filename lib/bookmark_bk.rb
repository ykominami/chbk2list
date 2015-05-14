# -*- coding: utf-8 -*-
require 'active_record'
require 'pp'

class Bk
  module Bkutil
    # === Bk::Bkutil::Dbクラス
    #
    # 
    class Db
      # === Bk::Bkutil::Db::Corespondingクラス
      #
      # テーブルCoresponding
      class Coresponding < ActiveRecord::Base
        def to_s
          return "#{id}@#{bookmark_id}:#{category_id}"
        end
      end

      # === Bk::Bkutil::Db::CorespondingInitクラス
      # 
      # テーブルCorespondingのマイグレート
      class CorespondingInit < ActiveRecord::Migration
        def self.up
          begin
            create_table(:corespondings){ |t|
              t.column :bookmark_id, :int, :null => false
              t.column :category_id, :int, :null => false
              t.column :start_datetime, :datetime, :null => false
              t.column :end_datetime, :datetime, :null => true
            }
            #        add_index :categories , :name, :unique => true
          rescue => ex
          end

        end

        def self.down
          drop_table(:corespondings) 
        end
      end

      # === Bk::Bkutil::Db::Categoryクラス
      # 
      # テーブルCategory
      class Category < ActiveRecord::Base
        def to_s
          return "#{id}@#{time}: #{text}"
        end
      end
      
      # === Bk::Bkutil::Db::CategoryInitクラス
      # 
      # テーブルCategoryのマイグレート
      class CategoryInit < ActiveRecord::Migration
        def self.up
          begin
            create_table(:categories){ |t|
              t.column :name, :string, :limit => 200, :null =>false
              t.column :desc, :string,    :null => true
              t.column :start_datetime, :datetime, :null => false
              t.column :end_datetime, :datetime, :null => true
            }
            #        add_index :categories , :name, :unique => true
          rescue => ex
          end
          
        end

        def self.down
          drop_table(:categories) 
        end
      end

      # === Bk::Bkutil::Db::Bookmarkクラス
      # 
      # テーブルBookmark
      class Bookmark < ActiveRecord::Base
        def to_s
          return "#{id}@#{title}:#{uri}"
        end

        def Bookmark.get(uri)
          Bookmark.find( uri: uri )
        end
      end

      # === Bk::Bkutil::Db::BookmarkInitクラス
      # 
      # テーブルBookmarkのマイグレート
      class BookmarkInit < ActiveRecord::Migration
        def self.up
          begin
            create_table(:bookmarks){ |t|
              t.column :title, :string, :limit => 200, :null =>false
              t.column :uri, :string,    :null => false
              t.column :desc, :string,    :null => true
              t.column :start_datetime, :datetime, :null => false
              t.column :end_datetime, :datetime, :null => true
            }
            #       add_index :bookmarks , :uri, :unique => true
          rescue => ex
          end
        end
        
        def self.down
          drop_table(:bookmarks) 
        end
      end

      # === Bk::Bkutil::Db::BookmarkMgrクラス
      #
      # テーブルBookmarkへのブックマークの新規登録、削除
      class BookmarkMgr

        # @param [Time] register_time データベースへの登録時間
        def initialize(register_time)
          @register_time = register_time
          @hs_by_uri = {}
          @hs_by_id = {}
        end

        # テーブルBookmarkにブックマークを登録する。重複して登録しない。
        #
        # @param [String] title ブックマークの説明
        # @param [String] uri ブックマークのuri
        # @return [Bookmark] テーブルBookmarkへ登録したレコード
        def add( title , uri )
          bookmark = @hs_by_uri[uri]
          unless bookmark
            ary = Bookmark.where( uri: uri , end_datetime: nil )
            if ary.size == 0
              begin
                bookmark = Bookmark.create( title: title , uri: uri , start_datetime: @register_time )
              rescue => ex
                p ex.class
                p ex.message
                pp ex.backtrace
                
                bookmark = nil
              end
            else
              bookmark = ary.first
            end
          end
          if bookmark
            @hs_by_uri[uri] = bookmark
            @hs_by_id[bookmark.id] = bookmark
          end
          bookmark
        end

        # テーブルBookmark上に存在するが、addメソッドで指定されなかったすべてのレコードに対して、終了時間を設定する
        # （テーブルBookmarkへの登録をすべて行った後に呼び出す）
        def post_process
          h_ids = Bookmark.where( end_datetime: nil).select(:id) .collect{ |x| x.id }
          t_ids = @hs_by_id.keys
          ids = h_ids - t_ids
          if ids.size > 0
            ids.each do |idx| 
              Bookmark.where( id: idx ).update_all( end_datetime: @register_time )
            end
          end
        end
      end

      # === Bk::Bkutil::Db::CategoryMgrクラス
      # 
      class CategoryMgr

        # @param [Time] register_time データベースへの登録時間
        def initialize(register_time)
          @register_time = register_time
          @hs_by_name = {}
          @hs_by_id = {}
        end

        # テーブルBookmarkにブックマークを登録する。重複して登録しない。
        #
        # @param [String] title ブックマークの説明
        # @param [String] uri ブックマークのuri
        # @return [Bookmark] テーブルBookmarkへ登録したレコード
        def add( name )
          category = @hs_by_name[name]
          unless category
            ary = Category.where( name: name , end_datetime: nil)
            if ary.size == 0
              begin
                category = Category.create( name: name , start_datetime: @register_time )
              rescue => ex
                p ex.class
                p ex.message
                pp ex.backtrace
                
                category = nil
              end
            else
              category = ary.first
            end
          end
          if category
            @hs_by_name[name] = category
            @hs_by_id[category.id] = category
          end
          category
        end
        
        def post_process
          h_ids = Category.where(end_datetime: nil).select(:id) .collect{ |x| x.id }
          t_ids = @hs_by_id.keys
          ids = h_ids - t_ids
          if ids.size > 0
            ids.each do |idx| 
              Category.where( id: idx ).update_all( end_datetime: @register_time )
            end
          end
        end
      end

      # === Bk::Bkutil::Db::CorespondingMgrクラス
      # 
      class CorespondingMgr
        def initialize(register_time)
          @register_time = register_time
          @hs_by_id = {}
          @hs_by_id_bm_cat = {}
          @hs_by_id_cat_bm = {}
        end

        def add( bookmark_id, category_id )
          @hs_by_id_bm_cat[bookmark_id] ||= {}
          @hs_by_id_cat_bm[category_id] ||= {}
          coresponding = @hs_by_id_bm_cat[bookmark_id][category_id]
          unless coresponding
            ary = Coresponding.where( bookmark_id: bookmark_id , category_id: category_id , end_datetime: nil )
            if ary.size == 0
              begin
                coresonding = Coresponding.create( bookmark_id: bookmark_id , category_id: category_id , start_datetime: @register_time )
              rescue => ex
                p ex.class
                p ex.message
                p ex.backtrace
                coresonding = nil
              end
            else
              coresonding = ary.first
            end
          end
          if coresonding
            @hs_by_id_bm_cat[bookmark_id][category_id] = coresonding
            @hs_by_id_cat_bm[category_id][bookmark_id] = coresonding
            @hs_by_id[coresonding.id] = coresonding
          end
          coresonding
        end

        def post_process
          h_ids = Coresponding.where(end_datetime: nil).select(:id) .collect{ |x| x.id }
          t_ids = @hs_by_id.keys
          ids = h_ids - t_ids
          if ids.size > 0
            ids.each do |idx| 
              Coresponding.where( id: idx ).update_all( end_datetime: @register_time )
            end
          end
        end
      end
      
      # for class Db

      # @param [String] db_adapter Database Adapter
      # @param [String] db_path Database File Name
      # @param [Boolean] exec_migrage trueであればmigrateを実行し、falseであれば実行しない
      def initialize( db_adapter: 'sqlite3', db_path: 'db/bookmark.db', exec_migrate: false )
        @exec_migrate = exec_migrate
        @db_adapter = db_adapter
        @db_path = db_path
        
        ActiveRecord::Base.establish_connection(
                                                :adapter => @db_adapter,
                                                :database => @db_path
                                                )
        @register_time = nil

        puts "@db_adapter=#{@db_adapter}"
        puts "@db_path=#{@db_path}"

        if @exec_migrate
          migrate_down
          migrate_up
        end
      end

      def migrate_up
        CorespondingInit.migrate(:up)
        CategoryInit.migrate(:up)
        BookmarkInit.migrate(:up)
      end
      
      def migrate_down
        CorespondingInit.migrate(:down)
        CategoryInit.migrate(:down)
        BookmarkInit.migrate(:down)
      end
      
      def register
        @register_time = Time.now
        @catmgr = CategoryMgr.new(@register_time) 
        @bmmgr = BookmarkMgr.new(@register_time)
        @cormgr = CorespondingMgr.new(@register_time)
      end

      def add_bm( title , uri , category )
        c = @catmgr.add( category )
        bm = @bmmgr.add( title , uri )
        coresonding = @cormgr.add( bm.id, c.id )
      end
      
      def post_process
        @catmgr.post_process
        @bmmgr.post_process
        @cormgr.post_process
      end

      def register_time
        @register_time
      end
    end
  end
end
