require "foobara/all"

module Foobara
  module Auth
    foobara_domain!
  end
end

Foobara::Util.require_directory "#{__dir__}/../../src"
