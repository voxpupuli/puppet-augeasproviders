# Additions for types

require File.dirname(__FILE__) + '/../augeasproviders'

# Utilities to help write types for Puppet with Augeas-based providers.
#
# To use, include in the type:
#
#     Puppet::Type.newtype(:example) do
#       extend AugeasProviders::Type
#       # [..]
#     end
#
# @api public
module AugeasProviders::Type
  # Implements `ensurable` with an additional value of `positioned`.
  #
  # When set to `positioned`, the type will call `provider.in_position?` to
  # check if the resource is currently in the correct position in the file.
  # If it isn't, the resource will be destroyed and recreated - assuming the
  # provider then creates it in the correct position.
  # 
  # @yield additional block to execute within `ensurable`
  # @api public
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
