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

  def get_category_listy
    File.open( @fname ){ |file|
      doc = Nokogiri::HTML::Document.parse(file)
      doc.search("a").each do |t| 
        # <a>は未発見でなければならない
#        raise if @node_hs[t]
        #
#        p t.search('H3').first
        puts t.text.strip
#        item_a( t )
      end
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
