class Datagrid::Columns::Column

  attr_accessor :grid, :parent, :options, :block, :name

  def initialize(grid, parent, name, options = {}, &block)
    self.grid = grid
    self.parent = parent
    self.name = name.to_sym
    self.options = options
    self.block = block if block_given?
    if format
      ::Datagrid::Utils.warn_once(":format column option is deprecated. Use :url or :html option instead.")
    end
  end

  def value(model, grid)
    value_for(model, grid)
  end

  def value_for(model, grid)
    return nil unless self.block
    if self.block.arity == 1
      self.block.call(model)
    elsif self.block.arity == 2
      self.block.call(model, grid)
    else
      model.instance_eval(&self.block)
    end
  end

  def format
    self.options[:format]
  end

  def label
    self.options[:label]
  end

  def header
    self.parent.header
  end

  def order
    if options.has_key?(:order)
      self.options[:order]
    else
      grid.driver.default_order(grid.scope, name)
    end
  end

  def order_desc
    return nil unless order
    self.options[:order_desc]
  end

  def html?
    !! self.options[:html]
  end

  def data?
    !html?
  end

end
