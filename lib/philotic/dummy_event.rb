require 'philotic/event'

module Philotic
  class DummyEvent < Philotic::Event
    attr_payload :subject
    attr_payload :message
    attr_routable :gender
    attr_routable :available
  end
end
