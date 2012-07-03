require "datagrid/utils"
require "active_support/core_ext/class/attribute"

module Datagrid

  module Columns
    require "datagrid/columns/column"
    require "datagrid/columns/header"

    def self.included(base)
      base.extend         ClassMethods
      base.class_eval do

        include InstanceMethods
        include Datagrid::Core
        #class_attribute :columns_array
        #self.columns_array = []

        attr_accessor :headers, :header_depth

      end
      #base.send :include, InstanceMethods
    end # self.included

    module ClassMethods

      #def columns(*args)
        #options = args.extract_options!
        #args.compact!
        #args.map!(&:to_sym)
        #columns_array.select do |column|
          #(!options[:data] || column.data?) && (args.empty? || args.include?(column.name))
        #end

      # Example:
      # group :full_name do
      #   column :first_name
      #   column :last_name
      # end
      #
      # Result:
      # |        Full name       |
      # | First name | Last name |
      def group(name, options = {}, &block)
        return unless block_given?

        @columns ||= []
        @columns << [:group, name, options, block]
      end

      def column(name, options = {}, &block)
        check_scope_defined!("Scope should be defined before columns")
        block ||= lambda do |model|
          model.send(name)
        end

        @columns ||= []
        @columns << [:column, name, options, block]
      end

      def columns
        @columns ||= []
      end

      def columns=(columns)
        @columns = columns
      end

      def inherited(child_class)
        super(child_class)
        child_class.columns = self.columns.clone
      end

    end # ClassMethods

    module InstanceMethods

      def initialize(attributes = nil)
        @level = 0
        @headers = []
        @columns = []
        @colspan = [0]
        @parents = []

        process
        super
      end

      def process
        self.class.columns.each do |col|
          data = col.dup
          type = data.shift
          block = data.pop
          type == :group ? group(*data, &block) : column(*data, &block)
        end
      end

      def group(name, options = {}, &block)
        @headers << Datagrid::Columns::Header.new(self, @parents.last, name, @level, options)
        header = @headers.last
        @parents << header

        @level += 1

        block.arity == 1 ? instance_eval(self, &block) : instance_eval(&block) if block_given?

        @level -= 1

        header.colspan = @colspan[@level]

        @parents.pop
        @colspan[@level] = 0
      end

      def column(name, options = {}, &block)
        @headers << Datagrid::Columns::Header.new(self, @parents.last, name, @level, options)

        @columns << Datagrid::Columns::Column.new(self, @headers.last, name, options, &block)
        0.upto(@level - 1) do |index|
          @colspan[index] ||= 0
          @colspan[index] += 1
        end

        @header_depth = [@level + 1, @header_depth || 1].max
      end

      # Returns <tt>Array</tt> of human readable column names. See also "Localization" section
      def header
        data_columns.map(&:header)
      end

      def header_for_csv
        data_columns.map do |col|
          header_chain = []
          parent = col
          while parent = parent.parent do
            header_chain << parent.header
          end
          header_chain.reverse.join(": ")
        end
      end

      def columns(*args)
        if args.first.is_a?(Hash)
          options = args.first
          (@columns ||= []).reject do |column|
            options[:data] && column.html?
          end
        elsif !args.blank?
          (@columns ||= []).select do |column|
            args.include?(column.name)
          end
        else
          @columns
        end
      end

      def columns=(columns)
        @columns = columns
      end

      # Returns <tt>Array</tt> column values for given asset
      def row_for(asset)
        data_columns.map do |column|
          column.value(asset, self)
        end
      end

      # Returns <tt>Hash</tt> where keys are column names and values are column values for the given asset
      def hash_for(asset)
        result = {}
        data_columns.each do |column|
          result[column.name] = column.value(asset, self)
        end
        result
      end

      # Returns Array of Arrays with data for each row in datagrid assets without header.
      def rows
        self.assets.map do |asset|
          self.row_for(asset)
        end
      end

      # Returns Array of Arrays with data for each row in datagrid assets with header.
      def data
        self.rows.unshift(self.header)
      end

      # Return Array of Hashes where keys are column names and values are column values for each row in datagrid <tt>#assets</tt>
      def data_hash
        self.assets.map do |asset|
          hash_for(asset)
        end
      end

      def to_csv(options = {})
        klass = if RUBY_VERSION >= "1.9"
                  require 'csv'
                  CSV
                else
                  require "fastercsv"
                  FasterCSV
                end
        klass.generate(
          {:headers => self.header_for_csv, :write_headers => true}.merge(options)
        ) do |csv|
          self.rows.each do |row|
            csv << row
          end
        end
      end

      #def columns(*args)
        #self.class.columns(*args)
      #end

      def data_columns
        columns(:data => true)
      end

      def column_by_name(name)
        self.columns.find do |col|
          col.name.to_sym == name.to_sym
        end
      end
    end # InstanceMethods

  end
end
