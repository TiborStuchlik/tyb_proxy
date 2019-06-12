# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#

every 60.minutes do
  #runner "Tyb::Certificate.check_update"
  command "wget -O- http://127.0.0.1:3003/command/check > /dev/null"
end
# whenever --update-crontab

# Learn more: http://github.com/javan/whenever
