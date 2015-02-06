# -*- coding: utf-8 -*-
require "pathname"
require "nokogiri"

class Chbk2list
  class Node
    def initialize(name)
      @name = name
    end
  end

  def initialize(fname)
    @fname = fname
    @obj_hs = {}
    @body = nil
  end

  def get_top( item , level )
    puts "----"
    puts item.class
    puts item.object_id
    puts item.name
    puts level
    @obj_hs[item] ||= item.name
    
    if item.name == "body"
      @body ||= item
      top_level = level
    else
      top_level = get_top( item.parent , level + 1 ) 
    end
    top_level
  end

  def get_category_list2
    @cnt = 3
    File.open( @fname ){ |file|
      doc = Nokogiri::HTML::Document.parse(file)
      doc.search("a").inject([nil,{}]){|container, t|
        top_level = get_top( t , 1 )
        puts "top_level=#{top_level}"
        puts ""
        @cnt -= 1
        exit if @cnt <= 0
#
        container
      }
    }
  end

  def inspect_item( item , n )
    if item
      case item[n].name
      when "a"
        puts "a"
        puts item[n].text.strip
      when "p"
        puts "p"
#        puts item[n+1].text.strip
        inspect_item( item , n + 1 )
      when "dt"
        puts "dt"
        inspect_item( item[n].children , 0 )
      when "dl"
        puts "dl"
        inspect_item( item[n].children , 0 )
      when "h3"
        puts "h3|#{item[n].text.strip}"
      else
        puts "ELSE|#{item[n].name}"
      end
    end
  end

  def inspect_parent( node )
    puts "************"
    p "node.name=#{node.name}"
#    p "node.children.first.name=#{node.children.first.name}"
#    puts node.children.first.text.strip if node.children.first.name == "a"
    inspect_item( node.children , 0 )

    p "parent.name=#{node.parent.name}"
    ary = []
    parent = nil
    
    if node and node.class == Nokogiri::XML::Element
      parent = node.parent 
      if parent.name != "body"
        parent.children.each do |it|
          break if it == node
          if it.name =~ /dt/i
            text = it.children.first.text.strip
            puts "text=#{text}"
#            ary << it.text.strip 
            ary << text
          end
        end
      else
        parent = nil
      end
    end
    [parent , ary.last]
  end

  def get_category( category_hs , node )
    ary = []
    hs = {}

    while( node )
      node , element = inspect_parent( node )
      if element
        saved_ary = category_hs[ element ]
        unless saved_ary
          hs.each_value do |v|
            v.unshift( element )
          end
          hs[ element ] = [ element ]
          ary.unshift( element ) 
        else
          hs.each do |k,v|
            category_hs[k] = saved_ary + v
          end
          ary.unshift( save_ary )
          break
        end
      end
    end

    ary
  end

  def get_list
    File.open( @fname ){ |file|
      doc = Nokogiri::HTML::Document.parse(file)
      doc.search("a").inject([nil,{}]){|container, t|
        prev_category_ary = container[0]
        category_hs = container[1]
        
        category_ary = get_category( category_hs , t.parent )
        category_ary.shift
        if !prev_category_ary or !(prev_category_ary == category_ary)
          puts ""
          puts category_ary.join("/")
          puts ""
          prev_category_ary = category_ary
        end
        puts "-- #{t.text}"
        puts t[:href]
        
        container[0] = prev_category_ary 
        container
      }
    }
  end

  def get_category_list
    @cnt = 20
    File.open( @fname ){ |file|
      doc = Nokogiri::HTML::Document.parse(file)
      doc.search("a").inject([nil,{}]){|container, t|
        prev_category_ary = container[0]
        category_hs = container[1]
        
        category_ary = get_category( category_hs , t.parent )
        category_ary.shift
        if !prev_category_ary or !(prev_category_ary == category_ary)
          puts category_ary.join("/")
#
          p category_ary
          @cnt -= 1
          exit if @cnt <= 0
#
          prev_category_ary = category_ary
        end
        container[0] = prev_category_ary 
        container
      }
    }
  end
end

fname = ARGV[0]

#str = Pathname( fname ).expand_path.read
c2l = Chbk2list.new( fname )
#c2l.get_category_list
c2l.get_category_list2
