require 'resque/plugins/lock'
require 'resque-loner'

class DebiterJob 
  extend Resque::Plugins::Lock
  include Resque::Plugins::UniqueJob
  @queue = :debit_worker_job

   def self.perform     
     call_attempts = CallAttempt.debit_not_processed.limit(5000)        
     call_attempts.each do |call_attempt|
       begin
         call_attempt.debit
         call_attempt.update_attribute(:debited, true)
       rescue Exception => e
         call_attempt.update_attribute(:debited, true)
       end
     end
     
    caller_sessions = CallerSession.debit_not_processed.limit(5000)     
    caller_sessions.each do |caller_session|
      begin
        caller_session.debit
        caller_session.update_attribute(:debited, true)
       rescue Exception=>e
         caller_session.update_attribute(:debited, true)
       end
    end
   end
end