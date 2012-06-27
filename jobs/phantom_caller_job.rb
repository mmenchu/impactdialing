require Rails.root.join("jobs/heroku_resque_answered_auto_scale")
require 'resque/plugins/lock'
require 'resque-loner'

class PhantomCallerJob 
  extend Resque::Plugins::Lock
  include Resque::Plugins::UniqueJob
  @queue = :background_worker_job
  
   def self.perform(caller_session_id)
     caller_session = CallerSession.find(caller_session_id)
     twilio_lib = TwilioLib.new
     twilio_lib.end_call_sync(caller_session.sid)
   end
end