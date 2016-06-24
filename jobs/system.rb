require_relative '../lib/scheduler_utils'

SchedulerUtils.smart_schedule SCHEDULER, "system_job", 60, lambda {
  free_value = `free | grep Mem|awk '{print $4}'`.to_f
  used_value = `free | grep Mem|awk '{print $3}'`.to_f
  free_value = (free_value/1024/1024).round(3)
  used_value = (used_value/1024/1024).round(3)
  send_event( "mem",{
      current: free_value,
      moreinfo: "Used #{used_value} GB"})

  free_value = `df| grep /dev/sda5 |awk '{print $4}'`.to_f
  used_value = `df| grep /dev/sda5 |awk '{print $3}'`.to_f
  free_value = (free_value/1024/1024).round(1)
  used_value = (used_value/1024/1024).round(1)
  send_event( "space",{
       current: free_value,
       moreinfo: "Used #{used_value} GB"})


  10
}
