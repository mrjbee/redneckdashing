class Component

  def initialize(id)
    @id = id
    @executed_times = 0
    @last_execution = nil
    @up = nil
    @messages = Array.new
  end

  def add_execution
    @executed_times += 1
    @last_execution = Time.now.to_s
  end

  def mark_up
    @up = true
  end

  def mark_down
    @up = false
  end

  def message (message)
    @messages << "[#{Time.now.to_s}] #{message}"
    @messages.shift if (@messages.size > 20)
  end

  # Do not try that at home!
  def to_html
    "<div>Component <b>#{@id}</b> #{(@up?'is <u>up</u>':' is <u>down</u>') if (@up!=nil)}
    #{(' last start at <u>'+@last_execution)+'</u>' if @last_execution} and executed
    <u>#{@executed_times}</u> times </div>
    #{@messages.inject('<ul>'){|ul,str| ul += '<li>'+str+'</li>'}}</ul>"
  end

end

class Audit

  COMPONENT_HASH = Hash.new {|hash, component_id|
    hash[component_id] = Component.new component_id
  }

  #@return [Component]
  def Audit::_component(component_id)
    COMPONENT_HASH[component_id]
  end

  def Audit::trace_execution(component_id)
    _component(component_id).add_execution
  end

  def Audit::trace_up(component_id, message)
    _component(component_id).mark_up
    _component(component_id).message "[COMPONENT UP] #{message}"
  end

  def Audit::trace_down(component_id, message)
    _component(component_id).mark_down
    _component(component_id).message "[COMPONENT DOWN] #{message}"
  end

  def Audit::trace(component_id, message)
    _component(component_id).message "[TRACE] #{message}"
  end

  # @return [Array{Component}]
  def Audit::trace_components
    COMPONENT_HASH.values.map(&:to_html)
  end

end