# -*- coding: utf-8 -*-
require 'pathname'
require 'nokogiri'

class Chbk2list
  def initialize(fname)
    @fname = fname
    @item_hs = {}
    @dl_hs = {}
  end

  def register_hier_item( item )
    rev_hier = item.ancestors()
    rev_hier.pop
    rev_hier.pop
    rev_hier.pop
    # rev_hierを逆順にして、itemを最後尾に追加する
    # ancestors()の返値であるNokogiri::XML::NodeSetがpush, unshiftを
    # サポートしていないため、一旦Arrayに詰め込んでから、itemを追加
    hier = rev_hier.reduce([]){ |s,x|  s.unshift(x) }
    hier.push( item )
    hier.reduce([]){ |s,x|
      register_item( x , nil )
      s.push( @item_hs[x] )
      @item_hs[x][:hier] = s[0 , s.size]
      s
    }
  end

  def register_item( item , title = nil )
    unless @item_hs[item]
      @item_hs[item] = {
        :name => item.name ,
        :title => nil,
        :item => item,
        :hier => [],
        :call_count => -1,
      }
    else
      unless @item_hs[item][:name]
        @item_hs[item][:name] = item.name
      end
      unless @item_hs[item][:item]
        @item_hs[item][:item] = item
      end
      unless @item_hs[item][:hier]
        @item_hs[item][:hier] = []
      end
    end
    if title
      @item_hs[item][:title] = title
    end

    if @item_hs[item][:title]
      #
    end
    @item_hs[item][:call_count] += 1
  end

  def inspect_ancestors( item )
    list = item.ancestors().map{ |x| "#{x.name}(#{x.object_id})<#{@item_hs[x] ? @item_hs[x][:title] : "nil"}>" }
    list.pop
    list.pop
    list.pop
    list.reverse.reduce{ |s,x| s + '/' + x  }
  end
  
  def get_dl_belong_to( item )
    # ancestors()は昇順の配列で返すので、最初に見つかったdlが最も近いdlになる
    item.ancestors().find{ |x| x.name == "dl" }
  end

  def assign_name_to_ancestor_h1(doc)
    x =doc.search("h1").first
    body_title = x.text.strip
    parent = x.parent
    
    dl = parent.children.find{ |x| x.name == "dl" }
    register_hier_item( dl )
    register_item( dl , body_title )
  end

  def assign_name_to_ancestor_h3( doc , state = :second )
    doc.search( "h3" ).each do |x|
      text = x.text.strip
      # parentはdt
      parent = x.parent
      if state != :second
        register_hier_item( parent )
        register_item( parent , text )
      end

      dl = get_dl_belong_to( parent )
      if @item_hs[dl][:title] == nil
        register_item( dl , @dl_hs[ dl.parent ][:text] ) if @dl_hs[ dl.parent ]
        @dl_hs.delete(dl.parent)
      elsif @item_hs[dl][:title].strip.size == 0
        register_item( dl , @dl_hs[ dl.parent ][:text] ) if @dl_hs[ dl.parent ]
        @dl_hs.delete(dl.parent)
      else
        if @dl_hs[dl] == nil
          @dl_hs[ dl ] = { :child => parent, :text => text }
        else
          @dl_hs[ dl ][:text] = text
        end
      end
    end
  end

  def assign_name_to_ancestor_a_stage1(doc )
    doc.search( "a" ).each do |x|
      text = x.text.strip
      # parentはdt
      parent = x.parent
      register_hier_item( parent )
      register_item( parent, text )
    end
  end

  def assign_name_to_ancestor_a_stage2(doc )
    doc.search( "a" ).each do |x|
      text = x.text.strip
      # parentはdt
      parent = x.parent

      dl = get_dl_belong_to( parent )
      dl_parent = dl.parent
      idx = dl_parent.children.index(dl)
      # dlの直前のdtを得る
      step = 1
      while true
        dt = dl_parent.children[ idx - step ]
        break if dt.name == "dt"
        step += 1
        if idx < step
          dt = nil
          break
        end
      end
      if @item_hs[dl] == nil
        register_hier_item( dl )
        register_item( dl , @item_hs[dt][:title] )
      elsif @item_hs[dl][:title] == nil
        @item_hs[dl][:title] = @item_hs[dt][:title]
      end
    end
  end  

  def listup_a(doc)
    doc.search("a").each do |t|
      str = ""
      parent = t.parent
      list = @item_hs[parent][:hier]

#      puts inspect_ancestors( t )
      
      if !list or list.size == 0
        register_hier_item(parent)
        list = @item_hs[parent][:hier]
      end
      if list.size > 0
        idx = list.find_index{ |x| x[:name] == "dt" }
        if idx 
#          listx = list[0, idx - 1 ]
          listx = list[0, idx ]
          if listx
            ax = listx.collect{ |y| y[:title] }
            str = ax.reduce(""){ |s,x| s + '/' + ( x != nil ? x : "") }
            puts "#{str},#{t.text.strip},#{t['href']}\n"
          end
        end
      else
        #
      end
    end
  end

  def get_category_list
    File.open( @fname ){ |file|
      doc = Nokogiri::HTML::Document.parse(file)
      assign_name_to_ancestor_h1( doc )
      assign_name_to_ancestor_h3( doc , :first )
      assign_name_to_ancestor_a_stage1(doc )

      assign_name_to_ancestor_h3( doc , :second )
      assign_name_to_ancestor_a_stage2(doc )

#      print_ancestor_of_h3( doc )

      listup_a(doc)
    }
  end

  def print_ancestor_of_h3( doc )
    doc.search( "h3" ).each do |x|
      puts inspect_ancestors( x )
    end
  end
end

fname = ARGV[0]

c2l = Chbk2list.new( fname )
c2l.get_category_list
