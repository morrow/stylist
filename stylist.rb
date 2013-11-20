#!/usr/bin/env ruby

class Stylist

  # initialize
  def initialize(params)
    # initial stylesheet set to shared
    @stylesheet = "shared"
    # get possible stylesheet names from directory of existing stylesheets  
    stylesheets = Dir::glob("app/assets/stylesheets/*.css").map! { |x| File.basename(x).gsub('.css', '') }    
    # check for user-specified stylesheet
    if params and params.include?("stylesheet") and params["stylesheet"] != "auto" and stylesheets.include?(params["stylesheet"])
      @stylesheet = params["stylesheet"]
    elsif params and params.include?("selector")
      # determine stylesheet from selector
      sanitized_selector = params["selector"].split(' ')[0].gsub(/#|\./, '')
      if sanitized_selector.match /#|\./
        sanitized_selector = sanitized_selector.split(/#|\./)[1]
      end
      # check that stylesheet exists before setting to selector-determined name
      if stylesheets.include?(sanitized_selector)
        @stylesheet = sanitized_selector
      end
    end
    # set stylesheet variable to full path of stylesheet file to write to
    @stylesheet = File.join(Rails.root, "app/assets/stylesheets/#{@stylesheet}.css")
  end

  # parse
  def parse(filename)
    css = {}
    return {:css => {}, :imports => {}, :comments => {}} unless File.exist? filename
    text = File.read filename
    # extract imports
    imports = text.scan /@import.*?;/
    imports.each do |import|
      text = text.gsub import, ''
    end
    # extract comments
    comments = text.scan /\/\*.*?\*\//
    comments.each do |comment|
      text = text.gsub comment, ''
    end    
    # parse remaining text
    text = text.split('}').reject! { |x| x.strip.empty? }
    text.each do |x|
      x = x.split('{')
      selector = x[0].strip
      css[selector] = {} unless css[selector]
      if x.length > 0 and x[1]
        styling = x[1].strip
        styling = styling.split(';')
      else
        styling = []
      end
      styling.each do |y|
        y = y.split(':')
        property = y[0].strip
        value = y[1].strip
        css[selector][property] = value
      end
    end
    return {:css => css, :imports => imports, :comments => comments}
  end

  # sort
  def sort(css)
    tags = []
    classes = []
    ids = []
    wildcards = []
    sorted_keys = []
    css.each do |css_obj|
      selector = css_obj[0]
      case selector[0]
        when '#'
          if selector.strip[-1] == '*'
            wildcards.unshift css_obj
          else
            ids.push css_obj
          end
        when '.' then classes.push css_obj
        else tags.push css_obj
      end
    end
    [tags, classes, wildcards, ids].each do |ary|
      sorted_keys += ary.sort_by { |y| [y, y.length] }
    end
    return sorted_keys
  end

  # set_with_object
  def set_with_object(object)
    set(object[:selector], object[:attribute], object[:value])
  end

  # get_with_object
  def get_with_object(object)
    get(object[:selector], object[:attribute])
  end

  #rm_with_object
  def rm_with_object(object)
    rm(object[:selector], object[:attribute])
  end

  # set
  def set(selector, property, value)
    obj = parse(@stylesheet)
    property = property.strip
    value = value.strip
    obj[:css][selector] = {} unless obj[:css][selector]
    obj[:css][selector][property] = process(property, value)
    write(obj)
    return get(selector, property)
  end

  # rm
  def rm(selector, property=nil)
    obj = parse(@stylesheet)
    return false unless obj
    property = property.strip if property
    if selector and property and obj[:css][selector]
      obj[:css][selector].delete(property)
    elsif selector and obj[:css]
      obj[:css].delete(selector)
    end
    write(obj)
    return get(selector, property)
  end

  # get
  def get(selector=nil, property=nil)
    css = parse(@stylesheet)[:css]
    if selector and property and css[selector]
      obj = {}
      obj[property] = css[selector][property]
      return obj
    elsif selector and css[selector]
      return css[selector]
    else
      return css
    end
  end

  # process
  def process(p,v)
    # quote content attributes
    if p.match /content/i
      v = '"' + v.gsub('"', '') + '"'
    # quote font-families
    elsif p.match /font-family/i
      split = v.split(',')
      _v = []
      split.each do |i|
        _v.push '"' + i.gsub('"', '').strip + '"' 
      end
      v = _v.join(',')
    end
    return v
  end

  # write
  def write(obj)
    text = "/* CSS updated: #{Time.now} */\n"
    css = obj[:css]
    imports = obj[:imports]
    comments = obj[:comments]
    imports.each do |import| 
      text += "#{import}\n"
    end
    css = sort(css)
    css.each do |selector,attributes|
      if not attributes.empty?
        text += "\n#{selector} {\n"
        attributes.sort.each do |property,value|
          value = process(property, value)
          text += "  #{property}:#{value};\n"
        end
        text += "}\n"
      end
    end
    if text and text.length > 0
      f = File.open(@stylesheet, 'w+')
      f.write(text)
      f.close
    end
  end
  
end
