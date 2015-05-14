# -*- coding: utf-8 -*-
require 'bookmark3'

time0 = Time.now
# パラメーターの読み込み
filename = ARGV[0]

parser = Bk::BookmarkHtmlParser.new( filename )
bookmark = parser.parse
bookmark.collect_category_x

db = Bk::Bkutil::Db.new(db_path: "db/x2.db" , exec_migrate: true)

time1 = Time.now

db.register
bookmark.add_bm { | title , uri , category | 
  db.add_bm( title , uri , category )
}
db.post_process

time2 = Time.now

puts time0
puts time1
puts time2
puts time1 - time0
puts time2 - time1
