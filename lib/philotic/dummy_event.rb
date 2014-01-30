module Philotic
  class DummyEvent < Event
    attr_payload :subject
    attr_payload :message
    attr_routable :gender
    attr_routable :available
  end
end
