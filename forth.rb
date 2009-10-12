#!/usr/bin/ruby 
require 'rubygems'
require 'forth_parser'

module Forthcan
  class Block
    attr_accessor :name
    def initialize(ast)
      @inst = ast
      @name = "<BLOCK>"
    end
    
    def length
      @inst.length
    end
    
    def [](i)
      @inst[i]
    end

    def call(e,v,c)
      Forthcan::Continuation.new(self).call(e,v,c)
    end

    def self.parse_blocks(data)
      data.map do |d|
        if d.is_a? Array
          Block.new parse_blocks(d)
        else
          d
        end
      end
    end
  end
  
  class Continuation
    def initialize(block)
      @block = block
      @iptr = 0
    end
    
    def eval_next(e,v,c)
      if @iptr >= @block.length
        c.pop
        return
      end
      @block[@iptr].fortheval(e,v,c)
      @iptr += 1
    end
    
    def name
      @block.name
    end
    
    def call(e,v,c)
      if @block.is_a? Proc
        @block.call(e,v,c)
        return
      end
      
      c << self
      nil
    end
  end

  DEFAULTS = {
    :"." => lambda do |e,v,c|
      num = v.pop; args = []
      num.times{ args << v.pop }
      msg = v.pop; receiver = v.pop
      res = receiver.send(msg,*args)
      v << res unless res.nil?  
    end,
    :"::" => lambda do |e,v,c|
      child = v.pop
      parent = v.pop
      v << parent.const_get(child)
    end,
    :";" => lambda do |e,v,c|
      name = v.pop.to_sym;  code = v.pop
      code.name = name
      e[name] = code
    end,
    :swap => lambda do |e,v,c|
      v1 = v.pop;  v2 = v.pop
      v << v1 << v2
    end,
    :rot => lambda do |e,v,c|
      v1 = v.pop;  v2 = v.pop; v3 = v.pop
      v << v2 << v1 << v3
    end,
    :dup => lambda do |e,v,c|
      val = v.pop
      v << val << val
    end,
    :true => lambda{|e,v,c| v << true},
    :false => lambda{|e,v,c| v << false},
    :ruby => lambda do |e,v,c|
      name = v.pop
      v << Kernel.const_get(name)
    end,
    :if => lambda do |e,v,c|
      xelse = v.pop; xthen = v.pop; cond = v.pop
      cond ? xthen.call(e,v,c) : xelse.call(e,v,c)
    end,
    :while => lambda do |e,v,c|
      body = v.pop; cond = v.pop
      condp = lambda{ cond.call(e,v,c); v.pop }
      while r = condp.call
        body.call(e,v,c)
      end
    end,
  }
  STDLIB = "std/std.forth"

  module CoreExt
    module Object
      def fortheval(env,valstack,callstack)
        valstack.push self
      end
      alias_method :call, :fortheval
    end
    
    module Nil
      def fortheval(e,v,c); end
    end
    
    module Symbol
      def fortheval(env,valstack,callstack)
        if env.has_key? self
          Forthcan::Continuation.new(env[self]).call(env,valstack,callstack)
        else
          raise "No word called #{self}"
        end
      end
    end
    
    module Array
      def pushn v
        self << v
        nil
      end
      def popn
        self.pop
        nil
      end
    end
  end

  class Interpreter
    def initialize
      @env = DEFAULTS
      @valstack = []
      @callstack = []
      @vars = {}
      @env[:stack] = lambda{|e,v,c| v << @valstack}
      @env[:callstack] = lambda{|e,v,c| v << @callstack}
      @env[:env] = lambda{|e,v,c| v << @env}
      @env[:vars] = lambda{|e,v,c| v << @vars}
      ::Object.send(:include, CoreExt::Object)
      ::NilClass.send(:include, CoreExt::Nil)
      ::Symbol.send(:include, CoreExt::Symbol)
      ::Array.send(:include, CoreExt::Array)
      load_file STDLIB
    end
    
    def eval_str(str)
      ast = Block.parse_blocks ForthParser.parse(str)
      top = Block.new(ast)
      top.name = "<TOPLEVEL>"
      Continuation.new(top).call(@env,@valstack,@callstack)
      until @callstack.empty?
        @callstack.last.eval_next(@env,@valstack,@callstack) 
      end
    end

    def load_file(name)
      eval_str File.read(name) 
    end

    def repl
      require 'readline'
      Readline.completion_proc = lambda{ |start| @env.keys.select{|x| x.to_s =~ /^#{Regexp.escape(start)}/} }
      while line = Readline.readline("> ",true)
        #begin
          eval_str line
          p @valstack
        #rescue StandardError => e
        #  puts "ERROR: #{e}"
        #  p @valstack, @callstack
        #end
      end
    end
  end
end

if __FILE__ == $0
  int = Forthcan::Interpreter.new
  if ARGV.size >= 1
    int.load_file(ARGV[0])
  end
  int.repl
end
