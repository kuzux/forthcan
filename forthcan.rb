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

    def call(int)
      Forthcan::Continuation.new(self).call(int)
    end

    def to_proc(int)
      cont = Forthcan::Continuation.new(self)
      lambda do |*args|
        args.each{ |a| int.valstack << a }
        cont.call
        while c.include? cont
          int.eval_next
        end
      end
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
    
    def eval_next(int)
      if @iptr >= @block.length
        int.callstack.pop
        return
      end
      @block[@iptr].fortheval(int)
      @iptr += 1
    end
    
    def name
      @block.name
    end
    
    def call(int)
      if @block.is_a? Proc
        @block.call(int)
        return
      end
      
      int.callstack << self
      nil
    end
  end

  DEFAULTS = {
    :"." => lambda do |int|
      v = int.valstack
      num = v.pop; args = []
      num.times{ args << v.pop }
      msg = v.pop; receiver = v.pop
      res = receiver.send(msg,*args)
      v << res unless res.nil?  
    end,
    :"::" => lambda do |int|
      v = int.valstack
      child = v.pop
      parent = v.pop
      v << parent.const_get(child)
    end,
    :";" => lambda do |int|
      v = int.valstack
      name = v.pop.to_sym;  code = v.pop
      code.name = name
      int.env[name] = code
    end,
    :swap => lambda do |int|
      v = int.valstack
      v1 = v.pop;  v2 = v.pop
      v << v1 << v2
    end,
    :rot => lambda do |int|
      v = int.valstack
      v1 = v.pop;  v2 = v.pop; v3 = v.pop
      v << v2 << v1 << v3
    end,
    :dup => lambda do |int|
      v = int.valstack
      val = v.pop
      v << val << val
    end,
    :true => lambda{|int| int.valstack << true},
    :false => lambda{|int| int.valstack << false},
    :ruby => lambda do |int|
      v = int.valstack
      name = v.pop
      v << Kernel.const_get(name)
    end,
    :if => lambda do |int|
      v = int.valstack
      xelse = v.pop; xthen = v.pop; cond = v.pop
      cond ? xthen.call(int) : xelse.call(int)
    end,
    :while => lambda do |int|
      v = int.valstack
      body = v.pop; cond = v.pop
      condp = lambda{ cond.call(int); v.pop }
      while r = condp.call
        body.call(int)
      end
    end,
  }
  STDLIB = "std/std.forth"

  module CoreExt
    module Object
      def fortheval(int)
        int.valstack.push self
      end
      alias_method :call, :fortheval
    end
    
    module Nil
      def fortheval(int); end
    end
    
    module Symbol
      def fortheval(int)
        if int.env.has_key? self
          int.env[self].call(int)
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
    attr_reader :valstack, :callstack, :env
    def initialize
      @env = DEFAULTS
      @valstack = []
      @callstack = []
      @vars = {}
      @env[:stack] = lambda{|int| int.valstack << @valstack}
      @env[:callstack] = lambda{|int| int.valstack << @callstack}
      @env[:env] = lambda{|int| int.valstack << @env}
      @env[:vars] = lambda{|int| int.valstack << @vars}
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
      Continuation.new(top).call(self)
      eval_next until @callstack.empty?
    end

    def eval_next
      @callstack.last.eval_next(self)
    end

    def load_file(name)
      eval_str File.read(name)
    end

    def repl
      require 'readline'
      Readline.completion_proc = lambda{ |start| @env.keys.select{|x| x.to_s =~ /^#{Regexp.escape(start)}/} }
      while line = Readline.readline("> ",true)
        begin
          eval_str line
          p @valstack
        rescue StandardError => e
          puts "ERROR: #{e}"
          p @valstack, @callstack.map{|c| c.name}
        end
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
