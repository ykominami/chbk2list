# -*- coding: utf-8 -*-
require "pathname"
require "nokogiri"

def inspect_parent( node )
  ary = []
  parent = nil

  if node and node.class == Nokogiri::XML::Element
    parent = node.parent
    parent.children.each do |it|
      break if it == node
      ary << it.text.strip if it.name =~ /dt/i
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

fname = ARGV[0]

#str = Pathname( fname ).expand_path.read
File.open( fname ){ |file|
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
