# -*- coding: utf-8 -*-
#TODO: Refactor Snippet Class
require "erb"
require "optparse"

@@settings ={
  :refe_command => "refe", #Please Use refe2
  :output_dir => "./snippets/ruby-mode",
  :output_classes => %w[Object Array Hash Range Enumerable String ARGF Integer Bignum Fixnum IO File Dir Mutex Module Proc Regexp Time],
  :ac_rsense => true
  }

OptionParser.new do |option|
  option.on("-p", "--refe-command-path PATH", "Specification of Refe Path. defaults system refe."){ |p| @@settings[:refe_command] = p}
  option.on("-o", "--output-dir DIR"){ |d| @@settings[:output_dir] = d}
  option.on("-c", "--output-classes DIR", "Output Classes. specify comma-separated values (e.g. '-c Array,Hash,Enumerable')"){ |d| @@settings[:output_classes] = d.split(",")}
  option.on("-a", "--[no-]rsense"){ |f| @@settings[:ac_rsense] = f}
  option.parse!(ARGV)
end

#exit
class Snippet
  FORMAT = <<EOS
# contributor: Yusuke Kanda <uskanda@gmail.com> (Extracted from Refe2 - "http://i.loveruby.net/ja/prog/refe.html")
# name: <%= @name %>
# key: .<%= @key %>
% if @@settings[:ac_rsense]
# condition: (and ac-rsense-yas-working (string= "<%= @class %>" ac-rsense-yas-class))
% end
# --
.<% counter = 0 %><%= @key %><%= "(" + @args.map{|a| counter += 1;"${" + counter.to_s + ":" + a.name + "}"}.join(",") +")" if @args %><%= "{|" + @block_args.map{|a| counter+=1; "${" + counter.to_s + ":" + a + "}"}.join(",") + "| $" + (counter+1).to_s + "}" if @block_args%>$0
EOS

  def initialize(key, class_name, args, block_args)
    @name = "#{class_name}##{key}"
    @name << "(#{args.map{|m| m.to_s_with_default}.join(',')})" if args.length > 0
    @name << "{|#{block_args.join(',')}}| ...}" if block_args
    @key = key
    @class = class_name
    @args = args
    @block_args = block_args
  end

  def make
    puts "[#{@class}] make a snippet '#{@name}'..."
    File.open(filename,'w') do |f|
      f.print ERB.new(FORMAT,nil,"%").result(binding).chomp
    end
  end

  private
  def filename
    filename = "#{@@settings[:output_dir]}/#{@key}"
    filename << ".#{@class}"
    filename << "_#{@args.join("_")}" if @args.length > 0
    filename << "#{"_block" if @block_args}" if @block_args
    filename
  end
end

class Argument
  attr_accessor :name, :default
  def initialize(name, default)
    @name = name
    @default = default
  end

  def to_s_with_default
    return @name unless default
    "#{@name} = #{@default}"
  end

  def to_s
    @name
  end
  
  def default_for_snippet
    return @default if @default
    @name
  end
end

class ArgFormat < Array
  attr_reader :method_info, :raw,  :has_block, :block_args
  def initialize(method_info, raw)
    @raw = raw
    @method_info = method_info
    @has_block = false
    #extract each arguments
    @raw.match(/.*\((.+)\).*/) do |md|
      ary = md[1].split(",").map do |s|
        argname = s.strip
        default = nil
        s.match(/(.*)\=(.*)/) do |args_md|
          argname = args_md[1].strip
          default = args_md[2].strip
        end
        Argument.new(argname, default)
      end
      self.replace ary
    end
    #extract block
    @raw.match(/.*\{(.+)\}.*/) do |md|
      @has_block = true
      md[1].match(/.*\|(.+)\|.*/) do |block_args_md|
        @block_args = block_args_md[1].split(",").map{|s| s.strip}
      end
    end
  end

  def make_snippets
    return unless need_snippets?
    self.each_with_index do |arg,idx|
      next if arg.default.nil?
      Snippet.new(method_info.name,
                  method_info.class_name,
                  self.first(idx),
                  self.block_args).make
    end
    Snippet.new(method_info.name,
                method_info.class_name,
                self,
                self.block_args).make
  end

  def need_snippets?
    @has_block || self.length > 0
  end
end

class MethodInfo
  attr_reader :expression, :name, :class_name, :doc, :arg_formats, :snippets
  def initialize(expression)
    @expression = expression
    @name = expression.sub(/.+#/,"")
    @class_name = expression.sub(/#.+/,"")
    @doc = `#{@@settings[:refe_command]} "#{@expression}"`
    @arg_formats = []
    @doc.each_line do |line|
      next unless line =~ /^\s*--- (.*) ->.+/
      arg_formats << ArgFormat.new(self, $1)
      arg_formats.last.make_snippets
    end
  end
end

@@settings[:output_classes].each do |c|
  puts "[#{c}] lookup instance methods..."
  result = `#{@@settings[:refe_command]} "#{c}#"`
  unless c == "Object"
    puts "[#{c}] lookup class methods..."  
    result << `#{@@settings[:refe_command]} "#{c}."`
  end
  puts "[#{c}] start generating snippets..."  
  methods = result.split
  methods.each do |m|
    next if m =~ /.+#[^\w].*/
    mi = MethodInfo.new(m)
  end
  puts "[#{c}] snippets generated."
end
