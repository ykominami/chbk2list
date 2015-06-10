#! -*- encoding: utf-8 -*-

class Bk
  # = Bk::BookmarkHtmlParser
  #
  # このクラスはBookmarkファイルを解析して、URLとその説明をカテゴリ別に格納する
  class BookmarkHtmlParser

    # @param [String] filename Bookmarkファイル名
    # @return [Bk::BookmarkhtmlParser] Bookmarkファイルを解析するパーサ
    def initialize( filename )
      @filename = filename
      @content = nil

      get_file_content
      
      # ブックマークデータを格納するインスタンスの生成
      @bookmark = Bk::Bookmark.new
 
      # カーソル位置(dl, bodyのいずれか) 
      @cursor = @bookmark.body
    end

    # 指定されたBookmarkファイルを(UTF-8として)読み込む
    def get_file_content
      # ファイルの読み込み
      file = open(@filename , {:encoding => Encoding::UTF_8})
      @content = file.readlines
      file.close
     end

    # 読み込んだファイルを一行ずつ処理する
    def parse
      ret = nil
      # 入力ファイルを1行ずつ処理する
      if @content
        @content.each_with_index{|line, i|
          if i < 5 then
            #    puts "#{i}|header"
            # ヘッダー部分
            @bookmark.header.lines.push(line)
          elsif line.include?("<DT><H3") then
            #    puts "#{i}|DT"
            # dlの生成
            dl = Bk::Dl.new line, @cursor
            # カーソルが存在するインスタンスのdlsに格納
            @cursor.dls.push(dl)
            # カーソルを1階層下へ変更する
            @cursor = dl
          elsif line.include?("</DL><p>") then
            #    puts "#{i}|/DL"
            # カーソルを1階層上に移動する
            @cursor = @cursor.parent if @cursor.class == Bk::Dl or @cursor.class == Bk::Dt
          elsif line.include?("<DT><A HREF") then
            #    puts "#{i}|DT"
            # dtの生成
            dt = Bk::Dt.new line, @cursor
            # カーソルが存在するインスタンスのdtsに格納
            @cursor.dts.push(dt)
          end
        }
        ret = @bookmark
      end
      ret
    end
  end
end