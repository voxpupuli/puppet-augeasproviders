# Additions for types

require File.dirname(__FILE__) + '/../augeasproviders'

module AugeasProviders::Type
  def positionable(&block)
    ensurable do
      defaultvalues
      block if block_given?

      newvalue(:positioned) do
        current = self.retrieve
        if current == :absent
          provider.create
        elsif !provider.in_position?
          provider.destroy
          provider.create
        end
      end

      def insync?(is)
        return true if should == :positioned and is == :present and provider.in_position?
        super
      end
    end
  end
end
