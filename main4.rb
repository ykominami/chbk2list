# -*- coding: utf-8 -*-
require 'bookmark2'

# パラメーターの読み込み
filename = ARGV[0]

db = Bk::Bkutil::Db.new(exec_migrate: true)

db.register

