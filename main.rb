require 'bookmark'
 
# パラメーターの読み込み
filename = ARGV[0]
 
# ブックマークデータを格納するインスタンスの生成
bookmark = Bookmark.new
 
# ファイルの読み込み
file = open(filename , {:encoding => Encoding::UTF_8})
#content = file.read
content = file.readlines
file.close
 
# カーソル位置(dl, bodyのいずれか) 
cursor = bookmark.body
 
# 入力ファイルを1行ずつ処理する
content.each_with_index{|line, i|
  if i < 5 then
#    puts "#{i}|header"
    # ヘッダー部分
    bookmark.header.lines.push(line)
  elsif line.include?("<DT><H3") then
#    puts "#{i}|DT"
    # dlの生成
    dl = Dl.new line, cursor
    # カーソルが存在するインスタンスのdlsに格納
    cursor.dls.push(dl)
    # カーソルを1階層下へ変更する
    cursor = dl
  elsif line.include?("</DL><p>") then
#    puts "#{i}|/DL"
    # カーソルを1階層上に移動する
    cursor = cursor.parent if cursor.class == Dl or cursor.class == Dt
  elsif line.include?("<DT><A HREF") then
#    puts "#{i}|DT"
    # dtの生成
    dt = Dt.new line, cursor
    # カーソルが存在するインスタンスのdtsに格納
    cursor.dts.push(dt)
  end
}

#bookmark.print
bookmark.print_folder

=begin 
# ソート
bookmark.sort
 
# 結果の書き出し
puts bookmark.to_s
=end
