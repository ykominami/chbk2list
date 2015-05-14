# -*- coding: utf-8 -*-
require 'bookmark3'

# パラメーターの読み込み
filename = ARGV[0]

parser = Bk::BookmarkHtmlParser.new( filename )
bookmark = parser.parse
bookmark.collect_category_x
