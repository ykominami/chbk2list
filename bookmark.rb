class Bookmark
  attr_reader :header, :body
  def initialize
    @header = Header.new
    @body = Body.new
  end
  def to_s
    @header.to_s + @body.to_s
  end
  def sort
    @body.sort
  end
end
 
class Header
  attr_accessor :lines
  def initialize
    @lines = Array.new
  end
  def to_s
    @lines.to_s
  end
end
 
class Body
  attr_accessor :dts, :dls
  def initialize
    @dts = Array.new
    @dls = Array.new
  end
  def to_s
    @dls.to_s + @dts.to_s
  end
  def sort
    @dls.sort! {|a,b| a.name <=> b.name}
    @dts.sort! {|a,b| a.name <=> b.name}
    @dls.each {|dl|
      dl.sort
    }
  end
end
 
class Dl
  attr_accessor :name, :dls, :dts, :parent
  def initialize(line, cursor)
    name = line.gsub("¥t", "").gsub("
<dt><h3 FOLDED>
", "").gsub("</H3>", "")
    @dls = Array.new
    @dts = Array.new
    @name = name
    @parent = cursor
  end
  def to_s
    result = "
<dt><h3 FOLDED>
"
    result << @name.gsub("¥n", "")
    result << "</H3>&#165;n
<dl><p>
&#165;n"
    result << @dls.to_s
    result << @dts.to_s
    result << "</DL><p>
&#165;n"
  end
  def sort
    @dls.sort! {|a,b| a.name <=> b.name}
    @dts.sort! {|a,b| a.name <=> b.name}
    @dls.each {|dl|
      dl.sort
    }
  end
end
 
class Dt 
  attr_accessor :url, :name, :parent
  def initialize(line, cursor)
    index1 = line.index("=¥"")
    index2 = line.index("¥">")
    index3 = line.index("</")
    @url = line[(index1 + 2)..(index2 - 1)]
    @name = line[(index2 + 2)..(index3 - 1)]
    @parent = cursor
  end
  def to_s
    result = "
<dt><a HREF=&#165;""
    result << @url.to_s
    result << "¥">"
    result << @name.to_s
    result << "</A>¥n"
  end
end
