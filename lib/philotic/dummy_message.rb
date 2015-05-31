require 'philotic/message'

module Philotic
  class DummyMessage < Philotic::Message
    attr_payload :subject
    attr_payload :message
    attr_routable :gender
    attr_routable :available
  end
end
