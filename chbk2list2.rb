# -*- coding: utf-8 -*-
require 'pathname'
require 'nokogiri'
#require 'minitest/autorun'

class Chbk2list
  class Node
    attr_accessor :obj , :parent , :prev , :next , :child, :category, :name ,:youngest

    def initialize(name)
      @name = name
    end
  end

  def initialize(fname)
    @fname = fname
    @node_hs = {}
    @body = nil

    @tag_list = []
    @item_hs = {}
    @dl_hs = {}
    @dt_hs = {}
  end

  def item_n_root_root(root)
    unless @node_hs[root]
      name = root.search("h1").first.text.strip
      @node_hs[:ROOT] = @node_hs[root] = Node.new(name)
    end

    @node_hs[root]
  end

  def item_n_sub_x( item , parent)
    raise unless @node_hs[item]
    raise if @node_hs[item].next
    raise if @node_hs[item].prev

    status = :NORMAL
    if @node_hs[parent]
      if @node_hs[parent].child
        if @node_hs[parent].youngest
          # parentのノードがchild, youngestを持つ（ノーマル）
        else
          # parentのノードがchildのみを持っている。youngestが同じノードを指すようにする
#          raise if @node_hs[parent].child.next
          raise if @node_hs[parent].child.prev
          @node_hs[parent].youngest = @node_hs[parent].child
        end
      else
        if @node_hs[parent].youngest
          # parentのノードがyoungestのみを持っている。childが同じノードを指すようにする
          raise if @node_hs[parent].youngest.prev
          raise if @node_hs[parent].youngest.next
          @node_hs[parent].child = @node_hs[parent].youngest
        else
          # @node_hs[parent]が孤立している
          status = :ALONE
        end
      end
    else
      # parentのノードが存在しないため、parentのノードを生成して、child, youngestがitemのノードを指すようにする。
      @node_hs[parent] = item_n(parent)
      status = :ALONE
    end

    case status
    when :NORMAL
      @node_hs[parent].youngest.next = @node_hs[item]
      @node_hs[item].prev = @node_hs[parent].youngest
      @node_hs[parent].youngest = @node_hs[item]
    when :ALONE
      @node_hs[parent].child = @node_hs[item]
      @node_hs[parent].youngest = @node_hs[item]
    else
      raise
    end

    if @node_hs[parent].youngest.next
      raise 
    end

    @node_hs[item].parent = @node_hs[parent]
    @node_hs[item].category = [@node_hs[parent].category , @node_hs[item].name].join('/')
  end

  def item_n_sub( item )
    parent = item.parent

    if @node_hs[parent]
      if @node_hs[parent].child
#        raise if @node_hs[parent].child.next
        raise if @node_hs[parent].child.prev
      end
    end

    # itemは<dl>要素または<dt>要素
    case item.name.downcase
    when "dl"
      # <dl>の直前の<dt>の直下の<H3>のテキストから<dl>に対応する1個のNodeを作る
      # parentが存在しなければならない
      raise unless parent

      case parent.name.downcase 
      when "dl"
        dt = parent.children[ parent.children.index(item) - 1 ]
        name = dt.search("h3").first.text.strip
        @node_hs[item] = Node.new(name)
        
        item_n_sub_x( item , parent)

      when "body"
        name = parent.search("h1").first.text.strip
        @node_hs[item] = Node.new(name)
        item_n_root_root(parent)
        item_n_sub_x( item , parent)

      else
        # <dl> , <body>以外であれば例外を投げる
        raise 
      end
    when "dt"
      unless parent
        raise
      end
      unless @node_hs[parent]
        raise
      end
      raise

    when "body"
      # Nodeの木のルートにする
      item_n_root_root(item)
    else
      # 上記以外のパターンであれば例外を投げる
      raise
    end

    raise unless @node_hs[item]

    @node_hs[item]
  end

  def item_n( item )
    # itemが存在しなければならない
    raise unless item

    ret = @node_hs[item] != nil ? @node_hs[item] : item_n_sub( item )

    ret
  end

  def item_a( item )
    # itemは<a>要素
    # item.parentは<dt>要素
    parent = item.parent
    # ここで生成するNode(またこのNodeは葉である)はitemとitem.parentに対応する
    @node_hs[parent] = @node_hs[item] = Node.new( item.text.strip )

    # parent.parentは<dt>要素あるいは<dl>要素

    # parent.parentが初めて現れた場合は、item_nメソッドで対応するNodeを作成
    unless @node_hs[parent.parent]
      @node_hs[parent.parent] = item_n( parent.parent )
    end

    case parent.parent.name 
    when "dl","body"
      # Nodeの親子関係を設定
      @node_hs[parent].parent = @node_hs[parent.parent]
      unless @node_hs[parent.parent].child
        @node_hs[parent.parent].child = @node_hs[parent]
      end

      unless @node_hs[parent.parent].youngest
        @node_hs[parent.parent].child = @node_hs[parent]
      else
        raise if @node_hs[parent.parent].youngest.next
        @node_hs[parent.parent].youngest.next = @node_hs[parent]
        @node_hs[parent].prev = @node_hs[parent.parent].youngest
        @node_hs[parent.parent].youngest = @node_hs[parent]
      end
      @node_hs[parent].parent = @node_hs[parent.parent] 

      raise if @node_hs[parent].category
      @node_hs[parent].category = @node_hs[parent.parent].category
#
    when "dt"
      # Nodeの前後関係を設定
      raise if @node_hs[parent.parent].next
      @node_hs[parent.parent].next = @node_hs[parent]
      @node_hs[parent].prev = @node_hs[parent.parent]
      @node_hs[parent].parent = @node_hs[parent.parent].parent
      @node_hs[parent].category = @node_hs[parent.parent].category
    else
      raise
    end

    @node_hs[item]
  end

  def get_top( item )
    if item.name != "body"
      @tag_list.unshift( item )
      get_top( item.parent )
    end
  end

  def item_dt( item )
    ret = nil
    ch = item.children[0]
    case ch.name
    when /H3/i
