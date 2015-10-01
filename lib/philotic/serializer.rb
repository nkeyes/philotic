require 'philotic/serializer/json'
module Philotic
  module Serializer
    extend self

    def factory(serializer)
      serializer = serializer.to_s
      require serializer
      serializer.classify.constantize
    end
  end
end