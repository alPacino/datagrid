require "datagrid/columns"

module Datagrid
  class OrderUnsupported < StandardError
  end
  module Ordering

    def self.included(base)
      base.class_eval do
        include Datagrid::Columns
        include InstanceMethods

        datagrid_attribute :order do |instance, value|
          instance.instance_eval do
            unless value.blank?
              value = value.to_sym
              column = column_by_name(value)
              unless column
                order_unsupported(value, "no column #{value} in #{self.class}")
              end
              unless column.order
                order_unsupported(
                  column.name, "#{self.class}##{column.name} don't support order"
                )
              end
              value
            else
              nil
            end
          end

        end

        datagrid_attribute :descending do |value|
          Datagrid::Utils.booleanize(value)
        end
        alias descending? descending

      end
      base.send :include, InstanceMethods
    end # self.included

    module InstanceMethods

      def order_unsupported(name, reason)
        raise Datagrid::OrderUnsupported, "Can not sort #{self.class.inspect} by ##{name}: #{reason}"
      end

      def assets
        result = super
        if self.order
          column = column_by_name(self.order)
          result = apply_order(result, column)
        end
        result
      end

      private

      def apply_order(assets, column)

        order = column.order
        if self.descending?
          if column.order_desc
            driver.asc(assets, column.order_desc)
          else
            driver.desc(assets, order)
          end
        else
          driver.asc(assets, order)
        end
      end

    end # InstanceMethods

  end
end
