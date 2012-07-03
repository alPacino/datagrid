class Datagrid::Columns::Header

  attr_accessor :grid, :options, :block, :name, :level, :parent#, :colspan

  def initialize(grid, parent, name, level, options = {})
    self.grid = grid
    self.parent = parent
    self.name = name.to_sym
    self.level = level
    self.options = options
  end

  def header
    self.options[:header] ||
      I18n.translate(self.name, :scope => "datagrid.#{self.grid.param_name}.columns", :default => self.name.to_s.humanize )
  end

  def colspan
    options[:colspan] || 1
  end

  def colspan=(colspan)
    options[:colspan] = colspan
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
end