#      puts "item_dt H3"
      ret = ch.text
    when /A/i
#      puts "item_dt A"
      ret = ch.text
    else
      puts "item_dt ELSE #{ch.name}"
    end
#    puts "item_dt ret=#{ret}"
    
    ret
  end
  
  def item_dl( item )
    ret = nil
    ch = item.children[0]
    case ch.name
    when /p/i
      ch1 = item.children[1]
      case ch1.name
      when /DT/i
#        puts "item_dl dt"        
        ret = item_dt( ch1 )
#        puts "ret=#{ret}"
      else
#        puts "item_dl else 2 #{ch1.name}"
        ret = ch.text
      end
    else
#      puts "item_dl else 1 #{ch.name}"
    end
#    puts "item_dl ret=#{ret}"
    
    ret
  end

  def assign_name_to_ancesotr_h1(doc)
    x =doc.search("h1").first
    body_title = x.text.strip
    parent = x.parent
    
    z = parent.children.find{ |x| x.name == "dl" }
    @item_hs[z] = { :name => z.name, :title => body_title , :label => nil , :item => z }
  end
  
  def assign_name_to_ancesotr_h3( doc )
    doc.search( "h3" ).each do |x|
      puts x.path
      text = x.text.strip
      puts text
      # parentはdt
      parent = x.parent

      get_top( parent )
      idx = @tag_list.find_index{ |x|  x.name == "dt" }
      # y はdtの１つ上(dl)
      dt = @tag_list[ idx ]
      y = @tag_list[ idx - 1 ]
=begin
      unless @item_hs[y]
        @item_hs[y] = {
          :name => y.name,
          :title => nil ,
          :label => nil ,
          :item => y
        }
      end
=end
      @tag_list = []
      get_top( y )
      #      @item_hs[y][:tag_list] = @tag_list
      p "=y.path"
      puts y.path
      p "=parent.path"
      puts parent.path

      puts "=y.children"
      y.children.map{ |x| puts x.path }
      puts "=========="
      idz = y.children.find_index(dt)
      puts "idz=#{idz}"
      z = y.children[ idz + 1 ]
      if @item_hs[z]
        @item_hs[z][:title] = text unless @item_hs[z][:title]
      else
        @item_hs[z] = {
          :name => z.name,
          :title => text ,
          :label => nil ,
          :item => z
        }
      end
      @tag_list = []
      puts "-------------------"
    end
  end
  
  def assign_name_to_ancesotr_a(doc )
    doc.search( "a" ).each do |x|
      text = x.text.strip

      get_top( x.parent )
      
      # dt -> a
      parent = x.parent
      parent_ex = @item_hs[parent]
      if parent_ex
        parent_ex[:title] = text
      else
        @item_hs[parent] = { :name => parent.name, :title => text , :label => nil , :item => parent }
        parent_ex = @item_hs[parent]
      end
      @item_hs[parent][:tag_list] = @tag_list
=begin
      idx = @tag_list.find_index{ |x|  x.name == "dt" }
      y = @tag_list[ idx - 1 ]
      @item_hs[y] = {
        :name => y.name,
        :title => text ,
        :label => nil ,
        :item => y
      }
      @tag_list = []
      get_top( y )
      @item_hs[y][:tag_list] = @tag_list
=end
      @tag_list = []
    end
  end

  def listup_a(doc)
    doc.search("a").each do |t|
      parent = t.parent
      list = @item_hs[parent][:hier]
      unless list
        tag_list = @item_hs[parent][:tag_list]
        idx = tag_list.find_index{ |x| x.name == "dt" }
#        @item_hs[parent][:hier] = make_hier( tag_list[0,(idx - 1)] )
        @item_hs[parent][:hier] = make_hier( tag_list[0,(idx)] )        
      end
      hier_str = @item_hs[parent][:hier].collect{ |x|  x[:title] }.join("/")
      puts hier_str
      puts @item_hs[parent][:title]
      puts "-----"
    end
  end
  
  def make_hier( tag_list )
    tag_list.collect{ |x|
      puts x.name
      case x.name
      when "dt"
        @item_hs[x] = { :name => x.name, :title => nil , :label => nil , :item => x } unless @item_hs[x]
      when "dl"
        @item_hs[x] = { :name => x.name, :title => nil , :label => nil , :item => x } unless @item_hs[x]
      else
#        puts x.text
      end
      @item_hs[x]
    }
  end

  def get_category_listy
    File.open( @fname ){ |file|
      doc = Nokogiri::HTML::Document.parse(file)
      assign_name_to_ancesotr_h1( doc )
      assign_name_to_ancesotr_h3( doc )
      assign_name_to_ancesotr_a( doc )
      listup_a(doc)
    }
  end
 
  def print_node_tree_sub( node )
    if node
      puts node.category + " in print_node_tree_sub"
      print_node_tree_sub( node.child )
      print_node_tree_sub( node.next )
    end
  end

  def print_node_tree
    puts "In print_node_tree"
    print_node_tree_sub( @node_hs[:ROOT] )
  end

end

fname = ARGV[0]

#str = Pathname( fname ).expand_path.read
c2l = Chbk2list.new( fname )
#c2l.get_category_list
#c2l.get_category_list2
#c2l.get_category_list_h1
#puts "next get_category_listx"
#c2l.get_category_listx
puts "next get_category_listy"
c2l.get_category_listy
#puts "next print_node_tree"

#c21.print_node_tree
#puts "x"
