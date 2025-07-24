require "test_helper"

class AgentWithCallbacks < ApplicationAgent
  include AbstractController::Callbacks
end

class CallbacksWithConditions < AgentWithCallbacks
  before_generation :set_resource, only: :test_action

  def test_action
    prompt(message: "Test action message")
  end

  private

  def set_resource
    @resource = 'some resource'
  end
end

class TestCallbacksWithConditions < ActiveSupport::TestCase
  def setup
    @agent_class = CallbacksWithConditions
  end

  test "when :only is specified, a before action is triggered on that action" do
    @agent_class.test_action.generate_now
    assert_equal "Hello, World", @agent.instance_variable_get("@second")
  end
end
